@echo off
echo ===================================================
echo   Rana Ecosystem - All Dependency Installer
echo ===================================================
echo.

echo [1/5] Installing Server Dependencies...
cd server
call npm install
cd ..
echo.

echo [2/5] Installing Merchant Client Dependencies...
cd client
call npm install
cd ..
echo.

echo [3/5] Installing Admin Client Dependencies...
cd admin_client
call npm install
cd ..
echo.

echo [4/5] Installing Mobile (Merchant) Dependencies...
cd mobile
call flutter pub get
cd ..
echo.

echo [5/5] Installing Mobile (Buyer) Dependencies...
cd mobile_buyer
call flutter pub get
cd ..
echo.

echo ===================================================
echo   All Dependencies Installed Successfully!
echo ===================================================
pause
