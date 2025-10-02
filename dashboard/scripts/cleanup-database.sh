#!/bin/bash

# Tenjo Database Cleanup Script
# This script removes old data to keep database size manageable
# Recommended to run daily via cron

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/storage/logs/cleanup.log"

# Retention periods (in days)
SCREENSHOT_RETENTION=7
URL_ACTIVITY_RETENTION=30
BROWSER_SESSION_RETENTION=30

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "================================"
log_message "Starting database cleanup..."
log_message "================================"

# Navigate to project root
cd "$PROJECT_ROOT" || exit 1

# Run cleanup commands using Laravel Tinker
log_message "Cleaning up old screenshots (older than $SCREENSHOT_RETENTION days)..."
php artisan tinker --execute="
    \$count = \App\Models\Screenshot::where('captured_at', '<', now()->subDays($SCREENSHOT_RETENTION))->count();
    echo \"Found \$count old screenshots to delete\n\";

    if (\$count > 0) {
        \$deleted = \App\Models\Screenshot::where('captured_at', '<', now()->subDays($SCREENSHOT_RETENTION))->delete();
        echo \"Deleted \$deleted screenshots\n\";
    }
" 2>&1 | tee -a "$LOG_FILE"

log_message "Cleaning up old URL activities (older than $URL_ACTIVITY_RETENTION days)..."
php artisan tinker --execute="
    \$count = \App\Models\UrlActivity::where('visit_start', '<', now()->subDays($URL_ACTIVITY_RETENTION))->count();
    echo \"Found \$count old URL activities to delete\n\";

    if (\$count > 0) {
        \$deleted = \App\Models\UrlActivity::where('visit_start', '<', now()->subDays($URL_ACTIVITY_RETENTION))->delete();
        echo \"Deleted \$deleted URL activities\n\";
    }
" 2>&1 | tee -a "$LOG_FILE"

log_message "Cleaning up old browser sessions (older than $BROWSER_SESSION_RETENTION days)..."
php artisan tinker --execute="
    \$count = \App\Models\BrowserSession::where('session_start', '<', now()->subDays($BROWSER_SESSION_RETENTION))->count();
    echo \"Found \$count old browser sessions to delete\n\";

    if (\$count > 0) {
        \$deleted = \App\Models\BrowserSession::where('session_start', '<', now()->subDays($BROWSER_SESSION_RETENTION))->delete();
        echo \"Deleted \$deleted browser sessions\n\";
    }
" 2>&1 | tee -a "$LOG_FILE"

# Optimize database (SQLite VACUUM)
log_message "Optimizing database (VACUUM)..."
php artisan tinker --execute="
    if (config('database.default') === 'sqlite') {
        \$dbPath = database_path('database.sqlite');
        \$sizeBefore = filesize(\$dbPath);
        echo \"Database size before VACUUM: \" . number_format(\$sizeBefore / 1024 / 1024, 2) . \" MB\n\";

        \DB::statement('VACUUM');
        clearstatcache();

        \$sizeAfter = filesize(\$dbPath);
        echo \"Database size after VACUUM: \" . number_format(\$sizeAfter / 1024 / 1024, 2) . \" MB\n\";
        echo \"Saved: \" . number_format((\$sizeBefore - \$sizeAfter) / 1024 / 1024, 2) . \" MB\n\";
    }
" 2>&1 | tee -a "$LOG_FILE"

# Clear old logs (older than 30 days)
log_message "Cleaning up old log files (older than 30 days)..."
find "$PROJECT_ROOT/storage/logs" -name "*.log" -type f -mtime +30 -delete 2>&1 | tee -a "$LOG_FILE"

# Database statistics
log_message "Current database statistics:"
php artisan tinker --execute="
    echo \"Clients: \" . \App\Models\Client::count() . \"\n\";
    echo \"Screenshots: \" . \App\Models\Screenshot::count() . \"\n\";
    echo \"Browser Sessions: \" . \App\Models\BrowserSession::count() . \"\n\";
    echo \"URL Activities: \" . \App\Models\UrlActivity::count() . \"\n\";

    if (config('database.default') === 'sqlite') {
        \$dbPath = database_path('database.sqlite');
        \$size = filesize(\$dbPath);
        echo \"Database size: \" . number_format(\$size / 1024 / 1024, 2) . \" MB\n\";
    }
" 2>&1 | tee -a "$LOG_FILE"

log_message "================================"
log_message "Database cleanup completed!"
log_message "================================"
log_message ""

exit 0
