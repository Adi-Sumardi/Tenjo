# 🚀 Termius Setup & VPS Deployment Guide

Panduan lengkap untuk setup Termius dan deploy update ke VPS Tenjo.

---

## 📱 Part 1: Setup Termius

### 1.1 Download Termius

**Desktop:**
- **Windows**: https://termius.com/download/windows
- **macOS**: https://termius.com/download/macos
- **Linux**: https://termius.com/download/linux

**Mobile:**
- **iOS**: https://apps.apple.com/app/termius-ssh-client/id549039908
- **Android**: https://play.google.com/store/apps/details?id=com.server.auditor.ssh.client

### 1.2 Setup Host Configuration

1. Open Termius
2. Click **"New Host"** atau **"+"** button
3. Fill in details:

```
┌─────────────────────────────────────────┐
│ Host Configuration                      │
├─────────────────────────────────────────┤
│ Label:     Tenjo VPS Production         │
│ Address:   tenjo.adilabs.id             │
│            (atau 103.129.149.67)        │
│ Port:      22                           │
│ Username:  root                         │
│ Password:  [your_vps_password]          │
└─────────────────────────────────────────┘
```

4. **Optional**: Add to group "Production Servers"
5. Click **"Save"**

### 1.3 Setup SSH Key Authentication (Recommended)

**Generate Key di Termius:**

1. Go to **Settings** → **Keychain** → **Keys**
2. Click **"+ New Key"**
3. Configure:
   ```
   Label: Tenjo VPS Key
   Type: RSA
   Length: 4096 bits
   Passphrase: [optional - untuk extra security]
   ```
4. Click **"Generate"**
5. **Copy Public Key** yang muncul

**Add Public Key ke VPS:**

1. Connect ke VPS dengan password (temporary)
2. Run commands:
   ```bash
   # Create .ssh directory jika belum ada
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   
   # Add public key
   nano ~/.ssh/authorized_keys
   # Paste public key dari Termius
   # Save: Ctrl+O, Enter, Ctrl+X
   
   # Set permissions
   chmod 600 ~/.ssh/authorized_keys
   
   # Restart SSH service
   systemctl restart sshd
   ```

3. **Test**: Disconnect dan reconnect - seharusnya tidak perlu password lagi!

### 1.4 Termius Useful Features

**Port Forwarding:**
- Settings → Port Forwarding
- Local: 8000 → Remote: 8000 (untuk access Laravel dev server)

**SFTP File Transfer:**
- Click SFTP icon (folder icon) setelah connect
- Drag & drop files untuk upload

**Snippets:**
- Save frequently used commands
- Quick access dengan shortcut

---

## 🚀 Part 2: Deploy Update ke VPS

### Method 1: Automated Deploy dari Local (RECOMMENDED) ⭐

**Setup One-Time:**

```bash
# 1. Setup SSH key untuk passwordless login
ssh-keygen -t rsa -b 4096 -C "tenjo-deployment"
ssh-copy-id root@tenjo.adilabs.id

# 2. Set environment variables (tambah ke ~/.zshrc)
echo 'export VPS_HOST="tenjo.adilabs.id"' >> ~/.zshrc
echo 'export VPS_USER="root"' >> ~/.zshrc
echo 'export TENJO_ADMIN_TOKEN="your_token_here"' >> ~/.zshrc
source ~/.zshrc

# 3. Test connection
ssh root@tenjo.adilabs.id "echo 'Connection OK'"
```

**Deploy Update:**

```bash
cd /Users/yapi/Adi/App-Dev/Tenjo

# Run full automated deployment
./deploy_update.sh

# Interactive prompts:
# - Version: 1.0.1
# - Changes: [enter your changes]
# - Trigger: [choose 1/2/3]
```

**What it does:**
1. ✅ Build package locally
2. ✅ Generate checksum (SHA256)
3. ✅ Create version.json
4. ✅ Upload to VPS via SCP
5. ✅ Set permissions
6. ✅ Trigger client updates (optional)

