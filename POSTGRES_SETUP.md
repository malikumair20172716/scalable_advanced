# PostgreSQL Local Setup Guide for PhotoShare

## Did you enter a password during PostgreSQL installation?

You'll need to know the password you set for the `postgres` user.

## Option 1: Quick Setup with Default Password (if you didn't change it)

If you used the default password during installation, run these commands in PowerShell:

```powershell
# Navigate to backend directory
cd "C:\Users\01-135231-091\Desktop\Scalable Advanced Software Solutions\backend"

# Create database (replace YOUR_PASSWORD with your actual postgres password)
$password = "YOUR_PASSWORD"
& "C:\Program Files\PostgreSQL\18\bin\psql" -U postgres -X -c "CREATE DATABASE photoshare_db;" 2>&1

# Run the schema
& "C:\Program Files\PostgreSQL\18\bin\psql" -U postgres -d photoshare_db -f "src/db/schema.sql" 2>&1
```

## Option 2: Using pgAdmin (GUI)

1. Open pgAdmin (installed with PostgreSQL)
2. Right-click on "Databases" and select "Create > Database"
3. Name it: `photoshare_db`
4. Right-click the new database and select "Query Tool"
5. Open and run the SQL from: `backend/src/db/schema.sql`

## Option 3: Update the .env file and test connection

If the database is created, make sure your `.env` has the correct password:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=photoshare_db
DB_USER=postgres
DB_PASSWORD=YOUR_ACTUAL_PASSWORD
```

## Testing the Connection

After creating the database, restart your backend server:

```powershell
cd "C:\Users\01-135231-091\Desktop\Scalable Advanced Software Solutions\backend"
npm start
```

You should see no PostgreSQL connection errors!

## Common Issues

- **Password authentication failed**: Make sure you're using the correct password set during PostgreSQL installation
- **Port 5432 not responding**: PostgreSQL service might not be running. Check Windows Services (services.msc) for PostgreSQL
- **Database already exists**: Drop it first with: `DROP DATABASE photoshare_db;`
