#!/bin/bash

# Tenjo USB Updater Package Creator (No Reboot Version)
# Creates a USB package to update existing Tenjo installations without reboot

OUTPUT_DIR="$HOME/Desktop/tenjo_usb_updater"

echo "=========================================="
echo "   CREATING TENJO USB UPDATER PACKAGE"
echo "   (No Reboot Version)"
echo "=========================================="
echo ""

# Create output directory
echo "[1/6] Creating package directory..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
echo "    ✓ Directory created: $OUTPUT_DIR"

# Create RUN_UPDATE.bat (no reboot version)
echo ""
echo "[2/6] Creating RUN_UPDATE.bat (no reboot)..."
cat > "$OUTPUT_DIR/RUN_UPDATE.bat" << 'UPDATE_BAT_EOF'
@echo off
echo ========================================
echo    TENJO - UPDATE TO PRODUCTION SERVER
echo    (No Reboot Required!)
echo ========================================
echo.

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo.
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [1/5] Stopping Tenjo service...
taskkill /F /IM python.exe /FI "WINDOWTITLE eq Tenjo*" >nul 2>&1
taskkill /F /IM pythonw.exe /FI "WINDOWTITLE eq Tenjo*" >nul 2>&1
schtasks /End /TN "TenjoMonitor" >nul 2>&1
timeout /t 2 /nobreak >nul
echo     ✓ Service stopped

echo.
echo [2/5] Backing up old config...
set TENJO_DIR=C:\ProgramData\Tenjo
if exist "%TENJO_DIR%\src\core\config.py" (
    copy "%TENJO_DIR%\src\core\config.py" "%TENJO_DIR%\src\core\config.py.backup" >nul
    echo     ✓ Backup created
) else (
    echo     ! Config not found, will create new
)

echo.
echo [3/5] Updating server configuration...
python update_server_config.py
if %errorLevel% neq 0 (
    echo     ✗ Failed to update config
    echo.
    echo Restoring backup...
    if exist "%TENJO_DIR%\src\core\config.py.backup" (
        copy "%TENJO_DIR%\src\core\config.py.backup" "%TENJO_DIR%\src\core\config.py" >nul
    )
    pause
    exit /b 1
)
echo     ✓ Config updated to production server

echo.
echo [4/5] Starting Tenjo service...
:: Try scheduled task first
schtasks /Run /TN "TenjoMonitor" >nul 2>&1
if %errorLevel% equ 0 (
    echo     ✓ Started via scheduled task
) else (
    :: Fallback: start directly
    cd /d "%TENJO_DIR%"
    start "" /B pythonw.exe main.py >nul 2>&1
    echo     ✓ Started directly
)

echo.
echo [5/5] Verifying Tenjo is running...
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
        echo     Check Task Manager for python.exe
    )
)

echo.
echo ========================================
echo    ✅ UPDATE COMPLETE!
echo ========================================
echo.
echo ✓ Server URL updated to: https://tenjo.adilabs.id
echo ✓ Tenjo service restarted
echo ✓ No reboot required!
echo.
echo The client should appear online in dashboard within 1-2 minutes.
echo.
echo OPTIONAL: Run OPTIONAL_enable_remote_access.bat to enable
echo           RDP/SMB/WinRM for future remote updates.
echo.
pause
UPDATE_BAT_EOF
echo "    ✓ RUN_UPDATE.bat created"

# Copy update_server_config.py
echo ""
echo "[3/6] Copying update_server_config.py..."
if [ -f "update_server_config.py" ]; then
    cp update_server_config.py "$OUTPUT_DIR/"
    echo "    ✓ update_server_config.py copied"
else
    echo "    ! update_server_config.py not found in current directory"
fi

# Copy enable_remote_access.bat
echo ""
echo "[4/6] Copying OPTIONAL_enable_remote_access.bat..."
if [ -f "usb_deployment/enable_remote_access.bat" ]; then
    cp usb_deployment/enable_remote_access.bat "$OUTPUT_DIR/OPTIONAL_enable_remote_access.bat"
    echo "    ✓ OPTIONAL_enable_remote_access.bat copied"
else
    echo "    ! enable_remote_access.bat not found"
