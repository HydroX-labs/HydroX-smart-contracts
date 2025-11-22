use aiken/transaction.{ScriptContext, Mint}
use aiken/transaction/value
use aiken/list
use aiken/dict
use baobabx_gmx/types.{VaultDatum, VaultRedeemer, AddLiquidity, RemoveLiquidity}

/// GLP Token Minting Policy
/// This policy ensures GLP tokens can only be minted/burned by the Vault
/// in accordance with AddLiquidity/RemoveLiquidity operations
minting {
  fn glp_policy(vault_script_hash: ByteArray, ctx: ScriptContext) -> Bool {
    when ctx.purpose is {
      Mint(own_policy_id) -> {
        // Get the minted/burned amount
        let minted_value = value.from_minted_value(ctx.transaction.mint)
        let glp_amount = get_glp_amount(minted_value, own_policy_id)
        
        // Check if Vault is involved in this transaction
        let vault_input = find_vault_input(ctx.transaction.inputs, vault_script_hash)
        let vault_output = find_vault_output(ctx.transaction.outputs, vault_script_hash)
        
        when (vault_input, vault_output) is {
          (Some(input), Some(output)) -> {
            // Parse Vault datums
            let input_datum = parse_vault_datum(input.output.datum)
            let output_datum = parse_vault_datum(output.datum)
            
            // Get Vault redeemer
            let vault_redeemer = get_vault_redeemer(ctx.transaction.redeemers, input)
            
            when vault_redeemer is {
              Some(AddLiquidity { amount }) -> {
                validate_add_liquidity(
                  input_datum,
                  output_datum,
                  amount,
                  glp_amount,
                )
              }
              
              Some(RemoveLiquidity { glp_amount: glp_burn_amount }) -> {
                validate_remove_liquidity(
                  input_datum,
                  output_datum,
                  glp_burn_amount,
                  glp_amount,
                )
              }
              
              _ -> False  // Other vault operations cannot mint/burn GLP
            }
          }
          
          _ -> False  // Vault must be involved
        }
      }
      
      _ -> False
    }
  }
}

/// Validate AddLiquidity: GLP should be minted
fn validate_add_liquidity(
  input_datum: VaultDatum,
  output_datum: VaultDatum,
  stablecoin_added: Int,
  glp_minted: Int,
) -> Bool {
  // Calculate expected GLP amount
  let expected_glp = calculate_glp_mint_amount(
    input_datum.total_liquidity,
    input_datum.glp_supply,
    stablecoin_added,
    input_datum.mint_burn_fee_basis_points,
  )
  
  // Verify calculations
  let glp_supply_increased = output_datum.glp_supply == input_datum.glp_supply + glp_minted
  let liquidity_increased_correctly = 
    output_datum.total_liquidity == input_datum.total_liquidity + stablecoin_added
  
  // GLP amount must match expected (positive mint)
  glp_minted > 0 && 
  glp_minted == expected_glp && 
  glp_supply_increased && 
  liquidity_increased_correctly
}

/// Validate RemoveLiquidity: GLP should be burned
fn validate_remove_liquidity(
  input_datum: VaultDatum,
  output_datum: VaultDatum,
  glp_to_burn: Int,
  glp_burned: Int,
) -> Bool {
  // Calculate expected stablecoin withdrawal
  let expected_stablecoin = calculate_stablecoin_withdrawal_amount(
    input_datum.total_liquidity,
    input_datum.glp_supply,
    glp_to_burn,
    input_datum.mint_burn_fee_basis_points,
  )
  
  // Verify calculations
  let glp_supply_decreased = output_datum.glp_supply == input_datum.glp_supply - glp_to_burn
  let liquidity_decreased_correctly = 
    output_datum.total_liquidity >= input_datum.total_liquidity - expected_stablecoin
  
  // GLP amount must be negative (burn)
  glp_burned < 0 && 
  glp_burned == -glp_to_burn && 
  glp_supply_decreased && 
  liquidity_decreased_correctly
}

/// Calculate GLP amount to mint when adding liquidity
fn calculate_glp_mint_amount(
  total_liquidity: Int,
  glp_supply: Int,
  stablecoin_amount: Int,
  fee_basis_points: Int,
) -> Int {
  let basis_points_divisor = 10000
  
  // Apply minting fee
  let after_fee = stablecoin_amount - (stablecoin_amount * fee_basis_points / basis_points_divisor)
  
  // Calculate GLP amount
  if glp_supply == 0 {
    // Initial mint: 1:1 ratio
    after_fee
  } else {
    // Proportional to existing supply
    after_fee * glp_supply / total_liquidity
  }
}

/// Calculate stablecoin amount to return when burning GLP
fn calculate_stablecoin_withdrawal_amount(
  total_liquidity: Int,
  glp_supply: Int,
  glp_amount: Int,
  fee_basis_points: Int,
) -> Int {
  let basis_points_divisor = 10000
  
  // Calculate proportional stablecoin
  let stablecoin_amount = glp_amount * total_liquidity / glp_supply
  
  // Apply burning fee
  stablecoin_amount - (stablecoin_amount * fee_basis_points / basis_points_divisor)
}

/// Get GLP amount from minted value (positive = mint, negative = burn)
fn get_glp_amount(minted_value: value.Value, policy_id: ByteArray) -> Int {
  let assets = value.tokens(minted_value, policy_id)
  
  when dict.to_list(assets) is {
    [(_, amount)] -> amount
    _ -> 0
  }
}

/// Find Vault input UTXO
fn find_vault_input(inputs: List<Input>, vault_script_hash: ByteArray) -> Option<Input> {
  list.find(
    inputs,
    fn(input) {
      when input.output.address.payment_credential is {
        ScriptCredential(hash) -> hash == vault_script_hash
        _ -> False
      }
    },
  )
}

/// Find Vault output UTXO
fn find_vault_output(outputs: List<Output>, vault_script_hash: ByteArray) -> Option<Output> {
  list.find(
    outputs,
    fn(output) {
      when output.address.payment_credential is {
        ScriptCredential(hash) -> hash == vault_script_hash
        _ -> False
      }
    },
  )
}

/// Parse Vault datum from output
fn parse_vault_datum(datum: Datum) -> VaultDatum {
  when datum is {
    InlineDatum(data) -> {
      // In practice, you'd properly decode this
      // For now, assuming it's properly typed
      expect vault_datum: VaultDatum = data
      vault_datum
    }
    _ -> error @"Invalid datum type"
  }
}

/// Get Vault redeemer from transaction
fn get_vault_redeemer(redeemers: List<(ScriptPurpose, Redeemer)>, vault_input: Input) -> Option<VaultRedeemer> {
  when 
    list.find(
      redeemers,
      fn(entry) {
        let (purpose, _) = entry
        when purpose is {
          Spend(output_ref) -> output_ref == vault_input.output_reference
          _ -> False
        }
      },
    )
  is {
    Some((_, redeemer)) -> {
      expect vault_redeemer: VaultRedeemer = redeemer
      Some(vault_redeemer)
    }
    None -> None
  }
}

