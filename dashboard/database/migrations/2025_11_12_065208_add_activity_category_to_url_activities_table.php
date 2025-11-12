<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('url_activities', function (Blueprint $table) {
            // Add activity_category column
            $table->string('activity_category', 50)->default('work')->after('is_active');

            // Add index for better query performance
            $table->index('activity_category');
            $table->index(['client_id', 'activity_category']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('url_activities', function (Blueprint $table) {
            // Drop indexes first
            $table->dropIndex(['client_id', 'activity_category']);
            $table->dropIndex(['activity_category']);

            // Drop column
            $table->dropColumn('activity_category');
        });
    }
};
