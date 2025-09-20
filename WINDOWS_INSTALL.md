# 🪟 Tenjo Windows Installer

## ⚡ Quick Install (One Command)

Buka **Command Prompt** atau **PowerShell** dan jalankan:

```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat' -OutFile 'install.bat' && install.bat"
```

## 📋 Manual Install

### 1. Download Installer
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat' -OutFile 'install_tenjo.bat'"
```

### 2. Run Installer
```cmd
install_tenjo.bat
```

## 🔧 Requirements

- **Windows 10/11** (64-bit recommended)
- **Python 3.13+** - [Download here](https://www.python.org/downloads/)
  - ⚠️ **Important**: Check "Add Python to PATH" during installation
- **Git for Windows** - [Download here](https://git-scm.com/download/win)

## 📍 Installation Details

### What the installer does:
1. ✅ Checks Python 3.13+ and Git
2. ✅ Downloads Tenjo from GitHub
3. ✅ Installs Python dependencies
4. ✅ Tests installation
5. ✅ Sets up auto-start on Windows boot
6. ✅ Starts monitoring service in background
7. ✅ Creates uninstaller

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

### Python Not Found
```cmd
# Check if Python is installed
python --version

# If not found, download and install Python 3.13+
# Make sure to check "Add Python to PATH"
```

### Git Not Found
```cmd
# Check if Git is installed
git --version

# If not found, download Git for Windows
```

### Permission Issues
- Run Command Prompt as **Administrator** if needed
- Or install to custom directory with write permissions

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