import { BASIS_POINTS_DIVISOR } from './constants';

/**
 * Fee calculations
 */

/**
 * Calculate position margin fee
 * Fee is charged on the position size
 */
export function calculateMarginFee(
  sizeDelta: bigint,
  marginFeeBasisPoints: number
): bigint {
  return (sizeDelta * BigInt(marginFeeBasisPoints)) / BASIS_POINTS_DIVISOR;
}

/**
 * Calculate liquidation fee
 * Fixed fee in USD
 */
export function calculateLiquidationFee(
  liquidationFeeUsd: bigint
): bigint {
  return liquidationFeeUsd;
}

/**
 * Calculate total fees for opening/increasing a position
 */
export function calculateOpenPositionFees(
  sizeDelta: bigint,
  marginFeeBasisPoints: number
): {
  marginFee: bigint;
  totalFees: bigint;
} {
  const marginFee = calculateMarginFee(sizeDelta, marginFeeBasisPoints);
  
  return {
    marginFee,
    totalFees: marginFee,
  };
}

/**
 * Calculate total fees for closing/decreasing a position
 */
export function calculateClosePositionFees(
  sizeDelta: bigint,
  marginFeeBasisPoints: number,
  fundingFee: bigint
): {
  marginFee: bigint;
  fundingFee: bigint;
  totalFees: bigint;
} {
  const marginFee = calculateMarginFee(sizeDelta, marginFeeBasisPoints);
  
  return {
    marginFee,
    fundingFee,
    totalFees: marginFee + fundingFee,
  };
}

