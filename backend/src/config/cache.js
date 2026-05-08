import { createClient } from 'redis';

const DEFAULT_TTL_SECONDS = 60;

function getRedisUrl() {
  if (process.env.REDIS_URL) return process.env.REDIS_URL;
  if (process.env.REDIS_HOST) {
    const port = process.env.REDIS_PORT || '6379';
    return `redis://${process.env.REDIS_HOST}:${port}`;
  }
  return null;
}

let clientPromise = null;

async function getClient() {
  const url = getRedisUrl();
  if (!url) return null;

  if (!clientPromise) {
    clientPromise = (async () => {
      const client = createClient({ url });

      client.on('error', (err) => {
        // Don't crash app because cache is optional
        console.error('Redis error:', err?.message || err);
      });

      await client.connect();
      return client;
    })().catch((err) => {
      console.error('Failed to connect to Redis:', err?.message || err);
      clientPromise = null;
      return null;
    });
  }

  return clientPromise;
}

async function getJson(key) {
  const client = await getClient();
  if (!client) return null;

  const raw = await client.get(key);
  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function setJson(key, value, ttlSeconds = DEFAULT_TTL_SECONDS) {
  const client = await getClient();
  if (!client) return;

  await client.set(key, JSON.stringify(value), {
    EX: ttlSeconds
  });
}

async function del(key) {
  const client = await getClient();
  if (!client) return;
  await client.del(key);
}

async function delByPrefix(prefix) {
  const client = await getClient();
  if (!client) return;

  // Use SCAN to avoid blocking Redis
  let cursor = '0';
  do {
    const reply = await client.scan(cursor, {
      MATCH: `${prefix}*`,
      COUNT: 100
    });
    cursor = reply.cursor;
    const keys = reply.keys;
    if (keys.length > 0) {
      await client.del(keys);
    }
  } while (cursor !== '0');
}

export const cache = {
  getJson,
  setJson,
  del,
  delByPrefix
};
