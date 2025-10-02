<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations - Add proper foreign key constraints for CASCADE DELETE.
     */
    public function up(): void
    {
        // Add foreign key for url_activities.client_id
        Schema::table('url_activities', function (Blueprint $table) {
            // Add foreign key constraint with cascade delete
            $table->foreign('client_id')
                ->references('client_id')
                ->on('clients')
                ->onDelete('cascade')
                ->name('fk_url_activities_client_id');
        });

        // Add foreign key for browser_sessions.client_id
        Schema::table('browser_sessions', function (Blueprint $table) {
            // Add foreign key constraint with cascade delete
            $table->foreign('client_id')
                ->references('client_id')
                ->on('clients')
                ->onDelete('cascade')
                ->name('fk_browser_sessions_client_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('url_activities', function (Blueprint $table) {
            $table->dropForeign('fk_url_activities_client_id');
        });

        Schema::table('browser_sessions', function (Blueprint $table) {
            $table->dropForeign('fk_browser_sessions_client_id');
        });
    }
};
