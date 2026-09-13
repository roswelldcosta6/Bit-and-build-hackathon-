@echo off
title SignBridge - ISL Translation Suite
color 0A

echo ================================================================
echo   Starting SignBridge - ISL Translation Suite on your Laptop
echo ================================================================
echo.

set PATH=C:\Users\ferna\OneDrive\Desktop\bit\flutter\bin;C:\Users\ferna\AppData\Local\Android\Sdk\platform-tools;%PATH%
set PYTHON_EXE=C:\Users\ferna\OneDrive\Desktop\bit\ml_venv\Scripts\python.exe

echo [1/3] Starting FastAPI Backend on http://127.0.0.1:8000 ...
start "SignBridge Backend" /B cmd /c ""%PYTHON_EXE%" -m uvicorn main:app --app-dir "%~dp0backend" --host 0.0.0.0 --port 8000"

timeout /t 3 /nobreak >nul

echo [2/3] Launching Web Application in Browser...
start "" "http://localhost:5000"
start "" "http://127.0.0.1:8000/avatar-preview"

echo [3/3] Starting Flutter App Server...
cd /d "%~dp0app"
call flutter run -d chrome --web-port 5000

pause
