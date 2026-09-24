@echo off
:: ============================================================
:: stop_demo.bat — Stop all Motor Claims Demo services on VM
::
:: Run this to kill all 4 services on the Azure VM.
:: ============================================================

setlocal
set VM_USER=azureuser
set VM_HOST=20.40.57.76
set KEY_FILE=%USERPROFILE%\.ssh\motor_demo_key
set LOCAL_PORT=5001

title Motor Demo — Stop Services

echo ============================================================
echo  Motor Claims Demo — Stopping Services
echo ============================================================
echo.

:: ── Kill services on VM ───────────────────────────────────────────────────────
echo [1/2] Stopping services on VM (ports 8500, 8501, 8502, 5000)...
ssh -i "%KEY_FILE%" -o StrictHostKeyChecking=accept-new -o BatchMode=yes %VM_USER%@%VM_HOST% ^
    "for PORT in 8500 8501 8502 5000; do PID=$(lsof -ti:$PORT 2>/dev/null); if [ -n \"$PID\" ]; then kill -9 $PID 2>/dev/null; echo \"  Stopped port $PORT (PID $PID)\"; else echo \"  Port $PORT was not running\"; fi; done"

if errorlevel 1 (
    echo [ERROR] Could not connect to VM.
    pause
    exit /b 1
)

:: ── Kill local port forward if running ────────────────────────────────────────
echo.
echo [2/2] Releasing local port %LOCAL_PORT%...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%LOCAL_PORT% " ^| findstr LISTENING 2^>nul') do (
    taskkill /PID %%a /F >nul 2>&1
    echo   Released local port %LOCAL_PORT%
)

echo.
echo ============================================================
echo  All services stopped.
echo ============================================================
echo.
pause
