<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\JsonResponse;

class UpdateController extends Controller
{
    /**
     * Check for available updates
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function check(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'current_version' => 'required|string',
            'platform' => 'required|string'
        ]);

        $clientId = $request->client_id;
        $currentVersion = $request->current_version;
        $platform = $request->platform;
        $latestVersion = config('app.client_version', '2.0.0');

        Log::info('Update check', [
            'client_id' => $clientId,
            'current_version' => $currentVersion,
            'platform' => $platform
        ]);

        // Compare versions
        $updateAvailable = version_compare($latestVersion, $currentVersion, '>');

        if (!$updateAvailable) {
            return response()->json([
                'update_available' => false,
                'latest_version' => $latestVersion,
                'current_version' => $currentVersion,
                'message' => 'Client is up to date'
            ]);
        }

        // Determine update type based on version change
        $updateType = $this->determineUpdateType($currentVersion, $latestVersion);

        // Get update package info
        $updateInfo = $this->getUpdatePackageInfo($latestVersion, $platform);

        if (!$updateInfo['exists']) {
            Log::error('Update package not found', [
                'version' => $latestVersion,
                'platform' => $platform
            ]);
            
            return response()->json([
                'update_available' => false,
                'error' => 'Update package not available',
                'message' => 'Update will be available soon'
            ], 503);
        }

        return response()->json([
            'update_available' => true,
            'latest_version' => $latestVersion,
            'current_version' => $currentVersion,
            'update_type' => $updateType,
            'download_url' => url("/api/updates/download/{$latestVersion}"),
            'checksum' => $updateInfo['checksum'],
            'size_bytes' => $updateInfo['size'],
            'release_notes' => $this->getReleaseNotes($latestVersion),
            'required' => $this->isUpdateRequired($currentVersion, $latestVersion),
            'execution_window' => [
                'start' => '22:00',
                'end' => '06:00'
            ],
            'platform' => $platform
        ]);
    }

    /**
     * Download update package
     * 
     * @param string $version
     * @return \Symfony\Component\HttpFoundation\BinaryFileResponse
     */
    public function download(string $version)
    {
        $filename = "update-{$version}.tar.gz";
        $filepath = storage_path("app/updates/{$filename}");

        if (!file_exists($filepath)) {
            Log::error('Update package file not found', [
                'version' => $version,
                'filepath' => $filepath
            ]);
            
            abort(404, 'Update package not found');
        }

        Log::info('Update package downloaded', [
            'version' => $version,
            'size' => filesize($filepath),
            'ip' => request()->ip()
        ]);

        return response()->download($filepath, $filename, [
            'Content-Type' => 'application/gzip',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"'
        ]);
    }

    /**
     * Record update status from client
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function status(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'version' => 'required|string',
            'status' => 'required|in:downloading,applying,success,failed,rolled_back',
            'message' => 'nullable|string',
            'error' => 'nullable|string'
        ]);

        Log::info('Update status reported', [
            'client_id' => $request->client_id,
            'version' => $request->version,
            'status' => $request->status,
            'message' => $request->message,
            'error' => $request->error
        ]);

        // Store update log (optional - create UpdateLog model if needed)
        // UpdateLog::create([
        //     'client_id' => $request->client_id,
        //     'version' => $request->version,
        //     'status' => $request->status,
        //     'message' => $request->message,
        //     'error' => $request->error
        // ]);

        return response()->json([
            'success' => true,
            'message' => 'Status recorded'
        ]);
    }

    /**
     * Determine update type based on version change
     * 
     * @param string $currentVersion
     * @param string $latestVersion
     * @return string 'live' or 'full'
     */
    private function determineUpdateType(string $currentVersion, string $latestVersion): string
    {
        $current = explode('.', $currentVersion);
        $latest = explode('.', $latestVersion);

        $currentMajor = (int)($current[0] ?? 0);
        $currentMinor = (int)($current[1] ?? 0);
        $latestMajor = (int)($latest[0] ?? 0);
        $latestMinor = (int)($latest[1] ?? 0);

        // Major version change = full update required
        if ($latestMajor > $currentMajor) {
            return 'full';
        }

        // Minor version change = can use live update
        if ($latestMinor > $currentMinor) {
            return 'live';
        }

        // Patch version = live update
        return 'live';
    }

    /**
     * Check if update is required (forced)
     * 
     * @param string $currentVersion
     * @param string $latestVersion
     * @return bool
     */
    private function isUpdateRequired(string $currentVersion, string $latestVersion): bool
    {
        // Define critical versions that MUST update
        $criticalVersions = ['1.0.0', '1.0.1', '1.0.2'];
        
        if (in_array($currentVersion, $criticalVersions)) {
            return true;
        }

        // Major version behind = required
        $current = explode('.', $currentVersion);
        $latest = explode('.', $latestVersion);
        
        $currentMajor = (int)($current[0] ?? 0);
        $latestMajor = (int)($latest[0] ?? 0);
        
        return ($latestMajor - $currentMajor) > 1; // 2+ major versions behind
    }

    /**
     * Get update package information
     * 
     * @param string $version
     * @param string $platform
     * @return array
     */
    private function getUpdatePackageInfo(string $version, string $platform): array
    {
        $filename = "update-{$version}.tar.gz";
        $filepath = storage_path("app/updates/{$filename}");
        $checksumFile = storage_path("app/updates/update-{$version}.sha256");

        if (!file_exists($filepath)) {
            return [
                'exists' => false,
                'size' => 0,
                'checksum' => null
            ];
        }

        $checksum = null;
        if (file_exists($checksumFile)) {
            $checksumContent = trim(file_get_contents($checksumFile));
            // Extract just the hash (in case format is: "hash  filename")
            $checksum = explode(' ', $checksumContent)[0];
        }

        return [
            'exists' => true,
            'size' => filesize($filepath),
            'checksum' => $checksum
        ];
    }

    /**
     * Get release notes for version
     * 
     * @param string $version
     * @return string
     */
    private function getReleaseNotes(string $version): string
    {
        $notesFile = storage_path("app/updates/release-notes-{$version}.md");
        
        if (file_exists($notesFile)) {
            return file_get_contents($notesFile);
        }

        // Default release notes
        return "Version {$version}\n\nSee CHANGELOG.md for details.";
    }
}
