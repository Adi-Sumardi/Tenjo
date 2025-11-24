# Tenjo Auto Update System

## Overview

Sistem auto update memungkinkan client Tenjo untuk update otomatis tanpa intervensi manual. Mendukung dua mode: **Push Update** (server-initiated) dan **Public Channel** (periodic check).

## Architecture

```
┌─────────────────┐          ┌──────────────────┐
│  Client Agent   │◄────────►│  Laravel Server  │
│                 │          │                  │
│ ClientUpdater   │          │ ClientController │
│  - Check update │          │  - Push trigger  │
│  - Download     │          │  - version.json  │
│  - Apply        │          │  - .tar.gz       │
│  - Rollback     │          │                  │
└─────────────────┘          └──────────────────┘
        │                             │
        │                             │
        ▼                             ▼
┌─────────────────┐          ┌──────────────────┐
│   Local Files   │          │   Public Files   │
│                 │          │                  │
│ .pending_update │          │ /downloads/      │
│ .update_tmp/    │          │   client/        │
│ .version        │          │   - version.json │
└─────────────────┘          │   - *.tar.gz     │
                             └──────────────────┘
```

## Fixed Bugs (v1.0.3)

### ✅ BUG #21: version.json File Missing
**Problem**: Server tidak memiliki `version.json` endpoint
**Fix**: Created `/public/downloads/client/version.json`
**Impact**: Public channel update check sekarang bekerja

### ✅ BUG #22-23: Version Info Not Saved
**Problem**: `apply_update()` hanya menulis timestamp, bukan version actual
**Fix**: Modified `apply_update()` to accept and use `version_info`
**Impact**: Version tracking sekarang akurat

### ✅ BUG #24: Downloads Directory Missing
**Problem**: Directory structure untuk packages tidak ada
**Fix**: Created `/public/downloads/client/` with `.gitkeep`
**Impact**: Update packages bisa disimpan dengan proper structure

### ✅ BUG #25: Config Initialization Race Condition
**Problem**: `DATA_DIR` bisa None jika `Config.init_directories()` belum dipanggil
**Fix**: Added fallback ke platform-specific default directories
**Impact**: ClientUpdater tidak crash saat initialization

### ✅ BUG #26: No Signature Verification
**Problem**: Signature field ada tapi tidak diverifikasi (security risk)
**Fix**: Added placeholder + logging, relies on HTTPS + checksum
**Impact**: Security documented, TODO added for RSA verification

### ✅ BUG #27: Cleanup Not Running Before Restart
**Problem**: `os._exit(0)` dipanggil sebelum cleanup selesai
**Fix**: Moved `cleanup_temp()` before `restart_client()` + added delays
**Impact**: Temp files sekarang dibersihkan dengan benar

### ✅ BUG #28: No Rollback Mechanism
**Problem**: Update failure meninggalkan corrupted installation
**Fix**: Added rollback to backup on `apply_update()` failure
**Impact**: Failed updates tidak merusak client installation

## Update Flow

### 1. Push Update (Server-Initiated)

```python
# Server triggers update via Dashboard
POST /api/clients/{clientId}/trigger-update
{
    "version": "1.0.3",
    "update_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.3.tar.gz",
    "checksum": "sha256_hash_here",
    "priority": "critical",
    "window_start": "02:00",
    "window_end": "06:00"
}

# Client checks for updates
GET /api/clients/{clientId}/check-update
Response: {has_update: true, version: "1.0.3", ...}

# Client downloads and applies update
# Client notifies completion
POST /api/clients/{clientId}/update-completed
{
    "version": "1.0.3",
    "completed_at": "2025-11-24T12:00:00Z"
}
```

### 2. Public Channel (Periodic Check)

```python
# Client checks public version.json (every 8-16 hours random)
GET /downloads/client/version.json
Response: {
    "version": "1.0.3",
    "download_url": "/downloads/client/tenjo_client_1.0.3.tar.gz",
    "checksum": "sha256_hash",
    ...
}

# If newer version available, download and apply
# No server notification (fire-and-forget)
```

## Creating Update Package

### Step 1: Prepare Client Files

```bash
cd /Users/yapi/Adi/App-Dev/Tenjo/client

# Create package tarball
tar -czf tenjo_client_1.0.3.tar.gz \
    main.py \
    src/ \
    requirements.txt \
    os_detector.py
```

### Step 2: Generate Checksum

```bash
# Generate SHA256 checksum
shasum -a 256 tenjo_client_1.0.3.tar.gz

# Output example:
# abc123def456... tenjo_client_1.0.3.tar.gz
```

### Step 3: Update version.json

```bash
cd /Users/yapi/Adi/App-Dev/Tenjo/dashboard/public/downloads/client

# Edit version.json
nano version.json
```

```json
{
    "version": "1.0.3",
    "download_url": "/downloads/client/tenjo_client_1.0.3.tar.gz",
    "checksum": "abc123def456...",
    "package_size": 1234567,
    "changes": [
        "Fixed browser tracking bugs",
        "Enhanced auto update system"
    ],
    "priority": "normal",
    "server_url": "https://tenjo.adilabs.id",
    "release_date": "2025-11-24"
}
```

### Step 4: Upload to Server

```bash
# Copy package to server public directory
cp tenjo_client_1.0.3.tar.gz /path/to/dashboard/public/downloads/client/

# Verify permissions
chmod 644 /path/to/dashboard/public/downloads/client/tenjo_client_1.0.3.tar.gz
chmod 644 /path/to/dashboard/public/downloads/client/version.json
```

## Update Priorities

### normal (default)
- Respects update window
- Random scheduling (8-16 hours)
- Non-disruptive

### high
- Executed during update window
- Shorter retry interval (2-4 hours)

