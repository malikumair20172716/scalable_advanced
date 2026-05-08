# PhotoShare Azure Deployment Script with AI Services (Option B)
# Fixed for Azure CLI v15.5+ and Ulster University Account
# Usage: .\deploy-azure-with-ai.ps1

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🚀 PhotoShare - Azure Deployment WITH AI SERVICES 🤖     ║" -ForegroundColor Cyan
Write-Host "║   Option B: Full Stack + Computer Vision + Content Mod     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ============================================================================
# CONFIGURATION
# ============================================================================
$resourceGroup = "photoshare-ai-rg"
$location = "germanywestcentral"
$registryName = "photoshareairegistry$(Get-Random -Minimum 100 -Maximum 999)" # Added randomizer to avoid global name conflicts
$dbServer = "photoshare-ai-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbName = "photoshare_db"
$dbUser = "dbadmin"
$storageName = "photoshareaistorage$(Get-Random -Minimum 100 -Maximum 999)"
$appPlan = "photoshare-ai-plan"
$backendApp = "photoshare-ai-backend"
$frontendApp = "photoshare-ai-frontend"
$vaultName = "photoshare-vault-$(Get-Random -Minimum 100 -Maximum 999)"
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

$subscriptionId = $(az account show --query id -o tsv)
$userUpn = $(az account show --query user.name -o tsv)
Write-Host "✅ Using Subscription: $subscriptionId" -ForegroundColor Green
Write-Host "✅ Authenticated as: $userUpn" -ForegroundColor Green

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Show-Progress {
    param([int]$step, [string]$message, [string]$icon = "⚙️")
    Write-Host "`n[$($step)/16] $icon $message" -ForegroundColor Yellow
}
function Show-Success { param([string]$message) Write-Host "    ✅ $message" -ForegroundColor Green }
function Show-Info { param([string]$message) Write-Host "    ℹ️  $message" -ForegroundColor Cyan }
function Show-Warning { param([string]$message) Write-Host "    ⚠️  $message" -ForegroundColor Yellow }

# ============================================================================
# STEP 0: Register Cognitive Services (FIXED)
# ============================================================================
Show-Progress 0 "Registering Cognitive Services Provider" "🔌"
az provider register --namespace Microsoft.CognitiveServices
Show-Info "Registration initiated (runs in background)..."

# ============================================================================
# STEP 1: Create Resource Group
# ============================================================================
Show-Progress 1 "Creating Resource Group" "📁"
az group create --name $resourceGroup --location $location --output table
Show-Success "Resource Group created"

# ============================================================================
# STEP 2: Create Container Registry (FIXED: Basic SKU)
# ============================================================================
Show-Progress 2 "Creating Container Registry" "🐳"
az acr create --resource-group $resourceGroup --name $registryName --sku Basic --output table
Show-Success "Container Registry created"

$acrUsername = az acr credential show --name $registryName --query username -o tsv
$acrPassword = az acr credential show --name $registryName --query "passwords[0].value" -o tsv
$acrUrl = "$registryName.azurecr.io"
Show-Info "Registry URL: $acrUrl"

# ============================================================================
# STEP 3: Build and Push Docker Images
# ============================================================================
Show-Progress 3 "Building and Pushing Docker Images" "🏗️"
Write-Host "    Building backend image..." -ForegroundColor Cyan
az acr build --registry $registryName --image photoshare-backend:latest --file Dockerfile ./backend
Show-Success "Backend image pushed"

Write-Host "    Building frontend image..." -ForegroundColor Cyan
az acr build --registry $registryName --image photoshare-frontend:latest --file Dockerfile ./frontend
Show-Success "Frontend image pushed"

