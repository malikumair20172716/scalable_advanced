# Azure Deployment Guide - Free Tier Focused

## Azure Free Services Strategy

This guide maximizes **Azure free tier** services for your PhotoShare application.

### Free Tier Services Used

| Service | Free Tier | Limit |
|---------|-----------|-------|
| **Azure App Service** | Yes | 1 free instance (B1) |
| **Azure Database for PostgreSQL** | Yes | 12 months free (B1) |
| **Azure Container Registry** | Yes | 10 builds/day, 1 repo |
| **Blob Storage** | Yes | 5GB + 20K ops/month |
| **Azure CDN** | Partial | First 10TB/month charged |
| **Key Vault** | Yes | Unlimited reads |
| **Application Insights** | Partial | 5GB/month free |

### Paid Services (But Minimal Cost)

| Service | Estimated Cost | Notes |
|---------|----------------|-------|
| Azure CDN | $0.08-0.72/GB | Optional, use Blob direct access first |
| Additional Storage | $0.018/GB | Beyond 5GB free |
| Log Analytics | Varies | Free tier available |

---

## Prerequisites

```bash
# Install Azure CLI
# Windows: choco install azure-cli
# macOS: brew install azure-cli
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Create resource group
az group create --name photoshare-rg --location eastus
```

---

## Step 1: Set Up Azure Container Registry (Free)

```bash
# Create registry (free tier)
az acr create \
  --resource-group photoshare-rg \
  --name photoshareregistry \
  --sku Free

# Get login credentials
az acr credential show --resource-group photoshare-rg --name photoshareregistry

# Login to ACR
az acr login --name photoshareregistry

# Build and push images
az acr build --registry photoshareregistry \
  --image photoshare-backend:1.0.0 \
  --file Dockerfile ./backend

az acr build --registry photoshareregistry \
  --image photoshare-frontend:1.0.0 \
  --file Dockerfile ./frontend

# Verify images
az acr repository list --name photoshareregistry
```

---

## Step 2: Set Up Azure Database for PostgreSQL (Free - 12 Months)

```bash
# Create PostgreSQL server (free tier - B1 for first 12 months)
az postgres server create \
  --resource-group photoshare-rg \
  --name photoshare-db-server \
  --location eastus \
  --admin-user dbadmin \
  --admin-password 'YourSecurePassword123!' \
  --sku-name B_Gen5_1 \
  --storage-size 51200 \
  --backup-retention 7 \
  --geo-redundant-backup Disabled

# Create database
az postgres db create \
  --resource-group photoshare-rg \
  --server-name photoshare-db-server \
  --name photoshare_db

# Allow Azure services to access database
az postgres server firewall-rule create \
  --resource-group photoshare-rg \
  --server-name photoshare-db-server \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Allow local IP for testing
az postgres server firewall-rule create \
  --resource-group photoshare-rg \
  --server-name photoshare-db-server \
  --name AllowLocalAccess \
  --start-ip-address YOUR_IP \
  --end-ip-address YOUR_IP

# Get connection string
az postgres server show \
  --resource-group photoshare-rg \
  --name photoshare-db-server \
  --query "fullyQualifiedDomainName"
```

### Connect and Initialize Database

```bash
# Install PostgreSQL client
# Windows: choco install postgresql
# macOS: brew install postgresql
# Linux: sudo apt-get install postgresql-client

# Connect to database
psql -h photoshare-db-server.postgres.database.azure.com \
     -U dbadmin@photoshare-db-server \
     -d photoshare_db \
     -f backend/src/db/schema.sql

# Enter password when prompted
```

---

## Step 3: Set Up Azure Blob Storage (Free - 5GB)

```bash
# Create storage account (free tier)
az storage account create \
  --resource-group photoshare-rg \
  --name photoshareussa \
  --location eastus \
  --sku Standard_LRS \
  --access-tier Hot

# Get connection string
CONNECTION_STRING=$(az storage account show-connection-string \
  --resource-group photoshare-rg \
  --name photoshareussa \
  --query connectionString -o tsv)

# Create blob container for photos
az storage container create \
  --account-name photoshareussa \
  --name photos \
  --public-access blob

# Enable CORS for photos
cat > cors.json << EOF
[{
  "allowedOrigins": ["*"],
  "allowedMethods": ["GET", "PUT", "POST", "DELETE"],
  "allowedHeaders": ["*"],
  "exposedHeaders": ["*"],
  "maxAgeInSeconds": 3600
}]
EOF

az storage cors add \
  --account-name photoshareussa \
  --services b \
  --methods GET PUT POST DELETE \
  --allowed-headers "*" \
  --exposed-headers "*" \
  --max-age 3600
```

---

## Step 4: Set Up Azure Key Vault (Free - Unlimited Reads)

```bash
# Create Key Vault
az keyvault create \
  --resource-group photoshare-rg \
  --name photoshare-vault \
  --location eastus

# Store secrets
az keyvault secret set \
  --vault-name photoshare-vault \
  --name db-password \
  --value 'YourSecurePassword123!'

az keyvault secret set \
  --vault-name photoshare-vault \
  --name jwt-secret \
  --value 'your-jwt-secret-key-here'

az keyvault secret set \
  --vault-name photoshare-vault \
  --name storage-connection \
  --value "$CONNECTION_STRING"
```

