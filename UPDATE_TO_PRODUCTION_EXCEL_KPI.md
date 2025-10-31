# 🚀 Update Production: Enhanced Excel KPI Export

Panduan lengkap untuk deploy update **Enhanced Excel KPI Export** ke production VPS via Termius.

---

## 📋 Update Summary

**Version**: Enhanced Excel KPI Export v1.0
**Commit**: `90bb859` - feat: Add Enhanced Excel KPI Export with multi-sheet workbook

### Files Changed (Dashboard Laravel):
```
✅ NEW: dashboard/app/Exports/EnhancedClientSummaryExport.php
✅ NEW: dashboard/app/Exports/Sheets/SummarySheet.php
✅ NEW: dashboard/app/Exports/Sheets/KPIDashboardSheet.php
✅ NEW: dashboard/app/Exports/Sheets/IndividualEmployeeSheet.php
✅ NEW: dashboard/app/Exports/Sheets/AnalyticsSheet.php
✅ MOD: dashboard/app/Http/Controllers/DashboardController.php
✅ NEW: EXCEL_KPI_EXPORT_GUIDE.md (dokumentasi)
```

### Files Changed (Client Python):
```
⚠️  MOD: client/main.py (thread-safe shutdown)
⚠️  MOD: client/src/modules/browser_tracker.py (thread safety)
⚠️  MOD: client/src/utils/api_client.py (bug fix)
```

**Note**: Client updates **OPTIONAL** untuk update ini karena hanya bug fixes minor.

---

## 🎯 Method 1: Update via Termius (Recommended)

### Prerequisites
1. **Termius** installed di laptop/PC lo
2. VPS credentials:
   - Host: `103.129.149.67` atau `tenjo.adilabs.id`
   - User: `tenjo-app` (atau `root`)
   - Password/SSH Key tersimpan di Termius

### Step-by-Step:

#### **STEP 1: Buka Termius & Connect ke VPS**

```bash
# Di Termius, connect ke VPS:
# Host: 103.129.149.67 (atau tenjo.adilabs.id)
# User: tenjo-app
```

#### **STEP 2: Backup Database (CRITICAL!)**

```bash
cd /var/www/Tenjo

# Create backup
mkdir -p backups
PGPASSWORD="tenjo_secure_2025" pg_dump -h 127.0.0.1 -U tenjo_user tenjo_production > backups/backup_excel_kpi_$(date +%Y%m%d_%H%M%S).sql

# Verify backup created
ls -lh backups/backup_excel_kpi_*.sql | tail -1
```

**Output yang diharapkan**:
```
-rw-r--r-- 1 tenjo-app tenjo-app 2.1M Oct 31 12:50 backups/backup_excel_kpi_20251031_125000.sql
```

✅ **STOP HERE IF BACKUP FAILED!**

---

#### **STEP 3: Pull Latest Code dari GitHub**

```bash
cd /var/www/Tenjo/dashboard

# Check current branch
git branch --show-current
# Output: master

# Pull latest changes
git pull origin master
```

**Output yang diharapkan**:
```
remote: Counting objects: 10, done.
remote: Compressing objects: 100% (10/10), done.
remote: Total 10 (delta 3), reused 10 (delta 3)
Unpacking objects: 100% (10/10), done.
From https://github.com/Adi-Sumardi/Tenjo
   e9a3158..90bb859  master     -> origin/master
Updating e9a3158..90bb859
Fast-forward
 EXCEL_KPI_EXPORT_GUIDE.md                          | 527 +++++++++++++++++++++
 dashboard/app/Exports/EnhancedClientSummaryExport.php    |  53 +++
 dashboard/app/Exports/Sheets/AnalyticsSheet.php    | 257 ++++++++++
 dashboard/app/Exports/Sheets/IndividualEmployeeSheet.php | 259 ++++++++++
 dashboard/app/Exports/Sheets/KPIDashboardSheet.php | 272 +++++++++++
 dashboard/app/Exports/Sheets/SummarySheet.php      | 227 +++++++++
 dashboard/app/Http/Controllers/DashboardController.php   |  13 +
 10 files changed, 1647 insertions(+), 39 deletions(-)
```

