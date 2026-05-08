# PhotoShare - Scalable Photo Sharing Platform

A cloud-native, scalable photo sharing application built with Node.js, React, and PostgreSQL. Designed for COM769: Scalable Advanced Software Solutions.

**🎯 Latest Feature**: Deploy to **Azure FREE TIER** - Year 1 costs $0! ✅

## ☁️ Quick Deployment

PhotoShare is an Instagram-like platform featuring:
- **Creator Accounts**: Upload photos with metadata (title, caption, location, people tagged)
- **Consumer Accounts**: Browse, search, comment on, and rate photos
- **Scalable Architecture**: Built with cloud-native principles for horizontal scaling
- **RESTful API**: Clean, well-documented REST endpoints
- **CI/CD Pipeline**: Automated testing and deployment with GitHub Actions
- **Docker Support**: Containerized for easy deployment

## 📋 Features

### Authentication & Authorization
- JWT-based authentication
- Role-based access control (Creator/Consumer)
- Secure password hashing with bcryptjs

### Role Capabilities

| Capability | Creator | Consumer |
| --- | --- | --- |
| Register and log in | Log in only | Yes |
| View photos | Yes | Yes |
| Search photos | Yes | Yes |
| Comment on photos | Yes | Yes |
| Rate photos | Yes | Yes |
| Upload photos | Yes | No |
| Add photo metadata | Yes | No |
| Access creator upload page | Yes | No |
| Manage own uploaded photos | Yes | No |

### Core Functionality
- **Photo Management**: Upload, view, search photos
- **Comments**: Users can comment on photos
- **Ratings**: 5-star rating system for photos
- **User Profiles**: Manage user information and profiles
- **Pagination**: Efficient data loading with pagination

### Scalability Features
- **Database Connection Pooling**: PostgreSQL with pg library
- **Redis Caching**: Optional caching layer for performance
- **Static Asset Hosting**: React frontend served via Nginx
- **API Pagination**: Prevent data overload
- **Database Indexing**: Optimized queries with strategic indexes

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React)                         │
│              (Nginx Static Hosting on Port 3000)            │
└───────────────────────────┬─────────────────────────────────┘
                            │ REST API Calls
┌───────────────────────────┴─────────────────────────────────┐
│               Backend API (Node.js + Express)               │
│                    (Port 5000)                              │
│   ┌──────────────┬──────────────┬──────────────┐           │
│   │   Auth       │   Photos     │   Comments   │           │
│   │  Endpoints   │  Endpoints   │  Endpoints   │           │
│   └──────┬───────┴──────┬───────┴──────┬───────┘           │
└──────────┼──────────────┼──────────────┼────────────────────┘
           │              │              │
   ┌───────▼──────┬───────▼──────┬──────▼───────┐
   │ PostgreSQL   │  Redis Cache │ AWS S3       │
   │   (RDS)      │              │ (Storage)    │
   └──────────────┴──────────────┴──────────────┘
```

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- PostgreSQL 15+
- Docker & Docker Compose (optional)
- **Azure Account** (free tier available) OR AWS Account

### Local Development Setup

#### 1. Setup Backend

```bash
cd backend
npm install

# Create .env file
cp .env.example .env
# Edit .env with your database credentials

# Run database migrations
npm run migrate

# Start development server
npm run dev
```

#### 2. Setup Frontend

```bash
cd frontend
npm install

# Start React development server
npm start
```

#### 3. Using Docker Compose (Recommended)

```bash
docker-compose up -d

# Backend will run on http://localhost:5000
# Frontend will run on http://localhost:3000
# PostgreSQL will run on localhost:5432
# Redis will run on localhost:6379
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Photos
- `GET /api/photos` - Get all photos (paginated)
- `GET /api/photos/search?q=query` - Search photos
- `GET /api/photos/:id` - Get photo details
- `POST /api/photos` - Upload photo (Creator only)

### Comments
- `GET /api/comments/photo/:photoId` - Get photo comments
- `POST /api/comments` - Add comment
- `DELETE /api/comments/:id` - Delete comment

