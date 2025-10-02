<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations - Convert unlimited TEXT fields to VARCHAR with size limits.
     * Note: SQLite doesn't support ALTER COLUMN, so we skip for SQLite (mainly used in testing).
     * For production PostgreSQL/MySQL, this reduces storage significantly.
     *
     * Only modifies url_activities table (other tables don't have TEXT columns that need limiting).
     */
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();

        // Check if using SQLite (skip modification for SQLite)
        if ($driver === 'sqlite') {
            // SQLite doesn't support ALTER COLUMN
            // In production, we'll use PostgreSQL/MySQL where this is critical
            return;
        }

        // Modify url_activities table ONLY - biggest storage impact
        // Columns: url, page_title, referrer_url (all are TEXT fields)

        // IMPORTANT: Truncate existing data that exceeds the new limits BEFORE changing column type
        // This prevents "value too long" errors during migration
        DB::statement("UPDATE url_activities SET url = LEFT(url, 2048) WHERE LENGTH(url) > 2048");
        DB::statement("UPDATE url_activities SET page_title = LEFT(page_title, 500) WHERE LENGTH(page_title) > 500");
        DB::statement("UPDATE url_activities SET referrer_url = LEFT(referrer_url, 2048) WHERE LENGTH(referrer_url) > 2048");

        // Use PostgreSQL syntax (ALTER COLUMN TYPE) or MySQL syntax (MODIFY COLUMN)
        if ($driver === 'pgsql') {
            // PostgreSQL syntax
            DB::statement('ALTER TABLE url_activities ALTER COLUMN url TYPE VARCHAR(2048)');
            DB::statement('ALTER TABLE url_activities ALTER COLUMN page_title TYPE VARCHAR(500)');
            DB::statement('ALTER TABLE url_activities ALTER COLUMN referrer_url TYPE VARCHAR(2048)');
        } else {
            // MySQL syntax
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN url VARCHAR(2048) NOT NULL');
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN page_title VARCHAR(500) NULL');
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN referrer_url VARCHAR(2048) NULL');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $driver = DB::connection()->getDriverName();

        // Check if using SQLite
        if ($driver === 'sqlite') {
            return;
        }

        // Revert back to TEXT if needed
        if ($driver === 'pgsql') {
            // PostgreSQL syntax
            DB::statement('ALTER TABLE url_activities ALTER COLUMN url TYPE TEXT');
            DB::statement('ALTER TABLE url_activities ALTER COLUMN page_title TYPE TEXT');
            DB::statement('ALTER TABLE url_activities ALTER COLUMN referrer_url TYPE TEXT');
        } else {
            // MySQL syntax
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN url TEXT NOT NULL');
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN page_title TEXT NULL');
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN referrer_url TEXT NULL');
        }
    }
};
