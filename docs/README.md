# BaobabX GMX Documentation

Complete documentation for BaobabX GMX - Decentralized Perpetual Futures Exchange on Cardano

---

## 📚 Documentation Index

### Core Documentation

1. **[01. Project Concept](01-concept.md)**
   - Vision and core innovation
   - Key features for LPs and Traders
   - Single stablecoin pool design

2. **[02. Architecture Overview](02-architecture.md)**
   - System architecture diagram
   - On-chain components (Vault, Position, Oracle)
   - Data flow and transaction lifecycle

3. **[03. Core Logic & Mechanics](03-core-logic.md)**
   - Liquidity pool mechanics (GLP)
   - Position mechanics (Long/Short)
   - Funding rate mechanism
   - Fee structure
   - Liquidation logic

4. **[04. Implementation Guide](04-implementation.md)**
   - Validator logic details
   - Utility functions (PnL, liquidation, funding)
   - Token-specific tracking
   - Code examples

5. **[05. Off-chain Architecture](05-offchain.md)**
   - UTXO Indexer
   - Transaction Builder
   - Liquidation Bot
   - Oracle Updater
   - Technology stack

6. **[06. GMX v1 Comparison](06-comparison.md)**
   - Feature comparison table
   - Architectural differences
   - Advantages and trade-offs
   - Ethereum vs Cardano

### Design Documents

- **[Multi-Asset Design](multi-asset-design.md)**
  - Single stablecoin pool + multiple asset positions
  - Per-token tracking
  - Risk management

- **[Off-chain Services](offchain-services.md)**
  - Detailed off-chain component design
  - Backend stack recommendations
  - TypeScript vs Go comparison

### Quick References

- **[Smart Contract API](api-reference.md)** *(Coming soon)*
  - Validator interfaces
  - Redeemer types
  - Datum structures

- **[Deployment Guide](deployment.md)** *(Coming soon)*
  - Testnet deployment steps
  - Configuration
  - Testing checklist

---

## 🚀 Quick Start

**For Developers:**
1. Start with [01. Project Concept](01-concept.md) to understand the vision
2. Read [02. Architecture Overview](02-architecture.md) for system design
3. Review [04. Implementation Guide](04-implementation.md) for code details
4. Check [05. Off-chain Architecture](05-offchain.md) for backend services

**For Protocol Designers:**
1. [01. Project Concept](01-concept.md) - Understand the innovation
2. [03. Core Logic & Mechanics](03-core-logic.md) - See how it works
3. [06. GMX v1 Comparison](06-comparison.md) - Compare with GMX
4. [Multi-Asset Design](multi-asset-design.md) - Deep dive into design

**For Auditors:**
1. [02. Architecture Overview](02-architecture.md) - System structure
2. [03. Core Logic & Mechanics](03-core-logic.md) - Business logic
3. [04. Implementation Guide](04-implementation.md) - Code implementation
4. Review actual code in `../lib/` and `../validators/`

---

## 📁 Repository Structure

```
baobabX-smart-contracts/
├── docs/                          # Documentation (you are here)
│   ├── README.md                  # This file
│   ├── 01-concept.md
│   ├── 02-architecture.md
│   ├── 03-core-logic.md
│   ├── 04-implementation.md
│   ├── 05-offchain.md
│   ├── 06-comparison.md
│   ├── multi-asset-design.md
│   └── offchain-services.md
├── lib/                           # Aiken library code
│   ├── types.ak                   # Type definitions
│   └── utils.ak                   # Utility functions
├── validators/                    # Smart contract validators
│   ├── vault.ak                   # Vault validator
│   ├── position.ak                # Position validator
│   └── oracle.ak                  # Oracle validator
├── aiken.toml                     # Aiken project config
└── README.md                      # Main README
```

---

## 🔑 Key Concepts

### Single Stablecoin Pool
One USDC liquidity pool serves all trading pairs (BTC, ETH, ADA, etc.)

### Multi-Asset Positions
Trade any whitelisted asset using the same stablecoin collateral

### Per-Token Tracking
Each asset has independent open interest, funding rates, and utilization

### eUTXO Model
Leverages Cardano's extended UTXO model for predictable execution

---

## 🎯 Status

- ✅ Core architecture designed
- ✅ Smart contract structure complete
- ✅ Per-token tracking implemented
- ⏳ Validator logic in progress
- ⏳ Off-chain services in planning
- ⏳ Frontend in planning

---

## 📝 Contributing to Docs

When adding new documentation:
1. Follow the existing structure
2. Use clear headings and examples
3. Include diagrams where helpful
4. Link to related documents
5. Update this index

---

## 📄 License

Apache-2.0

---

**Last Updated:** 2024  
**Version:** 1.0.0

