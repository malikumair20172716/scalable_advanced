# PhotoShare Local Runner
# This script installs dependencies and starts both backend and frontend

Write-Host ">>> Starting PhotoShare Local Development Setup..." -ForegroundColor Cyan

# 1. Backend Setup
Write-Host "`n[1/3] Setting up Backend..." -ForegroundColor Yellow
cd backend
if (-not (Test-Path "node_modules")) {
    Write-Host "      Installing backend dependencies..." -ForegroundColor Gray
    npm install
}

if (-not (Test-Path ".env")) {
    Write-Host "      Creating .env from .env.example..." -ForegroundColor Gray
    Copy-Item ".env.example" ".env"
}
cd ..

# 2. Frontend Setup
Write-Host "`n[2/3] Setting up Frontend..." -ForegroundColor Yellow
cd frontend
if (-not (Test-Path "node_modules")) {
    Write-Host "      Installing frontend dependencies..." -ForegroundColor Gray
    npm install
}
cd ..

# 3. Execution
Write-Host "`n[3/3] Starting Services..." -ForegroundColor Green
Write-Host "      Tip: Keep this window open for Frontend logs." -ForegroundColor Gray

# Start Backend in a new window
# We use -NoExit so you can see if it crashes
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; npm run dev" -WindowStyle Normal
Write-Host "      [OK] Backend starting in a separate window (Port 5000)" -ForegroundColor Green

# Start Frontend in this window
Write-Host "      [OK] Starting Frontend (Port 3000)..." -ForegroundColor Green
cd frontend
npm start
