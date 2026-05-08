# Scalability Considerations

## Scalability Analysis

### Current Bottlenecks & Solutions

#### 1. Database Scaling

**Problem**: Single database instance becomes bottleneck at high load

**Solutions**:
- **Read Replicas**: RDS multi-AZ for high availability
- **Read-Only Scaling**: Create read replicas for SELECT queries
- **Sharding**: Partition data by user_id or region (future)
- **Connection Pooling**: Already implemented with pg library

**Implementation**:
```javascript
// Current: Single connection pool
const pool = new Pool(config);

// Future: Read/Write separation
const writePool = new Pool(writeConfig);
const readPool = new Pool(readConfig);

// Route queries appropriately
if (isReadQuery) {
  result = await readPool.query(sql);
} else {
  result = await writePool.query(sql);
}
```

#### 2. API Server Scaling

**Current State**: Stateless design allows horizontal scaling

**Implementation**:
```yaml
# ECS Auto-Scaling Configuration
BackendServiceScaling:
  Type: AWS::ApplicationAutoScaling::ScalableTarget
  Properties:
    MaxCapacity: 10
    MinCapacity: 2
    DesiredCapacity: 3
    ScalingPolicy:
      TargetValue: 70.0  # CPU target
      PredefinedMetricSpecification:
        PredefinedMetricType: ECSServiceAverageCPUUtilization
    ScaleOutCooldown: 60
    ScaleInCooldown: 300
```

**Benefits**:
- Automatically adds/removes instances based on load
- Maintains performance even during traffic spikes
- Cost-efficient (pay only for what you use)

#### 3. Cache Layer Optimization

**Current**: Redis for basic caching

**Scalability Strategy**:
```javascript
// Cache invalidation pattern
async function updatePhoto(id, data) {
  // Update database
  const photo = await db.updatePhoto(id, data);
  
  // Invalidate cache
  await redis.del(`photo:${id}`);
  
  // Invalidate related caches
  await redis.del(`photos:list:*`);
  
  return photo;
}

// Cache population on read
async function getPhoto(id) {
  // Try cache first
  let photo = await redis.get(`photo:${id}`);
  if (photo) return JSON.parse(photo);
  
  // Load from database
  photo = await db.getPhoto(id);
  
  // Cache for 5 minutes
  await redis.setex(`photo:${id}`, 300, JSON.stringify(photo));
  
  return photo;
}
```

**Scaling Beyond Single Redis**:
- **Redis Cluster**: Multiple nodes for higher throughput
- **Memcached**: Alternative for simple key-value caching
- **AWS ElastiCache**: Managed solution with auto-scaling

#### 4. Storage Scaling (S3)

**Current**: AWS S3 (highly scalable)

**Optimization**:
```javascript
// Implement image optimization pipeline
const uploadPhoto = async (req, res) => {
  const file = req.file;
  
  // Generate multiple sizes
  const sizes = {
    thumbnail: '200x200',    // Preview
    medium: '500x500',       // Feed view
    large: '1200x1200'       // Full view
  };
  
  const uploadPromises = Object.entries(sizes).map(async ([size, dim]) => {
    const optimized = await imageOptimizer.resize(file, dim);
    return s3.upload({
      Key: `photos/${photoId}/${size}.jpg`,
      Body: optimized,
      ACL: 'public-read'
    });
  });
  
  await Promise.all(uploadPromises);
};
```

**S3 Optimization**:
- Use CloudFront CDN for global distribution
- Enable S3 Transfer Acceleration
- Implement object lifecycle policies (archive old images)
- Use S3 Intelligent-Tiering for cost optimization

#### 5. API Response Optimization

**Pagination Impact**:
```
Without pagination:
- Request 1M photos = 100MB response
- Slow network = timeout
- High server memory = crash

With pagination:
- Request 20 photos + metadata = 50KB response
- Fast, responsive
- Server memory stable
```

**Implementation**:
```javascript
// Smart pagination with cursor-based approach
const getPhotos = async (req, res) => {
  const cursor = req.query.cursor; // Last photo ID from previous page
  const limit = Math.min(req.query.limit || 20, 100); // Max 100
  
  let query = 'SELECT * FROM photos WHERE visibility = $1';
  const params = ['public'];
  
  if (cursor) {
    query += ' AND id < $2';
    params.push(cursor);
  }
  
  query += ` ORDER BY created_at DESC LIMIT ${limit + 1}`;
  
  const results = await db.query(query, params);
  
  return {
    photos: results.slice(0, limit),
    hasMore: results.length > limit,
    nextCursor: results[limit - 1]?.id
  };
};
```

