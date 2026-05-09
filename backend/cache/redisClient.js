const Redis = require("ioredis");

const client = new Redis(process.env.REDIS_URL || "redis://localhost:6379");

client.on("connect", () => console.log("✅ Redis connected."));
client.on("error",   (err) => console.error("❌ Redis error:", err.message));

// Pass a cache key, how many seconds to keep it, and a function that fetches from Oracle.
// If the key exists in Redis it returns immediately. Otherwise it runs fetchFn, stores the
// result, and returns it. You never have to write this if/else yourself in the routes.
async function cacheOrFetch(key, ttlSeconds, fetchFn) {
  const cached = await client.get(key);
  if (cached) {
    console.log(`[CACHE HIT]  ${key}`);
    return JSON.parse(cached);
  }
  console.log(`[CACHE MISS] ${key}`);
  const data = await fetchFn();
  await client.setex(key, ttlSeconds, JSON.stringify(data));
  return data;
}

module.exports = { client, cacheOrFetch };