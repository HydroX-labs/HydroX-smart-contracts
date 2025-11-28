import { AssetClass } from './cardano';

/**
 * Position-related types matching validators/position.ak
 */

export interface PositionDatum {
  account: string; // PubKeyHash
  indexToken: AssetClass;
  collateral: bigint;
  size: bigint;
  averagePrice: bigint;
  entryFundingRate: bigint;
  isLong: boolean;
  lastIncreasedTime: number;
}

export enum PositionRedeemer {
  ClosePosition = 'ClosePosition',
  UpdatePosition = 'UpdatePosition',
}

export interface PositionState {
  utxo: {
    txHash: string;
    outputIndex: number;
  };
  datum: PositionDatum;
  lastUpdated: Date;
}

export interface PositionPnL {
  position: PositionDatum;
  currentPrice: bigint;
  pnl: bigint;
  pnlPercentage: number;
  marginFee: bigint;
  fundingFee: bigint;
  netPnl: bigint;
  liquidationPrice: bigint;
  isLiquidatable: boolean;
}

export interface PositionKey {
  account: string;
  indexToken: AssetClass;
  isLong: boolean;
}

export function positionKeyToString(key: PositionKey): string {
  return `${key.account}:${key.indexToken.policyId}.${key.indexToken.assetName}:${key.isLong ? 'long' : 'short'}`;
}

export function stringToPositionKey(str: string): PositionKey {
  const [account, token, direction] = str.split(':');
  const [policyId, assetName] = token.split('.');
  return {
    account,
    indexToken: { policyId, assetName },
    isLong: direction === 'long',
  };
}

