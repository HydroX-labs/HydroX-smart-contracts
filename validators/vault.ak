use aiken/transaction.{ScriptContext, Spend, InlineDatum}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value
use aiken/list
use baobabx_gmx/types.{
  VaultDatum, VaultRedeemer, AssetClass, AddLiquidity, RemoveLiquidity,
  IncreasePosition, DecreasePosition, LiquidatePosition, UpdateFees, UpdateFundingRate,
}
use baobabx_gmx/common
use baobabx_gmx/vault_utils
use baobabx_gmx/position_utils
use baobabx_gmx/constants.{max_fee_basis_points, max_liquidation_fee_usd}

/// Vault validator - manages stablecoin liquidity pool and positions
validator {
  fn vault(datum: VaultDatum, redeemer: VaultRedeemer, ctx: ScriptContext) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        when redeemer is {
          AddLiquidity { amount } -> {
            validate_add_liquidity(datum, amount, ctx)
          }
          
          RemoveLiquidity { glp_amount } -> {
            validate_remove_liquidity(datum, glp_amount, ctx)
          }
          
          IncreasePosition { account, index_token, collateral_delta, size_delta, is_long } -> {
            validate_increase_position(
              datum,
              account,
              index_token,
              collateral_delta,
              size_delta,
              is_long,
              ctx,
            )
          }
          
          DecreasePosition { account, index_token, collateral_delta, size_delta, is_long } -> {
            validate_decrease_position(
              datum,
              account,
              index_token,
              collateral_delta,
              size_delta,
              is_long,
              ctx,
            )
          }
          
          LiquidatePosition { account, index_token, is_long } -> {
            validate_liquidate_position(
              datum,
              account,
              index_token,
              is_long,
              ctx,
            )
          }
          
          UpdateFees -> {
            validate_update_fees(datum, ctx)
          }
          
          UpdateFundingRate -> {
            validate_update_funding_rate(datum, ctx)
          }
        }
      }
      _ -> False
    }
  }
}

/// Validate add liquidity operation (stablecoin deposit)
fn validate_add_liquidity(
  datum: VaultDatum,
  amount: Int,
  ctx: ScriptContext,
) -> Bool {
  // Amount must be positive
  let valid_amount = amount > 0
  
  // TODO: Verify correct amount of stablecoin deposited
  // Check transaction inputs contain user's stablecoin
  
  // TODO: Calculate GLP to mint based on pool value
  // If pool is empty: GLP = amount
  // Otherwise: GLP = amount * glp_supply / total_liquidity
  // Apply mint fee
  
  // TODO: Verify GLP tokens minted to user
  
  // TODO: Update vault state:
  // - Increase total_liquidity by amount
  // - Increase glp_supply
  
  valid_amount
}

/// Validate remove liquidity operation (GLP burn for stablecoin)
fn validate_remove_liquidity(
  datum: VaultDatum,
  glp_amount: Int,
  ctx: ScriptContext,
) -> Bool {
  // GLP amount must be positive
  let valid_amount = glp_amount > 0 && glp_amount <= datum.glp_supply
  
  // TODO: Calculate stablecoin to return based on pool share
  // stablecoin_out = glp_amount * total_liquidity / glp_supply
  // Apply burn fee
  
  // TODO: Verify enough available liquidity (not reserved for positions)
  // available = total_liquidity - reserved_amount
  
  // TODO: Burn GLP tokens from user
  
  // TODO: Transfer stablecoin to user
  
  // TODO: Update vault state:
  // - Decrease total_liquidity
  // - Decrease glp_supply
  
  valid_amount
}

/// Validate increase position (open or add to position)
fn validate_increase_position(
  datum: VaultDatum,
  account: ByteArray,
  index_token: AssetClass,
  collateral_delta: Int,
  size_delta: Int,
  is_long: Bool,
  ctx: ScriptContext,
) -> Bool {
  // 1. Validate inputs
  let valid_amounts = collateral_delta > 0 && size_delta > 0
  
  // 2. Check token is whitelisted
  let is_whitelisted =
    list.any(
      datum.whitelisted_tokens,
      fn(t) {
        t.policy_id == index_token.policy_id && t.asset_name == index_token.asset_name
      },
    )
  
  // 3. Calculate leverage and validate
  let leverage = size_delta / collateral_delta
  let valid_leverage = leverage > 0 && leverage <= datum.max_leverage
  
  // 4. Calculate margin fee
  let margin_fee = position_utils.get_position_fee(size_delta, datum.margin_fee_basis_points)
  
  // 5. Get current reserved amount for this token
  let current_reserved = common.get_reserved_for_token(datum.reserved_amounts, index_token)
  let new_reserved = current_reserved + collateral_delta
  
  // 6. Check token-specific utilization
  // Get max utilization for this token (if not set, use default 80%)
  let max_util =
    when
      list.find(
        datum.max_utilization,
        fn(entry) {
          let (t, _u) = entry
          t.policy_id == index_token.policy_id && t.asset_name == index_token.asset_name
        },
      )
    is {
      Some((_t, util)) -> util
      None -> 8000  // Default 80%
    }
  
  let utilization = new_reserved * 10000 / datum.total_liquidity
  let valid_utilization = utilization <= max_util
  
  // 7. TODO: Verify user deposited collateral_delta + margin_fee in stablecoin
  
  // 8. TODO: Update or create position datum
  
  // 9. TODO: Update vault state (per-token):
  // - Update reserved_amounts for index_token
  // - Update open_interest_long or open_interest_short for index_token
  // - If short: update guaranteed_usd for index_token
  // - Update total_liquidity (add margin_fee)
  
  valid_amounts && is_whitelisted && valid_leverage && valid_utilization
}

