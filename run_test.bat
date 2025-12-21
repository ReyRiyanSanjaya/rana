@echo off
echo ===================================================
echo   Rana Ecosystem - Test Runner
echo ===================================================
echo.
echo No Android Emulator found. 
echo You can test the app on Windows or Chrome.
echo.
echo Select platform to run:
echo 1. Windows (Desktop)
echo 2. Chrome (Web)
echo.
set /p platform="Enter choice (1/2): "

if "%platform%"=="1" set DEVICE=windows
if "%platform%"=="2" set DEVICE=chrome

echo.
echo Select application to test:
echo 1. Rana Merchant (Kelola Toko)
echo 2. Rana Market (Buyer App)
echo.
set /p app="Enter choice (1/2): "

if "%app%"=="1" (
    cd mobile
    echo Starting Rana Merchant on %DEVICE%...
    if "%DEVICE%"=="chrome" (
        call flutter run -d chrome --web-browser-flag "--disable-web-security"
    ) else (
        call flutter run -d %DEVICE%
    )
)

if "%app%"=="2" (
    cd mobile_buyer
    echo Starting Rana Market on %DEVICE%...
    if "%DEVICE%"=="chrome" (
        call flutter run -d chrome --web-browser-flag "--disable-web-security"
    ) else (
        call flutter run -d %DEVICE%
    )
)

cd ..
pause