---

### Method 2: Quick Deploy (Package Sudah Built)

Jika sudah pernah run `deploy_update.sh` dan package sudah ada di `client/build/`:

```bash
# Make executable
chmod +x quick_deploy.sh

# Deploy
./quick_deploy.sh 1.0.1
```

---

### Method 3: Manual via Termius Terminal

**Step 1: Build Package di Local**

```bash
cd /Users/yapi/Adi/App-Dev/Tenjo/client

# Clean
find . -name __pycache__ -exec rm -rf {} + 2>/dev/null
find . -name "*.pyc" -delete

# Set version
VERSION="1.0.1"
echo "$VERSION" > .version

# Create package
tar -czf "tenjo_client_${VERSION}.tar.gz" \
  main.py \
  requirements.txt \
  src/ \
  install_autostart.sh \
  install_autostart.ps1 \
  uninstall_autostart.sh \
  uninstall_autostart.ps1
  
# Generate checksum (save this!)
shasum -a 256 "tenjo_client_${VERSION}.tar.gz"
```

**Step 2: Upload via Termius**

**Option A: SFTP (GUI)**
1. Connect to VPS in Termius
2. Click **SFTP** icon
3. Navigate to: `/var/www/html/tenjo/public/downloads/client`
4. Drag & drop `tenjo_client_1.0.1.tar.gz`

**Option B: SCP Command**
```bash
# From local terminal (not connected to VPS)
scp tenjo_client_1.0.1.tar.gz root@tenjo.adilabs.id:/var/www/html/tenjo/public/downloads/client/
```

**Step 3: Create version.json on VPS**

Connect to VPS via Termius dan run:

```bash
cd /var/www/html/tenjo/public/downloads/client

# Create version.json
cat > version.json << 'EOF'
{
  "version": "1.0.1",
  "download_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz",
  "server_url": "https://tenjo.adilabs.id",
  "changes": [
    "Fixed streaming auto-start issue",
    "Added automatic server migration",
    "Performance improvements"
  ],
  "checksum": "PASTE_SHA256_HERE",
  "package_size": 2048576,
  "priority": "normal",
  "release_date": "2025-10-06T12:00:00Z"
}
EOF

# Get actual checksum
sha256sum tenjo_client_1.0.1.tar.gz

# Get actual package size
stat -c%s tenjo_client_1.0.1.tar.gz

# Edit version.json dengan values yang benar
nano version.json
# Update checksum dan package_size
# Ctrl+O (save), Enter, Ctrl+X (exit)

# Set permissions
chmod 644 tenjo_client_1.0.1.tar.gz version.json
chown www-data:www-data tenjo_client_1.0.1.tar.gz version.json

# Verify
ls -lh
cat version.json
```

**Step 4: Verify Upload**

```bash
# Test download URL
curl -I https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz

# Should return: HTTP/2 200 OK

# Test version.json
curl https://tenjo.adilabs.id/downloads/client/version.json | jq '.'
```

---

## 🎯 Part 3: Trigger Client Updates

### Option 1: Via Dashboard (Easy)

1. Login: https://tenjo.adilabs.id/dashboard
2. Go to **Clients** page
3. Select client(s) to update
4. Click **"Trigger Update"**
5. Fill form:
   - Version: `1.0.1`
   - Package URL: `https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz`
   - Priority: `normal` / `high` / `critical`
6. Click **"Schedule Update"**

### Option 2: Via API (Termius Terminal)

**Trigger Single Client:**

```bash
# Get admin token dari dashboard first
ADMIN_TOKEN="your_admin_token_here"
CLIENT_ID="client_id_here"

curl -X POST "https://tenjo.adilabs.id/api/clients/${CLIENT_ID}/trigger-update" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0.1",
    "update_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz",
    "changes": [
      "Fixed streaming bug",
      "Improved stability"
    ],
    "checksum": "sha256_here",
    "priority": "normal"
  }'
```

**Trigger All Clients (Bulk):**

