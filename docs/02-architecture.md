# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend Layer                        │
│                     (React + TypeScript)                     │
│                                                              │
│  - User Interface (Positions, Charts, Analytics)            │
│  - Wallet Integration (Nami, Eternl, Flint)                 │
│  - Real-time Price Updates (WebSocket)                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ REST API / WebSocket
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                      Off-chain Services                      │
│                    (Node.js + TypeScript)                    │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Transaction Builder (Lucid)                           │ │
│  │  - Build complex transactions                          │ │
│  │  - Calculate all state transitions                     │ │
│  │  - Local validation before submission                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  UTXO Indexer (PostgreSQL)                             │ │
│  │  - Track Vault UTXO                                    │ │
│  │  - Index all Position UTXOs                            │ │
│  │  - Fast queries for frontend                           │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Oracle Service                                         │ │
│  │  - Fetch prices from external sources                  │ │
│  │  - Update Oracle UTXO periodically                     │ │
│  │  - Price validation and confidence checks              │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Liquidation Bot                                        │ │
│  │  - Monitor at-risk positions                           │ │
│  │  - Execute liquidations automatically                  │ │
│  │  - Earn liquidation fees                               │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Funding Rate Updater                                   │ │
│  │  - Calculate funding rates per token                   │ │
│  │  - Update Vault periodically                           │ │
│  │  - Balance long/short open interest                    │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Blockfrost API
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   Cardano Blockchain                         │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Smart Contracts (Aiken)                               │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  Vault Validator (Spending)                      │ │ │
│  │  │  - Main liquidity pool logic                      │ │ │
│  │  │  - Position management                            │ │ │
│  │  │  - Fee distribution                               │ │ │
│  │  │  - NFT preservation check                         │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  Vault NFT Policy (Minting)                       │ │ │
│  │  │  - One-time NFT mint                              │ │ │
│  │  │  - Vault UTXO identification                      │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  GLP Token Policy (Minting)                       │ │ │
│  │  │  - GLP minting/burning                            │ │ │
│  │  │  - Vault coordination                             │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  Position Validator                               │ │ │
│  │  │  - Individual position ownership                  │ │ │
│  │  │  - Position update rules                          │ │ │
│  │  │  - Liquidation conditions                         │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  Oracle Validator                                 │ │ │
│  │  │  - Price feed management                          │ │ │
│  │  │  - Price update authorization                     │ │ │
│  │  │  - Freshness validation                           │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## On-chain Components

### Vault Contract

**Purpose**: Core liquidity pool and position state machine.

**Key Responsibilities:**
- Track stablecoin liquidity and GLP supply.
- Validate position open/close actions.
- Maintain collateral and reserved balances.
- Monitor per-token open interest and funding.
- Collect and redistribute protocol fees.
- Preserve the unique vault NFT per UTXO. ✨

**State (VaultDatum):**
```aiken
pub type VaultDatum {
  // Vault identification (unique NFT)
  vault_nft: AssetClass,  // ← NEW: Ensures only one canonical Vault
  
  // Liquidity pool
  stablecoin: AssetClass,
  total_liquidity: Int,
  glp_supply: Int,
  
  // Per-token tracking
  reserved_amounts: List<(AssetClass, Int)>,
  guaranteed_usd: List<(AssetClass, Int)>,
  open_interest_long: List<(AssetClass, Int)>,
  open_interest_short: List<(AssetClass, Int)>,
  cumulative_funding_rate_long: List<(AssetClass, Int)>,
  cumulative_funding_rate_short: List<(AssetClass, Int)>,
  last_funding_times: List<(AssetClass, Int)>,
  
  // Risk management
  whitelisted_tokens: List<AssetClass>,
  max_utilization: List<(AssetClass, Int)>,
  
  // Parameters
  admin, fees, leverage, ...
}
```

### Vault NFT Policy

**Purpose**: Mint the single NFT that canonically identifies the vault UTXO.

**Key Features:**
- **One-time mint** during deployment.
- **Unique identifier** that pairs off-chain services with the correct UTXO.
- **Immutable** supply—no re-minting allowed.

