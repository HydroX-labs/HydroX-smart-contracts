// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Vault NFT Minting Policy
// One-time mint to uniquely identify the canonical Vault UTXO
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

use aiken/transaction.{ScriptContext, Mint, OutputReference}
use aiken/transaction/value
use aiken/list
use aiken/dict

/// Vault NFT Policy Parameters
/// This policy must be parameterized with a specific UTXO reference
/// that will be consumed during Vault initialization.
/// 
/// Usage:
/// 1. Choose a UTXO to consume (e.g., from admin wallet)
/// 2. Compile this policy with that UTXO reference
/// 3. In the same transaction:
///    - Consume the referenced UTXO
///    - Mint exactly 1 NFT
///    - Create the Vault UTXO with the NFT attached
/// 4. This NFT can never be minted again (one-time mint)
///
/// Parameters:
/// - utxo_ref: The specific UTXO that must be consumed to mint the NFT
minting {
  fn vault_nft_policy(utxo_ref: OutputReference, ctx: ScriptContext) -> Bool {
    expect Mint(own_policy_id) = ctx.purpose
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Rule 1: The specified UTXO must be consumed
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    let has_required_utxo =
      list.any(
        ctx.transaction.inputs,
        fn(input) { input.output_reference == utxo_ref },
      )
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Rule 2: Exactly 1 token must be minted (NFT)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    expect Some(minted_assets) = dict.get(value.from_minted_value(ctx.transaction.mint), own_policy_id)
    
    // Count total minted amount across all asset names under this policy
    let total_minted = 
      dict.foldr(
        minted_assets,
        0,
        fn(_asset_name, amount, acc) { acc + amount }
      )
    
    // Must be exactly 1 (NFT), not 0 or multiple
    let is_single_nft = total_minted == 1
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Both conditions must be satisfied
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    has_required_utxo && is_single_nft
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Note: Burning the NFT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// This policy does NOT allow burning (amount = -1).
// If you want to allow controlled burning (e.g., for protocol shutdown):
// - Add a separate redeemer/rule
// - Require admin signature
// - Ensure it's a deliberate protocol termination
//
// Current design: NFT is permanent once minted (immutable Vault identity)

