<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\BrowserSession;
use App\Models\UrlActivity;
use App\Models\Client;
use App\Services\ActivityCategorizerService;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class BrowserTrackingController extends Controller
{
    /**
     * Store browser tracking data (sessions and URL activities)
     */
    public function storeBrowserTracking(Request $request)
    {
        try {
            $data = $request->all();
            $clientId = $data['client_id'] ?? $request->header('X-Client-ID');

            if (!$clientId) {
                return response()->json(['error' => 'Client ID required'], 400);
            }

            // Verify client exists
            $client = Client::where('client_id', $clientId)->first();
            if (!$client) {
                return response()->json(['error' => 'Client not found'], 404);
            }

            $processed = [
                'browser_sessions' => 0,
                'url_activities' => 0
            ];

            // Process browser sessions
            if (isset($data['browser_sessions']) && is_array($data['browser_sessions'])) {
                foreach ($data['browser_sessions'] as $sessionData) {
                    $this->processBrowserSession($clientId, $sessionData);
                    $processed['browser_sessions']++;
                }
            }

            // Process URL activities
            if (isset($data['url_activities']) && is_array($data['url_activities'])) {
                foreach ($data['url_activities'] as $urlData) {
                    $this->processUrlActivity($clientId, $urlData);
                    $processed['url_activities']++;
                }
            }

            return response()->json([
                'status' => 'success',
                'processed' => $processed,
                'timestamp' => now()->toISOString()
            ]);

        } catch (\Exception $e) {
            Log::error('Browser tracking error: ' . $e->getMessage());
            return response()->json(['error' => 'Processing failed'], 500);
        }
    }

    /**
     * Store individual browser session
     */
    public function storeBrowserSession(Request $request)
    {
        try {
            $data = $request->all();
            $clientId = $data['client_id'] ?? $request->header('X-Client-ID');

            if (!$clientId) {
                return response()->json(['error' => 'Client ID required'], 400);
            }

            $session = $this->processBrowserSession($clientId, $data);

            return response()->json([
                'status' => 'success',
                'session_id' => $session->id,
                'timestamp' => now()->toISOString()
            ]);

        } catch (\Exception $e) {
            Log::error('Browser session error: ' . $e->getMessage());
            return response()->json(['error' => 'Processing failed'], 500);
        }
    }

    /**
     * Store individual URL activity
     */
    public function storeUrlActivity(Request $request)
    {
        try {
            $data = $request->all();
            $clientId = $data['client_id'] ?? $request->header('X-Client-ID');

            if (!$clientId) {
                return response()->json(['error' => 'Client ID required'], 400);
            }

            $activity = $this->processUrlActivity($clientId, $data);

            return response()->json([
                'status' => 'success',
                'activity_id' => $activity->id,
                'timestamp' => now()->toISOString()
            ]);

        } catch (\Exception $e) {
            Log::error('URL activity error: ' . $e->getMessage());
            return response()->json(['error' => 'Processing failed'], 500);
        }
    }

    /**
     * Get browser activity summary for a client
     */
    public function getBrowserSummary(Request $request, $clientId)
    {
        try {
            $client = Client::where('client_id', $clientId)->first();
            if (!$client) {
                return response()->json(['error' => 'Client not found'], 404);
            }

            // Get date range (default: last 7 days)
            $startDate = $request->get('start_date', now()->subDays(7));
            $endDate = $request->get('end_date', now());

            // Browser sessions summary
            $browserSessions = BrowserSession::where('client_id', $clientId)
                ->whereBetween('session_start', [$startDate, $endDate])
                ->selectRaw('
                    browser_name,
                    COUNT(*) as session_count,
                    SUM(total_duration) as total_time,
                    AVG(total_duration) as avg_session_time,
                    MAX(session_start) as last_session
                ')
                ->groupBy('browser_name')
                ->orderBy('total_time', 'desc')
                ->get();

            // Top domains
            $topDomains = UrlActivity::where('client_id', $clientId)
                ->whereBetween('visit_start', [$startDate, $endDate])
                ->selectRaw('
                    domain,
                    COUNT(*) as visit_count,
                    SUM(duration) as total_time,
                    AVG(duration) as avg_time
                ')
                ->groupBy('domain')
                ->orderBy('total_time', 'desc')
                ->limit(20)
                ->get();

            // Recent URL activities
            $recentActivities = UrlActivity::where('client_id', $clientId)
                ->whereBetween('visit_start', [$startDate, $endDate])
                ->orderBy('visit_start', 'desc')
                ->limit(50)
                ->get();

            // Daily usage statistics
            $dailyStats = UrlActivity::where('client_id', $clientId)
                ->whereBetween('visit_start', [$startDate, $endDate])
                ->selectRaw('
                    DATE(visit_start) as date,
                    COUNT(*) as visits,
                    SUM(duration) as total_time,
                    COUNT(DISTINCT domain) as unique_domains
                ')
                ->groupBy('date')
                ->orderBy('date', 'desc')
                ->get();

            return response()->json([
                'client_id' => $clientId,
                'period' => [
                    'start' => $startDate,
                    'end' => $endDate
                ],
                'browser_sessions' => $browserSessions,
                'top_domains' => $topDomains,
                'recent_activities' => $recentActivities,
                'daily_stats' => $dailyStats,
                'totals' => [
                    'sessions' => $browserSessions->sum('session_count'),
                    'total_browsing_time' => $browserSessions->sum('total_time'),
                    'unique_domains' => $topDomains->count(),
                    'total_visits' => $recentActivities->count()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Browser summary error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to get summary'], 500);
        }
    }

    /**
     * Process browser session data
     */
    private function processBrowserSession($clientId, $data)
    {
        $sessionId = $data['session_id'] ?? null;
        $browserName = $data['browser_name'] ?? 'Unknown';

        // Check if session already exists
        $session = BrowserSession::where('client_id', $clientId)
            ->where('browser_name', $browserName)
            ->where('is_active', true)
            ->first();

        if (!$session) {
            // Create new session
            $session = BrowserSession::create([
                'client_id' => $clientId,
                'browser_name' => $browserName,
                'browser_version' => $data['browser_version'] ?? 'Unknown',
                'browser_executable_path' => $data['executable_path'] ?? null,
                'window_count' => $data['window_count'] ?? 0,
                'tab_count' => $data['tab_count'] ?? 0,
                'session_start' => isset($data['start_time']) ? Carbon::parse($data['start_time']) : now(),
                'is_active' => $data['is_active'] ?? true,
                'window_titles' => $data['window_titles'] ?? null
            ]);
        } else {
            // Update existing session
            $updateData = [
                'window_count' => $data['window_count'] ?? $session->window_count,
                'tab_count' => $data['tab_count'] ?? $session->tab_count,
                'window_titles' => $data['window_titles'] ?? $session->window_titles,
                'is_active' => $data['is_active'] ?? true
            ];

            // FIX #20: Handle session end time and total duration
            if (isset($data['end_time'])) {
                $updateData['session_end'] = Carbon::parse($data['end_time']);
            }
            if (isset($data['total_duration'])) {
                $updateData['total_duration'] = $data['total_duration'];
            }

            $session->update($updateData);
        }

        return $session;
    }

    /**
     * Process URL activity data
     */
    private function processUrlActivity($clientId, $data)
    {
        $url = $data['url'] ?? null;
        $browserName = $data['browser_name'] ?? 'Unknown';

        if (!$url) {
            throw new \Exception('URL is required for URL activity');
        }

        // Extract domain
        $domain = $this->extractDomain($url);

        // Categorize the activity
        $categorizer = new ActivityCategorizerService();
        $pageTitle = $data['title'] ?? null;
        $category = $categorizer->categorize($url, $domain, $pageTitle);

        // Find or create browser session
        $browserSession = BrowserSession::where('client_id', $clientId)
            ->where('browser_name', $browserName)
            ->where('is_active', true)
            ->first();

        if (!$browserSession) {
            // Create a basic browser session if none exists
            $browserSession = BrowserSession::create([
                'client_id' => $clientId,
                'browser_name' => $browserName,
                'browser_version' => 'Unknown',
                'session_start' => now(),
                'is_active' => true
            ]);
        }

        // Check if this URL activity already exists and is RECENTLY active (within last 60 seconds)
        // This prevents duplicate entries while still allowing multiple visits to same URL
        // IMPORTANT: Also check browser_session_id to distinguish same URL in different browsers
        $recentCutoff = Carbon::now()->subSeconds(60);
        $existingActivity = UrlActivity::where('client_id', $clientId)
            ->where('url', $url)
            ->where('browser_session_id', $browserSession->id)  // ✅ Distinguish by browser
            ->where('is_active', true)
            ->where('visit_start', '>=', $recentCutoff)  // Only consider recent activities
            ->orderBy('visit_start', 'desc')
            ->first();

        if ($existingActivity) {
            // Update existing recent activity (within last 60 seconds)
            $updateData = [
                'duration' => $data['duration'] ?? $existingActivity->duration,
                'page_title' => $data['title'] ?? $existingActivity->page_title,
                'scroll_depth' => $data['scroll_depth'] ?? $existingActivity->scroll_depth,
                'clicks' => $data['clicks'] ?? $existingActivity->clicks,
                'keystrokes' => $data['keystrokes'] ?? $existingActivity->keystrokes,
                'is_active' => $data['is_active'] ?? true,
                'activity_category' => $category
            ];

            // Set end time if activity is no longer active
            if (isset($data['is_active']) && !$data['is_active'] && isset($data['end_time'])) {
                $updateData['visit_end'] = Carbon::parse($data['end_time']);
            }

            $existingActivity->update($updateData);
            return $existingActivity;
        } else {
            // Create new activity
            $activity = UrlActivity::create([
                'client_id' => $clientId,
                'browser_session_id' => $browserSession->id,
                'url' => $url,
                'domain' => $domain,
                'page_title' => $data['title'] ?? null,
                'tab_id' => $data['tab_id'] ?? null,
                'visit_start' => isset($data['start_time']) ? Carbon::parse($data['start_time']) : now(),
                'visit_end' => isset($data['end_time']) ? Carbon::parse($data['end_time']) : null,
                'duration' => $data['duration'] ?? 0,
                'scroll_depth' => $data['scroll_depth'] ?? 0,
                'clicks' => $data['clicks'] ?? 0,
                'keystrokes' => $data['keystrokes'] ?? 0,
                'is_active' => $data['is_active'] ?? true,
                'referrer_url' => $data['referrer_url'] ?? null,
                'metadata' => $data['metadata'] ?? null,
                'activity_category' => $category
            ]);

            return $activity;
        }
    }

    /**
     * Extract domain from URL
     */
    private function extractDomain($url)
    {
        $parsed = parse_url($url);
        return $parsed['host'] ?? 'unknown';
    }
}
