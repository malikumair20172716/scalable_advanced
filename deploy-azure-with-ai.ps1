# PhotoShare Azure Deployment Script - FINAL CORRECTED VERSION
# Deploys: Frontend + Backend + DB + Storage + AI Services
# Current Year: 2026

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    🚀 PhotoShare - Azure Deployment WITH AI SERVICES 🤖     ║" -ForegroundColor Cyan
Write-Host "║    Option B: Full Stack + Computer Vision + Content Mod     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ============================================================================
# CONFIGURATION
# ============================================================================
$resourceGroup = "photoshare-ai-rg"
$location = "germanywestcentral"
$registryName = "photoshareairegistry$(Get-Random -Minimum 100 -Maximum 999)"
$dbServer = "photoshare-ai-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbName = "photoshare_db"
$dbUser = "dbadmin"
$storageName = "photoshareaistorage$(Get-Random -Minimum 100 -Maximum 999)"
$appPlan = "photoshare-ai-plan"
$backendApp = "photoshare-ai-backend-$(Get-Random -Minimum 100 -Maximum 999)"
$frontendApp = "photoshare-ai-frontend-$(Get-Random -Minimum 100 -Maximum 999)"
$vaultName = "photoshare-vault-$(Get-Random -Minimum 100 -Maximum 999)"
$cvAccount = "photoshare-ai-cv"
$cmAccount = "photoshare-ai-cm"
$taAccount = "photoshare-ai-ta"

# ============================================================================
# USER INPUT
# ============================================================================
Write-Host "`n📋 CONFIGURATION SETUP" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────" -ForegroundColor Yellow

$dbPassword = Read-Host "🔐 Database Password"
$jwtSecret = Read-Host "🔑 JWT Secret Key"
if ([string]::IsNullOrWhiteSpace($jwtSecret)) { $jwtSecret = "photoshare-jwt-$(Get-Random)" }

$subscriptionId = $(az account show --query id -o tsv)
$userUpn = $(az account show --query user.name -o tsv)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Show-Progress { param([int]$step, [string]$message, [string]$icon = "⚙️") Write-Host "`n[$($step)/15] $icon $message" -ForegroundColor Yellow }
function Show-Success { param([string]$message) Write-Host "    ✅ $message" -ForegroundColor Green }
function Show-Info { param([string]$message) Write-Host "    ℹ️  $message" -ForegroundColor Cyan }

# ============================================================================
# STEP 0: Register Providers
# ============================================================================
Show-Progress 0 "Registering AI Providers" "🔌"
az provider register --namespace Microsoft.CognitiveServices
Show-Info "Registration check complete."

# ============================================================================
# STEP 1: Resource Group
# ============================================================================
Show-Progress 1 "Creating Resource Group" "📁"
az group create --name $resourceGroup --location $location --output none
Show-Success "Resource Group created"

# ============================================================================
# STEP 2: ACR (FIXED: Admin Enabled)
# ============================================================================
Show-Progress 2 "Creating Container Registry" "🐳"
az acr create --resource-group $resourceGroup --name $registryName --sku Basic --admin-enabled true --output none
$acrUsername = az acr credential show --name $registryName --query username -o tsv
$acrPassword = az acr credential show --name $registryName --query "passwords[0].value" -o tsv
$acrUrl = "$registryName.azurecr.io"
Show-Success "ACR created and Admin credentials retrieved"

# ============================================================================
# STEP 3: Build Images (FIXED: Nested Paths)
# ============================================================================
Show-Progress 3 "Building Docker Images" "🏗️"
Show-Info "Building Backend..."
az acr build --registry $registryName --image photoshare-backend:latest --file scalable_advanced/backend/Dockerfile ./scalable_advanced/backend
Show-Info "Building Frontend..."
az acr build --registry $registryName --image photoshare-frontend:latest --file scalable_advanced/frontend/Dockerfile ./scalable_advanced/frontend
Show-Success "Images pushed to $acrUrl"

# ============================================================================
# STEP 4: PostgreSQL
# ============================================================================
Show-Progress 4 "Creating PostgreSQL" "🗄️"
az postgres flexible-server create --resource-group $resourceGroup --name $dbServer --location $location --admin-user $dbUser --admin-password "$dbPassword" --sku-name Standard_B1s --tier Burstable --version 14 --public-access 0.0.0.0 --output none
$dbFqdn = az postgres flexible-server show --resource-group $resourceGroup --name $dbServer --query "fullyQualifiedDomainName" -o tsv
az postgres flexible-server db create --resource-group $resourceGroup --server-name $dbServer --database-name $dbName --output none
Show-Success "Database server and '$dbName' ready"

# ============================================================================
# STEP 6: Storage
# ============================================================================
Show-Progress 6 "Creating Blob Storage" "💾"
az storage account create --resource-group $resourceGroup --name $storageName --location $location --sku Standard_LRS --output none
az storage container create --account-name $storageName --name photos --public-access blob --output none
$storageConnection = az storage account show-connection-string --resource-group $resourceGroup --name $storageName --query connectionString -o tsv
Show-Success "Storage container 'photos' created"

