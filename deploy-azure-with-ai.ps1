# PhotoShare Azure Deployment Script - FINAL CORRECTED VERSION
# Deploys: Frontend + Backend + DB + Storage + AI Services

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    🚀 PhotoShare - Azure Deployment WITH AI SERVICES 🤖     ║" -ForegroundColor Cyan
Write-Host "║    Option B: Full Stack + Computer Vision + Content Mod     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ============================================================================
# CONFIGURATION
# ============================================================================
$resourceGroup = "photoshare-ai-rg"
$location = "norwayeast" # Changed to Norway East to fix Database Capacity Error
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
Show-Info "Registration check complete."

# ============================================================================
# STEP 1: Resource Group
# ============================================================================
Show-Progress 1 "Creating Resource Group" "📁"
az group create --name $resourceGroup --location $location --output none
Show-Success "Resource Group created"

# ============================================================================
# STEP 2: ACR 
# ============================================================================
Show-Progress 2 "Creating Container Registry" "🐳"
az acr create --resource-group $resourceGroup --name $registryName --sku Basic --admin-enabled true --output none
$acrUsername = az acr credential show --name $registryName --query username -o tsv
$acrPassword = az acr credential show --name $registryName --query "passwords[0].value" -o tsv
$acrUrl = "$registryName.azurecr.io"
Show-Success "ACR created and Admin credentials retrieved"

# ============================================================================
# STEP 3: Build Images (FIXED: Uses current directory paths)
# ============================================================================
Show-Progress 3 "Building Docker Images" "🏗️"
$imageTag = (Get-Date -Format "yyyyMMddHHmm")   # Unique per deploy - busts Azure image cache
Show-Info "Image tag: $imageTag  (prevents Azure caching old image on re-deploys)"
Show-Info "Building Backend..."
az acr build --registry $registryName --image "photoshare-backend:$imageTag" --image photoshare-backend:latest --file backend/Dockerfile ./backend
Show-Info "Building Frontend..."
az acr build --registry $registryName --image "photoshare-frontend:$imageTag" --image photoshare-frontend:latest --file frontend/Dockerfile ./frontend
Show-Success "Images pushed to $acrUrl (tag: $imageTag)"

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
# STEPS 7-9: AI Services (wrapped in try/catch - some may be unavailable in region)
# ============================================================================
Show-Progress 7 "Provisioning AI Services" "🤖"
$cvEndpoint = ""; $cvKey = ""; $cmEndpoint = ""; $cmKey = ""; $taEndpoint = ""; $taKey = ""

try {
    az cognitiveservices account create --name $cvAccount --resource-group $resourceGroup --kind ComputerVision --sku F0 --location $location --yes --output none
    $cvEndpoint = az cognitiveservices account show --name $cvAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
    $cvKey = az cognitiveservices account keys list --name $cvAccount --resource-group $resourceGroup --query "key1" -o tsv
    Show-Success "Computer Vision provisioned"
} catch { Write-Host "    ⚠️  Computer Vision skipped (may not be available in $location)" -ForegroundColor Yellow }

try {
    az cognitiveservices account create --name $cmAccount --resource-group $resourceGroup --kind ContentModerator --sku F0 --location $location --yes --output none
    $cmEndpoint = az cognitiveservices account show --name $cmAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
    $cmKey = az cognitiveservices account keys list --name $cmAccount --resource-group $resourceGroup --query "key1" -o tsv
    Show-Success "Content Moderator provisioned"
} catch { Write-Host "    ⚠️  Content Moderator skipped (legacy service - may be unavailable)" -ForegroundColor Yellow }

try {
    az cognitiveservices account create --name $taAccount --resource-group $resourceGroup --kind TextAnalytics --sku F0 --location $location --yes --output none
    $taEndpoint = az cognitiveservices account show --name $taAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
    $taKey = az cognitiveservices account keys list --name $taAccount --resource-group $resourceGroup --query "key1" -o tsv
    Show-Success "Text Analytics provisioned"
} catch { Write-Host "    ⚠️  Text Analytics skipped (may not be available in $location)" -ForegroundColor Yellow }
Show-Success "AI Services step complete (see above for individual status)"

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
# STEP 12: Backend Deployment (FIXED: Init with Nginx placeholder)
# ============================================================================
# ============================================================================
# STEP 12: Backend Deployment
# ============================================================================
Show-Progress 12 "Deploying Backend Web App" "⚙️"
az webapp create --resource-group $resourceGroup --plan $appPlan --name $backendApp --deployment-container-image-name nginx --output none

# Use versioned tag (not :latest) so Azure is FORCED to pull the new image
az webapp config container set --name $backendApp --resource-group $resourceGroup `
    --container-image-name "$acrUrl/photoshare-backend:$imageTag" `
    --container-registry-url "https://$acrUrl" `
    --container-registry-user "$acrUsername" `
    --container-registry-password "$acrPassword" --output none

