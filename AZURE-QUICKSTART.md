# Azure Deployment - Quick Start (5 minutes)

## 🚀 One-Step Azure Deployment

Your PhotoShare application is ready to deploy to **Azure FREE tier** (Year 1: $0 cost).

### Prerequisites

```bash
# Install Azure CLI
# Windows: choco install azure-cli
# macOS: brew install azure-cli
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login
```

### Deploy with One Command

#### Windows PowerShell
```powershell
# Enable script execution (first time only)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run deployment
.\deploy-azure.ps1
```

#### macOS/Linux
```bash
# Make script executable
chmod +x deploy-azure.sh

# Run deployment
./deploy-azure.sh
```

### What You'll Be Prompted For

1. **Database Password** - Create a secure password
2. **JWT Secret** - Generate a random secret for JWT tokens
3. **Subscription ID** - Leave blank to auto-detect

### Wait Times

| Step | Duration |
|------|----------|
| Container Registry creation | 1-2 min |
| Docker build & push | 5-10 min |
| PostgreSQL initialization | 2-3 min |
| App Service deployment | 3-5 min |
| **Total** | **15-20 minutes** |

### After Deployment Completes

You'll see URLs like:
```
Backend:  https://photoshare-backend.azurewebsites.net
Frontend: https://photoshare-frontend.azurewebsites.net
Health:   https://photoshare-backend.azurewebsites.net/health
```

### Test It

```bash
# Check backend is healthy
curl https://photoshare-backend.azurewebsites.net/health

# Open frontend in browser
# https://photoshare-frontend.azurewebsites.net
```

### View Logs

```powershell
az webapp log tail -g photoshare-rg -n photoshare-backend
```

## 💰 Cost Breakdown

| Service | Free Tier | After 12 Months |
|---------|-----------|-----------------|
| App Service | **FREE** (60min/day CPU) | $12+/month |
| PostgreSQL | **FREE** (12 months) | $40+/month |
| Container Registry | **FREE** | FREE |
| Blob Storage | **FREE** (5GB) | $0.018/GB |
| Key Vault | **FREE** | FREE |
| **TOTAL** | **$0** | ~$50-60/month |

## ⚙️ Manual Commands (If Script Doesn't Work)

See [Full Azure Deployment Guide](docs/azure-deployment.md) for step-by-step manual commands.

## 🆘 Troubleshooting

### Script fails with "command not found"
- Make sure Azure CLI is installed: `az --version`
- For PowerShell, enable script execution first

### Container won't start
```powershell
# Check logs
az webapp log tail -g photoshare-rg -n photoshare-backend

# Restart
az webapp restart -g photoshare-rg -n photoshare-backend
```

### Database connection error
```powershell
# List firewall rules
az postgres server firewall-rule list -g photoshare-rg -n photoshare-db-server

# Add your IP if needed (automatic in script)
```

### Can't initialize schema
You can do this manually using Azure Data Studio:
1. Open Azure Portal
2. Go to PostgreSQL server
3. Use Query Editor to run `backend/src/db/schema.sql`

## 📚 Next Steps

1. **Test API** with Postman (collection included)
2. **Record your 5-minute demo video**
3. **Create 12-slide PowerPoint presentation**
4. **Write 6-page Coursework 1 document** (CI/CD focus)

## 🎓 For Your Presentation

Mention in Slides 7-8 (Advanced Features):

*"Deployed to Azure using free-tier services:*
- *App Service (F1) - 60 minutes CPU quota per day*
- *PostgreSQL (free 12 months) - B_Gen5_1 SKU*
- *Blob Storage (5GB free) - for photos*
- *Container Registry (free) - for Docker images*
- *Total Year 1 Cost: $0"*

---

**Deployment time: 15-20 minutes** ⏱️

Go ahead and run the script! 🚀
