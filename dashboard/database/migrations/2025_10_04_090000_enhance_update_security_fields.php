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
            $table->string('update_checksum', 128)->nullable()->after('update_url');
            $table->unsignedBigInteger('update_package_size')->nullable()->after('update_checksum');
            $table->string('update_signature', 256)->nullable()->after('update_package_size');
            $table->enum('update_priority', ['low', 'normal', 'high', 'critical'])->default('normal')->after('update_signature');
            $table->time('update_window_start')->nullable()->after('update_priority');
            $table->time('update_window_end')->nullable()->after('update_window_start');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('clients', function (Blueprint $table) {
            $table->dropColumn([
                'update_checksum',
                'update_package_size',
                'update_signature',
                'update_priority',
                'update_window_start',
                'update_window_end',
            ]);
        });
    }
};
