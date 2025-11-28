import { BASIS_POINTS_DIVISOR } from './constants';

/**
 * GLP minting/burning calculations
 * Matches logic from validators/glp_policy.ak
 */

/**
 * Calculate GLP tokens to mint when adding liquidity
 * 
 * Formula:
 * - If pool is empty: GLP = amount (1:1)
 * - Otherwise: GLP = (amount * glpSupply / totalLiquidity) * (1 - fee)
 */
export function calculateGlpMint(
  stablecoinAmount: bigint,
  totalLiquidity: bigint,
  glpSupply: bigint,
  mintFeeBasisPoints: number
): bigint {
  if (stablecoinAmount <= 0n) {
    throw new Error('Amount must be positive');
  }

  let glpAmount: bigint;

  if (totalLiquidity === 0n || glpSupply === 0n) {
    // First deposit: 1:1 ratio
    glpAmount = stablecoinAmount;
  } else {
    // Subsequent deposits: proportional to pool share
    glpAmount = (stablecoinAmount * glpSupply) / totalLiquidity;
  }

  // Apply mint fee
  const fee = (glpAmount * BigInt(mintFeeBasisPoints)) / BASIS_POINTS_DIVISOR;
  return glpAmount - fee;
}

/**
 * Calculate stablecoin to return when burning GLP
 * 
 * Formula:
 * stablecoin = (glpAmount * totalLiquidity / glpSupply) * (1 - fee)
 */
export function calculateStablecoinRedeem(
  glpAmount: bigint,
  totalLiquidity: bigint,
  glpSupply: bigint,
  burnFeeBasisPoints: number
): bigint {
  if (glpAmount <= 0n) {
    throw new Error('GLP amount must be positive');
  }

  if (glpAmount > glpSupply) {
    throw new Error('GLP amount exceeds supply');
  }

  if (glpSupply === 0n) {
    throw new Error('GLP supply is zero');
  }

  // Calculate proportional stablecoin amount
  const stablecoinAmount = (glpAmount * totalLiquidity) / glpSupply;

  // Apply burn fee
  const fee = (stablecoinAmount * BigInt(burnFeeBasisPoints)) / BASIS_POINTS_DIVISOR;
  return stablecoinAmount - fee;
}

/**
 * Calculate available liquidity (not reserved for positions)
 */
export function calculateAvailableLiquidity(
  totalLiquidity: bigint,
  reservedAmounts: Record<string, bigint>
): bigint {
  const totalReserved = Object.values(reservedAmounts).reduce(
    (sum, amount) => sum + amount,
    0n
  );
  return totalLiquidity - totalReserved;
}

/**
 * Calculate pool utilization for a specific token
 */
export function calculateUtilization(
  reservedAmount: bigint,
  totalLiquidity: bigint
): number {
  if (totalLiquidity === 0n) {
    return 0;
  }
  return Number((reservedAmount * BASIS_POINTS_DIVISOR) / totalLiquidity);
}

