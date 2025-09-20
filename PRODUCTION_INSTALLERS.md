# Tenjo Production Installers

## 🚀 Overview

Production-ready installers untuk Tenjo Employee Monitoring System yang mendukung Python 3.13+ dan OS detection terbaru.

## 📦 Installer Files

### 1. macOS Production Installer
- **File**: `install_macos_production.sh`
- **Requirements**: macOS 10.15+ (Catalina atau lebih baru)
- **Python**: 3.13+ (otomatis detect atau install via Homebrew)
- **Service**: LaunchAgent (auto-start saat login)

### 2. Windows Production Installer  
- **File**: `install_windows_production.bat`
- **Requirements**: Windows 10/11
- **Python**: 3.13+ (manual install required)
- **Service**: Scheduled Task atau Registry startup

### 3. Linux Production Installer
- **File**: `install_linux_production.sh`
- **Requirements**: Ubuntu 20.04+, CentOS 8+, Fedora 35+, Arch Linux
- **Python**: 3.13+ (otomatis install dari repository)
- **Service**: systemd user service

## 🔧 Features

### ✅ Python 3.13+ Compatibility
- Version detection dan validation
- Automatic installation jika tidak tersedia
- Virtual environment fallback jika diperlukan
- Compatible dengan aplikasi utama yang menggunakan Python 3.13

### ✅ Advanced OS Detection
- Integrated dengan `os_detector.py` 
- Deteksi OS name, version, architecture
- Platform-specific optimization
- Compatibility test sebelum installation

### ✅ Production-Ready Features
- **Stealth Mode**: Service berjalan di background tanpa UI
- **Auto-Start**: Otomatis start saat system boot/login
- **Error Handling**: Comprehensive error checking dan rollback
- **Security**: Tidak memerlukan admin/root privileges
- **Logging**: Centralized logging dengan rotation
- **Uninstaller**: Clean removal script included

### ✅ Cross-Platform Service Management
- **macOS**: LaunchAgent (user-level service)
- **Windows**: Scheduled Task + Registry startup
- **Linux**: systemd user service

## 📋 Installation Instructions

### macOS Installation
```bash
# Download dan jalankan installer
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_macos_production.sh | bash

# Atau manual:
wget https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_macos_production.sh
chmod +x install_macos_production.sh
./install_macos_production.sh
```

### Windows Installation
```cmd
# Download installer
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows_production.bat' -OutFile 'install_tenjo.bat'"

# Jalankan installer
install_tenjo.bat
```

### Linux Installation
```bash
# Download dan jalankan installer
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_linux_production.sh | bash

# Atau manual:
wget https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_linux_production.sh
chmod +x install_linux_production.sh
./install_linux_production.sh
```

## 🔍 Pre-Installation Requirements

### All Platforms
- **Internet Connection** untuk download repository dan dependencies
- **Git** (otomatis install di macOS/Linux, manual untuk Windows)
- **Python 3.13+** (otomatis handle oleh installer)

### Platform-Specific
#### macOS
- Homebrew (optional, untuk auto-install Git/Python)
- Screen recording permissions (akan diminta saat pertama kali)

#### Windows  
- Git for Windows (manual install required)
- PowerShell 5.0+ (built-in Windows 10/11)

#### Linux
- Package manager (apt/dnf/yum/pacman)
- Development tools untuk compile Python packages

## 📊 Installation Process

### 1. Dependency Check
- Python version validation (>= 3.13)
- Git availability check
- OS compatibility verification

### 2. Download & Setup
- Clone dari GitHub repository
- Install Python dependencies
- Test OS detection system

### 3. Service Configuration
- Create platform-specific service
- Configure auto-start
- Set proper permissions

### 4. Verification
- Service status check
- Client initialization test
- Create uninstaller

## 🗂️ Installation Locations

### Default Install Directories
- **macOS**: `$HOME/.tenjo`
- **Windows**: `%USERPROFILE%\.tenjo`  
- **Linux**: `$HOME/.tenjo`

