# 🚀 Deployment Checklist - Production Ready

**Date**: October 2, 2025  
**Version**: 2025.10.02  
**VPS**: 103.129.149.67  
**Domain**: tenjo.adilabs.id  

---

## ✅ Pre-Deployment Checklist

### 1. Code & Repository
- [x] All unnecessary .md files deleted (9 files cleaned)
- [x] Redundant scripts removed
- [x] Git status checked
- [x] Ready to commit and push to GitHub

### 2. Database Configuration
**Production Environment (.env.production on VPS):**
```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=tenjo_production
DB_USERNAME=tenjo_user
DB_PASSWORD=tenjo_secure_2025
```

### 3. Deployment Scripts
- [x] `deploy_production.sh` - Executable ✓
- [x] `mass_deploy.sh` - Executable ✓
- [x] `silent_push_deploy.sh` - Executable ✓
- [x] `cleanup_duplicate_clients.php` - Ready ✓

### 4. Auto-Update System
- [x] `client/src/utils/auto_update.py` - Silent mode implemented
- [x] API endpoints added (`/check-update`, `/update-completed`)
- [x] Database migration created (update tracking fields)
- [x] Controller methods implemented (checkUpdate, updateCompleted)

---

## 📋 GitHub Push Steps

### Step 1: Add All Changes
```bash
cd /Users/yapi/Adi/App-Dev/Tenjo

# Add new files
git add SILENT_PUSH_DEPLOYMENT_GUIDE.md
git add cleanup_duplicate_clients.php
git add client/src/utils/auto_update.py
git add dashboard/database/migrations/2025_10_02_000001_add_update_fields_to_clients_table.php
git add dashboard/scripts/cleanup-database.sh
git add deploy_production.sh
git add mass_deploy.sh
git add silent_push_deploy.sh

# Add modified files
git add client/main.py
git add client/src/core/config.py
git add client/src/modules/browser_tracker.py
git add dashboard/app/Http/Controllers/Api/ClientController.php
git add dashboard/routes/api.php
git add dashboard/config/cors.php

# Add deleted files
git add -u
```

### Step 2: Commit
```bash
git commit -m "feat: Silent push deployment system with auto-update

- Implemented completely silent update mechanism (users see nothing)
- Added auto-update module with version 2025.10.02
- Created silent_push_deploy.sh for VPS-triggered updates
- Added API endpoints: /check-update and /update-completed
- Database migration for update tracking (pending_update, current_version, etc.)
- Triple redundancy for client_id persistence (Registry + File + Hardware)
- Cleanup duplicate clients script (46 → 20 clients)
- Updated SERVER_URL to https://tenjo.adilabs.id
- Deployment scripts: deploy_production.sh, mass_deploy.sh
- Documentation: SILENT_PUSH_DEPLOYMENT_GUIDE.md

BREAKING CHANGES:
- Client now checks for pushed updates every heartbeat (5 min)
- Update process is completely invisible to users
- Requires database migration on VPS

Closes #1 - Silent deployment system
Closes #2 - Client ID persistence fix
Closes #3 - Auto-update implementation"
```

### Step 3: Push to GitHub
```bash
git push origin master
```

---

## 🔧 VPS Deployment Steps

### Phase 1: Preparation (5 minutes)

```bash
# 1. SSH to VPS
ssh tenjo-app@103.129.149.67

# 2. Backup database first!
cd /var/www/Tenjo
pg_dump -U tenjo_user tenjo_production > backup_$(date +%Y%m%d_%H%M%S).sql

# 3. Pull latest code
cd /var/www/Tenjo/dashboard
git pull origin master

# Expected output:
# Updating files...
# - SILENT_PUSH_DEPLOYMENT_GUIDE.md
# - client/src/utils/auto_update.py
# - dashboard/database/migrations/...
# - (etc.)
```

### Phase 2: Database Migration (2 minutes)

```bash
# 1. Run migration
cd /var/www/Tenjo/dashboard
php artisan migrate --force

# Expected output:
# Running migrations...
# 2025_10_02_000001_add_update_fields_to_clients_table .................. DONE

# 2. Verify migration
php artisan tinker --execute="
use Illuminate\Support\Facades\Schema;
\$fields = ['pending_update', 'update_version', 'update_url', 'update_changes', 'update_triggered_at', 'update_completed_at', 'current_version'];
foreach (\$fields as \$field) {
    \$exists = Schema::hasColumn('clients', \$field);
    echo \$field . ': ' . (\$exists ? '✅' : '❌') . PHP_EOL;
}
"

# Expected: All fields show ✅
```

