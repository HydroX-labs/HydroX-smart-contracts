import { AssetClass } from './cardano';

/**
 * Oracle-related types matching validators/oracle.ak
 */

export interface PriceData {
  token: AssetClass;
  price: bigint; // Price in USD with 8 decimals (e.g., 50000_00000000 = $50,000)
  timestamp: number; // Unix timestamp
  confidence: number; // Confidence level in basis points (10000 = 100%)
}

export interface OracleDatum {
  oracleAdmin: string; // PubKeyHash
  prices: PriceData[];
  lastUpdated: number;
}

export enum OracleRedeemer {
  UpdatePrices = 'UpdatePrices',
  UpdateAdmin = 'UpdateAdmin',
}

export interface UpdatePricesRedeemer {
  type: OracleRedeemer.UpdatePrices;
  newPrices: PriceData[];
}

export interface UpdateAdminRedeemer {
  type: OracleRedeemer.UpdateAdmin;
  newAdmin: string;
}

export type OracleRedeemerData = UpdatePricesRedeemer | UpdateAdminRedeemer;

export interface OracleState {
  utxo: {
    txHash: string;
    outputIndex: number;
  };
  datum: OracleDatum;
  lastUpdated: Date;
}

export interface PriceFeed {
  source: string; // 'binance' | 'coinbase' | 'chainlink' etc.
  token: AssetClass;
  price: bigint;
  timestamp: number;
  volume24h?: bigint;
}

