# 🔧 VPS Quick Commands Reference

## Database Commands (CORRECT SYNTAX)

### ❌ WRONG (Peer authentication error):
```bash
pg_dump -U tenjo_user tenjo_production > backup.sql
```

### ✅ CORRECT (TCP connection with password):
```bash
# Backup database
PGPASSWORD="tenjo_secure_2025" pg_dump -h 127.0.0.1 -U tenjo_user tenjo_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Or using localhost
PGPASSWORD="tenjo_secure_2025" pg_dump -h localhost -U tenjo_user tenjo_production > backup.sql
```

### ✅ Connect to PostgreSQL:
```bash
PGPASSWORD="tenjo_secure_2025" psql -h 127.0.0.1 -U tenjo_user -d tenjo_production
```

### ✅ Check database size:
```bash
PGPASSWORD="tenjo_secure_2025" psql -h 127.0.0.1 -U tenjo_user -d tenjo_production -c "SELECT pg_size_pretty(pg_database_size('tenjo_production'));"
```

### ✅ Restore database:
```bash
PGPASSWORD="tenjo_secure_2025" psql -h 127.0.0.1 -U tenjo_user -d tenjo_production < backup.sql
```

---

## Quick Deployment Commands

### 1️⃣ SSH to VPS:
```bash
ssh tenjo-app@103.129.149.67
```

### 2️⃣ Run automated deployment:
```bash
cd /var/www/Tenjo
chmod +x vps_deploy_commands.sh
./vps_deploy_commands.sh
```

### 3️⃣ Or manual steps:

**Backup:**
```bash
cd /var/www/Tenjo
mkdir -p backups
PGPASSWORD="tenjo_secure_2025" pg_dump -h 127.0.0.1 -U tenjo_user tenjo_production > backups/backup_$(date +%Y%m%d_%H%M%S).sql
```

**Pull code:**
```bash
cd /var/www/Tenjo/dashboard
git pull origin master
```

**Run migration:**
```bash
php artisan migrate --force
```

**Cleanup duplicates:**
```bash
cd /var/www/Tenjo
php cleanup_duplicate_clients.php
```

**Verify:**
```bash
php artisan tinker --execute="
echo 'Total clients: ' . \App\Models\Client::count() . PHP_EOL;
echo 'Active (24h): ' . \App\Models\Client::where('last_seen', '>', now()->subHours(24))->count() . PHP_EOL;
"
```

---

## Silent Deployment Commands

### Test on 1 PC:
```bash
cd /var/www/Tenjo/dashboard

php artisan tinker
```

Then in tinker:
```php
$client = App\Models\Client::where('hostname', 'DESKTOP-TEST')->first();
$client->pending_update = true;
$client->update_version = '2025.10.02';
$client->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_2025.10.02.tar.gz';
$client->update_triggered_at = now();
$client->save();
echo "✅ Update triggered for " . $client->hostname . PHP_EOL;
exit
```

### Deploy to ALL clients:
```bash
cd /var/www/Tenjo
./silent_push_deploy.sh 2025.10.02
```

### Monitor progress:
```bash
watch -n 5 'cd /var/www/Tenjo/dashboard && php artisan tinker --execute="
\$pending = \App\Models\Client::where(\"pending_update\", true)->count();
\$updated = \App\Models\Client::where(\"current_version\", \"2025.10.02\")->count();
echo \"Pending: \" . \$pending . \" | Updated: \" . \$updated . \" / 20\" . PHP_EOL;
"'
```

### Check completion:
```bash
php artisan tinker --execute="
\$all = \App\Models\Client::count();
\$updated = \App\Models\Client::where('current_version', '2025.10.02')->count();
echo 'Updated: ' . \$updated . ' / ' . \$all . PHP_EOL;
"
```

---

## Monitoring Commands

### Check all clients:
```bash
php artisan tinker --execute="
\$clients = \App\Models\Client::orderBy('hostname')->get();
foreach (\$clients as \$c) {
    \$version = \$c->current_version ?? 'old';
    \$status = \$c->pending_update ? '⏳' : '✅';
    echo str_pad(\$c->hostname, 25) . ' | ' . str_pad(\$version, 12) . ' | ' . \$status . PHP_EOL;
}
"
```

### Check for duplicates:
```bash
php artisan tinker --execute="
\$duplicates = \App\Models\Client::select('hostname', \DB::raw('COUNT(*) as count'))
    ->groupBy('hostname')
    ->havingRaw('COUNT(*) > 1')
    ->get();
    
echo 'Duplicate hostnames: ' . \$duplicates->count() . PHP_EOL;
foreach (\$duplicates as \$dup) {
    echo '  - ' . \$dup->hostname . ' (' . \$dup->count . ' registrations)' . PHP_EOL;
}
"
```

