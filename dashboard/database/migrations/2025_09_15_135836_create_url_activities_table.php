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
        Schema::create('url_activities', function (Blueprint $table) {
            $table->id();
            $table->string('client_id');
            $table->foreignId('browser_session_id')->constrained()->onDelete('cascade');
            $table->text('url');
            $table->string('domain');
            $table->text('page_title')->nullable();
            $table->string('tab_id')->nullable(); // Unique tab identifier
            $table->timestamp('visit_start');
            $table->timestamp('visit_end')->nullable();
            $table->integer('duration')->default(0); // in seconds
            $table->integer('scroll_depth')->default(0); // percentage
            $table->integer('clicks')->default(0);
            $table->integer('keystrokes')->default(0);
            $table->boolean('is_active')->default(true);
            $table->text('referrer_url')->nullable();
            $table->json('metadata')->nullable(); // Additional data like viewport size, etc.
            $table->timestamps();

            $table->index(['client_id', 'is_active']);
            $table->index(['domain', 'visit_start']);
            $table->index('visit_start');
            $table->index('duration');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('url_activities');
    }
};