---

## Step 5: Deploy Backend to Azure App Service (Free)

### Create App Service Plan

```bash
# Create free App Service Plan
az appservice plan create \
  --name photoshare-plan \
  --resource-group photoshare-rg \
  --sku F1 \
  --is-linux

# Note: F1 (Free) includes:
# - 1GB RAM
# - 60 minutes CPU per day
# - Daily quota (enough for development/light production)
```

### Deploy Backend App

```bash
# Create backend web app
az webapp create \
  --resource-group photoshare-rg \
  --plan photoshare-plan \
  --name photoshare-backend \
  --deployment-container-image-name-user photoshareregistry.azurecr.io/photoshare-backend:1.0.0

# Configure container settings
az webapp config container set \
  --name photoshare-backend \
  --resource-group photoshare-rg \
  --docker-custom-image-name photoshareregistry.azurecr.io/photoshare-backend:1.0.0 \
  --docker-registry-server-url "https://photoshareregistry.azurecr.io" \
  --docker-registry-server-user "USERNAME" \
  --docker-registry-server-password "PASSWORD"

# Configure environment variables
az webapp config appsettings set \
  --resource-group photoshare-rg \
  --name photoshare-backend \
  --settings \
    DB_HOST="photoshare-db-server.postgres.database.azure.com" \
    DB_USER="dbadmin@photoshare-db-server" \
    DB_PASSWORD="YourSecurePassword123!" \
    DB_NAME="photoshare_db" \
    JWT_SECRET="your-jwt-secret-key" \
    STORAGE_CONNECTION_STRING="$CONNECTION_STRING" \
    NODE_ENV="production" \
    PORT=8080

# Enable logging
az webapp log config \
  --resource-group photoshare-rg \
  --name photoshare-backend \
  --docker-container-logging filesystem

# View backend URL
echo "Backend deployed at: https://photoshare-backend.azurewebsites.net"
```

---

## Step 6: Deploy Frontend to Azure App Service (Free)

```bash
# Create frontend web app (static hosting)
az webapp create \
  --resource-group photoshare-rg \
  --plan photoshare-plan \
  --name photoshare-frontend \
  --deployment-container-image-name-user photoshareregistry.azurecr.io/photoshare-frontend:1.0.0

# Configure container settings
az webapp config container set \
  --name photoshare-frontend \
  --resource-group photoshare-rg \
  --docker-custom-image-name photoshareregistry.azurecr.io/photoshare-frontend:1.0.0 \
  --docker-registry-server-url "https://photoshareregistry.azurecr.io" \
  --docker-registry-server-user "USERNAME" \
  --docker-registry-server-password "PASSWORD"

# Configure app settings (point to backend)
az webapp config appsettings set \
  --resource-group photoshare-rg \
  --name photoshare-frontend \
  --settings \
    REACT_APP_API_URL="https://photoshare-backend.azurewebsites.net/api"

# View frontend URL
echo "Frontend deployed at: https://photoshare-frontend.azurewebsites.net"
```

---

## Step 7: Optional - Azure CDN for Photos (Paid but Cheap)

```bash
# Create CDN profile (only if needed)
az cdn profile create \
  --resource-group photoshare-rg \
  --name photoshare-cdn \
  --sku Standard_Microsoft

# Create CDN endpoint for blob storage
az cdn endpoint create \
  --resource-group photoshare-rg \
  --profile-name photoshare-cdn \
  --name photoshare-photos \
  --origin photoshareussa.blob.core.windows.net \
  --origin-path /photos

# View CDN URL
echo "CDN URL: https://photoshare-photos.azureedge.net"
```

---

## Step 8: Monitoring & Logging (Free/Minimal)

```bash
# Enable Application Insights (free tier: 5GB/month)
az monitor app-insights component create \
  --resource-group photoshare-rg \
  --app photoshare-insights \
  --location eastus

# Link to backend app
INSIGHTS_KEY=$(az monitor app-insights component show \
  --resource-group photoshare-rg \
  --app photoshare-insights \
  --query instrumentationKey -o tsv)

az webapp config appsettings set \
  --resource-group photoshare-rg \
  --name photoshare-backend \
  --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$INSIGHTS_KEY"

# View logs
az webapp log tail --resource-group photoshare-rg --name photoshare-backend
```

---

## Step 9: Configure Custom Domain (Optional)

```bash
# Add custom domain
az webapp config hostname add \
  --resource-group photoshare-rg \
  --webapp-name photoshare-backend \
  --hostname api.yourdomain.com

# Add SSL certificate
az webapp config ssl bind \
  --resource-group photoshare-rg \
  --name photoshare-backend \
  --certificate-thumbprint THUMBPRINT
```

---

## Free Tier Limitations & Workarounds

### 1. App Service Plan F1 (Free)