### Users
- `GET /api/users/:id` - Get user profile
- `PUT /api/users/:id` - Update user profile



## 🗄️ Database Schema

### Tables
- **users**: User accounts with roles
- **photos**: Photo metadata and storage paths
- **comments**: Photo comments
- **ratings**: Photo ratings (1-5 stars)
- **photo_tags**: People tagged in photos
- **followers**: Social connections (optional)

See `backend/src/db/schema.sql` for full schema.

## 🔄 CI/CD Pipeline

GitHub Actions workflow includes:
- Automated testing on push/PRs
- Linting and code quality checks
- Docker image building
- PostgreSQL test database
- Coverage reports

**Push to `main` or `develop` to trigger pipeline.**

### Workflow Steps
1. Backend unit tests
2. Frontend tests & build
3. Docker image builds
4. (Optional) Push to container registry

See `.github/workflows/ci-cd.yml` for configuration.

## ☁️ Deployment

### Azure Deployment (FREE TIER - Recommended for This Project)

**Year 1: $0 Cost** ✅

```bash
# Install Azure CLI
az login

# Automated deployment (Windows)
.\deploy-azure.ps1

# OR Manual deployment
# See docs/azure-deployment.md for detailed steps
```

**Services Used**:
- App Service (F1 - Free)
- PostgreSQL (Free 12 months)
- Blob Storage (5GB free)
- Container Registry (Free)
- Key Vault (Free)

**Cost Estimate**:
- Year 1: **FREE**
- Year 2+: ~$40-50/month

See [Azure Deployment Guide](docs/azure-deployment.md) for details.

### AWS Deployment

1. **Database**: RDS PostgreSQL instance
2. **Backend**: ECS/App Runner (Docker container)
3. **Frontend**: S3 + CloudFront (CDN)
4. **Cache**: ElastiCache (Redis)
5. **Storage**: S3 bucket for photos

See [AWS deployment guide](docs/deployment.md) for details.

### Docker Deployment (Local Testing)

```bash
# Build images
docker build -t photoshare-backend:1.0.0 ./backend
docker build -t photoshare-frontend:1.0.0 ./frontend

# Push to registry
docker push your-registry/photoshare-backend:1.0.0
docker push your-registry/photoshare-frontend:1.0.0

# Deploy to Kubernetes or Docker Swarm
```

## 🛡️ Security Features

- JWT token authentication
- Password hashing with bcryptjs
- CORS protection
- Helmet.js for HTTP headers
- Input validation with express-validator
- SQL injection prevention (parameterized queries)
- Role-based access control

## 📊 Performance Optimization

- Database connection pooling
- Query result indexing
- Pagination for large datasets
- Redis caching for frequently accessed data
- Static asset caching with Nginx
- Image optimization placeholders
- CDN-ready frontend build

## 🧪 Testing

```bash
# Backend tests
cd backend
npm test

# Frontend tests
cd frontend
npm test
```

## 📚 Project Structure

```
.
├── backend/
│   ├── src/
│   │   ├── server.js
│   │   ├── config/
│   │   ├── middleware/
│   │   ├── routes/
│   │   ├── db/
│   │   └── services/
│   ├── Dockerfile
│   └── package.json
├── frontend/
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── App.js
│   │   └── App.css
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   └── scalability.md
├── docker-compose.yml
└── .github/
    └── workflows/
        └── ci-cd.yml
```

## 🔧 Environment Variables

See `backend/.env.example` for required variables:
- Database connection details
- JWT secret
- AWS credentials
- Redis configuration
- Node environment

## 📖 Additional Documentation

- [Architecture Design](docs/architecture.md)
- [Deployment Guide](docs/deployment.md)
- [Scalability Considerations](docs/scalability.md)

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Run tests
4. Submit PR

## 📝 License

MIT License

## 👨‍💼 Author

COM769 Student - Scalable Advanced Software Solutions

---

**Last Updated**: April 2026
