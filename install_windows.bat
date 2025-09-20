@echo off
REM Tenjo - Employee Monitoring System
REM Complete Windows Installer with Auto-Dependencies
REM Automatically installs Python 3.13+ and Git if needed

echo.
echo ============================================
echo    TENJO - Employee Monitoring System
echo    Complete Windows Installer
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
set "TEMP_DIR=%TEMP%\tenjo_install"

echo [INFO] Installation directory: %INSTALL_DIR%
echo [INFO] Temporary directory: %TEMP_DIR%
echo.

REM Create temp directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

REM Check and install Python
echo [1/8] Checking Python 3.13+ installation...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Python not found! Attempting to install...
    echo [INFO] Downloading Python 3.13...
    
    REM Download Python installer
    powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe' -OutFile '%TEMP_DIR%\python_installer.exe'"
    
    if exist "%TEMP_DIR%\python_installer.exe" (
        echo [INFO] Installing Python 3.13 (this may take a few minutes)...
        "%TEMP_DIR%\python_installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
        
        REM Wait for installation
        timeout /t 30 /nobreak >nul
        
        REM Refresh PATH
        call :RefreshPath
        
        REM Check again
        python --version >nul 2>&1
        if %errorLevel% neq 0 (
            echo [ERROR] Python installation failed or not in PATH
            echo [INFO] Please manually install Python 3.13+ from https://www.python.org/
            echo [INFO] Make sure to check "Add Python to PATH" during installation
            pause
            exit /b 1
        )
    ) else (
        echo [ERROR] Failed to download Python installer
        echo [INFO] Please manually install Python 3.13+ from https://www.python.org/
        pause
        exit /b 1
    )
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

REM Check and install Git
echo.
echo [2/8] Checking Git installation...
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Git not found! Attempting to install...
    echo [INFO] Downloading Git for Windows...
    
    REM Download Git installer
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe' -OutFile '%TEMP_DIR%\git_installer.exe'"
    
    if exist "%TEMP_DIR%\git_installer.exe" (
        echo [INFO] Installing Git (this may take a few minutes)...
        "%TEMP_DIR%\git_installer.exe" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
        
        REM Wait for installation
        timeout /t 45 /nobreak >nul
        
        REM Refresh PATH
        call :RefreshPath
        
        REM Check again
        git --version >nul 2>&1
        if %errorLevel% neq 0 (
            echo [ERROR] Git installation failed or not in PATH
            echo [INFO] Please manually install Git from https://git-scm.com/download/win
            pause
            exit /b 1
        )
    ) else (
        echo [ERROR] Failed to download Git installer
        echo [INFO] Please manually install Git from https://git-scm.com/download/win
        pause
        exit /b 1
    )
)
echo [OK] Git found

REM Remove existing installation
echo.
echo [3/8] Preparing installation directory...
if exist "%INSTALL_DIR%" (
    echo [INFO] Removing existing installation...
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)

REM Clone repository
echo.
echo [4/8] Downloading Tenjo from GitHub...
git clone "%GITHUB_REPO%" "%INSTALL_DIR%"
if %errorLevel% neq 0 (
    echo [ERROR] Failed to download from GitHub
    echo [INFO] Check your internet connection and try again
    pause
    exit /b 1
)
echo [OK] Repository downloaded

REM Install Python dependencies
echo.
echo [5/8] Installing Python dependencies...
cd /d "%INSTALL_DIR%\client"
python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt --quiet
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install dependencies
    echo [INFO] Check your internet connection and Python installation
    pause
    exit /b 1
)
echo [OK] Dependencies installed

REM Test installation
echo.
echo [6/8] Testing installation...
python -c "from src.core.config import Config; print('Config loaded successfully')" 2>nul
if %errorLevel% neq 0 (
    echo [ERROR] Installation test failed
    echo [INFO] Check the installation logs for details
    pause
    exit /b 1
)
echo [OK] Installation test passed

REM Create startup script
echo.
echo [7/8] Setting up auto-start...
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
echo [8/8] Creating uninstaller and starting service...
set "UNINSTALLER=%INSTALL_DIR%\uninstall.bat"
echo @echo off > "%UNINSTALLER%"
echo echo Uninstalling Tenjo... >> "%UNINSTALLER%"
echo taskkill /f /im python.exe 2^>nul >> "%UNINSTALLER%"
echo del "%STARTUP_LINK%" 2^>nul >> "%UNINSTALLER%"
echo rmdir /s /q "%INSTALL_DIR%" >> "%UNINSTALLER%"
echo echo Tenjo uninstalled successfully >> "%UNINSTALLER%"
echo pause >> "%UNINSTALLER%"

REM Cleanup temp files
if exist "%TEMP_DIR%" (
    rmdir /s /q "%TEMP_DIR%" 2>nul
)

REM Start the service
echo [INFO] Starting Tenjo monitoring service...
start /min "" "%STARTUP_SCRIPT%"

echo.
echo ============================================
echo         INSTALLATION COMPLETED!
echo ============================================
echo.
echo [✓] Python %PYTHON_VERSION% installed/verified
echo [✓] Git installed/verified
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
echo Your device will appear in the dashboard shortly.
echo.
pause
goto :eof

:RefreshPath
REM Refresh environment variables
for /f "skip=2 tokens=3*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "UserPath=%%a %%b"
for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SystemPath=%%a %%b"
set "PATH=%UserPath%;%SystemPath%"
goto :eof