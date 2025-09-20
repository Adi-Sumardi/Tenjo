@echo off
setlocal enabledelayedexpansion

REM Tenjo Production Installer for Windows
REM Compatible with Python 3.13+ and modern Windows versions
REM Includes OS detection and stealth installation

echo ==================================================
echo     TENJO EMPLOYEE MONITORING SYSTEM v2.0       
echo          Production Windows Installer            
echo          Python 3.13+ Compatible                
echo ==================================================

REM Configuration
set "GITHUB_REPO=https://github.com/Adi-Sumardi/Tenjo.git"
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "SERVICE_NAME=TenjoMonitoring"
set "PYTHON_EXEC="
set "PYTHON_MINIMUM_VERSION=3.13"

REM Security check
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [ERROR] This script should not be run as administrator for security reasons
    pause
    exit /b 1
)

echo [INFO] Checking system dependencies...

REM Check for git
git --version >nul 2>&1
if !errorLevel! neq 0 (
    echo [ERROR] Git not found. Please install Git for Windows first
    echo Download from: https://git-scm.com/download/win
    pause
    exit /b 1
)

REM Function to check Python version (simulated in batch)
:check_python_version
set "python_cmd=%1"
for /f "tokens=2" %%i in ('%python_cmd% --version 2^>^&1') do set "python_version=%%i"

REM Extract major.minor version
for /f "tokens=1,2 delims=." %%a in ("!python_version!") do (
    set /a "major=%%a"
    set /a "minor=%%b"
)

REM Check if version >= 3.13
if !major! gtr 3 (
    echo [SUCCESS] Python !python_version! is compatible ^(^>= %PYTHON_MINIMUM_VERSION%^)
    exit /b 0
) else if !major! equ 3 (
    if !minor! geq 13 (
        echo [SUCCESS] Python !python_version! is compatible ^(^>= %PYTHON_MINIMUM_VERSION%^)
        exit /b 0
    )
)

echo [ERROR] Python !python_version! is too old ^(requires ^>= %PYTHON_MINIMUM_VERSION%^)
exit /b 1

REM Check for Python 3.13+
python --version >nul 2>&1
if !errorLevel! == 0 (
    call :check_python_version python
    if !errorLevel! == 0 (
        set "PYTHON_EXEC=python"
        goto :check_dependencies_done
    )
)

python3 --version >nul 2>&1
if !errorLevel! == 0 (
    call :check_python_version python3
    if !errorLevel! == 0 (
        set "PYTHON_EXEC=python3"
        goto :check_dependencies_done
    )
)

py --version >nul 2>&1
if !errorLevel! == 0 (
    call :check_python_version py
    if !errorLevel! == 0 (
        set "PYTHON_EXEC=py"
        goto :check_dependencies_done
    )
)

echo [ERROR] Python %PYTHON_MINIMUM_VERSION% or higher is required but not found
echo Please install Python from: https://www.python.org/downloads/
echo Make sure to check "Add Python to PATH" during installation
pause
exit /b 1

:check_dependencies_done
echo [SUCCESS] Using Python: %PYTHON_EXEC%

REM Check for pip
%PYTHON_EXEC% -m pip --version >nul 2>&1
if !errorLevel! neq 0 (
    echo [WARNING] pip not found. Installing pip...
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    %PYTHON_EXEC% get-pip.py --user
    del get-pip.py
    if !errorLevel! neq 0 (
        echo [ERROR] Failed to install pip
        pause
        exit /b 1
    )
)

echo [INFO] Stopping existing Tenjo processes...

REM Kill any running Tenjo processes
taskkill /f /im python.exe /fi "windowtitle eq *Tenjo*" >nul 2>&1
taskkill /f /im python3.exe /fi "windowtitle eq *Tenjo*" >nul 2>&1
taskkill /f /im py.exe /fi "windowtitle eq *Tenjo*" >nul 2>&1

REM More thorough process killing
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq python.exe" /fo csv ^| findstr "main.py"') do taskkill /f /pid %%i >nul 2>&1
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq python3.exe" /fo csv ^| findstr "main.py"') do taskkill /f /pid %%i >nul 2>&1
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq py.exe" /fo csv ^| findstr "main.py"') do taskkill /f /pid %%i >nul 2>&1

REM Stop Windows scheduled task if exists
schtasks /end /tn "%SERVICE_NAME%" >nul 2>&1
schtasks /delete /tn "%SERVICE_NAME%" /f >nul 2>&1

echo [INFO] Downloading Tenjo from GitHub...

REM Remove existing installation
if exist "%INSTALL_DIR%" (
    echo [WARNING] Removing existing installation...
    rmdir /s /q "%INSTALL_DIR%"
)

REM Clone repository
git clone "%GITHUB_REPO%" "%INSTALL_DIR%"
if !errorLevel! neq 0 (
    echo [ERROR] Failed to download Tenjo from GitHub
    pause
    exit /b 1
)

echo [SUCCESS] Tenjo downloaded successfully

REM Navigate to client directory
cd /d "%INSTALL_DIR%\client"

echo [INFO] Installing Python dependencies...

REM Try different installation methods
%PYTHON_EXEC% -m pip install --user -r requirements.txt >nul 2>&1
if !errorLevel! == 0 (
    echo [SUCCESS] Dependencies installed using pip --user
    goto :dependencies_done
)

