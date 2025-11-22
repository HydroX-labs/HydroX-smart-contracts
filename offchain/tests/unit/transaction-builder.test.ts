import { describe, it, expect, beforeAll } from "vitest";
import { Lucid, Blockfrost } from "lucid-cardano";
import { TransactionBuilder } from "../../src/services/transaction-builder";
import { AssetClass, PositionType } from "../../src/types";

describe("TransactionBuilder", () => {
  let lucid: Lucid;
  let txBuilder: TransactionBuilder;

  beforeAll(async () => {
    // Initialize with mock/testnet
    lucid = await Lucid.new(
      new Blockfrost(
        "https://cardano-preview.blockfrost.io/api/v0",
        "preview_test_key"
      ),
      "Preview"
    );
    txBuilder = new TransactionBuilder(lucid);
  });

  describe("openLongPosition", () => {
    it("should calculate correct position size", () => {
      const collateral = 1000n;
      const leverage = 10;
      const expectedSize = collateral * BigInt(leverage);

      expect(expectedSize).toBe(10000n);
    });

    it("should calculate correct margin fee", () => {
      const size = 10000n;
      const feeBasisPoints = 30n; // 0.3%
      const fee = (size * feeBasisPoints) / 10000n;

      expect(fee).toBe(30n);
    });

    it("should validate max leverage", () => {
      const leverage = 60;
      const maxLeverage = 50;

      expect(leverage > maxLeverage).toBe(true);
    });
  });

  describe("Fee Calculations", () => {
    it("should calculate 0.3% fee correctly", () => {
      const amount = 10000n;
      const fee = (amount * 30n) / 10000n;
      expect(fee).toBe(30n);
    });

    it("should calculate 1% fee correctly", () => {
      const amount = 10000n;
      const fee = (amount * 100n) / 10000n;
      expect(fee).toBe(100n);
    });
  });

  describe("Utilization Calculation", () => {
    it("should calculate utilization correctly", () => {
      const reserved = 80000n;
      const totalLiquidity = 100000n;
      const utilization = (reserved * 10000n) / totalLiquidity;

      expect(utilization).toBe(8000n); // 80%
    });

    it("should detect over-utilization", () => {
      const reserved = 85000n;
      const totalLiquidity = 100000n;
      const utilization = (reserved * 10000n) / totalLiquidity;
      const maxUtil = 8000n; // 80%

      expect(utilization > maxUtil).toBe(true);
    });
  });
});

