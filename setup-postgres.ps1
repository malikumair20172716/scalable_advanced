#!/usr/bin/env pwsh

# PhotoShare PostgreSQL Database Setup Script
# This script creates the database and runs the schema

$PostgreSQLPath = "C:\Program Files\PostgreSQL\18\bin"
$psql = Join-Path $PostgreSQLPath "psql"
$BackendPath = "C:\Users\01-135231-091\Desktop\Scalable Advanced Software Solutions\backend"
$SchemaPath = Join-Path $BackendPath "src\db\schema.sql"

Write-Host "============================================" -ForegroundColor Green
Write-Host "PhotoShare PostgreSQL Setup Script" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Prompt for password
$SecurePassword = Read-Host "Enter PostgreSQL password for user 'postgres'" -AsSecureString
$Password = [System.Net.NetworkCredential]::new("", $SecurePassword).Password

Write-Host ""
Write-Host "[1/3] Creating database: photoshare_db..." -ForegroundColor Yellow

# Create database
$env:PGPASSWORD = $Password
& $psql -U postgres -h localhost -c "DROP DATABASE IF EXISTS photoshare_db;" 2>&1 | Out-Null
$createResult = & $psql -U postgres -h localhost -c "CREATE DATABASE photoshare_db;" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Database created successfully!" -ForegroundColor Green
} else {
    Write-Host "[✗] Failed to create database" -ForegroundColor Red
    Write-Host $createResult
    exit 1
}

Write-Host ""
Write-Host "[2/3] Creating tables and indexes..." -ForegroundColor Yellow

# Run schema
$schemaResult = & $psql -U postgres -h localhost -d photoshare_db -f $SchemaPath 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Schema created successfully!" -ForegroundColor Green
} else {
    Write-Host "[✗] Failed to create schema" -ForegroundColor Red
    Write-Host $schemaResult
    exit 1
}

Write-Host ""
Write-Host "[3/3] Testing connection..." -ForegroundColor Yellow

# Test connection
$testResult = & $psql -U postgres -h localhost -d photoshare_db -c "SELECT COUNT(*) FROM users;" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Connection test passed!" -ForegroundColor Green
} else {
    Write-Host "[✗] Connection test failed" -ForegroundColor Red
    Write-Host $testResult
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "[SUCCESS] PostgreSQL setup complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Update backend/.env with your PostgreSQL password"
Write-Host "2. Restart the backend server: cd backend && npm start"
Write-Host ""
