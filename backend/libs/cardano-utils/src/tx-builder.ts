import { Lucid, TxComplete, UTxO, Assets } from 'lucid-cardano';
import { LucidProvider } from './lucid-provider';
import { ScriptRegistryManager } from './script-registry';

/**
 * Transaction builder utilities
 */

export class TxBuilder {
  private lucid: Lucid;

  constructor(lucid?: Lucid) {
    this.lucid = lucid || LucidProvider.getInstance();
  }

  /**
   * Start building a new transaction
   */
  newTx() {
    return this.lucid.newTx();
  }

  /**
   * Set transaction validity interval (TTL)
   * @param validFor - Validity duration in milliseconds (default: 10 minutes)
   */
  async setValidityInterval(tx: any, validFor: number = 600_000): Promise<any> {
    const currentTime = Date.now();
    const validFrom = currentTime - 60_000; // 1 minute before now
    const validTo = currentTime + validFor;

    return tx
      .validFrom(validFrom)
      .validTo(validTo);
  }

  /**
   * Add collateral inputs
   */
  async addCollateral(tx: any, collateralUtxos?: UTxO[]): Promise<any> {
    if (collateralUtxos && collateralUtxos.length > 0) {
      return tx.collectFrom(collateralUtxos);
    }

    // Auto-select collateral
    const utxos = await this.lucid.wallet.getUtxos();
    const collateral = utxos
      .filter(u => {
        const keys = Object.keys(u.assets).filter(k => k !== 'lovelace');
        return keys.length === 0 && (u.assets.lovelace || 0n) >= 5_000_000n;
      })
      .slice(0, 3);

    if (collateral.length === 0) {
      throw new Error('No suitable collateral UTxOs found');
    }

    return tx.collectFrom(collateral);
  }

  /**
   * Complete and return unsigned transaction
   */
  async complete(tx: any): Promise<TxComplete> {
    return await tx.complete();
  }

  /**
   * Sign transaction with wallet
   */
  async sign(txComplete: TxComplete): Promise<string> {
    const signedTx = await txComplete.sign().complete();
    return signedTx.toCBOR();
  }

  /**
   * Submit signed transaction
   */
  async submit(signedTxCbor: string): Promise<string> {
    const txSigned = this.lucid.fromTx(signedTxCbor);
    return await txSigned.submit();
  }

  /**
   * Build, sign, and submit transaction (for server-side operations)
   */
  async buildSignSubmit(txBuilder: (tx: any) => Promise<any>): Promise<string> {
    const tx = await txBuilder(this.newTx());
    const txComplete = await this.complete(tx);
    const signedTxCbor = await this.sign(txComplete);
    return await this.submit(signedTxCbor);
  }

  /**
   * Get transaction hash from CBOR
   */
  getTxHash(txCbor: string): string {
    const tx = this.lucid.fromTx(txCbor);
    return tx.toHash();
  }

  /**
   * Estimate transaction fee
   */
  async estimateFee(tx: any): Promise<bigint> {
    const txComplete = await tx.complete();
    return BigInt(txComplete.txComplete.body().fee().to_str());
  }
}

/**
 * Helper to build asset units
 */
export function buildAssetUnit(policyId: string, assetName: string): string {
  return `${policyId}${assetName}`;
}

/**
 * Helper to build Assets object
 */
export function buildAssets(assets: Record<string, bigint>): Assets {
  const result: Assets = {};
  for (const [unit, amount] of Object.entries(assets)) {
    result[unit] = amount;
  }
  return result;
}

