# Core Logic & Mechanics

## Liquidity Pool Mechanics

### Adding Liquidity

**Process:**
```
User deposits USDC → Vault mints GLP → User receives GLP
```

**Calculation:**
```aiken
// First deposit
if glp_supply == 0:
  glp_to_mint = amount - mint_fee

// Subsequent deposits  
else:
  glp_to_mint = (amount - mint_fee) * glp_supply / total_liquidity
```

**Example:**
```
Pool state:
  total_liquidity: 100,000 USDC
  glp_supply: 95,000 GLP

User deposits: 10,000 USDC
Mint fee (0.3%): 30 USDC
After fee: 9,970 USDC

GLP to mint = 9,970 * 95,000 / 100,000 = 9,471 GLP

New state:
  total_liquidity: 109,970 USDC
  glp_supply: 104,471 GLP
```

### Removing Liquidity

**Process:**
```
User burns GLP → Vault returns USDC → User receives stablecoin
```

**Calculation:**
```aiken
stablecoin_out = glp_amount * total_liquidity / glp_supply - burn_fee
```

**Constraint:**
```aiken
// Cannot withdraw reserved amounts
available = total_liquidity - total_reserved
stablecoin_out <= available
```

## Position Mechanics

### Opening Long Position

**Scenario:** BTC Long with 10x leverage

**Input:**
- Collateral: 1,000 USDC
- Leverage: 10x
- Position Size: 10,000 USD
- BTC Price: 40,000 USD

**Validation:**
```aiken
1. BTC whitelisted? ✓
2. leverage <= max_leverage? ✓
3. reserved[BTC] + 1,000 <= max_utilization? ✓
4. margin_fee = 10,000 * 0.003 = 30 USDC ✓
5. user deposited 1,030 USDC? ✓
```

**State Updates:**
```aiken
VaultDatum:
  total_liquidity += 30
  reserved_amounts[BTC] += 1,000
  open_interest_long[BTC] += 10,000

Position UTXO:
  owner: user_pkh
  index_token: BTC
  position_type: Long
  size: 10,000
  collateral: 1,000
  average_price: 40,000
```

### Opening Short Position

**Scenario:** ETH Short with 5x leverage

**Input:**
- Collateral: 500 USDC
- Leverage: 5x
- Position Size: 2,500 USD
- ETH Price: 2,500 USD

**State Updates:**
```aiken
VaultDatum:
  total_liquidity += 7.5
  reserved_amounts[ETH] += 500
  open_interest_short[ETH] += 2,500
  guaranteed_usd[ETH] += 2,500  // Short-specific!
```

### Closing Position

**Scenario:** Close BTC Long after price increase

**Position:**
- Entry: 40,000 USD
- Current: 44,000 USD
- Size: 10,000 USD
- Collateral: 1,000 USDC

**PnL Calculation:**
```
For Long:
  PnL = size * (current - entry) / entry
  PnL = 10,000 * (44,000 - 40,000) / 40,000
  PnL = 1,000 USD profit
```

**Fees:**
```
Margin fee = 10,000 * 0.003 = 30 USDC
Funding fee = size * (current_funding - entry_funding) / 1e6
           = 10,000 * (1,500 - 1,200) / 1,000,000
           = 3 USDC
Total fees = 33 USDC
```

**Payout:**
```
Payout = collateral + PnL - fees
       = 1,000 + 1,000 - 33
       = 1,967 USDC
```

## Liquidation

### Condition

```aiken
Position liquidatable if:
  remaining_collateral / position_size < 1%
```

### Example

```
Position:
  size: 10,000 USD
  collateral: 1,000 USDC
  entry: 40,000 USD
  
Current: 36,000 USD (10% drop)

PnL = 10,000 * (36,000 - 40,000) / 40,000
    = -1,000 USD (loss)

Fees = 35 USDC

Remaining = 1,000 - 1,000 - 35 = -35 USDC

Ratio = -35 / 10,000 = -0.35% < 1%
→ Liquidatable!
```

### Process

```
1. Liquidator submits transaction
2. Validator verifies liquidation condition
3. $10 fee paid to liquidator
4. Remaining (if any) to pool
5. Position UTXO burned
6. Vault state updated
```

## Funding Rate

### Purpose

```
Balance long/short open interest
→ Prevent one-sided markets
→ Maintain system stability
```

### Calculation (Per Token)

```aiken
For each token:

1. Get open interest:
   oi_long = open_interest_long[token]
   oi_short = open_interest_short[token]

2. Calculate imbalance:
   imbalance = (oi_long - oi_short) / (oi_long + oi_short)

3. Funding rate:
   rate = imbalance * time_delta * factor

4. Update:
   If more longs:
     cumulative_long += rate  (longs pay)
     cumulative_short -= rate (shorts receive)
```

