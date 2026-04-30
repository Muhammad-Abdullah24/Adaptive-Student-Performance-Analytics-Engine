const oracledb = require("oracledb");
require("dotenv").config();

// oracledb v6+ uses Thin mode by default — no Oracle Client installation needed.
// Do NOT call oracledb.initOracleClient() here; that would switch to Thick mode
// and require the Oracle Instant Client libraries to be present on the host.

let pool;

async function createPool() {
  try {
    pool = await oracledb.createPool({
      user:             process.env.DB_USER,
      password:         process.env.DB_PASSWORD,
      connectionString: process.env.DB_CONNECTION_STRING, // e.g. localhost/XEPDB1
      poolMin:          2,
      poolMax:          10,
      poolIncrement:    1,
    });
    console.log("✅ Oracle connection pool created.");
  } catch (err) {
    console.error("❌ Failed to create Oracle pool:", err.message);
    process.exit(1);
  }
}

async function getConnection() {
  if (!pool) throw new Error("Connection pool has not been initialised. Call createPool() first.");
  return pool.getConnection();
}

async function closePool() {
  await pool.close(10);
}

module.exports = { createPool, getConnection, closePool };
