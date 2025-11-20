use aiken/transaction.{ScriptContext, Spend}
use baobabx_gmx/types.{PositionDatum, PositionRedeemer, ClosePosition, UpdatePosition}

/// Position validator - manages individual leveraged positions
validator {
  fn position(
    datum: PositionDatum,
    redeemer: PositionRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        when redeemer is {
          ClosePosition -> {
            // Position can be closed by:
            // 1. Owner decreasing position to zero
            // 2. Liquidator if position is underwater
            validate_close_position(datum, ctx)
          }
          
          UpdatePosition -> {
            // Position can be updated when:
            // 1. Owner increases position
            // 2. Owner decreases position (but not to zero)
            validate_update_position(datum, ctx)
          }
        }
      }
      _ -> False
    }
  }
}

/// Validate closing a position
fn validate_close_position(datum: PositionDatum, ctx: ScriptContext) -> Bool {
  // TODO: Verify either:
  // 1. Owner signature and vault processed decrease to zero
  // 2. Liquidator and vault confirmed liquidation
  // TODO: Ensure vault UTXO is spent in same transaction
  
  True
}

/// Validate updating a position
fn validate_update_position(datum: PositionDatum, ctx: ScriptContext) -> Bool {
  // TODO: Verify owner signature
  // TODO: Verify vault UTXO is spent
  // TODO: Verify new position output with updated datum
  // TODO: Validate position parameters are consistent
  
  True
}

