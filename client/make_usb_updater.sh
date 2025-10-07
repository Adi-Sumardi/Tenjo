#!/bin/bash
# Simple USB Updater Package Creator

USB_DIR="$HOME/Desktop/tenjo_usb_updater"
mkdir -p "$USB_DIR"

echo "Creating USB updater package..."

# Download update script
curl -s "https://tenjo.adilabs.id/downloads/client/update_server_config.py" -o "$USB_DIR/update_server_config.py"

# Create Windows batch file
cat > "$USB_DIR/RUN_UPDATE.bat" << 'BAT_EOF'
@echo off
echo ========================================
echo TENJO CLIENT CONFIG UPDATE
echo ========================================
echo.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Run as Administrator!
    pause
    exit /b 1
)
if not exist "C:\ProgramData\Tenjo" (
    echo ERROR: Tenjo not installed!
    pause
    exit /b 1
)
copy /Y "%~dp0update_server_config.py" "C:\ProgramData\Tenjo\" >nul
cd /d C:\ProgramData\Tenjo
python update_server_config.py
echo.
echo Update complete! Restarting in 60 seconds...
shutdown /r /t 60
pause
BAT_EOF

# Create instructions
cat > "$USB_DIR/HOW_TO_USE.txt" << 'EOF'
USB TENJO CLIENT UPDATER
========================

USAGE:
1. Plug USB into client PC
2. Right-click "RUN_UPDATE.bat"
3. Select "Run as administrator"
4. PC will restart in 60 seconds

Repeat for all 17 client PCs.

Time per PC: ~2 minutes
Total time: ~30-40 minutes
EOF

echo "✅ USB package created: $USB_DIR"
echo ""
echo "FILES:"
echo "  - RUN_UPDATE.bat (run this on each PC)"
echo "  - update_server_config.py (update script)"
echo "  - HOW_TO_USE.txt (instructions)"
echo ""
echo "NEXT: Copy folder to USB drive, then use on each client PC"

open "$USB_DIR"
