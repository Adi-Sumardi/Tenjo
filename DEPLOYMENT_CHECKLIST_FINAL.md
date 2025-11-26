# ✅ DEPLOYMENT CHECKLIST - Tenjo System v1.0.3

**Version:** 1.0.3  
**Date:** 2025-11-26  
**Status:** Ready for Production Deployment

---

## 📋 PRE-DEPLOYMENT CHECKS

### 1. Code Quality & Testing

**Client (Python):**
- [x] All syntax errors fixed
- [x] BUG #63 fixed (no pop-ups on startup)
- [x] BUG #64 fixed (browser tracking working)
- [x] BUG #65 verified (KPI categories working)
- [x] ISSUE #67 fixed (improved retry logic)
- [x] ISSUE #68 fixed (disk space check)
- [x] All files synced to usb_deployment
- [ ] Tested on Windows machine (user testing required)
- [ ] pywin32 installs correctly
- [ ] Browser tracking working on Chrome/Firefox/Edge
- [ ] Screenshots captured and uploaded
- [ ] No terminal windows appear on startup

**Dashboard (Laravel):**
- [x] All controllers validated
- [x] Database migrations ready
- [x] Category service working
- [x] API endpoints tested
- [ ] Migration verification (see below)
- [ ] Storage directory writable
- [ ] Scheduled tasks configured

---

## 🗄️ DATABASE DEPLOYMENT

### Migration Verification - CRITICAL! ⚠️

**File:** `2025_11_12_065208_add_activity_category_to_url_activities_table.php`

```bash
# Step 1: Check current migration status
php artisan migrate:status

# Step 2: Run pending migrations
php artisan migrate --force

# Step 3: Verify activity_category column exists
php artisan tinker
>> Schema::hasColumn('url_activities', 'activity_category')
=> true  # Should return true

# OR using SQL directly
mysql -u [user] -p [database]
mysql> DESCRIBE url_activities;
# Should show activity_category column

# Step 4: Test category assignment
>> $activity = \App\Models\UrlActivity::first();
>> $activity->activity_category;
=> "work"  # Should return value
```

**Rollback Plan (if needed):**
```bash
# Rollback last migration
php artisan migrate:rollback --step=1

# Or rollback specific migration
php artisan migrate:rollback --path=database/migrations/2025_11_12_065208_add_activity_category_to_url_activities_table.php
```

---

## 🚀 CLIENT DEPLOYMENT

### USB Installer Preparation

```bash
# 1. Navigate to USB deployment folder
cd /app/client/usb_deployment

# 2. Verify all files present
ls -la
# Should show:
# - INSTALL.bat
# - UNINSTALL.bat
# - README.md
# - client/ folder

# 3. Verify client folder structure
ls -la client/
# Should show:
# - main.py
# - requirements.txt
# - watchdog.py
# - src/ folder

# 4. Verify critical fixes present
grep -n "FIX BUG #63\|FIX BUG #64\|FIX ISSUE #67\|FIX ISSUE #68" INSTALL.bat
grep -n "FIX BUG #64" client/src/modules/browser_tracker.py
grep -n "FIX ISSUE #67" client/src/utils/api_client.py
grep -n "FIX ISSUE #68" client/src/modules/screen_capture.py

# 5. Copy to USB drives
# Windows:
xcopy /E /I /Y usb_deployment\ E:\Tenjo-Installer\

# Linux/macOS:
cp -r usb_deployment/ /media/usb/Tenjo-Installer/
```

---

## 🖥️ DASHBOARD DEPLOYMENT

### Laravel Setup

```bash
# 1. Navigate to dashboard directory
cd /app/dashboard

# 2. Install/update dependencies
composer install --optimize-autoloader --no-dev

# 3. Configure environment
cp .env.example .env
php artisan key:generate

# 4. Run migrations
php artisan migrate --force

# 5. Verify migrations
php artisan migrate:status
# All should show [Y]

# 6. Setup storage
php artisan storage:link
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# 7. Clear caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# 8. Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Setup Scheduled Tasks (Screenshot Cleanup)

```bash
# Add to crontab
crontab -e

# Add this line:
* * * * * cd /path/to/dashboard && php artisan schedule:run >> /dev/null 2>&1

# Or for Laravel Forge:
# Schedule will auto-run

# Verify scheduler
php artisan schedule:list
```

**Create Cleanup Command:**

```bash
# Create command
php artisan make:command CleanupOldScreenshots

# Edit: app/Console/Commands/CleanupOldScreenshots.php
```

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Screenshot;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class CleanupOldScreenshots extends Command
{
    protected $signature = 'screenshots:cleanup {--days=30}';
    protected $description = 'Delete screenshots older than specified days';

    public function handle()
    {
        $days = $this->option('days');
        $cutoffDate = Carbon::now()->subDays($days);
        
        $this->info("Cleaning up screenshots older than {$days} days...");
        
        $oldScreenshots = Screenshot::where('captured_at', '<', $cutoffDate)->get();
        $count = $oldScreenshots->count();
        
        foreach ($oldScreenshots as $screenshot) {
            // Delete file
            if ($screenshot->file_path && Storage::disk('public')->exists($screenshot->file_path)) {
                Storage::disk('public')->delete($screenshot->file_path);
            }
            // Delete record
            $screenshot->delete();
        }
        
        Log::info("Cleaned up {$count} old screenshots");
        $this->info("✓ Deleted {$count} screenshots");
        
        return 0;
    }
}
```

