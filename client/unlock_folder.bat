@echo off
REM Tenjo Client - Unlock Folder Utility
REM Temporarily unlock folder for maintenance (requires password)

SETLOCAL ENABLEDELAYEDEXPANSION

echo ========================================
echo   TENJO CLIENT - UNLOCK FOLDER
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
echo [3/3] Unlocking folder...

REM Verify and unlock folder
python "%INSTALL_DIR%\src\utils\folder_protection.py" unprotect "!password!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Folder berhasil di-unlock!
    echo.
    echo Folder sekarang bisa diakses dan dihapus
    echo.
    echo PERINGATAN:
    echo - Folder protection telah dinonaktifkan
    echo - Jalankan lock_folder.bat untuk proteksi lagi
) else (
    echo [!] ERROR: Password salah atau gagal unlock
)

echo.
pause
