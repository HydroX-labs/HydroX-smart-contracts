import { Data } from 'lucid-cardano';
import { VaultDatum, PositionDatum, OracleDatum, AssetClass } from '@hydrox/types';

/**
 * Datum builders for on-chain data structures
 */

// Plutus Data schemas matching Aiken validators
const AssetClassSchema = Data.Object({
  policyId: Data.Bytes(),
  assetName: Data.Bytes(),
});

const VaultDatumSchema = Data.Object({
  vaultNft: AssetClassSchema,
  admin: Data.Bytes(),
  totalLiquidity: Data.Integer(),
  glpSupply: Data.Integer(),
  mintBurnFeeBasisPoints: Data.Integer(),
  marginFeeBasisPoints: Data.Integer(),
  liquidationFeeUsd: Data.Integer(),
  maxLeverage: Data.Integer(),
  whitelistedTokens: Data.Array(AssetClassSchema),
  reservedAmounts: Data.Map(AssetClassSchema, Data.Integer()),
  openInterestLong: Data.Map(AssetClassSchema, Data.Integer()),
  openInterestShort: Data.Map(AssetClassSchema, Data.Integer()),
  guaranteedUsd: Data.Map(AssetClassSchema, Data.Integer()),
  maxUtilization: Data.Map(AssetClassSchema, Data.Integer()),
  cumulativeFundingRateLong: Data.Map(AssetClassSchema, Data.Integer()),
  cumulativeFundingRateShort: Data.Map(AssetClassSchema, Data.Integer()),
  lastFundingTimes: Data.Map(AssetClassSchema, Data.Integer()),
});

const PositionDatumSchema = Data.Object({
  account: Data.Bytes(),
  indexToken: AssetClassSchema,
  collateral: Data.Integer(),
  size: Data.Integer(),
  averagePrice: Data.Integer(),
  entryFundingRate: Data.Integer(),
  isLong: Data.Boolean(),
  lastIncreasedTime: Data.Integer(),
});

const PriceDataSchema = Data.Object({
  token: AssetClassSchema,
  price: Data.Integer(),
  timestamp: Data.Integer(),
  confidence: Data.Integer(),
});

const OracleDatumSchema = Data.Object({
  oracleAdmin: Data.Bytes(),
  prices: Data.Array(PriceDataSchema),
  lastUpdated: Data.Integer(),
});

/**
 * Convert AssetClass to Plutus Data
 */
export function assetClassToPlutusData(asset: AssetClass): string {
  return Data.to({
    policyId: asset.policyId,
    assetName: asset.assetName,
  }, AssetClassSchema);
}

/**
 * Convert VaultDatum to Plutus Data
 */
export function vaultDatumToPlutusData(datum: VaultDatum): string {
  // Convert Record<string, bigint> to Map format
  const reservedAmountsMap = new Map(
    Object.entries(datum.reservedAmounts).map(([key, value]) => {
      const [policyId, assetName] = key.split('.');
      return [{ policyId, assetName }, value];
    })
  );

  const openInterestLongMap = new Map(
    Object.entries(datum.openInterestLong).map(([key, value]) => {
      const [policyId, assetName] = key.split('.');
      return [{ policyId, assetName }, value];
    })
  );

  const openInterestShortMap = new Map(
    Object.entries(datum.openInterestShort).map(([key, value]) => {
      const [policyId, assetName] = key.split('.');
      return [{ policyId, assetName }, value];
    })
  );

  const guaranteedUsdMap = new Map(
    Object.entries(datum.guaranteedUsd).map(([key, value]) => {
      const [policyId, assetName] = key.split('.');
      return [{ policyId, assetName }, value];
    })
  );

  const maxUtilizationMap = new Map(
    Object.entries(datum.maxUtilization).map(([key, value]) => {
      const [policyId, assetName] = key.split('.');
      return [{ policyId, assetName }, BigInt(value)];
    })
  );

  const cumulativeFundingRateLongMap = new Map(
    Object.entries(datum.cumulativeFundingRateLong).map(([key, value]) => {
      const [policyId, assetName] = key.split('.');
      return [{ policyId, assetName }, value];
    })
  );

  const cumulativeFundingRateShortMap = new Map(
    Object.entries(datum.cumulativeFundingRateShort).map(([key, value]) => {
      const [policyId, assetName] = key.split('.');
      return [{ policyId, assetName }, value];
    })
  );

  const lastFundingTimesMap = new Map(
    Object.entries(datum.lastFundingTimes).map(([key, value]) => {
      const [policyId, assetName] = key.split('.');
      return [{ policyId, assetName }, BigInt(value)];
    })
  );

  return Data.to({
    vaultNft: datum.vaultNft,
    admin: datum.admin,
    totalLiquidity: datum.totalLiquidity,
    glpSupply: datum.glpSupply,
    mintBurnFeeBasisPoints: BigInt(datum.mintBurnFeeBasisPoints),
    marginFeeBasisPoints: BigInt(datum.marginFeeBasisPoints),
    liquidationFeeUsd: datum.liquidationFeeUsd,
    maxLeverage: BigInt(datum.maxLeverage),
    whitelistedTokens: datum.whitelistedTokens,
    reservedAmounts: reservedAmountsMap,
    openInterestLong: openInterestLongMap,
    openInterestShort: openInterestShortMap,
    guaranteedUsd: guaranteedUsdMap,
    maxUtilization: maxUtilizationMap,
    cumulativeFundingRateLong: cumulativeFundingRateLongMap,
    cumulativeFundingRateShort: cumulativeFundingRateShortMap,
    lastFundingTimes: lastFundingTimesMap,
  }, VaultDatumSchema);
}