**Schedule in Kernel.php:**

```php
// app/Console/Kernel.php
protected function schedule(Schedule $schedule)
{
    // Run daily at 2 AM
    $schedule->command('screenshots:cleanup --days=30')
             ->daily()
             ->at('02:00');
}
```

---

## 🧪 INSTALLATION TESTING

### Test on Clean Windows Machine

```
1. [ ] Fresh Windows 7/8/10/11 installation
2. [ ] Python 3.7+ installed
3. [ ] Internet connection available
4. [ ] Administrator privileges available

Installation Steps:
5. [ ] Insert USB drive
6. [ ] Right-click INSTALL.bat
7. [ ] Select "Run as administrator"
8. [ ] Watch for success messages:
     [ ] ✓ pythonw.exe copied as OfficeSync.exe
     [ ] ✓ All files copied
     [ ] ✓ Dependencies installed
     [ ] ✓ pywin32 installed (browser tracking support)
     [ ] ✓ Windows Defender exclusions added
     [ ] ✓ Windows Service registered
     [ ] ✓ Service started successfully

9. [ ] Restart computer
10. [ ] Verify NO pop-ups appear during startup
11. [ ] Open Task Manager
12. [ ] Verify "OfficeSync.exe" or "pythonw.exe" running (NOT "python.exe")
```

### Verify Browser Tracking

```
1. [ ] Open Chrome browser
2. [ ] Navigate to:
     [ ] YouTube - watch video 2 minutes
     [ ] Google.com - search something
     [ ] GitHub.com - browse code
3. [ ] Open Firefox browser
4. [ ] Navigate to:
     [ ] Facebook.com
     [ ] Twitter.com
5. [ ] Wait 3-5 minutes for data to sync
6. [ ] Open dashboard: https://tenjo.adilabs.id
7. [ ] Login to dashboard
8. [ ] Go to Clients page
9. [ ] Find test machine (should appear within 2-5 minutes)
10. [ ] Click on client name
11. [ ] Verify:
     [ ] Browser sessions show Chrome and Firefox
     [ ] URL activities show visited sites
     [ ] YouTube visit shows as "Social Media" category
     [ ] Google/GitHub show as "Pekerjaan" category
12. [ ] Check client logs:
     cd C:\ProgramData\Microsoft\Office365Sync_XXXX\logs
     type stealth.log | findstr "Found"
     # Should show: "Found X browser windows"
```

### Verify KPI Categories

```
1. [ ] Browse different types of sites:
     [ ] Work: Gmail, Google Docs, Slack
     [ ] Social: YouTube, Facebook, WhatsApp Web
     [ ] Streaming: Netflix, Disney+
     [ ] News: CNN, BBC
2. [ ] Wait 5 minutes for sync
3. [ ] Open dashboard
4. [ ] Go to Client Details
5. [ ] Check KPI Summary or Export
6. [ ] Verify categories:
     [ ] YouTube = "Media Sosial" (red/orange)
     [ ] WhatsApp = "Media Sosial"
     [ ] Gmail = "Pekerjaan" (green)
     [ ] Google Docs = "Pekerjaan"
7. [ ] Check database directly:
     SELECT activity_category, COUNT(*) as count
     FROM url_activities
     WHERE client_id = 'test-client-id'
     GROUP BY activity_category;
     # Should show distribution: work, social_media
```

---

## 🔍 POST-DEPLOYMENT MONITORING

### First 24 Hours

```bash
# Check client connections
php artisan tinker
>> \App\Models\Client::where('last_seen', '>=', now()->subHours(1))->count()
# Should increase as clients come online

# Check screenshot uploads
>> \App\Models\Screenshot::where('created_at', '>=', now()->subHours(1))->count()
# Should increase over time

# Check browser tracking
>> \App\Models\UrlActivity::where('created_at', '>=', now()->subHours(1))->count()
# Should increase as users browse

# Check category distribution
>> \App\Models\UrlActivity::select('activity_category', DB::raw('count(*) as count'))->groupBy('activity_category')->get()
# Should show: work, social_media, suspicious
```

### Monitor Logs

```bash
# Dashboard logs
tail -f /path/to/dashboard/storage/logs/laravel.log

# Look for errors:
grep "ERROR\|CRITICAL\|EMERGENCY" storage/logs/laravel.log

# Check for common issues:
grep "migration\|activity_category\|UrlActivity" storage/logs/laravel.log
```

### Client Health Check