### Phase 3: Cleanup Duplicates (5 minutes)

```bash
# 1. Copy cleanup script to VPS
cd /var/www/Tenjo
# (Script already in repo, pulled via git)

# 2. Dry-run first
php cleanup_duplicate_clients.php --dry-run

# Expected output:
# Found 26 duplicate clients (46 total → 20 unique)
# DRY RUN - No changes made

# 3. Execute cleanup
php cleanup_duplicate_clients.php

# Expected output:
# Deleted 26 duplicate clients
# ✅ Cleanup completed

# 4. Verify
php artisan tinker --execute="
echo 'Total clients: ' . \App\Models\Client::count() . PHP_EOL;
echo 'Active (24h): ' . \App\Models\Client::where('last_seen', '>', now()->subHours(24))->count() . PHP_EOL;
"

# Expected: ~20-21 clients total
```

### Phase 4: Deploy Scripts Setup (3 minutes)

```bash
# 1. Make scripts executable
cd /var/www/Tenjo
chmod +x deploy_production.sh mass_deploy.sh silent_push_deploy.sh

# 2. Create packages directory
mkdir -p /var/www/Tenjo/packages
chmod 755 /var/www/Tenjo/packages

# 3. Verify deployment files
ls -lh *.sh *.php

# Expected:
# -rwxr-xr-x deploy_production.sh
# -rwxr-xr-x mass_deploy.sh
# -rwxr-xr-x silent_push_deploy.sh
# -rw-r--r-- cleanup_duplicate_clients.php
```

### Phase 5: Test Deployment (10 minutes)

```bash
# 1. From Mac - build and upload package
cd /Users/yapi/Adi/App-Dev/Tenjo
./deploy_production.sh 2025.10.02

# Expected output:
# [1/6] Building client package...
# [2/6] Uploading to VPS...
# [3/6] Creating install scripts...
# [4/6] Setting up download endpoints...
# [5/6] Updating version.json...
# [6/6] Deployment complete!
#
# Download URL: https://tenjo.adilabs.id/downloads/client/tenjo_client_2025.10.02.tar.gz

# 2. Test on 1 PC first
# On test Windows PC:
irm https://tenjo.adilabs.id/downloads/client/install.ps1 | iex

# 3. Verify client registered
# Back on VPS:
php artisan tinker --execute="
\$latest = \App\Models\Client::orderBy('created_at', 'desc')->first();
echo 'Latest client: ' . \$latest->hostname . PHP_EOL;
echo 'Client ID: ' . \$latest->client_id . PHP_EOL;
echo 'Version: ' . (\$latest->current_version ?? 'old') . PHP_EOL;
"

# 4. Restart test PC and verify same client_id (no duplicate!)
```

### Phase 6: Silent Push Test (10 minutes)

```bash
# 1. On VPS - trigger silent update for 1 PC
cd /var/www/Tenjo

# Temporarily modify silent_push_deploy.sh to target only 1 hostname
# OR use SQL to set pending_update manually:
php artisan tinker --execute="
\$client = \App\Models\Client::where('hostname', 'DESKTOP-TEST')->first();
\$client->pending_update = true;
\$client->update_version = '2025.10.02';
\$client->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_2025.10.02.tar.gz';
\$client->update_triggered_at = now();
\$client->save();
echo '✅ Update triggered for ' . \$client->hostname . PHP_EOL;
"

# 2. Monitor client (should update within 5 minutes)
watch -n 5 "php artisan tinker --execute=\"
\$client = \App\Models\Client::where('hostname', 'DESKTOP-TEST')->first();
echo 'Pending: ' . (\$client->pending_update ? 'YES' : 'NO') . PHP_EOL;
echo 'Version: ' . (\$client->current_version ?? 'old') . PHP_EOL;
echo 'Completed: ' . (\$client->update_completed_at ? \$client->update_completed_at->format('H:i:s') : 'N/A') . PHP_EOL;
\""

# Expected after 5 min:
# Pending: NO
# Version: 2025.10.02
# Completed: 23:45:30

# 3. Verify user didn't see anything! ✅
```

### Phase 7: Mass Deployment (30 minutes)

