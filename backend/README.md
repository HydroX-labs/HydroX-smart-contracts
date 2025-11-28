# HydroX Backend

MSA architecture for HydroX perpetual trading protocol on Cardano.

## Architecture

```
backend/
├── libs/                    # Shared libraries
│   ├── cardano-utils/      # Cardano transaction building utilities
│   ├── types/              # Shared TypeScript types
│   └── vault-calculations/ # Vault math (GLP, fees, positions)
├── services/               # Microservices
│   ├── transaction-service/ # Unsigned tx builder & submission
│   ├── position-service/    # Position logic & liquidations
│   ├── oracle-service/      # Price feeds & oracle updates
│   └── indexer-service/     # Blockchain indexer & UTXO tracker
└── docker-compose.yml      # Local development environment
```

## Tech Stack

- **Runtime**: Node.js 18+ with TypeScript
- **Framework**: NestJS (for each service)
- **Cardano**: Lucid + Ogmios
- **Database**: PostgreSQL + Redis
- **Communication**: gRPC (internal), REST + WebSocket (external)

## Getting Started

### Prerequisites

- Node.js 18+
- pnpm 8+
- Docker & Docker Compose
- Cardano node + Ogmios (or use Blockfrost)

### Installation

```bash
# Install dependencies
pnpm install

# Build all packages
pnpm build

# Start infrastructure (PostgreSQL, Redis, Ogmios)
docker-compose up -d

# Run all services in development mode
pnpm dev
```

### Environment Variables

Copy `.env.example` to `.env` in each service directory and configure:

```env
# Common
NODE_ENV=development
LOG_LEVEL=debug

# Cardano
OGMIOS_URL=ws://localhost:1337
CARDANO_NETWORK=preprod

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/hydrox
REDIS_URL=redis://localhost:6379

# Service-specific
PORT=3000
```

## Services

### Transaction Service (Port 3001)

Builds unsigned transactions and submits signed transactions.

```bash
cd services/transaction-service
pnpm dev
```

**API Endpoints:**
- `POST /tx/build/add-liquidity` - Build add liquidity tx
- `POST /tx/build/remove-liquidity` - Build remove liquidity tx
- `POST /tx/build/increase-position` - Build increase position tx
- `POST /tx/build/decrease-position` - Build decrease position tx
- `POST /tx/submit` - Submit signed transaction
- `GET /tx/:txHash/status` - Get transaction status
- `WS /tx/subscribe` - Subscribe to tx status updates

### Position Service (Port 3002)

Manages position logic, PnL calculations, and liquidations.

```bash
cd services/position-service
pnpm dev
```

**API Endpoints:**
- `GET /positions/:account` - Get user positions
- `GET /positions/:account/:token` - Get specific position
- `POST /positions/calculate-pnl` - Calculate position PnL
- `GET /positions/liquidatable` - Get liquidatable positions

### Oracle Service (Port 3003)

Manages price feeds and oracle updates.

```bash
cd services/oracle-service
pnpm dev
```

**API Endpoints:**
- `GET /oracle/prices` - Get all token prices
- `GET /oracle/prices/:token` - Get specific token price
- `POST /oracle/update` - Update on-chain oracle (admin only)

### Indexer Service (Port 3004)

Indexes blockchain data and tracks UTXOs.

```bash
cd services/indexer-service
pnpm dev
```

**API Endpoints:**
- `GET /utxo/vault` - Get current vault UTXO
- `GET /utxo/position/:account/:token` - Get position UTXO
- `WS /events/subscribe` - Subscribe to UTXO change events

## Development

### Running Tests

```bash
pnpm test
```

### Linting

```bash
pnpm lint
```

### Building for Production

```bash
pnpm build
```

## Deployment

See `k8s/` directory for Kubernetes deployment manifests.

## License

MIT

