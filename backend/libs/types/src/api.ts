import { AssetClass } from './cardano';

/**
 * API request/response types
 */

// ============= Transaction Service =============

export interface BuildAddLiquidityRequest {
  userAddress: string;
  amount: string; // bigint as string
  collateralUtxos?: string[]; // Optional UTxO references for collateral
}

export interface BuildAddLiquidityResponse {
  txCbor: string;
  txHash: string;
  expectedGlp: string;
  fee: string;
  expiresAt: number; // Unix timestamp
}

export interface BuildRemoveLiquidityRequest {
  userAddress: string;
  glpAmount: string;
  collateralUtxos?: string[];
}

export interface BuildRemoveLiquidityResponse {
  txCbor: string;
  txHash: string;
  expectedStablecoin: string;
  fee: string;
  expiresAt: number;
}

export interface BuildIncreasePositionRequest {
  userAddress: string;
  indexToken: AssetClass;
  collateralDelta: string;
  sizeDelta: string;
  isLong: boolean;
  acceptablePrice: string; // Max price for long, min price for short
  collateralUtxos?: string[];
}

export interface BuildIncreasePositionResponse {
  txCbor: string;
  txHash: string;
  leverage: number;
  marginFee: string;
  estimatedLiquidationPrice: string;
  fee: string;
  expiresAt: number;
}

export interface BuildDecreasePositionRequest {
  userAddress: string;
  indexToken: AssetClass;
  collateralDelta: string;
  sizeDelta: string;
  isLong: boolean;
  acceptablePrice: string;
}

export interface BuildDecreasePositionResponse {
  txCbor: string;
  txHash: string;
  estimatedPayout: string;
  pnl: string;
  fee: string;
  expiresAt: number;
}

export interface SubmitTransactionRequest {
  signedTxCbor: string;
}

export interface SubmitTransactionResponse {
  txHash: string;
  submittedAt: number;
}

export interface TransactionStatusResponse {
  txHash: string;
  status: 'pending' | 'submitted' | 'confirmed' | 'failed';
  confirmations?: number;
  blockHeight?: number;
  blockHash?: string;
  submittedAt?: number;
  confirmedAt?: number;
  error?: string;
}

// ============= Position Service =============

export interface GetPositionsRequest {
  account: string;
}

export interface PositionResponse {
  account: string;
  indexToken: AssetClass;
  collateral: string;
  size: string;
  averagePrice: string;
  isLong: boolean;
  currentPrice: string;
  pnl: string;
  pnlPercentage: number;
  leverage: number;
  liquidationPrice: string;
  marginFee: string;
  fundingFee: string;
  netValue: string;
  isLiquidatable: boolean;
  lastUpdated: number;
}

export interface GetPositionsResponse {
  positions: PositionResponse[];
  totalValue: string;
  totalPnl: string;
}

export interface CalculatePnLRequest {
  account: string;
  indexToken: AssetClass;
  isLong: boolean;
  currentPrice?: string; // Optional, will use oracle price if not provided
}

export interface CalculatePnLResponse {
  pnl: string;
  pnlPercentage: number;
  marginFee: string;
  fundingFee: string;
  netPnl: string;
  liquidationPrice: string;
  isLiquidatable: boolean;
}

export interface GetLiquidatablePositionsResponse {
  positions: PositionResponse[];
  count: number;
}

// ============= Oracle Service =============

export interface GetPricesResponse {
  prices: Array<{
    token: AssetClass;
    price: string;
    timestamp: number;
    confidence: number;
    change24h?: number; // Percentage change
  }>;
  lastUpdated: number;
}

export interface GetPriceRequest {
  token: AssetClass;
}

export interface GetPriceResponse {
  token: AssetClass;
  price: string;
  timestamp: number;
  confidence: number;
  change24h?: number;
  high24h?: string;
  low24h?: string;
  volume24h?: string;
}

export interface UpdateOracleRequest {
  prices: Array<{
    token: AssetClass;
    price: string;
    timestamp: number;
    confidence: number;
  }>;
  adminSignature: string;
}

export interface UpdateOracleResponse {
  txHash: string;
  updatedPrices: number;
  submittedAt: number;
}

// ============= Indexer Service =============

export interface GetVaultUtxoResponse {
  txHash: string;
  outputIndex: number;
  address: string;
  datum: any; // VaultDatum
  value: {
    lovelace: string;
    assets: Record<string, string>;
  };
  lastUpdated: number;
}

export interface GetPositionUtxoRequest {
  account: string;
  indexToken: AssetClass;
  isLong: boolean;
}

export interface GetPositionUtxoResponse {
  txHash: string;
  outputIndex: number;
  address: string;
  datum: any; // PositionDatum
  value: {
    lovelace: string;
    assets: Record<string, string>;
  };
  lastUpdated: number;
}

// ============= WebSocket Events =============

export interface TxStatusEvent {
  type: 'tx_status';
  txHash: string;
  status: 'pending' | 'submitted' | 'confirmed' | 'failed';
  confirmations?: number;
  blockHeight?: number;
  timestamp: number;
}

export interface UtxoChangeEvent {
  type: 'utxo_change';
  utxoType: 'vault' | 'position' | 'oracle';
  txHash: string;
  outputIndex: number;
  action: 'created' | 'spent';
  timestamp: number;
}

export interface PriceUpdateEvent {
  type: 'price_update';
  token: AssetClass;
  price: string;
  previousPrice?: string;
  change: number;
  timestamp: number;
}

export type WebSocketEvent = TxStatusEvent | UtxoChangeEvent | PriceUpdateEvent;