fi

# Create HOW_TO_USE.txt
echo ""
echo "[5/6] Creating HOW_TO_USE.txt..."
cat > "$OUTPUT_DIR/HOW_TO_USE.txt" << 'HOWTO_EOF'
========================================
   TENJO USB UPDATER - QUICK GUIDE
========================================

WHAT THIS DOES:
- Updates Tenjo client config from localhost to production server
- Restarts Tenjo service automatically
- NO REBOOT REQUIRED!

REQUIREMENTS:
- Existing Tenjo installation on the PC
- Administrator privileges

HOW TO USE:
1. Plug USB drive into target PC
2. Open the tenjo_usb_updater folder
3. Right-click RUN_UPDATE.bat
4. Select "Run as administrator"
5. Wait for "UPDATE COMPLETE!" message (30 seconds)
6. Done! Client will appear online in 1-2 minutes

OPTIONAL:
- Run OPTIONAL_enable_remote_access.bat to enable RDP/SMB/WinRM
  This allows future updates via network (no USB needed)

TIMELINE:
- Per PC: 1 minute
- 17 PCs: 20-30 minutes total

TROUBLESHOOTING:
- If Tenjo not running after update, check Task Manager for python.exe
- If still offline after 5 minutes, check dashboard for error messages
- Config backup saved at: C:\ProgramData\Tenjo\src\utils\config.py.backup

For detailed instructions, see HOW_TO_USE_COMPLETE.txt
HOWTO_EOF
echo "    ✓ HOW_TO_USE.txt created"

# Create HOW_TO_USE_COMPLETE.txt
echo ""
echo "[6/6] Creating HOW_TO_USE_COMPLETE.txt..."
cat > "$OUTPUT_DIR/HOW_TO_USE_COMPLETE.txt" << 'COMPLETE_EOF'
========================================
   TENJO USB UPDATER
   COMPLETE GUIDE (No Reboot Version)
========================================

TABLE OF CONTENTS:
1. Overview
2. What's Included
3. Requirements
4. Step-by-Step Instructions
5. What Happens During Update
6. Troubleshooting
7. Enabling Remote Access (Optional)
8. Timeline & Planning

========================================
1. OVERVIEW
========================================

