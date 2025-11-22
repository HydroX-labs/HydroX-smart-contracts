import { Data } from "lucid-cardano";

// Asset Class
export interface AssetClass {
  policyId: string;
  assetName: string;
}

// Position Type
export enum PositionType {
  Long = "Long",
  Short = "Short",
}

// Vault Datum
export interface VaultDatum {
  stablecoin: AssetClass;
  total_liquidity: bigint;
  glp_supply: bigint;
  reserved_amounts: [AssetClass, bigint][];
  guaranteed_usd: [AssetClass, bigint][];
  open_interest_long: [AssetClass, bigint][];
  open_interest_short: [AssetClass, bigint][];
  cumulative_funding_rate_long: [AssetClass, bigint][];
  cumulative_funding_rate_short: [AssetClass, bigint][];
  last_funding_times: [AssetClass, bigint][];
  whitelisted_tokens: AssetClass[];
  max_utilization: [AssetClass, bigint][];
  admin: string;
  mint_burn_fee_basis_points: bigint;
  margin_fee_basis_points: bigint;
  liquidation_fee_usd: bigint;
  min_profit_time: bigint;
  max_leverage: bigint;
}

// Position
export interface Position {
  owner: string;
  index_token: AssetClass;
  position_type: PositionType;
  size: bigint;
  collateral: bigint;
  average_price: bigint;
  entry_funding_rate: bigint;
  last_increased_time: bigint;
}

// Position Datum
export interface PositionDatum {
  position: Position;
  vault_ref: string;
}

// Oracle Price Data
export interface PriceData {
  token: AssetClass;
  price: bigint;
  timestamp: bigint;
  confidence: bigint;
}

// Oracle Datum
export interface OracleDatum {
  prices: PriceData[];
  oracle_admin: string;
  max_price_age: bigint;
}

// Vault Redeemers
export enum VaultRedeemerType {
  AddLiquidity = 0,
  RemoveLiquidity = 1,
  IncreasePosition = 2,
  DecreasePosition = 3,
  LiquidatePosition = 4,
  UpdateFees = 5,
  UpdateFundingRate = 6,
}

export interface AddLiquidityRedeemer {
  type: VaultRedeemerType.AddLiquidity;
  amount: bigint;
}

export interface IncreasePositionRedeemer {
  type: VaultRedeemerType.IncreasePosition;
  account: string;
  index_token: AssetClass;
  collateral_delta: bigint;
  size_delta: bigint;
  is_long: boolean;
}

export type VaultRedeemer = 
  | AddLiquidityRedeemer 
  | IncreasePositionRedeemer
  // ... other redeemers

// Constants
export const PRICE_PRECISION = 10n ** 30n;
export const BASIS_POINTS_DIVISOR = 10000n;
export const FUNDING_RATE_PRECISION = 1000000n;

// Helper function to convert AssetClass to string
export function assetClassToString(asset: AssetClass): string {
  return `${asset.policyId}${asset.assetName}`;
}

// Helper to create Data representation
export function assetClassToData(asset: AssetClass): Data {
  return Data.to(new Constr(0, [
    Data.fromJson(asset.policyId),
    Data.fromJson(asset.assetName)
  ]));
}

