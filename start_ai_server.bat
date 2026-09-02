@echo off
echo ============================================================
echo   AlumniConnect AI Engine — Unified Server Startup v3.0
echo ============================================================
echo.

cd /d "%~dp0ai-module"

echo [1/4] Installing core AI dependencies...
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo [ERROR] pip install failed. Ensure Python 3.9+ is installed.
    pause
    exit /b 1
)

echo [2/4] Installing Alumni Skill Analyzer dependencies...
pip install scikit-learn numpy scipy --quiet

echo [3/4] Installing Mentor Match Engine (SBERT) dependencies...
pip install sentence-transformers torch --quiet
if errorlevel 1 (
    echo [WARN] sentence-transformers install failed. Mentor Match will use fallback mode.
)

echo [4/4] Starting AlumniConnect AI Server on http://0.0.0.0:8000 ...
echo.
echo  API Docs:  http://localhost:8000/docs
echo  Health:    http://localhost:8000/health
echo.
echo  Endpoints:
echo    POST /resume/upload           — PDF parsing pipeline
echo    POST /career-twin/analyze     — Career Twin AI
echo    POST /career-gps/analyze      — Career GPS AI
echo    POST /alumni-skill/analyze    — Alumni Skill Gap Analyzer
echo    POST /mentor-match/analyze    — SBERT Mentor Match Engine  [NEW]
echo.
echo  Flutter Android Emulator URL: http://10.0.2.2:8000
echo  Flutter Physical Device URL:  http://^<YOUR-PC-LAN-IP^>:8000
echo  Flutter iOS Simulator URL:    http://localhost:8000
echo.

set PYTHONPATH=%~dp0ai-module;%~dp0ai-module mentor match;%~dp0alumini_skill\alumini_skill;%PYTHONPATH%
python -m uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload

pause
