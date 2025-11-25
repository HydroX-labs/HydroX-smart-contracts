# HydroX GMX - Perpetual Exchange on Cardano

HydroX is a GMX v1–style perpetual futures protocol written in Aiken for the Cardano eUTXO ledger. The system intentionally keeps a single stablecoin collateral pool to reduce volatility risk and simplify accounting.

## Documentation

Full documentation lives in `docs/`. Start here if you are exploring the design:
- `01-concept.md` – product overview
- `02-architecture.md` – component breakdown
- `03-core-logic.md` – math and accounting rules
- `04-implementation.md` – on-chain details
- `06-comparison.md` – GMX v1 reference

## Architecture Snapshot

- **Vault validator (`validators/vault.ak`)**  
  Enforces that the vault NFT stays attached to every spend and routes logic through redeemers: `AddLiquidity`, `RemoveLiquidity`, `IncreasePosition`, `DecreasePosition`, `LiquidatePosition`, `UpdateFees`, and `UpdateFundingRate`. The first four currently focus on sanity checks (positive amounts, whitelist, leverage, utilization) with TODOs for full state/accounting updates. `UpdateFees` validates admin signatures and bounds, while `UpdateFundingRate` is a stub waiting for per-market math.

- **GLP minting policy (`validators/glp_policy.ak`)**  
  Mints on `AddLiquidity` and burns on `RemoveLiquidity` only when the vault UTXO (found via NFT) moves and its datum transitions match the expected liquidity/GLP math from `vault_utils`.

- **Vault NFT policy (`validators/vault_nft.ak`)**  
  One-time mint locked to a specific bootstrap UTXO reference so the vault identity can never be duplicated.

- **Position validator (`validators/position.ak`)**  
  Controls each position UTXO with two redeemers: `ClosePosition` (owner or liquidator) and `UpdatePosition` (owner adjustments). Both currently require future work to enforce signatures, vault co-spend, and state transitions, mirroring the TODOs inside the validator.

- **Oracle validator (`validators/oracle.ak`)**  
  Allows `UpdatePrices` when the current admin signs and supplies a non-empty price list, and `UpdateAdmin` when the existing admin authorizes the new key. Additional freshness/confidence checks are stubbed for later.

- **Utility library (`lib/utils.ak`)**  
  Houses shared helpers (`calculate_fee`, `get_aum`, `get_position_fee`, `get_funding_fee`, `validate_liquidation`, etc.) referenced by the validators and minting policies.

## Key Principles

- Stablecoin-only collateral and liquidity simplify risk management.
- eUTXO layout keeps vault, positions, and oracle in separate UTXOs, enabling parallel execution.
- Datum schemas stay minimal; all precision mirrors GMX (prices and amounts at 1e30, funding at 1e6, fees in basis points).

## Roadmap (high level)

1. Finish utility math (AUM, PnL, liquidation checks).
2. Complete vault validation for liquidity, position lifecycle, and GLP mint/burn.
3. Wire oracle freshness rules and multi-oracle support.
4. Add tests (unit + scenario) and performance passes.
5. Ship off-chain tooling (Lucid/Mesh), then preview/mainnet deployments.

Refer to `docs/roadmap` (coming soon) for finer detail.

## Getting Started

```bash
# Install Aiken (see https://github.com/aiken-lang/aiken)
winget install aiken-lang.aiken

# Check dependencies
aiken check

# Build contracts
aiken build

# Run tests (once added)
aiken test
```

## Repository Layout

```
HydroX-smart-contracts/
├── docs/
├── lib/
│   ├── types.ak
│   └── utils.ak
├── validators/
│   ├── vault.ak
│   ├── position.ak
│   └── oracle.ak
├── aiken.toml
└── README.md
```

## Security & Operations

- Price oracle updates must come from a trusted keeper set (Chainlink-style rotation recommended).
- Liquidation logic should incentivize third parties; review fee settings before deployment.
- Consider multisig or DAO governance for all admin actions.

## License & Credits

- License: Apache-2.0
- Inspired by the GMX team’s public contracts and the broader Cardano/Aiken community.

## Disclaimer

HydroX is experimental software. Use at your own risk, and commission a full audit before any mainnet deployment.
