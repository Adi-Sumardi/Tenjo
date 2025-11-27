<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * FIX BUG #78: Add indexes for better query performance
     */
    public function up(): void
    {
        // Add index on activity_category for faster filtering
        Schema::table('url_activities', function (Blueprint $table) {
            if (!$this->indexExists('url_activities', 'url_activities_activity_category_index')) {
                $table->index('activity_category', 'url_activities_activity_category_index');
            }
            
            // Composite index for common query pattern
            if (!$this->indexExists('url_activities', 'url_activities_client_category_index')) {
                $table->index(['client_id', 'activity_category'], 'url_activities_client_category_index');
            }
            
            // Index for date range queries
            if (!$this->indexExists('url_activities', 'url_activities_visit_start_index')) {
                $table->index('visit_start', 'url_activities_visit_start_index');
            }
        });
        
        // Add indexes on browser_sessions for performance
        Schema::table('browser_sessions', function (Blueprint $table) {
            if (!$this->indexExists('browser_sessions', 'browser_sessions_client_browser_index')) {
                $table->index(['client_id', 'browser_name'], 'browser_sessions_client_browser_index');
            }
        });
        
        // Add index on screenshots for date filtering
        Schema::table('screenshots', function (Blueprint $table) {
            if (!$this->indexExists('screenshots', 'screenshots_captured_at_index')) {
                $table->index('captured_at', 'screenshots_captured_at_index');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('url_activities', function (Blueprint $table) {
            $table->dropIndex('url_activities_activity_category_index');
            $table->dropIndex('url_activities_client_category_index');
            $table->dropIndex('url_activities_visit_start_index');
        });
        
        Schema::table('browser_sessions', function (Blueprint $table) {
            $table->dropIndex('browser_sessions_client_browser_index');
        });
        
        Schema::table('screenshots', function (Blueprint $table) {
            $table->dropIndex('screenshots_captured_at_index');
        });
    }
    
    /**
     * Check if index exists
     */
    private function indexExists(string $table, string $index): bool
    {
        $connection = Schema::getConnection();
        $doctrineSchemaManager = $connection->getDoctrineSchemaManager();
        $doctrineTable = $doctrineSchemaManager->listTableDetails($table);
        
        return $doctrineTable->hasIndex($index);
    }
};
