#!/bin/bash
# Create USB Installer Package for Fresh Tenjo Installation
# This creates a complete installer that works offline

set -e

echo "========================================"
echo "🔧 TENJO USB INSTALLER CREATOR"
echo "========================================"
echo ""

# Configuration
INSTALLER_DIR="$HOME/Desktop/tenjo_usb_installer"
PRODUCTION_URL="https://tenjo.adilabs.id"
LATEST_VERSION="1.0.2"

# Clean up old installer
if [ -d "$INSTALLER_DIR" ]; then
    echo "🗑️  Removing old installer package..."
    rm -rf "$INSTALLER_DIR"
fi

# Create directory structure
echo "📁 Creating installer directory structure..."
mkdir -p "$INSTALLER_DIR"
mkdir -p "$INSTALLER_DIR/client"
mkdir -p "$INSTALLER_DIR/python_installer"

# Download latest client package
echo "📥 Downloading latest Tenjo client v${LATEST_VERSION}..."
curl -s -L -o "$INSTALLER_DIR/client/tenjo_client_${LATEST_VERSION}.tar.gz" \
    "${PRODUCTION_URL}/downloads/client/tenjo_client_${LATEST_VERSION}.tar.gz"

if [ $? -eq 0 ]; then
    echo "   ✅ Client package downloaded ($(du -h "$INSTALLER_DIR/client/tenjo_client_${LATEST_VERSION}.tar.gz" | cut -f1))"
else
    echo "   ❌ Failed to download client package"
    echo "   Using local files instead..."
fi

# Create Windows installer batch script  
echo "📝 Creating Windows installer script (no reboot version)..."
cat > "$INSTALLER_DIR/INSTALL_TENJO.bat" << 'BAT_EOF'
@echo off
echo ========================================
echo    TENJO CLIENT - AUTOMATED INSTALLER
echo    (No Reboot Required!)
echo ========================================
echo.
echo This will install Tenjo monitoring client
echo Location: C:\ProgramData\Tenjo
echo.

REM Check Administrator privileges
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
REM Step 1: Check Python
REM ========================================
echo [1/7] Checking Python installation...

python --version >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] Python is installed
    python --version
) else (
    echo   [WARNING] Python not found!
    echo.
    echo   Please install Python first:
    echo   1. Run: python_installer\python-3.12.x.exe
    echo   2. Check "Add Python to PATH"
    echo   3. Re-run this installer
    echo.
    pause
    exit /b 1
)

echo.

REM ========================================
REM Step 2: Create installation directory
REM ========================================
echo [2/7] Creating installation directory...

set INSTALL_DIR=C:\ProgramData\Tenjo

if exist "%INSTALL_DIR%" (
    echo   [WARNING] Tenjo already installed at %INSTALL_DIR%
    echo.
    choice /C YN /M "Reinstall/Update existing installation"
    if errorlevel 2 exit /b 0
    echo.
    echo   [INFO] Stopping existing Tenjo service...
    sc stop TenjoMonitor >nul 2>&1
    timeout /t 2 >nul
)

mkdir "%INSTALL_DIR%" 2>nul
echo   [OK] Installation directory ready

echo.

REM ========================================
REM Step 3: Extract client files
REM ========================================
echo [3/7] Extracting Tenjo client files...

cd /d "%~dp0"

REM Check if tar command exists (Windows 10+)
where tar >nul 2>&1
if %errorLevel% equ 0 (
    echo   [INFO] Using Windows tar...
    tar -xzf "client\tenjo_client_1.0.2.tar.gz" -C "%INSTALL_DIR%"
    if %errorLevel% neq 0 (
        echo   [ERROR] Failed to extract files
        pause
        exit /b 1
    )
) else (
    echo   [INFO] Extracting manually...
    REM Fallback: Use PowerShell
    powershell -Command "Expand-Archive -Path 'client\tenjo_client_1.0.2.tar.gz' -DestinationPath '%INSTALL_DIR%' -Force"
)

echo   [OK] Files extracted successfully

echo.

REM ========================================
REM Step 4: Install Python dependencies
REM ========================================
echo [4/7] Installing Python dependencies...

cd /d "%INSTALL_DIR%"

if exist "requirements.txt" (
    python -m pip install --upgrade pip >nul 2>&1
    python -m pip install -r requirements.txt --quiet
    if %errorLevel% equ 0 (
        echo   [OK] Dependencies installed
    ) else (
        echo   [WARNING] Some dependencies failed to install
        echo   [INFO] Client may still work with existing packages
    )
) else (
    echo   [WARNING] requirements.txt not found
)