/// Validate decrease position (close or reduce position)
fn validate_decrease_position(
  datum: VaultDatum,
  account: ByteArray,
  index_token: AssetClass,
  collateral_delta: Int,
  size_delta: Int,
  is_long: Bool,
  ctx: ScriptContext,
) -> Bool {
  // TODO: Load position datum from inputs
  
  // TODO: Verify account owns position
  
  // TODO: Get current price from oracle
  
  // TODO: Calculate PnL
  // For long: PnL = size * (current_price - entry_price) / entry_price
  // For short: PnL = size * (entry_price - current_price) / entry_price
  
  // TODO: Calculate fees
  let margin_fee = position_utils.get_position_fee(size_delta, datum.margin_fee_basis_points)
  // Calculate funding fee based on time held
  
  // TODO: Calculate payout
  // payout = collateral_delta + PnL - fees
  
  // TODO: Verify position remains healthy if not closing fully
  // remaining_collateral / remaining_size >= min_collateral_ratio
  
  // TODO: Transfer payout to user in stablecoin
  
  // TODO: Update or close position
  // If closing fully: burn position UTXO
  // Otherwise: update position with new values
  
  // TODO: Update vault state:
  // - Decrease reserved_amount
  // - Decrease open_interest
  // - Pay out from total_liquidity
  
  True
}

/// Validate liquidation
fn validate_liquidate_position(
  datum: VaultDatum,
  account: ByteArray,
  index_token: AssetClass,
  is_long: Bool,
  ctx: ScriptContext,
) -> Bool {
  // TODO: Load position datum
  
  // TODO: Get current price from oracle
  
  // TODO: Calculate position PnL and fees
  
  // TODO: Verify position should be liquidated
  // Use position_utils.validate_liquidation
  // Position is liquidatable if:
  // - Losses exceed collateral
  // - Collateral ratio below threshold (e.g., < 1%)
  
  // TODO: Calculate liquidation fee for liquidator
  let liquidation_fee = datum.liquidation_fee_usd
  
  // TODO: Transfer liquidation fee to liquidator
  
  // TODO: Close position and burn position UTXO
  
  // TODO: Update vault state:
  // - Decrease reserved_amount
  // - Decrease open_interest
  // - Adjust total_liquidity based on loss
  
  True
}

/// Validate fee update (admin only)
fn validate_update_fees(datum: VaultDatum, ctx: ScriptContext) -> Bool {
  // 1. Verify admin signature
  let has_admin_sig =
    list.any(
      ctx.transaction.extra_signatories,
      fn(sig) { sig == datum.admin },
    )
  
  // 2. Find output vault UTXO
  expect Some(own_output) =
    list.find(
      ctx.transaction.outputs,
      fn(output) {
        when output.address.payment_credential is {
          ScriptCredential(_) -> True
          _ -> False
        }
      },
    )
  
  // 3. Parse output datum
  expect InlineDatum(output_data) = own_output.datum
  expect output_datum: VaultDatum = output_data
  
  // 4. Verify new fees are within acceptable ranges
  let mint_burn_fee_valid = 
    output_datum.mint_burn_fee_basis_points >= 0 && 
    output_datum.mint_burn_fee_basis_points <= max_fee_basis_points
  
  let margin_fee_valid = 
    output_datum.margin_fee_basis_points >= 0 && 
    output_datum.margin_fee_basis_points <= max_fee_basis_points
  
  let liquidation_fee_valid = 
    output_datum.liquidation_fee_usd > 0 && 
    output_datum.liquidation_fee_usd <= max_liquidation_fee_usd
  
  // 5. Verify other fields remain unchanged
  let liquidity_unchanged = output_datum.total_liquidity == datum.total_liquidity
  let glp_supply_unchanged = output_datum.glp_supply == datum.glp_supply
  let admin_unchanged = output_datum.admin == datum.admin
  
  // All checks must pass
  has_admin_sig &&
  mint_burn_fee_valid &&
  margin_fee_valid &&
  liquidation_fee_valid &&
  liquidity_unchanged &&
  glp_supply_unchanged &&
  admin_unchanged
}

/// Validate funding rate update
fn validate_update_funding_rate(datum: VaultDatum, ctx: ScriptContext) -> Bool {
  // Anyone can call this (permissionless funding rate updates)
  // or restrict to admin/keeper if preferred
  
  // TODO: For each whitelisted token:
  //
  // 1. Get current time
  // let current_time = get_tx_validity_range_start(ctx)
  //
  // 2. Get last funding time for this token
  // let last_time = get_last_funding_time(datum.last_funding_times, token)
  // let time_delta = current_time - last_time
  //
  // 3. Get open interest for this token
  // let oi_long = get_open_interest(datum.open_interest_long, token)
  // let oi_short = get_open_interest(datum.open_interest_short, token)
  //
  // 4. Calculate funding rate for this token
  // funding_rate = calculate_funding_rate(oi_long, oi_short, time_delta, factor)
  //
  // 5. Update cumulative funding rates
  // new_cumulative_long = current + funding_rate
  // new_cumulative_short = current - funding_rate
  //
  // 6. Update vault datum lists:
  // - cumulative_funding_rate_long (per token)
  // - cumulative_funding_rate_short (per token)
  // - last_funding_times (per token)
  
  True
}
