# 🪟 Tenjo Windows Installer

## ⚡ Quick Install (Choose One Method)

### Method 1: PowerShell Installer (Recommended)
```powershell
# Open PowerShell as Administrator and run:
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1' -OutFile 'install.ps1'; Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; .\install.ps1
```

### Method 2: Batch File Installer
```powershell
# PowerShell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat' -OutFile 'install.bat'; .\install.bat
```

```cmd
# Command Prompt
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat' -OutFile 'install.bat'"
install.bat
```

## 📋 Manual Install

### Option A: PowerShell Script
1. Download: `install_windows.ps1`
2. Right-click → "Run with PowerShell"

### Option B: Batch File
1. Download: `install_windows.bat`  
2. Double-click to run

## 🔧 Requirements

- **Windows 10/11** (64-bit recommended)
- **Internet Connection** for downloading dependencies
- **PowerShell 5.0+** (built-in on Windows 10/11)

### 🎯 Auto-Installed by Installer:
- **Python 3.13+** - Downloaded and installed automatically if needed
- **Git for Windows** - Downloaded and installed automatically if needed

*Note: Both installers handle all dependencies automatically!*

## 📍 Installation Details

### What Both Installers Do:
1. ✅ **Check System** - Detect existing Python/Git installations
2. ✅ **Auto-Download** - Download Python 3.13 + Git if missing
3. ✅ **Silent Install** - Install dependencies without user interaction
4. ✅ **GitHub Clone** - Download Tenjo repository
5. ✅ **Dependencies** - Install Python packages via pip
6. ✅ **Configuration** - Setup auto-start and stealth mode
7. ✅ **Testing** - Verify installation works
8. ✅ **Service Start** - Launch monitoring in background
9. ✅ **Cleanup** - Remove temporary files

### Key Differences:
- **PowerShell (.ps1)**: Better error handling, more robust
- **Batch (.bat)**: Traditional Windows installer, wider compatibility

### Installation Location:
- **Files**: `%USERPROFILE%\.tenjo\`
- **Logs**: `%USERPROFILE%\.tenjo\client\logs\`
- **Auto-start**: Added to Windows Startup folder

## 🎯 After Installation

### ✅ Service Status
- Service runs **automatically** in background
- **Stealth mode**: No visible windows
- **Auto-start**: Starts when Windows boots

### 🌐 Dashboard Access
- Open browser: `http://103.129.149.67`
- Your device will appear in the dashboard

### 🗑️ Uninstall
```cmd
%USERPROFILE%\.tenjo\uninstall.bat
```

## 🚨 Troubleshooting

### Installation Taking Long Time
- Python and Git downloads may take 2-5 minutes depending on internet speed
- The installer will show progress and wait for installations to complete

### Python/Git Already Installed
- Installer will detect existing installations and skip downloading
- If PATH issues occur, installer will attempt to refresh environment

### Permission Issues
- Run Command Prompt as **Administrator** if auto-install fails
- Alternatively, manually install Python and Git, then run installer

### Internet Connection Issues
- Ensure stable internet connection for downloading dependencies
- Try running installer again if downloads fail

### Service Not Starting
1. Check logs: `%USERPROFILE%\.tenjo\client\logs\`
2. Test manually: 
   ```cmd
   cd %USERPROFILE%\.tenjo\client
   python main.py
   ```

## 📞 Support

- **Dashboard**: http://103.129.149.67
- **GitHub**: https://github.com/Adi-Sumardi/Tenjo
- **Logs**: Check `%USERPROFILE%\.tenjo\client\logs\` for errors

---

**🎉 Installation complete! Your device is now monitored and will appear in the dashboard.**