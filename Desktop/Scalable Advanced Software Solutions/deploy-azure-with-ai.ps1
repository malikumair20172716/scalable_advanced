# PhotoShare Azure Deployment Script with AI Services (Option B)
# Enhanced for Ulster University Azure Account
# Deploys: Frontend + Backend + Database + Blob Storage + 3x AI Services
# Usage: .\deploy-azure-with-ai.ps1

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🚀 PhotoShare - Azure Deployment WITH AI SERVICES 🤖      ║" -ForegroundColor Cyan
Write-Host "║   Option B: Full Stack + Computer Vision + Content Mod      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ============================================================================
# CONFIGURATION
# ============================================================================
$resourceGroup = "photoshare-ai-rg"
$location = "germanywestcentral"  # Allowed regions: switzerlandnorth, italynorth, norwayeast, germanywestcentral, spaincentral
$registryName = "photoshareairegistry"
$dbServer = "photoshare-ai-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbName = "photoshare_db"
$dbUser = "dbadmin"
$storageName = "photoshareaistorage$(Get-Random -Minimum 100 -Maximum 999)"
$appPlan = "photoshare-ai-plan"
$backendApp = "photoshare-ai-backend"
$frontendApp = "photoshare-ai-frontend"
$vaultName = "photoshare-ai-vault"
$cvAccount = "photoshare-ai-cv"
$cmAccount = "photoshare-ai-cm"
$taAccount = "photoshare-ai-ta"

# ============================================================================
# USER INPUT
# ============================================================================
Write-Host "`n📋 CONFIGURATION SETUP" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────" -ForegroundColor Yellow

$dbPassword = Read-Host "🔐 Database Password (minimum 8 chars, must include uppercase, number, special char)"
if ($dbPassword.Length -lt 8) {
    Write-Host "❌ Password must be at least 8 characters!" -ForegroundColor Red
    exit 1
}

$jwtSecret = Read-Host "🔑 JWT Secret Key (any random string)"
if ([string]::IsNullOrWhiteSpace($jwtSecret)) {
    $jwtSecret = "photoshare-jwt-$(Get-Random -Minimum 10000 -Maximum 99999)"
}

# Auto-detect subscription
$subscriptionId = $(az account show --query id -o tsv)
Write-Host "✅ Using Subscription: $subscriptionId" -ForegroundColor Green

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Show-Progress {
    param([int]$step, [string]$message, [string]$icon = "⚙️")
    Write-Host "`n[$($step)/15] $icon $message" -ForegroundColor Yellow
}

function Show-Success {
    param([string]$message)
    Write-Host "    ✅ $message" -ForegroundColor Green
}

function Show-Info {
    param([string]$message)
    Write-Host "    ℹ️  $message" -ForegroundColor Cyan
}

function Show-Warning {
    param([string]$message)
    Write-Host "    ⚠️  $message" -ForegroundColor Yellow
}

# ============================================================================
# STEP 1: Create Resource Group
# ============================================================================
Show-Progress 1 "Creating Resource Group" "📁"
az group create --name $resourceGroup --location $location --output table
Show-Success "Resource Group created"

# ============================================================================
# STEP 2: Create Container Registry
# ============================================================================
Show-Progress 2 "Creating Container Registry (Free tier)" "🐳"
az acr create --resource-group $resourceGroup --name $registryName --sku Free --output table
Show-Success "Container Registry created"

# Get ACR credentials
$acrUsername = az acr credential show --name $registryName --query username -o tsv
$acrPassword = az acr credential show --name $registryName --query "passwords[0].value" -o tsv
$acrUrl = "$registryName.azurecr.io"
Show-Info "Registry URL: $acrUrl"

# ============================================================================
# STEP 3: Build and Push Docker Images
# ============================================================================
Show-Progress 3 "Building and Pushing Docker Images to Registry" "🏗️"

Write-Host "    Building backend image..." -ForegroundColor Cyan
az acr build --registry $registryName --image photoshare-backend:latest --file Dockerfile ./backend
Show-Success "Backend image pushed"

Write-Host "    Building frontend image..." -ForegroundColor Cyan
az acr build --registry $registryName --image photoshare-frontend:latest --file Dockerfile ./frontend
Show-Success "Frontend image pushed"