✅ **Jika error "Your local changes would be overwritten"**:
```bash
# Stash local changes
git stash

# Pull again
git pull origin master

# Apply stash (jika perlu)
git stash pop
```

---

#### **STEP 4: Verify New Files Exists**

```bash
cd /var/www/Tenjo/dashboard

# Check new files
ls -lh app/Exports/EnhancedClientSummaryExport.php
ls -lh app/Exports/Sheets/

# Check DashboardController updated
grep -n "EnhancedClientSummaryExport" app/Http/Controllers/DashboardController.php
```

**Output yang diharapkan**:
```
-rw-r--r-- 1 tenjo-app tenjo-app 1.5K app/Exports/EnhancedClientSummaryExport.php

app/Exports/Sheets/:
total 88K
-rw-r--r-- 1 tenjo-app tenjo-app 8.8K AnalyticsSheet.php
-rw-r--r-- 1 tenjo-app tenjo-app 9.2K IndividualEmployeeSheet.php
-rw-r--r-- 1 tenjo-app tenjo-app 9.3K KPIDashboardSheet.php
-rw-r--r-- 1 tenjo-app tenjo-app 7.5K SummarySheet.php

app/Http/Controllers/DashboardController.php:
12:use App\Exports\EnhancedClientSummaryExport;
```

✅ **Semua file ada? Lanjut!**

---

#### **STEP 5: Clear Laravel Cache**

```bash
cd /var/www/Tenjo/dashboard

# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Rebuild cache
php artisan config:cache
php artisan route:cache
```

**Output yang diharapkan**:
```
Application cache cleared!
Configuration cache cleared!
Route cache cleared!
Compiled views cleared!
Configuration cached successfully!
Routes cached successfully!
```

---

#### **STEP 6: Run Composer (if needed)**

```bash
cd /var/www/Tenjo/dashboard

# Check if composer update needed
composer validate

# If valid, no need to update
# If issues, run:
composer install --no-dev --optimize-autoloader
```

**Note**: Update ini **TIDAK** butuh composer update karena tidak ada dependency baru.

---

#### **STEP 7: Test Export Feature**

```bash
cd /var/www/Tenjo/dashboard

# Test via Tinker
php artisan tinker

# Di dalam Tinker, ketik:
```

```php
use App\Exports\EnhancedClientSummaryExport;
use Maatwebsite\Excel\Facades\Excel;

// Get sample data
$clients = App\Models\Client::with(['screenshots', 'browserSessions', 'urlActivities'])
    ->limit(2)
    ->get()
    ->map(function($client) {
        return [
            'client' => $client,
            'stats' => [
                'status' => 'online',
                'screenshots' => $client->screenshots()->count(),
                'browser_sessions' => $client->browserSessions()->count(),
                'url_activities' => $client->urlActivities()->count(),
                'unique_urls' => $client->urlActivities()->distinct('url')->count(),
                'total_duration_minutes' => 240,
                'top_domains' => 'google.com, youtube.com',
                'last_activity' => now()->format('Y-m-d H:i:s')
            ]
        ];
    });

$overallStats = [
    'total_clients' => 10,
    'active_clients' => 8
];

$period = [
    'from' => now()->subDays(7)->format('Y-m-d'),
    'to' => now()->format('Y-m-d')
];

// Test export
$export = new EnhancedClientSummaryExport($clients, $overallStats, $period);
echo "✅ Export class loaded successfully!\n";

// Check sheets
$sheets = $export->sheets();
echo "Total sheets: " . count($sheets) . "\n";

exit
```

**Output yang diharapkan**:
```
✅ Export class loaded successfully!
Total sheets: 6
```

✅ **Test sukses? Lanjut!**

---

#### **STEP 8: Test Download via Browser**

1. Buka browser
2. Login ke dashboard: `https://tenjo.adilabs.id/login`
3. Go to **Client Summary** page
4. Pilih date filter (e.g., "Last 7 Days")
5. Klik **Export Excel** button
6. File `Employee_KPI_Report_2025-10-31.xlsx` akan ter-download
7. Buka file Excel, verify ada **6 sheets**:
   - ✅ Summary
   - ✅ KPI Dashboard
   - ✅ [Employee Name] (per karyawan)
   - ✅ Analytics

