// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Vault-specific utility functions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

use aiken/list
use baobabx_gmx/types.{AssetClass}
use baobabx_gmx/constants.{basis_points_divisor, funding_rate_precision}
use baobabx_gmx/common.{calculate_fee}

/// Get AUM (Assets Under Management) for stablecoin vault
pub fn get_aum(
  total_liquidity: Int,
  reserved_amounts: List<(AssetClass, Int)>,
) -> Int {
  // For stablecoin vault: AUM = total liquidity
  // We assume stablecoin is always worth $1
  total_liquidity
}

/// Calculate GLP to mint when adding liquidity
pub fn calculate_glp_mint(
  stablecoin_amount: Int,
  total_liquidity: Int,
  glp_supply: Int,
  mint_fee_bp: Int,
) -> Int {
  let after_fee = stablecoin_amount - calculate_fee(stablecoin_amount, mint_fee_bp)
  
  if glp_supply == 0 {
    // First deposit: 1:1 ratio
    after_fee
  } else {
    // Subsequent deposits: proportional to pool share
    after_fee * glp_supply / total_liquidity
  }
}

/// Calculate stablecoin to return when burning GLP
pub fn calculate_stablecoin_redeem(
  glp_amount: Int,
  total_liquidity: Int,
  glp_supply: Int,
  burn_fee_bp: Int,
) -> Int {
  // Calculate proportional stablecoin
  let stablecoin = glp_amount * total_liquidity / glp_supply
  
  // Apply burn fee
  stablecoin - calculate_fee(stablecoin, burn_fee_bp)
}

/// Check if pool has enough available liquidity
pub fn has_sufficient_liquidity(
  total_liquidity: Int,
  reserved_amount: Int,
  required_amount: Int,
) -> Bool {
  let available = total_liquidity - reserved_amount
  available >= required_amount
}

/// Calculate pool utilization rate (in basis points)
pub fn calculate_utilization_rate(total_liquidity: Int, reserved_amount: Int) -> Int {
  if total_liquidity == 0 {
    0
  } else {
    // Return as basis points (10000 = 100%)
    reserved_amount * basis_points_divisor / total_liquidity
  }
}

/// Calculate funding rate for a specific token
pub fn calculate_funding_rate_for_token(
  open_interest_long: Int,
  open_interest_short: Int,
  time_delta: Int,  // Time elapsed in milliseconds
  funding_rate_factor: Int,  // Base funding rate
) -> Int {
  let total_open_interest = open_interest_long + open_interest_short
  
  if total_open_interest == 0 {
    0
  } else {
    // imbalance = (long - short) / (long + short)
    // funding_rate = imbalance * time_delta * factor
    let imbalance = open_interest_long - open_interest_short
    imbalance * time_delta * funding_rate_factor / total_open_interest / funding_rate_precision
  }
}

/// Get cumulative funding rate for a specific token
pub fn get_cumulative_funding_rate(
  funding_rates: List<(AssetClass, Int)>,
  token: AssetClass,
) -> Int {
  when
    list.find(
      funding_rates,
      fn(entry) {
        let (t, _rate) = entry
        t.policy_id == token.policy_id && t.asset_name == token.asset_name
      },
    )
  is {
    Some((_t, rate)) -> rate
    None -> 0
  }
}

