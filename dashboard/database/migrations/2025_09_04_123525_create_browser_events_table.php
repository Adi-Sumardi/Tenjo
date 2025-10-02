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
        Schema::create('browser_events', function (Blueprint $table) {
            $table->id();
            $table->string('client_id'); // Changed to string for UUID
            $table->foreign('client_id')->references('client_id')->on('clients')->onDelete('cascade');
            $table->enum('event_type', ['browser_started', 'browser_closed']);
            $table->string('browser_name');
            $table->timestamp('start_time')->nullable();
            $table->timestamp('end_time')->nullable();
            $table->integer('duration')->nullable(); // in seconds
            $table->timestamps();

            $table->index(['client_id', 'start_time']);
            $table->index(['browser_name', 'start_time']);
            $table->index('start_time');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('browser_events');
    }
};
