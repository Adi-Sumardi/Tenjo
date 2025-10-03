@echo off
:: Emergency cleanup script - removes all Tenjo traces
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

echo Removing Tenjo installation...

:: Stop processes
taskkill /F /IM python.exe >NUL 2>&1

:: Remove scheduled task
schtasks /delete /tn "WindowsSystemUpdate" /f >NUL 2>&1

:: Remove installation
rmdir /S /Q "C:\Windows\System32\.tenjo" >NUL 2>&1

:: Clean registry (if any)
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsSystemUpdate" /f >NUL 2>&1

echo Cleanup completed.
pause
