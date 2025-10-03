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
# STEP 6: CREATE ADMIN USER
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6: Create Admin User"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /var/www/Tenjo/dashboard

echo "Creating admin user for dashboard access..."
echo ""

# Check if User model exists
if php artisan tinker --execute="echo class_exists('App\Models\User') ? 'yes' : 'no';" | grep -q "yes"; then
    # Create admin user
    php artisan tinker --execute="
    \$email = 'admin@tenjo.local';
    \$existing = \App\Models\User::where('email', \$email)->first();
    
    if (\$existing) {
        echo '⚠️  Admin user already exists' . PHP_EOL;
        echo 'Email: ' . \$existing->email . PHP_EOL;
    } else {
        \$user = \App\Models\User::create([
            'name' => 'Tenjo Admin',
            'email' => \$email,
            'password' => bcrypt('TenjoAdmin2025!'),
            'email_verified_at' => now()
        ]);
        
        echo '✅ Admin user created successfully!' . PHP_EOL;
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
        echo 'Email:    ' . \$user->email . PHP_EOL;
        echo 'Password: TenjoAdmin2025!' . PHP_EOL;
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
        echo PHP_EOL;
        echo '⚠️  IMPORTANT: Change this password after first login!' . PHP_EOL;
    }
    "
else
    echo "⚠️  User model not found - skipping admin creation"
    echo "   You can create admin user later manually"
fi

echo ""
read -p "Press ENTER to continue to STEP 7..."

# ============================================================================
# STEP 7: SETUP DOMAIN & SSL
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 7: Setup Domain & SSL Certificate"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Domain: tenjo.adilabs.id"
echo ""

# Check DNS
echo "Checking DNS configuration..."
DNS_IP=$(dig +short tenjo.adilabs.id | tail -1)

if [ "$DNS_IP" = "103.129.149.67" ]; then
    echo "✅ DNS configured correctly: $DNS_IP"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "SSL Certificate Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To install SSL certificate with Certbot:"
    echo ""
    echo "1. Install Certbot (if not installed):"
    echo "   sudo apt update"
    echo "   sudo apt install -y certbot python3-certbot-nginx"
    echo ""
    echo "2. Install SSL certificate:"
    echo "   sudo certbot --nginx -d tenjo.adilabs.id"
    echo ""
    echo "3. Follow the prompts:"
    echo "   - Enter email address"
    echo "   - Agree to Terms of Service (Y)"
    echo "   - Choose redirect HTTP to HTTPS (option 2)"
    echo ""
    echo "4. Certbot will automatically:"
    echo "   - Obtain SSL certificate from Let's Encrypt"
    echo "   - Configure Nginx for HTTPS"
    echo "   - Setup auto-renewal"
    echo ""
    
    read -p "Do you want to install SSL certificate now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Installing SSL certificate..."
        
        # Check if certbot is installed
        if ! command -v certbot &> /dev/null; then
            echo "Installing Certbot..."
            sudo apt update
            sudo apt install -y certbot python3-certbot-nginx
        fi
        
        # Install SSL certificate
        echo ""
        echo "Running Certbot for tenjo.adilabs.id..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        sudo certbot --nginx -d tenjo.adilabs.id --non-interactive --agree-tos --email admin@adilabs.id --redirect
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ SSL certificate installed successfully!"
            echo "✅ HTTPS enabled: https://tenjo.adilabs.id"
            echo "✅ Auto-renewal configured"
        else
            echo ""
            echo "⚠️  SSL installation failed. You can try manually:"
            echo "   sudo certbot --nginx -d tenjo.adilabs.id"
        fi
    else
        echo "⏭️  Skipping SSL setup"
        echo "   You can install SSL later with:"
        echo "   sudo certbot --nginx -d tenjo.adilabs.id"
    fi
else
    echo "⚠️  DNS not configured correctly"
    echo "   Current IP: $DNS_IP"
    echo "   Expected:   103.129.149.67"
    echo ""
    echo "Please configure DNS A record:"
    echo "   tenjo.adilabs.id → 103.129.149.67"
    echo ""
    echo "After DNS is configured, run SSL setup manually:"
    echo "   sudo certbot --nginx -d tenjo.adilabs.id"
fi

echo ""
read -p "Press ENTER to continue to STEP 8..."

# ============================================================================
# STEP 8: FINAL VERIFICATION
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 8: Final Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /var/www/Tenjo/dashboard

echo "System Status:"
php artisan tinker --execute="
\$clients = \App\Models\Client::count();
\$active = \App\Models\Client::where('last_seen', '>', now()->subHours(24))->count();
\$screenshots = \App\Models\Screenshot::count();
$browserSessions = \App\Models\BrowserSession::count();
$urlActivities = \App\Models\UrlActivity::count();

echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo '         SYSTEM STATUS             ' . PHP_EOL;
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' . PHP_EOL;
echo 'Total Clients:    ' . \$clients . PHP_EOL;
echo 'Active (24h):     ' . \$active . PHP_EOL;
echo 'Screenshots:      ' . number_format(\$screenshots) . PHP_EOL;
echo 'Browser Sessions: ' . number_format($browserSessions) . PHP_EOL;
echo 'URL Activities:   ' . number_format($urlActivities) . PHP_EOL;
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "� ACCESS INFORMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Application URLs:"
if [ -f "/etc/letsencrypt/live/tenjo.adilabs.id/fullchain.pem" ]; then
    echo "   Dashboard: https://tenjo.adilabs.id ✅"
    echo "   API:       https://tenjo.adilabs.id/api ✅"
else
    echo "   Dashboard: http://103.129.149.67 (or http://tenjo.adilabs.id if DNS ready)"
    echo "   API:       http://103.129.149.67/api"
    echo "   ⚠️  SSL not installed - using HTTP"
fi
echo ""
echo "👤 Admin Login:"
echo "   Email:    admin@tenjo.local"
echo "   Password: TenjoAdmin2025!"
echo "   ⚠️  Change password after first login!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 🧪 Test Dashboard Access:"
if [ -f "/etc/letsencrypt/live/tenjo.adilabs.id/fullchain.pem" ]; then
    echo "   Open: https://tenjo.adilabs.id/login"
else
    echo "   Open: http://103.129.149.67/login"
fi
echo "   Login with admin credentials above"
echo ""
echo "2. 🚀 Test Silent Deployment (1 PC):"
echo "   cd /var/www/Tenjo/dashboard"
echo "   php artisan tinker --execute=\""
echo "   \\\$c = \\App\\Models\\Client::first();"
echo "   \\\$c->pending_update = true;"
echo "   \\\$c->update_version = '2025.10.02';"
echo "   \\\$c->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_2025.10.02.tar.gz';"
echo "   \\\$c->save();"
echo "   echo '✅ Test triggered' . PHP_EOL;"
echo "   \""
echo ""
echo "3. 📊 Monitor Update:"
echo "   watch -n 5 'php artisan tinker --execute=\""
echo "   \\\$c = \\App\\Models\\Client::first();"
echo "   echo \\\"Pending: \\\" . (\\\$c->pending_update ? \\\"YES\\\" : \\\"NO\\\") . PHP_EOL;"
echo "   echo \\\"Version: \\\" . (\\\$c->current_version ?? \\\"old\\\") . PHP_EOL;"
echo "   \"'"
echo ""
echo "4. 🚀 Mass Deployment (All PCs):"
echo "   cd /var/www/Tenjo"
echo "   ./silent_push_deploy.sh 2025.10.02"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 System is READY!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