**Minting Rules:**
```aiken
minting {
  fn vault_nft_policy(utxo_ref: OutputReference, ctx: ScriptContext) -> Bool {
    // 1. The designated bootstrap UTXO must be spent
    // 2. Exactly one NFT is minted
    // 3. No ability to mint again (immutability)
  }
}
```

**Why an NFT?**
- ✅ Guarantees uniqueness even if multiple UTXOs reside at the same script address.
- ✅ Lets GLP policy and backend services find the vault deterministically.
- ✅ Keeps validation simple: check for NFT presence.

### GLP Token Policy

**Purpose**: Govern GLP minting and burning.

**Key Responsibilities:**
- Sync GLP supply changes with vault state transitions.
- Use the vault NFT to ensure the correct UTXO is touched.
- Enforce AddLiquidity / RemoveLiquidity constraints.

**Parameters:**
```aiken
minting {
  fn glp_policy(vault_nft: AssetClass, ctx: ScriptContext) -> Bool {
    // locate the vault UTXO via NFT (no address assumptions)
    let vault_input = find_input_with_nft(inputs, vault_nft)
    let vault_output = find_output_with_nft(outputs, vault_nft)
    // ...
  }
}
```

### Position Contract

**Purpose**: Track ownership and lifecycle of every leveraged position.

**State (PositionDatum):**
```aiken
pub type Position {
  owner: Hash<Blake2b_224, VerificationKey>,
  index_token: AssetClass,      // BTC, ETH, ADA, etc.
  position_type: PositionType,  // Long or Short
  size: Int,                    // Position size (USD)
  collateral: Int,              // Stablecoin collateral
  average_price: Int,           // Entry price
  entry_funding_rate: Int,
  last_increased_time: Int,
}
```

### Oracle Contract

**Purpose**: Provide an auditable price feed UTXO.

**State (OracleDatum):**
```aiken
pub type OracleDatum {
  prices: List<PriceData>,
  oracle_admin: Hash<Blake2b_224, VerificationKey>,
  max_price_age: Int,
}

pub type PriceData {
  token: AssetClass,
  price: Int,          // USD price (1e30 scale)
  timestamp: Int,
  confidence: Int,
}
```

## Data Flow

### Opening a Long Position

```
User Action: Open BTC Long (1,000 USDC, 10x)

Step 1: Frontend
  ↓ User clicks "Open Long"
  ↓ Fetch BTC price from oracle
  ↓ Calculate total cost (collateral + fee)
  ↓ Send to backend

Step 2: Backend (Off-chain Computation)
  ↓ Query Vault UTXO from indexer
  ↓ Query Oracle UTXO for price
  ↓ Calculate:
     - Margin fee: 10,000 * 0.003 = 30 USDC
     - Total cost: 1,030 USDC
     - New reserved[BTC]: +1,000
     - New open_interest_long[BTC]: +10,000
  ↓ Build new VaultDatum
  ↓ Create PositionDatum
  ↓ Construct transaction
  ↓ Local validation ✓
  ↓ Return to frontend

Step 3: Frontend
  ↓ Show preview to user
  ↓ User signs with wallet
  ↓ Submit to blockchain

Step 4: On-chain Validation
  ↓ Vault Validator checks:
     ✓ BTC whitelisted?
     ✓ Leverage valid?
     ✓ Liquidity sufficient?
     ✓ Fee correct?
     ✓ State transition valid?
  ↓ Accept or Reject

Step 5: Result
  ✓ Position UTXO created
  ✓ Vault updated
  ✓ User sees position
```

## State Management

### On-chain State (UTXOs)

**Vault UTXO:**
```
┌──────────────────────────────────────┐
│  UTXO: abc123#0                     │
├──────────────────────────────────────┤
│  Address: Vault Script               │
│  Value:                              │
│    - 1,000,000 USDC                  │
│    - 1 Vault NFT (unique!) ✨        │
│    - 2 ADA                           │
│  Datum (Inline):                     │
│    VaultDatum {                      │
│      vault_nft: AssetClass(...),     │
│      stablecoin: USDC,               │
│      total_liquidity: 1M,            │
│      reserved_amounts: [...],        │
│      ...                             │
│    }                                 │
└──────────────────────────────────────┘
```