**Limitations**:
- 60 minutes CPU per day
- 1GB RAM
- No custom domains
- No auto-scaling
- Shared infrastructure

**Workaround**:
```bash
# Upgrade to B1 ($12/month) for development
az appservice plan update \
  --name photoshare-plan \
  --sku B1
```

### 2. PostgreSQL (Free for 12 months only)

**After 12 months**:
- B_Gen5_1 costs ~$40/month
- Consider migrating to Azure Database for MySQL (cheaper) or other options

**Cost-saving tips**:
```bash
# Monitor database CPU
az monitor metrics list \
  --resource /subscriptions/SUB_ID/resourceGroups/photoshare-rg/providers/Microsoft.DBforPostgreSQL/servers/photoshare-db-server \
  --metric cpu_percent \
  --start-time 2026-04-18T00:00:00Z
```

### 3. Blob Storage (Free 5GB)

**After 5GB**:
- $0.018 per GB per month (very cheap)
- Use lifecycle management to archive old photos

```bash
# Set lifecycle policy (archive after 30 days)
cat > lifecycle.json << EOF
{
  "rules": [{
    "name": "archive-old-photos",
    "enabled": true,
    "type": "Lifecycle",
    "definition": {
      "actions": {
        "baseBlob": {
          "tieredDelete": {
            "daysAfterModificationGreaterThan": 30
          }
        }
      },
      "filters": {
        "blobTypes": ["blockBlob"]
      }
    }
  }]
}
EOF

az storage account management-policy create \
  --account-name photoshareussa \
  --policy @lifecycle.json
```

---

## Monthly Cost Estimate (Free Tier)

| Service | Cost |
|---------|------|
| App Service (F1) | **FREE** |
| PostgreSQL (Free 12mo) | **FREE** |
| Container Registry (Free) | **FREE** |
| Blob Storage (5GB) | **FREE** |
| Key Vault | **FREE** |
| Application Insights (5GB) | **FREE** |
| **Total (Year 1)** | **$0** |
| **Total (Year 2+)** | ~$40-50/month |

---

## Deployment Checklist

```bash
[ ] Create resource group
[ ] Create Container Registry
[ ] Build and push Docker images
[ ] Create PostgreSQL database
[ ] Run database migrations
[ ] Create Blob Storage account
[ ] Create Key Vault with secrets
[ ] Create App Service Plan (F1)
[ ] Deploy backend app
[ ] Deploy frontend app
[ ] Configure environment variables
[ ] Test backend API
[ ] Test frontend access
[ ] Monitor logs for errors
[ ] Setup monitoring/insights
```

---

## Testing Deployment

```bash
# Health check backend
curl https://photoshare-backend.azurewebsites.net/health

# Test API
curl https://photoshare-backend.azurewebsites.net/api/photos

# View logs
az webapp log tail \
  --resource-group photoshare-rg \
  --name photoshare-backend \
  --follow

# Test frontend
# Navigate to: https://photoshare-frontend.azurewebsites.net
```

---

## Scaling Beyond Free Tier

When you outgrow free tier:

### Option 1: Upgrade App Service Plan
```bash
az appservice plan update \
  --name photoshare-plan \
  --sku B2  # ~$100/month
```

### Option 2: Use Azure Container Instances (Cheaper)
```bash
# Create container instance (pay-as-you-go, cheaper than App Service)
az container create \
  --resource-group photoshare-rg \
  --name photoshare-backend \
  --image photoshareregistry.azurecr.io/photoshare-backend:1.0.0 \
  --cpu 1 \
  --memory 1 \
  --environment-variables \
    DB_HOST="photoshare-db-server.postgres.database.azure.com" \
    DB_USER="dbadmin@photoshare-db-server" \
  --registry-login-server photoshareregistry.azurecr.io \
  --registry-username USERNAME \
  --registry-password PASSWORD
```

### Option 3: Use Azure Kubernetes Service (AKS)
- Free control plane
- Only pay for agent nodes
- Better for large-scale applications

---

## Troubleshooting

### Container won't start
```bash
# Check logs
az webapp log tail --resource-group photoshare-rg --name photoshare-backend

# Restart container
az webapp restart --resource-group photoshare-rg --name photoshare-backend
```

### Database connection error
```bash
# Check firewall rules
az postgres server firewall-rule list \
  --resource-group photoshare-rg \
  --server-name photoshare-db-server

# Add IP if needed
YOUR_IP=$(curl -s https://api.ipify.org)
echo "Your IP: $YOUR_IP"
```

### CDN not updating
```bash
# Purge CDN cache
az cdn endpoint purge \
  --resource-group photoshare-rg \
  --profile-name photoshare-cdn \
  --name photoshare-photos \
  --content-paths "/*"
```

---

## Moving Forward

- **Monitor costs**: https://portal.azure.com (Costs + Billing)
- **Set budget alerts**: Prevent unexpected charges
- **Consider reserved instances**: Save 30-40% on long-term commitments
- **Backup data**: Azure has automatic backups

**Total deployment time**: ~30-45 minutes with these scripts
