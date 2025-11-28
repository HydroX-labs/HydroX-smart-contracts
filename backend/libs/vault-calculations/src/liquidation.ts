import { PositionDatum } from '@hydrox/types';
import { calculatePositionPnL } from './position';
import { calculateFundingFee } from './funding';
import { calculateMarginFee } from './fees';
import { LIQUIDATION_THRESHOLD, BASIS_POINTS_DIVISOR } from './constants';

/**
 * Liquidation logic
 */

/**
 * Check if a position should be liquidated
 * 
 * A position is liquidatable if:
 * - Remaining collateral after losses and fees < liquidation threshold
 * - Collateral ratio < 1% (LIQUIDATION_THRESHOLD)
 */
export function isPositionLiquidatable(
  position: PositionDatum,
  currentPrice: bigint,
  currentFundingRate: bigint,
  marginFeeBasisPoints: number,
  liquidationFeeUsd: bigint
): boolean {
  // Calculate PnL
  const pnl = calculatePositionPnL(position, currentPrice);
  
  // Calculate fees
  const fundingFee = calculateFundingFee(
    position.size,
    position.entryFundingRate,
    currentFundingRate
  );
  const marginFee = calculateMarginFee(position.size, marginFeeBasisPoints);
  const totalFees = fundingFee + marginFee + liquidationFeeUsd;
  
  // Calculate remaining collateral
  const remainingCollateral = position.collateral + pnl - totalFees;
  
  // Position is liquidatable if remaining collateral is negative or below threshold
  if (remainingCollateral <= 0n) {
    return true;
  }
  
  // Check collateral ratio: (remainingCollateral / size) < LIQUIDATION_THRESHOLD
  const collateralRatio = (remainingCollateral * BASIS_POINTS_DIVISOR) / position.size;
  return collateralRatio < BigInt(LIQUIDATION_THRESHOLD);
}

/**
 * Calculate liquidation payout
 * 
 * Returns:
 * - liquidatorFee: Fee paid to liquidator
 * - remainingCollateral: Remaining collateral returned to pool
 */
export function calculateLiquidationPayout(
  position: PositionDatum,
  currentPrice: bigint,
  currentFundingRate: bigint,
  marginFeeBasisPoints: number,
  liquidationFeeUsd: bigint
): {
  liquidatorFee: bigint;
  remainingCollateral: bigint;
  totalLoss: bigint;
} {
  const pnl = calculatePositionPnL(position, currentPrice);
  const fundingFee = calculateFundingFee(
    position.size,
    position.entryFundingRate,
    currentFundingRate
  );
  const marginFee = calculateMarginFee(position.size, marginFeeBasisPoints);
  
  const totalFees = fundingFee + marginFee;
  const remainingAfterFeesAndPnl = position.collateral + pnl - totalFees;
  
  // Liquidator gets fixed fee (up to remaining collateral)
  const liquidatorFee = remainingAfterFeesAndPnl > liquidationFeeUsd
    ? liquidationFeeUsd
    : (remainingAfterFeesAndPnl > 0n ? remainingAfterFeesAndPnl : 0n);
  
  // Remaining goes back to pool (can be negative if position lost more than collateral)
  const remainingCollateral = remainingAfterFeesAndPnl - liquidatorFee;
  
  // Total loss to pool (if negative)
  const totalLoss = remainingCollateral < 0n ? -remainingCollateral : 0n;
  
  return {
    liquidatorFee,
    remainingCollateral: remainingCollateral > 0n ? remainingCollateral : 0n,
    totalLoss,
  };
}

/**
 * Validate liquidation is allowed
 */
export function validateLiquidation(
  position: PositionDatum,
  currentPrice: bigint,
  currentFundingRate: bigint,
  marginFeeBasisPoints: number,
  liquidationFeeUsd: bigint
): { valid: boolean; error?: string } {
  if (!isPositionLiquidatable(
    position,
    currentPrice,
    currentFundingRate,
    marginFeeBasisPoints,
    liquidationFeeUsd
  )) {
    return {
      valid: false,
      error: 'Position is not liquidatable',
    };
  }
  
  return { valid: true };
}

