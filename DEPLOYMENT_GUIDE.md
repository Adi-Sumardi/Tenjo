# 🚀 Tenjo Client Update Deployment Guide

Panduan lengkap untuk deploy update client Tenjo ke VPS dan trigger update ke semua client yang sudah terinstall.

## 📋 Prerequisites

### Linux/macOS:
- `bash` shell
- `python3` 
- `tar`
- `ssh` & `scp`
- `curl`
- `jq` (optional, untuk pretty-print JSON)
- `sha256sum` atau `shasum`

### Windows:
- PowerShell 5.1+
- Python 3.x
- Git for Windows (includes `tar`, `ssh`, `scp`)
  - Download: https://git-scm.com/download/win
  - Atau OpenSSH for Windows
- Alternative: 7-Zip (jika tidak ada tar)

## 🔧 Setup

### 1. Konfigurasi SSH Key untuk VPS

**Linux/macOS:**
```bash
# Generate SSH key (jika belum punya)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy public key ke VPS
ssh-copy-id root@tenjo.adilabs.id

# Test koneksi
ssh root@tenjo.adilabs.id "echo 'Connection OK'"
```

**Windows (PowerShell):**
```powershell
# Generate SSH key (jika belum punya)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy public key ke VPS (manual)
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub | ssh root@tenjo.adilabs.id "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Test koneksi
ssh root@tenjo.adilabs.id "echo 'Connection OK'"
```

### 2. Set Environment Variables

**Linux/macOS:**
```bash
# Edit ~/.bashrc atau ~/.zshrc
export VPS_HOST="tenjo.adilabs.id"
export VPS_USER="root"
export VPS_PATH="/var/www/html/tenjo/public/downloads/client"
export API_URL="https://tenjo.adilabs.id"
export TENJO_ADMIN_TOKEN="your_admin_token_here"

# Reload
source ~/.bashrc  # atau source ~/.zshrc
```

**Windows (PowerShell):**
```powershell
# Set untuk session saat ini
$env:VPS_HOST = "tenjo.adilabs.id"
$env:VPS_USER = "root"
$env:VPS_PATH = "/var/www/html/tenjo/public/downloads/client"
$env:API_URL = "https://tenjo.adilabs.id"
$env:TENJO_ADMIN_TOKEN = "your_admin_token_here"

# Set permanent (System)
[System.Environment]::SetEnvironmentVariable('TENJO_ADMIN_TOKEN', 'your_token', 'User')
```

**Atau gunakan file `.env.deployment`:**
```bash
# Copy template
cp .env.deployment .env.deployment.local

# Edit dengan nilai yang sesuai
nano .env.deployment.local  # Linux/macOS
notepad .env.deployment.local  # Windows

# Source file (Linux/macOS)
source .env.deployment.local
```

### 3. Get Admin Token dari Dashboard

1. Login ke dashboard: https://tenjo.adilabs.id/dashboard
2. Go to **Settings** → **API Tokens**
3. Generate new token dengan permission: `trigger-update`, `schedule-update`
4. Copy token dan simpan ke environment variable `TENJO_ADMIN_TOKEN`

## 🎯 Cara Penggunaan

### Linux/macOS

```bash
# Make script executable
chmod +x deploy_update.sh

# Run deployment
./deploy_update.sh
```

**Interactive Mode:**
Script akan meminta input:
1. **Version number** - e.g., `1.0.1` (default: current version)
2. **Update changes** - list of changes, one per line
3. **Trigger mode** - pilih salah satu:
   - Option 1: Trigger specific client (masukkan client_id)
   - Option 2: Trigger ALL clients (bulk update)
   - Option 3: Skip (manual trigger nanti dari dashboard)

### Windows

```powershell
# Run dengan PowerShell
.\deploy_update_windows.ps1
```

**Dengan Parameters:**
```powershell
# Set version number
.\deploy_update_windows.ps1 -Version "1.0.2"

# Skip upload (testing)
.\deploy_update_windows.ps1 -SkipUpload

# Skip trigger (manual nanti)
.\deploy_update_windows.ps1 -SkipTrigger

# Custom VPS
.\deploy_update_windows.ps1 -VpsHost "103.129.149.67" -VpsUser "admin"
```

