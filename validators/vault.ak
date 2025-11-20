use aiken/transaction.{ScriptContext, Spend, InlineDatum}
use aiken/transaction/value
use aiken/list
use baobabx_gmx/types.{
  VaultDatum, VaultRedeemer, AssetClass, AddLiquidity, RemoveLiquidity,
  IncreasePosition, DecreasePosition, LiquidatePosition, UpdateFees, UpdateFundingRate,
}
use baobabx_gmx/utils

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
  // Validate inputs
  let valid_amounts = collateral_delta > 0 && size_delta > 0
  
  // TODO: Get index token price from oracle
  
  // TODO: Calculate leverage
  // leverage = size_delta / collateral_delta
  // Verify: leverage <= max_leverage
  
  // TODO: Calculate margin fee
  let margin_fee = utils.get_position_fee(size_delta, datum.margin_fee_basis_points)
  
  // TODO: Verify user deposited collateral_delta + margin_fee in stablecoin
  
  // TODO: Update or create position datum
  // If position exists: add to existing
  // If new: create new position UTXO
  
  // TODO: Update vault state:
  // - Increase reserved_amount by collateral_delta
  // - Increase open_interest_long or open_interest_short by size_delta
  // - If short: increase guaranteed_usd
  
  // TODO: Check utilization is not too high
  // utilization = reserved_amount / total_liquidity
  // Should be < 100%
  
  valid_amounts
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
  let margin_fee = utils.get_position_fee(size_delta, datum.margin_fee_basis_points)
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
  // Use utils.validate_liquidation
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
  // Verify admin signature
  let has_admin_sig =
    list.any(
      ctx.transaction.extra_signatories,
      fn(sig) { sig == datum.admin },
    )
  
  // TODO: Verify new fees are within acceptable ranges
  // mint_burn_fee_basis_points <= max_fee (e.g., 500 = 5%)
  // margin_fee_basis_points <= max_fee
  
  // TODO: Update vault datum with new fees
  
  has_admin_sig
}

/// Validate funding rate update
fn validate_update_funding_rate(datum: VaultDatum, ctx: ScriptContext) -> Bool {
  // Anyone can call this (permissionless funding rate updates)
  // or restrict to admin/keeper if preferred
  
  // TODO: Calculate time elapsed since last update
  // time_delta = current_time - last_funding_time
  
  // TODO: Calculate funding rate based on open interest imbalance
  // If open_interest_long > open_interest_short:
  //   - Longs pay shorts (positive funding rate for longs)
  // If open_interest_short > open_interest_long:
  //   - Shorts pay longs (negative funding rate for longs)
  // 
  // funding_rate = (open_interest_long - open_interest_short) 
  //                / (open_interest_long + open_interest_short)
  //                * time_delta * funding_rate_factor
  
  // TODO: Update vault datum:
  // - Update cumulative_funding_rate_long
  // - Update cumulative_funding_rate_short
  // - Update last_funding_time
  
  True
}
