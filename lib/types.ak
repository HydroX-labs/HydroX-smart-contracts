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

/// Position data structure - Stablecoin collateral only
pub type Position {
  owner: Hash<Blake2b_224, VerificationKey>,
  index_token: AssetClass,  // Token being tracked (e.g., BTC, ETH price feed)
  position_type: PositionType,
  size: Int,  // Position size in USD (scaled by 1e30)
  collateral: Int,  // Collateral in stablecoin (scaled by 1e30)
  average_price: Int,  // Average entry price (scaled by 1e30)
  entry_funding_rate: Int,
  last_increased_time: Int,
}

/// Vault state datum - Stablecoin only version
pub type VaultDatum {
  // Stablecoin used (e.g., USDC, USDT, or Cardano stablecoin)
  stablecoin: AssetClass,
  // Total stablecoin liquidity in pool
  total_liquidity: Int,
  // Reserved amount for open positions
  reserved_amount: Int,
  // Guaranteed USD values for short positions
  guaranteed_usd: Int,
  // Cumulative funding rate for longs
  cumulative_funding_rate_long: Int,
  // Cumulative funding rate for shorts
  cumulative_funding_rate_short: Int,
  // Last funding update time
  last_funding_time: Int,
  // Open interest (total position size) for longs
  open_interest_long: Int,
  // Open interest (total position size) for shorts
  open_interest_short: Int,
  // Admin public key hash
  admin: Hash<Blake2b_224, VerificationKey>,
  // Fee basis points (1 basis point = 0.01%)
  mint_burn_fee_basis_points: Int,  // GLP minting/burning fee
  margin_fee_basis_points: Int,     // Position open/close fee
  liquidation_fee_usd: Int,         // Liquidation fee (in USD, 1e30 scale)
  // Protocol parameters
  min_profit_time: Int,
  max_leverage: Int,  // Maximum leverage (e.g., 50 for 50x)
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

/// Redeemer actions for Vault - Stablecoin only version
pub type VaultRedeemer {
  // Liquidity operations (stablecoin only)
  AddLiquidity { amount: Int }
  RemoveLiquidity { glp_amount: Int }
  // Position operations (stablecoin collateral)
  IncreasePosition {
    account: Hash<Blake2b_224, VerificationKey>,
    index_token: AssetClass,  // Asset to trade (BTC, ETH, etc.)
    collateral_delta: Int,     // Stablecoin to add as collateral
    size_delta: Int,           // Position size to add
    is_long: Bool,
  }
  DecreasePosition {
    account: Hash<Blake2b_224, VerificationKey>,
    index_token: AssetClass,
    collateral_delta: Int,
    size_delta: Int,
    is_long: Bool,
  }
  LiquidatePosition {
    account: Hash<Blake2b_224, VerificationKey>,
    index_token: AssetClass,
    is_long: Bool,
  }
  // Admin operations
  UpdateFees
  UpdateFundingRate  // Update funding rate for long/short balancing
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

