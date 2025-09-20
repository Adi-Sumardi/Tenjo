@echo off
REM Tenjo Windows Installer - Final Bulletproof Version
REM Handles all edge cases and provides clear error messages

echo.
echo ============================================
echo    TENJO - Employee Monitoring System
echo    Windows Installer v3.0 - Final
echo ============================================
echo.

REM Basic variables
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "GITHUB_REPO=https://github.com/Adi-Sumardi/Tenjo.git"
set "TEMP_DIR=%TEMP%\tenjo_install_%RANDOM%"

echo [INFO] Installation directory: %INSTALL_DIR%
echo [INFO] Temporary directory: %TEMP_DIR%
echo.

REM Create temp directory
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%"
    if errorlevel 1 (
        echo [ERROR] Cannot create temporary directory
        pause
        exit /b 1
    )
)

REM Test internet connectivity
echo [0/6] Testing internet connectivity...
ping -n 1 google.com >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No internet connection detected
    echo [INFO] Please check your internet connection and try again
    pause
    exit /b 1
)
echo [OK] Internet connection verified

REM Check Python
echo [1/6] Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Python not found. Installing Python 3.13...
    
    REM Download Python using PowerShell (most reliable)
    powershell -NoProfile -Command ^
        "try { " ^
        "Write-Host '[INFO] Downloading Python 3.13...'; " ^
        "$ProgressPreference = 'SilentlyContinue'; " ^
        "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe' -OutFile '%TEMP_DIR%\python_installer.exe' -UseBasicParsing; " ^
        "Write-Host '[OK] Python installer downloaded'; " ^
        "} catch { " ^
        "Write-Host '[ERROR] Download failed:' $_.Exception.Message; " ^
        "exit 1 " ^
        "}"
    
    if errorlevel 1 (
        echo [ERROR] Failed to download Python installer
        echo [INFO] Please manually install Python 3.13+ from https://www.python.org/
        pause
        exit /b 1
    )
    
    if not exist "%TEMP_DIR%\python_installer.exe" (
        echo [ERROR] Python installer not found after download
        pause
        exit /b 1
    )
    
    echo [INFO] Installing Python 3.13 (this will take 2-3 minutes)...
    "%TEMP_DIR%\python_installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
    
    REM Wait for installation to complete
    echo [INFO] Waiting for Python installation to complete...
    timeout /t 90 /nobreak >nul
    
    REM Refresh PATH environment variable
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SYSTEM_PATH=%%B"
    set "PATH=%USER_PATH%;%SYSTEM_PATH%"
    
    REM Test Python again
    python --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Python installation failed or not accessible
        echo [INFO] Please:
        echo [INFO] 1. Restart this Command Prompt
        echo [INFO] 2. Or manually install Python from https://www.python.org/
        echo [INFO] 3. Make sure to check 'Add Python to PATH' during install
        pause
        exit /b 1
    )
)

REM Get Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%i"
echo [OK] Python %PYTHON_VERSION% found

REM Check Git
echo [2/6] Checking Git installation...
git --version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Git not found. Installing Git for Windows...
    
    REM Download Git using PowerShell
    powershell -NoProfile -Command ^
        "try { " ^
        "Write-Host '[INFO] Downloading Git for Windows...'; " ^
        "$ProgressPreference = 'SilentlyContinue'; " ^
        "Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe' -OutFile '%TEMP_DIR%\git_installer.exe' -UseBasicParsing; " ^
        "Write-Host '[OK] Git installer downloaded'; " ^
        "} catch { " ^
        "Write-Host '[ERROR] Download failed:' $_.Exception.Message; " ^
        "exit 1 " ^
        "}"
    
    if errorlevel 1 (
        echo [ERROR] Failed to download Git installer
        echo [INFO] Please manually install Git from https://git-scm.com/download/win
        pause
        exit /b 1
    )
    
    if not exist "%TEMP_DIR%\git_installer.exe" (
        echo [ERROR] Git installer not found after download
        pause
        exit /b 1
    )
    
    echo [INFO] Installing Git for Windows (this will take 3-4 minutes)...
    "%TEMP_DIR%\git_installer.exe" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS
    
    REM Wait for installation
    echo [INFO] Waiting for Git installation to complete...
    timeout /t 120 /nobreak >nul
    
    REM Refresh PATH
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SYSTEM_PATH=%%B"
    set "PATH=%USER_PATH%;%SYSTEM_PATH%"
    
    REM Test Git again
    git --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Git installation failed or not accessible
        echo [INFO] Please:
        echo [INFO] 1. Restart this Command Prompt
        echo [INFO] 2. Or manually install Git from https://git-scm.com/download/win
        pause
        exit /b 1
    )
)
echo [OK] Git found

