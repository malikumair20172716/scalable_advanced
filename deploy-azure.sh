#!/bin/bash

# PhotoShare Azure Deployment Script
# Automates free tier Azure deployment
# Usage: bash deploy-azure.sh

set -e

echo "🚀 PhotoShare - Azure Free Tier Deployment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="photoshare-rg"
LOCATION="eastus"
REGISTRY_NAME="photoshareregistry"
DB_SERVER="photoshare-db-server"
DB_NAME="photoshare_db"
DB_USER="dbadmin"
STORAGE_NAME="photoshareussa"
APP_PLAN="photoshare-plan"
BACKEND_APP="photoshare-backend"
FRONTEND_APP="photoshare-frontend"
VAULT_NAME="photoshare-vault"

# Read configuration from user
read -p "Enter your desired database password: " DB_PASSWORD
read -p "Enter your JWT secret key: " JWT_SECRET
read -p "Enter your Azure subscription ID (optional, will auto-detect): " SUBSCRIPTION_ID

# Auto-detect subscription if not provided
if [ -z "$SUBSCRIPTION_ID" ]; then
  SUBSCRIPTION_ID=$(az account show --query id -o tsv)
fi

echo -e "${GREEN}✓${NC} Using Subscription: $SUBSCRIPTION_ID"

# Step 1: Create Resource Group
echo -e "\n${YELLOW}[1/10]${NC} Creating Resource Group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output table
echo -e "${GREEN}✓${NC} Resource Group created"

# Step 2: Create Container Registry
echo -e "\n${YELLOW}[2/10]${NC} Creating Container Registry (Free)..."
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $REGISTRY_NAME \
  --sku Free \
  --output table
echo -e "${GREEN}✓${NC} Container Registry created"

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $REGISTRY_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $REGISTRY_NAME --query "passwords[0].value" -o tsv)
ACR_URL="$REGISTRY_NAME.azurecr.io"

echo -e "${GREEN}✓${NC} ACR Credentials obtained"

# Step 3: Build and push Docker images
echo -e "\n${YELLOW}[3/10]${NC} Building and pushing Docker images..."
echo "Building backend..."
az acr build \
  --registry $REGISTRY_NAME \
  --image photoshare-backend:1.0.0 \
  --file Dockerfile ./backend

echo "Building frontend..."
az acr build \
  --registry $REGISTRY_NAME \
  --image photoshare-frontend:1.0.0 \
  --file Dockerfile ./frontend

echo -e "${GREEN}✓${NC} Docker images built and pushed"

# Step 4: Create PostgreSQL Database
echo -e "\n${YELLOW}[4/10]${NC} Creating PostgreSQL Database (Free 12 months)..."
az postgres server create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER \
  --location $LOCATION \
  --admin-user $DB_USER \
  --admin-password "$DB_PASSWORD" \
  --sku-name B_Gen5_1 \
  --storage-size 51200 \
  --backup-retention 7 \
  --geo-redundant-backup Disabled \
  --output table

az postgres db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_SERVER \
  --name $DB_NAME

# Allow Azure services
az postgres server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_SERVER \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Allow local machine (get current IP)
CURRENT_IP=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null || echo "0.0.0.0")
if [ "$CURRENT_IP" != "0.0.0.0" ]; then
  az postgres server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --server-name $DB_SERVER \
    --name AllowLocalAccess \
    --start-ip-address $CURRENT_IP \
    --end-ip-address $CURRENT_IP
  echo -e "${GREEN}✓${NC} Added firewall rule for your IP: $CURRENT_IP"
fi

echo -e "${GREEN}✓${NC} PostgreSQL Database created"

# Get DB FQDN
DB_FQDN=$(az postgres server show \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER \
  --query "fullyQualifiedDomainName" -o tsv)

echo "Database FQDN: $DB_FQDN"

# Step 5: Initialize Database Schema
echo -e "\n${YELLOW}[5/10]${NC} Initializing Database Schema..."
echo "Note: You may need to wait 1-2 minutes for database to be accessible"
sleep 10

# Try to connect and initialize (may fail first time, that's ok)
if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_FQDN" \
     -U "$DB_USER@$DB_SERVER" \
     -d "$DB_NAME" \
     -f backend/src/db/schema.sql 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Database schema initialized"
else
  echo -e "${YELLOW}⚠${NC} Could not initialize schema. You may need to do this manually:"
  echo "   PGPASSWORD='$DB_PASSWORD' psql -h $DB_FQDN -U $DB_USER@$DB_SERVER -d $DB_NAME -f backend/src/db/schema.sql"
fi

# Step 6: Create Blob Storage
echo -e "\n${YELLOW}[6/10]${NC} Creating Blob Storage (Free 5GB)..."
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --access-tier Hot \
  --output table

# Create container
az storage container create \
  --account-name $STORAGE_NAME \
  --name photos \
  --public-access blob

# Get connection string
STORAGE_CONNECTION=$(az storage account show-connection-string \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_NAME \
  --query connectionString -o tsv)

