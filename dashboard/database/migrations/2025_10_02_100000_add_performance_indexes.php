<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations - Add missing indexes for performance optimization.
     */
    public function up(): void
    {
        // Add composite indexes for url_activities table (most critical)
        Schema::table('url_activities', function (Blueprint $table) {
            // Composite index for common queries filtering by client, active status, and date
            $table->index(['client_id', 'visit_start', 'is_active'], 'idx_url_activities_client_date_active');

            // Index for duration-based queries (analytics)
            $table->index(['domain', 'duration'], 'idx_url_activities_domain_duration');

            // Index for cleanup operations
            $table->index(['created_at', 'is_active'], 'idx_url_activities_cleanup');
        });

        // Add indexes for screenshots table
        Schema::table('screenshots', function (Blueprint $table) {
            // Composite index for queries filtering by client, monitor, and date
            $table->index(['client_id', 'monitor', 'captured_at'], 'idx_screenshots_client_monitor_date');

            // Index for cleanup operations
            $table->index(['created_at'], 'idx_screenshots_cleanup');
        });

        // Add indexes for browser_sessions table
        Schema::table('browser_sessions', function (Blueprint $table) {
            // Index for session end time (used in cleanup and analytics)
            $table->index(['session_end'], 'idx_browser_sessions_end_time');

            // Composite index for browser analytics
            $table->index(['browser_name', 'session_start'], 'idx_browser_sessions_analytics');

            // Index for cleanup operations
            $table->index(['created_at', 'is_active'], 'idx_browser_sessions_cleanup');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('url_activities', function (Blueprint $table) {
            $table->dropIndex('idx_url_activities_client_date_active');
            $table->dropIndex('idx_url_activities_domain_duration');
            $table->dropIndex('idx_url_activities_cleanup');
        });

        Schema::table('screenshots', function (Blueprint $table) {
            $table->dropIndex('idx_screenshots_client_monitor_date');
            $table->dropIndex('idx_screenshots_cleanup');
        });

        Schema::table('browser_sessions', function (Blueprint $table) {
            $table->dropIndex('idx_browser_sessions_end_time');
            $table->dropIndex('idx_browser_sessions_analytics');
            $table->dropIndex('idx_browser_sessions_cleanup');
        });
    }
};