echo.

REM ========================================
REM Step 5: Configure server URL
REM ========================================
echo [5/7] Configuring server connection...

echo.
echo [5/8] Configuring production server...
:: Create server override config
(
echo {
echo     "server_url": "https://tenjo.adilabs.id",
echo     "api_endpoint": "/api",
echo     "update_interval": 60
echo }
) > "%TENJO_DIR%\server_override.json"

:: Update config.py if exists (CORRECT PATH: src/core/config.py)
if exist "%TENJO_DIR%\src\core\config.py" (
    powershell -Command "(Get-Content '%TENJO_DIR%\src\core\config.py') -replace 'http://127.0.0.1:8000', 'https://tenjo.adilabs.id' | Set-Content '%TENJO_DIR%\src\core\config.py'"
    powershell -Command "(Get-Content '%TENJO_DIR%\src\core\config.py') -replace 'http://localhost:8000', 'https://tenjo.adilabs.id' | Set-Content '%TENJO_DIR%\src\core\config.py'"
    powershell -Command "(Get-Content '%TENJO_DIR%\src\core\config.py') -replace 'DEFAULT_SERVER_URL = os.getenv\([^)]+\)', 'DEFAULT_SERVER_URL = os.getenv(\"TENJO_SERVER_URL\", \"https://tenjo.adilabs.id\")' | Set-Content '%TENJO_DIR%\src\core\config.py'"
    echo     ✓ Config.py updated
) else (
    echo     ! Warning: config.py not found at expected location
)
echo     ✓ Server configured: https://tenjo.adilabs.id

echo.

REM ========================================
REM Step 6: Install Windows service
REM ========================================
echo [6/7] Installing Windows service...

REM Create service wrapper script
echo @echo off > "%INSTALL_DIR%\run_client.bat"
echo cd /d "%INSTALL_DIR%" >> "%INSTALL_DIR%\run_client.bat"
echo python main.py >> "%INSTALL_DIR%\run_client.bat"

REM Install as Windows service using Task Scheduler (more reliable than sc)
schtasks /Create /TN "TenjoMonitor" /TR "%INSTALL_DIR%\run_client.bat" /SC ONLOGON /RL HIGHEST /F >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] Service installed (TenjoMonitor)
) else (
    echo   [WARNING] Failed to install service
)

REM Also create startup entry
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitor" /t REG_SZ /d "%INSTALL_DIR%\run_client.bat" /f >nul 2>&1

echo   [OK] Auto-start configured

echo.

echo.
echo [7/8] Starting Tenjo service...
:: Create logs directory
if not exist "%TENJO_DIR%\logs" mkdir "%TENJO_DIR%\logs"

:: Try scheduled task first
schtasks /Run /TN "TenjoMonitor" >nul 2>&1
if %errorLevel% equ 0 (
    echo     ✓ Started via scheduled task
) else (
    :: Fallback: start with PowerShell for proper working directory
    powershell -Command "Start-Process -FilePath 'pythonw.exe' -ArgumentList 'main.py' -WorkingDirectory '%TENJO_DIR%' -WindowStyle Hidden" >nul 2>&1
    echo     ✓ Started directly with proper working directory
)

echo.
echo [8/8] Verifying installation...
timeout /t 3 /nobreak >nul
tasklist /FI "IMAGENAME eq pythonw.exe" 2>NUL | find /I /N "pythonw.exe">NUL
if %errorLevel% equ 0 (
    echo     ✓ Tenjo is running!
) else (
    tasklist /FI "IMAGENAME eq python.exe" 2>NUL | find /I /N "python.exe">NUL
    if %errorLevel% equ 0 (
        echo     ✓ Tenjo is running!
    ) else (
        echo     ⚠ Warning: Could not verify Tenjo process
        echo     The service may start on next login
    )
)

echo.
echo ========================================
echo    ✅ INSTALLATION COMPLETE!
echo ========================================
echo.
echo ✓ Tenjo installed to: %TENJO_DIR%
echo ✓ Server: https://tenjo.adilabs.id
echo ✓ Service started (no reboot needed!)
echo ✓ Auto-start enabled (runs on login)
echo.
echo The client should appear in dashboard within 1-2 minutes.
echo.
echo To uninstall: Run UNINSTALL_TENJO.bat from this USB
echo.
pause
BAT_EOF

echo "   ✅ INSTALL_TENJO.bat created"

