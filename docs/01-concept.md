# Project Concept

## Vision

HydroX brings the proven GMX v1 perpetual model to Cardano. By leaning on the eUTXO ledger and Aiken smart contracts, the protocol delivers predictable, transparent leverage trading while keeping capital inside a single stablecoin vault.

## Core Innovation

### One Stablecoin Pool, Many Markets

```
┌─────────────────────────────────────────┐
│      Single Stablecoin Liquidity Pool   │
│        (e.g., USDC / iUSD / USDA)       │
│                                         │
│  Total Liquidity: 1,000,000 USD         │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  BTC Long/Short Positions         │ │
│  │  ETH Long/Short Positions         │ │
│  │  ADA Long/Short Positions         │ │
│  │  SOL Long/Short Positions         │ │
│  │  ... any whitelisted market       │ │
│  └───────────────────────────────────┘ │
│                                         │
│  Every position settles against        │
│  the same stablecoin reserve.          │
└─────────────────────────────────────────┘
```

Highlights:
- Stablecoin-only collateral keeps accounting simple.
- Shared liquidity unlocks capital efficiency across markets.
- Risk naturally diversifies across trader positions.

## Key Features

### For Liquidity Providers

- **GLP-style receipts**: Providers receive a Cardano native token that tracks their vault share. Burn anytime to withdraw stablecoins (subject to reserved liquidity).
- **Fee capture**: Earn a share of position open/close fees, mint/burn fees, and liquidation penalties. Parameters default to 30 bps but are configurable.
- **Trader PnL flow**: Trader losses accrue to the vault; trader profits come out of it. LPs effectively take the opposing side of leveraged traders.
- **Passive diversification**: Exposure spans every whitelisted index token, so losses on one market can be offset by gains on another.

Example:
```
Alice deposits 10,000 USD stablecoin
→ Receives ~9,970 GLP after the 0.3% mint fee
→ Starts accruing fees from BTC/ETH/ADA traders
→ Benefits when traders lose, but bears their profits
→ Burns GLP later to reclaim her share
```

### For Traders

- **Leverage up to 50x** (tunable). Lock 1,000 USD to control a 50,000 USD position.
- **Long and short** exposure on every listed index token using the same stablecoin collateral.
- **Funding rate** mechanism (GMX-style) nudges the market back toward balance: the crowded side pays the other.
- **Transparent liquidation rules**: when collateral ratio drops below 1% (after deducting fees), positions are liquidated with a deterministic penalty.

Example:
```
Bob opens a BTC long
Collateral: 1,000 USD
Leverage: 10x
Position size: 10,000 USD
BTC +10% → +1,000 USD (100% return on collateral)
BTC −10% → liquidation warning
```

## Why This Architecture?

1. **Capital efficiency** – Instead of splitting 300k USD across three asset pools, HydroX concentrates the same 300k into a single vault that all markets use, enabling larger trades and tighter spreads.
2. **Risk pooling** – LP PnL reflects aggregate trader activity. A BTC crash might benefit LPs while ETH trades remain neutral, smoothing outcomes.
3. **User simplicity** – Traders only manage one stablecoin wallet; no asset swaps or multi-collateral UX. Positions are denominated in USD, making margins intuitive.

## Traditional DEX vs HydroX

| Aspect            | Traditional DEX (Spot)      | HydroX (Perps)             |
|-------------------|-----------------------------|----------------------------|
| Exposure          | Must hold the asset         | Uses stablecoin collateral |
| Shorts            | Not available               | Native shorting            |
| Leverage          | 1x                          | Up to 50x                  |
| PnL               | Price change                | Leverage × price change    |
| Fees              | Swap fees per trade         | Entry/exit + funding       |

Example:
```
BTC climbs 10%

Spot (Uniswap):
→ Buy BTC with 1,000 USD
→ Profit: 100 USD (10%)

HydroX (10x):
→ 1,000 USD collateral
→ 10,000 USD position
→ Profit: 1,000 USD (100%)
```

## Risk Notes

### Liquidity Providers
- Trader gains reduce vault equity; prolonged bull runs favor traders.
- Reserved liquidity cannot be withdrawn until positions settle, so exit capacity depends on utilization.
- Monitoring oracle integrity and funding parameters is essential before depositing.

### Traders
- High leverage increases liquidation probability; once the collateral ratio < 1%, liquidation is automatic.
- Funding can accumulate quickly when the market is imbalanced.
- Fast price swings on Cardano L1 still matter: on-chain latency means risk management should be conservative.

## Common Use Cases

1. **Hedging** – Lock in USD value by shorting the asset you hold elsewhere.
2. **Directional conviction** – Express bullish or bearish views with capital-efficient leverage.
3. **Funding arbitrage** – Capture positive/negative funding spreads between HydroX and other venues.
4. **Leveraged portfolio** – Build a basket of moderate-leverage longs (or shorts) using one collateral wallet.

## Design Principles

1. **Simplicity** – USD-denominated accounting, single collateral type, minimal redemption paths.
2. **Transparency** – All formulas, parameters, and liquidation rules are on-chain and documented.
3. **Efficiency** – Concentrated liquidity, predictable fees, and streamlined redeemers keep transactions lean.
4. **Safety** – Auditable contracts, conservative defaults, and incentive-aligned liquidations.
5. **Decentralization** – Anyone can provide liquidity, trade, liquidate, or update prices (with proper credentials); governance will progressively decentralize.

## Next Steps

Ready to dive deeper?

1. **[Architecture Overview](02-architecture.md)** – smart-contract topology and data models.
2. **[Core Logic](03-core-logic.md)** – fee math, PnL flows, and validation rules.
3. **[Multi-Asset Design](multi-asset-design.md)** – token whitelisting and oracle considerations.

---

[← Back to Index](README.md) | [Next: Architecture →](02-architecture.md)

