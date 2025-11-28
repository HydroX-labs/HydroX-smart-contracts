/**
 * Cardano-specific types
 */

export interface AssetClass {
  policyId: string;
  assetName: string;
}

export interface UTxO {
  txHash: string;
  outputIndex: number;
  address: string;
  value: Value;
  datum?: Datum;
  datumHash?: string;
  scriptRef?: string;
}

export interface Value {
  lovelace: bigint;
  assets: Record<string, bigint>; // "policyId.assetName" -> amount
}

export interface Datum {
  type: 'inline' | 'hash';
  data: any;
  hash?: string;
}

export interface Redeemer {
  tag: 'spend' | 'mint' | 'cert' | 'reward';
  index: number;
  data: any;
}

export interface Transaction {
  hash: string;
  cbor: string;
  inputs: UTxO[];
  outputs: UTxO[];
  mint?: Record<string, bigint>;
  fee: bigint;
  validFrom?: number;
  validTo?: number;
  signatories: string[];
  metadata?: Record<string, any>;
}

export interface TxStatus {
  txHash: string;
  status: 'pending' | 'submitted' | 'confirmed' | 'failed';
  confirmations?: number;
  blockHeight?: number;
  blockHash?: string;
  submittedAt?: Date;
  confirmedAt?: Date;
  error?: string;
}