# Create uninstaller
echo "📝 Creating uninstaller script..."
cat > "$INSTALLER_DIR/UNINSTALL_TENJO.bat" << 'UNINSTALL_EOF'
@echo off
REM Tenjo Client - Uninstaller

echo ========================================
echo  TENJO CLIENT UNINSTALLER
echo ========================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run as Administrator!
    pause
    exit /b 1
)

echo WARNING: This will completely remove Tenjo from this PC.
echo.
choice /C YN /M "Continue with uninstallation"
if errorlevel 2 exit /b 0

echo.
echo [1/4] Stopping service...
schtasks /End /TN "TenjoMonitor" >nul 2>&1
timeout /t 2 >nul
echo   [OK] Service stopped

echo.
echo [2/4] Removing service...
schtasks /Delete /TN "TenjoMonitor" /F >nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitor" /f >nul 2>&1
echo   [OK] Service removed

echo.
echo [3/4] Removing files...
rmdir /S /Q "C:\ProgramData\Tenjo" >nul 2>&1
echo   [OK] Files removed

echo.
echo [4/4] Cleaning up...
echo   [OK] Cleanup complete

echo.
echo ========================================
echo  UNINSTALLATION COMPLETE
echo ========================================
echo.
echo Tenjo has been removed from this PC.
echo.
pause
UNINSTALL_EOF

echo "   ✅ UNINSTALL_TENJO.bat created"

# Create comprehensive README
echo "📝 Creating installation guide..."
cat > "$INSTALLER_DIR/README.txt" << 'README_EOF'
========================================
TENJO CLIENT - USB INSTALLER PACKAGE
========================================

This USB package installs Tenjo monitoring client on Windows PCs.

========================================
📋 WHAT'S INCLUDED
========================================

✅ INSTALL_TENJO.bat
   → Main installer (REQUIRED)
   → Installs client to C:\ProgramData\Tenjo
   → Runtime: ~2 minutes

✅ UNINSTALL_TENJO.bat
   → Uninstaller (if needed)
   → Completely removes Tenjo from PC

✅ client/tenjo_client_1.0.2.tar.gz
   → Latest Tenjo client package (27 MB)
   → Complete with all dependencies

✅ python_installer/
   → Python installers (download separately)
   → Required if Python not installed

✅ README.txt
   → This file

========================================
⚡ QUICK START
========================================

For each PC to install:

STEP 1: Plug USB into PC

STEP 2: Double-click "INSTALL_TENJO.bat"
        (Right-click → Run as Administrator)

STEP 3: Follow on-screen prompts

STEP 4: Reboot PC when prompted

STEP 5: Verify in dashboard:
        https://tenjo.adilabs.id/

========================================
📋 REQUIREMENTS
========================================

✅ Windows 10/11 (64-bit)
✅ Python 3.10+ installed
✅ Administrator privileges
✅ Internet connection (for pip packages)
✅ ~100 MB free disk space

If Python not installed:
  1. Download from: https://www.python.org/downloads/
  2. Or use installer in python_installer/ folder
  3. Check "Add Python to PATH" during install
  4. Restart CMD and verify: python --version

========================================
🔧 WHAT IT DOES
========================================

