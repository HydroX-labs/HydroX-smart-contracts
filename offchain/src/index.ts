import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";
import { initLucid } from "./config/lucid";
import { TransactionBuilder } from "./services/transaction-builder";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Global Lucid instance
let lucid: any;
let txBuilder: TransactionBuilder;

// Initialize
async function init() {
  console.log("🚀 Initializing BaobabX GMX Backend...");
  
  lucid = await initLucid();
  txBuilder = new TransactionBuilder(lucid);
  
  console.log("✅ Lucid initialized");
  console.log(`📡 Network: ${process.env.NETWORK}`);
}

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Get vault info
app.get("/api/vault", async (req, res) => {
  try {
    // In real app, query from indexer
    res.json({
      total_liquidity: "1000000",
      glp_supply: "950000",
      reserved: "100000",
      utilization: "10%",
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Open long position
app.post("/api/position/open-long", async (req, res) => {
  try {
    const { indexToken, collateral, leverage, userAddress } = req.body;

    // Validate input
    if (!indexToken || !collateral || !leverage || !userAddress) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Build transaction
    const tx = await txBuilder.openLongPosition({
      indexToken,
      collateral: BigInt(collateral),
      leverage: Number(leverage),
      userAddress,
    });

    // Return unsigned transaction for user to sign
    res.json({
      success: true,
      transaction: tx.toString(),
      message: "Transaction built. Please sign and submit.",
    });
  } catch (error: any) {
    console.error("Error opening position:", error);
    res.status(500).json({ error: error.message });
  }
});

// Get positions for user
app.get("/api/positions/:address", async (req, res) => {
  try {
    const { address } = req.params;

    // In real app, query from indexer
    res.json({
      positions: [
        {
          id: "position_1",
          index_token: "BTC",
          type: "Long",
          size: "10000",
          collateral: "1000",
          entry_price: "40000",
          current_pnl: "+500",
        },
      ],
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Start server
init().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📖 API: http://localhost:${PORT}/api`);
    console.log(`💚 Health: http://localhost:${PORT}/health`);
  });
});

export default app;

