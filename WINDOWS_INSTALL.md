# 🪟 Tenjo Windows Installer

## ⚡ Quick Install (One Command)

Buka **Command Prompt** atau **PowerShell** dan jalankan:

```powershell
# PowerShell (Recommended)
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat' -OutFile 'install.bat'; .\install.bat
```

```cmd
# Command Prompt
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat' -OutFile 'install.bat'"
install.bat
```

## 📋 Manual Install

### 1. Download Installer
```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat' -OutFile 'install_tenjo.bat'
```

### 2. Run Installer
```cmd
install_tenjo.bat
```

## 🔧 Requirements

- **Windows 10/11** (64-bit recommended)
- **Internet Connection** for downloading dependencies
- **PowerShell 5.0+** (built-in on Windows 10/11)

### 🎯 Auto-Installed by Installer:
- **Python 3.13+** - Will be downloaded and installed automatically
- **Git for Windows** - Will be downloaded and installed automatically

*Note: Manual installation of Python and Git is no longer required!*

## 📍 Installation Details

### What the installer does:
1. ✅ Auto-installs Python 3.13+ if not found
2. ✅ Auto-installs Git for Windows if not found
3. ✅ Downloads Tenjo from GitHub
4. ✅ Installs Python dependencies
5. ✅ Tests installation
6. ✅ Sets up auto-start on Windows boot
7. ✅ Starts monitoring service in background
8. ✅ Creates uninstaller
9. ✅ Cleans up temporary files

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