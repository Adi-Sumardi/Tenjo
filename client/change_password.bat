@echo off
REM Tenjo Client - Change Password Utility

SETLOCAL ENABLEDELAYEDEXPANSION

echo ========================================
echo   TENJO CLIENT - CHANGE PASSWORD
echo ========================================
echo.

REM Installation directory
set "INSTALL_DIR=C:\ProgramData\Tenjo"
set "PASSWORD_FILE=%INSTALL_DIR%\.password_hash"

echo [1/3] Checking installation...

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
    echo.
    echo [!] Password belum diset, akan set password baru...
    echo.
    echo [2/3] Setting new password...
    
    set /p "new_password=Masukkan password baru (min 6 karakter): "
    
    REM Set password using Python module
    python "%INSTALL_DIR%\src\utils\password_protection.py" set "!new_password!" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Password berhasil diset!
    ) else (
        echo [!] ERROR: Gagal set password
        echo.
        pause
        exit /b 1
    )
    
) else (
    echo.
    echo [2/3] Verifying old password...
    
    set /p "old_password=Masukkan password lama: "
    
    REM Verify old password
    python "%INSTALL_DIR%\src\utils\password_protection.py" verify "!old_password!" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [!] ERROR: Password lama salah!
        echo.
        pause
        exit /b 1
    )
    echo [OK] Password lama benar
    
    echo.
    echo [3/3] Setting new password...
    
    set /p "new_password=Masukkan password baru (min 6 karakter): "
    
    REM Change password
    python "%INSTALL_DIR%\src\utils\password_protection.py" change "!old_password!" "!new_password!" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Password berhasil diubah!
    ) else (
        echo [!] ERROR: Gagal ubah password
        echo.
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo   PASSWORD CHANGE COMPLETED
echo ========================================
echo.
echo Password berhasil diubah!
echo Simpan password baru untuk uninstall client
echo.

pause
