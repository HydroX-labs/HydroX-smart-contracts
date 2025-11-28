import { UTxO as LucidUTxO } from 'lucid-cardano';
import { UTxO, AssetClass } from '@hydrox/types';

/**
 * UTXO utility functions
 */

/**
 * Convert Lucid UTxO to internal UTxO type
 */
export function lucidUtxoToUtxo(utxo: LucidUTxO): UTxO {
  const assets: Record<string, bigint> = {};
  
  for (const [unit, amount] of Object.entries(utxo.assets)) {
    if (unit !== 'lovelace') {
      assets[unit] = amount;
    }
  }

  return {
    txHash: utxo.txHash,
    outputIndex: utxo.outputIndex,
    address: utxo.address,
    value: {
      lovelace: utxo.assets.lovelace || 0n,
      assets,
    },
    datum: utxo.datum ? {
      type: 'inline',
      data: utxo.datum,
    } : undefined,
    datumHash: utxo.datumHash,
    scriptRef: utxo.scriptRef,
  };
}

/**
 * Find UTxO containing specific NFT
 */
export function findUtxoWithNft(
  utxos: LucidUTxO[],
  nft: AssetClass
): LucidUTxO | undefined {
  const nftUnit = `${nft.policyId}${nft.assetName}`;
  return utxos.find(utxo => utxo.assets[nftUnit] === 1n);
}

/**
 * Find UTxOs at specific address
 */
export function findUtxosAtAddress(
  utxos: LucidUTxO[],
  address: string
): LucidUTxO[] {
  return utxos.filter(utxo => utxo.address === address);
}

/**
 * Calculate total ADA in UTxOs
 */
export function calculateTotalAda(utxos: LucidUTxO[]): bigint {
  return utxos.reduce((sum, utxo) => sum + (utxo.assets.lovelace || 0n), 0n);
}

/**
 * Calculate total of specific asset in UTxOs
 */
export function calculateTotalAsset(
  utxos: LucidUTxO[],
  assetUnit: string
): bigint {
  return utxos.reduce((sum, utxo) => sum + (utxo.assets[assetUnit] || 0n), 0n);
}

/**
 * Select UTxOs for collateral (plain ADA only, no assets)
 */
export function selectCollateralUtxos(
  utxos: LucidUTxO[],
  requiredLovelace: bigint = 5_000_000n
): LucidUTxO[] {
  // Filter UTxOs with only ADA (no other assets)
  const pureAdaUtxos = utxos.filter(utxo => {
    const assetKeys = Object.keys(utxo.assets).filter(k => k !== 'lovelace');
    return assetKeys.length === 0 && (utxo.assets.lovelace || 0n) >= requiredLovelace;
  });

  // Sort by ADA amount (prefer smaller UTxOs for collateral)
  pureAdaUtxos.sort((a, b) => {
    const aAda = a.assets.lovelace || 0n;
    const bAda = b.assets.lovelace || 0n;
    return aAda < bAda ? -1 : aAda > bAda ? 1 : 0;
  });

  // Return up to 3 UTxOs for collateral
  return pureAdaUtxos.slice(0, 3);
}

/**
 * Format UTxO reference as string
 */
export function formatUtxoRef(utxo: LucidUTxO): string {
  return `${utxo.txHash}#${utxo.outputIndex}`;
}

/**
 * Parse UTxO reference from string
 */
export function parseUtxoRef(ref: string): { txHash: string; outputIndex: number } {
  const [txHash, outputIndex] = ref.split('#');
  return {
    txHash,
    outputIndex: parseInt(outputIndex, 10),
  };
}

