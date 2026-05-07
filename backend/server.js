require("dotenv").config();
const express  = require("express");
const cors     = require("cors");
const { createPool, closePool } = require("./db/connection");

const studentsRouter      = require("./routes/students");
const coursesRouter       = require("./routes/courses");
const analyticsRouter     = require("./routes/analytics");
const interventionsRouter = require("./routes/interventions");

const app  = express();
const PORT = process.env.PORT || 5000;

// ── Middleware ─────────────────────────────────────────────────────────────────
app.use(cors({ origin: "http://localhost:3000" })); // React dev server
app.use(express.json());

// ── Request logger ─────────────────────────────────────────────────────────────
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// ── Routes ─────────────────────────────────────────────────────────────────────
app.use("/api/students",      studentsRouter);
app.use("/api/courses",       coursesRouter);
app.use("/api/analytics",     analyticsRouter);
app.use("/api/interventions", interventionsRouter);

// Health check
app.get("/api/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString(), db: "Oracle 21c XE" });
});

// 404 fallback
app.use((_req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

// ── Start ──────────────────────────────────────────────────────────────────────
async function start() {
  await createPool();
  app.listen(PORT, () => {
    console.log(`\n🚀 ASPAE backend running on http://localhost:${PORT}`);
    console.log(`   Health: http://localhost:${PORT}/api/health\n`);
  });
}

// Graceful shutdown
process.on("SIGINT", async () => {
  console.log("\nShutting down...");
  await closePool();
  process.exit(0);
});

start();
