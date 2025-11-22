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
│  │  │  Vault Validator                                  │ │ │
│  │  │  - Main liquidity pool logic                      │ │ │
│  │  │  - Position management                            │ │ │
│  │  │  - GLP minting/burning                            │ │ │
│  │  │  - Fee distribution                               │ │ │
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

**Purpose**: 중앙 유동성 풀 및 포지션 관리

**Key Responsibilities:**
- 스테이블 코인 유동성 관리
- GLP 토큰 발행/소각
- 포지션 오픈/종료 검증
- 담보 및 예약 금액 추적
- 토큰별 오픈 인터레스트 관리
- 수수료 수집 및 분배

**State (VaultDatum):**
```aiken
pub type VaultDatum {
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

### Position Contract

**Purpose**: 개별 포지션 관리 및 소유권

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

**Purpose**: 신뢰할 수 있는 가격 피드

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
┌──────────────────────────────┐
│  UTXO: abc123#0             │
├──────────────────────────────┤
│  Address: Vault Script       │
│  Value: 1,000,000 USDC +2 ADA│
│  Datum (Inline):             │
│    VaultDatum {              │
│      stablecoin: USDC,       │
│      total_liquidity: 1M,    │
│      reserved_amounts: [...],│
│      ...                     │
│    }                         │
└──────────────────────────────┘
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

**Purpose:** 빠른 조회 및 분석

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
- **Validators**: Vault, Position, Oracle
- **Tokens**: GLP (Native Token)

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

더 자세한 내용은 다음 문서를 참조하세요:

- **[Core Logic](03-core-logic.md)** - 동작 원리 상세
- **[Implementation](04-implementation.md)** - 코드 구현
- **[Off-chain Services](offchain-services.md)** - 백엔드 서비스

---

[← Back to Concept](01-concept.md) | [Back to Index](README.md) | [Next: Core Logic →](03-core-logic.md)

