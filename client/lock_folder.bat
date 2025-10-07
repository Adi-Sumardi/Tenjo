@echo off
REM Tenjo Client - Lock Folder Utility
REM Re-apply folder protection (requires password)

SETLOCAL ENABLEDELAYEDEXPANSION

echo ========================================
echo   TENJO CLIENT - LOCK FOLDER
echo ========================================
echo.

REM Installation directory
set "INSTALL_DIR=C:\ProgramData\Tenjo"

echo [1/3] Checking installation...

REM Check if client is installed
if not exist "%INSTALL_DIR%" (
    echo [!] ERROR: Tenjo client tidak terinstall
    echo.
    pause
    exit /b 1
)

echo [OK] Installation found

echo [2/3] Password verification...
echo.

REM Prompt for master password
set /p "password=Masukkan master password: "

echo.
echo [3/3] Locking folder...

REM Verify and lock folder
python "%INSTALL_DIR%\src\utils\folder_protection.py" protect "!password!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Folder berhasil di-lock!
    echo.
    echo Folder sekarang diproteksi:
    echo - Tidak bisa dihapus tanpa password
    echo - File critical hidden + system
) else (
    echo [!] ERROR: Password salah atau gagal lock
)

echo.
pause
