import express from 'express';
import pool from '../config/database.js';
import { verifyToken, requireRole } from '../middleware/authMiddleware.js';
import { cache } from '../config/cache.js';
import upload from '../middleware/fileUpload.js';
import { uploadImage } from '../config/storage.js';

const router = express.Router();

// Get all photos (with pagination)
router.get('/', async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const cacheKey = `photos:public:page:${page}:limit:${limit}`;
    const cached = await cache.getJson(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    const result = await pool.query(
      `SELECT p.*, u.username, u.profile_picture_url,
              COUNT(DISTINCT c.id)::int as comment_count,
              COALESCE(AVG(r.rating_value), 0)::float as average_rating
       FROM photos p
       JOIN users u ON p.creator_id = u.id
       LEFT JOIN comments c ON p.id = c.photo_id
       LEFT JOIN ratings r ON p.id = r.photo_id
       WHERE p.visibility = 'public'
       GROUP BY p.id, u.id
       ORDER BY p.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    const countResult = await pool.query('SELECT COUNT(*) FROM photos WHERE visibility = $1', ['public']);

    const payload = {
      photos: result.rows,
      total: parseInt(countResult.rows[0].count),
      page,
      pages: Math.ceil(parseInt(countResult.rows[0].count) / limit)
    };

    await cache.setJson(cacheKey, payload);

    res.json(payload);
  } catch (error) {
    next(error);
  }
});

// Search photos
router.get('/search', async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q || q.length < 2) {
      return res.status(400).json({ message: 'Search query must be at least 2 characters' });
    }

    const normalizedQuery = String(q).trim().toLowerCase();
    const cacheKey = `photos:search:q:${normalizedQuery}`;
    const cached = await cache.getJson(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    const result = await pool.query(
      `SELECT p.*, u.username
       FROM photos p
       JOIN users u ON p.creator_id = u.id
       WHERE p.visibility = 'public' AND (
         p.title ILIKE $1 OR 
         p.caption ILIKE $1 OR 
         p.location ILIKE $1
       )
       ORDER BY p.created_at DESC
       LIMIT 50`,
      [`%${q}%`]
    );

    const payload = { photos: result.rows };
    await cache.setJson(cacheKey, payload);
    res.json(payload);
  } catch (error) {
    next(error);
  }
});

// Get photo by ID
router.get('/:id', async (req, res, next) => {
  try {
    const cacheKey = `photo:${req.params.id}`;
    const cached = await cache.getJson(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    const result = await pool.query(
      `SELECT p.*, u.username, u.profile_picture_url,
              COUNT(DISTINCT c.id)::int as comment_count,
              COALESCE(AVG(r.rating_value), 0)::float as average_rating
       FROM photos p
       JOIN users u ON p.creator_id = u.id
       LEFT JOIN comments c ON p.id = c.photo_id
       LEFT JOIN ratings r ON p.id = r.photo_id
       WHERE p.id = $1
       GROUP BY p.id, u.id`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Photo not found' });
    }

    const photo = result.rows[0];

    const tagsResult = await pool.query(
      `SELECT tag_name
       FROM photo_tags
       WHERE photo_id = $1
       ORDER BY id ASC`,
      [req.params.id]
    );

    const payload = {
      ...photo,
      tags: tagsResult.rows.map((r) => r.tag_name)
    };

    await cache.setJson(cacheKey, payload);
    res.json(payload);
  } catch (error) {
    next(error);
  }
});

// Upload photo (creators only) - supports file upload and image URL
router.post('/', verifyToken, requireRole(['creator']), upload.single('photo_file'), async (req, res, next) => {
  try {
    const { title, caption, location, image_url, thumbnail_url, tags } = req.body;

    if (!title) {
      return res.status(400).json({ message: 'Title is required' });
    }

    // Determine image URL: either from uploaded file or provided URL
    let finalImageUrl = image_url;
    if (req.file) {
      // Upload to Azure Blob when configured, otherwise store locally.
      finalImageUrl = await uploadImage(req.file);
    } else if (!finalImageUrl) {
      return res.status(400).json({ message: 'Either upload a file or provide an image URL' });
    }

    const result = await pool.query(
      `INSERT INTO photos (creator_id, title, caption, location, image_url)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [req.user.id, title, caption, location, finalImageUrl]
    );

    const photo = result.rows[0];

    if (thumbnail_url) {
      await pool.query(
        `UPDATE photos SET thumbnail_url = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`,
        [thumbnail_url, photo.id]
      );
      photo.thumbnail_url = thumbnail_url;
    }

    if (Array.isArray(tags) && tags.length > 0) {
      const cleanedTags = [...new Set(tags.map((t) => String(t).trim()).filter(Boolean))];
      for (const tagName of cleanedTags) {
        await pool.query(
          `INSERT INTO photo_tags (photo_id, tag_name)
           VALUES ($1, $2)`,
          [photo.id, tagName]
        );
      }
      photo.tags = cleanedTags;
    } else {
      photo.tags = [];
    }

    await cache.delByPrefix('photos:public:');
    await cache.delByPrefix('photos:search:');

    res.status(201).json(photo);
  } catch (error) {
    next(error);
  }
});

