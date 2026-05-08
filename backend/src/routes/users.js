import express from 'express';
import pool from '../config/database.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Get user profile
router.get('/:id', async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, username, email, full_name, profile_picture_url, bio, role, created_at
       FROM users
       WHERE id = $1 AND is_active = true`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

// Update user profile
router.put('/:id', verifyToken, async (req, res, next) => {
  try {
    if (req.user.id !== parseInt(req.params.id)) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    const { full_name, bio, profile_picture_url } = req.body;

    const result = await pool.query(
      `UPDATE users 
       SET full_name = COALESCE($1, full_name),
           bio = COALESCE($2, bio),
           profile_picture_url = COALESCE($3, profile_picture_url),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $4
       RETURNING id, username, email, full_name, profile_picture_url, bio, role`,
      [full_name, bio, profile_picture_url, req.user.id]
    );

    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

export default router;
