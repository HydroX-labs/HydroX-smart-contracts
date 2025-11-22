// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Oracle-specific utility functions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

use aiken/list
use baobabx_gmx/types.{AssetClass, PriceData}

/// Find price data for a specific token
pub fn find_price(
  prices: List<PriceData>,
  token: AssetClass,
) -> Option<PriceData> {
  list.find(
    prices,
    fn(price_data) {
      price_data.token.policy_id == token.policy_id && 
      price_data.token.asset_name == token.asset_name
    },
  )
}

/// Validate price data freshness
pub fn is_price_fresh(price_timestamp: Int, current_time: Int, max_age: Int) -> Bool {
  current_time - price_timestamp <= max_age
}

/// Get price value from PriceData
pub fn get_price_value(price_data: PriceData) -> Int {
  price_data.price
}