// Update photo (creator owner)
router.put('/:id', verifyToken, requireRole(['creator']), async (req, res, next) => {
  try {
    const photoId = parseInt(req.params.id);
    if (Number.isNaN(photoId)) {
      return res.status(400).json({ message: 'Invalid photo id' });
    }

    const existing = await pool.query('SELECT id, creator_id FROM photos WHERE id = $1', [photoId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ message: 'Photo not found' });
    }

    const creatorId = existing.rows[0].creator_id;
    if (creatorId !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    const { title, caption, location, image_url, thumbnail_url, visibility, tags } = req.body;

    const updated = await pool.query(
      `UPDATE photos
       SET title = COALESCE($1, title),
           caption = COALESCE($2, caption),
           location = COALESCE($3, location),
           image_url = COALESCE($4, image_url),
           thumbnail_url = COALESCE($5, thumbnail_url),
           visibility = COALESCE($6, visibility),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $7
       RETURNING *`,
      [title, caption, location, image_url, thumbnail_url, visibility, photoId]
    );

    const photo = updated.rows[0];

    if (Array.isArray(tags)) {
      const cleanedTags = [...new Set(tags.map((t) => String(t).trim()).filter(Boolean))];
      await pool.query('DELETE FROM photo_tags WHERE photo_id = $1', [photoId]);
      for (const tagName of cleanedTags) {
        await pool.query(
          `INSERT INTO photo_tags (photo_id, tag_name)
           VALUES ($1, $2)`,
          [photoId, tagName]
        );
      }
      photo.tags = cleanedTags;
    } else {
      const tagsResult = await pool.query(
        `SELECT tag_name FROM photo_tags WHERE photo_id = $1 ORDER BY id ASC`,
        [photoId]
      );
      photo.tags = tagsResult.rows.map((r) => r.tag_name);
    }

    await cache.del(`photo:${photoId}`);
    await cache.delByPrefix('photos:public:');
    await cache.delByPrefix('photos:search:');

    res.json(photo);
  } catch (error) {
    next(error);
  }
});

// Delete photo (creator owner)
router.delete('/:id', verifyToken, requireRole(['creator']), async (req, res, next) => {
  try {
    const photoId = parseInt(req.params.id);
    if (Number.isNaN(photoId)) {
      return res.status(400).json({ message: 'Invalid photo id' });
    }

    const existing = await pool.query('SELECT id, creator_id FROM photos WHERE id = $1', [photoId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ message: 'Photo not found' });
    }

    const creatorId = existing.rows[0].creator_id;
    if (creatorId !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    await pool.query('DELETE FROM photos WHERE id = $1', [photoId]);

    await cache.del(`photo:${photoId}`);
    await cache.delByPrefix('photos:public:');
    await cache.delByPrefix('photos:search:');

    res.json({ message: 'Photo deleted' });
  } catch (error) {
    next(error);
  }
});

export default router;
