<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Screenshot;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class CleanupOldScreenshots extends Command
{
    /**
     * The name and signature of the console command.
     * FIX BUG #79: Prevent disk space from filling up
     *
     * @var string
     */
    protected $signature = 'cleanup:screenshots {--days=30 : Number of days to keep}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Delete screenshots older than specified days to free up disk space';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $days = (int) $this->option('days');
        $cutoffDate = Carbon::now()->subDays($days);
        
        $this->info("Cleaning up screenshots older than {$days} days (before {$cutoffDate->toDateString()})...");
        
        // Get old screenshots
        $oldScreenshots = Screenshot::where('captured_at', '<', $cutoffDate)->get();
        $count = $oldScreenshots->count();
        
        if ($count === 0) {
            $this->info('✓ No old screenshots to clean up');
            return 0;
        }
        
        $this->info("Found {$count} screenshots to delete");
        $bar = $this->output->createProgressBar($count);
        $bar->start();
        
        $deletedFiles = 0;
        $deletedRecords = 0;
        $failedDeletes = 0;
        $freedSpace = 0;
        
        foreach ($oldScreenshots as $screenshot) {
            try {
                // Get file size before deleting
                if ($screenshot->file_path && Storage::disk('public')->exists($screenshot->file_path)) {
                    $fileSize = Storage::disk('public')->size($screenshot->file_path);
                    
                    // Delete file
                    Storage::disk('public')->delete($screenshot->file_path);
                    $deletedFiles++;
                    $freedSpace += $fileSize;
                }
                
                // Delete database record
                $screenshot->delete();
                $deletedRecords++;
                
            } catch (\Exception $e) {
                $failedDeletes++;
                Log::error("Failed to delete screenshot {$screenshot->id}: {$e->getMessage()}");
            }
            
            $bar->advance();
        }
        
        $bar->finish();
        $this->newLine(2);
        
        // Show results
        $this->info('Cleanup completed!');
        $this->table(
            ['Metric', 'Count/Size'],
            [
                ['Screenshots found', $count],
                ['Files deleted', $deletedFiles],
                ['Records deleted', $deletedRecords],
                ['Failed deletes', $failedDeletes],
                ['Disk space freed', $this->formatBytes($freedSpace)],
            ]
        );
        
        Log::info("Screenshot cleanup completed", [
            'total' => $count,
            'deleted_files' => $deletedFiles,
            'deleted_records' => $deletedRecords,
            'failed' => $failedDeletes,
            'freed_bytes' => $freedSpace,
        ]);
        
        return 0;
    }
    
    /**
     * Format bytes to human readable
     */
    private function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, 2) . ' ' . $units[$i];
    }
}