**Position UTXO:**
```
┌──────────────────────────────┐
│  UTXO: def456#0             │
├──────────────────────────────┤
│  Address: Position Script    │
│  Value: 2 ADA (min)          │
│  Datum (Inline):             │
│    Position {                │
│      owner: user_pkh,        │
│      index_token: BTC,       │
│      size: 10,000,           │
│      collateral: 1,000,      │
│      ...                     │
│    }                         │
└──────────────────────────────┘
```

### Off-chain State (Database)

**Purpose:** Enable fast queries, analytics, and historical tracking.

**Tables:**
- `vaults`: Current vault state
- `token_states`: Per-token metrics
- `positions`: All open positions
- `oracle_prices`: Latest prices

## eUTXO Transaction Model

### Key Concept

```
Transaction = {
  Inputs: [UTXO_1, UTXO_2, ...],    // Spend these
  Outputs: [UTXO_A, UTXO_B, ...],   // Create these
  Redeemers: [...]                   // How to spend scripts
  Datums: [...]                      // Data for new UTXOs
}
```

**Validation:**
```
For each script input:
  validator(datum, redeemer, context) → Bool
  
If all return True:
  → Transaction accepted
  → State transition
Else:
  → Transaction rejected
  → No state change
```

### Example Transaction

```typescript
const tx = await lucid.newTx()
  // INPUT: Vault UTXO (spend)
  .collectFrom([vaultUtxo], vaultRedeemer)
  
  // INPUT: User's USDC (spend)
  .collectFrom(userUtxos, Data.void())
  
  // INPUT: Oracle (reference only, not spent)
  .readFrom([oracleUtxo])
  
  // OUTPUT: Updated Vault
  .payToContract(vaultAddress, newVaultDatum, vaultAssets)
  
  // OUTPUT: New Position
  .payToContract(positionAddress, positionDatum, {})
  
  // OUTPUT: Change to user
  .payToAddress(userAddress, change)
  
  .complete();
```

## Why Cardano's eUTXO?

### Predictability

```
Ethereum:
  Submit TX → Unknown gas → May fail → Lost gas
  
Cardano:
  Build TX → Local validation → Know result → Submit
  ✓ Predict before payment
  ✓ Known fees
  ✓ No surprises
```

### Parallelization

```
Ethereum:
  Vault in contract storage
  → One transaction at a time
  → Sequential
  
Cardano:
  Each position = separate UTXO
  → Multiple positions simultaneously
  → Parallel
  → Higher throughput
```

### Determinism

```
eUTXO guarantees:
  ✓ Same inputs → Same outputs
  ✓ No hidden state
  ✓ Clear causality
  ✓ Easier auditing
```

## Technology Stack

### On-chain
- **Language**: Aiken
- **Validators**: 
  - Vault (spending validator)
  - Position (spending validator)
  - Oracle (spending validator)
- **Minting Policies**: 
  - Vault NFT (one-time mint)
  - GLP Token (coordinated with Vault)
- **Native Tokens**: GLP, Vault NFT

### Off-chain
- **Language**: TypeScript
- **Runtime**: Node.js
- **Framework**: Express
- **Cardano Lib**: Lucid
- **Node Access**: Blockfrost API

### Database
- **Primary**: PostgreSQL
- **ORM**: Drizzle ORM
- **Cache**: Redis (optional)

### Real-time
- **WebSocket**: Socket.IO
- **Updates**: 10s polling or webhooks

### Monitoring
- **Logging**: Winston
- **Metrics**: Prometheus
- **Visualization**: Grafana

## Next Steps

Continue with:

- **[Core Logic](03-core-logic.md)** – fee math, funding, and liquidation flows.
- **[Implementation](04-implementation.md)** – validator structure and code organization.
- **[Off-chain Services](offchain-services.md)** – supporting infrastructure.

---

[← Back to Concept](01-concept.md) | [Back to Index](README.md) | [Next: Core Logic →](03-core-logic.md)