---

#### **STEP 9: Restart PHP-FPM (Optional)**

```bash
# Restart PHP-FPM untuk refresh
sudo systemctl restart php8.2-fpm

# Verify running
sudo systemctl status php8.2-fpm
```

---

#### **STEP 10: Verify Production Status**

```bash
cd /var/www/Tenjo/dashboard

# Check system status
php artisan tinker --execute="
\$clients = \App\Models\Client::count();
\$active = \App\Models\Client::where('last_seen', '>', now()->subHours(24))->count();

echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo '      PRODUCTION STATUS            ' . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo 'Total Clients:    ' . \$clients . PHP_EOL;
echo 'Active (24h):     ' . \$active . PHP_EOL;
echo 'Excel Export:     ✅ READY' . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
"
```

---

## 🎯 Method 2: Update via Quick Script (Alternative)

Jika lo mau cepat, bisa pake script otomatis:

### **Buat Script di VPS**

```bash
# Di Termius, connect ke VPS dan buat script:
nano /var/www/Tenjo/update_excel_kpi.sh
```

**Paste script ini**:

```bash
#!/bin/bash
# Quick Update Script - Excel KPI Export

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Updating Excel KPI Export Feature...${NC}\n"

# Step 1: Backup
echo -e "${YELLOW}[1/6] Creating backup...${NC}"
cd /var/www/Tenjo
mkdir -p backups
PGPASSWORD="tenjo_secure_2025" pg_dump -h 127.0.0.1 -U tenjo_user tenjo_production > backups/backup_excel_kpi_$(date +%Y%m%d_%H%M%S).sql
echo -e "${GREEN}✓ Backup created${NC}\n"

# Step 2: Pull code
echo -e "${YELLOW}[2/6] Pulling latest code...${NC}"
cd /var/www/Tenjo/dashboard
git pull origin master
echo -e "${GREEN}✓ Code updated${NC}\n"

# Step 3: Verify files
echo -e "${YELLOW}[3/6] Verifying new files...${NC}"
if [ -f "app/Exports/EnhancedClientSummaryExport.php" ]; then
    echo -e "${GREEN}✓ EnhancedClientSummaryExport.php${NC}"
else
    echo -e "${RED}✗ EnhancedClientSummaryExport.php NOT FOUND!${NC}"
    exit 1
fi

if [ -d "app/Exports/Sheets" ]; then
    echo -e "${GREEN}✓ Sheets directory ($(ls app/Exports/Sheets/*.php | wc -l) files)${NC}"
else
    echo -e "${RED}✗ Sheets directory NOT FOUND!${NC}"
    exit 1
fi

# Step 4: Clear cache
echo -e "\n${YELLOW}[4/6] Clearing Laravel cache...${NC}"
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan config:cache
php artisan route:cache
echo -e "${GREEN}✓ Cache cleared${NC}\n"

# Step 5: Test export class
echo -e "${YELLOW}[5/6] Testing export class...${NC}"
php artisan tinker --execute="
use App\Exports\EnhancedClientSummaryExport;
echo '✅ Export class loaded successfully!' . PHP_EOL;
"

# Step 6: Restart PHP-FPM
echo -e "\n${YELLOW}[6/6] Restarting PHP-FPM...${NC}"
sudo systemctl restart php8.2-fpm
echo -e "${GREEN}✓ PHP-FPM restarted${NC}\n"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Update completed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Test the feature:${NC}"
echo "1. Login to dashboard: https://tenjo.adilabs.id/login"
echo "2. Go to Client Summary page"
echo "3. Click 'Export Excel' button"
echo "4. Verify multi-sheet Excel file downloads"
```

**Simpan dan jalankan**:

```bash
# Save: Ctrl+X, Y, Enter

# Make executable
chmod +x /var/www/Tenjo/update_excel_kpi.sh

# Run
./update_excel_kpi.sh
```

---

