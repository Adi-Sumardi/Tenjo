<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\UrlActivity;
use App\Models\Screenshot;
use App\Models\BrowserSession;
use App\Models\BrowserEvent;
use Carbon\Carbon;

class CleanupDatabase extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'tenjo:cleanup-database
                            {--days=7 : Number of days to keep data}
                            {--deep : Deep cleanup mode (more aggressive)}
                            {--dry-run : Show what would be deleted without actually deleting}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean up old database records to free up memory and disk space';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $days = (int) $this->option('days');
        $deep = $this->option('deep');
        $dryRun = $this->option('dry-run');

        $cutoffDate = Carbon::now()->subDays($days);

        $this->info("🧹 Database Cleanup Started");
        $this->info("📅 Cleaning data older than: {$cutoffDate->format('Y-m-d H:i:s')}");
        $this->info("🔧 Mode: " . ($deep ? 'Deep Cleanup' : 'Standard Cleanup'));

        if ($dryRun) {
            $this->warn("🔍 DRY RUN MODE - No data will be deleted");
        }

        $totalDeleted = 0;

        // 1. URL Activities (biggest table)
        $this->info("\n📊 Cleaning URL Activities...");
        $urlActivitiesQuery = UrlActivity::where('created_at', '<', $cutoffDate);
        $urlActivitiesCount = $urlActivitiesQuery->count();

        if ($urlActivitiesCount > 0) {
            $this->info("Found {$urlActivitiesCount} old URL activities");
            if (!$dryRun) {
                $deleted = $urlActivitiesQuery->delete();
                $totalDeleted += $deleted;
                $this->info("✅ Deleted {$deleted} URL activities");
            }
        } else {
            $this->info("✅ No old URL activities found");
        }

        // 2. Screenshots
        $this->info("\n📸 Cleaning Screenshots...");
        $screenshotsQuery = Screenshot::where('created_at', '<', $cutoffDate);
        $screenshotsCount = $screenshotsQuery->count();

        if ($screenshotsCount > 0) {
            $this->info("Found {$screenshotsCount} old screenshots");
            if (!$dryRun) {
                // Delete actual files first
                $screenshots = $screenshotsQuery->get();
                foreach ($screenshots as $screenshot) {
                    $filePath = storage_path('app/private/' . $screenshot->file_path);
                    if (file_exists($filePath)) {
                        unlink($filePath);
                    }
                }

                $deleted = $screenshotsQuery->delete();
                $totalDeleted += $deleted;
                $this->info("✅ Deleted {$deleted} screenshots and their files");
            }
        } else {
            $this->info("✅ No old screenshots found");
        }

        // 3. Browser Sessions
        $this->info("\n🌐 Cleaning Browser Sessions...");
        $browserSessionsQuery = BrowserSession::where('created_at', '<', $cutoffDate);
        $browserSessionsCount = $browserSessionsQuery->count();

        if ($browserSessionsCount > 0) {
            $this->info("Found {$browserSessionsCount} old browser sessions");
            if (!$dryRun) {
                $deleted = $browserSessionsQuery->delete();
                $totalDeleted += $deleted;
                $this->info("✅ Deleted {$deleted} browser sessions");
            }
        } else {
            $this->info("✅ No old browser sessions found");
        }

        // 4. Browser Events
        $this->info("\n📅 Cleaning Browser Events...");
        $browserEventsQuery = BrowserEvent::where('created_at', '<', $cutoffDate);
        $browserEventsCount = $browserEventsQuery->count();

        if ($browserEventsCount > 0) {
            $this->info("Found {$browserEventsCount} old browser events");
            if (!$dryRun) {
                $deleted = $browserEventsQuery->delete();
                $totalDeleted += $deleted;
                $this->info("✅ Deleted {$deleted} browser events");
            }
        } else {
            $this->info("✅ No old browser events found");
        }

        // Deep cleanup mode - more aggressive
        if ($deep && !$dryRun) {
            $this->info("\n🔥 Deep Cleanup Mode");

            // Keep only recent data for heavy tables
            $recentCutoff = Carbon::now()->subDays(3);

            $this->info("🗂️  Aggressive cleanup of URL Activities (keeping only 3 days)...");
            $aggressiveDeleted = UrlActivity::where('created_at', '<', $recentCutoff)->delete();
            $totalDeleted += $aggressiveDeleted;
            $this->info("✅ Deep cleaned {$aggressiveDeleted} additional URL activities");
        }

        // Summary
        $this->info("\n" . str_repeat('=', 50));
        $this->info("🎉 Database Cleanup Complete!");

        if (!$dryRun) {
            $this->info("📊 Total records deleted: {$totalDeleted}");
        }

        // Show remaining data counts
        $this->info("\n📈 Current data counts:");
        $this->table(
            ['Table', 'Records'],
            [
                ['URL Activities', number_format(UrlActivity::count())],
                ['Screenshots', number_format(Screenshot::count())],
                ['Browser Sessions', number_format(BrowserSession::count())],
                ['Browser Events', number_format(BrowserEvent::count())],
            ]
        );

        // Memory optimization tip
        if (UrlActivity::count() > 100000) {
            $this->warn("⚠️  URL Activities still high. Consider running deep cleanup:");
            $this->info("   php artisan tenjo:cleanup-database --days=3 --deep");
        }

        return Command::SUCCESS;
    }
}