```bash
# 1. Deploy to all 20 PCs
cd /var/www/Tenjo
./silent_push_deploy.sh 2025.10.02

# Expected:
# ╔══════════════════════════════════════════════════════════╗
# ║      Tenjo Silent Push Deployment v2025.10.02           ║
# ╚══════════════════════════════════════════════════════════╝
# 
# [1/5] Fetching active clients from database...
# ✓ Found 20 active clients
# 
# ... (shows all PCs)
# 
# 🚀 Silent push update to 20 clients? (y/N): y
# 
# ✅ All clients queued for silent update

# 2. Monitor progress
watch -n 10 "php artisan tinker --execute=\"
\$pending = \App\Models\Client::where('pending_update', true)->count();
\$updated = \App\Models\Client::where('current_version', '2025.10.02')->count();
echo 'Pending: ' . \$pending . ' / Updated: ' . \$updated . ' / 20' . PHP_EOL;
\""

# Wait for all to complete (~10-20 minutes)

# 3. Final verification
php artisan tinker --execute="
\$all = \App\Models\Client::count();
\$updated = \App\Models\Client::where('current_version', '2025.10.02')->count();
\$duplicates = \App\Models\Client::select('hostname', \DB::raw('COUNT(*) as count'))
    ->groupBy('hostname')
    ->havingRaw('COUNT(*) > 1')
    ->count();

echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo '           DEPLOYMENT SUMMARY             ' . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo 'Total clients:    ' . \$all . PHP_EOL;
echo 'Updated to v2025.10.02: ' . \$updated . PHP_EOL;
echo 'Duplicates:       ' . \$duplicates . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo (\$all == \$updated && \$duplicates == 0) ? '✅ SUCCESS!' : '⚠️ CHECK NEEDED' . PHP_EOL;
"

# Expected:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#            DEPLOYMENT SUMMARY             
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Total clients:    20
# Updated to v2025.10.02: 20
# Duplicates:       0
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ✅ SUCCESS!
```

---

## 🔒 Post-Deployment Tasks

### 1. DNS & SSL Setup (if not done)
```bash
# Check DNS
dig tenjo.adilabs.id +short
# Should return: 103.129.149.67

# Install SSL
sudo certbot --nginx -d tenjo.adilabs.id

# Verify HTTPS
curl -I https://tenjo.adilabs.id
# Should return: HTTP/2 200
```

### 2. Monitoring Setup
```bash
# Add to crontab for daily monitoring
crontab -e

# Add this line:
0 2 * * * cd /var/www/Tenjo/dashboard && php artisan tinker --execute="\$dups = \App\Models\Client::select('hostname', \DB::raw('COUNT(*) as count'))->groupBy('hostname')->havingRaw('COUNT(*) > 1')->count(); if (\$dups > 0) echo 'WARNING: ' . \$dups . ' duplicate clients found';"
```

### 3. Backup Automation
```bash
# Add daily database backup
crontab -e

# Add this line:
0 3 * * * pg_dump -U tenjo_user tenjo_production | gzip > /var/www/Tenjo/backups/db_$(date +\%Y\%m\%d).sql.gz
```

---

## 📊 Success Criteria

- ✅ GitHub push successful (all commits uploaded)
- ✅ Database migration completed (7 new fields added)
- ✅ Duplicate clients cleaned (46 → 20)
- ✅ All 20 PCs updated to version 2025.10.02
- ✅ No new duplicates created after deployment
- ✅ Silent update working (users see nothing!)
- ✅ API endpoints responding correctly
- ✅ HTTPS working (if DNS configured)

---

## 🆘 Rollback Plan (If Needed)

### Emergency Rollback:
```bash
# 1. Restore database backup
cd /var/www/Tenjo
psql -U tenjo_user tenjo_production < backup_YYYYMMDD_HHMMSS.sql

# 2. Cancel all pending updates
php artisan tinker --execute="
\App\Models\Client::where('pending_update', true)->update(['pending_update' => false]);
echo '✅ All updates cancelled' . PHP_EOL;
"

# 3. Revert code (if needed)
git reset --hard HEAD~1
```

---

## 📝 Notes

1. **Silent Mode**: Users akan NOT see anything during update - completely transparent!
2. **Deployment Time**: ~10-20 minutes for all 20 PCs (vs 1-2 hours manual)
3. **Heartbeat**: Clients check every 5 minutes, so update propagates quickly
4. **Backup**: Always backup database before major changes!
5. **Monitoring**: Watch progress with provided commands

---

## ✅ READY TO DEPLOY! 🚀

**Next Action:**
```bash
# 1. Push to GitHub
cd /Users/yapi/Adi/App-Dev/Tenjo
git add -A
git commit -m "feat: Silent push deployment system"
git push origin master

# 2. Deploy to VPS
ssh tenjo-app@103.129.149.67
cd /var/www/Tenjo/dashboard
git pull origin master
php artisan migrate --force
```

**User Experience:** 🤫 COMPLETELY SILENT - Users won't know anything! ✨
