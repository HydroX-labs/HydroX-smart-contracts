import { Lucid, UTxO, Data, Constr } from "lucid-cardano";
import {
  VaultDatum,
  PositionDatum,
  Position,
  PositionType,
  AssetClass,
  PRICE_PRECISION,
  BASIS_POINTS_DIVISOR,
  assetClassToString,
} from "../types";
import { ADDRESSES } from "../config/lucid";

export class TransactionBuilder {
  constructor(private lucid: Lucid) {}

  /**
   * Build transaction to open a long position
   */
  async openLongPosition(params: {
    indexToken: AssetClass;
    collateral: bigint;
    leverage: number;
    userAddress: string;
  }) {
    const { indexToken, collateral, leverage, userAddress } = params;

    // 1. Get vault UTXO (in real app, from indexer)
    const vaultUtxos = await this.lucid.utxosAt(ADDRESSES.vault);
    if (vaultUtxos.length === 0) {
      throw new Error("Vault UTXO not found");
    }
    const vaultUtxo = vaultUtxos[0];

    // 2. Parse vault datum
    const vaultDatum = await this.parseVaultDatum(vaultUtxo);

    // 3. Get oracle price (mock for now)
    const currentPrice = await this.getCurrentPrice(indexToken);

    // 4. Calculate position details
    const size = collateral * BigInt(leverage);
    const marginFee = this.calculateFee(
      size,
      vaultDatum.margin_fee_basis_points
    );
    const totalCost = collateral + marginFee;

    // 5. Validate
    this.validateLeverage(leverage, Number(vaultDatum.max_leverage));
    this.validateUtilization(vaultDatum, indexToken, collateral);

    // 6. Create new vault datum
    const newVaultDatum = this.updateVaultForIncrease(
      vaultDatum,
      indexToken,
      collateral,
      size,
      marginFee,
      true // is_long
    );

    // 7. Create position datum
    const positionDatum: PositionDatum = {
      position: {
        owner: userAddress,
        index_token: indexToken,
        position_type: PositionType.Long,
        size,
        collateral,
        average_price: currentPrice,
        entry_funding_rate: this.getFundingRate(
          vaultDatum.cumulative_funding_rate_long,
          indexToken
        ),
        last_increased_time: BigInt(Date.now()),
      },
      vault_ref: `${vaultUtxo.txHash}#${vaultUtxo.outputIndex}`,
    };

    // 8. Build transaction
    const redeemer = Data.to(
      new Constr(2, [
        // IncreasePosition
        Data.fromJson(userAddress),
        this.assetToData(indexToken),
        Data.fromJson(collateral.toString()),
        Data.fromJson(size.toString()),
        Data.fromJson(true), // is_long
      ])
    );

    const tx = await this.lucid
      .newTx()
      .collectFrom([vaultUtxo], redeemer)
      .payToContract(
        ADDRESSES.vault,
        { inline: Data.to(newVaultDatum) },
        { lovelace: 2000000n } // Min ADA
      )
      .payToContract(
        ADDRESSES.position,
        { inline: Data.to(positionDatum) },
        { lovelace: 2000000n }
      )
      .complete();

    return tx;
  }

  /**
   * Calculate fee based on basis points
   */
  private calculateFee(amount: bigint, feeBasisPoints: bigint): bigint {
    return (amount * feeBasisPoints) / BASIS_POINTS_DIVISOR;
  }

  /**
   * Validate leverage
   */
  private validateLeverage(leverage: number, maxLeverage: number) {
    if (leverage > maxLeverage) {
      throw new Error(
        `Leverage ${leverage}x exceeds maximum ${maxLeverage}x`
      );
    }
  }

  /**
   * Validate utilization
   */
  private validateUtilization(
    vaultDatum: VaultDatum,
    token: AssetClass,
    additionalCollateral: bigint
  ) {
    const currentReserved = this.getTokenValue(
      vaultDatum.reserved_amounts,
      token
    );
    const newReserved = currentReserved + additionalCollateral;
    const utilization =
      (newReserved * 10000n) / vaultDatum.total_liquidity;

    const maxUtil = this.getTokenValue(vaultDatum.max_utilization, token);
    if (utilization > maxUtil) {
      throw new Error(
        `Utilization ${utilization}bps exceeds maximum ${maxUtil}bps`
      );
    }
  }

