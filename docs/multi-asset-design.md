# Multi-Asset Design – Single Stablecoin Pool

HydroX mirrors GMX v1’s most important idea: run every market out of one USD-denominated vault. Liquidity providers deposit a stablecoin once, mint GLP, and immediately become the counterparty to BTC, ETH, ADA, and any other whitelisted index token. Traders, in turn, borrow buying power from the same pool regardless of which asset they trade.

## System Overview

```
┌────────────────────────────────────────────────────────┐
│                 HydroX Stablecoin Vault                │
│   Total Liquidity: 1,000,000 USD (single asset)        │
│                                                        │
│   Markets (per-token accounting)                       │
│   ┌────────────────────────────────────────────────┐   │
│   │ BTC: reserved 150k, OI long 600k, short 200k   │   │
│   │ ETH: reserved  80k, OI long 300k, short 400k   │   │
│   │ ADA: reserved  30k, OI long 100k, short  50k   │   │
│   │ … any other whitelisted token                  │   │
│   └────────────────────────────────────────────────┘   │
│                                                        │
│   Available liquidity = total_liquidity - reserved     │
└────────────────────────────────────────────────────────┘
```

## Vault Datum Essentials

```aiken
pub type VaultDatum {
  // Identification
  vault_nft: AssetClass,
  stablecoin: AssetClass,

  // Global accounting
  total_liquidity: Int,
  glp_supply: Int,

  // Token-level tracking
  reserved_amounts: List<(AssetClass, Int)>,
  guaranteed_usd: List<(AssetClass, Int)>,
  open_interest_long: List<(AssetClass, Int)>,
  open_interest_short: List<(AssetClass, Int)>,
  cumulative_funding_rate_long: List<(AssetClass, Int)>,
  cumulative_funding_rate_short: List<(AssetClass, Int)>,
  last_funding_times: List<(AssetClass, Int)>,

  // Risk controls
  whitelisted_tokens: List<AssetClass>,
  max_utilization: List<(AssetClass, Int)>, // basis points

  // Parameters
  admin: Hash<Blake2b_224, VerificationKey>,
  mint_burn_fee_basis_points: Int,
  margin_fee_basis_points: Int,
  liquidation_fee_usd: Int,
  min_profit_time: Int,
  max_leverage: Int,
}
```

Every per-token list (reserved, open interest, funding, guaranteed USD) shares the same schema: match by `policy_id + asset_name`, update the entry, or append a new tuple.

## Position Datum Snapshot

```aiken
pub type Position {
  owner: Hash<Blake2b_224, VerificationKey>,
  index_token: AssetClass,      // e.g., BTC, ETH, ADA
  position_type: PositionType,  // Long or Short
  size: Int,                    // USD notionals (1e30)
  collateral: Int,              // Stablecoin collateral (1e30)
  average_price: Int,           // Entry price (1e30)
  entry_funding_rate: Int,
  last_increased_time: Int,
}
```

Each leveraged position sits in its own UTXO, so multiple users can open or update positions in parallel without contending for shared storage.

## Flow Examples

### BTC Long (10x)

- Collateral: 1,000 USD  
- Size: 10,000 USD  
- Margin fee (0.3%): 30 USD → vault

State updates:
- `reserved_amounts[BTC] += 1,000`
- `open_interest_long[BTC] += 10,000`
- `total_liquidity += 30`
- Position datum created with the user’s parameters.

### ETH Short (5x) at the same time

- Collateral: 500 USD  
- Size: 2,500 USD  
- Margin fee: 7.5 USD

State updates:
- `reserved_amounts[ETH] += 500`
- `open_interest_short[ETH] += 2,500`
- `guaranteed_usd[ETH] += 2,500` (short accounting)
- BTC data is untouched because the lists are token-scoped.

## Why a Single Pool?

1. **Capital efficiency** – Instead of splitting 300k USD into three asset pools, concentrate it in one and let every market draw from it. Bigger trades clear, spreads tighten, and utilization stays high.
2. **Risk diversification** – LP PnL equals “fees + trader losses − trader profits” aggregated across all assets. Losses in BTC can be offset by gains or fees from ETH and ADA.
3. **User simplicity** – Traders manage a single stablecoin wallet; they never swap collateral or worry about mixed margin types.

## Token-Level Risk Controls

### Utilization Caps

```aiken
max_utilization = [
  (BTC, 8000),   // 80%
  (ETH, 8000),
  (ADA, 7000),
  (MEME, 5000),  // higher volatility → lower cap
]
```

`validate_increase_position` refuses new collateral if it would exceed a token’s cap, preventing any single market from consuming the vault.

### Per-Token Tracking Benefits

```
Without tracking:
  total_reserved = 80,000 USD
  → impossible to see which asset dominates.

With tracking:
  reserved_amounts = { BTC: 40k, ETH: 30k, ADA: 10k }
  → risk & treasury teams gain instant visibility.
```

## Funding Rates (Per Token)

HydroX adopts GMX-style funding:

1. Read `open_interest_long[token]` and `open_interest_short[token]`.  
2. Compute imbalance = (long − short) / (long + short).  
3. Funding delta = imbalance × time_delta × factor.  
4. Update `cumulative_funding_rate_long/short`. The crowded side pays.

This ensures one asset’s crowding does not bleed into another’s fees.

## Validator Checklist for `IncreasePosition`

Inside `validators/vault.ak`, the redeemer path enforces:

1. Token is in `whitelisted_tokens`.  
2. `collateral_delta` and `size_delta` are positive.  
3. Resulting leverage ≤ `max_leverage`.  
4. `reserved_amounts[token] + collateral_delta` stays ≤ `max_utilization[token]`.  
5. User supplies `collateral_delta + margin_fee` stablecoins.  
6. Vault datum updates the correct token entries (reserved, open interest, guaranteed USD for shorts).  
7. (TODO in code) The corresponding Position datum is created or updated consistently.

## Funding Updater (Future Work)

`UpdateFundingRate` will iterate every whitelisted token and:

- Read current timestamp and the token’s `last_funding_time`.  
- Pull `open_interest_long/short`.  
- Calculate funding delta and update cumulative rates.  
- Write the refreshed `last_funding_time`.  

Anyone can call this function; incentives can be added later for keepers.

## Real-Time Monitoring Example

```json
{
  "stablecoin": "USDC",
  "total_liquidity": "1000000",
  "glp_supply": "950000",
  "reserved": {
    "BTC": "150000",
    "ETH": "80000",
    "ADA": "30000"
  },
  "open_interest": {
    "BTC": { "long": "600000", "short": "200000" },
    "ETH": { "long": "300000", "short": "400000" },
    "ADA": { "long": "100000", "short": "50000" }
  },
  "funding": {
    "BTC": 120,
    "ETH": -80,
    "ADA": 50
  }
}
```

## LP and Trader Perspectives

- **LPs** deposit once, mint GLP, and automatically earn fees from every market. Trader losses flow directly into the vault; trader wins come out of it.
- **Traders** mix and match strategies (e.g., BTC long + ETH short) using the same collateral wallet, with predictable USD accounting.

## Summary

- ✅ Single stablecoin pool shared across markets  
- ✅ Per-token reserved/open-interest/funding lists  
- ✅ Token-specific utilization caps and funding curves  
- ✅ Deterministic eUTXO storage: vault UTXO + position UTXOs + oracle UTXO  

HydroX faithfully recreates GMX v1’s capital efficiency while leaning on Cardano’s predictable execution model.