# ============================================================================
# STEPS 7-9: AI Services
# ============================================================================
Show-Progress 7 "Provisioning AI Services" "🤖"
az cognitiveservices account create --name $cvAccount --resource-group $resourceGroup --kind ComputerVision --sku F0 --location $location --yes --output none
$cvEndpoint = az cognitiveservices account show --name $cvAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$cvKey = az cognitiveservices account keys list --name $cvAccount --resource-group $resourceGroup --query "key1" -o tsv

az cognitiveservices account create --name $cmAccount --resource-group $resourceGroup --kind ContentModerator --sku F0 --location $location --yes --output none
$cmEndpoint = az cognitiveservices account show --name $cmAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$cmKey = az cognitiveservices account keys list --name $cmAccount --resource-group $resourceGroup --query "key1" -o tsv

az cognitiveservices account create --name $taAccount --resource-group $resourceGroup --kind TextAnalytics --sku F0 --location $location --yes --output none
$taEndpoint = az cognitiveservices account show --name $taAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
$taKey = az cognitiveservices account keys list --name $taAccount --resource-group $resourceGroup --query "key1" -o tsv
Show-Success "Computer Vision, Content Moderator, and Text Analytics online"

# ============================================================================
# STEP 10: Key Vault
# ============================================================================
Show-Progress 10 "Securing Secrets in Key Vault" "🔐"
az keyvault create --resource-group $resourceGroup --name $vaultName --location $location --output none
az role assignment create --role "Key Vault Secrets Officer" --assignee $userUpn --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$vaultName" --output none
Write-Host "    Waiting for RBAC sync..." -ForegroundColor Gray
Start-Sleep -Seconds 20
az keyvault secret set --vault-name $vaultName --name "db-password" --value "$dbPassword" --output none
az keyvault secret set --vault-name $vaultName --name "storage-connection" --value "$storageConnection" --output none
Show-Success "Secrets safely stored"

# ============================================================================
# STEP 11: App Service Plan
# ============================================================================
Show-Progress 11 "Creating Hosting Plan" "🏠"
az appservice plan create --name $appPlan --resource-group $resourceGroup --sku F1 --is-linux --output none
Show-Success "App Plan created"

# ============================================================================
# STEP 12: Backend Deployment (FIXED: 2-Step Process)
# ============================================================================
Show-Progress 12 "Deploying Backend Web App" "⚙️"
az webapp create --resource-group $resourceGroup --plan $appPlan --name $backendApp --runtime "NODE:18-lts" --output none
az webapp config container set --name $backendApp --resource-group $resourceGroup --container-image-name "$acrUrl/photoshare-backend:latest" --container-registry-url "https://$acrUrl" --container-registry-user "$acrUsername" --container-registry-password "$acrPassword" --output none

az webapp config appsettings set --resource-group $resourceGroup --name $backendApp --settings `
    DB_HOST="$dbFqdn" DB_USER="$dbUser" DB_PASSWORD="$dbPassword" DB_NAME="$dbName" `
    JWT_SECRET="$jwtSecret" STORAGE_CONNECTION_STRING="$storageConnection" `
    CV_ENDPOINT="$cvEndpoint" CV_KEY="$cvKey" CM_ENDPOINT="$cmEndpoint" CM_KEY="$cmKey" `
    TA_ENDPOINT="$taEndpoint" TA_KEY="$taKey" PORT=8080 --output none
Show-Success "Backend online"

# ============================================================================
# STEP 13: Frontend Deployment (FIXED: 2-Step Process)
# ============================================================================
Show-Progress 13 "Deploying Frontend Web App" "⚡"
az webapp create --resource-group $resourceGroup --plan $appPlan --name $frontendApp --runtime "NODE:18-lts" --output none
az webapp config container set --name $frontendApp --resource-group $resourceGroup --container-image-name "$acrUrl/photoshare-frontend:latest" --container-registry-url "https://$acrUrl" --container-registry-user "$acrUsername" --container-registry-password "$acrPassword" --output none

az webapp config appsettings set --resource-group $resourceGroup --name $frontendApp --settings `
    REACT_APP_API_URL="https://$backendApp.azurewebsites.net" --output none
Show-Success "Frontend online"

# ============================================================================
# STEP 15: Final Summary
# ============================================================================
Show-Progress 15 "Deployment Complete" "✅"
Write-Host "`n📍 URLS TO TEST:" -ForegroundColor Green
Write-Host "🌐 Frontend: https://$frontendApp.azurewebsites.net" -ForegroundColor Cyan
Write-Host "⚙️  Backend Health: https://$backendApp.azurewebsites.net/health" -ForegroundColor Cyan
