@echo off
REM Tenjo - Employee Monitoring System
REM One-Script Windows Installer
REM Python 3.13+ Required

echo.
echo ============================================
echo    TENJO - Employee Monitoring System
echo    Windows Production Installer
echo ============================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] Running with administrator privileges
) else (
    echo [INFO] Running with user privileges
)

REM Set installation directory
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "GITHUB_REPO=https://github.com/Adi-Sumardi/Tenjo.git"

echo [INFO] Installation directory: %INSTALL_DIR%
echo.

REM Check Python installation
echo [1/7] Checking Python 3.13+ installation...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Python not found! Please install Python 3.13+ first
    echo [INFO] Download from: https://www.python.org/downloads/
    echo [INFO] Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

REM Get Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%i"
echo [OK] Python %PYTHON_VERSION% found

REM Check Python version (basic check for 3.x)
echo %PYTHON_VERSION% | findstr "^3\." >nul
if %errorLevel% neq 0 (
    echo [ERROR] Python 3.x required, found %PYTHON_VERSION%
    pause
    exit /b 1
)

REM Check Git installation
echo.
echo [2/7] Checking Git installation...
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Git not found! Please install Git for Windows first
    echo [INFO] Download from: https://git-scm.com/download/win
    pause
    exit /b 1
)
echo [OK] Git found

REM Remove existing installation
echo.
echo [3/7] Preparing installation directory...
if exist "%INSTALL_DIR%" (
    echo [INFO] Removing existing installation...
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)

REM Clone repository
echo.
echo [4/7] Downloading Tenjo from GitHub...
git clone "%GITHUB_REPO%" "%INSTALL_DIR%"
if %errorLevel% neq 0 (
    echo [ERROR] Failed to download from GitHub
    pause
    exit /b 1
)
echo [OK] Repository downloaded

REM Install Python dependencies
echo.
echo [5/7] Installing Python dependencies...
cd /d "%INSTALL_DIR%\client"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed

REM Test installation
echo.
echo [6/7] Testing installation...
python -c "from src.core.config import Config; print('Config loaded successfully')" 2>nul
if %errorLevel% neq 0 (
    echo [ERROR] Installation test failed
    pause
    exit /b 1
)
echo [OK] Installation test passed

REM Create startup script
echo.
echo [7/7] Setting up auto-start...
set "STARTUP_SCRIPT=%INSTALL_DIR%\start_tenjo.bat"
echo @echo off > "%STARTUP_SCRIPT%"
echo cd /d "%INSTALL_DIR%\client" >> "%STARTUP_SCRIPT%"
echo python main.py >> "%STARTUP_SCRIPT%"

REM Add to Windows startup (user startup folder)
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "STARTUP_LINK=%STARTUP_FOLDER%\Tenjo.bat"

echo @echo off > "%STARTUP_LINK%"
echo start /min "" "%STARTUP_SCRIPT%" >> "%STARTUP_LINK%"

echo [OK] Auto-start configured

REM Create uninstaller
echo.
echo [INFO] Creating uninstaller...
set "UNINSTALLER=%INSTALL_DIR%\uninstall.bat"
echo @echo off > "%UNINSTALLER%"
echo echo Uninstalling Tenjo... >> "%UNINSTALLER%"
echo taskkill /f /im python.exe 2^>nul >> "%UNINSTALLER%"
echo del "%STARTUP_LINK%" 2^>nul >> "%UNINSTALLER%"
echo rmdir /s /q "%INSTALL_DIR%" >> "%UNINSTALLER%"
echo echo Tenjo uninstalled successfully >> "%UNINSTALLER%"
echo pause >> "%UNINSTALLER%"

REM Start the service
echo.
echo [INFO] Starting Tenjo monitoring service...
start /min "" "%STARTUP_SCRIPT%"

echo.
echo ============================================
echo         INSTALLATION COMPLETED!
echo ============================================
echo.
echo [✓] Tenjo installed to: %INSTALL_DIR%
echo [✓] Service started and will auto-start on boot
echo [✓] Running in stealth mode (minimized)
echo.
echo MANAGEMENT:
echo - Stop service: Close from Task Manager
echo - Uninstall: Run %INSTALL_DIR%\uninstall.bat
echo - Logs: %INSTALL_DIR%\client\logs\
echo.
echo Dashboard: http://103.129.149.67
echo.
echo Installation completed successfully!
echo.
pause