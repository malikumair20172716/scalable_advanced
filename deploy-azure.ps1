# PhotoShare Azure Deployment Script (PowerShell)
# Automates free tier Azure deployment
# Usage: .\deploy-azure.ps1

$ErrorActionPreference = "Stop"

Write-Host "🚀 PhotoShare - Azure Free Tier Deployment" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Configuration
$resourceGroup = "photoshare-rg"
$location = "eastus"
$registryName = "photoshareregistry"
$dbServer = "photoshare-db-server"
$dbName = "photoshare_db"
$dbUser = "dbadmin"
$storageName = "photoshareussa"
$appPlan = "photoshare-plan"
$backendApp = "photoshare-backend"
$frontendApp = "photoshare-frontend"
$vaultName = "photoshare-vault"

# Read configuration from user
$dbPassword = Read-Host "Enter your desired database password"
$jwtSecret = Read-Host "Enter your JWT secret key"
$subscriptionInput = Read-Host "Enter your Azure subscription ID (optional, press Enter to auto-detect)"

# Auto-detect subscription if not provided
if ([string]::IsNullOrWhiteSpace($subscriptionInput)) {
    $subscriptionId = $(az account show --query id -o tsv)
} else {
    $subscriptionId = $subscriptionInput
}

Write-Host "✓ Using Subscription: $subscriptionId" -ForegroundColor Green

# Function to show progress
function Show-Progress {
    param(
        [int]$step,
        [string]$message
    )
    Write-Host "`n[$($step)/10] $message" -ForegroundColor Yellow
}

# Step 1: Create Resource Group
Show-Progress 1 "Creating Resource Group..."
az group create `
  --name $resourceGroup `
  --location $location `
  --output table

Write-Host "✓ Resource Group created" -ForegroundColor Green

# Step 2: Create Container Registry
Show-Progress 2 "Creating Container Registry (Free)..."
az acr create `
  --resource-group $resourceGroup `
  --name $registryName `
  --sku Free `
  --output table

Write-Host "✓ Container Registry created" -ForegroundColor Green

# Get ACR credentials
$acrUsername = az acr credential show --name $registryName --query username -o tsv
$acrPassword = az acr credential show --name $registryName --query "passwords[0].value" -o tsv
$acrUrl = "$registryName.azurecr.io"

Write-Host "✓ ACR Credentials obtained" -ForegroundColor Green

# Step 3: Build and push Docker images
Show-Progress 3 "Building and pushing Docker images..."
Write-Host "Building backend..." -ForegroundColor Cyan
az acr build `
  --registry $registryName `
  --image photoshare-backend:1.0.0 `
  --file Dockerfile `
  ./backend

Write-Host "Building frontend..." -ForegroundColor Cyan
az acr build `
  --registry $registryName `
  --image photoshare-frontend:1.0.0 `
  --file Dockerfile `
  ./frontend

Write-Host "✓ Docker images built and pushed" -ForegroundColor Green

# Step 4: Create PostgreSQL Database
Show-Progress 4 "Creating PostgreSQL Database (Free 12 months)..."
az postgres server create `
  --resource-group $resourceGroup `
  --name $dbServer `
  --location $location `
  --admin-user $dbUser `
  --admin-password "$dbPassword" `
  --sku-name B_Gen5_1 `
  --storage-size 51200 `
  --backup-retention 7 `
  --geo-redundant-backup Disabled `
  --output table

az postgres db create `
  --resource-group $resourceGroup `
  --server-name $dbServer `
  --name $dbName

# Allow Azure services
az postgres server firewall-rule create `
  --resource-group $resourceGroup `
  --server-name $dbServer `
  --name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0

# Allow local machine (try to get current IP)
try {
    $currentIp = Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing | ForEach-Object { $_.Content }
    if ($currentIp -and $currentIp -ne "0.0.0.0") {
        az postgres server firewall-rule create `
          --resource-group $resourceGroup `
          --server-name $dbServer `
          --name AllowLocalAccess `
          --start-ip-address $currentIp `
          --end-ip-address $currentIp
        Write-Host "✓ Added firewall rule for your IP: $currentIp" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Could not determine your IP. You may need to add it manually." -ForegroundColor Yellow
}

Write-Host "✓ PostgreSQL Database created" -ForegroundColor Green

# Get DB FQDN
$dbFqdn = az postgres server show `
  --resource-group $resourceGroup `
  --name $dbServer `
  --query "fullyQualifiedDomainName" -o tsv

Write-Host "Database FQDN: $dbFqdn"

# Step 5: Initialize Database Schema
Show-Progress 5 "Initializing Database Schema..."
Write-Host "Note: Waiting for database to be accessible..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

$schemaPath = "backend/src/db/schema.sql"
if (Test-Path $schemaPath) {
    try {
        # Read schema file
        $schemaContent = Get-Content $schemaPath -Raw
        
        # Try to initialize (this might fail if psql is not installed)
        Write-Host "Attempting to initialize schema..." -ForegroundColor Cyan
        $env:PGPASSWORD = $dbPassword
        
        # Check if psql is available
        $psqlCheck = Get-Command psql -ErrorAction SilentlyContinue
        if ($psqlCheck) {
            psql -h "$dbFqdn" `
              -U "$dbUser@$dbServer" `
              -d "$dbName" `
              -f $schemaPath
            Write-Host "✓ Database schema initialized" -ForegroundColor Green
        } else {
            Write-Host "⚠ psql not installed. Use Azure Data Studio or other tool to initialize:" -ForegroundColor Yellow
            Write-Host "   psql -h $dbFqdn -U $dbUser@$dbServer -d $dbName -f $schemaPath" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠ Could not initialize schema automatically." -ForegroundColor Yellow
        Write-Host "   Run manually using Azure Data Studio or psql" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Schema file not found at $schemaPath" -ForegroundColor Yellow
}