## 🔥 Quick Commands Reference

### Check Git Status
```bash
cd /var/www/Tenjo/dashboard
git status
git log --oneline -5
```

### Check Files
```bash
cd /var/www/Tenjo/dashboard
find app/Exports -name "*.php" -type f
```

### Check Laravel Logs (If Error)
```bash
tail -f /var/www/Tenjo/dashboard/storage/logs/laravel.log
```

### Clear Cache Manual
```bash
cd /var/www/Tenjo/dashboard
rm -rf bootstrap/cache/*.php
rm -rf storage/framework/cache/data/*
rm -rf storage/framework/views/*
php artisan cache:clear
```

### Restart Services
```bash
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
```

---

## ⚠️ Troubleshooting

### Error: "Class EnhancedClientSummaryExport not found"

**Solution**:
```bash
cd /var/www/Tenjo/dashboard

# Rebuild autoload
composer dump-autoload

# Clear cache
php artisan cache:clear
php artisan config:clear

# Test again
php artisan tinker --execute="use App\Exports\EnhancedClientSummaryExport; echo 'OK';"
```

---

### Error: "Column not found" in Excel export

**Solution**: Check namespace imports
```bash
cd /var/www/Tenjo/dashboard

# Check DashboardController imports
grep -A 5 "^use " app/Http/Controllers/DashboardController.php | grep Export
```

Should show:
```
use App\Exports\ClientSummaryExport;
use App\Exports\EnhancedClientSummaryExport;
```

---

### Error: Excel download fails (500 error)

**Solution**: Check Laravel logs
```bash
tail -50 /var/www/Tenjo/dashboard/storage/logs/laravel.log
```

Common issues:
1. **Memory limit**: Increase `memory_limit` di `php.ini`
2. **Timeout**: Increase `max_execution_time`
3. **Permissions**: Check storage folder writable

```bash
# Fix permissions
sudo chown -R www-data:www-data /var/www/Tenjo/dashboard/storage
sudo chmod -R 775 /var/www/Tenjo/dashboard/storage
```

---

## 📊 Testing Checklist

After deployment, verify:

- [ ] Git pull successful (commit hash: `90bb859`)
- [ ] New files exist in `app/Exports/`
- [ ] Laravel cache cleared
- [ ] Export class loadable in Tinker
- [ ] Dashboard login works
- [ ] Client Summary page loads
- [ ] Export Excel button visible
- [ ] Excel file downloads successfully
- [ ] Excel has 6 sheets (Summary, KPI, Individual, Analytics)
- [ ] Data populated correctly in all sheets
- [ ] KPI scores calculated
- [ ] Date filtering works

---

## 🎉 Done!

Setelah semua step selesai:

1. ✅ **Dashboard updated** dengan Enhanced Excel KPI Export
2. ✅ **Multi-sheet Excel** ready to use
3. ✅ **KPI Dashboard** with performance metrics
4. ✅ **Individual employee reports** tersedia
5. ✅ **Team analytics** dengan insights

**Features Available**:
- 📊 Summary Sheet - Overview semua karyawan
- 🏆 KPI Dashboard - Performance ranking
- 👤 Individual Sheets - Detail per karyawan
- 📈 Analytics Sheet - Team insights & recommendations
- 📅 Date Filtering - Today, Week, Month, Custom

---

## 📚 Documentation

Untuk guide lengkap fitur Excel KPI Export:
- [EXCEL_KPI_EXPORT_GUIDE.md](EXCEL_KPI_EXPORT_GUIDE.md)

Untuk deployment guide umum:
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- [vps_deploy_commands.sh](vps_deploy_commands.sh)

---

## 🆘 Need Help?

Jika ada error atau masalah:

1. Check Laravel logs: `tail -f storage/logs/laravel.log`
2. Check Nginx logs: `tail -f /var/log/nginx/error.log`
3. Check PHP-FPM logs: `tail -f /var/log/php8.2-fpm.log`
4. Contact: adisumardi888@gmail.com

---

**Last Updated**: October 31, 2025
**Version**: Excel KPI Export v1.0
**Commit**: `90bb859`