## 📦 Apa yang Dilakukan Script?

### 1. **Build Package** 
   - Clean Python cache (`__pycache__`, `*.pyc`)
   - Copy source files ke staging directory
   - Create `.version` file
   - Create tarball: `tenjo_client_<version>.tar.gz`

### 2. **Generate Checksum**
   - SHA256 hash untuk integrity verification

### 3. **Create version.json**
   ```json
   {
     "version": "1.0.1",
     "download_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz",
     "server_url": "https://tenjo.adilabs.id",
     "changes": [
       "Fixed streaming auto-start",
       "Added migration support"
     ],
     "checksum": "sha256_hash_here",
     "package_size": 2048576,
     "priority": "normal",
     "release_date": "2025-10-06T12:00:00Z"
   }
   ```

### 4. **Upload to VPS**
   - Upload package via `scp`
   - Upload `version.json`
   - Set file permissions (644)

### 5. **Trigger Updates (Optional)**
   
   **Option A: Specific Client**
   ```bash
   POST /api/clients/{client_id}/trigger-update
   ```
   
   **Option B: All Clients**
   ```bash
   POST /api/clients/schedule-update
   ```

## 🔍 Manual Trigger via API

Jika skip automatic trigger, bisa trigger manual via API:

### Trigger Specific Client

```bash
curl -X POST "https://tenjo.adilabs.id/api/clients/{CLIENT_ID}/trigger-update" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0.1",
    "update_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz",
    "changes": ["Bug fixes", "New features"],
    "checksum": "sha256_hash_here",
    "priority": "normal"
  }'
```

### Trigger All Clients (Bulk)

```bash
curl -X POST "https://tenjo.adilabs.id/api/clients/schedule-update" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0.1",
    "update_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz",
    "changes": ["Security updates"],
    "priority": "critical"
  }'
```

### Trigger dengan Update Window

```bash
curl -X POST "https://tenjo.adilabs.id/api/clients/{CLIENT_ID}/trigger-update" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0.1",
    "update_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz",
    "priority": "normal",
    "window_start": "02:00:00",
    "window_end": "05:00:00"
  }'
```

## 📊 Monitoring Update Status

### Via Dashboard
1. Login ke dashboard: https://tenjo.adilabs.id/dashboard
2. Go to **Clients** page
3. Check kolom **Pending Update** dan **Version**

### Via API

**Check client status:**
```bash
curl "https://tenjo.adilabs.id/api/clients/{CLIENT_ID}" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "client": {
    "client_id": "xxx-xxx-xxx",
    "hostname": "PC-NAME",
    "current_version": "1.0.0",
    "pending_update": true,
    "update_version": "1.0.1",
    "update_triggered_at": "2025-10-06T12:00:00Z",
    "last_seen": "2025-10-06T12:05:00Z"
  }
}
```

## 🔄 Update Process Flow

### Client-Side Auto-Update:

1. **Polling** - Client cek update setiap 8-16 jam (random)
2. **Push Check** - Client cek push update setiap heartbeat (5 menit)
3. **Download** - Download package + verify checksum
4. **Backup** - Backup current installation
5. **Extract** - Extract new version
6. **Restart** - Restart dengan version baru
7. **Notify** - Notify server: update completed
8. **Cleanup** - Remove backup after 7 days

### Server Migration (IP → Domain):

Client yang masih connect ke IP lama akan **otomatis migrate** ke domain baru:

1. Client cek update ke IP lama `http://103.129.149.67`
2. Server response dengan `server_url: "https://tenjo.adilabs.id"`
3. Client detect dan auto-switch ke domain baru
4. Client persist domain baru ke config
5. Next restart langsung pake domain baru

**IP lama sudah masuk `LEGACY_SERVER_URLS`**, tidak akan jadi primary server.