### Scalability Metrics

#### Read-Heavy Workload (Photo browsing)
- Cache hit ratio target: 80%+
- Database read replicas: 3-5
- CDN edge locations: Global

#### Write-Heavy Workload (Comments/ratings)
- Database connection pool: 50-100
- Queue system (optional): SQS for async processing
- Batch writes: Accumulate and write periodically

#### Concurrent Users
```
Current Architecture Capacity:

2 Backend Instances:
- 200-500 requests/sec per instance
- Total: 400-1000 concurrent users

With Auto-Scaling (10 instances):
- 2000-5000 concurrent users possible
- Cost scales with demand
```

## Performance Tuning

### Database Query Optimization

**Query Analysis**:
```sql
-- Enable query analysis
EXPLAIN ANALYZE
SELECT p.*, COUNT(c.id) as comment_count
FROM photos p
LEFT JOIN comments c ON p.id = c.photo_id
WHERE p.visibility = 'public'
GROUP BY p.id
ORDER BY p.created_at DESC
LIMIT 20;

-- Check for sequential scans (bad) vs index scans (good)
-- If sequential scan, ensure indexes exist
CREATE INDEX idx_photos_visibility ON photos(visibility);
CREATE INDEX idx_photos_created_at ON photos(created_at DESC);
```

### Node.js Performance

**Memory Optimization**:
```javascript
// Use streaming for large responses
app.get('/api/photos/export', (req, res) => {
  const stream = db.query(sql).stream();
  
  res.setHeader('Content-Type', 'application/json');
  res.write('[');
  
  let first = true;
  stream.on('data', (row) => {
    if (!first) res.write(',');
    res.write(JSON.stringify(row));
    first = false;
  });
  
  stream.on('end', () => {
    res.write(']');
    res.end();
  });
});
```

### Frontend Performance

**Code Splitting**:
```javascript
// Lazy load photo detail page
const PhotoDetailPage = lazy(() => import('./pages/PhotoDetailPage'));

// Suspense boundary
<Suspense fallback={<Loading />}>
  <PhotoDetailPage />
</Suspense>
```

## Load Testing

### Using Apache Bench
```bash
# Test 1000 requests with 100 concurrent connections
ab -n 1000 -c 100 http://localhost:5000/api/photos

# With POST data
ab -n 1000 -c 100 -p data.json \
   -T application/json \
   http://localhost:5000/api/comments
```

### Using k6
```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 100,
  duration: '30s',
  stages: [
    { duration: '5s', target: 50 },
    { duration: '10s', target: 100 },
    { duration: '5s', target: 0 },
  ],
};

export default () => {
  const response = http.get('http://localhost:5000/api/photos');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
};
```

##Cost Estimation (AWS)

### Monthly Costs (1M monthly active users)

| Service | Cost | Details |
|---------|------|---------|
| RDS (db.t4g.micro → db.t4g.small) | $200-300 | Multi-AZ, backups |
| ECS/Fargate (avg 4 instances) | $300-400 | vCPU + Memory |
| ElastiCache (cache.t4g.micro) | $20-30 | Redis cluster |
| S3 Storage (100GB photos) | $2.50 | Standard storage |
| S3 Transfer (2TB/month) | $180 | Data out |
| CloudFront CDN | $100-150 | Global distribution |
| **Total** | **~$800-1100** | Scalable to millions |

### Optimization Options
- Reserved instances: 30-50% discount
- Spot instances: 70% discount (non-critical)
- S3 Intelligent-Tiering: Auto archive old data
- AWS Free Tier: First 12 months free (limited)

## Recommendations for COM769

1. **Implement caching** with Redis for photo listings
2. **Use connection pooling** (✓ Already done)
3. **Add database indexes** on frequently queried columns (✓ Already done)
4. **Implement pagination** for all list endpoints (✓ Already done)
5. **Use CDN** for static content and images
6. **Monitor performance** with CloudWatch
7. **Stress test** with k6 or Apache Bench
8. **Document architecture** decisions (✓ Done in architecture.md)
