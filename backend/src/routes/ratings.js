import express from 'express';
import pool from '../config/database.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Get photo rating (current user's rating)
router.get('/photo/:photoId', verifyToken, async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT rating_value FROM ratings 
       WHERE photo_id = $1 AND user_id = $2`,
      [req.params.photoId, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.json({ rating: null });
    }

    res.json({ rating: result.rows[0].rating_value });
  } catch (error) {
    next(error);
  }
});

// Submit or update rating
router.post('/', verifyToken, async (req, res, next) => {
  try {
    const { photo_id, rating_value } = req.body;

    if (!photo_id || !rating_value || rating_value < 1 || rating_value > 5) {
      return res.status(400).json({ message: 'Valid photo_id and rating_value (1-5) required' });
    }

    // Upsert: update if exists, insert if not
    const result = await pool.query(
      `INSERT INTO ratings (photo_id, user_id, rating_value)
       VALUES ($1, $2, $3)
       ON CONFLICT (photo_id, user_id) 
       DO UPDATE SET rating_value = EXCLUDED.rating_value
       RETURNING *`,
      [photo_id, req.user.id, rating_value]
    );

    res.json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

// Delete rating
router.delete('/:photoId', verifyToken, async (req, res, next) => {
  try {
    await pool.query(
      `DELETE FROM ratings WHERE photo_id = $1 AND user_id = $2`,
      [req.params.photoId, req.user.id]
    );

    res.json({ message: 'Rating deleted' });
  } catch (error) {
    next(error);
  }
});

export default router;
