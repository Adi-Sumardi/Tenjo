@echo off
setlocal enabledelayedexpansion

REM Tenjo - Employee Monitoring System
REM Robust Windows Installer with Error Handling

echo.
echo ============================================
echo    TENJO - Employee Monitoring System
echo    Windows Installer v2.0
echo ============================================
echo.

REM Set installation directory
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "GITHUB_REPO=https://github.com/Adi-Sumardi/Tenjo.git"
set "TEMP_DIR=%TEMP%\tenjo_install_%RANDOM%"

echo [INFO] Installation directory: %INSTALL_DIR%
echo [INFO] Temporary directory: %TEMP_DIR%
echo.

REM Create temp directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

REM Check if curl is available
curl --version >nul 2>&1
if !errorLevel! neq 0 (
    echo [WARNING] curl not found, using PowerShell for downloads
    set "USE_CURL=0"
) else (
    echo [INFO] Using curl for downloads
    set "USE_CURL=1"
)

REM Check Python installation
echo [1/6] Checking Python installation...
python --version >"%TEMP_DIR%\python_check.txt" 2>&1
if !errorLevel! neq 0 (
    echo [WARNING] Python not found! Downloading Python 3.13...
    
    if !USE_CURL! == 1 (
        curl -L -o "%TEMP_DIR%\python_installer.exe" "https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe" --silent --show-error
    ) else (
        powershell -Command "try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe' -OutFile '%TEMP_DIR%\python_installer.exe' -ErrorAction Stop } catch { exit 1 }"
    )
    
    if exist "%TEMP_DIR%\python_installer.exe" (
        echo [INFO] Installing Python 3.13...
        start /wait "" "%TEMP_DIR%\python_installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
        
        REM Refresh PATH by restarting current session
        call :RefreshEnvironment
        
        REM Check again
        python --version >nul 2>&1
        if !errorLevel! neq 0 (
            echo [ERROR] Python installation failed
            echo [INFO] Please restart Command Prompt and try again
            echo [INFO] Or manually install from: https://www.python.org/downloads/
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
python --version >"%TEMP_DIR%\python_version.txt" 2>&1
set "PYTHON_VERSION=Unknown"
for /f "tokens=2" %%i in ('type "%TEMP_DIR%\python_version.txt"') do set "PYTHON_VERSION=%%i"
echo [OK] Python !PYTHON_VERSION! found

REM Check Git installation
echo.
echo [2/6] Checking Git installation...
git --version >nul 2>&1
if !errorLevel! neq 0 (
    echo [WARNING] Git not found! Downloading Git for Windows...
    
    if !USE_CURL! == 1 (
        curl -L -o "%TEMP_DIR%\git_installer.exe" "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe" --silent --show-error
    ) else (
        powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe' -OutFile '%TEMP_DIR%\git_installer.exe' -ErrorAction Stop } catch { exit 1 }"
    )
    
    if exist "%TEMP_DIR%\git_installer.exe" (
        echo [INFO] Installing Git for Windows...
        start /wait "" "%TEMP_DIR%\git_installer.exe" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
        
        REM Refresh PATH
        call :RefreshEnvironment
        
        REM Check again
        git --version >nul 2>&1
        if !errorLevel! neq 0 (
            echo [ERROR] Git installation failed
            echo [INFO] Please restart Command Prompt and try again
            echo [INFO] Or manually install from: https://git-scm.com/download/win
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
echo [3/6] Preparing installation directory...
if exist "%INSTALL_DIR%" (
    echo [INFO] Removing existing installation...
    taskkill /f /im python.exe 2>nul
    timeout /t 2 /nobreak >nul
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)

REM Clone repository
echo.
echo [4/6] Downloading Tenjo from GitHub...
git clone "%GITHUB_REPO%" "%INSTALL_DIR%"
if !errorLevel! neq 0 (
    echo [ERROR] Failed to download from GitHub
    echo [INFO] Check your internet connection and try again
    pause
    exit /b 1
)
echo [OK] Repository downloaded

REM Install Python dependencies
echo.
echo [5/6] Installing Python dependencies...
cd /d "%INSTALL_DIR%\client"
echo [INFO] Upgrading pip...
python -m pip install --upgrade pip >nul 2>&1
echo [INFO] Installing requirements...
python -m pip install -r requirements.txt >nul 2>&1
if !errorLevel! neq 0 (
    echo [ERROR] Failed to install dependencies
    echo [INFO] Trying without quiet mode for debugging...
    python -m pip install -r requirements.txt
    pause
    exit /b 1
)
echo [OK] Dependencies installed

REM Test installation
echo.
echo [6/6] Testing installation and starting service...
python -c "from src.core.config import Config; print('[TEST] Config loaded successfully')" 2>nul
if !errorLevel! neq 0 (
    echo [ERROR] Installation test failed
    echo [INFO] Testing without import...
    python -c "print('[TEST] Python is working')"
    pause
    exit /b 1
)
echo [OK] Installation test passed

REM Create startup script
set "STARTUP_SCRIPT=%INSTALL_DIR%\start_tenjo.bat"
(
echo @echo off
echo cd /d "%INSTALL_DIR%\client"
echo python main.py
) > "%STARTUP_SCRIPT%"

REM Add to Windows startup
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "STARTUP_LINK=%STARTUP_FOLDER%\Tenjo.bat"

(
echo @echo off
echo start /min "" "%STARTUP_SCRIPT%"
) > "%STARTUP_LINK%"

echo [INFO] Auto-start configured

REM Create uninstaller
set "UNINSTALLER=%INSTALL_DIR%\uninstall.bat"
(
echo @echo off
echo echo Stopping Tenjo service...
echo taskkill /f /im python.exe 2^>nul
echo echo Removing startup entry...
echo del "%STARTUP_LINK%" 2^>nul
echo echo Removing installation directory...
echo rmdir /s /q "%INSTALL_DIR%"
echo echo Tenjo uninstalled successfully
echo pause
) > "%UNINSTALLER%"

REM Start the service
echo [INFO] Starting Tenjo monitoring service...
start /min "" "%STARTUP_SCRIPT%"

REM Cleanup temp files
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul

echo.
echo ============================================
echo         INSTALLATION COMPLETED!
echo ============================================
echo.
echo [✓] Python !PYTHON_VERSION! verified
echo [✓] Git verified
echo [✓] Tenjo installed to: %INSTALL_DIR%
echo [✓] Service started and configured for auto-start
echo [✓] Running in stealth mode
echo.
echo MANAGEMENT:
echo - Dashboard: http://103.129.149.67
echo - Uninstall: Run %INSTALL_DIR%\uninstall.bat
echo - Logs: %INSTALL_DIR%\client\logs\
echo.
echo Your device will appear in the dashboard shortly.
echo.
pause
goto :eof

:RefreshEnvironment
REM Force refresh of environment variables
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "UserPath=%%b"
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SystemPath=%%b"
if defined UserPath if defined SystemPath (
    set "PATH=%UserPath%;%SystemPath%"
) else if defined UserPath (
    set "PATH=%UserPath%"
) else if defined SystemPath (
    set "PATH=%SystemPath%"
)
goto :eof