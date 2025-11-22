// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Common utilities shared across all validators
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

use aiken/list
use baobabx_gmx/types.{AssetClass}
use baobabx_gmx/constants.{basis_points_divisor}

/// Calculate fee amount based on basis points
pub fn calculate_fee(amount: Int, fee_basis_points: Int) -> Int {
  amount * fee_basis_points / basis_points_divisor
}

/// Get reserved amount for specific token
pub fn get_reserved_for_token(
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
    Some((_t, amount)) -> amount
    None -> 0
  }
}

/// Get open interest for specific token
pub fn get_open_interest(
  open_interest_list: List<(AssetClass, Int)>,
  token: AssetClass,
) -> Int {
  when
    list.find(
      open_interest_list,
      fn(entry) {
        let (t, _amount) = entry
        t.policy_id == token.policy_id && t.asset_name == token.asset_name
      },
    )
  is {
    Some((_t, amount)) -> amount
    None -> 0
  }
}

/// Update or add entry in a list of (AssetClass, Int)
pub fn update_token_entry(
  list_data: List<(AssetClass, Int)>,
  token: AssetClass,
  new_value: Int,
) -> List<(AssetClass, Int)> {
  let exists =
    list.any(
      list_data,
      fn(entry) {
        let (t, _v) = entry
        t.policy_id == token.policy_id && t.asset_name == token.asset_name
      },
    )
  
  if exists {
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
  } else {
    list.concat(list_data, [(token, new_value)])
  }
}

/// Get total reserved amount across all tokens
pub fn get_total_reserved(reserved_amounts: List<(AssetClass, Int)>) -> Int {
  list.foldl(
    reserved_amounts,
    0,
    fn(acc, entry) {
      let (_token, amount) = entry
      acc + amount
    },
  )
}

/// Check if two AssetClass are equal
pub fn asset_class_eq(a: AssetClass, b: AssetClass) -> Bool {
  a.policy_id == b.policy_id && a.asset_name == b.asset_name
}

