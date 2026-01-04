@echo off
echo ==========================================
echo    Rana POS - Local Server Launcher
echo ==========================================
echo.
echo [1/3] Checking environment...
cd server
if not exist .env (
    echo [ERROR] File .env tidak ditemukan!
    echo Silakan copy .env.example ke .env
    pause
    exit
)

echo [2/3] Installing dependencies (if needed)...
call npm install

echo [3/3] Starting Server...
echo.
echo Server akan berjalan di http://localhost:4000
echo Tekan Ctrl+C untuk berhenti.
echo.
call npm run dev
pause
