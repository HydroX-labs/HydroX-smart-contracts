# Implementation Guide

이 문서는 스마트 컨트랙트의 실제 구현 세부사항을 다룹니다.

## Code Structure

```
baobabX-smart-contracts/
├── lib/
│   ├── types.ak          # Type definitions
│   └── utils.ak          # Utility functions
└── validators/
    ├── vault.ak          # Vault validator
    ├── position.ak       # Position validator
    └── oracle.ak         # Oracle validator
```

## Key Type Definitions

### VaultDatum

```aiken
// lib/types.ak
pub type VaultDatum {
  // Single stablecoin
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
  
  // Whitelist and limits
  whitelisted_tokens: List<AssetClass>,
  max_utilization: List<(AssetClass, Int)>,
  
  // Parameters
  admin: Hash<Blake2b_224, VerificationKey>,
  mint_burn_fee_basis_points: Int,
  margin_fee_basis_points: Int,
  liquidation_fee_usd: Int,
  min_profit_time: Int,
  max_leverage: Int,
}
```

### Position

```aiken
pub type Position {
  owner: Hash<Blake2b_224, VerificationKey>,
  index_token: AssetClass,
  position_type: PositionType,
  size: Int,
  collateral: Int,
  average_price: Int,
  entry_funding_rate: Int,
  last_increased_time: Int,
}
```

## Utility Functions

### PnL Calculation

```aiken
// lib/utils.ak

/// Calculate PnL for long position
pub fn calculate_long_pnl(
  size: Int,
  entry_price: Int,
  current_price: Int,
) -> (Bool, Int) {
  if current_price >= entry_price {
    let pnl = size * (current_price - entry_price) / entry_price
    (True, pnl)  // Profit
  } else {
    let pnl = size * (entry_price - current_price) / entry_price
    (False, pnl)  // Loss
  }
}

/// Calculate PnL for short position
pub fn calculate_short_pnl(
  size: Int,
  entry_price: Int,
  current_price: Int,
) -> (Bool, Int) {
  if entry_price >= current_price {
    let pnl = size * (entry_price - current_price) / entry_price
    (True, pnl)  // Profit
  } else {
    let pnl = size * (current_price - entry_price) / entry_price
    (False, pnl)  // Loss
  }
}
```

### Liquidation Validation

```aiken
/// Check if position should be liquidated
pub fn validate_liquidation(
  position_size: Int,
  position_collateral: Int,
  margin_fees: Int,
  funding_fees: Int,
  has_profit: Bool,
  delta: Int,
  liquidation_fee_usd: Int,
) -> Bool {
  let total_fees = margin_fees + funding_fees + liquidation_fee_usd
  
  if !has_profit && position_collateral < delta {
    True  // Loss exceeds collateral
  } else {
    let remaining = if has_profit {
      position_collateral + delta - total_fees
    } else {
      position_collateral - delta - total_fees
    }
    
    if remaining <= 0 {
      True
    } else {
      // Check if below 1% collateral ratio
      remaining * 10000 / position_size < 100
    }
  }
}
```

### Token-Specific Helpers

```aiken
/// Get value for specific token
pub fn get_for_token(
  list_data: List<(AssetClass, Int)>,
  token: AssetClass,
) -> Int {
  when list.find(list_data, fn(entry) {
    let (t, _) = entry
    t.policy_id == token.policy_id && 
    t.asset_name == token.asset_name
  }) is {
    Some((_, value)) -> value
    None -> 0
  }
}

/// Update value for specific token
pub fn update_token_entry(
  list_data: List<(AssetClass, Int)>,
  token: AssetClass,
  new_value: Int,
) -> List<(AssetClass, Int)> {
  // Check if exists
  let exists = list.any(list_data, fn(entry) {
    let (t, _) = entry
    t.policy_id == token.policy_id && 
    t.asset_name == token.asset_name
  })
  
  if exists {
    // Update
    list.map(list_data, fn(entry) {
      let (t, value) = entry
      if t.policy_id == token.policy_id && 
         t.asset_name == token.asset_name {
        (t, new_value)
      } else {
        entry
      }
    })
  } else {
    // Add new
    list.concat(list_data, [(token, new_value)])
  }
}
```

## Vault Validator

### Main Validator

```aiken
// validators/vault.ak

validator {
  fn vault(
    datum: VaultDatum, 
    redeemer: VaultRedeemer, 
    ctx: ScriptContext
  ) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        when redeemer is {
          AddLiquidity { amount } ->
            validate_add_liquidity(datum, amount, ctx)
          
          RemoveLiquidity { glp_amount } ->
            validate_remove_liquidity(datum, glp_amount, ctx)
          
          IncreasePosition { account, index_token, 
                            collateral_delta, size_delta, is_long } ->
            validate_increase_position(
              datum, account, index_token,
              collateral_delta, size_delta, is_long, ctx
            )
          
          // ... other redeemers
        }
      }
      _ -> False
    }
  }
}
```

### Increase Position Validation

