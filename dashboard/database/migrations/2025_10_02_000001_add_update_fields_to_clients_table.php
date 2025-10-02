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
        Schema::table('clients', function (Blueprint $table) {
            // Update management fields
            $table->boolean('pending_update')->default(false)->after('status');
            $table->string('update_version', 50)->nullable()->after('pending_update');
            $table->text('update_url')->nullable()->after('update_version');
            $table->text('update_changes')->nullable()->after('update_url');
            $table->timestamp('update_triggered_at')->nullable()->after('update_changes');
            $table->timestamp('update_completed_at')->nullable()->after('update_triggered_at');
            $table->string('current_version', 50)->nullable()->after('update_completed_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('clients', function (Blueprint $table) {
            $table->dropColumn([
                'pending_update',
                'update_version',
                'update_url',
                'update_changes',
                'update_triggered_at',
                'update_completed_at',
                'current_version'
            ]);
        });
    }
};
