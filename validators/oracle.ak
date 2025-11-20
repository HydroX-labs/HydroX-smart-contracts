use aiken/transaction.{ScriptContext, Spend}
use aiken/list
use aiken/transaction/credential.{Address}
use baobabx_gmx/types.{
  OracleDatum, OracleRedeemer, UpdatePrices, UpdateAdmin, PriceData,
}

/// Oracle validator - manages price feeds
validator {
  fn oracle(
    datum: OracleDatum,
    redeemer: OracleRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        when redeemer is {
          UpdatePrices { new_prices } -> {
            validate_update_prices(datum, new_prices, ctx)
          }
          
          UpdateAdmin { new_admin } -> {
            validate_update_admin(datum, new_admin, ctx)
          }
        }
      }
      _ -> False
    }
  }
}

/// Validate price update
fn validate_update_prices(
  datum: OracleDatum,
  new_prices: List<PriceData>,
  ctx: ScriptContext,
) -> Bool {
  // Verify oracle admin signature
  let has_admin_signature =
    list.any(
      ctx.transaction.extra_signatories,
      fn(sig) { sig == datum.oracle_admin },
    )
  
  // TODO: Validate price data:
  // 1. Timestamps are recent
  // 2. Prices are reasonable (no extreme changes)
  // 3. Confidence levels are acceptable
  
  // TODO: Create output with updated prices
  
  has_admin_signature && !list.is_empty(new_prices)
}

/// Validate admin update
fn validate_update_admin(
  datum: OracleDatum,
  new_admin: ByteArray,
  ctx: ScriptContext,
) -> Bool {
  // Verify current admin signature
  let has_admin_signature =
    list.any(
      ctx.transaction.extra_signatories,
      fn(sig) { sig == datum.oracle_admin },
    )
  
  // TODO: Create output with new admin
  
  has_admin_signature
}

