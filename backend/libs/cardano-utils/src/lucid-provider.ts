import { Lucid, Blockfrost, Ogmios } from 'lucid-cardano';

export interface CardanoProviderConfig {
  type: 'blockfrost' | 'ogmios';
  network: 'Mainnet' | 'Preprod' | 'Preview';
  // Blockfrost config
  projectId?: string;
  // Ogmios config
  ogmiosUrl?: string;
  kupoUrl?: string;
}

/**
 * Initialize Lucid instance with provider
 */
export async function initLucid(config: CardanoProviderConfig): Promise<Lucid> {
  let provider;

  if (config.type === 'blockfrost') {
    if (!config.projectId) {
      throw new Error('Blockfrost projectId is required');
    }
    provider = new Blockfrost(
      `https://cardano-${config.network.toLowerCase()}.blockfrost.io/api/v0`,
      config.projectId
    );
  } else if (config.type === 'ogmios') {
    if (!config.ogmiosUrl) {
      throw new Error('Ogmios URL is required');
    }
    provider = new Ogmios(config.ogmiosUrl, config.kupoUrl);
  } else {
    throw new Error(`Unsupported provider type: ${config.type}`);
  }

  return await Lucid.new(provider, config.network);
}

/**
 * Singleton Lucid instance manager
 */
export class LucidProvider {
  private static instance: Lucid | null = null;
  private static config: CardanoProviderConfig | null = null;

  static async initialize(config: CardanoProviderConfig): Promise<void> {
    this.config = config;
    this.instance = await initLucid(config);
  }

  static getInstance(): Lucid {
    if (!this.instance) {
      throw new Error('LucidProvider not initialized. Call initialize() first.');
    }
    return this.instance;
  }

  static getConfig(): CardanoProviderConfig {
    if (!this.config) {
      throw new Error('LucidProvider not initialized. Call initialize() first.');
    }
    return this.config;
  }
}

