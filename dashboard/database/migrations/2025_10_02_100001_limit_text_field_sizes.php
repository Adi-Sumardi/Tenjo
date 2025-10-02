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

        // Modify url_activities table - biggest storage impact
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
