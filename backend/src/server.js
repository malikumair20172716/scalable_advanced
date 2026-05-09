import dotenv from 'dotenv';
import app from './app.js';
import { migrate } from './db/migrate.js';

dotenv.config();
const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    console.log('Running database migrations...');
    await migrate();
    
    app.listen(PORT, () => {
      console.log(`PhotoShare API running on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV || 'production'}`);
    });
  } catch (err) {
    console.error('Failed to start server due to migration error:', err);
    process.exit(1);
  }
}

startServer();
