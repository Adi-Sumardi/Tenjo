@echo off
REM Tenjo Client - Uninstall with Password Protection
REM Requires password to uninstall client

SETLOCAL ENABLEDELAYEDEXPANSION

echo ========================================
echo   TENJO CLIENT - UNINSTALL
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
set "PASSWORD_FILE=%INSTALL_DIR%\.password_hash"

echo [1/5] Checking installation...

REM Check if client is installed
if not exist "%INSTALL_DIR%" (
    echo [!] ERROR: Tenjo client tidak terinstall
    echo.
    pause
    exit /b 1
)

echo [OK] Installation found

REM Check if password is set
if not exist "%PASSWORD_FILE%" (
    echo [!] ERROR: Password belum diset
    echo.
    echo Silakan hubungi administrator untuk set password terlebih dahulu
    echo.
    pause
    exit /b 1
)

echo [2/5] Password verification...
echo.

REM Prompt for password (max 3 attempts)
set "MAX_ATTEMPTS=3"
set "attempt=0"
set "verified=0"

:password_loop
set /a attempt+=1
echo Attempt !attempt!/%MAX_ATTEMPTS%
set /p "password=Masukkan password: "

REM Verify password using Python module
python "%INSTALL_DIR%\src\utils\password_protection.py" verify "!password!" >nul 2>&1
if !errorlevel! equ 0 (
    set "verified=1"
    echo.
    echo [OK] Password benar!
    goto password_verified
) else (
    echo.
    echo [!] Password salah!
    if !attempt! lss %MAX_ATTEMPTS% (
        echo Silakan coba lagi...
        echo.
        goto password_loop
    )
)

:password_failed
echo.
echo [!] FAILED: Password salah 3 kali
echo Uninstall dibatalkan untuk keamanan
echo.
pause
exit /b 1

:password_verified
echo.
echo [3/6] Unlocking folder protection...

REM Unlock folder first
set "MASTER_PASSWORD=TenjoAdilabs96"
python "%INSTALL_DIR%\src\utils\folder_protection.py" unprotect "%MASTER_PASSWORD%" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Folder unlocked
) else (
    echo [!] WARNING: Gagal unlock folder ^(akan coba lanjut^)
)

echo [4/6] Stopping client...

REM Stop any running client processes
taskkill /F /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *Tenjo*" >nul 2>&1
timeout /t 2 /nobreak >nul

echo [OK] Client stopped

echo [5/6] Removing scheduled tasks...

REM Remove scheduled tasks
schtasks /delete /tn "TenjoMonitor" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo   - Removed: TenjoMonitor
) else (
    echo   - Task not found: TenjoMonitor
)

schtasks /delete /tn "TenjoWatchdog" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo   - Removed: TenjoWatchdog
) else (
    echo   - Task not found: TenjoWatchdog
)

REM Remove from Registry (startup)
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitor" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo   - Removed Registry startup
) else (
    echo   - Registry entry not found
)

echo [6/6] Removing files...

REM Remove installation directory
rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Files removed
) else (
    echo [!] WARNING: Tidak bisa hapus semua file
    echo Mungkin ada file yang sedang digunakan
)

echo.
echo ========================================
echo   UNINSTALL COMPLETED
echo ========================================
echo.
echo Tenjo client berhasil di-uninstall
echo.

pause
