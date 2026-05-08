# Architecture & Design Documentation

## System Architecture

### High-Level Design

The PhotoShare application follows a classic three-tier architecture:

1. **Presentation Layer** (React Frontend)
   - Single-page application (SPA)
   - Component-based UI
   - REST API consumption
   - Local state management

2. **Application Layer** (Node.js/Express Backend)
   - RESTful API endpoints
   - Business logic implementation
   - Authentication & authorization
   - Data validation

3. **Data Layer** (PostgreSQL + S3)
   - Relational database for structured data
   - Object storage for media files
   - Connection pooling for performance

### Scalability Patterns Implemented

#### 1. Horizontal Scaling - Backend
- Stateless API design (no session storage)
- JWT tokens for authentication (client-managed state)
- Multiple backend instances can run independently
- Load balancer distributes traffic

#### 2. Database Optimization
- Connection pooling (pg library with pool config)
- Query optimization with indexes
- Pagination to limit data transfer
- Caching layer (Redis) for frequently accessed data

#### 3. Static Asset Optimization
- Frontend compiled and minified
- Nginx reverse proxy for efficient serving
- CDN-ready output (S3 + CloudFront)
- Gzip compression enabled

#### 4. Caching Strategy
```
User Request
    ↓
[Cache Check] → (Hit) → Return Cached Response
    ↓ (Miss)
[Database Query] → [Store in Cache] → Return Response
```

#### 5. Database Indexing
Strategic indexes on:
- `photos(creator_id)` - Filter by creator
- `photos(created_at DESC)` - Sort by recency
- `comments(photo_id)` - Find photo comments
- `ratings(photo_id)` - Aggregate ratings
- `users(email)` + `users(username)` - Authentication lookups

## API Design

### RESTful Principles

All endpoints follow REST conventions:
- `GET` - Retrieve data
- `POST` - Create data
- `PUT` - Update data
- `DELETE` - Remove data

### Request/Response Format

**Request**:
```json
{
  "title": "Beautiful sunset",
  "caption": "Captured at the beach",
  "location": "Miami Beach",
  "image_url": "https://s3.amazonaws.com/..."
}
```

**Response**:
```json
{
  "id": 1,
  "creator_id": 5,
  "title": "Beautiful sunset",
  "created_at": "2026-04-18T10:30:00Z",
  "average_rating": 4.5,
  "comment_count": 12
}
```

### Error Handling

Standardized error responses:
```json
{
  "success": false,
  "message": "Description of the error",
  "statusCode": 400
}
```

## Security Architecture

### Authentication Flow

```
User Input (email + password)
    ↓
Password Validation (bcryptjs.compare)
    ↓
Generate JWT Token (jwt.sign)
    ↓
Return Token to Client
    ↓
Client Stores Token (localStorage)
    ↓
Future Requests Include Token in Header
    ↓
Server Validates Token (jwt.verify)
    ↓
Extract User Info from Token
```

### Authorization Strategy

Role-based access control (RBAC):
- **Consumer**: View photos, comment, rate
- **Creator**: Upload photos + Consumer permissions

## Database Design

### Entity Relationships

```
users (1) ──────────── (N) photos
  │                        │
  │                        ├──── (N) comments
  │                        ├──── (N) ratings
  │                        └──── (N) photo_tags
  │
  └─────────── (N) comments
  │
  └─────────── (N) ratings
```

### Key Design Decisions

1. **UTF-8 Support**: All text fields support Unicode
2. **Timestamps**: All records include `created_at` and `updated_at`
3. **Soft Deletes**: Comments use `is_deleted` flag (audit trail)
4. **Cascading Deletes**: Deleting user cascades to photos/comments
5. **Unique Constraints**: Prevent duplicate ratings/follows

## Performance Considerations

### Query Optimization

**Before** (N+1 problem):
```javascript
const photos = await getPhotos();
for (let photo of photos) {
  photo.comments = await getComments(photo.id); // N+1 queries!
}
```

**After** (Join query):
```javascript
const photos = await query(`
  SELECT p.*, COUNT(c.id) as comment_count
  FROM photos p
  LEFT JOIN comments c ON p.id = c.photo_id
  GROUP BY p.id
`);
```

### Caching Strategy

```javascript
// Check cache first
const cached = await redis.get(`photo:${id}`);
if (cached) return JSON.parse(cached);

// Query database
const photo = await db.query('SELECT * FROM photos WHERE id = $1', [id]);

// Store in cache (60 seconds TTL)
await redis.setex(`photo:${id}`, 60, JSON.stringify(photo));

return photo;
```

### Pagination Implementation

```javascript
const page = req.query.page || 1;
const limit = 20;
const offset = (page - 1) * limit;

const result = await query(`
  SELECT * FROM photos
  LIMIT $1 OFFSET $2
`, [limit, offset]);

// Return metadata for client
return {
  data: result.rows,
  page: page,
  total: totalCount,
  pages: Math.ceil(totalCount / limit)
};
```

## Deployment Architecture

### Local Development
- Docker Compose orchestrates all services
- Hot-reload for backend and frontend
- Shared volume for code changes

### Production (AWS)
```
┌─────────────────────────────────────┐
│       Route 53 (DNS)                │
├─────────────────────────────────────┤
│                                     │
│   ┌──────────────┐  ┌────────────┐ │
│   │  CloudFront  │  │   ALB      │ │
│   │   (CDN)      │  │(Load Bal)  │ │
│   └──────────────┘  └────────────┘ │
│         │                   │       │
│         │            ┌──────┴────┐  │
│         │      ┌───────┐   ┌──────┐ │
│         └─────→│ S3 (Frontend)    │ │
│                │      │   │Backend│ │
│                │      └─────────┐ │ │
│                │ ECS Cluster    └─┘ │
│                └────────────────────┘│
│                                     │
├─────────────────────────────────────┤
│ RDS (PostgreSQL)                    │
├─────────────────────────────────────┤
│ ElastiCache (Redis)                 │
├─────────────────────────────────────┤
│ S3 (Photo Storage)                  │
└─────────────────────────────────────┘
```

## Monitoring & Logging

### Application Metrics
- API response times
- Database query performance
- Cache hit/miss ratios
- Error rates
- User authentication events

### System Metrics
- CPU utilization
- Memory usage
- Disk I/O
- Network throughput
- Database connections

### Logging
- Request/response logs
- Error stack traces
- Database query logs
- Authentication attempts

## Future Enhancements

1. **WebSocket Support**: Real-time notifications
2. **Image Processing**: Automatic resizing, compression
3. **Recommendation Engine**: Personalized photo suggestions
4. **Advanced Search**: Full-text search capabilities
5. **Social Features**: Following, notifications, messaging
6. **Analytics**: User behavior tracking, insights
