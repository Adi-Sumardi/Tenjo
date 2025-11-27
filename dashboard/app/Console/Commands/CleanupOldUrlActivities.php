<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\UrlActivity;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class CleanupOldUrlActivities extends Command
{
    /**
     * The name and signature of the console command.
     * FIX BUG #80: Prevent database from growing unbounded
     *
     * @var string
     */
    protected $signature = 'cleanup:url-activities {--days=90 : Number of days to keep}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Delete URL activities older than specified days to keep database size manageable';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $days = (int) $this->option('days');
        $cutoffDate = Carbon::now()->subDays($days);
        
        $this->info("Cleaning up URL activities older than {$days} days (before {$cutoffDate->toDateString()})...");
        
        // Get count first
        $count = UrlActivity::where('visit_start', '<', $cutoffDate)->count();
        
        if ($count === 0) {
            $this->info('✓ No old URL activities to clean up');
            return 0;
        }
        
        $this->info("Found {$count} URL activities to delete");
        
        if (!$this->confirm("This will permanently delete {$count} records. Continue?")) {
            $this->warn('Cleanup cancelled');
            return 1;
        }
        
        // Delete in chunks to avoid memory issues
        $chunkSize = 1000;
        $deleted = 0;
        $bar = $this->output->createProgressBar($count);
        $bar->start();
        
        try {
            DB::transaction(function () use ($cutoffDate, $chunkSize, &$deleted, $bar) {
                do {
                    $chunkDeleted = UrlActivity::where('visit_start', '<', $cutoffDate)
                        ->limit($chunkSize)
                        ->delete();
                    
                    $deleted += $chunkDeleted;
                    $bar->advance($chunkDeleted);
                    
                    // Prevent infinite loop
                    if ($chunkDeleted === 0) {
                        break;
                    }
                    
                } while ($chunkDeleted > 0);
            });
            
            $bar->finish();
            $this->newLine(2);
            
            $this->info("✓ Successfully deleted {$deleted} URL activities");
            
            // Optimize table after deletion
            $this->info('Optimizing database table...');
            DB::statement('OPTIMIZE TABLE url_activities');
            $this->info('✓ Table optimized');
            
            Log::info("URL activities cleanup completed", [
                'deleted' => $deleted,
                'cutoff_date' => $cutoffDate->toDateTimeString(),
            ]);
            
            return 0;
            
        } catch (\Exception $e) {
            $bar->finish();
            $this->newLine(2);
            $this->error("Error during cleanup: {$e->getMessage()}");
            Log::error("URL activities cleanup failed", [
                'error' => $e->getMessage(),
                'deleted_so_far' => $deleted,
            ]);
            return 1;
        }
    }
}
