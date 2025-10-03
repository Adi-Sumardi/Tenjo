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
