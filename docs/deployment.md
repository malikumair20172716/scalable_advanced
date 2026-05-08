# Deployment Guide

## Prerequisites

- AWS Account with appropriate IAM permissions
- AWS CLI configured
- Docker installed locally
- Node.js 18+
- PostgreSQL client tools

## Step 1: Set Up AWS RDS (PostgreSQL)

### Create RDS Instance

```bash
# Using AWS CLI
aws rds create-db-instance \
  --db-instance-identifier photoshare-db \
  --db-instance-class db.t4g.micro \
  --engine postgres \
  --master-username postgres \
  --master-user-password YourSecurePassword123 \
  --allocated-storage 20 \
  --backup-retention-period 7 \
  --multi-az \
  --storage-encrypted
```

### Allow Inbound Traffic

```bash
# Get RDS Security Group ID
SG_ID=$(aws rds describe-db-instances \
  --db-instance-identifier photoshare-db \
  --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
  --output text)

# Allow inbound on port 5432
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 5432 \
  --cidr 0.0.0.0/0
```

### Initialize Database

```bash
# Connect to RDS instance
psql -h photoshare-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com \
     -U postgres \
     -d postgres

# Create database
CREATE DATABASE photoshare_db;

# Connect to new database
\c photoshare_db

# Run schema
\i backend/src/db/schema.sql
```

## Step 2: Set Up ElastiCache (Redis)

```bash
# Create Redis cluster
aws elasticache create-cache-cluster \
  --cache-cluster-id photoshare-cache \
  --cache-node-type cache.t4g.micro \
  --engine redis \
  --num-cache-nodes 1 \
  --security-group-ids sg-xxxxxxxxx
```

## Step 3: Set Up S3 for Photo Storage

```bash
# Create S3 bucket
aws s3 mb s3://photoshare-images-$(date +%s)

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket photoshare-images-xxxx \
  --versioning-configuration Status=Enabled

# Create CORS configuration
cat > cors.json << EOF
{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}
EOF

aws s3api put-bucket-cors \
  --bucket photoshare-images-xxxx \
  --cors-configuration file://cors.json
```

## Step 4: Create IAM Role for Backend

```bash
# Create role
aws iam create-role \
  --role-name PhotoShareBackendRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach S3 policy
aws iam put-role-policy \
  --role-name PhotoShareBackendRole \
  --policy-name S3Access \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": "arn:aws:s3:::photoshare-images-*"
    }]
  }'
```

## Step 5: Push Docker Images to ECR

```bash
# Create ECR repository
aws ecr create-repository --repository-name photoshare-backend
aws ecr create-repository --repository-name photoshare-frontend

# Get login token
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  1234567890.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend
docker build -t photoshare-backend:1.0.0 ./backend
docker tag photoshare-backend:1.0.0 \
  1234567890.dkr.ecr.us-east-1.amazonaws.com/photoshare-backend:1.0.0
docker push \
  1234567890.dkr.ecr.us-east-1.amazonaws.com/photoshare-backend:1.0.0

# Build and push frontend
docker build -t photoshare-frontend:1.0.0 ./frontend
docker tag photoshare-frontend:1.0.0 \
  1234567890.dkr.ecr.us-east-1.amazonaws.com/photoshare-frontend:1.0.0
docker push \
  1234567890.dkr.ecr.us-east-1.amazonaws.com/photoshare-frontend:1.0.0
```

## Step 6: Deploy with ECS

### Create ECS Cluster And Services

```bash
# Create cluster
aws ecs create-cluster --cluster-name photoshare-cluster

# Register backend task definition (create task-def.json first)
aws ecs register-task-definition \
  --cli-input-json file://backend-task-def.json

# Create backend service
aws ecs create-service \
  --cluster photoshare-cluster \
  --service-name photoshare-backend \
  --task-definition photoshare-backend:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"

# Similar for frontend service
```

### Backend Task Definition (`backend-task-def.json`)

```json
{
  "family": "photoshare-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "photoshare-backend",
      "image": "1234567890.dkr.ecr.us-east-1.amazonaws.com/photoshare-backend:1.0.0",
      "portMappings": [{
        "containerPort": 5000,
        "protocol": "tcp"
      }],
      "environment": [
        {
          "name": "DB_HOST",
          "value": "photoshare-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com"
        },
        {
          "name": "DB_USER",
          "value": "postgres"
        },
        {
          "name": "DB_NAME",
          "value": "photoshare_db"
        },
        {
          "name": "REDIS_HOST",
          "value": "photoshare-cache.xxxxxxxxxxxx.ng.0001.use1.cache.amazonaws.com"
        },
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:db-password"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:jwt-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/photoshare-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

## Step 7: Set Up CloudFront CDN

```bash
# Create CloudFront distribution
aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json
```

## Step 8: Configure DNS with Route 53

```bash
# Create Route 53 hosted zone (if needed)
aws route53 create-hosted-zone \
  --name photoshare.example.com \
  --caller-reference $(date +%s)

# Create alias record for ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.photoshare.example.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z35SXDOTRQ7X7K",
          "DNSName": "photoshare-alb-xxx.us-east-1.elb.amazonaws.com",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

## Step 9: Enable Monitoring & Logging

```bash
# Create CloudWatch log group
aws logs create-log-group --log-group-name /ecs/photoshare-backend

# Set retention
aws logs put-retention-policy \
  --log-group-name /ecs/photoshare-backend \
  --retention-in-days 30

# Create alarms
aws cloudwatch put-metric-alarm \
  --alarm-name photoshare-backend-errors \
  --alarm-description "Alert on backend errors" \
  --metric-name Errors \
  --namespace AWS/ECS \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

## Verification

```bash
# Test API health
curl https://api.photoshare.example.com/health

# Check logs
aws logs tail /ecs/photoshare-backend --follow

# Monitor services
aws ecs describe-services \
  --cluster photoshare-cluster \
  --services photoshare-backend
```

## Cost Optimization

- Use t4g instances (Graviton2, better performance/cost)
- Enable auto-scaling based on CPU/memory
- Use spot instances for non-critical workloads
- Configure RDS backup retention appropriately
- Monitor and clean up unused S3 objects

## Security Hardening

- Enable VPC security groups
- Use AWS Secrets Manager for credentials
- Enable CloudTrail logging
- Configure WAF for additional protection
- Enable S3 bucket encryption
