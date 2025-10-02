#!/bin/bash
# VPS Deployment Commands - Copy/Paste ke Terminal VPS
# Execute on VPS: tenjo-app@103.129.149.67

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Tenjo Production Deployment Script              ║"
echo "║              VPS: 103.129.149.67                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# STEP 1: BACKUP DATABASE (CRITICAL!)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Backup Database"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /var/www/Tenjo

# Create backups directory if not exists
mkdir -p backups

# Backup with password (using -h 127.0.0.1 to force TCP connection)
PGPASSWORD="tenjo_secure_2025" pg_dump -h 127.0.0.1 -U tenjo_user tenjo_production > backups/backup_$(date +%Y%m%d_%H%M%S).sql

if [ $? -eq 0 ]; then
    echo "✅ Database backup created successfully!"
    ls -lh backups/backup_*.sql | tail -1
else
    echo "❌ Backup failed! STOP HERE - Do not proceed!"
    exit 1
fi

echo ""
read -p "Press ENTER to continue to STEP 2..."

# ============================================================================
# STEP 2: PULL LATEST CODE FROM GITHUB
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Pull Latest Code from GitHub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /var/www/Tenjo/dashboard

echo "Current branch:"
git branch --show-current

echo ""
echo "Pulling latest changes..."
git pull origin master

if [ $? -eq 0 ]; then
    echo "✅ Code updated successfully!"
else
    echo "❌ Git pull failed!"
    exit 1
fi

echo ""
read -p "Press ENTER to continue to STEP 3..."

# ============================================================================
# STEP 3: RUN DATABASE MIGRATION
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Run Database Migration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /var/www/Tenjo/dashboard

echo "Running migrations..."
php artisan migrate --force

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
else
    echo "❌ Migration failed!"
    exit 1
fi

# Verify migration
echo ""
echo "Verifying new columns..."
php artisan tinker --execute="
use Illuminate\Support\Facades\Schema;
\$fields = ['pending_update', 'update_version', 'update_url', 'update_changes', 'update_triggered_at', 'update_completed_at', 'current_version'];
echo 'Checking new columns:' . PHP_EOL;
foreach (\$fields as \$field) {
    \$exists = Schema::hasColumn('clients', \$field);
    echo '  ' . \$field . ': ' . (\$exists ? '✅' : '❌') . PHP_EOL;
}
"

echo ""
read -p "Press ENTER to continue to STEP 4..."

# ============================================================================
# STEP 4: CLEANUP DUPLICATE CLIENTS
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Cleanup Duplicate Clients"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /var/www/Tenjo

echo "Current client count:"
php artisan tinker --execute="
\$total = \App\Models\Client::count();
\$duplicates = \App\Models\Client::select('hostname', \DB::raw('COUNT(*) as count'))
    ->groupBy('hostname')
    ->havingRaw('COUNT(*) > 1')
    ->get();
    
echo 'Total clients: ' . \$total . PHP_EOL;
echo 'Hostnames with duplicates: ' . \$duplicates->count() . PHP_EOL;

if (\$duplicates->count() > 0) {
    echo PHP_EOL . 'Duplicate hostnames:' . PHP_EOL;
    foreach (\$duplicates as \$dup) {
        echo '  - ' . \$dup->hostname . ' (' . \$dup->count . ' registrations)' . PHP_EOL;
    }
}
"

echo ""
read -p "Do you want to cleanup duplicates? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running cleanup script..."
    php cleanup_duplicate_clients.php
    
    echo ""
    echo "After cleanup:"
    php artisan tinker --execute="
    \$total = \App\Models\Client::count();
    echo 'Total clients: ' . \$total . PHP_EOL;
    "
    
    echo "✅ Cleanup completed!"
else
    echo "⏭️  Skipping cleanup"
fi

echo ""
read -p "Press ENTER to continue to STEP 5..."

# ============================================================================
# STEP 5: SETUP DEPLOYMENT SCRIPTS
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Setup Deployment Scripts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /var/www/Tenjo

# Make scripts executable
chmod +x deploy_production.sh mass_deploy.sh silent_push_deploy.sh

# Create packages directory
mkdir -p packages
chmod 755 packages

echo "✅ Scripts ready:"
ls -lh *.sh | grep -E "deploy|mass|silent"

echo ""
read -p "Press ENTER to continue to STEP 6..."

# ============================================================================
# STEP 6: FINAL VERIFICATION
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6: Final Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /var/www/Tenjo/dashboard

echo "System Status:"
php artisan tinker --execute="
\$clients = \App\Models\Client::count();
\$active = \App\Models\Client::where('last_seen', '>', now()->subHours(24))->count();
\$screenshots = \App\Models\Screenshot::count();
\$urlEvents = \App\Models\UrlEvent::count();

echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo '         SYSTEM STATUS             ' . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo 'Total Clients:    ' . \$clients . PHP_EOL;
echo 'Active (24h):     ' . \$active . PHP_EOL;
echo 'Screenshots:      ' . number_format(\$screenshots) . PHP_EOL;
echo 'URL Events:       ' . number_format(\$urlEvents) . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
"

echo ""
echo "Database size:"
PGPASSWORD="tenjo_secure_2025" psql -h 127.0.0.1 -U tenjo_user -d tenjo_production -c "SELECT pg_size_pretty(pg_database_size('tenjo_production')) AS size;"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              ✅ DEPLOYMENT COMPLETED!                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Test silent deployment on 1 PC first:"
echo "   ./silent_push_deploy.sh 2025.10.02"
echo ""
echo "2. Or trigger update manually for testing:"
echo "   cd /var/www/Tenjo/dashboard"
echo "   php artisan tinker"
echo "   >>> \$client = App\\Models\\Client::first();"
echo "   >>> \$client->pending_update = true;"
echo "   >>> \$client->update_version = '2025.10.02';"
echo "   >>> \$client->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_2025.10.02.tar.gz';"
echo "   >>> \$client->save();"
echo ""
echo "3. Monitor update progress:"
echo "   watch -n 5 'php artisan tinker --execute=\"echo App\\\\Models\\\\Client::where(\\\"pending_update\\\", true)->count();\"'"
echo ""
echo "🎉 System is READY for silent deployment!"
echo ""
