import { Lucid, Blockfrost, Network } from "lucid-cardano";
import dotenv from "dotenv";

dotenv.config();

export async function initLucid(): Promise<Lucid> {
  const network = (process.env.NETWORK || "Preview") as Network;
  
  const lucid = await Lucid.new(
    new Blockfrost(
      process.env.BLOCKFROST_URL!,
      process.env.BLOCKFROST_API_KEY!
    ),
    network
  );

  return lucid;
}

export async function initLucidWithSeed(seedPhrase: string): Promise<Lucid> {
  const lucid = await initLucid();
  lucid.selectWalletFromSeed(seedPhrase);
  return lucid;
}

export const ADDRESSES = {
  vault: process.env.VAULT_ADDRESS || "",
  position: process.env.POSITION_ADDRESS || "",
  oracle: process.env.ORACLE_ADDRESS || "",
};

export const POLICY_IDS = {
  glp: process.env.GLP_POLICY_ID || "",
  stablecoin: process.env.STABLECOIN_POLICY_ID || "",
};