### Service Locations
- **macOS**: `~/Library/LaunchAgents/com.tenjo.monitoring.plist`
- **Windows**: Scheduled Task `TenjoMonitoring`
- **Linux**: `~/.config/systemd/user/tenjo-monitoring.service`

### Log Files
- **All Platforms**: `~/.tenjo/client/logs/`

## 🔧 Post-Installation Management

### Service Control

#### macOS
```bash
# Status
launchctl list | grep tenjo

# Stop/Start
launchctl unload ~/Library/LaunchAgents/com.tenjo.monitoring.plist
launchctl load ~/Library/LaunchAgents/com.tenjo.monitoring.plist
```

#### Windows
```cmd
# Status
schtasks /query /tn "TenjoMonitoring"

# Stop/Start
schtasks /end /tn "TenjoMonitoring"
schtasks /run /tn "TenjoMonitoring"
```

#### Linux
```bash
# Status
systemctl --user status tenjo-monitoring

# Stop/Start/Restart
systemctl --user stop tenjo-monitoring
systemctl --user start tenjo-monitoring
systemctl --user restart tenjo-monitoring
```

## 🗑️ Uninstallation

### Automatic Uninstaller
Setiap installer creates uninstaller script:

- **macOS**: `~/.tenjo/uninstall_tenjo_macos.sh`
- **Windows**: `%USERPROFILE%\.tenjo\uninstall_tenjo_windows.bat`
- **Linux**: `~/.tenjo/uninstall_tenjo_linux.sh`

### Manual Uninstallation
```bash
# Stop service (platform-specific commands above)
# Remove files
rm -rf ~/.tenjo

# Remove service files (macOS)
rm ~/Library/LaunchAgents/com.tenjo.monitoring.plist

# Remove scheduled task (Windows)
schtasks /delete /tn "TenjoMonitoring" /f

# Remove systemd service (Linux)
systemctl --user disable tenjo-monitoring
rm ~/.config/systemd/user/tenjo-monitoring.service
systemctl --user daemon-reload
```

## 🔒 Security Features

### User-Level Installation
- **Tidak memerlukan admin/root privileges**
- Service berjalan dengan user permissions
- File tersimpan di user directory

### Stealth Operation
- Background service tanpa UI
- Minimal system resource usage
- No visible indicators untuk end users

### Privacy Compliance
- Local data storage only
- Configurable data retention
- Audit trail tersedia

## 🐛 Troubleshooting

### Common Issues

#### Python Version Issues
```bash
# Check Python version
python3 --version

# If too old, upgrade
# macOS: brew upgrade python
# Ubuntu: sudo apt update && sudo apt install python3.13
# Windows: Download from python.org
```

#### Service Not Starting
```bash
# Check logs
tail -f ~/.tenjo/client/logs/service.log

# Check permissions
ls -la ~/.tenjo/client/main.py

# Restart service (platform-specific)
```

#### OS Detection Issues
```bash
# Test OS detection
cd ~/.tenjo/client
python3 os_detector.py

# Check dependencies
python3 -c "import platform; print(platform.system())"
```

## 📈 Production Deployment

### Batch Deployment
Installer dapat dijalankan secara batch untuk multiple machines:

```bash
# Corporate deployment script
for host in $(cat hostlist.txt); do
    ssh user@$host 'curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_linux_production.sh | bash'
done
```

### Configuration Management
- Environment variables untuk custom configuration
- Central dashboard untuk monitoring deployments
- Health checks dan status reporting

## 🎯 Production Benefits

### ✅ Reliability
- Automatic restart on failure
- Error recovery mechanisms
- Comprehensive logging

### ✅ Maintainability  
- Clean installation/uninstallation
- Version control integration
- Update-friendly architecture

### ✅ Scalability
- Multi-platform deployment
- Centralized management ready
- Resource-efficient operation

### ✅ Compliance
- Audit trail maintenance
- Privacy-focused design
- Security best practices