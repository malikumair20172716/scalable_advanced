import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import pkg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pkg;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function assertValidDbName(dbName) {
  if (!dbName || !/^[a-zA-Z0-9_]+$/.test(dbName)) {
    throw new Error('DB_NAME is missing or contains invalid characters');
  }
}

function quoteIdent(name) {
  return `"${String(name).replace(/"/g, '""')}"`;
}

function getRoleFallback() {
  const fallback = (process.env.ADMIN_ROLE_FALLBACK || 'consumer').toLowerCase();
  if (!['creator', 'consumer'].includes(fallback)) {
    throw new Error('ADMIN_ROLE_FALLBACK must be creator or consumer');
  }
  return fallback;
}

async function enforceUsersRoleConstraint(pool) {
  const fallback = getRoleFallback();

  // First normalize any legacy/invalid values so the constraint can be applied.
  await pool.query(
    "UPDATE users SET role = $1, updated_at = NOW() WHERE role IS NULL OR role NOT IN ('creator', 'consumer')",
    [fallback]
  );

  // Drop any existing CHECK constraints that mention role (including older role constraints).
  const existing = await pool.query(
    `SELECT c.conname
     FROM pg_constraint c
     JOIN pg_class t ON t.oid = c.conrelid
     JOIN pg_namespace n ON n.oid = t.relnamespace
     WHERE n.nspname = 'public'
       AND t.relname = 'users'
       AND c.contype = 'c'
       AND pg_get_constraintdef(c.oid) ILIKE '%role%'`
  );

  for (const row of existing.rows) {
    await pool.query(`ALTER TABLE users DROP CONSTRAINT IF EXISTS ${quoteIdent(row.conname)}`);
  }

  await pool.query(
    "ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('creator', 'consumer'))"
  );
}

async function ensureDatabaseExists() {
  const dbName = process.env.DB_NAME || 'photoshare_db';
  assertValidDbName(dbName);

  const postgresPool = new Pool({
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 5432),
    database: 'postgres'
  });

  const dbExists = await postgresPool.query(
    'SELECT 1 FROM pg_database WHERE datname = $1 LIMIT 1',
    [dbName]
  );

  if (dbExists.rows.length === 0) {
    await postgresPool.query(`CREATE DATABASE ${dbName}`);
    console.log(`Created database: ${dbName}`);
  } else {
    console.log(`Database exists: ${dbName}`);
  }

  await postgresPool.end();
}

async function applySchemaIfNeeded() {
  const dbName = process.env.DB_NAME || 'photoshare_db';

  const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 5432),
    database: dbName
  });

  const tableExists = await pool.query(
    `SELECT 1
     FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'users'
     LIMIT 1`
  );

  if (tableExists.rows.length > 0) {
    console.log('Schema already initialized (users table exists).');
    await pool.query('BEGIN');
    try {
      await enforceUsersRoleConstraint(pool);
      await pool.query('COMMIT');
      console.log('Verified users.role constraint (creator/consumer only).');
    } catch (err) {
      await pool.query('ROLLBACK');
      throw err;
    } finally {
      await pool.end();
    }
    return;
  }

  const schemaPath = path.resolve(__dirname, './schema.sql');
  const schemaSql = await fs.readFile(schemaPath, 'utf8');

  await pool.query('BEGIN');
  try {
    await pool.query(schemaSql);
    await enforceUsersRoleConstraint(pool);
    await pool.query('COMMIT');
    console.log('Schema applied successfully.');
  } catch (err) {
    await pool.query('ROLLBACK');
    throw err;
  } finally {
    await pool.end();
  }
}

async function main() {
  await ensureDatabaseExists();
  await applySchemaIfNeeded();
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exitCode = 1;
});