The installer will:
  1. Check Python installation
  2. Create C:\ProgramData\Tenjo directory
  3. Extract client files
  4. Install Python dependencies (mss, psutil, etc)
  5. Configure server URL (https://tenjo.adilabs.id)
  6. Install Windows service (TenjoMonitor)
  7. Configure auto-start on boot
  8. Start the client

After installation:
  ✅ Client runs in stealth mode (no visible windows)
  ✅ Auto-starts on system boot
  ✅ Sends heartbeat every 5 minutes
  ✅ Streams screen when requested
  ✅ Takes screenshots every 1 minute
  ✅ Tracks browser activity

========================================
✅ EXPECTED RESULTS
========================================

After installation:
  ✅ PC appears in dashboard within 5 minutes
  ✅ Status shows ONLINE
  ✅ Version shows 1.0.2
  ✅ Streaming becomes available
  ✅ Screenshots start appearing

Dashboard: https://tenjo.adilabs.id/

========================================
⚠️ TROUBLESHOOTING
========================================

Error: "Python not found"
→ Install Python first
→ Add Python to PATH
→ Restart CMD and try again

Error: "Permission denied"
→ Right-click → Run as Administrator
→ Wait for UAC prompt

Error: "Failed to extract files"
→ Check USB drive has files
→ Verify tar command available (Windows 10+)
→ Try manual extraction

Client doesn't show in dashboard:
→ Wait 5-10 minutes
→ Check internet connection
→ Verify Windows Firewall allows Python
→ Check logs: C:\ProgramData\Tenjo\logs\

Service not starting:
→ Reboot PC
→ Check Task Scheduler → TenjoMonitor
→ Run manually: C:\ProgramData\Tenjo\run_client.bat
→ Check Python path in environment variables

========================================
📂 INSTALLATION DETAILS
========================================

Install Location:
  C:\ProgramData\Tenjo\

Service Name:
  TenjoMonitor

Auto-start Method:
  - Task Scheduler (ONLOGON trigger)
  - Registry Run key (backup)

Configuration:
  C:\ProgramData\Tenjo\src\core\config.py
  C:\ProgramData\Tenjo\server_override.json

Logs:
  C:\ProgramData\Tenjo\logs\client.log

Installation Info:
  C:\ProgramData\Tenjo\install_info.txt

========================================
🗑️ UNINSTALLATION
========================================

To remove Tenjo:

OPTION 1: Use uninstaller
  1. Double-click UNINSTALL_TENJO.bat
  2. Run as Administrator
  3. Confirm when prompted

OPTION 2: Manual removal
  1. Stop service: schtasks /End /TN "TenjoMonitor"
  2. Remove service: schtasks /Delete /TN "TenjoMonitor" /F
  3. Delete folder: rmdir /S /Q "C:\ProgramData\Tenjo"
  4. Remove registry: reg delete "HKLM\...\Run" /v "TenjoMonitor" /f

========================================
🔍 VERIFICATION
========================================

After installation, verify:

1. Check Process:
   tasklist | findstr python
   → Should show python.exe running

2. Check Service:
   schtasks /Query /TN "TenjoMonitor"
   → Should show "Ready" or "Running"

3. Check Files:
   dir C:\ProgramData\Tenjo
   → Should show main.py, src/, logs/

4. Check Config:
   type C:\ProgramData\Tenjo\src\core\config.py | findstr SERVER_URL
   → Should show: https://tenjo.adilabs.id

5. Check Dashboard:
   Open: https://tenjo.adilabs.id/
   → PC should appear in client list within 5 minutes

========================================
⏱️ INSTALLATION TIME
========================================

Per PC:
  - Check Python: 10 seconds
  - Extract files: 30 seconds
  - Install dependencies: 60 seconds
  - Configure & start: 20 seconds
  TOTAL: ~2 minutes

All PCs:
  - 1 PC: 2 minutes
  - 5 PCs: 10 minutes
  - 10 PCs: 20 minutes
  - 17 PCs: 35 minutes

========================================
🎯 BEST PRACTICES
========================================

✅ Test on 1 PC first before mass deployment
✅ Ensure Python installed beforehand
✅ Use Administrator account
✅ Connect PCs to internet during install
✅ Reboot PC after installation
✅ Verify dashboard after each 5 PCs
✅ Keep USB installer for future deployments
✅ Document installed PCs (IP, hostname, date)

========================================
📊 CLIENT IP LIST
========================================

Track your installations:

Subnet 192.168.1.x:
  □ 192.168.1.2
  □ 192.168.1.26
  □ 192.168.1.21
  □ 192.168.1.25
  □ 192.168.1.29
  □ 192.168.1.8
  □ 192.168.1.27
  □ 192.168.1.22
  □ 192.168.1.38
  □ 192.168.1.30
  □ 192.168.1.32
  □ 192.168.1.18

Subnet 192.168.100.x:
  □ 192.168.100.165
  □ 192.168.100.216
  □ 192.168.100.178
  □ 192.168.100.158
  □ 192.168.100.159

Total: 17 PCs

========================================
📞 SUPPORT
========================================

Dashboard: https://tenjo.adilabs.id/
Admin Panel: https://tenjo.adilabs.id/admin

Configuration: C:\ProgramData\Tenjo\src\core\config.py
Logs: C:\ProgramData\Tenjo\logs\

For issues:
1. Check logs
2. Verify Python installation
3. Check Windows Firewall
4. Verify internet connection
5. Restart service

========================================
README_EOF

echo "   ✅ README.txt created"

# Create Python download instructions
echo "📝 Creating Python installer guide..."
cat > "$INSTALLER_DIR/python_installer/DOWNLOAD_PYTHON.txt" << 'PYTHON_EOF'
========================================
PYTHON INSTALLER - DOWNLOAD INSTRUCTIONS
========================================

Tenjo requires Python 3.10 or newer.

If PCs don't have Python installed, download it first:

========================================
📥 DOWNLOAD PYTHON
========================================

Official Website:
  https://www.python.org/downloads/

Recommended Version:
  Python 3.12.x (latest stable)

Direct Download Links:
  Windows 64-bit:
  https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe

  Windows 32-bit:
  https://www.python.org/ftp/python/3.12.0/python-3.12.0.exe

========================================
🔧 INSTALLATION STEPS
========================================

1. Download python-3.12.x-amd64.exe
2. Copy to this folder (python_installer/)
3. Double-click to install
4. ✅ CHECK "Add Python to PATH" (IMPORTANT!)
5. Click "Install Now"
6. Wait for installation
7. Verify: open CMD and type "python --version"

========================================
⚠️ IMPORTANT
========================================

✅ Always check "Add Python to PATH"
✅ Use 64-bit version (unless 32-bit Windows)
✅ Restart CMD after installation
✅ Verify: python --version

========================================
PYTHON_EOF

echo "   ✅ Python download guide created"

# Create quick checklist
cat > "$INSTALLER_DIR/INSTALLATION_CHECKLIST.txt" << 'CHECKLIST_EOF'
========================================
TENJO INSTALLATION CHECKLIST
========================================

Date: _______________

Use this checklist to track installations:

PRE-INSTALLATION:
□ USB drive prepared
□ Python installers downloaded (if needed)
□ Administrator credentials ready
□ Dashboard accessible (https://tenjo.adilabs.id)

PER PC INSTALLATION:

PC: _____________ IP: _____________
□ Python installed (python --version)
□ USB plugged in
□ Run INSTALL_TENJO.bat as Admin
□ Installation completed (no errors)
□ PC rebooted
□ Appears in dashboard (wait 5 min)
□ Status: ONLINE
□ Version: 1.0.2
□ Streaming: ACTIVE
Time: _______ Notes: _________________

PC: _____________ IP: _____________
□ Python installed (python --version)
□ USB plugged in
□ Run INSTALL_TENJO.bat as Admin
□ Installation completed (no errors)
□ PC rebooted
□ Appears in dashboard (wait 5 min)
□ Status: ONLINE
□ Version: 1.0.2
□ Streaming: ACTIVE
Time: _______ Notes: _________________

[Add more entries as needed]

POST-INSTALLATION:
□ All PCs verified in dashboard
□ All showing ONLINE status
□ All version 1.0.2
□ Streaming tested on sample PCs
□ Installation documented
□ USB installer archived for future use

SUMMARY:
Total PCs: _______
Successful: _______
Failed: _______
Time taken: _______

========================================
CHECKLIST_EOF

echo "   ✅ Installation checklist created"

# Summary
echo ""
echo "========================================"
echo "✅ USB INSTALLER PACKAGE CREATED!"
echo "========================================"
echo ""
echo "📁 Location: $INSTALLER_DIR"
echo ""
echo "📦 Package Contents:"
echo "   ✅ INSTALL_TENJO.bat (main installer)"
echo "   ✅ UNINSTALL_TENJO.bat (uninstaller)"
echo "   ✅ client/tenjo_client_1.0.2.tar.gz (27 MB)"
echo "   ✅ README.txt (comprehensive guide)"
echo "   ✅ INSTALLATION_CHECKLIST.txt (tracking)"
echo "   ✅ python_installer/ (download instructions)"
echo ""
echo "📊 Package Size:"
du -sh "$INSTALLER_DIR" 2>/dev/null || echo "   ~28 MB"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. Copy folder to USB drive:"
echo "      cp -r ~/Desktop/tenjo_usb_installer /Volumes/YOUR_USB/"
echo ""
echo "   2. Download Python installer (if needed):"
echo "      - Visit: https://www.python.org/downloads/"
echo "      - Download: python-3.12.x-amd64.exe"
echo "      - Copy to: USB/python_installer/"
echo ""
echo "   3. At office, for each PC:"
echo "      - Plug USB"
echo "      - Run: INSTALL_TENJO.bat (as Administrator)"
echo "      - Wait 2 minutes"
echo "      - Reboot"
echo "      - Verify dashboard"
echo ""
echo "⏱️  Timeline:"
echo "   Per PC: ~2 minutes"
echo "   17 PCs: ~35 minutes"
echo ""
echo "========================================"
