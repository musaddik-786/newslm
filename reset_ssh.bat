@echo off
:: ============================================================
:: reset_ssh.bat — Reset SSH key for Motor Claims Demo
::
:: Run this if you want to generate a fresh SSH key.
:: It will:
::   1. Delete the old key from this machine
::   2. Remove the old key from the Azure VM (needs VM password once)
::   3. Run 1_setup_once.bat to create and install a fresh key
::
:: After this completes, run_demo.bat will work with the new key.
:: ============================================================

setlocal
set VM_USER=azureuser
set VM_HOST=20.40.57.76
set KEY_FILE=%USERPROFILE%\.ssh\motor_demo_key
set SCRIPT_DIR=%~dp0

title Motor Demo — Reset SSH Key

echo ============================================================
echo  Motor Claims Demo — SSH Key Reset
echo ============================================================
echo.
echo This will delete the old SSH key and create a fresh one.
echo You will need the VM password once during this process.
echo.
echo Press any key to continue, or Ctrl+C to cancel.
pause >nul

:: ── Step 1: Delete old key from this machine ──────────────────────────────────
echo.
echo [1/3] Removing old SSH key from this machine...
if exist "%KEY_FILE%" (
    del "%KEY_FILE%"
    echo        Deleted: %KEY_FILE%
) else (
    echo        No key found at %KEY_FILE% — skipping.
)
if exist "%KEY_FILE%.pub" (
    del "%KEY_FILE%.pub"
    echo        Deleted: %KEY_FILE%.pub
)

:: ── Step 2: Remove old key from VM ────────────────────────────────────────────
echo.
echo [2/3] Removing old key from VM (enter VM password when prompted)...
ssh -o StrictHostKeyChecking=accept-new %VM_USER%@%VM_HOST% "echo '' > ~/.ssh/authorized_keys"
if errorlevel 1 (
    echo [WARNING] Could not clear authorized_keys on VM.
    echo           The old key may still be on the VM — that is OK,
    echo           the new key will still be added in the next step.
) else (
    echo        Old key removed from VM.
)

:: ── Step 3: Run 1_setup_once.bat to create and install fresh key ───────────────
echo.
echo [3/3] Running fresh setup...
echo.
call "%SCRIPT_DIR%1_setup_once.bat"

