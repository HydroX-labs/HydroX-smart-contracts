# BaobabX GMX Backend

Backend services for testing and interacting with BaobabX GMX smart contracts.

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
```

Required:
- `BLOCKFROST_API_KEY`: Get from https://blockfrost.io
- `NETWORK`: "Preview" for testnet

### 3. Run Development Server

```bash
npm run dev
```

Server starts at `http://localhost:3000`

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/
│   │   └── lucid.ts              # Lucid configuration
│   ├── services/
│   │   └── transaction-builder.ts # Transaction building logic
│   ├── types/
│   │   └── index.ts              # Type definitions
│   └── index.ts                  # Main server
├── tests/
│   ├── unit/                     # Unit tests
│   └── integration/              # Integration tests
├── package.json
├── tsconfig.json
└── .env.example
```

## 🧪 Testing

### Unit Tests

```bash
npm run test:unit
```

Tests:
- Fee calculations
- Leverage validation
- Utilization checks
- PnL calculations

### Integration Tests

```bash
npm run test:integration
```

Tests full flow on Preview testnet (requires deployed contracts).

## 📡 API Endpoints

### Health Check

```bash
GET /health
```

Response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Get Vault Info

```bash
GET /api/vault
```

Response:
```json
{
  "total_liquidity": "1000000",
  "glp_supply": "950000",
  "reserved": "100000",
  "utilization": "10%"
}
```

### Open Long Position

```bash
POST /api/position/open-long
Content-Type: application/json

{
  "indexToken": {
    "policyId": "",
    "assetName": "BTC"
  },
  "collateral": "1000",
  "leverage": 10,
  "userAddress": "addr_test1..."
}
```

Response:
```json
{
  "success": true,
  "transaction": "84a400...",
  "message": "Transaction built. Please sign and submit."
}
```

### Get User Positions

```bash
GET /api/positions/:address
```

Response:
```json
{
  "positions": [
    {
      "id": "position_1",
      "index_token": "BTC",
      "type": "Long",
      "size": "10000",
      "collateral": "1000",
      "entry_price": "40000",
      "current_pnl": "+500"
    }
  ]
}
```

## 🔧 Services

### Transaction Builder

Builds transactions for:
- Opening positions (long/short)
- Closing positions
- Adding/removing liquidity
- Liquidations

Example:
```typescript
import { TransactionBuilder } from "./services/transaction-builder";

const txBuilder = new TransactionBuilder(lucid);

const tx = await txBuilder.openLongPosition({
  indexToken: { policyId: "", assetName: "BTC" },
  collateral: 1000n,
  leverage: 10,
  userAddress: "addr_test1..."
});

// Sign and submit
const signedTx = await tx.sign().complete();
const txHash = await signedTx.submit();
```

## 🧮 Calculations

### Fee Calculation

```typescript
// 0.3% fee (30 basis points)
const fee = (amount * 30n) / 10000n;
```

### Leverage Calculation

```typescript
const size = collateral * BigInt(leverage);
```

### Utilization Calculation

```typescript
const utilization = (reserved * 10000n) / total_liquidity;
// Result in basis points (8000 = 80%)
```

### PnL Calculation

```typescript
// Long
const pnl = size * (current_price - entry_price) / entry_price;

// Short
const pnl = size * (entry_price - current_price) / entry_price;
```

## 🎯 Testing Strategy

### 1. Unit Tests

Test individual functions:
- ✅ Fee calculations
- ✅ Validation logic
- ✅ State updates
- ✅ Edge cases

### 2. Integration Tests

Test full flows:
- 🔄 Open position → Close position
- 🔄 Add liquidity → Remove liquidity
- 🔄 Position → Liquidation

### 3. Manual Testing

1. Deploy contracts to Preview testnet
2. Update `.env` with contract addresses
3. Run backend server
4. Use Postman or curl to test endpoints
5. Verify on Cardanoscan

## 📝 Example Test Flow

```bash
# 1. Health check
curl http://localhost:3000/health

# 2. Get vault info
curl http://localhost:3000/api/vault

# 3. Open long position
curl -X POST http://localhost:3000/api/position/open-long \
  -H "Content-Type: application/json" \
  -d '{
    "indexToken": {"policyId": "", "assetName": "BTC"},
    "collateral": "1000",
    "leverage": 10,
    "userAddress": "addr_test1..."
  }'

# 4. Get positions
curl http://localhost:3000/api/positions/addr_test1...
```

## 🚨 Common Issues

### Issue: "Vault UTXO not found"

**Solution**: Deploy vault contract first, update `VAULT_ADDRESS` in `.env`

### Issue: "Blockfrost API error"

**Solution**: Check `BLOCKFROST_API_KEY` and `BLOCKFROST_URL` in `.env`

### Issue: "Leverage exceeds maximum"

**Solution**: Reduce leverage or increase `max_leverage` in vault

### Issue: "Utilization exceeds maximum"

**Solution**: Add more liquidity or reduce position size

## 🔒 Security

**⚠️ This is for testing only!**

- Never use mainnet keys in `.env`
- Use Preview/Preprod testnet only
- Keep seed phrases secure
- Don't commit `.env` to git

## 📚 Next Steps

1. **Deploy Contracts**
   ```bash
   cd ../
   aiken build
   # Deploy to Preview testnet
   ```

2. **Update Environment**
   ```bash
   # Add deployed addresses to .env
   VAULT_ADDRESS=addr_test1...
   POSITION_ADDRESS=addr_test1...
   ORACLE_ADDRESS=addr_test1...
   ```

3. **Test Flow**
   ```bash
   npm run dev
   # Use API endpoints to test
   ```

4. **Add Features**
   - UTXO Indexer (PostgreSQL)
   - WebSocket for real-time updates
   - Liquidation bot
   - Oracle price updater

## 🤝 Contributing

See main [CONTRIBUTING.md](../CONTRIBUTING.md)

## 📄 License

Apache-2.0

---

**Built with:**
- TypeScript
- Lucid (Cardano library)
- Express (API server)
- Vitest (Testing)

