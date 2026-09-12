@echo off
title Ourly App - Mobile Development
echo.
echo  ======================================================
echo    Ourly App - Chay truc tiep tren Dien thoai Android
echo  ======================================================
echo.

:: 1. Khoi dong Backend
echo [1/3] Dang khoi dong Backend (FastAPI)...
start "Ourly Backend" cmd /k "cd /d d:\Ourly-App\backend && call .venv\Scripts\activate && python -m uvicorn app.main:app --reload"

:: Doi 3 giay de backend san sang
timeout /t 3 /nobreak >nul

:: 2. Tim thiet bi dien thoai ket noi qua ADB
echo [2/3] Dang tim thiet bi dien thoai ket noi qua USB...
set "DEVICE_ID="
for /f "skip=1 tokens=1,2" %%A in ('"C:\Android\Sdk\platform-tools\adb.exe" devices') do (
    if "%%B"=="device" (
        set "DEVICE_ID=%%A"
        goto :found_device
    )
)

:found_device
if "%DEVICE_ID%"=="" (
    echo   [!] KHONG TIM THAY DIEN THOAI KET NOI!
    echo       Hay kiem tra lai cap USB va bat che do USB Debugging tren dien thoai.
    pause
    exit /b 1
)

echo   - Da tim thay dien thoai: %DEVICE_ID%
echo   - Dang cau hinh chuyen tiep cong USB (adb reverse)...
"C:\Android\Sdk\platform-tools\adb.exe" -s %DEVICE_ID% reverse tcp:8000 tcp:8000
if %ERRORLEVEL% EQU 0 (
    echo   - Chuyen tiep cong 8000 thanh cong!
) else (
    echo   - Canh bao: Khong the thiet lap adb reverse!
)

:: 3. Khoi chay Flutter truc tiep tren thiet bi
echo.
echo [3/3] Dang cai dat va mo app tren dien thoai (%DEVICE_ID%)...
echo   (Qua trinh build lan dau co the mat 1-2 phut, vui long de mo khoa man hinh dien thoai...)
echo   (Nhan "r" de Hot Reload, "R" de Hot Restart, "q" de thoat)
echo.
cd /d d:\Ourly-App\frontend
flutter run -d %DEVICE_ID%

pause
