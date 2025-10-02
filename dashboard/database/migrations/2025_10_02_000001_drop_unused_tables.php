<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Drop unused tables to optimize database:
     * - browser_events (replaced by browser_sessions)
     * - process_events (not critical for monitoring)
     * - url_events (replaced by url_activities)
     */
    public function up(): void
    {
        // Drop browser_events table (replaced by browser_sessions with better tracking)
        Schema::dropIfExists('browser_events');

        // Drop process_events table (not critical, heavy on database)
        Schema::dropIfExists('process_events');

        // Drop url_events table (replaced by url_activities with better tracking)
        Schema::dropIfExists('url_events');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Recreate browser_events table
        Schema::create('browser_events', function (Blueprint $table) {
            $table->id();
            $table->string('client_id');
            $table->foreign('client_id')->references('client_id')->on('clients')->onDelete('cascade');
            $table->enum('event_type', ['browser_started', 'browser_closed']);
            $table->string('browser_name');
            $table->timestamp('start_time')->nullable();
            $table->timestamp('end_time')->nullable();
            $table->integer('duration')->nullable();
            $table->timestamps();

            $table->index(['client_id', 'start_time']);
            $table->index(['browser_name', 'start_time']);
            $table->index('start_time');
        });

        // Recreate process_events table
        Schema::create('process_events', function (Blueprint $table) {
            $table->id();
            $table->string('client_id');
            $table->foreign('client_id')->references('client_id')->on('clients')->onDelete('cascade');
            $table->string('process_name');
            $table->string('executable_path')->nullable();
            $table->enum('event_type', ['started', 'stopped']);
            $table->integer('memory_usage')->nullable();
            $table->float('cpu_usage')->nullable();
            $table->timestamps();

            $table->index(['client_id', 'created_at']);
            $table->index('process_name');
        });

        // Recreate url_events table
        Schema::create('url_events', function (Blueprint $table) {
            $table->id();
            $table->string('client_id');
            $table->foreign('client_id')->references('client_id')->on('clients')->onDelete('cascade');
            $table->text('url');
            $table->string('title')->nullable();
            $table->string('browser_name')->nullable();
            $table->timestamps();

            $table->index(['client_id', 'created_at']);
        });
    }
};
