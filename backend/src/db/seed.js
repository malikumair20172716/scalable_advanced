import bcrypt from 'bcryptjs';
import pool from '../config/database.js';

async function getOrCreateUser({ username, email, password, fullName, role }) {
  const passwordHash = await bcrypt.hash(password, 10);

  const existing = await pool.query(
    'SELECT id FROM users WHERE email = $1 OR username = $2 LIMIT 1',
    [email, username]
  );
  if (existing.rows.length > 0) return existing.rows[0].id;

  const inserted = await pool.query(
    `INSERT INTO users (username, email, password_hash, full_name, role)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id`,
    [username, email, passwordHash, fullName, role]
  );

  return inserted.rows[0].id;
}

async function createPhotoIfMissing({ creatorId, title, caption, location, imageUrl, thumbnailUrl }) {
  const existing = await pool.query(
    'SELECT id FROM photos WHERE creator_id = $1 AND title = $2 LIMIT 1',
    [creatorId, title]
  );
  if (existing.rows.length > 0) return existing.rows[0].id;

  const inserted = await pool.query(
    `INSERT INTO photos (creator_id, title, caption, location, image_url, thumbnail_url, visibility)
     VALUES ($1, $2, $3, $4, $5, $6, 'public')
     RETURNING id`,
    [creatorId, title, caption, location, imageUrl, thumbnailUrl]
  );

  return inserted.rows[0].id;
}

async function seed() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const creatorId = await getOrCreateUser({
      username: 'creator_demo',
      email: 'creator_demo@photoshare.local',
      password: 'Password123!',
      fullName: 'Creator Demo',
      role: 'creator'
    });

    await getOrCreateUser({
      username: 'consumer_demo',
      email: 'consumer_demo@photoshare.local',
      password: 'Password123!',
      fullName: 'Consumer Demo',
      role: 'consumer'
    });


    const photos = [
      {
        title: 'Sunset Over The Hills',
        caption: 'A calm sunset with warm colors.',
        location: 'Hill View',
        imageUrl: 'https://picsum.photos/seed/photoshare1/1200/800',
        thumbnailUrl: 'https://picsum.photos/seed/photoshare1/600/400'
      },
      {
        title: 'City Lights',
        caption: 'Night lights in the city.',
        location: 'Downtown',
        imageUrl: 'https://picsum.photos/seed/photoshare2/1200/800',
        thumbnailUrl: 'https://picsum.photos/seed/photoshare2/600/400'
      },
      {
        title: 'Forest Path',
        caption: 'A walk through the trees.',
        location: 'Greenwood',
        imageUrl: 'https://picsum.photos/seed/photoshare3/1200/800',
        thumbnailUrl: 'https://picsum.photos/seed/photoshare3/600/400'
      },
      {
        title: 'Mountain Lake',
        caption: 'Reflections on a clear lake.',
        location: 'Highlands',
        imageUrl: 'https://picsum.photos/seed/photoshare4/1200/800',
        thumbnailUrl: 'https://picsum.photos/seed/photoshare4/600/400'
      },
      {
        title: 'Coastal Breeze',
        caption: 'Waves and sea air.',
        location: 'Seaside',
        imageUrl: 'https://picsum.photos/seed/photoshare5/1200/800',
        thumbnailUrl: 'https://picsum.photos/seed/photoshare5/600/400'
      }
    ];

    for (const photo of photos) {
      await createPhotoIfMissing({
        creatorId,
        title: photo.title,
        caption: photo.caption,
        location: photo.location,
        imageUrl: photo.imageUrl,
        thumbnailUrl: photo.thumbnailUrl
      });
    }

    await client.query('COMMIT');
    console.log('Seed complete: demo users + photos added.');
    console.log('Login demo accounts:');
    console.log('- creator_demo@photoshare.local / Password123!');
    console.log('- consumer_demo@photoshare.local / Password123!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Seed failed:', error);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
