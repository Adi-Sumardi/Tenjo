<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

class ClearCacheData extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'tenjo:clear-cache {--all : Clear all cache data}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clear cache data to prevent sensitive data storage';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        if ($this->option('all')) {
            // Clear all cache
            Cache::flush();
            $this->info('✅ All cache data cleared successfully.');
        } else {
            // Clear only stream-related cache
            $cleared = 0;

            // Since we can't iterate cache keys directly with file driver,
            // we'll just flush all cache for safety
            Cache::flush();

            $this->info('✅ Cache cleared successfully.');
            $this->warn('⚠️  Note: File cache driver clears all cache. Use --all flag is redundant.');
        }

        // Clear compiled views
        $this->call('view:clear');

        // Clear config cache
        $this->call('config:clear');

        // Clear route cache
        $this->call('route:clear');

        $this->info('');
        $this->info('🎉 All cache and compiled files cleared!');

        return Command::SUCCESS;
    }
}
