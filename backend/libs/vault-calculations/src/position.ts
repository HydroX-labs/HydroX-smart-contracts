import { PositionDatum } from '@hydrox/types';
import { PRICE_PRECISION } from './constants';

/**
 * Position calculations
 */

/**
 * Calculate position PnL
 * 
 * For long positions:
 * PnL = size * (currentPrice - averagePrice) / averagePrice
 * 
 * For short positions:
 * PnL = size * (averagePrice - currentPrice) / averagePrice
 */
export function calculatePositionPnL(
  position: PositionDatum,
  currentPrice: bigint
): bigint {
  if (position.size === 0n) {
    return 0n;
  }

  const priceDelta = position.isLong
    ? currentPrice - position.averagePrice
    : position.averagePrice - currentPrice;

  // PnL = (size * priceDelta) / averagePrice
  return (position.size * priceDelta) / position.averagePrice;
}

/**
 * Calculate position leverage
 * Leverage = size / collateral
 */
export function calculateLeverage(
  size: bigint,
  collateral: bigint
): number {
  if (collateral === 0n) {
    return 0;
  }
  return Number((size * 10000n) / collateral) / 100; // Return as decimal (e.g., 5.0 for 5x)
}

/**
 * Calculate liquidation price for a position
 * 
 * For long:
 * liquidationPrice = averagePrice * (1 - collateral / size)
 * 
 * For short:
 * liquidationPrice = averagePrice * (1 + collateral / size)
 */
export function calculateLiquidationPrice(
  position: PositionDatum,
  marginFeeBasisPoints: number,
  liquidationFeeUsd: bigint
): bigint {
  if (position.size === 0n) {
    return 0n;
  }

  // Account for fees in liquidation calculation
  const fees = liquidationFeeUsd;
  const effectiveCollateral = position.collateral > fees ? position.collateral - fees : 0n;

  if (position.isLong) {
    // Long liquidation: price drops
    // liqPrice = avgPrice - (collateral / size) * avgPrice
    const collateralRatio = (effectiveCollateral * PRICE_PRECISION) / position.size;
    const priceDropRatio = (collateralRatio * position.averagePrice) / PRICE_PRECISION;
    return position.averagePrice > priceDropRatio ? position.averagePrice - priceDropRatio : 0n;
  } else {
    // Short liquidation: price rises
    // liqPrice = avgPrice + (collateral / size) * avgPrice
    const collateralRatio = (effectiveCollateral * PRICE_PRECISION) / position.size;
    const priceRiseRatio = (collateralRatio * position.averagePrice) / PRICE_PRECISION;
    return position.averagePrice + priceRiseRatio;
  }
}

/**
 * Calculate new average price when increasing position
 */
export function calculateAveragePrice(
  currentSize: bigint,
  currentAveragePrice: bigint,
  sizeDelta: bigint,
  entryPrice: bigint
): bigint {
  if (currentSize === 0n) {
    return entryPrice;
  }

  const newSize = currentSize + sizeDelta;
  if (newSize === 0n) {
    return 0n;
  }

  // Weighted average: (currentSize * currentAvgPrice + sizeDelta * entryPrice) / newSize
  const totalValue = currentSize * currentAveragePrice + sizeDelta * entryPrice;
  return totalValue / newSize;
}

/**
 * Validate position parameters
 */
export function validatePositionParams(
  collateral: bigint,
  size: bigint,
  maxLeverage: number
): { valid: boolean; error?: string } {
  if (collateral <= 0n) {
    return { valid: false, error: 'Collateral must be positive' };
  }

  if (size <= 0n) {
    return { valid: false, error: 'Size must be positive' };
  }

  const leverage = calculateLeverage(size, collateral);
  if (leverage > maxLeverage / 100) {
    return { valid: false, error: `Leverage ${leverage}x exceeds maximum ${maxLeverage / 100}x` };
  }

  return { valid: true };
}

