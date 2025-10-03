@echo off
echo Verifying Tenjo deployment...

:: Check if service is running
tasklist /FI "IMAGENAME eq python.exe" 2>NUL | find /I /N "python.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo ✅ Tenjo service is running
) else (
    echo ❌ Tenjo service not found
)

:: Check installation directory
if exist "C:\Windows\System32\.tenjo\main.py" (
    echo ✅ Installation files found
) else (
    echo ❌ Installation files missing
)

:: Check scheduled task
schtasks /query /tn "WindowsSystemUpdate" >NUL 2>&1
if "%ERRORLEVEL%"=="0" (
    echo ✅ Startup task configured
) else (
    echo ❌ Startup task missing
)

pause
