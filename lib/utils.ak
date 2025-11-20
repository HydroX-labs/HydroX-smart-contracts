use aiken/list
use aiken/math
use baobabx_gmx/types.{AssetClass, PriceData}

/// Constants
pub const basis_points_divisor = 10000

pub const price_precision = 1_000_000_000_000_000_000_000_000_000_000  // 1e30

pub const usdg_decimals = 18

pub const funding_rate_precision = 1_000_000

pub const max_fee_basis_points = 500  // 5%

pub const max_liquidation_fee_usd = 100_000_000_000_000_000_000_000_000_000_000  // $100 in 1e30

/// Calculate fee amount based on basis points
pub fn calculate_fee(amount: Int, fee_basis_points: Int) -> Int {
  amount * fee_basis_points / basis_points_divisor
}

/// Get AUM (Assets Under Management) in USD
pub fn get_aum(
  pool_amounts: List<(AssetClass, Int)>,
  reserved_amounts: List<(AssetClass, Int)>,
  guaranteed_usd: List<(AssetClass, Int)>,
  prices: List<PriceData>,
  maximize: Bool,
) -> Int {
  let aum =
    list.foldl(
      pool_amounts,
      0,
      fn(acc, entry) {
        let (token, pool_amount) = entry
        
        when find_price(prices, token) is {
          Some(price_data) -> {
            let price = price_data.price
            let reserved = get_reserved_amount(reserved_amounts, token)
            let token_aum = ( pool_amount - reserved ) * price / price_precision
            acc + token_aum
          }
          None -> acc
        }
      },
    )
  
  // Add short positions profit
  let total_guaranteed =
    list.foldl(guaranteed_usd, 0, fn(acc, entry) {
      let (_token, amount) = entry
      acc + amount
    })
  
  if maximize {
    aum + total_guaranteed
  } else {
    aum
  }
}

/// Find price for a token
pub fn find_price(prices: List<PriceData>, token: AssetClass) -> Option<PriceData> {
  list.find(
    prices,
    fn(price_data) {
      price_data.token.policy_id == token.policy_id && price_data.token.asset_name == token.asset_name
    },
  )
}

/// Get reserved amount for token
pub fn get_reserved_amount(
  reserved_amounts: List<(AssetClass, Int)>,
  token: AssetClass,
) -> Int {
  when
    list.find(
      reserved_amounts,
      fn(entry) {
        let (t, _amount) = entry
        t.policy_id == token.policy_id && t.asset_name == token.asset_name
      },
    )
  is {
    Some((_token, amount)) -> amount
    None -> 0
  }
}

/// Calculate position fee
pub fn get_position_fee(size_delta: Int, margin_fee_basis_points: Int) -> Int {
  if size_delta == 0 {
    0
  } else {
    let after_fee_usd = size_delta * ( basis_points_divisor - margin_fee_basis_points ) / basis_points_divisor
    size_delta - after_fee_usd
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
  let fees = margin_fees + funding_fees + liquidation_fee_usd
  
  if !has_profit && position_collateral < delta {
    // Loss exceeds collateral
    True
  } else {
    let remaining_collateral =
      if has_profit {
        position_collateral + delta
      } else {
        position_collateral - delta
      }
    
    remaining_collateral < fees || remaining_collateral * basis_points_divisor < position_size * 10000
  }
}

/// Update list entry
pub fn update_list_entry(
  list_data: List<(AssetClass, Int)>,
  token: AssetClass,
  new_value: Int,
) -> List<(AssetClass, Int)> {
  list.map(
    list_data,
    fn(entry) {
      let (t, value) = entry
      if t.policy_id == token.policy_id && t.asset_name == token.asset_name {
        (t, new_value)
      } else {
        entry
      }
    },
  )
}

/// Adjust for decimals (token decimals to USD decimals)
pub fn adjust_for_decimals(
  amount: Int,
  token_decimals: Int,
  usd_decimals: Int,
) -> Int {
  if token_decimals > usd_decimals {
    amount / math.pow(10, token_decimals - usd_decimals)
  } else {
    amount * math.pow(10, usd_decimals - token_decimals)
  }
}

