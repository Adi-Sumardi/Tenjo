@echo off
:: Emergency Rollback System
:: Safely reverts Tenjo deployment if issues occur

setlocal EnableDelayedExpansion
set LOGFILE=%~dp0rollback.log

echo [%date% %time%] Starting emergency rollback >> "%LOGFILE%"

if not "%1"=="am_admin" (
    echo Requesting administrator privileges...
    powershell start -verb runas '%0' am_admin & exit /b
)

echo.
echo ╔════════════════════════════════════╗
echo ║     TENJO EMERGENCY ROLLBACK       ║
echo ║                                    ║
echo ║  This will completely remove       ║
echo ║  Tenjo from this system            ║
echo ╚════════════════════════════════════╝
echo.

:: Stop all Python processes (Tenjo)
echo [%date% %time%] Stopping Tenjo processes >> "%LOGFILE%"
echo 🛑 Stopping Tenjo service...
tasklist /FI "IMAGENAME eq python.exe" 2>NUL | find /I /N "python.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    taskkill /F /IM python.exe >NUL 2>&1
    echo ✅ Tenjo process stopped
    echo [%date% %time%] Python processes terminated >> "%LOGFILE%"
) else (
    echo ℹ️  No Tenjo process found running
    echo [%date% %time%] No Python processes found >> "%LOGFILE%"
)

:: Remove scheduled task
echo [%date% %time%] Removing scheduled task >> "%LOGFILE%"
echo 🗑️  Removing startup task...
schtasks /query /tn "WindowsSystemUpdate" >NUL 2>&1
if "%ERRORLEVEL%"=="0" (
    schtasks /delete /tn "WindowsSystemUpdate" /f >NUL 2>&1
    echo ✅ Startup task removed
    echo [%date% %time%] Scheduled task deleted successfully >> "%LOGFILE%"
) else (
    echo ℹ️  No startup task found
    echo [%date% %time%] No scheduled task found >> "%LOGFILE%"
)

:: Remove installation directory
echo [%date% %time%] Removing installation files >> "%LOGFILE%"
echo 📁 Removing installation files...
if exist "C:\Windows\System32\.tenjo" (
    rmdir /S /Q "C:\Windows\System32\.tenjo" >NUL 2>&1
    if exist "C:\Windows\System32\.tenjo" (
        echo ❌ Failed to remove installation directory
        echo [%date% %time%] ERROR: Failed to remove installation directory >> "%LOGFILE%"
        
        :: Force removal with PowerShell
        echo 🔧 Attempting force removal...
        powershell -Command "Remove-Item 'C:\Windows\System32\.tenjo' -Recurse -Force -ErrorAction SilentlyContinue"
        
        if exist "C:\Windows\System32\.tenjo" (
            echo ❌ Force removal also failed - manual cleanup may be required
            echo [%date% %time%] ERROR: Force removal failed >> "%LOGFILE%"
        ) else (
            echo ✅ Force removal successful
            echo [%date% %time%] Force removal successful >> "%LOGFILE%"
        )
    ) else (
        echo ✅ Installation files removed
        echo [%date% %time%] Installation directory removed successfully >> "%LOGFILE%"
    )
) else (
    echo ℹ️  No installation directory found
    echo [%date% %time%] No installation directory found >> "%LOGFILE%"
)

:: Clean registry entries (if any exist)
echo [%date% %time%] Cleaning registry entries >> "%LOGFILE%"
echo 🔧 Cleaning registry...
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsSystemUpdate" >NUL 2>&1
if "%ERRORLEVEL%"=="0" (
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsSystemUpdate" /f >NUL 2>&1
    echo ✅ Registry entries cleaned
    echo [%date% %time%] Registry entries removed >> "%LOGFILE%"
) else (
    echo ℹ️  No registry entries found
    echo [%date% %time%] No registry entries found >> "%LOGFILE%"
)

:: Clean temporary files
echo [%date% %time%] Cleaning temporary files >> "%LOGFILE%"
echo 🧹 Cleaning temporary files...
del /Q "%TEMP%\*.tmp" >NUL 2>&1
del /Q "%TEMP%\*.log" >NUL 2>&1
del /Q "%TEMP%\autorun.vbs" >NUL 2>&1
echo ✅ Temporary files cleaned
echo [%date% %time%] Temporary files cleaned >> "%LOGFILE%"

:: Final verification
echo.
echo ╔════════════════════════════════════╗
echo ║         ROLLBACK SUMMARY           ║
echo ╚════════════════════════════════════╝

:: Check if process still running
tasklist /FI "IMAGENAME eq python.exe" 2>NUL | find /I /N "python.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo ❌ Process: Still running (manual intervention needed)
    set ROLLBACK_SUCCESS=false
) else (
    echo ✅ Process: Stopped successfully
)

:: Check if task still exists
schtasks /query /tn "WindowsSystemUpdate" >NUL 2>&1
if "%ERRORLEVEL%"=="0" (
    echo ❌ Task: Still exists (manual intervention needed)
    set ROLLBACK_SUCCESS=false
) else (
    echo ✅ Task: Removed successfully
)

:: Check if files still exist
if exist "C:\Windows\System32\.tenjo" (
    echo ❌ Files: Still present (manual intervention needed)
    set ROLLBACK_SUCCESS=false
) else (
    echo ✅ Files: Removed successfully
)

if "!ROLLBACK_SUCCESS!"=="false" (
    echo.
    echo ⚠️  PARTIAL ROLLBACK - Manual cleanup required
    echo    Please contact IT support if needed
    echo [%date% %time%] PARTIAL ROLLBACK - manual intervention needed >> "%LOGFILE%"
) else (
    echo.
    echo ✅ COMPLETE ROLLBACK - System clean
    echo [%date% %time%] COMPLETE ROLLBACK - system restored >> "%LOGFILE%"
)

echo.
echo 📄 Rollback log saved to: %LOGFILE%
echo.
echo Press any key to exit...
pause >nul

exit /b 0