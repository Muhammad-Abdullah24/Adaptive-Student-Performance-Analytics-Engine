const oracledb = require("oracledb");
require("dotenv").config();

// Use Thin mode — no Oracle Client installation needed
oracledb.initOracleClient();

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
  return pool.getConnection();
}

async function closePool() {
  await pool.close(10);
}

module.exports = { createPool, getConnection, closePool };