/**
 * Convert PositionDatum to Plutus Data
 */
export function positionDatumToPlutusData(datum: PositionDatum): string {
  return Data.to({
    account: datum.account,
    indexToken: datum.indexToken,
    collateral: datum.collateral,
    size: datum.size,
    averagePrice: datum.averagePrice,
    entryFundingRate: datum.entryFundingRate,
    isLong: datum.isLong,
    lastIncreasedTime: BigInt(datum.lastIncreasedTime),
  }, PositionDatumSchema);
}

/**
 * Convert OracleDatum to Plutus Data
 */
export function oracleDatumToPlutusData(datum: OracleDatum): string {
  return Data.to({
    oracleAdmin: datum.oracleAdmin,
    prices: datum.prices.map(p => ({
      token: p.token,
      price: p.price,
      timestamp: BigInt(p.timestamp),
      confidence: BigInt(p.confidence),
    })),
    lastUpdated: BigInt(datum.lastUpdated),
  }, OracleDatumSchema);
}

/**
 * Parse Plutus Data to VaultDatum
 */
export function plutusDataToVaultDatum(data: string): VaultDatum {
  const parsed = Data.from(data, VaultDatumSchema);
  
  // Convert Maps back to Records
  const reservedAmounts: Record<string, bigint> = {};
  for (const [key, value] of parsed.reservedAmounts) {
    reservedAmounts[`${key.policyId}.${key.assetName}`] = value;
  }

  const openInterestLong: Record<string, bigint> = {};
  for (const [key, value] of parsed.openInterestLong) {
    openInterestLong[`${key.policyId}.${key.assetName}`] = value;
  }

  const openInterestShort: Record<string, bigint> = {};
  for (const [key, value] of parsed.openInterestShort) {
    openInterestShort[`${key.policyId}.${key.assetName}`] = value;
  }

  const guaranteedUsd: Record<string, bigint> = {};
  for (const [key, value] of parsed.guaranteedUsd) {
    guaranteedUsd[`${key.policyId}.${key.assetName}`] = value;
  }

  const maxUtilization: Record<string, number> = {};
  for (const [key, value] of parsed.maxUtilization) {
    maxUtilization[`${key.policyId}.${key.assetName}`] = Number(value);
  }

  const cumulativeFundingRateLong: Record<string, bigint> = {};
  for (const [key, value] of parsed.cumulativeFundingRateLong) {
    cumulativeFundingRateLong[`${key.policyId}.${key.assetName}`] = value;
  }

  const cumulativeFundingRateShort: Record<string, bigint> = {};
  for (const [key, value] of parsed.cumulativeFundingRateShort) {
    cumulativeFundingRateShort[`${key.policyId}.${key.assetName}`] = value;
  }

  const lastFundingTimes: Record<string, number> = {};
  for (const [key, value] of parsed.lastFundingTimes) {
    lastFundingTimes[`${key.policyId}.${key.assetName}`] = Number(value);
  }

  return {
    vaultNft: parsed.vaultNft,
    admin: parsed.admin,
    totalLiquidity: parsed.totalLiquidity,
    glpSupply: parsed.glpSupply,
    mintBurnFeeBasisPoints: Number(parsed.mintBurnFeeBasisPoints),
    marginFeeBasisPoints: Number(parsed.marginFeeBasisPoints),
    liquidationFeeUsd: parsed.liquidationFeeUsd,
    maxLeverage: Number(parsed.maxLeverage),
    whitelistedTokens: parsed.whitelistedTokens,
    reservedAmounts,
    openInterestLong,
    openInterestShort,
    guaranteedUsd,
    maxUtilization,
    cumulativeFundingRateLong,
    cumulativeFundingRateShort,
    lastFundingTimes,
  };
}

/**
 * Parse Plutus Data to PositionDatum
 */
export function plutusDataToPositionDatum(data: string): PositionDatum {
  const parsed = Data.from(data, PositionDatumSchema);
  return {
    account: parsed.account,
    indexToken: parsed.indexToken,
    collateral: parsed.collateral,
    size: parsed.size,
    averagePrice: parsed.averagePrice,
    entryFundingRate: parsed.entryFundingRate,
    isLong: parsed.isLong,
    lastIncreasedTime: Number(parsed.lastIncreasedTime),
  };
}

/**
 * Parse Plutus Data to OracleDatum
 */
export function plutusDataToOracleDatum(data: string): OracleDatum {
  const parsed = Data.from(data, OracleDatumSchema);
  return {
    oracleAdmin: parsed.oracleAdmin,
    prices: parsed.prices.map(p => ({
      token: p.token,
      price: p.price,
      timestamp: Number(p.timestamp),
      confidence: Number(p.confidence),
    })),
    lastUpdated: Number(parsed.lastUpdated),
  };
}

