@echo off

REM Tenjo Remote Installer for Windows
REM One-liner installer that downloads and installs from GitHub

REM Usage: Download and run this file, or use PowerShell:
REM powershell -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install.bat' -OutFile 'install.bat'; .\install.bat}"

echo ======================================
echo    TENJO EMPLOYEE MONITORING SYSTEM   
echo         Remote Auto Installer        
echo ======================================
echo.

set "GITHUB_RAW=https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master"
set "TEMP_DIR=%TEMP%\tenjo_installer"

echo [INFO] Creating temporary directory...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
cd /d "%TEMP_DIR%"

echo [INFO] Downloading installer from GitHub...

REM Check if curl is available
curl --version >nul 2>&1
if !errorLevel! == 0 (
    curl -sSL "%GITHUB_RAW%/auto_install_windows.bat" -o installer.bat
) else (
    REM Fallback to PowerShell
    powershell -Command "Invoke-WebRequest -Uri '%GITHUB_RAW%/auto_install_windows.bat' -OutFile 'installer.bat'"
)

if not exist "installer.bat" (
    echo [ERROR] Failed to download installer
    pause
    exit /b 1
)

echo [INFO] Running installer...
call installer.bat

echo [INFO] Cleaning up...
cd /d "%USERPROFILE%"
rmdir /s /q "%TEMP_DIR%"

echo [SUCCESS] Remote installation completed!
pause
