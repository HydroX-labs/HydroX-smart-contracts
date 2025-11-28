import { FUNDING_RATE_PRECISION, BASIS_POINTS_DIVISOR } from './constants';

/**
 * Funding rate calculations
 */

/**
 * Calculate funding rate based on open interest imbalance
 * 
 * fundingRate = (OI_long - OI_short) / total_liquidity * factor * time_delta
 */
export function calculateFundingRate(
  openInterestLong: bigint,
  openInterestShort: bigint,
  totalLiquidity: bigint,
  fundingRateFactor: bigint,
  timeDeltaHours: number
): bigint {
  if (totalLiquidity === 0n) {
    return 0n;
  }

  const imbalance = openInterestLong - openInterestShort;
  const imbalanceRatio = (imbalance * FUNDING_RATE_PRECISION) / totalLiquidity;
  
  // Apply factor and time
  const fundingRate = (imbalanceRatio * fundingRateFactor * BigInt(timeDeltaHours)) / FUNDING_RATE_PRECISION;
  
  return fundingRate;
}

/**
 * Calculate funding fee for a position
 * 
 * fundingFee = position.size * (currentFundingRate - entryFundingRate) / PRECISION
 */
export function calculateFundingFee(
  positionSize: bigint,
  entryFundingRate: bigint,
  currentFundingRate: bigint
): bigint {
  const fundingRateDelta = currentFundingRate - entryFundingRate;
  return (positionSize * fundingRateDelta) / FUNDING_RATE_PRECISION;
}

/**
 * Calculate time delta in hours
 */
export function calculateTimeDeltaHours(
  lastUpdateTime: number,
  currentTime: number
): number {
  const deltaSeconds = currentTime - lastUpdateTime;
  return deltaSeconds / 3600; // Convert to hours
}

/**
 * Update cumulative funding rate
 */
export function updateCumulativeFundingRate(
  currentCumulativeRate: bigint,
  fundingRateDelta: bigint,
  isLong: boolean
): bigint {
  // Long positions pay funding when OI is imbalanced towards longs
  // Short positions receive funding in this case
  return isLong
    ? currentCumulativeRate + fundingRateDelta
    : currentCumulativeRate - fundingRateDelta;
}

