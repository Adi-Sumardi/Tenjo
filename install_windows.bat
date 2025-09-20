@echo off
REM Tenjo Windows Batch Installer
REM Employee Monitoring System - Clean Installation Script

setlocal enabledelayedexpansion

cls
echo.
echo ============================================
echo    TENJO - Employee Monitoring System
echo    Windows Batch Installer v1.0
echo ============================================
echo.

REM Configuration
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "GITHUB_REPO=https://github.com/Adi-Sumardi/Tenjo.git"
set "TEMP_DIR=%TEMP%\tenjo_install_%RANDOM%"

echo [INFO] Installation directory: !INSTALL_DIR!
echo [INFO] Temporary directory: !TEMP_DIR!
echo.

REM Create temp directory
echo [0/6] Preparing installation environment...
if exist "!TEMP_DIR!" rmdir /s /q "!TEMP_DIR!" >nul 2>&1
mkdir "!TEMP_DIR!" >nul 2>&1
echo [OK] Temporary directory created

REM Test internet connection
echo.
echo [1/6] Testing internet connectivity...
ping -n 1 google.com >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Internet connection verified
) else (
    echo [ERROR] No internet connection detected
    echo [INFO] Please check your connection and try again
    goto :error_exit
)

REM Check Python
echo.
echo [2/6] Checking Python installation...
python --version >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%i"
    echo [OK] Python found: !PYTHON_VERSION!
) else (
    echo [WARNING] Python not found. Installing Python 3.13...
    
    set "PYTHON_URL=https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe"
    set "PYTHON_INSTALLER=!TEMP_DIR!\python_installer.exe"
    
    echo [INFO] Downloading Python 3.13 installer...
    powershell -Command "try { Invoke-WebRequest -Uri '!PYTHON_URL!' -OutFile '!PYTHON_INSTALLER!' -UseBasicParsing -TimeoutSec 300; if (Test-Path '!PYTHON_INSTALLER!') { exit 0 } else { exit 1 } } catch { exit 1 }"
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to download Python installer
        goto :error_exit
    )
    echo [OK] Python installer downloaded successfully
    
    echo [INFO] Installing Python 3.13 ^(this may take 3-5 minutes^)...
    "!PYTHON_INSTALLER!" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
    if !errorlevel! neq 0 (
        echo [ERROR] Python installation failed
        goto :error_exit
    )
    
    REM Wait and refresh environment
    timeout /t 10 /nobreak >nul
    call :refresh_environment
    
    REM Verify Python installation
    python --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Python installation completed but python command not found
        echo [INFO] Please restart Command Prompt and try again
        goto :error_exit
    )
    
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%i"
    echo [OK] Python installed successfully: !PYTHON_VERSION!
)

REM Check Git
echo.
echo [3/6] Checking Git installation...
git --version >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('git --version 2^>^&1') do set "GIT_VERSION=%%i"
    echo [OK] Git found: !GIT_VERSION!
) else (
    echo [WARNING] Git not found. Installing Git for Windows...
    
    set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
    set "GIT_INSTALLER=!TEMP_DIR!\git_installer.exe"
    
    echo [INFO] Downloading Git for Windows installer...
    powershell -Command "try { Invoke-WebRequest -Uri '!GIT_URL!' -OutFile '!GIT_INSTALLER!' -UseBasicParsing -TimeoutSec 300; if (Test-Path '!GIT_INSTALLER!') { exit 0 } else { exit 1 } } catch { exit 1 }"
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to download Git installer
        goto :error_exit
    )
    echo [OK] Git installer downloaded successfully
    
    echo [INFO] Installing Git for Windows ^(this may take 3-5 minutes^)...
    "!GIT_INSTALLER!" /VERYSILENT /NORESTART /NOCANCEL /SP-
    if !errorlevel! neq 0 (
        echo [ERROR] Git installation failed
        goto :error_exit
    )
    
    REM Wait and refresh environment
    timeout /t 10 /nobreak >nul
    call :refresh_environment
    
    REM Verify Git installation
    git --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Git installation completed but git command not found
        echo [INFO] Please restart Command Prompt and try again
        goto :error_exit
    )
    
    for /f "tokens=*" %%i in ('git --version 2^>^&1') do set "GIT_VERSION=%%i"
    echo [OK] Git installed successfully: !GIT_VERSION!
)

REM Clean existing installation
echo.
echo [4/6] Preparing installation directory...
if exist "!INSTALL_DIR!" (
    echo [INFO] Removing existing installation...
    taskkill /f /im python.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    rmdir /s /q "!INSTALL_DIR!" >nul 2>&1
)
echo [OK] Installation directory prepared

REM Clone repository
echo.
echo [5/6] Downloading Tenjo from GitHub...

