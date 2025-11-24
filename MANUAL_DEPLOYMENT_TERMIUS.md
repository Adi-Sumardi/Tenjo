# Manual Deployment via Termius - Step by Step

**Version:** 1.0.1 (Critical Bug Fixes)
**Date:** 2025-11-24
**Fixes:** BUG #44-58 (11 critical bugs fixed)

---

## 📋 Pre-Deployment Checklist

- [ ] SSH access ke VPS ready
- [ ] GitHub repo sudah di-push (commit `857759c`)
- [ ] Backup database (CRITICAL!)
- [ ] Client package siap di-build

---

## 🚀 PART 1: Build Package di Local (MacBook)

Jalankan di Terminal **local** (bukan Termius):

### Step 1: Navigate ke project directory
```bash
cd /Users/yapi/Adi/App-Dev/Tenjo
```

### Step 2: Clean build files
```bash
# Remove old build artifacts
rm -rf client/build/
mkdir -p client/build/

# Clean Python cache
find client -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find client -type f -name "*.pyc" -delete 2>/dev/null || true
```

### Step 3: Create package structure
```bash
# Create staging directory
mkdir -p client/build/tenjo_client

# Copy necessary files
cp client/main.py client/build/tenjo_client/
cp client/requirements.txt client/build/tenjo_client/
cp -r client/src client/build/tenjo_client/

# Copy watchdog (critical for auto-restart)
cp client/watchdog.py client/build/tenjo_client/ 2>/dev/null || true

# Copy OS detector
cp client/os_detector.py client/build/tenjo_client/ 2>/dev/null || true
cp client/ip_detector.py client/build/tenjo_client/ 2>/dev/null || true

# Create version file
echo "1.0.1" > client/build/tenjo_client/.version
```

### Step 4: Create tarball
```bash
cd client/build
tar -czf tenjo_client_1.0.1.tar.gz tenjo_client/

# Verify package created
ls -lh tenjo_client_1.0.1.tar.gz
```

### Step 5: Generate SHA256 checksum
```bash
# macOS
shasum -a 256 tenjo_client_1.0.1.tar.gz | awk '{print $1}'

# Save checksum to variable for later
CHECKSUM=$(shasum -a 256 tenjo_client_1.0.1.tar.gz | awk '{print $1}')
echo "Checksum: $CHECKSUM"
```

### Step 6: Create version.json
```bash
cat > version.json <<EOF
{
  "version": "1.0.1",
  "download_url": "https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz",
  "server_url": "https://tenjo.adilabs.id",
  "changes": [
    "fix: Fixed 4 critical subprocess stealth bugs (BUG #53-58)",
    "fix: CREATE_NO_WINDOW now works on Python 3.6+",
    "fix: Service installation fully stealth (no terminal pop-ups)",
    "fix: Client startup timeout protection",
    "fix: Auto-update powershell fallback stealth",
    "fix: Fixed 7 previous critical bugs (BUG #44-52)"
  ],
  "checksum": "$CHECKSUM",
  "package_size": $(stat -f%z tenjo_client_1.0.1.tar.gz),
  "priority": "high",
  "release_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "min_python_version": "3.6",
  "compatible_platforms": ["Windows", "macOS", "Linux"]
}
EOF

# Verify version.json
cat version.json | python3 -m json.tool
```

**✅ Package ready! Sekarang pindah ke Termius untuk upload ke VPS.**

---

## 🌐 PART 2: Upload ke VPS via Termius

### Step 1: Connect to VPS via Termius
```
Host: tenjo.adilabs.id (atau 103.129.149.67)
User: root (atau tenjo-app)
Port: 22
```

### Step 2: Buka terminal **local** baru (bukan Termius) untuk SCP upload

**Dari MacBook terminal:**

```bash
# Navigate to build directory
cd /Users/yapi/Adi/App-Dev/Tenjo/client/build

# Upload package ke VPS
scp tenjo_client_1.0.1.tar.gz root@tenjo.adilabs.id:/var/www/html/tenjo/public/downloads/client/

# Upload version.json
scp version.json root@tenjo.adilabs.id:/var/www/html/tenjo/public/downloads/client/

# Verify upload
ssh root@tenjo.adilabs.id "ls -lh /var/www/html/tenjo/public/downloads/client/"
```

**⚠️ Jika ada error "Permission denied":**
```bash
# Try dengan sudo atau ganti user
scp tenjo_client_1.0.1.tar.gz tenjo-app@tenjo.adilabs.id:/tmp/
scp version.json tenjo-app@tenjo.adilabs.id:/tmp/

# Lalu pindahkan via SSH (di Termius)
ssh root@tenjo.adilabs.id
sudo mv /tmp/tenjo_client_1.0.1.tar.gz /var/www/html/tenjo/public/downloads/client/
sudo mv /tmp/version.json /var/www/html/tenjo/public/downloads/client/
sudo chmod 644 /var/www/html/tenjo/public/downloads/client/*
```

---

