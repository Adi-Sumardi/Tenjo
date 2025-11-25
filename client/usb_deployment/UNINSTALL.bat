@echo off
:: Microsoft Office 365 Sync Service Uninstaller

title Microsoft Office 365 Uninstaller
color 0C

echo.
echo ========================================
echo   Microsoft Office 365 Sync Service
echo   Uninstaller
echo ========================================
echo.
echo WARNING: This will completely remove the sync service
echo.
set /p CONFIRM="Type YES to confirm uninstallation: "

if /I not "%CONFIRM%"=="YES" (
    echo.
    echo Uninstallation cancelled
    pause
    exit /b 0
)

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] This uninstaller requires Administrator privileges
    echo Right-click on UNINSTALL.bat and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

:: Try to read install path from saved location
set INSTALL_DIR=
if exist "%TEMP%\office365_path.txt" (
    set /p INSTALL_DIR=<"%TEMP%\office365_path.txt"
)

:: Fallback to scanning for installation
if "%INSTALL_DIR%"=="" (
    for /d %%i in ("C:\ProgramData\Microsoft\Office365Sync_*") do (
        set INSTALL_DIR=%%i
        goto :found_dir
    )
    :: Final fallback
    set INSTALL_DIR=C:\ProgramData\Microsoft Office 365
)
:found_dir

set STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

echo.
echo [1/4] Stopping sync service...
:: Stop Windows Service first
sc stop "Office365Sync" >nul 2>&1
timeout /t 2 /nobreak >nul
sc delete "Office365Sync" >nul 2>&1

:: Stop processes
taskkill /F /IM OfficeSync.exe >nul 2>&1
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM pythonw.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/4] Removing Windows Defender exclusions...
powershell -Command "Remove-MpPreference -ExclusionPath '%INSTALL_DIR%'" 2>nul
powershell -Command "Remove-MpPreference -ExclusionProcess 'OfficeSync.exe'" 2>nul
powershell -Command "Remove-MpPreference -ExclusionProcess 'pythonw.exe'" 2>nul

echo [3/4] Removing files...
:: Unhide before deleting
attrib -h -s "%INSTALL_DIR%" 2>nul
if exist "%INSTALL_DIR%" (
    rmdir /S /Q "%INSTALL_DIR%"
    echo     Removed: %INSTALL_DIR%
)

:: Unhide and remove startup shortcut
attrib -h "%STARTUP_DIR%\OfficeSync.lnk" 2>nul
if exist "%STARTUP_DIR%\OfficeSync.lnk" (
    del /Q "%STARTUP_DIR%\OfficeSync.lnk"
    echo     Removed: Startup shortcut
)

:: Clean up temp file
if exist "%TEMP%\office365_path.txt" (
    del /Q "%TEMP%\office365_path.txt"
)

echo [4/4] Cleanup complete

echo.
echo ========================================
echo   Uninstallation Complete
echo ========================================
echo.
echo Microsoft Office 365 Sync Service removed
echo.
pause
