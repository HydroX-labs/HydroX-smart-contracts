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
  Manages the stablecoin pool, mints/burns GLP, tracks funding, fees, and reserved liquidity. Redeemers cover Add/Remove liquidity, Increase/Decrease position, Liquidate, and UpdateFundingRate.

- **Position validator (`validators/position.ak`)**  
  Holds each leveraged position in its own UTXO. Datum fields: owner key hash, index token, long/short flag, size (USD @ 1e30), collateral (stablecoin @ 1e30), average price, entry funding rate, last increased time.

- **Oracle validator (`validators/oracle.ak`)**  
  Provides batched price data (token, price @ 1e30, timestamp, confidence) under an oracle admin policy.

- **Utility library (`lib/utils.ak`)**  
  Shared helpers such as `calculate_fee`, `get_aum`, `get_position_fee`, `get_funding_fee`, and `validate_liquidation`.

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
