@echo off
echo ===================================================
echo   Rana Ecosystem - APK Builder
echo ===================================================
echo.
echo Select application to build:
echo 1. Rana Merchant (Kelola Toko)
echo 2. Rana Market (Buyer App)
echo 3. Build Both
echo.
set /p choice="Enter choice (1/2/3): "

if "%choice%"=="1" goto build_merchant
if "%choice%"=="2" goto build_market
if "%choice%"=="3" goto build_all
goto end

:build_merchant
echo.
echo Building Rana Merchant (mobile)...
cd mobile
call flutter build apk --release
if errorlevel 1 (
    echo Build Failed!
    cd ..
    pause
    exit /b
)
echo Copying APK to root/builds...
cd ..
if not exist builds mkdir builds
copy "mobile\build\app\outputs\flutter-apk\app-release.apk" "builds\rana-merchant-release.apk"
echo Done! APK saved to builds\rana-merchant-release.apk
goto end

:build_market
echo.
echo Building Rana Market (mobile_buyer)...
cd mobile_buyer
call flutter build apk --release
if errorlevel 1 (
    echo Build Failed!
    cd ..
    pause
    exit /b
)
echo Copying APK to root/builds...
cd ..
if not exist builds mkdir builds
copy "mobile_buyer\build\app\outputs\flutter-apk\app-release.apk" "builds\rana-market-release.apk"
echo Done! APK saved to builds\rana-market-release.apk
goto end

:build_all
echo.
echo [1/2] Building Rana Merchant...
cd mobile
call flutter build apk --release
if errorlevel 1 (
   echo Merchant Build Failed!
) else (
   cd ..
   if not exist builds mkdir builds
   copy "mobile\build\app\outputs\flutter-apk\app-release.apk" "builds\rana-merchant-release.apk"
)

echo.
echo [2/2] Building Rana Market...
cd mobile_buyer
call flutter build apk --release
if errorlevel 1 (
   echo Market Build Failed!
) else (
   cd ..
   if not exist builds mkdir builds
   copy "mobile_buyer\build\app\outputs\flutter-apk\app-release.apk" "builds\rana-market-release.apk"
)
pause
exit /b

:end
pause
