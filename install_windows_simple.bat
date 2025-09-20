@echo off
REM Tenjo Windows Simple Installer
REM No admin rights required, minimal dependencies

cls
echo.
echo ============================================
echo    TENJO - Employee Monitoring System
echo    Simple Installer v1.0 (Manual Mode)
echo ============================================
echo.

REM Variables
set INSTALL_DIR=%USERPROFILE%\.tenjo
set TEMP_DIR=%TEMP%\tenjo_simple_%RANDOM%

echo [INFO] This installer will guide you through manual setup
echo [INFO] Installation directory: %INSTALL_DIR%
echo.

REM Check prerequisites
echo [1/4] Checking system requirements...

REM Test Python
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python is available
    python --version
) else (
    echo [ERROR] Python not found!
    echo.
    echo PLEASE INSTALL PYTHON FIRST:
    echo 1. Download from: https://www.python.org/downloads/
    echo 2. Run installer and check "Add Python to PATH"
    echo 3. Restart this installer
    echo.
    pause
    exit /b 1
)

REM Test Git
git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Git is available
    git --version
) else (
    echo [ERROR] Git not found!
    echo.
    echo PLEASE INSTALL GIT FIRST:
    echo 1. Download from: https://git-scm.com/download/win
    echo 2. Run installer with default settings
    echo 3. Restart this installer
    echo.
    pause
    exit /b 1
)

REM Test internet
echo [INFO] Testing internet connection...
ping -n 1 google.com >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Internet connection available
) else (
    echo [ERROR] No internet connection!
    echo [INFO] Please check your connection and try again
    echo.
    pause
    exit /b 1
)

echo.
echo [2/4] Preparing installation...

REM Clean existing installation
if exist "%INSTALL_DIR%" (
    echo [INFO] Removing existing installation...
    taskkill /f /im python.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
)

REM Create temp directory
mkdir "%TEMP_DIR%" >nul 2>&1

echo.
echo [3/4] Downloading Tenjo...
echo [INFO] This may take 1-2 minutes depending on your connection

REM Clone repository
git clone https://github.com/Adi-Sumardi/Tenjo.git "%INSTALL_DIR%"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to download from GitHub
    echo [INFO] Please check your internet connection
    pause
    exit /b 1
)

if not exist "%INSTALL_DIR%\client" (
    echo [ERROR] Download incomplete - client folder not found
    pause
    exit /b 1
)

echo [OK] Download completed successfully

echo.
echo [4/4] Installing dependencies...
cd /d "%INSTALL_DIR%\client"

if not exist "requirements.txt" (
    echo [ERROR] requirements.txt not found
    pause
    exit /b 1
)

echo [INFO] Installing Python packages...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install some packages
    echo [INFO] You may need to install them manually:
    echo pip install -r requirements.txt
    pause
)

echo.
echo ============================================
echo         INSTALLATION COMPLETED!
echo ============================================
echo.

REM Create startup script
echo [INFO] Creating startup script...
set STARTUP_SCRIPT=%INSTALL_DIR%\start_tenjo.bat
echo @echo off > "%STARTUP_SCRIPT%"
echo cd /d "%INSTALL_DIR%\client" >> "%STARTUP_SCRIPT%"
echo python main.py >> "%STARTUP_SCRIPT%"
echo pause >> "%STARTUP_SCRIPT%"

REM Create uninstaller
echo [INFO] Creating uninstaller...
set UNINSTALLER=%INSTALL_DIR%\uninstall.bat
echo @echo off > "%UNINSTALLER%"
echo echo Stopping Tenjo service... >> "%UNINSTALLER%"
echo taskkill /f /im python.exe ^>nul 2^>^&1 >> "%UNINSTALLER%"
echo timeout /t 3 /nobreak ^>nul >> "%UNINSTALLER%"
echo echo Removing installation... >> "%UNINSTALLER%"
echo rmdir /s /q "%INSTALL_DIR%" >> "%UNINSTALLER%"
echo echo Tenjo uninstalled successfully >> "%UNINSTALLER%"
echo pause >> "%UNINSTALLER%"

echo.
echo ✓ Tenjo installed to: %INSTALL_DIR%
echo ✓ Startup script: %STARTUP_SCRIPT%
echo ✓ Uninstaller: %UNINSTALLER%
echo.
echo NEXT STEPS:
echo 1. Run: "%STARTUP_SCRIPT%"
echo 2. Open dashboard: http://103.129.149.67
echo 3. Your device should appear within 1-2 minutes
echo.
echo AUTO-START SETUP (Optional):
echo To make Tenjo start with Windows:
echo 1. Press Win+R, type: shell:startup
echo 2. Copy "%STARTUP_SCRIPT%" to that folder
echo.

REM Ask if user wants to start now
echo.
set /p START_NOW="Start Tenjo now? (Y/N): "
if /i "%START_NOW%"=="Y" (
    echo [INFO] Starting Tenjo monitoring service...
    start /min "" "%STARTUP_SCRIPT%"
    echo [OK] Service started in background
    echo [INFO] Check dashboard: http://103.129.149.67
)

echo.
echo Installation completed successfully!
echo.
pause