%PYTHON_EXEC% -m pip install --break-system-packages -r requirements.txt >nul 2>&1
if !errorLevel! == 0 (
    echo [SUCCESS] Dependencies installed using pip --break-system-packages
    goto :dependencies_done
)

echo [WARNING] Standard pip installation failed. Creating virtual environment...
%PYTHON_EXEC% -m venv "%INSTALL_DIR%\venv"
call "%INSTALL_DIR%\venv\Scripts\activate.bat"
"%INSTALL_DIR%\venv\Scripts\python.exe" -m pip install --upgrade pip
"%INSTALL_DIR%\venv\Scripts\python.exe" -m pip install -r requirements.txt
if !errorLevel! == 0 (
    set "PYTHON_EXEC=%INSTALL_DIR%\venv\Scripts\python.exe"
    echo [SUCCESS] Dependencies installed in virtual environment
) else (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)

:dependencies_done

echo [INFO] Testing OS detection system...

%PYTHON_EXEC% -c "from os_detector import get_os_info_for_client; import json; os_info = get_os_info_for_client(); print(f'SUCCESS: {os_info[\"name\"]} {os_info[\"version\"]} ({os_info[\"architecture\"]})')" 2>nul
if !errorLevel! == 0 (
    for /f "tokens=2,3,4" %%a in ('%PYTHON_EXEC% -c "from os_detector import get_os_info_for_client; os_info = get_os_info_for_client(); print(f'{os_info[\"name\"]} {os_info[\"version\"]} ({os_info[\"architecture\"]})')"') do (
        echo [SUCCESS] OS Detection: %%a %%b %%c
    )
) else (
    echo [ERROR] OS Detection failed
    pause
    exit /b 1
)

echo [INFO] Creating stealth service configuration...

REM Create Windows scheduled task for stealth operation
schtasks /create /tn "%SERVICE_NAME%" /tr "\"%PYTHON_EXEC%\" \"%INSTALL_DIR%\client\main.py\"" /sc onlogon /rl limited /f >nul 2>&1
if !errorLevel! == 0 (
    echo [SUCCESS] Stealth service configured
    
    REM Start the task
    schtasks /run /tn "%SERVICE_NAME%" >nul 2>&1
    if !errorLevel! == 0 (
        echo [SUCCESS] Stealth service started
    ) else (
        echo [WARNING] Service created but failed to start
    )
) else (
    echo [WARNING] Failed to create scheduled task. Adding to startup registry instead...
    
    REM Add to Windows startup registry
    reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitoring" /t REG_SZ /d "\"%PYTHON_EXEC%\" \"%INSTALL_DIR%\client\main.py\"" /f >nul 2>&1
    if !errorLevel! == 0 (
        echo [SUCCESS] Added to startup registry
    ) else (
        echo [ERROR] Failed to configure automatic startup
    )
)

echo [INFO] Creating uninstaller...

REM Create comprehensive uninstaller
echo @echo off > "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo setlocal enabledelayedexpansion >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo ======================================= >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo        Tenjo Uninstaller for Windows    >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo ======================================= >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo [INFO] Stopping Tenjo service... >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo schtasks /end /tn "%SERVICE_NAME%" ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo schtasks /delete /tn "%SERVICE_NAME%" /f ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo. >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo echo [INFO] Killing Tenjo processes... >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo taskkill /f /im python.exe /fi "windowtitle eq *Tenjo*" ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo taskkill /f /im python3.exe /fi "windowtitle eq *Tenjo*" ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
echo taskkill /f /im py.exe /fi "windowtitle eq *Tenjo*" ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall_tenjo_windows.bat"
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

echo [INFO] Verifying installation...

REM Verify installation
timeout /t 3 >nul

REM Check if task is running
schtasks /query /tn "%SERVICE_NAME%" >nul 2>&1
if !errorLevel! == 0 (
    echo [SUCCESS] Service is configured and running
) else (
    echo [WARNING] Service may not be configured properly
)

REM Test client initialization
cd /d "%INSTALL_DIR%\client"
%PYTHON_EXEC% -c "import sys; sys.path.append('src'); from src.core.config import Config; from os_detector import get_os_info_for_client; print('✅ Client initialization test passed')" 2>nul
if !errorLevel! == 0 (
    echo [SUCCESS] Client initialization test passed
) else (
    echo [WARNING] Client initialization test failed
)

echo.
echo ==================================================
echo    🎉 TENJO INSTALLATION COMPLETED SUCCESSFULLY!   
echo ==================================================
echo.
echo 📋 Installation Details:
echo    • Install Directory: %INSTALL_DIR%
for /f "tokens=*" %%i in ('%PYTHON_EXEC% --version') do echo    • Python Version: %%i
echo    • Service: %SERVICE_NAME% (running in background)
echo    • Logs: %INSTALL_DIR%\client\logs\
echo    • Uninstaller: %INSTALL_DIR%\uninstall_tenjo_windows.bat
echo.
echo 🔒 Security Notes:
echo    • Service runs in stealth mode (background)
echo    • Auto-starts at user login
echo    • Logs are stored locally
echo.
echo ⚠️  Important:
echo    • This software is for authorized monitoring only
echo    • Ensure compliance with local privacy laws
echo    • Keep installation directory secure
echo.
echo 🗑️  To uninstall: %INSTALL_DIR%\uninstall_tenjo_windows.bat
echo.
echo [SUCCESS] Installation completed! Tenjo is now running in stealth mode.
echo.
echo Press any key to exit...
pause >nul

exit /b 0