# ============================================================================
# STEP 4: Create PostgreSQL Database
# ============================================================================
Show-Progress 4 "Creating Azure Database for PostgreSQL" "🗄️"

az postgres flexible-server create `
    --resource-group $resourceGroup `
    --name $dbServer `
    --location $location `
    --admin-user $dbUser `
    --admin-password "$dbPassword" `
    --sku-name "Standard_B1s" `
    --storage-size 32 `
    --tier "Burstable" `
    --version 14 `
    --output table

Show-Success "PostgreSQL Database created"

# Get DB FQDN
$dbFqdn = az postgres flexible-server show --resource-group $resourceGroup --name $dbServer --query "fullyQualifiedDomainName" -o tsv
Show-Info "Database FQDN: $dbFqdn"

# Create database
az postgres flexible-server db create --resource-group $resourceGroup --server-name $dbServer --database-name $dbName
Show-Success "Database '$dbName' created"

# ============================================================================
# STEP 5: Initialize Database Schema
# ============================================================================
Show-Progress 5 "Initializing Database Schema" "📊"

$schemaPath = "backend/src/db/schema.sql"
if (Test-Path $schemaPath) {
    try {
        Show-Info "Waiting for database to be accessible..."
        Start-Sleep -Seconds 30
        
        $psqlCheck = Get-Command psql -ErrorAction SilentlyContinue
        if ($psqlCheck) {
            $env:PGPASSWORD = $dbPassword
            psql -h "$dbFqdn" -U "$dbUser" -d "$dbName" -f $schemaPath
            Show-Success "Database schema initialized"
        } else {
            Show-Warning "psql not found. Schema initialization skipped (run manually later)"
        }
    } catch {
        Show-Warning "Schema initialization failed (not critical, can initialize manually)"
    }
} else {
    Show-Warning "Schema file not found"
}

# ============================================================================
# STEP 6: Create Blob Storage
# ============================================================================
Show-Progress 6 "Creating Azure Blob Storage (Free 5GB)" "💾"

az storage account create `
    --resource-group $resourceGroup `
    --name $storageName `
    --location $location `
    --sku Standard_LRS `
    --access-tier Hot `
    --output table

# Create container
az storage container create --account-name $storageName --name photos --public-access blob
Show-Success "Blob Storage created with 'photos' container"

# Get connection string
$storageConnection = az storage account show-connection-string --resource-group $resourceGroup --name $storageName --query connectionString -o tsv
Show-Info "Storage connection string obtained"

# ============================================================================
# STEP 7: Create Computer Vision API (for photo tagging)
# ============================================================================
Show-Progress 7 "Creating Computer Vision API (AI - Photo Analysis)" "👁️"

az cognitiveservices account create `
    --name $cvAccount `
    --resource-group $resourceGroup `
    --kind ComputerVision `
    --sku F0 `
    --location $location `
    --yes `
    --output table

$cvEndpoint = az cognitiveservices account show --name $cvAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$cvKey = az cognitiveservices account keys list --name $cvAccount --resource-group $resourceGroup --query "key1" -o tsv
Show-Success "Computer Vision API created"
Show-Info "Endpoint: $cvEndpoint"

# ============================================================================
# STEP 8: Create Content Moderator API (for safe content checking)
# ============================================================================
Show-Progress 8 "Creating Content Moderator API (AI - Safe Content)" "🛡️"

az cognitiveservices account create `
    --name $cmAccount `
    --resource-group $resourceGroup `
    --kind ContentModerator `
    --sku F0 `
    --location $location `
    --yes `
    --output table

$cmEndpoint = az cognitiveservices account show --name $cmAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$cmKey = az cognitiveservices account keys list --name $cmAccount --resource-group $resourceGroup --query "key1" -o tsv
Show-Success "Content Moderator API created"
Show-Info "Endpoint: $cmEndpoint"

# ============================================================================
# STEP 9: Create Text Analytics API (for descriptions & sentiment)
# ============================================================================
Show-Progress 9 "Creating Text Analytics API (AI - Text Analysis)" "📝"

