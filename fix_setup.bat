@echo off
echo ===================================================
echo   Rana Ecosystem - Tailwind v4 Fixer
echo ===================================================
echo.
echo [1/2] Installing @tailwindcss/vite...
cd admin_client
call npm install @tailwindcss/vite
echo.

echo [2/2] Cleaning up old config...
if exist postcss.config.js (
    del postcss.config.js
    echo Deleted old postcss.config.js
)
cd ..

echo.
echo ===================================================
echo   Fix Complete! Restarting servers...
echo ===================================================
timeout /t 3
start_all.bat