## 📡 PART 3: Verify Upload (Di Termius)

**SSH ke VPS (di Termius):**

### Step 1: Check files uploaded
```bash
ssh root@tenjo.adilabs.id

# Check download directory
ls -lh /var/www/html/tenjo/public/downloads/client/

# Expected output:
# -rw-r--r-- 1 root root  XXXK Nov 24 HH:MM tenjo_client_1.0.1.tar.gz
# -rw-r--r-- 1 root root  XXX  Nov 24 HH:MM version.json
```

### Step 2: Verify checksum on server
```bash
cd /var/www/html/tenjo/public/downloads/client/

# Calculate checksum on server
sha256sum tenjo_client_1.0.1.tar.gz

# Compare with version.json checksum
cat version.json | grep checksum

# Both should match!
```

### Step 3: Test download URL
```bash
# Test dari VPS
curl -I https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz

# Expected: HTTP 200 OK

# Test version.json
curl https://tenjo.adilabs.id/downloads/client/version.json | jq '.'
```

---

## 🎯 PART 4: Update Database Schema (Di Termius)

**Masih di SSH Termius:**

### Step 1: Navigate to dashboard
```bash
cd /var/www/Tenjo/dashboard
```

### Step 2: Check current git status
```bash
git status
git log --oneline -5

# Expected: Should show latest commits with bug fixes
```

### Step 3: Pull latest code (if needed)
```bash
git pull origin master
```

### Step 4: Run migrations (if any)
```bash
php artisan migrate --force

# Expected output:
# Nothing to migrate (if schema already updated)
# OR
# Migration table created successfully
# Migrated: YYYY_MM_DD_XXXXXX_migration_name
```

### Step 5: Verify database columns exist
```bash
php artisan tinker --execute="
use Illuminate\Support\Facades\Schema;
\$fields = ['pending_update', 'update_version', 'update_url', 'update_changes', 'current_version'];
echo 'Checking update columns:' . PHP_EOL;
foreach (\$fields as \$field) {
    \$exists = Schema::hasColumn('clients', \$field);
    echo '  ' . \$field . ': ' . (\$exists ? '✅' : '❌') . PHP_EOL;
}
"
```

---

## 📊 PART 5: Verify System Status (Di Termius)

### Step 1: Check registered clients
```bash
php artisan tinker --execute="
\$total = \App\Models\Client::count();
\$active = \App\Models\Client::where('last_seen', '>', now()->subHours(24))->count();

echo 'Total Clients: ' . \$total . PHP_EOL;
echo 'Active (24h):  ' . \$active . PHP_EOL;
"
```

### Step 2: Check package info
```bash
cd /var/www/html/tenjo/public/downloads/client/

echo "Package Information:"
echo "===================="
echo "Version: $(cat version.json | jq -r '.version')"
echo "Size: $(ls -lh tenjo_client_1.0.1.tar.gz | awk '{print $5}')"
echo "Checksum: $(cat version.json | jq -r '.checksum')"
echo "Priority: $(cat version.json | jq -r '.priority')"
echo ""
echo "Changes:"
cat version.json | jq -r '.changes[]'
```

---

## 🚀 PART 6: Trigger Update to Clients

### Option A: Test dengan 1 Client (Recommended)

**Di Termius:**

```bash
cd /var/www/Tenjo/dashboard

# Get first client ID
php artisan tinker --execute="
\$client = \App\Models\Client::first();
if (\$client) {
    echo 'Testing with client:' . PHP_EOL;
    echo 'ID: ' . \$client->id . PHP_EOL;
    echo 'Hostname: ' . \$client->hostname . PHP_EOL;
    echo 'Current version: ' . (\$client->current_version ?? 'unknown') . PHP_EOL;
    echo 'Last seen: ' . \$client->last_seen . PHP_EOL;
} else {
    echo 'No clients found!' . PHP_EOL;
}
"
```

**Trigger update for 1 client:**

```bash
php artisan tinker --execute="
\$client = \App\Models\Client::first();

if (\$client) {
    \$client->pending_update = true;
    \$client->update_version = '1.0.1';
    \$client->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz';
    \$client->update_changes = json_encode([
        'fix: Fixed 4 critical subprocess stealth bugs',
        'fix: CREATE_NO_WINDOW compatibility',
        'fix: Service installation stealth',
        'fix: Startup timeout protection'
    ]);
    \$client->update_triggered_at = now();
    \$client->save();

    echo '✅ Update triggered for: ' . \$client->hostname . PHP_EOL;
    echo 'Version: ' . \$client->update_version . PHP_EOL;
    echo 'URL: ' . \$client->update_url . PHP_EOL;
} else {
    echo '❌ No clients found!' . PHP_EOL;
}
"
```

**Monitor update progress:**