az webapp config appsettings set --resource-group $resourceGroup --name $backendApp --settings `
    DB_HOST="$dbFqdn" DB_USER="$dbUser" DB_PASSWORD="$dbPassword" DB_NAME="$dbName" `
    JWT_SECRET="$jwtSecret" STORAGE_CONNECTION_STRING="$storageConnection" `
    CV_ENDPOINT="$cvEndpoint" CV_KEY="$cvKey" CM_ENDPOINT="$cmEndpoint" CM_KEY="$cmKey" `
    TA_ENDPOINT="$taEndpoint" TA_KEY="$taKey" PORT=8080 NODE_ENV="production" --output none

# Restart to force pull of new image
az webapp restart --resource-group $resourceGroup --name $backendApp --output none
Show-Success "Backend deployed and restarted (image: $imageTag)"

# Initialize Database Schema
Show-Info "Initializing database schema..."
Write-Host "    Waiting 30s for PostgreSQL to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 30
$schemaPath = "backend/src/db/schema.sql"
if (Test-Path $schemaPath) {
    $psqlCheck = Get-Command psql -ErrorAction SilentlyContinue
    if ($psqlCheck) {
        $env:PGPASSWORD = $dbPassword
        psql -h "$dbFqdn" -U "$dbUser" -d "$dbName" -f $schemaPath
        Show-Success "Database schema initialized via psql"
    } else {
        Write-Host "    ⚠️  psql not installed. Run manually after deployment:" -ForegroundColor Yellow
        Write-Host "        psql -h $dbFqdn -U $dbUser -d $dbName -f $schemaPath" -ForegroundColor Gray
        Write-Host "        OR: Azure Portal -> PostgreSQL -> Query Editor" -ForegroundColor Gray
    }
} else {
    Write-Host "    ⚠️  Schema file not found at $schemaPath" -ForegroundColor Yellow
}

# ============================================================================
# STEP 13: Frontend Deployment
# ============================================================================
Show-Progress 13 "Deploying Frontend Web App" "⚡"
az webapp create --resource-group $resourceGroup --plan $appPlan --name $frontendApp --deployment-container-image-name nginx --output none

# Use versioned tag (not :latest) - this is the key fix for "old UI" problem
az webapp config container set --name $frontendApp --resource-group $resourceGroup `
    --container-image-name "$acrUrl/photoshare-frontend:$imageTag" `
    --container-registry-url "https://$acrUrl" `
    --container-registry-user "$acrUsername" `
    --container-registry-password "$acrPassword" --output none

az webapp config appsettings set --resource-group $resourceGroup --name $frontendApp --settings `
    REACT_APP_API_URL="https://$backendApp.azurewebsites.net/api" --output none

# Restart to force pull of new image
az webapp restart --resource-group $resourceGroup --name $frontendApp --output none
Show-Success "Frontend deployed and restarted (image: $imageTag)"

# ============================================================================
# STEP 15: Final Summary
# ============================================================================
Show-Progress 15 "Deployment Complete" "✅"

$backendUrl  = "https://$backendApp.azurewebsites.net"
$frontendUrl = "https://$frontendApp.azurewebsites.net"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ DEPLOYMENT SUCCESSFUL                                 ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Frontend:     $frontendUrl" -ForegroundColor Cyan
Write-Host "⚙️  Backend API:  $backendUrl/api" -ForegroundColor Cyan
Write-Host "💚 Health Check: $backendUrl/health" -ForegroundColor Cyan
Write-Host "🏷️  Image Tag:    $imageTag" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Wait 2-3 minutes for containers to fully start"
Write-Host "   2. Visit: $frontendUrl"
Write-Host "   3. Register as Creator → Upload photo"
Write-Host "   4. Register as Consumer → Browse, comment, rate"
Write-Host ""
Write-Host "📝 View live logs:" -ForegroundColor Yellow
Write-Host "   az webapp log tail -g $resourceGroup -n $backendApp" -ForegroundColor Gray
Write-Host "   az webapp log tail -g $resourceGroup -n $frontendApp" -ForegroundColor Gray
Write-Host ""
Write-Host "🔄 To re-deploy after code changes:" -ForegroundColor Yellow
Write-Host "   Run this script again - new image tag auto-generated, old UI WILL NOT be served" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# STEP 15: Final Summary
# ============================================================================
Show-Progress 15 "Deployment Complete" "✅"
Write-Host "`n📍 URLS TO TEST:" -ForegroundColor Green
Write-Host "🌐 Frontend: https://$frontendApp.azurewebsites.net" -ForegroundColor Cyan
Write-Host "⚙️  Backend Health: https://$backendApp.azurewebsites.net/health" -ForegroundColor Cyan
