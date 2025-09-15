# Tenjo Auto Installer Guide

## Quick Installation

### One-Line Installation

**macOS/Linux:**
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install.sh | bash
```

**Windows (PowerShell):**
```powershell
powershell -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install.bat' -OutFile 'install.bat'; .\install.bat}"
```

### Manual Installation

1. **Download the installer for your platform:**
   - macOS: `auto_install_macos.sh`
   - Linux: `auto_install_linux.sh` 
   - Windows: `auto_install_windows.bat`

2. **Run the installer:**
   ```bash
   # macOS/Linux
   chmod +x auto_install_macos.sh
   ./auto_install_macos.sh
   
   # Windows
   auto_install_windows.bat
   ```

## What the Installer Does

### 🔧 System Preparation
- ✅ Checks and installs required dependencies (Git, Python 3, pip)
- ✅ Installs system packages for screen capture (Linux only)
- ✅ Stops any existing Tenjo processes

### 📦 Application Installation
- ✅ Downloads latest Tenjo from GitHub repository
- ✅ Installs Python dependencies automatically
- ✅ Creates installation directory (`~/.tenjo`)

### 🚀 Service Configuration
- ✅ **macOS**: Creates LaunchAgent for automatic startup
- ✅ **Linux**: Creates systemd user service
- ✅ **Windows**: Creates Task Scheduler entry and registry startup
- ✅ Configures stealth mode operation

### 🛡️ Security Features
- ✅ Runs in user context (not as root/administrator)
- ✅ Background operation (stealth mode)
- ✅ Automatic restart on failure
- ✅ Proper logging configuration

## Installation Locations

| Platform | Install Directory | Service Location |
|----------|------------------|------------------|
| **macOS** | `~/.tenjo` | `~/Library/LaunchAgents/com.tenjo.monitoring.plist` |
| **Linux** | `~/.tenjo` | `~/.config/systemd/user/tenjo-monitoring.service` |
| **Windows** | `%USERPROFILE%\.tenjo` | Task Scheduler + Registry startup |

## Uninstallation

Each installation automatically creates an uninstaller:

- **macOS**: `~/.tenjo/uninstall_tenjo_macos.sh`
- **Linux**: `~/.tenjo/uninstall_tenjo_linux.sh`
- **Windows**: `%USERPROFILE%\.tenjo\uninstall_tenjo_windows.bat`

## Post-Installation

### Verify Installation
```bash
# Check if service is running (macOS)
launchctl list | grep com.tenjo.monitoring

# Check if service is running (Linux)
systemctl --user status tenjo-monitoring

# Check if service is running (Windows)
schtasks /query /tn "TenjoMonitoring"
```

### Log Files
- **Logs Location**: `[install_dir]/client/logs/`
- **Main Log**: `tenjo_client_YYYYMMDD.log`
- **Service Logs**: `tenjo_stdout.log`, `tenjo_stderr.log`

### Service Management

**macOS:**
```bash
# Start service
launchctl load ~/Library/LaunchAgents/com.tenjo.monitoring.plist

# Stop service
launchctl unload ~/Library/LaunchAgents/com.tenjo.monitoring.plist
```

**Linux:**
```bash
# Start service
systemctl --user start tenjo-monitoring

# Stop service
systemctl --user stop tenjo-monitoring

# View logs
journalctl --user -u tenjo-monitoring
```

**Windows:**
```cmd
# Start service
schtasks /run /tn "TenjoMonitoring"

# Stop service
schtasks /end /tn "TenjoMonitoring"
```

## Troubleshooting

### Installation Issues

1. **Python not found:**
   - Install Python 3.7+ from https://python.org
   - Ensure Python is in PATH

2. **Git not found:**
   - **macOS**: Install Xcode Command Line Tools: `xcode-select --install`
   - **Linux**: Install via package manager: `sudo apt install git` (Ubuntu/Debian)
   - **Windows**: Install Git for Windows: https://git-scm.com/download/win

3. **Permission denied:**
   - Don't run as root/administrator
   - Ensure user has write access to home directory

4. **Network issues:**
   - Check internet connection
   - Verify GitHub access: https://github.com/Adi-Sumardi/Tenjo

### Service Issues

1. **Service not starting:**
   - Check logs in `[install_dir]/client/logs/`
   - Verify Python dependencies: `cd ~/.tenjo/client && python3 -m pip check`
   - Test manual start: `cd ~/.tenjo/client && python3 main.py`

2. **Missing dependencies:**
   - Reinstall: `cd ~/.tenjo/client && python3 -m pip install -r requirements.txt`

3. **Screen capture issues (Linux):**
   - Install X11 development packages
   - Ensure running in graphical session
   - Check DISPLAY environment variable

## Security Considerations

⚠️ **Important Security Notes:**

1. **Authorized Use Only**: This software should only be installed on systems you own or have explicit permission to monitor
2. **Privacy Compliance**: Ensure compliance with local privacy laws and regulations
3. **Network Security**: Monitor network traffic for the monitoring data
4. **Access Control**: Secure the dashboard with proper authentication
5. **Data Protection**: Implement proper data retention and deletion policies

## Support

For installation issues:
1. Check the troubleshooting section above
2. Review log files for error messages
3. Ensure all prerequisites are met
4. Test with manual installation steps

## Features After Installation

✅ **Automatic Startup**: Service starts automatically on system boot  
✅ **Stealth Operation**: Runs silently in background  
✅ **Screen Streaming**: Live screen capture and streaming  
✅ **Activity Monitoring**: Browser and application tracking  
✅ **Automatic Recovery**: Service restarts on failure  
✅ **Cross-Platform**: Works on macOS, Linux, and Windows  

---

**Note**: This installer downloads the latest version from GitHub and sets up everything automatically. The application will be ready to use immediately after installation.
