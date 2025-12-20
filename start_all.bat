@echo off
echo Starting Rana Ecosystem...

:: 1. Server (Backend)
:: we run prisma db push first to ensure DB is up to date
start "Rana Server" cmd /k "cd server && echo Updating DB Schema... && npx prisma db push && echo Starting Server... && npm run dev"

:: 2. Merchant Client
start "Rana Merchant Client" cmd /k "cd client && echo Starting Merchant App... && npm run dev"

:: 3. Admin Client
start "Rana Admin Client" cmd /k "cd admin_client && echo Starting Admin Dashboard... && npm run dev"

echo.
echo ========================================================
echo  All applications are launching in separate windows.
echo  Please wait for them to initialize.
echo.
echo  Server: http://localhost:4000
echo  Merchant App: http://localhost:5173 (usually)
echo  Admin Dashboard: http://localhost:5174 (usually)
echo ========================================================
echo.
pause
