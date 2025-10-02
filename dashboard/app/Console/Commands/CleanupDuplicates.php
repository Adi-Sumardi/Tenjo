<?php

namespace App\Console\Commands;

use App\Models\Client;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class CleanupDuplicates extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'cleanup:duplicates
                            {--dry-run : Run in dry-run mode without making changes}
                            {--force : Force the operation without confirmation}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Remove duplicate client registrations, keeping only the most recent active one per hostname';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $dryRun = $this->option('dry-run');
        $force = $this->option('force');

        $this->info('=== DUPLICATE CLIENT CLEANUP ===');
        $this->newLine();

        if ($dryRun) {
            $this->warn('🔍 DRY RUN MODE - No changes will be made');
            $this->newLine();
        }

        // Get all hostnames with multiple registrations
        $duplicateHostnames = Client::select('hostname', DB::raw('COUNT(*) as count'))
            ->groupBy('hostname')
            ->havingRaw('COUNT(*) > 1')
            ->orderByDesc(DB::raw('COUNT(*)'))
            ->get();

        $this->info("Found {$duplicateHostnames->count()} hostnames with multiple registrations");
        $this->newLine();

        if ($duplicateHostnames->count() === 0) {
            $this->info('✅ No duplicates found! Database is clean.');
            return 0;
        }

        // Show summary
        $totalClients = Client::count();
        $totalDuplicates = Client::whereIn('hostname', $duplicateHostnames->pluck('hostname'))
            ->count() - $duplicateHostnames->count();

        $this->table(
            ['Metric', 'Count'],
            [
                ['Total Clients', $totalClients],
                ['Unique Hostnames', $duplicateHostnames->count()],
                ['Duplicate Records', $totalDuplicates],
                ['After Cleanup', $totalClients - $totalDuplicates],
            ]
        );

        $this->newLine();

        // Confirm deletion
        if (!$dryRun && !$force) {
            if (!$this->confirm("Delete {$totalDuplicates} duplicate client records?")) {
                $this->info('Operation cancelled.');
                return 0;
            }
        }

        $totalDeleted = 0;
        $totalKept = 0;

        $progressBar = $this->output->createProgressBar($duplicateHostnames->count());
        $progressBar->start();

        foreach ($duplicateHostnames as $host) {
            // Get all clients for this hostname, ordered by last_seen DESC (most recent first)
            $clients = Client::where('hostname', $host->hostname)
                ->orderByDesc('last_seen')
                ->orderByDesc('is_active')
                ->orderByDesc('created_at')
                ->get();

            // Keep the first one (most recent)
            $keepClient = $clients->first();
            $totalKept++;

            // Delete the rest
            foreach ($clients->skip(1) as $client) {
                if (!$dryRun) {
                    $client->delete();
                }
                $totalDeleted++;
            }

            $progressBar->advance();
        }

        $progressBar->finish();
        $this->newLine(2);

        // Show results
        $this->info('=== CLEANUP RESULTS ===');
        $this->table(
            ['Action', 'Count'],
            [
                ['Clients Kept', $totalKept],
                ['Clients Deleted', $totalDeleted],
                ['Total Before', $totalClients],
                ['Total After', $totalClients - $totalDeleted],
            ]
        );

        if ($dryRun) {
            $this->warn('This was a DRY RUN. No changes were made.');
            $this->info('Run without --dry-run to actually delete duplicates.');
        } else {
            $this->info('✅ Cleanup complete!');
            $this->info("💾 Database size reduced significantly");
        }

        return 0;
    }
}
