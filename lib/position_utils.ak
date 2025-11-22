// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Position-specific utility functions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

use baobabx_gmx/constants.{basis_points_divisor, funding_rate_precision, min_collateral_ratio_bps}
use baobabx_gmx/common.{calculate_fee}

/// Calculate PnL for long position
/// Returns: (has_profit: Bool, pnl_amount: Int)
pub fn calculate_long_pnl(
  size: Int,
  entry_price: Int,
  current_price: Int,
) -> (Bool, Int) {
  if current_price >= entry_price {
    // Profit
    let pnl = size * (current_price - entry_price) / entry_price
    (True, pnl)
  } else {
    // Loss
    let pnl = size * (entry_price - current_price) / entry_price
    (False, pnl)
  }
}

/// Calculate PnL for short position
/// Returns: (has_profit: Bool, pnl_amount: Int)
pub fn calculate_short_pnl(
  size: Int,
  entry_price: Int,
  current_price: Int,
) -> (Bool, Int) {
  if entry_price >= current_price {
    // Profit
    let pnl = size * (entry_price - current_price) / entry_price
    (True, pnl)
  } else {
    // Loss
    let pnl = size * (current_price - entry_price) / entry_price
    (False, pnl)
  }
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
      size * funding_rate / funding_rate_precision
    }
  }
}

/// Validate if position should be liquidated
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
    size / collateral
  }
}

/// Validate leverage is within limits
pub fn validate_leverage(size: Int, collateral: Int, max_leverage: Int) -> Bool {
  let leverage = calculate_leverage(size, collateral)
  leverage > 0 && leverage <= max_leverage
}

