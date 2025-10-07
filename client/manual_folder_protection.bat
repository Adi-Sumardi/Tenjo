@echo off
REM Manual Folder Protection Script
REM Run this if folder protection failed during installation

SETLOCAL ENABLEDELAYEDEXPANSION

echo ========================================
echo   MANUAL FOLDER PROTECTION
echo ========================================
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: Script harus dijalankan sebagai Administrator
    echo.
    echo Cara menjalankan sebagai Admin:
    echo 1. Klik kanan file .bat ini
    echo 2. Pilih "Run as Administrator"
    echo.
    pause
    exit /b 1
)

REM Installation directory
set "INSTALL_DIR=C:\ProgramData\Realtek 786"
set "MASTER_PASSWORD=TenjoAdilabs96"

echo [1/3] Checking installation...

if not exist "%INSTALL_DIR%" (
    echo [!] ERROR: Tenjo tidak terinstall di %INSTALL_DIR%
    echo.
    pause
    exit /b 1
)

echo [OK] Installation found

echo [2/3] Checking folder_protection.py...

set "PROTECTION_SCRIPT=%INSTALL_DIR%\src\utils\folder_protection.py"
if not exist "%PROTECTION_SCRIPT%" (
    echo [!] ERROR: folder_protection.py tidak ditemukan
    echo   Path: %PROTECTION_SCRIPT%
    echo.
    pause
    exit /b 1
)

echo [OK] Protection script found

echo [3/3] Applying folder protection...
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [!] ERROR: Python tidak ditemukan
    echo   Pastikan Python terinstall dan ada di PATH
    echo.
    pause
    exit /b 1
)

REM Apply folder protection
python "%PROTECTION_SCRIPT%" protect "%MASTER_PASSWORD%" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Folder protection berhasil diterapkan!
    echo.
    echo Proteksi aktif:
    echo   - Folder tidak bisa dihapus paksa
    echo   - Critical files di-hidden
    echo   - ICACLS deny delete
    echo.
    
    REM Show protection status
    echo Status:
    python "%PROTECTION_SCRIPT%" status
    
) else (
    echo [!] ERROR: Gagal apply folder protection
    echo.
    echo Kemungkinan penyebab:
    echo 1. Tidak dijalankan sebagai Administrator
    echo 2. Password salah ^(seharusnya: TenjoAdilabs96^)
    echo 3. ICACLS tidak bisa dijalankan
    echo.
)

echo.
pause
