@echo off
cd /d "%~dp0"
echo ====================================================
echo Starting SignBridge Backend with 3D Humanoid Avatar...
echo ====================================================
start http://127.0.0.1:8000/avatar-preview
call .venv\Scripts\activate.bat
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
pause