# Step 6: Create Blob Storage
Show-Progress 6 "Creating Blob Storage (Free 5GB)..."
az storage account create `
  --resource-group $resourceGroup `
  --name $storageName `
  --location $location `
  --sku Standard_LRS `
  --access-tier Hot `
  --output table

# Create container
az storage container create `
  --account-name $storageName `
  --name photos `
  --public-access blob

# Get connection string
$storageConnection = az storage account show-connection-string `
  --resource-group $resourceGroup `
  --name $storageName `
  --query connectionString -o tsv

Write-Host "✓ Blob Storage created" -ForegroundColor Green

# Step 7: Create Key Vault
Show-Progress 7 "Creating Key Vault..."
az keyvault create `
  --resource-group $resourceGroup `
  --name $vaultName `
  --location $location `
  --output table

# Store secrets
az keyvault secret set `
  --vault-name $vaultName `
  --name db-password `
  --value "$dbPassword"

az keyvault secret set `
  --vault-name $vaultName `
  --name jwt-secret `
  --value "$jwtSecret"

az keyvault secret set `
  --vault-name $vaultName `
  --name storage-connection `
  --value "$storageConnection"

Write-Host "✓ Key Vault created with secrets" -ForegroundColor Green

# Step 8: Create App Service Plan
Show-Progress 8 "Creating App Service Plan (Free F1)..."
az appservice plan create `
  --name $appPlan `
  --resource-group $resourceGroup `
  --sku F1 `
  --is-linux `
  --output table

Write-Host "✓ App Service Plan created" -ForegroundColor Green

# Step 9: Deploy Backend
Show-Progress 9 "Deploying Backend App..."
az webapp create `
  --resource-group $resourceGroup `
  --plan $appPlan `
  --name $backendApp `
  --deployment-container-image-name-user "$acrUrl/photoshare-backend:1.0.0"

az webapp config container set `
  --name $backendApp `
  --resource-group $resourceGroup `
  --docker-custom-image-name "$acrUrl/photoshare-backend:1.0.0" `
  --docker-registry-server-url "https://$acrUrl" `
  --docker-registry-server-user "$acrUsername" `
  --docker-registry-server-password "$acrPassword"

# Set environment variables
az webapp config appsettings set `
  --resource-group $resourceGroup `
  --name $backendApp `
  --settings `
    DB_HOST="$dbFqdn" `
    DB_USER="$dbUser@$dbServer" `
    DB_PASSWORD="$dbPassword" `
    DB_NAME="$dbName" `
    JWT_SECRET="$jwtSecret" `
    STORAGE_CONNECTION_STRING="$storageConnection" `
    NODE_ENV="production" `
    PORT=8080

# Enable logging
az webapp log config `
  --resource-group $resourceGroup `
  --name $backendApp `
  --docker-container-logging filesystem

Write-Host "✓ Backend deployed" -ForegroundColor Green

# Step 10: Deploy Frontend
Show-Progress 10 "Deploying Frontend App..."
az webapp create `
  --resource-group $resourceGroup `
  --plan $appPlan `
  --name $frontendApp `
  --deployment-container-image-name-user "$acrUrl/photoshare-frontend:1.0.0"

az webapp config container set `
  --name $frontendApp `
  --resource-group $resourceGroup `
  --docker-custom-image-name "$acrUrl/photoshare-frontend:1.0.0" `
  --docker-registry-server-url "https://$acrUrl" `
  --docker-registry-server-user "$acrUsername" `
  --docker-registry-server-password "$acrPassword"

# Set environment for frontend
az webapp config appsettings set `
  --resource-group $resourceGroup `
  --name $frontendApp `
  --settings `
    REACT_APP_API_URL="https://$backendApp.azurewebsites.net/api"

Write-Host "✓ Frontend deployed" -ForegroundColor Green

# Summary
Write-Host "`n=================================================="
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

$backendUrl = "https://$backendApp.azurewebsites.net"
$frontendUrl = "https://$frontendApp.azurewebsites.net"

Write-Host "`n📍 Application URLs:" -ForegroundColor Green
Write-Host "   Backend:  $backendUrl"
Write-Host "   Frontend: $frontendUrl"
Write-Host "   Health:   $backendUrl/health"

Write-Host "`n📊 Database Info:" -ForegroundColor Green
Write-Host "   Server:   $dbFqdn"
Write-Host "   Database: $dbName"
Write-Host "   User:     $dbUser@$dbServer"

Write-Host "`n💾 Storage Info:" -ForegroundColor Green
Write-Host "   Account:  $storageName"
Write-Host "   Container: photos"

Write-Host "`n🔑 Secrets stored in:" -ForegroundColor Green
Write-Host "   Key Vault: $vaultName"

Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Wait 2-3 minutes for containers to start"
Write-Host "   2. Test backend: curl $backendUrl/health"
Write-Host "   3. Access frontend: $frontendUrl"
Write-Host "   4. Check logs: az webapp log tail -g $resourceGroup -n $backendApp"

Write-Host "`n💰 Cost Estimate:" -ForegroundColor Yellow
Write-Host "   Year 1: FREE (all services at free tier)"
Write-Host "   Year 2+: ~\$40-50/month"

Write-Host "`n⚠ Important Notes:" -ForegroundColor Yellow
Write-Host "   - PostgreSQL free tier expires after 12 months"
Write-Host "   - App Service F1 has CPU quota limits (60min/day)"
Write-Host "   - For production, upgrade to B1+ plan"
Write-Host "   - Monitor costs at: https://portal.azure.com"
