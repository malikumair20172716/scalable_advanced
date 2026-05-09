import express from 'express';
import bcryptjs from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { body, validationResult } from 'express-validator';
import pool from '../config/database.js';

const router = express.Router();

// Register Route
router.post('/register', [
  body('username').trim().isLength({ min: 3 }).withMessage('Username must be at least 3 characters'),
  body('email').isEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('role').isIn(['consumer', 'creator']).withMessage('Invalid role selected'),
    body('full_name').optional().trim()
  ], async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }
  
      const { username, email, password, full_name, role } = req.body;
  
      // Check if user exists
      const existing = await pool.query('SELECT id FROM users WHERE username = $1 OR email = $2', [username, email]);
      if (existing.rows.length > 0) {
        return res.status(409).json({ message: 'Username or email already exists' });
      }
  
      // Hash password
      const hashedPassword = await bcryptjs.hash(password, 10);
  
      // Create user
      const result = await pool.query(
        'INSERT INTO users (username, email, password_hash, full_name, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, username, email, role',
        [username, email, hashedPassword, full_name || null, role]
      );

    const user = result.rows[0];

    // Generate JWT
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user
    });
  } catch (error) {
    next(error);
  }
});

// Login Route
router.post('/login', [
  body('email').isEmail().withMessage('Valid email required'),
  body('password').exists().withMessage('Password required')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    // Find user
    const result = await pool.query('SELECT * FROM users WHERE email = $1 AND is_active = true', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const user = result.rows[0];

    // Verify password
    const isMatch = await bcryptjs.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Generate JWT
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    next(error);
  }
});

export default router;
