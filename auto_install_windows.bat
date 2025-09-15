@echo off
setlocal enabledelayedexpansion

REM Tenjo Auto Installer for Windows
REM Downloads from GitHub and installs automatically

echo ======================================
echo    TENJO EMPLOYEE MONITORING SYSTEM   
echo          Windows Auto Installer       
echo ======================================

REM Configuration
set "GITHUB_REPO=https://github.com/Adi-Sumardi/Tenjo.git"
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "SERVICE_NAME=TenjoMonitoring"
set "PYTHON_EXEC="

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [ERROR] This script should not be run as administrator for security reasons
    pause
    exit /b 1
)

echo [INFO] Checking dependencies...

REM Check for git
git --version >nul 2>&1
if !errorLevel! neq 0 (
    echo [WARNING] Git not found. Please install Git for Windows manually
    echo Download from: https://git-scm.com/download/win
    pause
    exit /b 1
)

REM Check for Python 3
python --version >nul 2>&1
if !errorLevel! == 0 (
    for /f "tokens=2" %%i in ('python --version') do set PYTHON_VERSION=%%i
    echo !PYTHON_VERSION! | findstr /C:"3." >nul
    if !errorLevel! == 0 (
        set "PYTHON_EXEC=python"
        echo [SUCCESS] Python 3 found: !PYTHON_VERSION!
    ) else (
        echo [ERROR] Python 3 is required but Python 2 found
        goto install_python
    )
) else (
    python3 --version >nul 2>&1
    if !errorLevel! == 0 (
        set "PYTHON_EXEC=python3"
        echo [SUCCESS] Python 3 found
    ) else (
        goto install_python
    )
)

goto check_pip

:install_python
echo [ERROR] Python 3 is required but not found
echo Please install Python 3 from: https://www.python.org/downloads/
pause
exit /b 1

:check_pip
REM Check for pip
%PYTHON_EXEC% -m pip --version >nul 2>&1
if !errorLevel! neq 0 (
    echo [WARNING] pip not found. Installing pip...
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    %PYTHON_EXEC% get-pip.py --user
    del get-pip.py
)

echo [INFO] Stopping existing Tenjo processes...

REM Kill any running Tenjo processes
taskkill /f /im python.exe /fi "windowtitle eq Tenjo*" >nul 2>&1
taskkill /f /im python3.exe /fi "windowtitle eq Tenjo*" >nul 2>&1
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq python.exe" /fo csv ^| findstr "main.py"') do taskkill /f /pid %%i >nul 2>&1
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq python3.exe" /fo csv ^| findstr "main.py"') do taskkill /f /pid %%i >nul 2>&1

REM Stop Windows service if exists
sc query "%SERVICE_NAME%" >nul 2>&1
if !errorLevel! == 0 (
    echo [INFO] Stopping existing service...
    sc stop "%SERVICE_NAME%" >nul 2>&1
    sc delete "%SERVICE_NAME%" >nul 2>&1
)

echo [INFO] Downloading Tenjo from GitHub...

REM Remove existing installation
if exist "%INSTALL_DIR%" (
    echo [WARNING] Removing existing installation...
    rmdir /s /q "%INSTALL_DIR%"
)

REM Create install directory
mkdir "%INSTALL_DIR%"

REM Clone repository
git clone "%GITHUB_REPO%" "%INSTALL_DIR%"
if !errorLevel! neq 0 (
    echo [ERROR] Failed to download Tenjo from GitHub
    pause
    exit /b 1
)

echo [SUCCESS] Tenjo downloaded successfully

echo [INFO] Installing Python dependencies...
cd /d "%INSTALL_DIR%\client"

REM Install requirements
%PYTHON_EXEC% -m pip install --user -r requirements.txt
if !errorLevel! neq 0 (
    echo [ERROR] Failed to install Python dependencies
    pause
    exit /b 1
)

echo [SUCCESS] Dependencies installed

echo [INFO] Creating autostart registry entry...

REM Create startup registry entry
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitoring" /t REG_SZ /d "\"%PYTHON_EXEC%\" \"%INSTALL_DIR%\client\main.py\"" /f >nul 2>&1

echo [SUCCESS] Autostart configured

echo [INFO] Creating Windows service...

REM Create service wrapper script
echo @echo off > "%INSTALL_DIR%\tenjo_service.bat"
echo cd /d "%INSTALL_DIR%\client" >> "%INSTALL_DIR%\tenjo_service.bat"
echo %PYTHON_EXEC% main.py >> "%INSTALL_DIR%\tenjo_service.bat"

REM Install as Windows service using NSSM (if available) or Task Scheduler
schtasks /create /tn "TenjoMonitoring" /tr "\"%INSTALL_DIR%\tenjo_service.bat\"" /sc onlogon /ru "%USERNAME%" /f >nul 2>&1
if !errorLevel! == 0 (
    echo [SUCCESS] Service created using Task Scheduler
) else (
    echo [WARNING] Could not create scheduled task, using registry startup only
)

echo [INFO] Starting Tenjo monitoring service...

REM Create logs directory
mkdir "%INSTALL_DIR%\client\logs" >nul 2>&1

REM Start the service using Task Scheduler
schtasks /run /tn "TenjoMonitoring" >nul 2>&1

REM Wait for service to start
timeout /t 3 >nul

echo [SUCCESS] Tenjo service started

echo [INFO] Creating uninstaller...

REM Create uninstaller script
echo @echo off > "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo setlocal enabledelayedexpansion >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo ====================================== >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo       TENJO UNINSTALLER - Windows     >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo ====================================== >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo [INFO] Stopping Tenjo service... >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo schtasks /end /tn "TenjoMonitoring" ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo schtasks /delete /tn "TenjoMonitoring" /f ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo [INFO] Killing Tenjo processes... >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo taskkill /f /im python.exe /fi "windowtitle eq Tenjo*" ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo taskkill /f /im python3.exe /fi "windowtitle eq Tenjo*" ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo [INFO] Removing registry entries... >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitoring" /f ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo [INFO] Removing Tenjo files... >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo timeout /t 2 ^>nul >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo cd /d "%%USERPROFILE%%" >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo rmdir /s /q "%INSTALL_DIR%" >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo [SUCCESS] Tenjo has been completely removed from your system. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo pause >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"

echo [SUCCESS] Uninstaller created at: %INSTALL_DIR%\uninstall_tenjo_windows.bat

echo.
echo ======================================
echo [SUCCESS] TENJO INSTALLATION COMPLETED!
echo ======================================
echo.
echo [INFO] Installation Details:
echo   • Install Directory: %INSTALL_DIR%
echo   • Logs Directory: %INSTALL_DIR%\client\logs
echo   • Uninstaller: %INSTALL_DIR%\uninstall_tenjo_windows.bat
echo.
echo [INFO] Service Status:
schtasks /query /tn "TenjoMonitoring" >nul 2>&1
if !errorLevel! == 0 (
    echo   ✅ Service is configured and running in background ^(stealth mode^)
) else (
    echo   ❌ Service is not configured properly
)
echo.
echo [WARNING] IMPORTANT NOTES:
echo   • This software is for authorized monitoring only
echo   • Ensure compliance with local privacy laws
echo   • The service runs automatically at system startup
echo.
echo [INFO] To uninstall: %INSTALL_DIR%\uninstall_tenjo_windows.bat
echo.

echo [SUCCESS] Installation completed successfully!
echo.
echo Press any key to exit...
pause >nul
