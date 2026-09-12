@echo off
echo ===================================================
echo   Starting SignBridge Flutter App in Microsoft Edge
echo ===================================================
cd /d "%~dp0"
flutter run -d edge --web-port 5000