  /**
   * Update vault datum for position increase
   */
  private updateVaultForIncrease(
    vaultDatum: VaultDatum,
    token: AssetClass,
    collateral: bigint,
    size: bigint,
    fee: bigint,
    isLong: boolean
  ): VaultDatum {
    return {
      ...vaultDatum,
      total_liquidity: vaultDatum.total_liquidity + fee,
      reserved_amounts: this.updateTokenValue(
        vaultDatum.reserved_amounts,
        token,
        this.getTokenValue(vaultDatum.reserved_amounts, token) + collateral
      ),
      open_interest_long: isLong
        ? this.updateTokenValue(
            vaultDatum.open_interest_long,
            token,
            this.getTokenValue(vaultDatum.open_interest_long, token) + size
          )
        : vaultDatum.open_interest_long,
      open_interest_short: !isLong
        ? this.updateTokenValue(
            vaultDatum.open_interest_short,
            token,
            this.getTokenValue(vaultDatum.open_interest_short, token) + size
          )
        : vaultDatum.open_interest_short,
    };
  }

  /**
   * Get value for specific token from list
   */
  private getTokenValue(
    list: [AssetClass, bigint][],
    token: AssetClass
  ): bigint {
    const entry = list.find(
      ([t]) =>
        t.policyId === token.policyId && t.assetName === token.assetName
    );
    return entry ? entry[1] : 0n;
  }

  /**
   * Update token value in list
   */
  private updateTokenValue(
    list: [AssetClass, bigint][],
    token: AssetClass,
    newValue: bigint
  ): [AssetClass, bigint][] {
    const index = list.findIndex(
      ([t]) =>
        t.policyId === token.policyId && t.assetName === token.assetName
    );

    if (index >= 0) {
      const newList = [...list];
      newList[index] = [token, newValue];
      return newList;
    } else {
      return [...list, [token, newValue]];
    }
  }

  /**
   * Get funding rate for token
   */
  private getFundingRate(
    fundingRates: [AssetClass, bigint][],
    token: AssetClass
  ): bigint {
    return this.getTokenValue(fundingRates, token);
  }

  /**
   * Parse vault datum from UTXO
   */
  private async parseVaultDatum(utxo: UTxO): Promise<VaultDatum> {
    // In real implementation, properly parse the datum
    // For now, return a mock
    return {
      stablecoin: { policyId: "", assetName: "USDC" },
      total_liquidity: 1000000n * PRICE_PRECISION,
      glp_supply: 950000n * PRICE_PRECISION,
      reserved_amounts: [],
      guaranteed_usd: [],
      open_interest_long: [],
      open_interest_short: [],
      cumulative_funding_rate_long: [],
      cumulative_funding_rate_short: [],
      last_funding_times: [],
      whitelisted_tokens: [],
      max_utilization: [],
      admin: "",
      mint_burn_fee_basis_points: 30n,
      margin_fee_basis_points: 30n,
      liquidation_fee_usd: 10n * PRICE_PRECISION,
      min_profit_time: 0n,
      max_leverage: 50n,
    };
  }

  /**
   * Get current price from oracle
   */
  private async getCurrentPrice(token: AssetClass): Promise<bigint> {
    // Mock price for testing
    if (token.assetName === "BTC") {
      return 40000n * PRICE_PRECISION;
    }
    if (token.assetName === "ETH") {
      return 2500n * PRICE_PRECISION;
    }
    return 1n * PRICE_PRECISION;
  }

  /**
   * Convert AssetClass to Data
   */
  private assetToData(asset: AssetClass): Data {
    return Data.to(
      new Constr(0, [Data.fromJson(asset.policyId), Data.fromJson(asset.assetName)])
    );
  }
}

