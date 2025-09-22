#!/bin/bash

# Database Cleanup Setup Script for Tenjo Employee Monitoring
# This script sets up automated database cleanup cronjobs

echo "🧹 Setting up Tenjo Database Cleanup Cronjobs..."

# Backup current crontab
echo "📋 Backing up current crontab..."
crontab -l > /tmp/crontab_backup_$(date +%Y%m%d_%H%M%S).txt

# Create new crontab with existing entries plus database cleanup
echo "⚙️  Adding database cleanup jobs..."

# Get existing crontab (excluding our cleanup jobs)
(crontab -l 2>/dev/null | grep -v "tenjo:cleanup-database") > /tmp/new_crontab

# Add database cleanup jobs
cat << EOF >> /tmp/new_crontab

# Tenjo Database Cleanup Jobs
# ============================

# Daily database cleanup (keep 7 days) - Every day at 4:00 AM
0 4 * * * /usr/bin/php /var/www/tenjo/dashboard/artisan tenjo:cleanup-database --days=7 >> /var/www/tenjo/dashboard/storage/logs/cleanup.log 2>&1

# Weekly deep cleanup (keep 3 days for heavy tables) - Every Sunday at 5:00 AM
0 5 * * 0 /usr/bin/php /var/www/tenjo/dashboard/artisan tenjo:cleanup-database --days=3 --deep >> /var/www/tenjo/dashboard/storage/logs/cleanup.log 2>&1

# Emergency cleanup (if URL activities > 200k) - Every 6 hours
0 */6 * * * [ \$(/usr/bin/php /var/www/tenjo/dashboard/artisan tinker --execute="echo App\\Models\\UrlActivity::count();" | tail -1) -gt 200000 ] && /usr/bin/php /var/www/tenjo/dashboard/artisan tenjo:cleanup-database --days=5 --deep >> /var/www/tenjo/dashboard/storage/logs/cleanup.log 2>&1

EOF

# Install new crontab
crontab /tmp/new_crontab

echo "✅ Database cleanup cronjobs installed successfully!"
echo ""
echo "📋 Current crontab:"
crontab -l

echo ""
echo "🔧 Manual Commands Available:"
echo "  # Test cleanup (dry run):"
echo "  php artisan tenjo:cleanup-database --dry-run"
echo ""
echo "  # Standard cleanup (keep 7 days):"
echo "  php artisan tenjo:cleanup-database --days=7"
echo ""
echo "  # Aggressive cleanup (keep 3 days):"
echo "  php artisan tenjo:cleanup-database --days=3 --deep"
echo ""
echo "  # Emergency cleanup (keep 1 day):"
echo "  php artisan tenjo:cleanup-database --days=1 --deep"

echo ""
echo "📊 Run test cleanup now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "🧪 Running test cleanup (dry run)..."
    cd /var/www/tenjo/dashboard
    php artisan tenjo:cleanup-database --dry-run
fi

echo ""
echo "🎉 Setup complete! Database will be automatically cleaned daily at 4 AM."
echo "📝 Logs available at: /var/www/tenjo/dashboard/storage/logs/cleanup.log"

# Cleanup temp file
rm -f /tmp/new_crontab
