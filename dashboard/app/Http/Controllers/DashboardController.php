<?php

namespace App\Http\Controllers;

use App\Models\Client;
use App\Models\Screenshot;
use App\Models\BrowserSession;
use App\Models\UrlActivity;
use App\Exports\ClientSummaryExport;
use App\Exports\EnhancedClientSummaryExport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\View\View;
use Carbon\Carbon;
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index(): View
    {
        $clients = Client::with(['screenshots' => function($query) {
                $query->latest()->limit(1);
            }])
            ->orderBy('last_seen', 'desc')
            ->get();

        $stats = [
            'total_clients' => Client::count(),
            'active_clients' => Client::whereDate('last_seen', today())->count(),
            'online_clients' => $clients->filter(fn($client) => $client->isOnline())->count(),
            'total_screenshots' => Screenshot::whereDate('created_at', today())->count(),
        ];

        return view('dashboard.index', compact('clients', 'stats'));
    }

    public function clientDetails(string $clientId): View
    {
        $client = Client::where('client_id', $clientId)
            ->with([
                'screenshots' => function($query) {
                    $query->whereDate('captured_at', today())
                          ->orderBy('captured_at', 'desc');
                }
            ])
            ->firstOrFail();

        // Browser usage statistics from browser sessions
        $browserStats = BrowserSession::where('client_id', $clientId)
            ->whereDate('session_start', today())
            ->selectRaw('browser_name, SUM(total_duration) as total_duration, COUNT(*) as sessions')
            ->groupBy('browser_name')
            ->get();

        // Top URLs accessed today from URL activities
        $topUrls = UrlActivity::where('client_id', $clientId)
            ->whereDate('visit_start', today())
            ->selectRaw('url, SUM(duration) as total_duration, COUNT(*) as visits')
            ->groupBy('url')
            ->orderBy('total_duration', 'desc')
            ->limit(10)
            ->get();

        // Enhanced Browser Tracking Data
        $enhancedBrowserStats = BrowserSession::where('client_id', $clientId)
            ->whereDate('session_start', today())
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

        // Enhanced URL Activities
        $enhancedUrlStats = UrlActivity::where('client_id', $clientId)
            ->whereDate('visit_start', today())
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

        // Recent Enhanced URL Activities
        $recentUrlActivities = UrlActivity::where('client_id', $clientId)
            ->whereDate('visit_start', today())
            ->orderBy('visit_start', 'desc')
            ->limit(30)
            ->get();

        // Recent browser sessions with their latest URL activities
        $recentBrowserSessions = BrowserSession::where('client_id', $clientId)
            ->with(['urlActivities' => function ($query) {
                $query->orderBy('visit_start', 'desc')->limit(10);
            }])
            ->orderBy('session_start', 'desc')
            ->limit(10)
            ->get();

        // Daily Usage Summary
        $totalBrowsingTime = $enhancedBrowserStats->sum('total_time') ?: 0;
        $avgSessionTime = $enhancedBrowserStats->avg('avg_session_time') ?: 0;

        $dailyUsageSummary = [
            'total_browsing_time' => $totalBrowsingTime,
            'unique_browsers' => $enhancedBrowserStats->count(),
            'total_sessions' => $enhancedBrowserStats->sum('session_count') ?: 0,
            'unique_domains' => $enhancedUrlStats->count(),
            'total_url_visits' => $recentUrlActivities->count(),
            'avg_session_time' => $avgSessionTime
        ];

        return view('dashboard.client-details', compact(
            'client',
            'browserStats',
            'topUrls',
            'enhancedBrowserStats',
            'enhancedUrlStats',
            'recentBrowserSessions',
            'recentUrlActivities',
            'dailyUsageSummary'
        ));
    }

    public function clientLive(string $clientId): View
    {
        $client = Client::where('client_id', $clientId)->firstOrFail();

        return view('dashboard.client-live', compact('client'));
    }

    public function screenshots(Request $request): View
    {
        $query = Screenshot::with('client:client_id,hostname,custom_username,username');

        // Client filter
        if ($request->has('client_id') && $request->client_id) {
            $query->where('client_id', $request->client_id);
        }

        // Date filter
        if ($request->has('date')) {
            $query->whereDate('captured_at', $request->date);
        } else {
            $query->whereDate('captured_at', today());
        }

        $screenshots = $query->orderBy('captured_at', 'desc')->paginate(20);
        $clients = Client::orderBy('hostname')->get();

        return view('dashboard.screenshots', compact('screenshots', 'clients'));
    }

    public function exportActivities(Request $request)
    {
        $from = $request->get('from', today()->subDays(7)->toDateString());
        $to = $request->get('to', today()->toDateString());
        $clientId = $request->get('client_id');

        // Prepare CSV headers
        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="activity-export-' . date('Y-m-d') . '.csv"',
        ];

        // Create CSV content
        $callback = function() use ($from, $to, $clientId) {
            $file = fopen('php://output', 'w');

            // CSV headers
            fputcsv($file, ['Type', 'Client', 'Activity', 'Details', 'Date', 'Duration']);

            // Export browser sessions
            $browserSessionsQuery = BrowserSession::with('client')
                ->whereBetween('session_start', [$from . ' 00:00:00', $to . ' 23:59:59']);

            if ($clientId) {
                $browserSessionsQuery->where('client_id', $clientId);
            }

            foreach ($browserSessionsQuery->get() as $session) {
                fputcsv($file, [
                    'Browser Session',
                    $session->client ? $session->client->getDisplayUsername() . ' (' . $session->client->hostname . ')' : 'Unknown',
                    $session->browser_name . ' Session',
                    $session->window_count . ' windows, ' . $session->tab_count . ' tabs',
                    $session->session_start->format('Y-m-d H:i:s'),
                    gmdate('H:i:s', $session->total_duration)
                ]);
            }

            // Export URL activities
            $urlActivitiesQuery = UrlActivity::with('client')
                ->whereBetween('visit_start', [$from . ' 00:00:00', $to . ' 23:59:59']);

            if ($clientId) {
                $urlActivitiesQuery->where('client_id', $clientId);
            }

            foreach ($urlActivitiesQuery->get() as $activity) {
                fputcsv($file, [
                    'URL Activity',
                    $activity->client ? $activity->client->getDisplayUsername() . ' (' . $activity->client->hostname . ')' : 'Unknown',
                    $activity->title ?: 'Page Visit',
                    $activity->domain,
                    $activity->visit_start->format('Y-m-d H:i:s'),
                    gmdate('H:i:s', $activity->duration)
                ]);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    public function exportReport(Request $request)
    {
        // This would generate PDF report
        // For now, return JSON data that can be processed

        $from = $request->get('from', today()->subDays(7)->toDateString());
        $to = $request->get('to', today()->toDateString());

        $reportData = [
            'period' => ['from' => $from, 'to' => $to],
            'clients' => Client::count(),
            'screenshots' => Screenshot::whereBetween('captured_at', [$from, $to])->count(),
            'browser_sessions' => BrowserSession::whereBetween('session_start', [$from, $to])->count(),
            'urls_visited' => UrlActivity::whereBetween('visit_start', [$from, $to])->count(),
        ];

        return response()->json($reportData);
    }

    public function clientSummary(Request $request)
    {
        // Get date range filter with validation
        $customFrom = $request->get('from');
        $customTo = $request->get('to');

        // If from/to parameters are provided, use custom date range
        if ($customFrom && $customTo) {
            $dateRange = 'custom';
        } else {
            $dateRange = $request->get('date_range', 'today');
        }

        // Set date filters based on range
        switch ($dateRange) {
            case 'yesterday':
                $from = today()->subDay();
                $to = today()->subDay()->endOfDay();
                break;
            case 'week':
                $from = today()->startOfWeek();
                $to = today()->endOfWeek();
                break;
            case 'month':
                $from = today()->startOfMonth();
                $to = today()->endOfMonth();
                break;
            case 'last_7_days':
                $from = today()->subDays(6);
                $to = today()->endOfDay();
                break;
            case 'last_30_days':
                $from = today()->subDays(29);
                $to = today()->endOfDay();
                break;
            case 'custom':
                $from = $customFrom ? Carbon::parse($customFrom) : today();
                $to = $customTo ? Carbon::parse($customTo)->endOfDay() : today()->endOfDay();
                break;
            default: // today
                $from = today();
                $to = today()->endOfDay();
        }

        // Add date range info for view
        $dateRangeInfo = [
            'type' => $dateRange,
            'from' => $from->format('Y-m-d'),
            'to' => $to->format('Y-m-d'),
            'label' => $this->getDateRangeLabel($dateRange, $from, $to)
        ];

        // Get all clients and their stats in a more optimized way
        $clientsWithStats = Client::all()->keyBy('client_id');
        $clientsWithStats = Client::orderBy('hostname')->get()->keyBy('client_id');

        $screenshotStats = Screenshot::whereBetween('captured_at', [$from, $to])
            ->select('client_id', DB::raw('count(*) as count'))
            ->groupBy('client_id')
            ->get()->keyBy('client_id')
            ->pluck('count', 'client_id');

        $sessionStats = BrowserSession::whereBetween('session_start', [$from, $to])
            ->select('client_id', DB::raw('count(*) as count'))
            ->groupBy('client_id')
            ->get()->keyBy('client_id');

        $urlStats = UrlActivity::whereBetween('visit_start', [$from, $to])
            ->select(
                'client_id',
                DB::raw('count(*) as activities_count'),
                DB::raw('count(distinct url) as unique_urls_count'),
                DB::raw('sum(duration) as total_duration_sum')
            )
            ->groupBy('client_id')
            ->get()->keyBy('client_id');

        $topDomains = UrlActivity::whereBetween('visit_start', [$from, $to])
            ->select('client_id', 'domain', DB::raw('count(*) as count'))
            ->groupBy('client_id', 'domain')
            ->orderBy('count', 'desc')
            ->get()
            ->groupBy('client_id');

        $clients = $clientsWithStats->map(function($client) use ($screenshotStats, $sessionStats, $urlStats, $topDomains) {
            $clientTopDomains = $topDomains->get($client->client_id);
            $topDomainsString = $clientTopDomains
                ? $clientTopDomains->pluck('domain')->take(3)->implode(', ')
                : 'None';

            return [
                'client' => $client,
                'stats' => [
                    'screenshots' => $screenshotStats->get($client->client_id) ?? 0,
                    // FIX: Use nullsafe operator (?->) to prevent "property of non-object" error
                    'browser_sessions' => $sessionStats->get($client->client_id)?->count ?? 0,
                    'url_activities' => $urlStats->get($client->client_id)?->activities_count ?? 0,
                    'unique_urls' => $urlStats->get($client->client_id)?->unique_urls_count ?? 0,
                    'total_duration_minutes' => round(($urlStats->get($client->client_id)?->total_duration_sum ?? 0) / 60, 1),
                    'top_domains' => $topDomainsString,
                    'last_activity' => $client->last_seen ? Carbon::parse($client->last_seen)->diffForHumans() : 'Never',
                    'status' => $client->isOnline() ? 'Online' : 'Offline'
                ]
            ];
        });

        // Overall statistics
        $overallStats = [
            'total_clients' => $clients->count(),
            'online_clients' => $clients->where('stats.status', 'Online')->count(),
            'total_screenshots' => $screenshotStats->sum(),
            'total_browser_sessions' => $sessionStats->sum('count'),
            'total_url_activities' => $urlStats->sum('activities_count'),
            'total_unique_urls' => $urlStats->sum('unique_urls_count'),
            'total_duration_hours' => round($urlStats->sum('total_duration_sum') / 3600, 1),
        ];

        // Handle export requests
        if ($request->has('export')) {
            if ($request->export === 'excel') {
                // Use enhanced export with KPI metrics
                return Excel::download(
                    new EnhancedClientSummaryExport($clients, $overallStats, [
                        'from' => $from->format('Y-m-d'),
                        'to' => $to->format('Y-m-d')
                    ]),
                    'Employee_KPI_Report_' . now()->format('Y-m-d') . '.xlsx'
                );
            }

            if ($request->export === 'excel_simple') {
                // Keep simple export as fallback option
                return Excel::download(
                    new ClientSummaryExport($clients, $overallStats, [
                        'from' => $from->format('Y-m-d'),
                        'to' => $to->format('Y-m-d')
                    ]),
                    'client-summary-' . now()->format('Y-m-d') . '.xlsx'
                );
            }

            if ($request->export === 'pdf') {
                $pdf = Pdf::loadView('exports.client-summary-pdf', compact(
                    'clients',
                    'overallStats',
                    'from',
                    'to'
                ));

                return $pdf->download('client-summary-' . now()->format('Y-m-d') . '.pdf');
            }
        }

        return view('dashboard.client-summary', compact(
            'clients',
            'overallStats',
            'dateRange',
            'dateRangeInfo',
            'from',
            'to',
            'customFrom',
            'customTo'
        ));
    }

    /**
     * Helper method to generate date range label for display
     */
    private function getDateRangeLabel($type, $from, $to)
    {
        switch($type) {
            case 'yesterday':
                return 'Yesterday - ' . $from->format('M d, Y');
            case 'week':
                return 'This Week (' . $from->format('M d') . ' - ' . $to->format('M d, Y') . ')';
            case 'month':
                return $from->format('F Y');
            case 'last_7_days':
                return 'Last 7 Days (' . $from->format('M d') . ' - ' . $to->format('M d, Y') . ')';
            case 'last_30_days':
                return 'Last 30 Days (' . $from->format('M d') . ' - ' . $to->format('M d, Y') . ')';
            case 'custom':
                return 'Custom Range: ' . $from->format('M d, Y') . ' - ' . $to->format('M d, Y');
            default:
                return 'Today - ' . $from->format('M d, Y');
        }
    }

    /**
     * Get browser usage statistics for specific client and date range
     */
    public function browserUsageStats(Request $request, string $clientId)
    {
        $from = $request->get('from', today());
        $to = $request->get('to', today()->endOfDay());

        $browserUsage = BrowserSession::where('client_id', $clientId)
            ->whereBetween('session_start', [$from, $to])
            ->selectRaw('
                browser_name,
                COUNT(*) as session_count,
                SUM(total_duration) as total_duration,
                ROUND(AVG(total_duration), 2) as avg_duration,
                MAX(session_start) as last_used
            ')
            ->groupBy('browser_name')
            ->orderBy('total_duration', 'desc')
            ->get()
            ->map(function($item) {
                $item->total_duration_formatted = gmdate('H:i:s', $item->total_duration);
                $item->avg_duration_formatted = gmdate('H:i:s', $item->avg_duration);
                return $item;
            });

        return response()->json($browserUsage);
    }

    /**
     * Get URL access duration statistics for specific client and date range
     */
    public function urlDurationStats(Request $request, string $clientId)
    {
        $from = $request->get('from', today());
        $to = $request->get('to', today()->endOfDay());
        $groupBy = $request->get('group_by', 'url'); // 'url' or 'domain'

        $query = UrlActivity::where('client_id', $clientId)
            ->whereBetween('visit_start', [$from, $to]);

        if ($groupBy === 'domain') {
            $urlStats = $query->selectRaw('
                domain as item,
                COUNT(*) as visit_count,
                SUM(duration) as total_duration,
                ROUND(AVG(duration), 2) as avg_duration,
                MAX(visit_start) as last_visited
            ')
            ->groupBy('domain')
            ->orderBy('total_duration', 'desc')
            ->limit(20)
            ->get();
        } else {
            $urlStats = $query->selectRaw('
                url as item,
                domain,
                COUNT(*) as visit_count,
                SUM(duration) as total_duration,
                ROUND(AVG(duration), 2) as avg_duration,
                MAX(visit_start) as last_visited
            ')
            ->groupBy('url', 'domain')
            ->orderBy('total_duration', 'desc')
            ->limit(20)
            ->get();
        }

        $urlStats = $urlStats->map(function($item) {
            $item->total_duration_formatted = gmdate('H:i:s', $item->total_duration);
            $item->avg_duration_formatted = gmdate('H:i:s', $item->avg_duration);
            return $item;
        });

        return response()->json($urlStats);
    }
}
