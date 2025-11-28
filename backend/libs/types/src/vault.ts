import { AssetClass } from './cardano';

/**
 * Vault-related types matching validators/vault.ak
 */

export interface VaultDatum {
  vaultNft: AssetClass;
  admin: string; // PubKeyHash
  totalLiquidity: bigint;
  glpSupply: bigint;
  mintBurnFeeBasisPoints: number;
  marginFeeBasisPoints: number;
  liquidationFeeUsd: bigint;
  maxLeverage: number;
  whitelistedTokens: AssetClass[];
  reservedAmounts: Record<string, bigint>; // token -> reserved amount
  openInterestLong: Record<string, bigint>; // token -> OI
  openInterestShort: Record<string, bigint>; // token -> OI
  guaranteedUsd: Record<string, bigint>; // token -> guaranteed
  maxUtilization: Record<string, number>; // token -> basis points
  cumulativeFundingRateLong: Record<string, bigint>; // token -> rate
  cumulativeFundingRateShort: Record<string, bigint>; // token -> rate
  lastFundingTimes: Record<string, number>; // token -> timestamp
}

export enum VaultRedeemer {
  AddLiquidity = 'AddLiquidity',
  RemoveLiquidity = 'RemoveLiquidity',
  IncreasePosition = 'IncreasePosition',
  DecreasePosition = 'DecreasePosition',
  LiquidatePosition = 'LiquidatePosition',
  UpdateFees = 'UpdateFees',
  UpdateFundingRate = 'UpdateFundingRate',
}

export interface AddLiquidityRedeemer {
  type: VaultRedeemer.AddLiquidity;
  amount: bigint;
}

export interface RemoveLiquidityRedeemer {
  type: VaultRedeemer.RemoveLiquidity;
  glpAmount: bigint;
}

export interface IncreasePositionRedeemer {
  type: VaultRedeemer.IncreasePosition;
  account: string;
  indexToken: AssetClass;
  collateralDelta: bigint;
  sizeDelta: bigint;
  isLong: boolean;
}

export interface DecreasePositionRedeemer {
  type: VaultRedeemer.DecreasePosition;
  account: string;
  indexToken: AssetClass;
  collateralDelta: bigint;
  sizeDelta: bigint;
  isLong: boolean;
}

export interface LiquidatePositionRedeemer {
  type: VaultRedeemer.LiquidatePosition;
  account: string;
  indexToken: AssetClass;
  isLong: boolean;
}

export type VaultRedeemerData =
  | AddLiquidityRedeemer
  | RemoveLiquidityRedeemer
  | IncreasePositionRedeemer
  | DecreasePositionRedeemer
  | LiquidatePositionRedeemer
  | { type: VaultRedeemer.UpdateFees }
  | { type: VaultRedeemer.UpdateFundingRate };

export interface VaultState {
  utxo: {
    txHash: string;
    outputIndex: number;
  };
  datum: VaultDatum;
  lastUpdated: Date;
}