```aiken
fn validate_increase_position(
  datum: VaultDatum,
  account: ByteArray,
  index_token: AssetClass,
  collateral_delta: Int,
  size_delta: Int,
  is_long: Bool,
  ctx: ScriptContext,
) -> Bool {
  // 1. Basic validation
  let valid_amounts = collateral_delta > 0 && size_delta > 0
  
  // 2. Check whitelisted
  let is_whitelisted = list.any(
    datum.whitelisted_tokens,
    fn(t) { t == index_token }
  )
  
  // 3. Check leverage
  let leverage = size_delta / collateral_delta
  let valid_leverage = leverage <= datum.max_leverage
  
  // 4. Check utilization
  let current_reserved = 
    get_for_token(datum.reserved_amounts, index_token)
  let new_reserved = current_reserved + collateral_delta
  let utilization = new_reserved * 10000 / datum.total_liquidity
  let max_util = get_for_token(datum.max_utilization, index_token)
  let valid_utilization = utilization <= max_util
  
  // 5. Verify state updates
  // ... (check new vault datum, position created, etc.)
  
  valid_amounts && is_whitelisted && 
  valid_leverage && valid_utilization
}
```

## Position Validator

```aiken
// validators/position.ak

validator {
  fn position(
    datum: PositionDatum,
    redeemer: PositionRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        when redeemer is {
          ClosePosition ->
            validate_close_position(datum, ctx)
          
          UpdatePosition ->
            validate_update_position(datum, ctx)
        }
      }
      _ -> False
    }
  }
}

fn validate_close_position(
  datum: PositionDatum, 
  ctx: ScriptContext
) -> Bool {
  // 1. Owner signature
  let has_owner_sig = list.any(
    ctx.transaction.extra_signatories,
    fn(sig) { sig == datum.position.owner }
  )
  
  // 2. Vault spent
  let vault_spent = verify_vault_spent(ctx, datum.vault_ref)
  
  // 3. No continuing position
  let position_closed = !has_continuing_position_output(ctx)
  
  has_owner_sig && vault_spent && position_closed
}
```

## Oracle Validator

```aiken
// validators/oracle.ak

validator {
  fn oracle(
    datum: OracleDatum,
    redeemer: OracleRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        when redeemer is {
          UpdatePrices { new_prices } ->
            validate_update_prices(datum, new_prices, ctx)
          
          UpdateAdmin { new_admin } ->
            validate_update_admin(datum, new_admin, ctx)
        }
      }
      _ -> False
    }
  }
}
```

## Testing Strategy

### Unit Tests

```aiken
test calculate_fee_correct() {
  let amount = 1000000
  let fee_bp = 30  // 0.3%
  let fee = calculate_fee(amount, fee_bp)
  fee == 3000
}

test liquidation_underwater() {
  let should_liquidate = validate_liquidation(
    position_size: 10000,
    position_collateral: 1000,
    margin_fees: 100,
    funding_fees: 50,
    has_profit: False,
    delta: 1200,  // Loss > collateral
    liquidation_fee_usd: 10
  )
  should_liquidate == True
}
```

### Integration Tests

실제 트랜잭션 테스트:
1. Add liquidity flow
2. Open position flow
3. Close position flow
4. Liquidation flow

## Best Practices

### 1. Precision Handling

```aiken
// Always use 1e30 for USD values
const price_precision = 1_000_000_000_000_000_000_000_000_000_000

// Use basis points for percentages
const basis_points_divisor = 10000
```

### 2. State Validation

```aiken
// Always verify:
// - Token whitelisted
// - Amounts positive
// - Leverage within limits
// - Utilization within bounds
// - Correct fees paid
```

### 3. Error Handling

```aiken
// Return Bool, don't panic
// Let transaction fail gracefully
```

## Security Considerations

### Critical Checks

1. **Owner verification**: Always check signatures
2. **Amount validation**: Positive, non-zero
3. **Token whitelist**: Only allowed tokens
4. **Leverage limits**: Enforce max_leverage
5. **Utilization limits**: Per-token max_utilization
6. **Fee calculation**: Correct and consistent
7. **State transitions**: Valid vault updates

### Attack Vectors

1. **Reentrancy**: Not applicable (eUTXO)
2. **Front-running**: Possible, use slippage protection
3. **Oracle manipulation**: Use multiple sources
4. **Flash loans**: Not directly applicable
5. **Integer overflow**: Aiken handles this

## Deployment

### Testnet Deployment

```bash
# 1. Build contracts
aiken build

# 2. Generate addresses
aiken blueprint apply ...

# 3. Deploy to Preview
cardano-cli transaction build ...

# 4. Test thoroughly
```

### Mainnet Deployment

1. **Audit**: Multiple independent audits
2. **Bug bounty**: Incentivize white-hats
3. **Gradual rollout**: Start with limits
4. **Monitoring**: 24/7 monitoring
5. **Emergency pause**: Admin functions

## Next Steps

더 자세한 내용:

- **실제 코드**: `../lib/` and `../validators/`
- **Off-chain**: [Off-chain Services](offchain-services.md)
- **비교**: [GMX Comparison](06-comparison.md)

---

[← Back to Core Logic](03-core-logic.md) | [Back to Index](README.md)

