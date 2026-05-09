# PhotoShare Azure Deployment Script - CLOUD SHELL COMPATIBLE
# Deploys: Infrastructure (Safe Mode) + Pre-configures for CI/CD

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION (Using your random naming strategy for safety)
# ============================================================================
$rand = Get-Random -Minimum 10000 -Maximum 99999
$resourceGroup = "photoshare-ai-rg-$rand"
$location = "norwayeast"
$registryName = "photoshareacr$rand"
$dbServer = "photosharedb-$rand"
$dbName = "photoshare_db"
$dbUser = "dbadmin"
$storageName = "photosharest$rand"
$appPlan = "photoshareplan$rand"
$backendApp = "photoshare-be-$rand"
$frontendApp = "photoshare-fe-$rand"
$vaultName = "photosharesv$rand"
$cvAccount = "photoshare-cv-$rand"
$cmAccount = "photoshare-cm-$rand"
$taAccount = "photoshare-ta-$rand"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    🚀 PhotoShare - Infrastructure Deployment (Safe Mode)    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ============================================================================
# USER INPUT
# ============================================================================
Write-Host "`n📋 CONFIGURATION SETUP" -ForegroundColor Yellow
$dbPassword = Read-Host "🔐 Set Database Password (e.g. PhotoShare2024!)"
$jwtSecret = "photoshare-jwt-$rand"

# ============================================================================
# DEPLOYMENT STEPS
# ============================================================================

# 1. Resource Group
Write-Host "`n[1/7] Creating Resource Group..." -ForegroundColor Yellow
az group create --name $resourceGroup --location $location --output none
Write-Host "    ✅ RG: $resourceGroup" -ForegroundColor Green

# 2. Container Registry
Write-Host "`n[2/7] Creating Container Registry..." -ForegroundColor Yellow
az acr create --resource-group $resourceGroup --name $registryName --sku Basic --admin-enabled true --output none
$acrUrl = "$registryName.azurecr.io"
$acrUsername = az acr credential show --name $registryName --query "username" -o tsv
$acrPassword = az acr credential show --name $registryName --query "passwords[0].value" -o tsv
Write-Host "    ✅ ACR: $acrUrl" -ForegroundColor Green

# 3. PostgreSQL Database
Write-Host "`n[3/7] Creating PostgreSQL (Flexible Server)..." -ForegroundColor Yellow
az postgres flexible-server create --resource-group $resourceGroup --name $dbServer --location $location --admin-user $dbUser --admin-password "$dbPassword" --sku-name Standard_B1ms --tier Burstable --public-access 0.0.0.0 --output none
az postgres flexible-server db create --resource-group $resourceGroup --server-name $dbServer --database-name $dbName --output none
$dbFqdn = "$dbServer.postgres.database.azure.com"
Write-Host "    ✅ Database: $dbFqdn" -ForegroundColor Green

# 4. Storage Account
Write-Host "`n[4/7] Creating Storage..." -ForegroundColor Yellow
az storage account create --name $storageName --resource-group $resourceGroup --location $location --sku Standard_LRS --output none
az storage container create --account-name $storageName --name photos --public-access blob --output none
$storageConnection = az storage account show-connection-string --resource-group $resourceGroup --name $storageName --query connectionString -o tsv
Write-Host "    ✅ Storage: $storageName" -ForegroundColor Green

# 5. AI Services
Write-Host "`n[5/7] Provisioning AI Services..." -ForegroundColor Yellow
$cvKey = ""; $cvEndpoint = ""
try {
    az cognitiveservices account create --name $cvAccount --resource-group $resourceGroup --kind ComputerVision --sku F0 --location $location --yes --output none
    az cognitiveservices account create --name $cmAccount --resource-group $resourceGroup --kind ContentModerator --sku F0 --location $location --yes --output none
    az cognitiveservices account create --name $taAccount --resource-group $resourceGroup --kind TextAnalytics --sku F0 --location $location --yes --output none
    $cvKey = az cognitiveservices account keys list --name $cvAccount --resource-group $resourceGroup --query "key1" -o tsv
    $cvEndpoint = az cognitiveservices account show --name $cvAccount --resource-group $resourceGroup --query "properties.endpoint" -o tsv
    Write-Host "    ✅ AI Services Provisioned" -ForegroundColor Green
} catch {
    Write-Host "    ⚠️  AI Services skipped (already exists or limit reached). App will continue..." -ForegroundColor Yellow
}

# 6. Hosting Plan & Apps (With placeholder image)
Write-Host "`n[6/7] Creating Hosting Plan & Apps..." -ForegroundColor Yellow
az appservice plan create --name $appPlan --resource-group $resourceGroup --sku B2 --is-linux --output none
az webapp create --resource-group $resourceGroup --plan $appPlan --name $backendApp --deployment-container-image-name nginx --output none
az webapp create --resource-group $resourceGroup --plan $appPlan --name $frontendApp --deployment-container-image-name nginx --output none

# Configure Backend Settings
az webapp config appsettings set --resource-group $resourceGroup --name $backendApp --settings `
    DB_HOST="$dbFqdn" DB_USER="$dbUser" DB_PASSWORD="$dbPassword" DB_NAME="$dbName" `
    JWT_SECRET="$jwtSecret" STORAGE_CONNECTION_STRING="$storageConnection" `
    CV_ENDPOINT="$cvEndpoint" CV_KEY="$cvKey" PORT=8080 --output none

# Configure Frontend Settings
az webapp config appsettings set --resource-group $resourceGroup --name $frontendApp --settings `
    REACT_APP_API_URL="https://$backendApp.azurewebsites.net/api" --output none

Write-Host "    ✅ Web Apps Pre-Configured" -ForegroundColor Green

# 7. Summary & Secret Collection
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  🎉 INFRASTRUCTURE READY FOR CI/CD                        ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📋 CI/CD SECRETS FOR GITHUB (Add these NOW):" -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------"
Write-Host "ACR_NAME               : $registryName" -ForegroundColor White
Write-Host "ACR_USERNAME           : $acrUsername" -ForegroundColor White
Write-Host "ACR_PASSWORD           : $acrPassword" -ForegroundColor White
Write-Host "AZURE_BACKEND_APP_NAME : $backendApp" -ForegroundColor White
Write-Host "AZURE_FRONTEND_APP_NAME: $frontendApp" -ForegroundColor White
Write-Host "-------------------------------------------------------------"

Write-Host "`n🚀 Final Step: After adding these to GitHub, just PUSH your code!" -ForegroundColor Yellow
Write-Host "GitHub will build your images and put them in these apps automatically." -ForegroundColor White