### Database statistics:
```bash
php artisan tinker --execute="
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo 'Clients:      ' . \App\Models\Client::count() . PHP_EOL;
echo 'Screenshots:  ' . number_format(\App\Models\Screenshot::count()) . PHP_EOL;
echo 'URL Events:   ' . number_format(\App\Models\UrlEvent::count()) . PHP_EOL;
echo 'Browser Evts: ' . number_format(\App\Models\BrowserEvent::count()) . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
"
```

### Database size:
```bash
PGPASSWORD="tenjo_secure_2025" psql -h 127.0.0.1 -U tenjo_user -d tenjo_production -c "
SELECT 
    pg_size_pretty(pg_database_size('tenjo_production')) AS db_size,
    pg_size_pretty(pg_total_relation_size('clients')) AS clients_size,
    pg_size_pretty(pg_total_relation_size('screenshots')) AS screenshots_size,
    pg_size_pretty(pg_total_relation_size('url_events')) AS url_events_size;
"
```

---

## Troubleshooting

### If migration fails:
```bash
# Check migration status
php artisan migrate:status

# Rollback last migration
php artisan migrate:rollback --step=1

# Run again
php artisan migrate --force
```

### If cleanup fails:
```bash
# Check error logs
tail -50 /var/www/Tenjo/dashboard/storage/logs/laravel.log

# Manual cleanup (careful!)
php artisan tinker
```

### If client not updating:
```bash
# Check if flag is set
php artisan tinker --execute="
\$client = \App\Models\Client::where('hostname', 'DESKTOP-TEST')->first();
echo 'Pending update: ' . (\$client->pending_update ? 'YES' : 'NO') . PHP_EOL;
echo 'Update version: ' . (\$client->update_version ?? 'none') . PHP_EOL;
echo 'Last seen: ' . \$client->last_seen->diffForHumans() . PHP_EOL;
"

# Force re-trigger
php artisan tinker
>>> $client = App\Models\Client::where('hostname', 'DESKTOP-TEST')->first();
>>> $client->pending_update = true;
>>> $client->update_triggered_at = now();
>>> $client->save();
```

### Cancel all pending updates:
```bash
php artisan tinker --execute="
\$count = \App\Models\Client::where('pending_update', true)
    ->update(['pending_update' => false]);
echo 'Cancelled updates for ' . \$count . ' clients' . PHP_EOL;
"
```

---

## Log Files

### Laravel logs:
```bash
tail -f /var/www/Tenjo/dashboard/storage/logs/laravel.log
```

### Nginx access logs:
```bash
tail -f /var/log/nginx/access.log
```

### Nginx error logs:
```bash
tail -f /var/log/nginx/error.log
```

### PostgreSQL logs:
```bash
sudo tail -f /var/log/postgresql/postgresql-11-main.log
```

---

## Emergency Rollback

### Restore database:
```bash
cd /var/www/Tenjo/backups
ls -lh backup_*.sql  # Find latest backup

PGPASSWORD="tenjo_secure_2025" psql -h 127.0.0.1 -U tenjo_user -d tenjo_production < backup_YYYYMMDD_HHMMSS.sql
```

### Revert code:
```bash
cd /var/www/Tenjo/dashboard
git log --oneline -5  # Find commit to revert to
git reset --hard <commit-hash>
```

---

## 🎯 Quick Start (Copy & Paste)

**Full deployment in one go:**
```bash
cd /var/www/Tenjo && \
mkdir -p backups && \
PGPASSWORD="tenjo_secure_2025" pg_dump -h 127.0.0.1 -U tenjo_user tenjo_production > backups/backup_$(date +%Y%m%d_%H%M%S).sql && \
cd dashboard && \
git pull origin master && \
php artisan migrate --force && \
cd /var/www/Tenjo && \
php cleanup_duplicate_clients.php && \
echo "✅ Deployment complete!"
```

**Test silent deployment:**
```bash
cd /var/www/Tenjo/dashboard && \
php artisan tinker --execute="
\$client = \App\Models\Client::first();
\$client->pending_update = true;
\$client->update_version = '2025.10.02';
\$client->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_2025.10.02.tar.gz';
\$client->save();
echo '✅ Test update triggered for ' . \$client->hostname . PHP_EOL;
"
```

---

## 📞 Need Help?

**Check system status:**
```bash
cd /var/www/Tenjo && php artisan tinker --execute="
echo '━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo 'SYSTEM STATUS' . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo 'Clients: ' . \App\Models\Client::count() . PHP_EOL;
echo 'Active: ' . \App\Models\Client::where('last_seen', '>', now()->subHours(24))->count() . PHP_EOL;
echo 'Pending updates: ' . \App\Models\Client::where('pending_update', true)->count() . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
"
```
