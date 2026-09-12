@echo off
echo ===================================================
echo   Starting SignBridge 3D Avatar & App
echo ===================================================
cd /d "%~dp0"
start "" node server.js
timeout /t 2 /nobreak >nul
start msedge "http://localhost:5000/avatar_3d.html"
start msedge "http://localhost:5000"
echo.
echo Application running at:
echo   - 3D Avatar Studio: http://localhost:5000/avatar_3d.html
echo   - Full Flutter App:  http://localhost:5000
echo.
pause
