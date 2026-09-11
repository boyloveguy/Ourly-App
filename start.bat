@echo off
title Ourly App - Startup
echo.
echo  ========================================
echo    Ourly App - Khoi dong du an
echo  ========================================
echo.

:: Khoi dong Backend (FastAPI)
echo [1/2] Dang khoi dong Backend (FastAPI)...
start "Ourly Backend" cmd /k "cd /d d:\Ourly-App\backend && call .venv\Scripts\activate && python -m uvicorn app.main:app --reload"

:: Doi 3 giay de backend khoi dong truoc
timeout /t 3 /nobreak >nul

:: Khoi dong Frontend (Flutter Web)
echo [2/2] Dang khoi dong Frontend (Flutter Web)...
start "Ourly Frontend" cmd /k "cd /d d:\Ourly-App\frontend && flutter run -d web-server --web-port 3000"

echo.
echo  ========================================
echo   Backend:  http://localhost:8000
echo   Frontend: http://localhost:3000
echo  ========================================
echo.
echo  Nhan phim bat ky de dong cua so nay...
pause >nul
