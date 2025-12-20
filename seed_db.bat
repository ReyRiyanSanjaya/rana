@echo off
echo Seeding Database...
cd server
call node prisma/seed.js
echo.
echo =========================================
echo  Seeding Complete!
echo  Use the credentials provided in chat.
echo =========================================
pause
