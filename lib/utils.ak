use aiken/list
use aiken/math
use baobabx_gmx/types.{AssetClass, PriceData}

/// Constants
pub const basis_points_divisor = 10000

pub const price_precision = 1_000_000_000_000_000_000_000_000_000_000  // 1e30

pub const funding_rate_precision = 1_000_000

pub const max_fee_basis_points = 500  // 5%

pub const max_liquidation_fee_usd = 100_000_000_000_000_000_000_000_000_000_000  // $100 in 1e30

/// Minimum collateral ratio (1% = 100 basis points)
pub const min_collateral_ratio_bps = 100  // 1%

/// Calculate fee amount based on basis points
pub fn calculate_fee(amount: Int, fee_basis_points: Int) -> Int {
  amount * fee_basis_points / basis_points_divisor
}

/// Get AUM (Assets Under Management) for stablecoin vault
/// AUM = total_liquidity + pending_pnl
pub fn get_aum(
  total_liquidity: Int,
  open_interest_long: Int,
  open_interest_short: Int,
  guaranteed_usd: Int,
) -> Int {
  // For stablecoin vault:
  // AUM = stablecoin_liquidity
  // We assume stablecoin is always worth $1
  // Pending profits/losses affect AUM but are harder to calculate without prices
  // Simplified: just use total liquidity
  total_liquidity
}

/// Calculate GLP to mint when adding liquidity
pub fn calculate_glp_mint(
  stablecoin_amount: Int,
  total_liquidity: Int,
  glp_supply: Int,
  mint_fee_bp: Int,
) -> Int {
  // Apply mint fee
  let after_fee = stablecoin_amount - calculate_fee(stablecoin_amount, mint_fee_bp)
  
  if glp_supply == 0 {
    // First deposit: 1:1 ratio
    after_fee
  } else {
    // Subsequent deposits: proportional to pool share
    // glp = (stablecoin_amount * glp_supply) / total_liquidity
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

/// Calculate position PnL for long position
pub fn calculate_long_pnl(
  size: Int,
  entry_price: Int,
  current_price: Int,
) -> (Bool, Int) {
  // PnL = size * (current_price - entry_price) / entry_price
  if current_price >= entry_price {
    // Profit
    let pnl = size * ( current_price - entry_price ) / entry_price
    (True, pnl)
  } else {
    // Loss
    let pnl = size * ( entry_price - current_price ) / entry_price
    (False, pnl)
  }
}

/// Calculate position PnL for short position
pub fn calculate_short_pnl(
  size: Int,
  entry_price: Int,
  current_price: Int,
) -> (Bool, Int) {
  // PnL = size * (entry_price - current_price) / entry_price
  if entry_price >= current_price {
    // Profit
    let pnl = size * ( entry_price - current_price ) / entry_price
    (True, pnl)
  } else {
    // Loss
    let pnl = size * ( current_price - entry_price ) / entry_price
    (False, pnl)
  }
}

/// Find price for a token from oracle data
pub fn find_price(prices: List<PriceData>, token: AssetClass) -> Option<PriceData> {
  list.find(
    prices,
    fn(price_data) {
      price_data.token.policy_id == token.policy_id && price_data.token.asset_name == token.asset_name
    },
  )
}

/// Calculate position fee (margin fee)
pub fn get_position_fee(size_delta: Int, margin_fee_basis_points: Int) -> Int {
  if size_delta == 0 {
    0
  } else {
    calculate_fee(size_delta, margin_fee_basis_points)
  }
}

/// Calculate funding fee
pub fn get_funding_fee(
  size: Int,
  entry_funding_rate: Int,
  cumulative_funding_rate: Int,
) -> Int {
  if size == 0 {
    0
  } else {
    let funding_rate = cumulative_funding_rate - entry_funding_rate
    if funding_rate == 0 {
      0
    } else {
      // funding_fee = size * funding_rate / precision
      size * funding_rate / funding_rate_precision
    }
  }
}

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
    // Loss exceeds collateral - definitely liquidatable
    True
  } else {
    // Calculate remaining collateral after PnL and fees
    let remaining_collateral =
      if has_profit {
        position_collateral + delta - total_fees
      } else {
        position_collateral - delta - total_fees
      }
    
    // Check if collateral ratio is below minimum
    // collateral_ratio = remaining_collateral / position_size
    if remaining_collateral <= 0 {
      True
    } else {
      // Check minimum collateral ratio (e.g., 1%)
      remaining_collateral * basis_points_divisor < position_size * min_collateral_ratio_bps
    }
  }
}

/// Calculate leverage of a position
pub fn calculate_leverage(size: Int, collateral: Int) -> Int {
  if collateral == 0 {
    0
  } else {
    // leverage = size / collateral
    // Return as integer (e.g., 10 for 10x)
    size / collateral
  }
}

/// Validate leverage is within limits
pub fn validate_leverage(size: Int, collateral: Int, max_leverage: Int) -> Bool {
  let leverage = calculate_leverage(size, collateral)
  leverage > 0 && leverage <= max_leverage
}

/// Calculate funding rate based on open interest imbalance
pub fn calculate_funding_rate(
  open_interest_long: Int,
  open_interest_short: Int,
  time_delta: Int,  // Time elapsed in milliseconds
  funding_rate_factor: Int,  // Base funding rate (e.g., 0.01% per hour)
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

/// Check if pool has enough available liquidity
pub fn has_sufficient_liquidity(
  total_liquidity: Int,
  reserved_amount: Int,
  required_amount: Int,
) -> Bool {
  let available = total_liquidity - reserved_amount
  available >= required_amount
}

/// Calculate pool utilization rate
pub fn calculate_utilization_rate(total_liquidity: Int, reserved_amount: Int) -> Int {
  if total_liquidity == 0 {
    0
  } else {
    // Return as basis points (10000 = 100%)
    reserved_amount * basis_points_divisor / total_liquidity
  }
}