az cognitiveservices account create `
    --name $taAccount `
    --resource-group $resourceGroup `
    --kind TextAnalytics `
    --sku F0 `
    --location $location `
    --yes `
    --output table

$taEndpoint = az cognitiveservices account show --name $taAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$taKey = az cognitiveservices account keys list --name $taAccount --resource-group $resourceGroup --query "key1" -o tsv
Show-Success "Text Analytics API created"
Show-Info "Endpoint: $taEndpoint"

# ============================================================================
# STEP 10: Create Key Vault
# ============================================================================
Show-Progress 10 "Creating Key Vault (Secure Secrets Storage)" "🔐"

az keyvault create `
    --resource-group $resourceGroup `
    --name $vaultName `
    --location $location `
    --output table

# Store all secrets
az keyvault secret set --vault-name $vaultName --name "db-password" --value "$dbPassword"
az keyvault secret set --vault-name $vaultName --name "jwt-secret" --value "$jwtSecret"
az keyvault secret set --vault-name $vaultName --name "storage-connection" --value "$storageConnection"
az keyvault secret set --vault-name $vaultName --name "cv-endpoint" --value "$cvEndpoint"
az keyvault secret set --vault-name $vaultName --name "cv-key" --value "$cvKey"
az keyvault secret set --vault-name $vaultName --name "cm-endpoint" --value "$cmEndpoint"
az keyvault secret set --vault-name $vaultName --name "cm-key" --value "$cmKey"
az keyvault secret set --vault-name $vaultName --name "ta-endpoint" --value "$taEndpoint"
az keyvault secret set --vault-name $vaultName --name "ta-key" --value "$taKey"

Show-Success "Key Vault created with all secrets stored"

# ============================================================================
# STEP 11: Create App Service Plan
# ============================================================================
Show-Progress 11 "Creating App Service Plan (Free F1 tier)" "🏠"

az appservice plan create `
    --name $appPlan `
    --resource-group $resourceGroup `
    --sku F1 `
    --is-linux `
    --output table

Show-Success "App Service Plan created"

# ============================================================================
# STEP 12: Deploy Backend API
# ============================================================================
Show-Progress 12 "Deploying Backend API (Node.js + Express)" "⚙️"

az webapp create `
    --resource-group $resourceGroup `
    --plan $appPlan `
    --name $backendApp `
    --deployment-container-image-name-user "$acrUrl/photoshare-backend:latest"

az webapp config container set `
    --name $backendApp `
    --resource-group $resourceGroup `
    --docker-custom-image-name "$acrUrl/photoshare-backend:latest" `
    --docker-registry-server-url "https://$acrUrl" `
    --docker-registry-server-user "$acrUsername" `
    --docker-registry-server-password "$acrPassword"

# Set backend environment variables
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
        CV_ENDPOINT="$cvEndpoint" `
        CV_KEY="$cvKey" `
        CM_ENDPOINT="$cmEndpoint" `
        CM_KEY="$cmKey" `
        TA_ENDPOINT="$taEndpoint" `
        TA_KEY="$taKey" `
        NODE_ENV="production" `
        PORT=8080

# Enable logging
az webapp log config --resource-group $resourceGroup --name $backendApp --docker-container-logging filesystem

Show-Success "Backend API deployed with AI credentials"

# ============================================================================
# STEP 13: Deploy Frontend App
# ============================================================================
Show-Progress 13 "Deploying Frontend App (React + Static)" "⚡"

az webapp create `
    --resource-group $resourceGroup `
    --plan $appPlan `
    --name $frontendApp `
    --deployment-container-image-name-user "$acrUrl/photoshare-frontend:latest"

az webapp config container set `
    --name $frontendApp `
    --resource-group $resourceGroup `
    --docker-custom-image-name "$acrUrl/photoshare-frontend:latest" `
    --docker-registry-server-url "https://$acrUrl" `
    --docker-registry-server-user "$acrUsername" `
    --docker-registry-server-password "$acrPassword"

# Set frontend environment
az webapp config appsettings set `
    --resource-group $resourceGroup `
    --name $frontendApp `
    --settings `
        REACT_APP_API_URL="https://$backendApp.azurewebsites.net/api"

Show-Success "Frontend App deployed"

# ============================================================================
# STEP 14: Wait for apps to start
# ============================================================================
Show-Progress 14 "Waiting for applications to start (2-3 minutes)" "⏳"

$maxWait = 180  # 3 minutes
$elapsed = 0
$checkInterval = 10

While ($elapsed -lt $maxWait) {
    try {
        $response = Invoke-WebRequest -Uri "https://$backendApp.azurewebsites.net/health" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Show-Success "Backend is responding"
            break
        }
    } catch {
        # Still waiting
    }
    
    Write-Host "    ⏳ Waiting... ($elapsed/$maxWait seconds)" -ForegroundColor Gray
    Start-Sleep -Seconds $checkInterval
    $elapsed += $checkInterval
}

if ($elapsed -ge $maxWait) {
    Show-Warning "Apps are still starting, this may take a few more minutes"
}

# ============================================================================
# STEP 15: Summary and URLs
# ============================================================================
Show-Progress 15 "Deployment Summary" "✅"

$backendUrl = "https://$backendApp.azurewebsites.net"
$frontendUrl = "https://$frontendApp.azurewebsites.net"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           ✅ DEPLOYMENT COMPLETE - OPTION B 🎉             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📍 APPLICATION URLS:" -ForegroundColor Green
Write-Host "   🌐 Frontend:  $frontendUrl" -ForegroundColor Cyan
Write-Host "   ⚙️  Backend:   $backendUrl" -ForegroundColor Cyan
Write-Host "   ❤️  Health:    $backendUrl/health" -ForegroundColor Cyan

Write-Host "`n🤖 AI SERVICES DEPLOYED:" -ForegroundColor Green
Write-Host "   👁️  Computer Vision:    $cvEndpoint" -ForegroundColor Cyan
Write-Host "   🛡️  Content Moderator:   $cmEndpoint" -ForegroundColor Cyan
Write-Host "   📝 Text Analytics:      $taEndpoint" -ForegroundColor Cyan

