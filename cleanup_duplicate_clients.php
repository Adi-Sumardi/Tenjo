#!/usr/bin/env php
<?php
/**
 * Cleanup Duplicate Client Registrations
 * 
 * This script removes duplicate client registrations, keeping only the most recent
 * active registration for each hostname.
 * 
 * Usage: php cleanup_duplicate_clients.php [--dry-run]
 */

// Autoload
require __DIR__ . '/dashboard/vendor/autoload.php';

// Bootstrap Laravel
$app = require_once __DIR__ . '/dashboard/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Client;
use Illuminate\Support\Facades\DB;

$dryRun = in_array('--dry-run', $argv);

echo "=== DUPLICATE CLIENT CLEANUP ===" . PHP_EOL;
echo PHP_EOL;

if ($dryRun) {
    echo "🔍 DRY RUN MODE - No changes will be made" . PHP_EOL;
    echo PHP_EOL;
}

// Get all hostnames with multiple registrations
$duplicateHostnames = Client::select('hostname', DB::raw('COUNT(*) as count'))
    ->groupBy('hostname')
    ->havingRaw('COUNT(*) > 1')
    ->orderByDesc(DB::raw('COUNT(*)'))
    ->get();

echo "Found " . $duplicateHostnames->count() . " hostnames with multiple registrations" . PHP_EOL;
echo PHP_EOL;

$totalDeleted = 0;
$totalKept = 0;

foreach ($duplicateHostnames as $host) {
    echo "Processing: {$host->hostname} ({$host->count} registrations)" . PHP_EOL;
    
    // Get all clients for this hostname, ordered by last_seen DESC (most recent first)
    $clients = Client::where('hostname', $host->hostname)
        ->orderBy('last_seen', 'desc')
        ->get();
    
    // Keep the first one (most recent), delete the rest
    $keepClient = $clients->first();
    $deleteClients = $clients->slice(1);
    
    echo "  ✅ KEEP: " . substr($keepClient->client_id, 0, 8) . "... (Last seen: " . $keepClient->last_seen->format('Y-m-d H:i') . ")" . PHP_EOL;
    $totalKept++;
    
    foreach ($deleteClients as $client) {
        echo "  ❌ DELETE: " . substr($client->client_id, 0, 8) . "... (Last seen: " . $client->last_seen->format('Y-m-d H:i') . ")";
        
        if (!$dryRun) {
            // Delete related records first (foreign key constraints)
            DB::table('screenshots')->where('client_id', $client->id)->delete();
            DB::table('url_events')->where('client_id', $client->id)->delete();
            DB::table('browser_events')->where('client_id', $client->id)->delete();
            DB::table('process_events')->where('client_id', $client->id)->delete();
            DB::table('browser_sessions')->where('client_id', $client->id)->delete();
            
            // Delete the client
            $client->delete();
            echo " ✓ DELETED" . PHP_EOL;
        } else {
            echo " (would delete)" . PHP_EOL;
        }
        
        $totalDeleted++;
    }
    
    echo PHP_EOL;
}

echo "=== SUMMARY ===" . PHP_EOL;
echo "Total clients kept: {$totalKept}" . PHP_EOL;
echo "Total clients deleted: {$totalDeleted}" . PHP_EOL;
echo PHP_EOL;

if ($dryRun) {
    echo "🔍 This was a DRY RUN - no changes were made" . PHP_EOL;
    echo "Run without --dry-run to actually delete duplicates" . PHP_EOL;
} else {
    echo "✅ Cleanup completed successfully!" . PHP_EOL;
    
    // Final count
    $finalCount = Client::count();
    echo "Final client count: {$finalCount}" . PHP_EOL;
}

echo PHP_EOL;