# ============================================================================
# STEP 4: Create PostgreSQL Database & Firewall
# ============================================================================
Show-Progress 4 "Creating Azure Database for PostgreSQL" "🗄️"
az postgres flexible-server create `
    --resource-group $resourceGroup `
    --name $dbServer `
    --location $location `
    --admin-user $dbUser `
    --admin-password "$dbPassword" `
    --sku-name "Standard_B1s" `
    --tier "Burstable" `
    --version 14 `
    --output none

$dbFqdn = az postgres flexible-server show --resource-group $resourceGroup --name $dbServer --query "fullyQualifiedDomainName" -o tsv
Show-Info "Database FQDN: $dbFqdn"

# FIX: Allow Cloud Shell to connect via DB Firewall
az postgres flexible-server firewall-rule create --resource-group $resourceGroup --name $dbServer --rule-name AllowAllAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --output none

az postgres flexible-server db create --resource-group $resourceGroup --server-name $dbServer --database-name $dbName --output none
Show-Success "Database '$dbName' created"

# ============================================================================
# STEP 5: Initialize Database Schema (FIXED)
# ============================================================================
Show-Progress 5 "Initializing Database Schema" "📊"
$schemaPath = "backend/src/db/schema.sql"
if (Test-Path $schemaPath) {
    try {
        Show-Info "Waiting for database firewall to update..."
        Start-Sleep -Seconds 15
        
        $env:PGPASSWORD = $dbPassword
        # Using correct host FQDN
        psql -h "$dbFqdn" -U "$dbUser" -d "$dbName" -f $schemaPath
        Show-Success "Database schema initialized"
    } catch {
        Show-Warning "Schema initialization failed. Check connection."
    }
} else {
    Show-Warning "Schema file not found at $schemaPath"
}

# ============================================================================
# STEP 6: Create Blob Storage
# ============================================================================
Show-Progress 6 "Creating Azure Blob Storage" "💾"
az storage account create --resource-group $resourceGroup --name $storageName --location $location --sku Standard_LRS --access-tier Hot --output none
az storage container create --account-name $storageName --name photos --public-access blob --output none
$storageConnection = az storage account show-connection-string --resource-group $resourceGroup --name $storageName --query connectionString -o tsv
Show-Success "Blob Storage created"

# ============================================================================
# STEPS 7, 8, 9: AI Services
# ============================================================================
Show-Progress 7 "Creating Computer Vision API" "👁️"
az cognitiveservices account create --name $cvAccount --resource-group $resourceGroup --kind ComputerVision --sku F0 --location $location --yes --output none
$cvEndpoint = az cognitiveservices account show --name $cvAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$cvKey = az cognitiveservices account keys list --name $cvAccount --resource-group $resourceGroup --query "key1" -o tsv

Show-Progress 8 "Creating Content Moderator API" "🛡️"
az cognitiveservices account create --name $cmAccount --resource-group $resourceGroup --kind ContentModerator --sku F0 --location $location --yes --output none
$cmEndpoint = az cognitiveservices account show --name $cmAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$cmKey = az cognitiveservices account keys list --name $cmAccount --resource-group $resourceGroup --query "key1" -o tsv

Show-Progress 9 "Creating Text Analytics API" "📝"
az cognitiveservices account create --name $taAccount --resource-group $resourceGroup --kind TextAnalytics --sku F0 --location $location --yes --output none
$taEndpoint = az cognitiveservices account show --name $taAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$taKey = az cognitiveservices account keys list --name $taAccount --resource-group $resourceGroup --query "key1" -o tsv
Show-Success "AI APIs Provisioned"

# ============================================================================
# STEP 10: Create Key Vault (FIXED: RBAC Permissions)
# ============================================================================
Show-Progress 10 "Creating Key Vault (Secure Secrets Storage)" "🔐"
az keyvault create --resource-group $resourceGroup --name $vaultName --location $location --output none

Show-Info "Assigning Secrets Officer role to $userUpn..."
az role assignment create --role "Key Vault Secrets Officer" --assignee $userUpn --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$vaultName" --output none
Show-Info "Waiting 30 seconds for permissions to propagate..."
Start-Sleep -Seconds 30

az keyvault secret set --vault-name $vaultName --name "db-password" --value "$dbPassword" --output none
az keyvault secret set --vault-name $vaultName --name "jwt-secret" --value "$jwtSecret" --output none
az keyvault secret set --vault-name $vaultName --name "storage-connection" --value "$storageConnection" --output none
Show-Success "Key Vault secrets stored"

# ============================================================================
# STEP 11: Create App Service Plan
# ============================================================================
Show-Progress 11 "Creating App Service Plan" "🏠"
az appservice plan create --name $appPlan --resource-group $resourceGroup --sku F1 --is-linux --output none
Show-Success "App Service Plan created"

# ============================================================================
# STEP 12: Deploy Backend API (FIXED: Webapp syntax)
# ============================================================================
Show-Progress 12 "Deploying Backend API" "⚙️"
az webapp create --resource-group $resourceGroup --plan $appPlan --name $backendApp --output none

az webapp config container set `
    --name $backendApp `
    --resource-group $resourceGroup `
    --container-image-name "$acrUrl/photoshare-backend:latest" `
    --container-registry-url "https://$acrUrl" `
    --container-registry-user "$acrUsername" `
    --container-registry-password "$acrPassword" `
    --output none

az webapp config appsettings set `
    --resource-group $resourceGroup `
    --name $backendApp `
    --settings `
        DB_HOST="$dbFqdn" `
        DB_USER="$dbUser" `
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
        PORT=8080 `
    --output none

Show-Success "Backend API deployed"

# ============================================================================
# STEP 13: Deploy Frontend App (FIXED: Webapp syntax)
# ============================================================================
Show-Progress 13 "Deploying Frontend App" "⚡"
az webapp create --resource-group $resourceGroup --plan $appPlan --name $frontendApp --output none

az webapp config container set `
    --name $frontendApp `
    --resource-group $resourceGroup `
    --container-image-name "$acrUrl/photoshare-frontend:latest" `
    --container-registry-url "https://$acrUrl" `
    --container-registry-user "$acrUsername" `
    --container-registry-password "$acrPassword" `
    --output none

az webapp config appsettings set `
    --resource-group $resourceGroup `
    --name $frontendApp `
    --settings REACT_APP_API_URL="https://$backendApp.azurewebsites.net/api" `
    --output none

Show-Success "Frontend App deployed"

# ============================================================================
# STEP 14: Wait for apps to start
# ============================================================================
Show-Progress 14 "Waiting for applications to start (2-3 minutes)" "⏳"
$maxWait = 180
$elapsed = 0
$checkInterval = 10

While ($elapsed -lt $maxWait) {
    try {
        $response = Invoke-WebRequest -Uri "https://$backendApp.azurewebsites.net/health" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Show-Success "Backend is responding!"
            break
        }
    } catch { }
    Write-Host "    ⏳ Waiting... ($elapsed/$maxWait seconds)" -ForegroundColor Gray
    Start-Sleep -Seconds $checkInterval
    $elapsed += $checkInterval
}

# ============================================================================
# STEP 15: Summary and URLs
# ============================================================================
Show-Progress 15 "Deployment Summary" "✅"
$backendUrl = "https://$backendApp.azurewebsites.net"
$frontendUrl = "https://$frontendApp.azurewebsites.net"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║            ✅ DEPLOYMENT COMPLETE 🎉                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "`n🌐 Frontend:  $frontendUrl" -ForegroundColor Cyan
Write-Host "⚙️  Backend:   $backendUrl" -ForegroundColor Cyan