### Example

**BTC State:**
```
open_interest_long: 100,000 USD
open_interest_short: 50,000 USD
time_delta: 3,600,000 ms (1 hour)
factor: 100
```

**Calculation:**
```
imbalance = (100,000 - 50,000) / 150,000 = 0.333

funding_rate = 0.333 * 3,600,000 * 100 / 1,000,000 = 120

cumulative_long[BTC] += 120
cumulative_short[BTC] -= 120
```

**Effect:**
```
BTC Long Position (10,000 USD):
  funding_fee = 10,000 * 120 / 1,000,000 = 1.2 USDC (pays)

BTC Short Position (5,000 USD):
  funding_fee = 5,000 * (-120) / 1,000,000 = -0.6 USDC (receives)
```

## Fee Structure

```
┌─────────────────────────────────┐
│  Fee Type           Rate  Goes │
├─────────────────────────────────┤
│  GLP Mint           0.3%  Pool │
│  GLP Burn           0.3%  Pool │
│  Position Open      0.3%  Pool │
│  Position Close     0.3%  Pool │
│  Liquidation        $10   Liq. │
│  Funding Rate       Var.  Ctr. │
└─────────────────────────────────┘

All fees (except liquidation) → GLP holders
```

## Per-Token Tracking

### Why Important?

```
Without per-token tracking:
  total_reserved: 80,000 USDC
  → Which token? Unknown! 😱

With per-token tracking:
  reserved_amounts:
    BTC: 40,000 (40%)
    ETH: 30,000 (30%)
    ADA: 10,000 (10%)
  → Clear risk profile! ✅
```

### Token-Specific Limits

```aiken
max_utilization:
  BTC: 8000  // 80% (stable)
  ETH: 8000  // 80% (stable)
  ADA: 7000  // 70% (more volatile)
  MEME: 5000 // 50% (very risky)
```

**Meaning:**
- BTC: Max 80% of pool for BTC positions
- ADA: Max 70% (higher risk)
- MEME: Max 50% (very high risk)

## Precision and Scaling

### 1e30 Precision

```aiken
const price_precision = 1e30

Examples:
  BTC price: $40,000
  On-chain: 40,000 * 1e30
  
  Position: $10,000
  On-chain: 10,000 * 1e30
```

**Why 1e30?**
- GMX v1 compatibility
- Sufficient precision
- Support small and large values
- Avoid rounding errors

### Basis Points

```aiken
const basis_points_divisor = 10000

fee_bp = 30  // 0.3%
amount = 10,000 * 1e30

fee = amount * fee_bp / basis_points_divisor
    = 30 * 1e30  // $30
```

## Complete Flow Example

### User Journey: Opening and Closing

```
Day 1: Alice opens BTC Long
  - Deposits: 1,000 USDC
  - Leverage: 10x
  - Entry: BTC @ 40,000
  - Position: 10,000 USD

Day 2: BTC rises to 44,000 (+10%)
  - PnL: +1,000 USD
  - Funding: -10 USDC (paid)
  
Day 3: Alice closes
  - PnL: +1,000 USD
  - Fees: -40 USDC
  - Receives: 1,960 USDC
  - Profit: 960 USDC (96% return!)
```

### LP Journey: Earning Fees

```
Day 1: Bob provides 10,000 USDC
  - Receives: 9,970 GLP
  - Pool share: 1%

Weeks later:
  - Traders paid: 10,000 USDC in fees
  - Pool grew: 100,000 → 110,000
  - Bob's 1%: 1,100 USDC
  - Profit: 1,100 - 10,000 = +100 USDC

Plus: Trader losses added to pool
```

## Risk Management

### For the Protocol

1. **Per-token limits**: Prevent concentration
2. **Max utilization**: Reserve liquidity
3. **Liquidation incentives**: Ensure timely liquidations
4. **Funding rates**: Balance long/short

### For LPs

1. **Diversification**: Multiple tokens
2. **Fee income**: Steady revenue
3. **Risk**: Trader profits = LP losses
4. **Long-term**: Fees compound

### For Traders

1. **Leverage carefully**: High leverage = high risk
2. **Monitor funding**: Costs add up
3. **Set limits**: Know liquidation price
4. **Manage size**: Don't over-leverage

## Next Steps

For deeper implementation details:

- **[Implementation Guide](04-implementation.md)** – validator walkthroughs and helper functions.
- **[Multi-Asset Design](multi-asset-design.md)** – extended coverage of per-market tracking and risk controls.

---

[← Back to Architecture](02-architecture.md) | [Back to Index](README.md) | [Next: Implementation →](04-implementation.md)