## ⚠️ Troubleshooting

### SSH Connection Failed
```bash
# Test koneksi
ssh -v root@tenjo.adilabs.id

# Jika port custom
ssh -p 2222 root@tenjo.adilabs.id

# Specify key file
ssh -i ~/.ssh/tenjo_key root@tenjo.adilabs.id
```

### SCP Upload Failed
```bash
# Check VPS path writable
ssh root@tenjo.adilabs.id "ls -la /var/www/html/tenjo/public/downloads"

# Create directory jika belum ada
ssh root@tenjo.adilabs.id "mkdir -p /var/www/html/tenjo/public/downloads/client"

# Set permissions
ssh root@tenjo.adilabs.id "chown -R www-data:www-data /var/www/html/tenjo/public/downloads"
```

### API Trigger Failed

**401 Unauthorized:**
- Check `TENJO_ADMIN_TOKEN` valid
- Token expired? Generate new token di dashboard

**404 Not Found:**
- Check API URL correct
- Check client_id exists

**500 Internal Server Error:**
- Check Laravel logs: `ssh root@tenjo.adilabs.id "tail -f /var/www/html/tenjo/storage/logs/laravel.log"`

### Client Not Updating

**Check client logs:**
```bash
# macOS
tail -f ~/Library/Application\ Support/Tenjo/logs/auto_update.log

# Linux
tail -f ~/.tenjo/logs/auto_update.log

# Windows
Get-Content $env:APPDATA\Tenjo\logs\auto_update.log -Tail 50 -Wait
```

**Force update check:**
```bash
# Set environment variable untuk debug
export TENJO_UPDATE_DEBUG=1

# Manual trigger dari client
python3 -c "
from src.utils.auto_update import ClientUpdater
from src.core.config import Config
Config.init_directories()
updater = ClientUpdater(Config)
has_update, info = updater.check_for_updates(force=True)
print(f'Has update: {has_update}')
print(f'Info: {info}')
"
```

## 📝 Best Practices

1. **Test Package Locally First**
   ```bash
   # Extract and test
   tar -xzf build/tenjo_client_1.0.1.tar.gz
   cd tenjo_client
   python3 main.py  # Test run
   ```

2. **Gradual Rollout**
   - Deploy ke 1-2 test clients dulu
   - Monitor 24 jam
   - Jika stable, rollout ke semua clients

3. **Use Update Windows**
   - Schedule update jam non-working hours
   - Avoid peak usage times
   - Set `window_start` dan `window_end`

4. **Priority Levels**
   - `normal` - Update saat window
   - `high` - Update ASAP tapi respect window
   - `critical` - Force update immediately (security fixes)

5. **Backup Strategy**
   - Client auto-backup sebelum update
   - Keep backups 7 days
   - Manual rollback jika needed

6. **Version Naming**
   - Semantic versioning: `MAJOR.MINOR.PATCH`
   - Example: `1.0.0` → `1.0.1` (patch), `1.1.0` (minor), `2.0.0` (major)

## 🎉 Quick Start Example

```bash
# 1. Setup SSH
ssh-copy-id root@tenjo.adilabs.id

# 2. Set environment
export TENJO_ADMIN_TOKEN="your_token_here"

# 3. Run deployment
./deploy_update.sh

# Interactive prompts:
# Version: 1.0.1
# Changes: 
#   - Fixed streaming bug
#   - Improved stability
#   - (empty line)
# Trigger mode: 2 (all clients)
# Confirm: yes

# 4. Monitor
# Check dashboard atau API untuk status update
```

## 📚 Resources

- **Dashboard**: https://tenjo.adilabs.id/dashboard
- **API Docs**: https://tenjo.adilabs.id/api/docs
- **GitHub**: https://github.com/Adi-Sumardi/Tenjo

## 🆘 Support

Jika ada masalah:
1. Check logs di VPS: `/var/www/html/tenjo/storage/logs/laravel.log`
2. Check client logs: `~/Library/Application Support/Tenjo/logs/`
3. Contact: your-email@example.com
