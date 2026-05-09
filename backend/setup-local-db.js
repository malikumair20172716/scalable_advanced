import pkg from 'pg';
const { Client } = pkg;
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

dotenv.config(); // Loads .env from current directory

async function setupLocalDB() {
    // 1. Connect to default 'postgres' database first to create our app DB
    const client = new Client({
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD,
        database: 'postgres' // Connect to system DB
    });

    try {
        await client.connect();
        console.log('Connected to PostgreSQL server.');

        // 2. Create the database if it doesn't exist
        const dbName = process.env.DB_NAME || 'photoshare_db';
        const dbCheck = await client.query("SELECT 1 FROM pg_database WHERE datname = $1", [dbName]);
        
        if (dbCheck.rowCount === 0) {
            console.log(`Creating database "${dbName}"...`);
            // CREATE DATABASE cannot be run in a transaction or with parameters
            await client.query(`CREATE DATABASE ${dbName}`);
            console.log('Database created successfully.');
        } else {
            console.log(`Database "${dbName}" already exists.`);
        }
        await client.end();

        // 3. Connect to the NEW database to create tables
        const appClient = new Client({
            host: process.env.DB_HOST || 'localhost',
            port: process.env.DB_PORT || 5432,
            user: process.env.DB_USER || 'postgres',
            password: process.env.DB_PASSWORD,
            database: dbName
        });

        await appClient.connect();
        console.log(`Connected to "${dbName}".`);

        // 4. Read and execute schema.sql
        const schemaPath = path.resolve('src/db/schema.sql');
        if (fs.existsSync(schemaPath)) {
            console.log('Running schema.sql...');
            const schemaSql = fs.readFileSync(schemaPath, 'utf8');
            await appClient.query(schemaSql);
            console.log('Tables created successfully.');
        } else {
            console.warn('Warning: schema.sql not found at', schemaPath);
        }

        await appClient.end();
        console.log('✅ Local database setup complete!');

    } catch (err) {
        console.error('❌ Error during setup:');
        console.error(err.message);
        process.exit(1);
    }
}

setupLocalDB();
