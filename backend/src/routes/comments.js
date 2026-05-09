import express from 'express';
import pool from '../config/database.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Get comments for a photo
router.get('/photo/:photoId', async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT c.id, c.content, c.sentiment, c.created_at, u.id as user_id, u.username, u.profile_picture_url
       FROM comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.photo_id = $1 AND c.is_deleted = false
       ORDER BY c.created_at DESC`,
      [req.params.photoId]
    );

    res.json({ comments: result.rows });
  } catch (error) {
    next(error);
  }
});

// Add comment
router.post('/', verifyToken, async (req, res, next) => {
  try {
    const { photo_id, content } = req.body;

    if (!photo_id || !content || content.trim().length === 0) {
      return res.status(400).json({ message: 'Photo ID and content are required' });
    }

    // Verify photo exists
    const photoCheck = await pool.query('SELECT id FROM photos WHERE id = $1', [photo_id]);
    if (photoCheck.rows.length === 0) {
      return res.status(404).json({ message: 'Photo not found' });
    }

    const { analyzeSentiment } = await import('../services/aiService.js');
    const sentiment = await analyzeSentiment(content);

    const result = await pool.query(
      `INSERT INTO comments (photo_id, user_id, content, sentiment)
       VALUES ($1, $2, $3, $4)
       RETURNING id, content, sentiment, created_at, user_id`,
      [photo_id, req.user.id, content, sentiment]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

// Delete comment
router.delete('/:id', verifyToken, async (req, res, next) => {
  try {
    const result = await pool.query(
      `UPDATE comments
       SET is_deleted = true
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [req.params.id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Comment not found or unauthorized' });
    }

    res.json({ message: 'Comment deleted' });
  } catch (error) {
    next(error);
  }
});

export default router;