### critical
- **IMMEDIATE** execution (ignores window)
- Forces update regardless of time
- Use for security patches only

## Update Windows

Update windows mengontrol kapan update dijalankan (timezone-aware):

```php
// Example: Update only during night hours
"window_start": "02:00",  // 2 AM
"window_end": "06:00"     // 6 AM

// If current time outside window:
// - Client defers update until window opens
// - Calculates seconds until next window
// - Schedules retry accordingly
```

## Rollback Mechanism

Jika update gagal, sistem otomatis rollback:

```python
# 1. Backup created before update
backup_success, backup_dir = self.backup_current_installation()

# 2. Apply update
if not self.apply_update(package_path, version_info):
    # 3. Rollback on failure
    if backup_success and backup_dir.exists():
        shutil.rmtree(self.install_path)
        shutil.copytree(backup_dir, self.install_path)
        # Client continues running with old version
```

## Security

### Current Implementation
- ✅ HTTPS transport encryption
- ✅ SHA256 checksum verification
- ✅ Package size validation
- ⚠️ Signature verification (TODO)

### Planned Enhancements
- [ ] RSA signature verification with public key
- [ ] Certificate pinning
- [ ] Rollback signing

## Testing

### Test Push Update

```bash
# Via Dashboard or API
curl -X POST https://tenjo.adilabs.id/api/clients/{clientId}/trigger-update \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0.3",
    "update_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.3.tar.gz",
    "checksum": "abc123...",
    "priority": "normal"
  }'
```

### Test Public Channel

```bash
# Check version.json accessible
curl https://tenjo.adilabs.id/downloads/client/version.json

# Check package downloadable
curl -I https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.3.tar.gz
```

### Force Update Check (Development)

```python
# In client code
from src.utils.auto_update import check_and_update_if_needed
from src.core.config import Config

# Force immediate check (bypass schedule)
check_and_update_if_needed(Config, force=True)
```

## Monitoring

### Client Logs

```bash
# Auto update logs
# Windows: %LOCALAPPDATA%\Tenjo\logs\auto_update.log
# macOS: ~/Library/Logs/Tenjo/auto_update.log
# Linux: ~/.tenjo/logs/auto_update.log

tail -f ~/Library/Logs/Tenjo/auto_update.log
```

### Server Logs

```bash
# Laravel logs
tail -f /path/to/dashboard/storage/logs/laravel.log | grep -i update
```

### Database Records

```sql
-- Check pending updates
SELECT client_id, hostname, pending_update, update_version, update_priority
FROM clients
WHERE pending_update = 1;

-- Check completed updates
SELECT client_id, hostname, current_version, update_completed_at
FROM clients
WHERE update_completed_at IS NOT NULL
ORDER BY update_completed_at DESC;
```

## Troubleshooting

### Client Not Updating

1. **Check version.json accessible**
   ```bash
   curl https://tenjo.adilabs.id/downloads/client/version.json
   ```

2. **Check client logs**
   ```bash
   grep -i "update" ~/Library/Logs/Tenjo/auto_update.log
   ```

3. **Force update check**
   ```python
   check_and_update_if_needed(Config, force=True)
   ```

### Update Fails with Checksum Error

1. **Regenerate checksum**
   ```bash
   shasum -a 256 tenjo_client_1.0.3.tar.gz
   ```

2. **Update version.json with correct checksum**

3. **Verify package not corrupted**
   ```bash
   tar -tzf tenjo_client_1.0.3.tar.gz
   ```

### Update Stuck in Pending

1. **Check update window**
   ```sql
   SELECT update_window_start, update_window_end, timezone
   FROM clients WHERE client_id = 'xxx';
   ```

2. **Set critical priority**
   ```bash
   # Via API to force immediate update
   ```

3. **Cancel and retry**
   ```bash
   POST /api/clients/{clientId}/cancel-update
   POST /api/clients/{clientId}/trigger-update
   ```

## Best Practices

### For Production Deployment

1. **Test updates on staging first**
   - Deploy to test client
   - Verify functionality
   - Check logs for errors

2. **Use gradual rollout**
   - Update 10% of clients first
   - Monitor for 24 hours
   - Roll out to remaining clients

3. **Schedule during low usage**
   - Use update windows (02:00-06:00)
   - Avoid business hours
   - Consider timezones

4. **Keep backups**
   - Automatic backups created
   - Verify backup directory exists
   - Test rollback procedure

5. **Monitor completion**
   - Check `update_completed_at` timestamps
   - Verify version numbers
   - Review error logs

## Files Reference

### Client-Side
- `client/src/utils/auto_update.py` - Main updater logic
- `client/main.py` - Calls `check_and_update_if_needed()`
- `.version` - Current version file
- `.pending_update.json` - Cached update metadata
- `.update_schedule.json` - Next check schedule

### Server-Side
- `dashboard/app/Http/Controllers/Api/ClientController.php` - Update endpoints
- `dashboard/public/downloads/client/version.json` - Public version metadata
- `dashboard/public/downloads/client/*.tar.gz` - Update packages
- `dashboard/database/migrations/*_add_update_fields_to_clients_table.php` - Database schema

### API Routes
- `GET /api/clients/{clientId}/check-update` - Check for updates
- `POST /api/clients/{clientId}/update-completed` - Report completion
- `POST /api/clients/{clientId}/trigger-update` - Trigger update (auth required)
- `POST /api/clients/{clientId}/cancel-update` - Cancel pending (auth required)
- `GET /downloads/client/version.json` - Public version info

## Version History

- **v1.0.3** (2025-11-24) - Fixed 8 critical auto update bugs
- **v1.0.2** (2025-11-23) - Browser tracking improvements
- **v1.0.1** (2025-11-22) - Initial production release
- **v1.0.0** (2025-11-20) - First stable release
