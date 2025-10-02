#!/bin/bash
# Fix PostgreSQL Migration Syntax Error

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          Fix PostgreSQL Migration Syntax                ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

cd /var/www/Tenjo/dashboard

# Rollback the failed migration
echo "Step 1: Rolling back failed migration..."
php artisan migrate:rollback --step=1

if [ $? -eq 0 ]; then
    echo "✅ Rollback successful!"
else
    echo "⚠️  Rollback had issues (might be already rolled back)"
fi

# Find and fix the migration file
echo ""
echo "Step 2: Fixing migration syntax for PostgreSQL..."

MIGRATION_FILE="database/migrations/2025_10_02_100001_limit_text_field_sizes.php"

if [ -f "$MIGRATION_FILE" ]; then
    # Create backup
    cp "$MIGRATION_FILE" "${MIGRATION_FILE}.backup"
    echo "✅ Backup created: ${MIGRATION_FILE}.backup"
    
    # Fix the migration file for PostgreSQL
    cat > "$MIGRATION_FILE" << 'MIGRATION_EOF'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // PostgreSQL syntax: ALTER COLUMN instead of MODIFY COLUMN
        
        // Limit url_activities.url to 2048 characters
        DB::statement('ALTER TABLE url_activities ALTER COLUMN url TYPE VARCHAR(2048)');
        
        // Limit url_activities.title to 500 characters
        DB::statement('ALTER TABLE url_activities ALTER COLUMN title TYPE VARCHAR(500)');
        
        // Limit browser_events.url to 2048 characters
        DB::statement('ALTER TABLE browser_events ALTER COLUMN url TYPE VARCHAR(2048)');
        
        // Limit browser_events.title to 500 characters
        DB::statement('ALTER TABLE browser_events ALTER COLUMN title TYPE VARCHAR(500)');
        
        // Limit process_events.process_name to 255 characters
        DB::statement('ALTER TABLE process_events ALTER COLUMN process_name TYPE VARCHAR(255)');
        
        // Limit process_events.window_title to 500 characters
        DB::statement('ALTER TABLE process_events ALTER COLUMN window_title TYPE VARCHAR(500)');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert back to TEXT type
        DB::statement('ALTER TABLE url_activities ALTER COLUMN url TYPE TEXT');
        DB::statement('ALTER TABLE url_activities ALTER COLUMN title TYPE TEXT');
        DB::statement('ALTER TABLE browser_events ALTER COLUMN url TYPE TEXT');
        DB::statement('ALTER TABLE browser_events ALTER COLUMN title TYPE TEXT');
        DB::statement('ALTER TABLE process_events ALTER COLUMN process_name TYPE TEXT');
        DB::statement('ALTER TABLE process_events ALTER COLUMN window_title TYPE TEXT');
    }
};
MIGRATION_EOF
    
    echo "✅ Migration file fixed for PostgreSQL!"
    
    # Show the changes
    echo ""
    echo "Changes made:"
    echo "  - Changed: MODIFY COLUMN → ALTER COLUMN TYPE"
    echo "  - Syntax: PostgreSQL compatible"
    
else
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

# Run the migration again
echo ""
echo "Step 3: Running migration again..."
php artisan migrate --force

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              ✅ MIGRATION FIXED!                         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "All migrations completed successfully!"
    echo "You can continue with the deployment."
else
    echo ""
    echo "❌ Migration still has errors!"
    echo ""
    echo "Check the error above and try:"
    echo "  php artisan migrate:status"
    echo "  php artisan migrate --force"
    exit 1
fi
