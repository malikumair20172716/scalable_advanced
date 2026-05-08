# Quick Start Guide

## 🚀 Start Development in 5 Minutes

### Option 1: Docker Compose (Recommended)

```bash
# 1. Navigate to project root
cd "Scalable Advanced Software Solutions"

# 2. Start all services
docker-compose up

# Wait for services to initialize (2-3 minutes)

# 3. Access the application
Frontend:  http://localhost:3000
Backend:   http://localhost:5000
Database:  localhost:5432 (postgres / postgres)
Redis:     localhost:6379
```

### Option 2: Manual Setup

```bash
# 1. Setup Backend
cd backend
npm install

# 2. Setup Frontend (in new terminal)
cd frontend
npm install

# 3. Create backend .env file
cp backend/.env.example backend/.env

# Update with your local database credentials:
# DB_HOST=localhost
# DB_USER=postgres
# DB_PASSWORD=postgres

# 4. Run migrations (create tables)
cd backend
npm run migrate

# 5. Start backend (from backend folder)
npm run dev

# 6. Start frontend (from frontend folder, in new terminal)
npm start
```

## 📝 Default Users (After Seeding)

```
Creator User:
  Username: creator1
  Email: creator@example.com
  Password: password123
  Role: Creator

Consumer User:
  Username: consumer1
  Email: consumer@example.com
  Password: password123
  Role: Consumer
```

## 🧪 Test the API

### 1. Register a New User

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "full_name": "Test User",
    "role": "consumer"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Response will include a JWT token:
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "role": "consumer"
  }
}
```

### 3. Get All Photos

```bash
curl http://localhost:5000/api/photos?page=1
```

### 4. Upload a Photo (Creator Only)

```bash
curl -X POST http://localhost:5000/api/photos \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Beautiful Sunset",
    "caption": "Captured at the beach",
    "location": "Miami Beach",
    "image_url": "https://via.placeholder.com/800x600?text=Sample+Photo"
  }'
```

### 5. Add a Comment

```bash
curl -X POST http://localhost:5000/api/comments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "photo_id": 1,
    "content": "Amazing photo!"
  }'
```

## 📊 Import Postman Collection

1. Open Postman
2. Click "Import"
3. Paste this:
   ```
   https://raw.githubusercontent.com/your-repo/photoshare-api.postman_collection.json
   ```

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Windows - Kill process on port 5000 (backend)
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# macOS/Linux
lsof -ti:5000 | xargs kill -9
```

### Database Connection Error

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Or connect directly
psql -h localhost -U postgres -d photoshare_db
```

### Frontend shows blank page

- Check browser console for errors (F12)
- Ensure backend is running on port 5000
- Clear browser cache

## 📚 Next Steps

1. **Read the documentation**:
   - [Architecture Guide](docs/architecture.md)
   - [Deployment Guide](docs/deployment.md)
   - [Scalability](docs/scalability.md)

2. **Explore the codebase**:
   - Backend routes: `backend/src/routes/`
   - Frontend components: `frontend/src/components/`
   - Database schema: `backend/src/db/schema.sql`

3. **Run tests**:
   ```bash
   cd backend
   npm test
   
   cd frontend
   npm test
   ```

4. **Build for production**:
   ```bash
   cd frontend
   npm run build
   
   cd backend
   npm start
   ```

## 🆘 Need Help?

- Check logs: `docker-compose logs -f backend`
- Backend errors: Check `backend/src/middleware/errorHandler.js`
- Database issues: Connect directly with psql
- Frontend issues: Check browser DevTools console

---

**Happy coding! 🎉**