REM Try normal clone first
git clone "!GITHUB_REPO!" "!INSTALL_DIR!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [WARNING] Standard clone failed, trying alternative methods...
    
    REM Try shallow clone
    git clone --depth 1 "!GITHUB_REPO!" "!INSTALL_DIR!" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [WARNING] Shallow clone failed, trying ZIP download...
        
        REM Try ZIP download
        set "ZIP_URL=https://github.com/Adi-Sumardi/Tenjo/archive/refs/heads/master.zip"
        set "ZIP_FILE=!TEMP_DIR!\tenjo-master.zip"
        
        powershell -Command "try { Invoke-WebRequest -Uri '!ZIP_URL!' -OutFile '!ZIP_FILE!' -UseBasicParsing; if (Test-Path '!ZIP_FILE!') { exit 0 } else { exit 1 } } catch { exit 1 }"
        if !errorlevel! equ 0 (
            echo [INFO] ZIP downloaded, extracting...
            powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('!ZIP_FILE!', '!TEMP_DIR!')"
            
            REM Move extracted folder
            if exist "!TEMP_DIR!\Tenjo-master" (
                move "!TEMP_DIR!\Tenjo-master" "!INSTALL_DIR!" >nul 2>&1
                if !errorlevel! equ 0 (
                    echo [OK] Downloaded via ZIP method
                ) else (
                    echo [ERROR] Failed to move extracted files
                    goto :error_exit
                )
            ) else (
                echo [ERROR] ZIP extraction failed
                goto :error_exit
            )
        ) else (
            echo [ERROR] All download methods failed
            echo [INFO] Please check your internet connection and GitHub access
            goto :error_exit
        )
    ) else (
        echo [OK] Shallow clone successful
    )
) else (
    echo [OK] Repository cloned successfully
)

if not exist "!INSTALL_DIR!\client" (
    echo [ERROR] Repository downloaded but client directory not found
    goto :error_exit
)

REM Install Python dependencies
echo.
echo [6/6] Installing Python dependencies...
cd /d "!INSTALL_DIR!\client"

if not exist "requirements.txt" (
    echo [ERROR] requirements.txt not found in client directory
    goto :error_exit
)

echo [INFO] Upgrading pip...
python -m pip install --upgrade pip >nul 2>&1

echo [INFO] Installing requirements...
python -m pip install -r requirements.txt >nul 2>&1
if !errorlevel! neq 0 (
    echo [WARNING] Some packages failed to install, trying again...
    python -m pip install -r requirements.txt
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to install Python dependencies
        goto :error_exit
    )
)
echo [OK] Dependencies installed successfully

REM Test installation
echo.
echo [INFO] Testing installation...
python -c "import sys; print('Python executable:', sys.executable)" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Python test failed
    goto :error_exit
)

REM Create startup script
echo [INFO] Creating startup script...
set "STARTUP_SCRIPT=!INSTALL_DIR!\start_tenjo.bat"
(
    echo @echo off
    echo cd /d "!INSTALL_DIR!\client"
    echo python main.py
    echo pause
) > "!STARTUP_SCRIPT!"

REM Add to Windows startup
echo [INFO] Configuring auto-start...
for /f "tokens=*" %%i in ('powershell -Command "[Environment]::GetFolderPath('Startup')"') do set "STARTUP_FOLDER=%%i"
set "STARTUP_LINK=!STARTUP_FOLDER!\Tenjo.bat"
(
    echo @echo off
    echo start /min "" "!STARTUP_SCRIPT!"
) > "!STARTUP_LINK!"

REM Create uninstaller
echo [INFO] Creating uninstaller...
set "UNINSTALLER=!INSTALL_DIR!\uninstall.bat"
(
    echo @echo off
    echo echo Stopping Tenjo monitoring service...
    echo taskkill /f /im python.exe ^>nul 2^>^&1
    echo timeout /t 3 /nobreak ^>nul
    echo echo Removing startup entry...
    echo del "!STARTUP_LINK!" ^>nul 2^>^&1
    echo echo Removing installation directory...
    echo rmdir /s /q "!INSTALL_DIR!"
    echo echo Tenjo has been uninstalled successfully
    echo pause
) > "!UNINSTALLER!"

REM Start service
echo [INFO] Starting Tenjo monitoring service...
start /min "" "!STARTUP_SCRIPT!"

REM Cleanup
echo [INFO] Cleaning up temporary files...
rmdir /s /q "!TEMP_DIR!" >nul 2>&1

REM Success message
echo.
echo ============================================
echo         INSTALLATION COMPLETED!
echo ============================================
echo.
echo Installation Details:
echo - Python: Verified and working
echo - Git: Verified and working
echo - Tenjo installed to: !INSTALL_DIR!
echo - Service started in background
echo - Auto-start configured for Windows boot
echo - Uninstaller created
echo.
echo Next Steps:
echo 1. Open dashboard: http://103.129.149.67
echo 2. Your device should appear within 1-2 minutes
echo 3. Service runs automatically in background
echo.
echo Management:
echo - Uninstall: !INSTALL_DIR!\uninstall.bat
echo - Logs: !INSTALL_DIR!\client\logs\
echo - Manual start: !STARTUP_SCRIPT!
echo.
echo Installation completed successfully!
goto :end

:refresh_environment
REM Refresh environment variables
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do set "MACHINE_PATH=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%b"
if defined USER_PATH (
    set "PATH=!MACHINE_PATH!;!USER_PATH!"
) else (
    set "PATH=!MACHINE_PATH!"
)
goto :eof

:error_exit
echo.
echo ============================================
echo         INSTALLATION FAILED!
echo ============================================
echo.
echo Manual Installation Steps:
echo 1. Install Python 3.13+ from: https://www.python.org/downloads/
echo 2. Install Git from: https://git-scm.com/download/win
echo 3. Restart Command Prompt as Administrator
echo 4. Run this installer again
echo.
echo For support, visit: https://github.com/Adi-Sumardi/Tenjo
echo.
if exist "!TEMP_DIR!" rmdir /s /q "!TEMP_DIR!" >nul 2>&1

:end
echo.
echo Press any key to continue...
pause >nul