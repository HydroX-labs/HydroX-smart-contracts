# GMX v1 Comparison

## Feature Comparison

| Feature | GMX v1 (Ethereum) | HydroX (Cardano) | Notes |
|---------|-------------------|-------------------|-------|
| **Core Concept** |
| Single liquidity pool | ✅ | ✅ | Same |
| Multi-asset positions | ✅ | ✅ | Same |
| Leverage trading | ✅ Max 50x | ✅ Configurable | Same |
| Long/Short | ✅ | ✅ | Same |
| **Collateral** |
| Multiple collaterals | ✅ ETH, BTC, USDC | ❌ Stablecoin only | Simplified |
| Swap between collaterals | ✅ | ❌ Not needed | N/A |
| **Liquidity** |
| LP token | ✅ GLP (ERC-20) | ✅ GLP (Native) | Better |
| Add liquidity | ✅ | ✅ | Same |
| Remove liquidity | ✅ | ✅ | Same |
| Fee distribution | ✅ | ✅ | Same |
| **Trading** |
| Position open/close | ✅ | ✅ | Same |
| Partial close | ✅ | ✅ (Planned) | Same |
| Stop loss/take profit | ✅ | ⏳ Future | Not yet |
| Liquidations | ✅ | ✅ | Same |
| **Funding Rate** |
| Per-token funding | ✅ | ✅ | Same |
| Dynamic rates | ✅ | ✅ | Same |
| **Technical** |
| State model | Account-based | eUTXO-based | Different |
| Execution | Sequential | Parallel possible | Better |
| Predictability | Low | High | Better |
| Fees | Variable, high | Predictable, low | Better |
| **Decentralization** |
| Price oracle | Chainlink | Custom/planned | Similar |
| Governance | DAO | Admin (DAO planned) | Similar |
| Keepers | Decentralized | Permissionless | Same |

## Architectural Differences

### State Management

**GMX v1 (Ethereum):**
```solidity
contract Vault {
  mapping(address => uint256) public tokenBalances;
  mapping(bytes32 => Position) public positions;
  
  function increasePosition(...) external {
    // Read state
    uint256 balance = tokenBalances[token];
    
    // Modify state
    tokenBalances[token] = newBalance;
    positions[key] = newPosition;
    
    emit IncreasePosition(...);
  }
}
```

**HydroX (Cardano):**
```aiken
validator vault {
  fn increase_position(...) -> Bool {
    // Input: Old Vault UTXO
    // Output: New Vault UTXO
    // Output: New Position UTXO
    
    // Validate transition
    // No direct mutation!
    True/False
  }
}
```

### Execution Flow

**GMX v1:**
```
User → TX → Mempool → Miner → EVM → State Change
                                ↑
                          Unknown cost
                          Can fail
```

**HydroX:**
```
User → Backend → Build → Validate → Sign → Submit → Validator
                   ↑                                    ↑
              Know everything                    Just verify
              Fail before payment                Deterministic
```

## Advantages of Cardano

### 1. Predictability

```
Ethereum:
  ❌ Submit → Unknown gas → May fail → Lost gas
  
Cardano:
  ✅ Build → Know outcome → Submit
  ✅ Fees known upfront
  ✅ No surprise failures
```

### 2. Parallelization

```
Ethereum:
  ❌ One transaction at a time
  ❌ Sequential execution
  
Cardano:
  ✅ Multiple positions simultaneously
  ✅ Different UTXOs = no conflicts
  ✅ Higher throughput
```

### 3. Determinism

```
Ethereum:
  ❌ State can change during execution
  ❌ Hidden dependencies
  
Cardano:
  ✅ Same inputs → Same outputs
  ✅ No hidden state
  ✅ Clear causality
```

### 4. Native Tokens

```
Ethereum:
  ❌ GLP = ERC-20 contract
  ❌ Extra gas for transfers
  
Cardano:
  ✅ GLP = Native token
  ✅ No contract calls
  ✅ More efficient
```

### 5. Lower Fees

```
Ethereum:
  Position open: ~$50-200
  Position close: ~$50-200
  Liquidation: ~$100-300
  
Cardano:
  Position open: ~$0.50
  Position close: ~$0.50
  Liquidation: ~$1
```

## Challenges and Trade-offs

### 1. Complexity

**Ethereum:**
```typescript
// Simple!
await vault.increasePosition(token, amount, size);
```

**Cardano:**
```typescript
// Complex!
const vaultUtxo = await findVault();
const newDatum = calculateNewState();
const tx = buildTransaction();
await validate();
await sign();
await submit();
```

### 2. Tooling

**Ethereum:**
- ✅ Mature ecosystem
- ✅ Many examples
- ✅ Large community
- ✅ Lots of libraries

**Cardano:**
- ⚠️ Newer ecosystem
- ⚠️ Fewer examples
- ⚠️ Smaller community
- ⚠️ Growing libraries

### 3. UTXO Contention

**Problem:**
```
User A: Want to use Vault UTXO
User B: Want to use Vault UTXO (same time!)
→ One will fail (UTXO already spent)
```

**Solutions:**
- Queue system
- Retry logic
- Multiple vault UTXOs (advanced)

### 4. Off-chain Requirements

**Ethereum:**
```
Frontend → Ethereum RPC → Done
```

**Cardano:**
```
Frontend → Backend API → UTXO Indexer → PostgreSQL
                      → Transaction Builder
                      → Blockfrost API
                      → Done
```

More infrastructure needed!

## Why Choose Cardano?

### For Users

1. **Lower fees**: ~100x cheaper
2. **Predictability**: Know outcome before paying
3. **Speed**: Parallel execution
4. **Security**: Formal verification possible

### For Developers

1. **Aiken**: Better DX than Plutus
2. **Determinism**: Easier debugging
3. **Composability**: Clear UTXO flow
4. **Innovation**: New design space

### For the Protocol

1. **Efficiency**: Lower operating costs
2. **Scalability**: Parallel positions
3. **Security**: eUTXO guarantees
4. **Future-proof**: Growing ecosystem

## Comparison Summary

### What's the Same?

- ✅ Single stablecoin pool
- ✅ Multi-asset positions
- ✅ Leverage trading
- ✅ Funding rates
- ✅ Liquidations
- ✅ GLP tokens

### What's Different?

- 🔄 eUTXO vs Account model
- 🔄 Native tokens vs ERC-20
- 🔄 Parallel vs Sequential
- 🔄 Predictable vs Variable fees
- 🔄 Stablecoin-only vs Multi-collateral

### What's Better?

- ✅ Lower fees
- ✅ Predictability
- ✅ Parallelization
- ✅ Determinism

### What's Challenging?

- ⚠️ More complex off-chain
- ⚠️ UTXO contention
- ⚠️ Smaller ecosystem
- ⚠️ Steeper learning curve

## Conclusion

HydroX brings GMX v1's innovation to Cardano with:

**Same core mechanics:**
- Single pool, multi-asset
- Leverage trading
- GLP liquidity tokens

**Cardano advantages:**
- Lower fees
- Better predictability
- Parallel execution

**Simplified design:**
- Stablecoin-only (vs multi-collateral)
- Clearer risk management
- Easier to understand

**Trade-offs:**
- More complex off-chain infrastructure
- Smaller ecosystem (for now)
- Different development model

The result: A powerful perpetual futures exchange that leverages Cardano's unique strengths!

---

[← Back to Implementation](04-implementation.md) | [Back to Index](README.md)

