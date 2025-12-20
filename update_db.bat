@echo off
echo Updating Database Schema...
cd server
call npx prisma db push
cd ..
echo Schema Updated!
pause
