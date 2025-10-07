@echo off
REM Enable Remote Access (RDP, SMB, WinRM) on Windows Client
REM Run as Administrator!

echo ========================================
echo  TENJO - ENABLE REMOTE ACCESS
echo ========================================
echo.
echo This will enable:
echo   - Remote Desktop (RDP)
echo   - File Sharing (SMB)
echo   - Remote PowerShell (WinRM)
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run as Administrator!
    echo Right-click and select "Run as Administrator"
    pause
    exit /b 1
)

echo [OK] Running with Administrator privileges
echo.

REM ========================================
REM Enable Remote Desktop (RDP)
REM ========================================
echo [1/3] Enabling Remote Desktop...

REM Enable RDP in registry
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1

REM Enable RDP through firewall
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul 2>&1

REM Enable Network Level Authentication (more secure)
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f >nul 2>&1

echo   [OK] RDP enabled on port 3389

REM ========================================
REM Enable File Sharing (SMB)
REM ========================================
echo [2/3] Enabling File Sharing...

REM Enable File and Printer Sharing
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1

REM Enable Network Discovery
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1

REM Enable SMB1 (if needed for older systems)
REM sc config lanmanworkstation start= auto >nul 2>&1
REM sc start lanmanworkstation >nul 2>&1

REM Enable admin shares (C$, D$, etc)
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /t REG_DWORD /d 1 /f >nul 2>&1

echo   [OK] SMB enabled on port 445

REM ========================================
REM Enable WinRM (Remote PowerShell)
REM ========================================
echo [3/3] Enabling WinRM...

REM Enable WinRM service
sc config winrm start= auto >nul 2>&1
net start winrm >nul 2>&1

REM Configure WinRM
winrm quickconfig -q >nul 2>&1
winrm set winrm/config/service/auth @{Basic="true"} >nul 2>&1
winrm set winrm/config/service @{AllowUnencrypted="true"} >nul 2>&1
winrm set winrm/config/winrs @{MaxMemoryPerShellMB="1024"} >nul 2>&1

REM Enable WinRM through firewall
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=Yes >nul 2>&1

echo   [OK] WinRM enabled on ports 5985/5986

REM ========================================
REM Summary
REM ========================================
echo.
echo ========================================
echo  REMOTE ACCESS ENABLED!
echo ========================================
echo.

REM Get computer info
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do set LOCAL_IP=%%a
set LOCAL_IP=%LOCAL_IP:~1%

echo Computer Name: %COMPUTERNAME%
echo IP Address:    %LOCAL_IP%
echo.
echo You can now access this PC remotely via:
echo.
echo   [RDP]   Remote Desktop:
echo           open rdp://%LOCAL_IP%
echo           or: mstsc /v:%LOCAL_IP%
echo.
echo   [SMB]   File Sharing:
echo           \\%LOCAL_IP%\C$
echo           smb://%LOCAL_IP%/C$
echo.
echo   [WinRM] PowerShell:
echo           Invoke-Command -ComputerName %LOCAL_IP% -ScriptBlock { ... }
echo.

REM ========================================
REM Save info to file
REM ========================================
set INFO_FILE=C:\ProgramData\Tenjo\remote_access_info.txt

echo REMOTE ACCESS INFORMATION > "%INFO_FILE%"
echo Date: %DATE% %TIME% >> "%INFO_FILE%"
echo Computer: %COMPUTERNAME% >> "%INFO_FILE%"
echo IP: %LOCAL_IP% >> "%INFO_FILE%"
echo. >> "%INFO_FILE%"
echo Services Enabled: >> "%INFO_FILE%"
echo   - RDP (3389) >> "%INFO_FILE%"
echo   - SMB (445) >> "%INFO_FILE%"
echo   - WinRM (5985/5986) >> "%INFO_FILE%"

echo [OK] Info saved to: %INFO_FILE%
echo.

REM ========================================
REM Optional: Restart services
REM ========================================
echo Restarting services...

net stop TermService >nul 2>&1
net start TermService >nul 2>&1

net stop LanmanServer >nul 2>&1
net start LanmanServer >nul 2>&1

echo   [OK] Services restarted
echo.

REM ========================================
REM Test connectivity
REM ========================================
echo Testing connectivity...
echo.

REM Test RDP port
netstat -an | findstr ":3389" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] RDP listening on port 3389
) else (
    echo   [WARNING] RDP may not be ready
)

REM Test SMB port
netstat -an | findstr ":445" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] SMB listening on port 445
) else (
    echo   [WARNING] SMB may not be ready
)

REM Test WinRM port
netstat -an | findstr ":5985" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] WinRM listening on port 5985
) else (
    echo   [WARNING] WinRM may not be ready
)

echo.
echo ========================================
echo  DONE!
echo ========================================
echo.
echo Next time you can update remotely from your Mac:
echo.
echo   Option 1: RDP (Remote Desktop)
echo   - Install Microsoft Remote Desktop from Mac App Store
echo   - Connect to: %LOCAL_IP%
echo   - Run update commands manually
echo.
echo   Option 2: SMB (File Copy)
echo   - Finder -^> Go -^> Connect to Server
echo   - Enter: smb://%LOCAL_IP%/C$
echo   - Copy update files to C:\ProgramData\Tenjo
echo.
echo   Option 3: WinRM (Automatic)
echo   - Use mass_update_clients.ps1 script
echo   - Updates all clients automatically
echo.

echo Press any key to exit...
pause >nul
