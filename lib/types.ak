use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{VerificationKey}

/// Asset identifier
pub type AssetClass {
  policy_id: ByteArray,
  asset_name: ByteArray,
}

/// Position type (Long or Short)
pub type PositionType {
  Long
  Short
}

/// Position data structure
pub type Position {
  owner: Hash<Blake2b_224, VerificationKey>,
  collateral_token: AssetClass,
  index_token: AssetClass,
  position_type: PositionType,
  size: Int,  // Position size in USD (scaled by 1e30)
  collateral: Int,  // Collateral amount (scaled by 1e30)
  average_price: Int,  // Average entry price (scaled by 1e30)
  entry_funding_rate: Int,
  reserve_amount: Int,
  realized_pnl: Int,
  last_increased_time: Int,
}

/// Vault state datum
pub type VaultDatum {
  // Pool tokens and amounts
  pool_amounts: List<(AssetClass, Int)>,
  // Reserved amounts for open positions
  reserved_amounts: List<(AssetClass, Int)>,
  // Guaranteed USD values
  guaranteed_usd: List<(AssetClass, Int)>,
  // Total token weights
  token_weights: List<(AssetClass, Int)>,
  // USDG (stablecoin) debt
  usdg_amounts: List<(AssetClass, Int)>,
  // Max USDG amounts
  max_usdg_amounts: List<(AssetClass, Int)>,
  // Cumulative funding rates
  cumulative_funding_rates: List<(AssetClass, Int)>,
  // Last funding times
  last_funding_times: List<(AssetClass, Int)>,
  // Whitelisted tokens
  whitelisted_tokens: List<AssetClass>,
  // Admin public key hash
  admin: Hash<Blake2b_224, VerificationKey>,
  // Fee basis points (1 basis point = 0.01%)
  tax_basis_points: Int,
  stable_tax_basis_points: Int,
  mint_burn_fee_basis_points: Int,
  swap_fee_basis_points: Int,
  stable_swap_fee_basis_points: Int,
  margin_fee_basis_points: Int,
  liquidation_fee_usd: Int,
  // Protocol parameters
  min_profit_time: Int,
  has_dynamic_fees: Bool,
  // GLP supply
  glp_supply: Int,
}

/// Position manager datum
pub type PositionDatum {
  position: Position,
  vault_ref: ByteArray,  // Reference to vault UTXO
}

/// Price feed data
pub type PriceData {
  token: AssetClass,
  price: Int,  // Price in USD (scaled by 1e30)
  timestamp: Int,
  confidence: Int,
}

/// Oracle datum
pub type OracleDatum {
  prices: List<PriceData>,
  oracle_admin: Hash<Blake2b_224, VerificationKey>,
  max_price_age: Int,  // Maximum age of price in milliseconds
}

/// Redeemer actions for Vault
pub type VaultRedeemer {
  // Liquidity operations
  AddLiquidity { token: AssetClass, amount: Int }
  RemoveLiquidity { glp_amount: Int, token_out: AssetClass }
  // Position operations
  IncreasePosition {
    account: Hash<Blake2b_224, VerificationKey>,
    collateral_token: AssetClass,
    index_token: AssetClass,
    size_delta: Int,
    is_long: Bool,
  }
  DecreasePosition {
    account: Hash<Blake2b_224, VerificationKey>,
    collateral_token: AssetClass,
    index_token: AssetClass,
    collateral_delta: Int,
    size_delta: Int,
    is_long: Bool,
  }
  LiquidatePosition {
    account: Hash<Blake2b_224, VerificationKey>,
    collateral_token: AssetClass,
    index_token: AssetClass,
    is_long: Bool,
  }
  // Swap
  Swap {
    token_in: AssetClass,
    token_out: AssetClass,
    receiver: Hash<Blake2b_224, VerificationKey>,
  }
  // Admin operations
  UpdateFees
  AddWhitelistedToken { token: AssetClass }
}

/// Redeemer for Position
pub type PositionRedeemer {
  ClosePosition
  UpdatePosition
}

/// Redeemer for Oracle
pub type OracleRedeemer {
  UpdatePrices { new_prices: List<PriceData> }
  UpdateAdmin { new_admin: Hash<Blake2b_224, VerificationKey> }
}