```bash
# Watch client status (update setiap 5 detik)
watch -n 5 'php artisan tinker --execute="
\$c = \App\Models\Client::first();
echo \"Client: \" . \$c->hostname . PHP_EOL;
echo \"Pending: \" . (\$c->pending_update ? \"YES\" : \"NO\") . PHP_EOL;
echo \"Current Version: \" . (\$c->current_version ?? \"old\") . PHP_EOL;
echo \"Update Version: \" . (\$c->update_version ?? \"N/A\") . PHP_EOL;
echo \"Triggered: \" . (\$c->update_triggered_at ?? \"N/A\") . PHP_EOL;
echo \"Completed: \" . (\$c->update_completed_at ?? \"N/A\") . PHP_EOL;
echo \"Last Seen: \" . \$c->last_seen . PHP_EOL;
"'

# Press Ctrl+C to stop watching
```

---

### Option B: Trigger ALL Clients (Use with caution!)

```bash
php artisan tinker --execute="
\$clients = \App\Models\Client::all();
\$count = 0;

foreach (\$clients as \$client) {
    \$client->pending_update = true;
    \$client->update_version = '1.0.1';
    \$client->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz';
    \$client->update_changes = json_encode([
        'fix: Fixed 11 critical bugs',
        'fix: Full stealth mode on Windows',
        'fix: Python 3.6+ compatibility'
    ]);
    \$client->update_triggered_at = now();
    \$client->save();
    \$count++;
}

echo '✅ Update triggered for ' . \$count . ' clients' . PHP_EOL;
"
```

---

## 📈 PART 7: Monitor Deployment

### Real-time monitoring
```bash
# Monitor update stats
watch -n 10 'php artisan tinker --execute="
\$total = \App\Models\Client::count();
\$pending = \App\Models\Client::where(\"pending_update\", true)->count();
\$completed = \App\Models\Client::where(\"current_version\", \"1.0.1\")->count();

echo \"═══════════════════════════════\" . PHP_EOL;
echo \"  UPDATE DEPLOYMENT STATUS      \" . PHP_EOL;
echo \"═══════════════════════════════\" . PHP_EOL;
echo \"Total Clients:    \" . \$total . PHP_EOL;
echo \"Pending Update:   \" . \$pending . PHP_EOL;
echo \"Updated to 1.0.1: \" . \$completed . PHP_EOL;
echo \"Progress:         \" . round((\$completed / \$total) * 100, 1) . \"%\" . PHP_EOL;
echo \"═══════════════════════════════\" . PHP_EOL;
"'
```

### Check logs
```bash
# Server logs
tail -f /var/www/Tenjo/dashboard/storage/logs/laravel.log

# Nginx logs
tail -f /var/log/nginx/access.log | grep "tenjo_client"
```

---

## ✅ SUCCESS INDICATORS

**Update berhasil jika:**
1. ✅ Client `pending_update` berubah dari `true` ke `false`
2. ✅ Client `current_version` berubah ke `1.0.1`
3. ✅ Client `update_completed_at` terisi dengan timestamp
4. ✅ Client masih `last_seen` update (heartbeat masih jalan)

**Contoh success status:**
```
Client: DESKTOP-ABC123
Pending: NO
Current Version: 1.0.1
Update Version: 1.0.1
Triggered: 2025-11-24 10:00:00
Completed: 2025-11-24 10:05:23
Last Seen: 2025-11-24 10:06:15 (just now)
```

---

## 🚨 ROLLBACK (Jika ada masalah)

### Rollback to previous version
```bash
# Update version.json to point to old version
cd /var/www/html/tenjo/public/downloads/client/

# Backup current version.json
cp version.json version_1.0.1.json

# Restore old version
cp version_1.0.0.json version.json  # If you have it

# OR manually edit
nano version.json
# Change version back to previous stable version
```

### Clear pending updates
```bash
php artisan tinker --execute="
\App\Models\Client::where('pending_update', true)->update([
    'pending_update' => false,
    'update_version' => null,
    'update_url' => null,
    'update_triggered_at' => null
]);
echo '✅ All pending updates cleared' . PHP_EOL;
"
```

---

## 📞 Quick Commands Reference

**Check package:**
```bash
curl -I https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz
```

**Check version.json:**
```bash
curl https://tenjo.adilabs.id/downloads/client/version.json | jq '.'
```

**Client count:**
```bash
php artisan tinker --execute="echo \App\Models\Client::count() . ' clients' . PHP_EOL;"
```

**Trigger one client:**
```bash
php artisan tinker --execute="\$c = \App\Models\Client::first(); \$c->pending_update = true; \$c->update_version = '1.0.1'; \$c->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.1.tar.gz'; \$c->update_triggered_at = now(); \$c->save(); echo 'Triggered' . PHP_EOL;"
```

**Clear all updates:**
```bash
php artisan tinker --execute="\App\Models\Client::query()->update(['pending_update' => false]); echo 'Cleared' . PHP_EOL;"
```

---

**Last Updated:** 2025-11-24
**Package Version:** 1.0.1
**Bug Fixes:** 11 critical bugs (BUG #44-58)
**Status:** READY FOR PRODUCTION DEPLOYMENT
