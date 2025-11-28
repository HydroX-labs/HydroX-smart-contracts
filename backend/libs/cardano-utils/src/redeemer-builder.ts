import { Data } from 'lucid-cardano';
import {
  VaultRedeemerData,
  VaultRedeemer,
  PositionRedeemer,
  OracleRedeemerData,
  OracleRedeemer,
  AssetClass,
} from '@hydrox/types';

/**
 * Redeemer builders for validator actions
 */

const AssetClassSchema = Data.Object({
  policyId: Data.Bytes(),
  assetName: Data.Bytes(),
});

// Vault Redeemer Schemas
const AddLiquiditySchema = Data.Object({
  AddLiquidity: Data.Object({
    amount: Data.Integer(),
  }),
});

const RemoveLiquiditySchema = Data.Object({
  RemoveLiquidity: Data.Object({
    glpAmount: Data.Integer(),
  }),
});

const IncreasePositionSchema = Data.Object({
  IncreasePosition: Data.Object({
    account: Data.Bytes(),
    indexToken: AssetClassSchema,
    collateralDelta: Data.Integer(),
    sizeDelta: Data.Integer(),
    isLong: Data.Boolean(),
  }),
});

const DecreasePositionSchema = Data.Object({
  DecreasePosition: Data.Object({
    account: Data.Bytes(),
    indexToken: AssetClassSchema,
    collateralDelta: Data.Integer(),
    sizeDelta: Data.Integer(),
    isLong: Data.Boolean(),
  }),
});

const LiquidatePositionSchema = Data.Object({
  LiquidatePosition: Data.Object({
    account: Data.Bytes(),
    indexToken: AssetClassSchema,
    isLong: Data.Boolean(),
  }),
});

const UpdateFeesSchema = Data.Enum([
  Data.Literal('UpdateFees'),
]);

const UpdateFundingRateSchema = Data.Enum([
  Data.Literal('UpdateFundingRate'),
]);

// Position Redeemer Schemas
const ClosePositionSchema = Data.Enum([
  Data.Literal('ClosePosition'),
]);

const UpdatePositionSchema = Data.Enum([
  Data.Literal('UpdatePosition'),
]);

// Oracle Redeemer Schemas
const PriceDataSchema = Data.Object({
  token: AssetClassSchema,
  price: Data.Integer(),
  timestamp: Data.Integer(),
  confidence: Data.Integer(),
});

const UpdatePricesSchema = Data.Object({
  UpdatePrices: Data.Object({
    newPrices: Data.Array(PriceDataSchema),
  }),
});

const UpdateAdminSchema = Data.Object({
  UpdateAdmin: Data.Object({
    newAdmin: Data.Bytes(),
  }),
});

/**
 * Build Vault Redeemer
 */
export function buildVaultRedeemer(redeemer: VaultRedeemerData): string {
  switch (redeemer.type) {
    case VaultRedeemer.AddLiquidity:
      return Data.to({
        AddLiquidity: {
          amount: redeemer.amount,
        },
      }, AddLiquiditySchema);

    case VaultRedeemer.RemoveLiquidity:
      return Data.to({
        RemoveLiquidity: {
          glpAmount: redeemer.glpAmount,
        },
      }, RemoveLiquiditySchema);

    case VaultRedeemer.IncreasePosition:
      return Data.to({
        IncreasePosition: {
          account: redeemer.account,
          indexToken: redeemer.indexToken,
          collateralDelta: redeemer.collateralDelta,
          sizeDelta: redeemer.sizeDelta,
          isLong: redeemer.isLong,
        },
      }, IncreasePositionSchema);

    case VaultRedeemer.DecreasePosition:
      return Data.to({
        DecreasePosition: {
          account: redeemer.account,
          indexToken: redeemer.indexToken,
          collateralDelta: redeemer.collateralDelta,
          sizeDelta: redeemer.sizeDelta,
          isLong: redeemer.isLong,
        },
      }, DecreasePositionSchema);

    case VaultRedeemer.LiquidatePosition:
      return Data.to({
        LiquidatePosition: {
          account: redeemer.account,
          indexToken: redeemer.indexToken,
          isLong: redeemer.isLong,
        },
      }, LiquidatePositionSchema);

    case VaultRedeemer.UpdateFees:
      return Data.to('UpdateFees', UpdateFeesSchema);

    case VaultRedeemer.UpdateFundingRate:
      return Data.to('UpdateFundingRate', UpdateFundingRateSchema);

    default:
      throw new Error(`Unknown vault redeemer type: ${(redeemer as any).type}`);
  }
}

/**
 * Build Position Redeemer
 */
export function buildPositionRedeemer(redeemer: PositionRedeemer): string {
  switch (redeemer) {
    case PositionRedeemer.ClosePosition:
      return Data.to('ClosePosition', ClosePositionSchema);

    case PositionRedeemer.UpdatePosition:
      return Data.to('UpdatePosition', UpdatePositionSchema);

    default:
      throw new Error(`Unknown position redeemer: ${redeemer}`);
  }
}

/**
 * Build Oracle Redeemer
 */
export function buildOracleRedeemer(redeemer: OracleRedeemerData): string {
  switch (redeemer.type) {
    case OracleRedeemer.UpdatePrices:
      return Data.to({
        UpdatePrices: {
          newPrices: redeemer.newPrices.map(p => ({
            token: p.token,
            price: p.price,
            timestamp: BigInt(p.timestamp),
            confidence: BigInt(p.confidence),
          })),
        },
      }, UpdatePricesSchema);

    case OracleRedeemer.UpdateAdmin:
      return Data.to({
        UpdateAdmin: {
          newAdmin: redeemer.newAdmin,
        },
      }, UpdateAdminSchema);

    default:
      throw new Error(`Unknown oracle redeemer type: ${(redeemer as any).type}`);
  }
}

