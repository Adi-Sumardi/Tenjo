<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations - Convert unlimited TEXT fields to VARCHAR with size limits.
     * Note: SQLite doesn't support MODIFY COLUMN, so we skip for SQLite (mainly used in testing).
     * For production MySQL/PostgreSQL, this reduces storage significantly.
     */
    public function up(): void
    {
        // Check if using SQLite (skip modification for SQLite)
        if (DB::connection()->getDriverName() === 'sqlite') {
            // SQLite doesn't support MODIFY COLUMN
            // In production, we'll use MySQL/PostgreSQL where this is critical
            return;
        }

        // Modify url_activities table - biggest storage impact
        // For MySQL/PostgreSQL
        Schema::table('url_activities', function (Blueprint $table) {
            // Change TEXT to VARCHAR with reasonable limits
            // URLs are typically < 2KB, but we allow 2048 chars to be safe
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN url VARCHAR(2048) NOT NULL');
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN page_title VARCHAR(500) NULL');
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN referrer_url VARCHAR(2048) NULL');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Check if using SQLite
        if (DB::connection()->getDriverName() === 'sqlite') {
            return;
        }

        Schema::table('url_activities', function (Blueprint $table) {
            // Revert back to TEXT if needed
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN url TEXT NOT NULL');
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN page_title TEXT NULL');
            DB::statement('ALTER TABLE url_activities MODIFY COLUMN referrer_url TEXT NULL');
        });
    }
};