echo -e "${GREEN}✓${NC} Blob Storage created"

# Step 7: Create Key Vault
echo -e "\n${YELLOW}[7/10]${NC} Creating Key Vault..."
az keyvault create \
  --resource-group $RESOURCE_GROUP \
  --name $VAULT_NAME \
  --location $LOCATION \
  --output table

# Store secrets
az keyvault secret set \
  --vault-name $VAULT_NAME \
  --name db-password \
  --value "$DB_PASSWORD"

az keyvault secret set \
  --vault-name $VAULT_NAME \
  --name jwt-secret \
  --value "$JWT_SECRET"

az keyvault secret set \
  --vault-name $VAULT_NAME \
  --name storage-connection \
  --value "$STORAGE_CONNECTION"

echo -e "${GREEN}✓${NC} Key Vault created with secrets"

# Step 8: Create App Service Plan (Free)
echo -e "\n${YELLOW}[8/10]${NC} Creating App Service Plan (Free F1)..."
az appservice plan create \
  --name $APP_PLAN \
  --resource-group $RESOURCE_GROUP \
  --sku F1 \
  --is-linux \
  --output table
echo -e "${GREEN}✓${NC} App Service Plan created"

# Step 9: Deploy Backend
echo -e "\n${YELLOW}[9/10]${NC} Deploying Backend App..."
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_PLAN \
  --name $BACKEND_APP \
  --deployment-container-image-name-user "$ACR_URL/photoshare-backend:1.0.0"

az webapp config container set \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name "$ACR_URL/photoshare-backend:1.0.0" \
  --docker-registry-server-url "https://$ACR_URL" \
  --docker-registry-server-user "$ACR_USERNAME" \
  --docker-registry-server-password "$ACR_PASSWORD"

# Set environment variables
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --settings \
    DB_HOST="$DB_FQDN" \
    DB_USER="$DB_USER@$DB_SERVER" \
    DB_PASSWORD="$DB_PASSWORD" \
    DB_NAME="$DB_NAME" \
    JWT_SECRET="$JWT_SECRET" \
    STORAGE_CONNECTION_STRING="$STORAGE_CONNECTION" \
    NODE_ENV="production" \
    PORT=8080

# Enable logging
az webapp log config \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --docker-container-logging filesystem

echo -e "${GREEN}✓${NC} Backend deployed"

# Step 10: Deploy Frontend
echo -e "\n${YELLOW}[10/10]${NC} Deploying Frontend App..."
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_PLAN \
  --name $FRONTEND_APP \
  --deployment-container-image-name-user "$ACR_URL/photoshare-frontend:1.0.0"

az webapp config container set \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name "$ACR_URL/photoshare-frontend:1.0.0" \
  --docker-registry-server-url "https://$ACR_URL" \
  --docker-registry-server-user "$ACR_USERNAME" \
  --docker-registry-server-password "$ACR_PASSWORD"

# Set environment for frontend (point to backend)
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $FRONTEND_APP \
  --settings \
    REACT_APP_API_URL="https://$BACKEND_APP.azurewebsites.net/api"

echo -e "${GREEN}✓${NC} Frontend deployed"

# Summary
echo -e "\n${GREEN}=================================================="
echo "✅ Deployment Complete!"
echo "==================================================${NC}\n"

BACKEND_URL="https://$BACKEND_APP.azurewebsites.net"
FRONTEND_URL="https://$FRONTEND_APP.azurewebsites.net"

echo -e "${GREEN}📍 Application URLs:${NC}"
echo "   Backend:  $BACKEND_URL"
echo "   Frontend: $FRONTEND_URL"
echo "   Health:   $BACKEND_URL/health"

echo -e "\n${GREEN}📊 Database Info:${NC}"
echo "   Server:   $DB_FQDN"
echo "   Database: $DB_NAME"
echo "   User:     $DB_USER@$DB_SERVER"

echo -e "\n${GREEN}💾 Storage Info:${NC}"
echo "   Account:  $STORAGE_NAME"
echo "   Container: photos"

echo -e "\n${GREEN}🔑 Secrets stored in:${NC}"
echo "   Key Vault: $VAULT_NAME"

echo -e "\n${YELLOW}📝 Next Steps:${NC}"
echo "   1. Wait 2-3 minutes for containers to start"
echo "   2. Test backend: curl $BACKEND_URL/health"
echo "   3. Access frontend: $FRONTEND_URL"
echo "   4. Check logs: az webapp log tail -g $RESOURCE_GROUP -n $BACKEND_APP"

echo -e "\n${YELLOW}💰 Cost Estimate:${NC}"
echo "   Year 1: FREE (all services at free tier)"
echo "   Year 2+: ~\$40-50/month"

echo -e "\n${YELLOW}⚠ Important Notes:${NC}"
echo "   - PostgreSQL free tier expires after 12 months"
echo "   - App Service F1 has CPU quota limits (60min/day)"
echo "   - For production, upgrade to B1+ plan"
echo "   - Monitor costs at: https://portal.azure.com"
