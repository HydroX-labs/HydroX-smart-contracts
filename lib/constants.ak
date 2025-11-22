// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Global constants used across all validators
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Basis points divisor (100% = 10000 basis points)
pub const basis_points_divisor = 10000

/// Price precision (1e30 for USD values)
pub const price_precision = 1_000_000_000_000_000_000_000_000_000_000  // 1e30

/// Funding rate precision
pub const funding_rate_precision = 1_000_000

/// Maximum fee in basis points (5%)
pub const max_fee_basis_points = 500  // 5%

/// Maximum liquidation fee in USD (scaled by 1e30)
pub const max_liquidation_fee_usd = 100_000_000_000_000_000_000_000_000_000_000  // $100

/// Minimum collateral ratio (1% = 100 basis points)
pub const min_collateral_ratio_bps = 100  // 1%

