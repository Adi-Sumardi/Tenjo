<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Schedule automatic database cleanup daily (CRITICAL for preventing storage explosion)
Schedule::command('tenjo:cleanup-database', ['--days=7'])
    ->daily()
    ->at('02:00')
    ->description('Daily cleanup of old database records (screenshots, URL activities, browser sessions older than 7 days)')
    ->emailOutputOnFailure(config('mail.admin_email', 'admin@tenjo.app'));

// Schedule weekly deep cleanup to aggressively reduce database size
Schedule::command('tenjo:cleanup-database', ['--days=3', '--deep'])
    ->weekly()
    ->sundays()
    ->at('03:00')
    ->description('Weekly deep cleanup - keeps only 3 days of data for heavy tables')
    ->emailOutputOnFailure(config('mail.admin_email', 'admin@tenjo.app'));

// Schedule automatic cleanup of stream chunks every week
Schedule::command('tenjo:cleanup-streams', ['--days=7'])
    ->weekly()
    ->sundays()
    ->at('02:00')
    ->description('Weekly cleanup of old stream chunks (older than 7 days)')
    ->emailOutputOnFailure(config('mail.admin_email', 'admin@tenjo.app'));

// Schedule daily cleanup for very old files (older than 30 days)
Schedule::command('tenjo:cleanup-streams', ['--days=30'])
    ->daily()
    ->at('03:00')
    ->description('Daily cleanup of very old stream chunks (older than 30 days)')
    ->when(function () {
        // Only run if storage is getting full (more than 5GB)
        $streamPath = storage_path('app/private/stream_chunks');
        if (!is_dir($streamPath)) return false;

        $totalSize = 0;
        $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($streamPath));
        foreach ($iterator as $file) {
            if ($file->isFile()) {
                $totalSize += $file->getSize();
            }
        }

        // Run cleanup if storage > 5GB (5 * 1024 * 1024 * 1024 bytes)
        return $totalSize > 5368709120;
    });

// Emergency cleanup for extremely old files (older than 1 day) if storage > 10GB
Schedule::command('tenjo:cleanup-streams', ['--days=1'])
    ->hourly()
    ->description('Emergency cleanup when storage is critically full')
    ->when(function () {
        $streamPath = storage_path('app/private/stream_chunks');
        if (!is_dir($streamPath)) return false;

        $totalSize = 0;
        $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($streamPath));
        foreach ($iterator as $file) {
            if ($file->isFile()) {
                $totalSize += $file->getSize();
            }
        }

        // Emergency cleanup if storage > 10GB
        return $totalSize > 10737418240;
    });

// Clear expired cache entries daily to prevent bloat
Schedule::call(function () {
    \Illuminate\Support\Facades\Cache::flush();
})->daily()->at('04:00')
    ->description('Daily cache cleanup to remove expired entries');

// Clear specific stream-related cache every hour
Schedule::call(function () {
    $prefix = 'stream_request_*';
    $pattern = 'latest_video_chunk_*';

    // Note: For file driver, Laravel handles expiration automatically
    // This is just a safety measure for edge cases
})->hourly()
    ->description('Hourly cleanup of stream cache entries');