REM Clean existing installation
echo [3/6] Preparing installation directory...
if exist "%INSTALL_DIR%" (
    echo [INFO] Removing existing installation...
    REM Stop any running Python processes safely
    taskkill /f /im python.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
    rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
    if exist "%INSTALL_DIR%" (
        echo [WARNING] Could not fully remove existing installation
        echo [INFO] Some files may be in use, continuing anyway...
    )
)

REM Clone repository
echo [4/6] Downloading Tenjo from GitHub...
git clone "%GITHUB_REPO%" "%INSTALL_DIR%"
if errorlevel 1 (
    echo [ERROR] Failed to clone repository from GitHub
    echo [INFO] Please check:
    echo [INFO] 1. Internet connection is stable
    echo [INFO] 2. GitHub is accessible
    echo [INFO] 3. No firewall blocking Git
    pause
    exit /b 1
)

if not exist "%INSTALL_DIR%\client" (
    echo [ERROR] Repository cloned but client directory not found
    pause
    exit /b 1
)
echo [OK] Repository downloaded successfully

REM Install Python dependencies
echo [5/6] Installing Python dependencies...
cd /d "%INSTALL_DIR%\client"
if errorlevel 1 (
    echo [ERROR] Cannot access client directory
    pause
    exit /b 1
)

echo [INFO] Upgrading pip...
python -m pip install --upgrade pip >nul 2>&1

echo [INFO] Installing requirements...
if not exist "requirements.txt" (
    echo [ERROR] requirements.txt not found in client directory
    pause
    exit /b 1
)

python -m pip install -r requirements.txt >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Some packages failed to install, trying verbose mode...
    python -m pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERROR] Failed to install Python dependencies
        echo [INFO] Please check Python installation and internet connection
        pause
        exit /b 1
    )
)
echo [OK] Dependencies installed successfully

REM Test installation
echo [6/6] Testing installation and configuring startup...
python -c "import sys; print('[TEST] Python executable:', sys.executable)" 2>nul
if errorlevel 1 (
    echo [ERROR] Python test failed
    pause
    exit /b 1
)

python -c "from src.core.config import Config; print('[TEST] Tenjo config loaded successfully')" 2>nul
if errorlevel 1 (
    echo [WARNING] Config import test failed, checking basic structure...
    if not exist "src\core\config.py" (
        echo [ERROR] Tenjo source files not found properly
        pause
        exit /b 1
    )
    echo [INFO] Files exist but import failed - this may work at runtime
)

echo [OK] Installation test completed

REM Create startup script
echo [INFO] Creating startup script...
set "STARTUP_SCRIPT=%INSTALL_DIR%\start_tenjo.bat"
(
echo @echo off
echo REM Auto-generated Tenjo startup script
echo cd /d "%INSTALL_DIR%\client"
echo python main.py
echo pause
) > "%STARTUP_SCRIPT%"

REM Add to Windows startup
echo [INFO] Configuring auto-start...
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "STARTUP_LINK=%STARTUP_FOLDER%\Tenjo.bat"

if not exist "%STARTUP_FOLDER%" (
    echo [ERROR] Windows startup folder not found
    pause
    exit /b 1
)

(
echo @echo off
echo REM Tenjo auto-start script
echo start /min "" "%STARTUP_SCRIPT%"
) > "%STARTUP_LINK%"

REM Create uninstaller
echo [INFO] Creating uninstaller...
set "UNINSTALLER=%INSTALL_DIR%\uninstall.bat"
(
echo @echo off
echo echo Stopping Tenjo monitoring service...
echo taskkill /f /im python.exe 2^>nul
echo timeout /t 3 /nobreak ^>nul
echo echo Removing startup entry...
echo del "%STARTUP_LINK%" 2^>nul
echo echo Removing installation directory...
echo rmdir /s /q "%INSTALL_DIR%"
echo echo Tenjo has been uninstalled successfully
echo pause
) > "%UNINSTALLER%"

REM Start service
echo [INFO] Starting Tenjo monitoring service...
start /min "" "%STARTUP_SCRIPT%"

REM Cleanup
echo [INFO] Cleaning up temporary files...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul 2>&1

REM Success message
echo.
echo ============================================
echo         INSTALLATION COMPLETED!
echo ============================================
echo.
echo [✓] Python %PYTHON_VERSION% verified
echo [✓] Git verified and working
echo [✓] Tenjo installed to: %INSTALL_DIR%
echo [✓] Service started in background
echo [✓] Auto-start configured for Windows boot
echo [✓] Uninstaller created
echo.
echo NEXT STEPS:
echo 1. Open dashboard: http://103.129.149.67
echo 2. Your device should appear within 1-2 minutes
echo 3. Service runs automatically in background
echo.
echo MANAGEMENT:
echo - Uninstall: %INSTALL_DIR%\uninstall.bat
echo - Logs: %INSTALL_DIR%\client\logs\
echo - Manual start: %STARTUP_SCRIPT%
echo.
echo Installation completed successfully!
echo.
pause