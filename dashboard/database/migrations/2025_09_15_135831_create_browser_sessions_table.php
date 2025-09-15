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
        Schema::create('browser_sessions', function (Blueprint $table) {
            $table->id();
            $table->string('client_id');
            $table->string('browser_name'); // Chrome, Firefox, Safari, etc.
            $table->string('browser_version')->nullable();
            $table->string('browser_executable_path')->nullable();
            $table->integer('window_count')->default(0);
            $table->integer('tab_count')->default(0);
            $table->timestamp('session_start');
            $table->timestamp('session_end')->nullable();
            $table->integer('total_duration')->default(0); // in seconds
            $table->boolean('is_active')->default(true);
            $table->json('window_titles')->nullable(); // Array of window titles
            $table->timestamps();
            
            $table->index(['client_id', 'is_active']);
            $table->index('session_start');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('browser_sessions');
    }
};
