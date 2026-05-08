import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Routes
import authRoutes from './routes/auth.js';
import photoRoutes from './routes/photos.js';
import userRoutes from './routes/users.js';
import commentRoutes from './routes/comments.js';
import ratingRoutes from './routes/ratings.js';

// Middleware
import { errorHandler } from './middleware/errorHandler.js';
import { requestLogger } from './middleware/requestLogger.js';

dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();

// Security Middleware
app.use(helmet());
app.use(
  cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    credentials: true
  })
);

// Body Parser Middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Static Files - Serve uploaded images
app.use('/uploads', express.static(path.join(__dirname, '../public/uploads')));

// Request Logger
app.use(requestLogger);

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/photos', photoRoutes);
app.use('/api/users', userRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/ratings', ratingRoutes);

// Root Endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    name: 'PhotoShare API',
    status: 'OK',
    endpoints: {
      health: '/health',
      photos: '/api/photos',
      auth: '/api/auth',
      users: '/api/users',
      comments: '/api/comments',
      ratings: '/api/ratings'
    }
  });
});

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Error Handler Middleware (must be last)
app.use(errorHandler);

export default app;