```bash
curl -X POST "https://tenjo.adilabs.id/api/clients/schedule-update" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0.1",
    "update_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz",
    "priority": "high"
  }'
```

### Option 3: Automatic (Clients Poll Every 8-16 Hours)

Clients will **automatically detect** new version from `version.json`:
- No trigger needed
- Clients check every 8-16 hours (randomized)
- Auto-update when detected

---

## 📊 Part 4: Monitor Updates

### Check Update Status

**Via Dashboard:**
1. Go to **Clients** page
2. Check columns:
   - **Current Version**
   - **Pending Update** (Yes/No)
   - **Update Version**
   - **Last Seen**

**Via API:**

```bash
# Check specific client
curl "https://tenjo.adilabs.id/api/clients/${CLIENT_ID}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq '.'

# List all clients
curl "https://tenjo.adilabs.id/api/clients?per_page=100" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq '.clients[] | {hostname, current_version, pending_update}'
```

**Via VPS Logs:**

```bash
# Connect to VPS
ssh root@tenjo.adilabs.id

# Watch Laravel logs
tail -f /var/www/html/tenjo/storage/logs/laravel.log

# Filter for update events
tail -f /var/www/html/tenjo/storage/logs/laravel.log | grep -i update
```

---

## 🔧 Part 5: Troubleshooting

### SSH Connection Issues

```bash
# Test connection
ssh -v root@tenjo.adilabs.id

# If timeout, check VPS firewall
ssh root@tenjo.adilabs.id
ufw status
ufw allow 22/tcp

# If permission denied
chmod 600 ~/.ssh/id_rsa
ssh-add ~/.ssh/id_rsa
```

### Upload Failed

```bash
# Check VPS directory exists
ssh root@tenjo.adilabs.id "ls -la /var/www/html/tenjo/public/downloads"

# Create if missing
ssh root@tenjo.adilabs.id "mkdir -p /var/www/html/tenjo/public/downloads/client"

# Check permissions
ssh root@tenjo.adilabs.id "chmod 755 /var/www/html/tenjo/public/downloads/client"
```

### Client Not Updating

**Check client logs:**

```bash
# macOS
tail -f ~/Library/Application\ Support/Tenjo/logs/auto_update.log

# Force update check (on client machine)
cd /path/to/client
TENJO_UPDATE_DEBUG=1 python3 -c "
from src.utils.auto_update import ClientUpdater
from src.core.config import Config
Config.init_directories()
updater = ClientUpdater(Config)
has_update, info = updater.check_for_updates(force=True)
print(f'Has update: {has_update}')
print(f'Info: {info}')
"
```

---

## 📝 Quick Reference Commands

```bash
# Connect to VPS
ssh root@tenjo.adilabs.id

# Upload file
scp file.tar.gz root@tenjo.adilabs.id:/path/to/destination/

# Download file from VPS
scp root@tenjo.adilabs.id:/path/to/file.tar.gz ~/Downloads/

# Run command on VPS
ssh root@tenjo.adilabs.id "ls -la /var/www/html/tenjo"

# Edit file on VPS
ssh root@tenjo.adilabs.id
nano /var/www/html/tenjo/public/downloads/client/version.json

# Check Laravel logs
ssh root@tenjo.adilabs.id "tail -100 /var/www/html/tenjo/storage/logs/laravel.log"

# Restart Laravel
ssh root@tenjo.adilabs.id "cd /var/www/html/tenjo && php artisan optimize:clear"
```

---

## 🎉 Summary

**Easiest Way to Deploy:**

1. **Setup SSH once**: `ssh-copy-id root@tenjo.adilabs.id`
2. **Run script**: `./deploy_update.sh`
3. **Done!** 🚀

**Using Termius:**
- Great for **monitoring** and **troubleshooting**
- Use **SFTP** for manual file uploads
- Save **snippets** for common commands
- Access from **mobile** when needed

**Best Practice:**
- Use automated script for deployments
- Use Termius for emergency access
- Monitor via dashboard
- Keep backups before major updates
