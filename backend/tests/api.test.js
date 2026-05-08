import request from 'supertest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import pkg from 'pg';
import bcryptjs from 'bcryptjs';

const { Pool } = pkg;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let app;
let pool;

function assertSafeTestDb() {
  const dbName = process.env.DB_NAME;
  const nodeEnv = process.env.NODE_ENV;

  if (nodeEnv !== 'test') {
    throw new Error('Refusing to run destructive DB setup unless NODE_ENV=test');
  }

  if (!dbName || !dbName.toLowerCase().includes('test')) {
    throw new Error('Refusing to run destructive DB setup unless DB_NAME includes "test"');
  }
}

async function initSchema() {
  assertSafeTestDb();

  const dbName = process.env.DB_NAME;
  if (!/^[a-zA-Z0-9_]+$/.test(dbName)) {
    throw new Error('DB_NAME contains invalid characters');
  }

  // Ensure the test database exists (useful for local runs without psql)
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
  }

  await postgresPool.end();

  const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 5432),
    database: dbName
  });

  const schemaPath = path.resolve(__dirname, '../src/db/schema.sql');
  const schemaSql = await fs.readFile(schemaPath, 'utf8');

  // Reset schema for repeatable tests
  await pool.query('DROP SCHEMA public CASCADE;');
  await pool.query('CREATE SCHEMA public;');
  await pool.query(schemaSql);

  const creatorPasswordHash = await bcryptjs.hash('Password123!', 10);
  await pool.query(
    `INSERT INTO users (username, email, password_hash, full_name, role)
     VALUES ($1, $2, $3, $4, $5)`,
    ['creator_demo', 'creator_demo@photoshare.local', creatorPasswordHash, 'Creator Demo', 'creator']
  );

  await pool.end();
}

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  // Force a safe test DB name even if a local .env sets a non-test DB.
  process.env.DB_NAME = 'photoshare_test_db';
  if (!process.env.JWT_SECRET) process.env.JWT_SECRET = 'test_secret';

  ({ default: app } = await import('../src/app.js'));
  ({ default: pool } = await import('../src/config/database.js'));

  await initSchema();
});

afterAll(async () => {
  if (pool) await pool.end();
});

describe('API smoke tests', () => {
  test('GET /health returns OK', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('OK');
  });

  test('Consumer cannot upload; creator can upload', async () => {
    const consumerRegister = await request(app)
      .post('/api/auth/register')
      .send({
        username: 'consumer_test',
        email: 'consumer_test@example.com',
        password: 'password123',
        full_name: 'Consumer',
        role: 'consumer'
      });

    expect(consumerRegister.status).toBe(201);
    const consumerToken = consumerRegister.body.token;

    const consumerUpload = await request(app)
      .post('/api/photos')
      .set('Authorization', `Bearer ${consumerToken}`)
      .send({
        title: 'Should fail',
        caption: 'nope',
        location: 'X',
        image_url: 'https://picsum.photos/seed/shouldfail/1200/800'
      });

    expect(consumerUpload.status).toBe(403);

    const creatorLogin = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'creator_demo@photoshare.local',
        password: 'Password123!'
      });

    expect(creatorLogin.status).toBe(200);
    const creatorToken = creatorLogin.body.token;

    const creatorUpload = await request(app)
      .post('/api/photos')
      .set('Authorization', `Bearer ${creatorToken}`)
      .send({
        title: 'Creator upload',
        caption: 'ok',
        location: 'Test',
        image_url: 'https://picsum.photos/seed/creatorupload/1200/800',
        tags: ['Alice', 'Bob']
      });

    expect(creatorUpload.status).toBe(201);
    expect(creatorUpload.body.title).toBe('Creator upload');
    expect(Array.isArray(creatorUpload.body.tags)).toBe(true);
    expect(creatorUpload.body.tags).toEqual(expect.arrayContaining(['Alice', 'Bob']));
  });
});