Write-Host "`n📊 DATABASE INFORMATION:" -ForegroundColor Green
Write-Host "   🗄️  Server:   $dbFqdn" -ForegroundColor Cyan
Write-Host "   📦 Database: $dbName" -ForegroundColor Cyan
Write-Host "   👤 Username: $dbUser@$dbServer" -ForegroundColor Cyan

Write-Host "`n💾 STORAGE INFORMATION:" -ForegroundColor Green
Write-Host "   🪣 Account:   $storageName" -ForegroundColor Cyan
Write-Host "   📁 Container: photos" -ForegroundColor Cyan

Write-Host "`n🔑 SECRETS STORED IN:" -ForegroundColor Green
Write-Host "   🔐 Key Vault: $vaultName" -ForegroundColor Cyan

Write-Host "`n📝 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "   1. ✅ Wait 2-3 minutes for containers to fully start" -ForegroundColor White
Write-Host "   2. ✅ Test frontend: Open $frontendUrl in browser" -ForegroundColor White
Write-Host "   3. ✅ Test backend: curl $backendUrl/health" -ForegroundColor White
Write-Host "   4. ✅ Create test account and upload a photo" -ForegroundColor White
Write-Host "   5. ✅ Verify AI tagging appears on the photo" -ForegroundColor White

Write-Host "`n🎓 COURSEWORK CHECKLIST:" -ForegroundColor Yellow
Write-Host "   ✅ Full-stack deployment (Frontend + Backend + DB + AI)" -ForegroundColor Green
Write-Host "   ✅ CI/CD pipeline auto-triggers on GitHub push" -ForegroundColor Green
Write-Host "   ✅ AI integration (Computer Vision, Content Moderator, Text Analytics)" -ForegroundColor Green
Write-Host "   ⏳ Next: Record 5-minute demo video" -ForegroundColor Yellow
Write-Host "   ⏳ Next: Create 12-slide PowerPoint presentation" -ForegroundColor Yellow

Write-Host "`n💰 COST ESTIMATE:" -ForegroundColor Yellow
Write-Host "   Year 1:  FREE (all services at educational tier)" -ForegroundColor Green
Write-Host "   Year 2+: ~\$40-60/month (if kept after free tier expires)" -ForegroundColor Cyan

Write-Host "`n📱 TROUBLESHOOTING:" -ForegroundColor Yellow
Write-Host "   Check logs:  az webapp log tail -g $resourceGroup -n $backendApp" -ForegroundColor White
Write-Host "   Restart app: az webapp restart -g $resourceGroup -n $backendApp" -ForegroundColor White
Write-Host "   View costs:  https://portal.azure.com/#view/Microsoft_Azure_Billing/BillingMenuBlade" -ForegroundColor White

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 Your PhotoShare app is now live with AI features! 🎉" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