This USB package updates Tenjo client configurations from localhost
(http://127.0.0.1:8000) to production server (https://tenjo.adilabs.id).

KEY FEATURES:
- Automatic config backup before update
- Automatic rollback if update fails
- Service restart (no reboot needed!)
- Verification of running service
- Takes ~1 minute per PC

TARGET:
- 17 PCs with existing Tenjo installations
- All currently showing offline in dashboard

========================================
2. WHAT'S INCLUDED
========================================

Files in this USB package:

1. RUN_UPDATE.bat
   - Main update script (no reboot version)
   - Stops service, updates config, restarts service
   - ~30 seconds runtime
   
2. update_server_config.py
   - Backend Python script
   - Updates config.py with production URL
   - Creates server_override.json
   
3. OPTIONAL_enable_remote_access.bat
   - Enables RDP, SMB, WinRM on Windows
   - Configures firewall rules
   - Allows future remote updates
   
4. HOW_TO_USE.txt
   - Quick reference guide
   
5. HOW_TO_USE_COMPLETE.txt
   - This comprehensive guide

========================================
3. REQUIREMENTS
========================================

REQUIRED:
✓ Existing Tenjo installation (C:\ProgramData\Tenjo)
✓ Windows 10 or 11
✓ Administrator privileges
✓ Python already installed (Tenjo was installed with it)

NOT REQUIRED:
✗ Internet connection during update
✗ Reboot or restart
✗ Stopping user work

========================================
4. STEP-BY-STEP INSTRUCTIONS
========================================

FOR EACH PC:

STEP 1: Preparation
   - Save any open work on the PC
   - Keep PC running (don't lock or sleep)
   
STEP 2: Insert USB
   - Plug USB drive into target PC
   - Open File Explorer
   - Navigate to USB drive > tenjo_usb_updater folder

STEP 3: Run Update
   - Right-click on "RUN_UPDATE.bat"
   - Select "Run as administrator"
   - Click "Yes" on UAC prompt
   
STEP 4: Monitor Progress
   Watch the command window show:
   [1/5] Stopping Tenjo service...        (3 seconds)
   [2/5] Backing up old config...         (1 second)
   [3/5] Updating server configuration... (5 seconds)
   [4/5] Starting Tenjo service...        (2 seconds)
   [5/5] Verifying Tenjo is running...    (3 seconds)
   
   Total time: ~30 seconds

STEP 5: Verify Success
   - Wait for "UPDATE COMPLETE!" message
   - Service starts automatically
   - Press any key to close window
   
STEP 6: Move to Next PC
   - Eject USB drive
   - Move to next PC
   - Repeat steps 2-5

STEP 7: Final Verification (after all PCs done)
   - Wait 15 minutes for all clients to connect
   - Open dashboard: https://tenjo.adilabs.id
   - Verify all 19 clients show ONLINE

========================================
5. WHAT HAPPENS DURING UPDATE
========================================

DETAILED PROCESS:

[1/5] Stopping Tenjo service
      - Kills python.exe and pythonw.exe processes
      - Stops TenjoMonitor scheduled task
      - Waits 2 seconds for clean shutdown
      Result: Tenjo service stopped

[2/5] Backing up old config
      - Copies config.py to config.py.backup
      - Preserves original settings
      Result: Backup created at C:\ProgramData\Tenjo\src\utils\config.py.backup

[3/5] Updating server configuration
      - Runs update_server_config.py
      - Changes DEFAULT_SERVER_URL from "http://127.0.0.1:8000"
        to "https://tenjo.adilabs.id"
      - Creates server_override.json for precedence
      Result: Config points to production server

[4/5] Starting Tenjo service
      - Attempts to start via scheduled task (TenjoMonitor)
      - Fallback: Direct pythonw.exe execution
      Result: Tenjo service running in background

[5/5] Verifying Tenjo is running
      - Checks for pythonw.exe or python.exe in process list
      - Confirms service started successfully
      Result: Service verified running

IF ANY ERROR OCCURS:
      - Automatic rollback restores config.py.backup
      - Error message displayed
      - User can retry or contact support

========================================
6. TROUBLESHOOTING
========================================

ISSUE: "This script must be run as Administrator"
SOLUTION: Right-click RUN_UPDATE.bat → Run as administrator

ISSUE: "Python is not installed"
SOLUTION: This shouldn't happen if Tenjo was already installed.
          Check if Tenjo directory exists: C:\ProgramData\Tenjo

ISSUE: "Failed to update config"
SOLUTION: 
   1. Check if Tenjo directory exists
   2. Verify Python works: python --version
   3. Manually restore backup:
      copy C:\ProgramData\Tenjo\src\utils\config.py.backup 
           C:\ProgramData\Tenjo\src\utils\config.py

ISSUE: "Could not verify Tenjo process"
SOLUTION:
   1. Open Task Manager (Ctrl+Shift+Esc)
   2. Look for python.exe or pythonw.exe
   3. If not found, manually start:
      cd C:\ProgramData\Tenjo
      pythonw.exe main.py

ISSUE: Client still shows offline after 5 minutes
SOLUTION:
   1. Check dashboard for specific error messages
   2. Check Tenjo logs: C:\ProgramData\Tenjo\logs\
   3. Verify internet connection on PC
   4. Try restarting Tenjo service manually

ISSUE: Update works but client goes offline again
SOLUTION:
   Config may be getting reset. Create persistent override:
   1. Open: C:\ProgramData\Tenjo\server_override.json
   2. Verify contents:
      {
        "server_url": "https://tenjo.adilabs.id",
        "api_endpoint": "/api",
        "update_interval": 60
      }

========================================
7. ENABLING REMOTE ACCESS (OPTIONAL)
========================================

After updating all PCs, you can enable remote access for future
updates without needing physical USB access.

WHAT IT ENABLES:
✓ Remote Desktop Protocol (RDP) - Port 3389
✓ Windows Remote Management (WinRM) - Port 5985
✓ SMB File Sharing - Port 445
✓ Firewall rules for remote connections

HOW TO ENABLE:

STEP 1: On each PC after running RUN_UPDATE.bat
   - Right-click "OPTIONAL_enable_remote_access.bat"
   - Select "Run as administrator"
   - Wait for "SUCCESS" message
   - Note: This DOES require a reboot!

STEP 2: Reboot the PC
   - Save all work
   - Restart computer
   - Remote access will be available after reboot

STEP 3: Test remote access (from your Mac)
   - Run network scanner:
     cd ~/Adi/App-Dev/Tenjo/client
     ./advanced_network_scan.sh
   - Should show ports 3389, 5985, 445 open

FUTURE UPDATES:
   With remote access enabled, you can:
   - Deploy updates via network (no USB needed)
   - Use remote_network_deploy.py for mass deployment
   - Connect via RDP to troubleshoot issues
   - Access files via SMB network share

SECURITY NOTE:
   Remote access may be blocked by company firewall policy.
   Consult IT security team before enabling on production PCs.

========================================
8. TIMELINE & PLANNING
========================================

SINGLE PC TIMELINE:
   - Insert USB: 5 seconds
   - Run script: 30 seconds
   - Verify: 5 seconds
   - Eject USB: 5 seconds
   Total: ~1 minute per PC

MASS DEPLOYMENT TIMELINE:
   17 PCs × 1 minute = 17 minutes (best case)
   Add 5 minutes buffer = 22 minutes
   Add 15 minutes for verification = 37 minutes
   
   REALISTIC TOTAL: 40-50 minutes

RECOMMENDED SCHEDULE:

09:00 - Arrive at office with USB
09:00 - Start with PC #1 (192.168.1.2 - confirmed online)
09:01 - Move to PC #2 (192.168.1.26)
09:02 - Move to PC #3
[Continue for all 17 PCs...]
09:20 - All updates complete
09:35 - Wait 15 minutes for client heartbeats
09:35 - Check dashboard (https://tenjo.adilabs.id)
09:40 - Verify all 19 clients show ONLINE
09:45 - DONE!

TIPS FOR EFFICIENCY:
   1. Start with PCs closest to each other physically
   2. Don't wait for each PC to finish - start next while previous runs
   3. Keep USB plugged in for 1 minute minimum
   4. If PC is locked/asleep, wake it up first
   5. Mark completed PCs with sticky notes to track progress

ROLLBACK PLAN:
   If major issues occur:
   1. All configs backed up to .backup files
   2. To rollback a single PC:
      copy C:\ProgramData\Tenjo\src\utils\config.py.backup
           C:\ProgramData\Tenjo\src\utils\config.py
      schtasks /Run /TN "TenjoMonitor"
   3. To rollback all PCs:
      Create USB with restore script (contact support)

========================================

For questions or issues:
- Dashboard: https://tenjo.adilabs.id
- Check logs: C:\ProgramData\Tenjo\logs\
- Network tools: ~/Adi/App-Dev/Tenjo/client/

Good luck with the deployment!

========================================
COMPLETE_EOF
echo "    ✓ HOW_TO_USE_COMPLETE.txt created"

# Show results
echo ""
echo "=========================================="
echo "   ✅ USB UPDATER PACKAGE CREATED!"
echo "=========================================="
echo ""
echo "Location: $OUTPUT_DIR"
echo ""
echo "Package contents:"
ls -lh "$OUTPUT_DIR"
echo ""
echo "Package size:"
du -sh "$OUTPUT_DIR"
echo ""
echo "=========================================="
echo "NEXT STEPS:"
echo "=========================================="
echo ""
echo "1. Copy to USB drive:"
echo "   cp -r $OUTPUT_DIR /Volumes/YOUR_USB/"
echo ""
echo "2. Tomorrow at office:"
echo "   - Plug USB into each PC"
echo "   - Run RUN_UPDATE.bat as Administrator"
echo "   - Wait 1 minute per PC"
echo "   - No reboot required!"
echo ""
echo "3. After all updates (15 min later):"
echo "   - Check https://tenjo.adilabs.id"
echo "   - Verify 19 clients ONLINE"
echo ""
echo "Timeline: 20-30 minutes for all 17 PCs"
echo "=========================================="

