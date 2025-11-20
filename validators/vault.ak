use aiken/transaction.{ScriptContext, Spend, InlineDatum}
use aiken/transaction/value
use aiken/list
use baobabx_gmx/types.{
  VaultDatum, VaultRedeemer, AssetClass, AddLiquidity, RemoveLiquidity,
  IncreasePosition, DecreasePosition, LiquidatePosition, Swap, PriceData,
}
use baobabx_gmx/utils

/// Vault validator - manages liquidity pool and positions
validator {
  fn vault(datum: VaultDatum, redeemer: VaultRedeemer, ctx: ScriptContext) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        when redeemer is {
          AddLiquidity { token, amount } -> {
            validate_add_liquidity(datum, token, amount, ctx)
          }
          
          RemoveLiquidity { glp_amount, token_out } -> {
            validate_remove_liquidity(datum, glp_amount, token_out, ctx)
          }
          
          IncreasePosition { account, collateral_token, index_token, size_delta, is_long } -> {
            validate_increase_position(
              datum,
              account,
              collateral_token,
              index_token,
              size_delta,
              is_long,
              ctx,
            )
          }
          
          DecreasePosition { account, collateral_token, index_token, collateral_delta, size_delta, is_long } -> {
            validate_decrease_position(
              datum,
              account,
              collateral_token,
              index_token,
              collateral_delta,
              size_delta,
              is_long,
              ctx,
            )
          }
          
          LiquidatePosition { account, collateral_token, index_token, is_long } -> {
            validate_liquidate_position(
              datum,
              account,
              collateral_token,
              index_token,
              is_long,
              ctx,
            )
          }
          
          Swap { token_in, token_out, receiver } -> {
            validate_swap(datum, token_in, token_out, receiver, ctx)
          }
          
          UpdateFees -> {
            validate_update_fees(datum, ctx)
          }
          
          AddWhitelistedToken { token } -> {
            validate_add_whitelisted_token(datum, token, ctx)
          }
        }
      }
      _ -> False
    }
  }
}

/// Validate add liquidity operation
fn validate_add_liquidity(
  datum: VaultDatum,
  token: AssetClass,
  amount: Int,
  ctx: ScriptContext,
) -> Bool {
  // Check token is whitelisted
  let is_whitelisted =
    list.any(
      datum.whitelisted_tokens,
      fn(t) { t.policy_id == token.policy_id && t.asset_name == token.asset_name },
    )
  
  // TODO: Calculate GLP to mint based on AUM
  // TODO: Verify correct amount of tokens deposited
  // TODO: Mint GLP tokens to user
  // TODO: Update vault state
  
  is_whitelisted
}

/// Validate remove liquidity operation
fn validate_remove_liquidity(
  datum: VaultDatum,
  glp_amount: Int,
  token_out: AssetClass,
  ctx: ScriptContext,
) -> Bool {
  // TODO: Calculate tokens to return based on AUM and GLP supply
  // TODO: Burn GLP tokens
  // TODO: Transfer tokens to user
  // TODO: Update vault state
  
  True
}

/// Validate increase position
fn validate_increase_position(
  datum: VaultDatum,
  account: ByteArray,
  collateral_token: AssetClass,
  index_token: AssetClass,
  size_delta: Int,
  is_long: Bool,
  ctx: ScriptContext,
) -> Bool {
  // Check tokens are whitelisted
  let collateral_whitelisted =
    list.any(
      datum.whitelisted_tokens,
      fn(t) {
        t.policy_id == collateral_token.policy_id && t.asset_name == collateral_token.asset_name
      },
    )
  
  let index_whitelisted =
    list.any(
      datum.whitelisted_tokens,
      fn(t) {
        t.policy_id == index_token.policy_id && t.asset_name == index_token.asset_name
      },
    )
  
  // TODO: Get prices from oracle
  // TODO: Calculate fees
  // TODO: Validate collateral
  // TODO: Update position datum
  // TODO: Update vault reserves
  
  collateral_whitelisted && index_whitelisted && size_delta > 0
}

/// Validate decrease position
fn validate_decrease_position(
  datum: VaultDatum,
  account: ByteArray,
  collateral_token: AssetClass,
  index_token: AssetClass,
  collateral_delta: Int,
  size_delta: Int,
  is_long: Bool,
  ctx: ScriptContext,
) -> Bool {
  // TODO: Load position datum
  // TODO: Verify account owns position
  // TODO: Get prices from oracle
  // TODO: Calculate PnL
  // TODO: Calculate and deduct fees
  // TODO: Transfer collateral and profit to user
  // TODO: Update or close position
  // TODO: Update vault reserves
  
  True
}

/// Validate liquidation
fn validate_liquidate_position(
  datum: VaultDatum,
  account: ByteArray,
  collateral_token: AssetClass,
  index_token: AssetClass,
  is_long: Bool,
  ctx: ScriptContext,
) -> Bool {
  // TODO: Load position datum
  // TODO: Get current price
  // TODO: Calculate position PnL and fees
  // TODO: Verify position should be liquidated
  // TODO: Transfer liquidation fee to liquidator
  // TODO: Close position and update vault
  
  True
}

/// Validate swap operation
fn validate_swap(
  datum: VaultDatum,
  token_in: AssetClass,
  token_out: AssetClass,
  receiver: ByteArray,
  ctx: ScriptContext,
) -> Bool {
  // Check both tokens are whitelisted
  let token_in_whitelisted =
    list.any(
      datum.whitelisted_tokens,
      fn(t) { t.policy_id == token_in.policy_id && t.asset_name == token_in.asset_name },
    )
  
  let token_out_whitelisted =
    list.any(
      datum.whitelisted_tokens,
      fn(t) { t.policy_id == token_out.policy_id && t.asset_name == token_out.asset_name },
    )
  
  // TODO: Get prices from oracle
  // TODO: Calculate swap amount and fees
  // TODO: Verify sufficient pool liquidity
  // TODO: Transfer tokens
  // TODO: Update pool amounts
  
  token_in_whitelisted && token_out_whitelisted
}

/// Validate fee update (admin only)
fn validate_update_fees(datum: VaultDatum, ctx: ScriptContext) -> Bool {
  // TODO: Verify admin signature
  // TODO: Validate new fees are within acceptable ranges
  // TODO: Update vault datum with new fees
  
  True
}

/// Validate adding whitelisted token (admin only)
fn validate_add_whitelisted_token(
  datum: VaultDatum,
  token: AssetClass,
  ctx: ScriptContext,
) -> Bool {
  // TODO: Verify admin signature
  // TODO: Add token to whitelist
  // TODO: Initialize token parameters
  
  True
}