**For each client:**
```cmd
# Find installation folder
dir /s /a:h "C:\ProgramData\Microsoft\Office365Sync_*"

# Check logs
cd C:\ProgramData\Microsoft\Office365Sync_XXXX\logs
type stealth.log | findstr "ERROR\|CRITICAL\|pywin32\|browser"

# Verify pywin32
cd C:\ProgramData\Microsoft\Office365Sync_XXXX
python -c "import win32gui; print('OK')"

# Check service
sc query Office365Sync
```

---

## ⚠️ TROUBLESHOOTING

### Issue: No Pop-ups But Service Not Starting

```cmd
# Check if OfficeSync.exe exists
dir %INSTALL_DIR%\OfficeSync.exe

# Check if it's pythonw.exe (should be ~100KB)
# If 3-4MB, it's python.exe (wrong!)

# Fix: Manual copy
where pythonw.exe
copy "[path to pythonw.exe]" "%INSTALL_DIR%\OfficeSync.exe"

# Restart service
sc stop Office365Sync
sc start Office365Sync
```

### Issue: Browser Tracking Not Working

```cmd
# 1. Check pywin32 installation
python -c "import win32gui; print('OK')"
# If error: pip install pywin32
# Then: python -m pywin32_postinstall -install

# 2. Check logs for ImportError
type logs\stealth.log | findstr "ImportError\|pywin32"

# 3. Manually test browser detection
python -c "import psutil; [print(p.info['name']) for p in psutil.process_iter(['name']) if 'chrome' in p.info['name'].lower()]"

# 4. Restart client
sc stop Office365Sync
sc start Office365Sync
```

### Issue: KPI Categories All Show "Pekerjaan"

```bash
# 1. Verify migration ran
php artisan migrate:status
# Should show activity_category migration as [Y]

# 2. Check database schema
php artisan tinker
>> Schema::hasColumn('url_activities', 'activity_category')
=> true

# 3. Check if categories are being saved
>> \App\Models\UrlActivity::whereNotNull('activity_category')->count()
# Should be > 0

# 4. Test categorization manually
>> $categorizer = new \App\Services\ActivityCategorizerService();
>> $categorizer->categorize('https://youtube.com', 'youtube.com', 'YouTube');
=> "social_media"  # Should return social_media

# 5. If still not working, check if BUG #64 (browser tracking) is actually fixed
# No browser data = No categories
```

---

## 📊 SUCCESS METRICS

### Day 1 (First 24 hours):
- [ ] 80%+ of target machines installed successfully
- [ ] All installed clients show up in dashboard
- [ ] No user complaints about pop-ups
- [ ] Browser tracking data appearing for 70%+ clients

### Week 1:
- [ ] 95%+ installation success rate
- [ ] All clients tracking browsers correctly
- [ ] KPI categories showing correct distribution
- [ ] No performance issues
- [ ] Storage usage within limits

### Month 1:
- [ ] 100% stable operations
- [ ] Automated cleanup working
- [ ] No manual interventions needed
- [ ] User feedback: "Don't even notice it's running"

---

## 🎯 ROLLBACK CRITERIA

Stop deployment and rollback if:

1. **> 20% installation failures**
   - Action: Investigate and fix installer
   
2. **Users see pop-ups consistently**
   - Action: Fix BUG #63 implementation
   
3. **< 50% clients showing browser data**
   - Action: Fix BUG #64 implementation
   
4. **Database errors in dashboard logs**
   - Action: Check migrations, fix schema
   
5. **Disk space issues on clients**
   - Action: Verify ISSUE #68 fix working
   
6. **Performance degradation**
   - Action: Check resource usage, optimize

---

## ✅ FINAL VERIFICATION

Before marking deployment as complete:

### Client Side:
- [x] BUG #63 fixed (no pop-ups)
- [x] BUG #64 fixed (browser tracking)
- [x] ISSUE #67 fixed (retry logic)
- [x] ISSUE #68 fixed (disk space check)
- [x] All files synced to USB
- [ ] Tested on real Windows machine
- [ ] No visible windows during startup
- [ ] Browser tracking working
- [ ] KPI categories correct

### Dashboard Side:
- [x] Code quality verified
- [x] Migrations ready
- [x] Category service working
- [ ] Migrations run in production
- [ ] activity_category column exists
- [ ] Scheduled cleanup configured
- [ ] Storage permissions set
- [ ] Performance acceptable

### Integration:
- [ ] Client connects to dashboard
- [ ] Screenshots upload successfully
- [ ] Browser tracking data syncs
- [ ] KPI categories assigned correctly
- [ ] No error spikes in logs

---

## 📝 DEPLOYMENT SIGN-OFF

**Prepared By:** E1 AI Agent  
**Date:** 2025-11-26  
**Version:** 1.0.3

**Deployment Approval:**

- [ ] Technical Lead: ____________________ Date: ________
- [ ] Product Owner: ____________________ Date: ________
- [ ] Security Review: ____________________ Date: ________

**Post-Deployment Verification:**

- [ ] Installation tested successfully
- [ ] All features working as expected
- [ ] No critical issues found
- [ ] Monitoring in place

**Notes:**
_____________________________________________________________________
_____________________________________________________________________
_____________________________________________________________________

