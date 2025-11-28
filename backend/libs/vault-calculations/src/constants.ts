/**
 * Constants matching validators/constants.ak
 */

export const BASIS_POINTS_DIVISOR = 10000n;
export const PRICE_PRECISION = 100000000n; // 8 decimals
export const USD_PRECISION = 1000000n; // 6 decimals

export const MAX_FEE_BASIS_POINTS = 500; // 5%
export const MAX_LIQUIDATION_FEE_USD = 100n * USD_PRECISION; // $100

export const DEFAULT_FUNDING_RATE_FACTOR = 100n; // 0.01% per hour
export const FUNDING_RATE_PRECISION = 1000000n;

export const MIN_LEVERAGE = 11000; // 1.1x (basis points)
export const MAX_LEVERAGE = 500000; // 50x (basis points)

export const LIQUIDATION_THRESHOLD = 100; // 1% (basis points)

