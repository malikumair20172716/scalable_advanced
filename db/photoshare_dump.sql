-- PhotoShare database export
-- Exported at 2026-05-05T18:23:12.466Z
-- Schema
-- Users Table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  profile_picture_url TEXT,
  bio TEXT,
  role VARCHAR(50) NOT NULL DEFAULT 'consumer' CHECK (role IN ('creator', 'consumer')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE
);

-- Photos Table
CREATE TABLE photos (
  id SERIAL PRIMARY KEY,
  creator_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  caption TEXT,
  image_url TEXT NOT NULL,
  thumbnail_url TEXT,
  location VARCHAR(255),
  visibility VARCHAR(50) DEFAULT 'public' CHECK (visibility IN ('public', 'private')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  view_count INTEGER DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2) DEFAULT 0
);

-- Photo Tags (people present in photo)
CREATE TABLE photo_tags (
  id SERIAL PRIMARY KEY,
  photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  tag_name VARCHAR(255) NOT NULL,
  x_coordinate FLOAT,
  y_coordinate FLOAT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Comments Table
CREATE TABLE comments (
  id SERIAL PRIMARY KEY,
  photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE
);

-- Ratings Table
CREATE TABLE ratings (
  id SERIAL PRIMARY KEY,
  photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating_value INTEGER NOT NULL CHECK (rating_value BETWEEN 1 AND 5),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(photo_id, user_id)
);

-- Followers Table (for potential social features)
CREATE TABLE followers (
  id SERIAL PRIMARY KEY,
  follower_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- Indexes for performance
CREATE INDEX idx_photos_creator_id ON photos(creator_id);
CREATE INDEX idx_photos_created_at ON photos(created_at DESC);
CREATE INDEX idx_comments_photo_id ON comments(photo_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_ratings_photo_id ON ratings(photo_id);
CREATE INDEX idx_photo_tags_photo_id ON photo_tags(photo_id);
CREATE INDEX idx_followers_follower_id ON followers(follower_id);
CREATE INDEX idx_followers_following_id ON followers(following_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- Data
-- Table: users
INSERT INTO users (id, username, email, password_hash, full_name, profile_picture_url, bio, role, created_at, updated_at, is_active) VALUES
  (1, 'creator_demo', 'creator_demo@photoshare.local', '$2a$10$vCxNLCY7xFrXPHMAp0m.mOv9W8BoZYFu21xWkmTyESFeUdwFqTese', 'Creator Demo', NULL, NULL, 'creator', '2026-04-18T07:25:50.851Z', '2026-04-18T07:25:50.851Z', TRUE),
  (2, 'consumer_demo', 'consumer_demo@photoshare.local', '$2a$10$RsjhCiWZnG9xQxI8X5NJ0.SjAIChOb6igoHqQs1peyGIAuYVHIaAW', 'Consumer Demo', NULL, NULL, 'consumer', '2026-04-18T07:25:50.985Z', '2026-04-18T07:25:50.985Z', TRUE),
  (3, 'cons_20260418123717', 'cons_20260418123717@example.com', '$2a$10$NIOFgi5p2IVJ8QqExSwEnenDQxKXKHP9MTnSvAtKwNx5II86/O0Vu', 'Consumer Test', NULL, NULL, 'consumer', '2026-04-18T07:37:18.085Z', '2026-04-18T07:37:18.085Z', TRUE),
  (4, 'creator_20260418123717', 'creator_20260418123717@example.com', '$2a$10$64X/QWEa7eZtdiJ2hfOSQOr0eyDYU/JJgpbWKA2o/nnhqagGtdHD2', 'Creator Test', NULL, NULL, 'creator', '2026-04-18T07:37:18.592Z', '2026-04-18T07:37:18.592Z', TRUE),
  (5, 'cons_20260418123732', 'cons_20260418123732@example.com', '$2a$10$ZOBrqLla67Msx657OPKYMOwmQq4hgL2Rh/uYQzG3SuebNglz6lDF2', 'Consumer Test', NULL, NULL, 'consumer', '2026-04-18T07:37:32.520Z', '2026-04-18T07:37:32.520Z', TRUE),
  (6, 'creator_20260418123732', 'creator_20260418123732@example.com', '$2a$10$DCOVjTqB7I6Nxf3FtQlNfeunaVt2qn9DX2d4axADVbgbSxF5mIP1m', 'Creator Test', NULL, NULL, 'creator', '2026-04-18T07:37:32.662Z', '2026-04-18T07:37:32.662Z', TRUE),
  (7, 'admin_demo', 'admin_demo@photoshare.local', '$2a$10$6PELjymLhWe4HVWwU9Or0eUnzL8De/yErkKJ9D9JcPh8qKUvFm3xK', 'Admin Demo', NULL, NULL, 'consumer', '2026-05-03T09:10:18.624Z', '2026-05-03T13:17:09.642Z', TRUE),
  (8, 'Wajahat', 'wat@example.com', '$2a$10$RYZcq6Zu0WOCRi2btomN2uEz0IKSo9B1LHQu.eEavimSrE34U/jYS', 'Wajahat Ali Tariq', NULL, NULL, 'consumer', '2026-05-03T09:12:55.754Z', '2026-05-03T09:12:55.754Z', TRUE),
  (9, 'Ali', 'ali@example.com', '$2a$10$aj5QZ5./.VNbxO7QccVRZuGePoYcah57DgXBwHK87bZYZQ3ZWOQZi', 'Ali Hashmi', NULL, NULL, 'creator', '2026-05-03T09:20:30.742Z', '2026-05-03T09:20:30.742Z', TRUE),
  (10, 'Admin', 'admin@example.com', '$2a$10$9TjOuEVPXCcmOop5NhhVTulgBtGF3U5B2QfAw/BdWPdN2FnFEEEeW', 'Admin_1', NULL, NULL, 'consumer', '2026-05-03T09:22:30.116Z', '2026-05-03T13:17:09.642Z', TRUE);

-- Table: photos
INSERT INTO photos (id, creator_id, title, caption, image_url, thumbnail_url, location, visibility, created_at, updated_at, view_count, rating_count, average_rating) VALUES
  (1, 1, 'Sunset Over The Hills', 'A calm sunset with warm colors.', 'https://picsum.photos/seed/photoshare1/1200/800', 'https://picsum.photos/seed/photoshare1/600/400', 'Hill View', 'public', '2026-04-18T07:25:50.990Z', '2026-04-18T07:25:50.990Z', 0, 0, '0.00'),
  (2, 1, 'City Lights', 'Night lights in the city.', 'https://picsum.photos/seed/photoshare2/1200/800', 'https://picsum.photos/seed/photoshare2/600/400', 'Downtown', 'public', '2026-04-18T07:25:50.994Z', '2026-04-18T07:25:50.994Z', 0, 0, '0.00'),
  (3, 1, 'Forest Path', 'A walk through the trees.', 'https://picsum.photos/seed/photoshare3/1200/800', 'https://picsum.photos/seed/photoshare3/600/400', 'Greenwood', 'public', '2026-04-18T07:25:50.996Z', '2026-04-18T07:25:50.996Z', 0, 0, '0.00'),
  (4, 1, 'Mountain Lake', 'Reflections on a clear lake.', 'https://picsum.photos/seed/photoshare4/1200/800', 'https://picsum.photos/seed/photoshare4/600/400', 'Highlands', 'public', '2026-04-18T07:25:50.998Z', '2026-04-18T07:25:50.998Z', 0, 0, '0.00'),
  (5, 1, 'Coastal Breeze', 'Waves and sea air.', 'https://picsum.photos/seed/photoshare5/1200/800', 'https://picsum.photos/seed/photoshare5/600/400', 'Seaside', 'public', '2026-04-18T07:25:50.999Z', '2026-04-18T07:25:50.999Z', 0, 0, '0.00'),
  (6, 4, 'Creator Upload', 'ok', 'https://picsum.photos/seed/creatorupload/1200/800', NULL, 'Test', 'public', '2026-04-18T07:37:18.745Z', '2026-04-18T07:37:18.745Z', 0, 0, '0.00'),
  (7, 6, 'Creator Upload', 'ok', 'https://picsum.photos/seed/creatorupload/1200/800', NULL, 'Test', 'public', '2026-04-18T07:37:32.670Z', '2026-04-18T07:37:32.670Z', 0, 0, '0.00');

-- Table: photo_tags
INSERT INTO photo_tags (id, photo_id, user_id, tag_name, x_coordinate, y_coordinate, created_at) VALUES
  (1, 6, NULL, 'Alice', NULL, NULL, '2026-04-18T07:37:18.748Z'),
  (2, 6, NULL, 'Bob', NULL, NULL, '2026-04-18T07:37:18.751Z'),
  (3, 7, NULL, 'Alice', NULL, NULL, '2026-04-18T07:37:32.671Z'),
  (4, 7, NULL, 'Bob', NULL, NULL, '2026-04-18T07:37:32.672Z');

-- Table: comments
INSERT INTO comments (id, photo_id, user_id, content, created_at, updated_at, is_deleted) VALUES
  (1, 7, 8, 'nice ', '2026-05-03T09:15:17.370Z', '2026-05-03T09:15:17.370Z', FALSE),
  (2, 4, 8, 'good', '2026-05-03T13:31:43.686Z', '2026-05-03T13:31:43.686Z', FALSE);

-- Table: ratings
INSERT INTO ratings (id, photo_id, user_id, rating_value, created_at) VALUES
  (1, 7, 8, 5, '2026-05-03T09:15:11.876Z'),
  (2, 4, 8, 3, '2026-05-03T13:31:36.260Z');

-- Table: followers
-- No rows in followers

-- Sequence resets
SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE(MAX(id), 1), true) FROM users;
SELECT setval(pg_get_serial_sequence('photos', 'id'), COALESCE(MAX(id), 1), true) FROM photos;
SELECT setval(pg_get_serial_sequence('photo_tags', 'id'), COALESCE(MAX(id), 1), true) FROM photo_tags;
SELECT setval(pg_get_serial_sequence('comments', 'id'), COALESCE(MAX(id), 1), true) FROM comments;
SELECT setval(pg_get_serial_sequence('ratings', 'id'), COALESCE(MAX(id), 1), true) FROM ratings;
SELECT setval(pg_get_serial_sequence('followers', 'id'), COALESCE(MAX(id), 1), true) FROM followers;
