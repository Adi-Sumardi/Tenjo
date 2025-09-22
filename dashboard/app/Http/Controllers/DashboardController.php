<?php

namespace App\Http\Controllers;

use App\Models\Client;
use App\Models\Screenshot;
use App\Models\BrowserEvent;
use App\Models\ProcessEvent;
use App\Models\UrlEvent;
use App\Models\BrowserSession;
use App\Models\UrlActivity;
use App\Exports\ClientSummaryExport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\View\View;
use Carbon\Carbon;
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;

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
                },
                'browserEvents' => function($query) {
                    $query->whereDate('created_at', today())
                          ->orderBy('start_time', 'desc');
                },
                'urlEvents' => function($query) {
                    $query->whereDate('created_at', today())
                          ->orderBy('start_time', 'desc');
                },
                'processEvents' => function($query) {
                    $query->whereDate('created_at', today())
                          ->orderBy('start_time', 'desc')
                          ->limit(50);
                }
            ])
            ->firstOrFail();

        // Browser usage statistics (fallback to enhanced data if basic events are empty)
        $browserStats = BrowserEvent::where('client_id', $client->id)
            ->whereDate('created_at', today())
            ->selectRaw('browser_name, SUM(duration) as total_duration, COUNT(*) as sessions')
            ->groupBy('browser_name')
            ->get();

        // If no basic browser events, use enhanced browser data
        if ($browserStats->isEmpty()) {
            $browserStats = BrowserSession::where('client_id', $clientId)
                ->whereDate('session_start', today())
                ->selectRaw('browser_name, SUM(total_duration) as total_duration, COUNT(*) as sessions')
                ->groupBy('browser_name')
                ->get();
        }

        // Top URLs accessed today (fallback to enhanced data if basic events are empty)
        $topUrls = UrlEvent::where('client_id', $client->id)
            ->whereDate('created_at', today())
            ->selectRaw('url, SUM(duration) as total_duration, COUNT(*) as visits')
            ->groupBy('url')
            ->orderBy('total_duration', 'desc')
            ->limit(10)
            ->get();

        // If no basic URL events, use enhanced URL data
        if ($topUrls->isEmpty()) {
            $topUrls = UrlActivity::where('client_id', $clientId)
                ->whereDate('visit_start', today())
                ->selectRaw('url, SUM(duration) as total_duration, COUNT(*) as visits')
                ->groupBy('url')
                ->orderBy('total_duration', 'desc')
                ->limit(10)
                ->get();
        }

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
            'recentUrlActivities',
            'dailyUsageSummary'
        ));
    }

    public function clientLive(string $clientId): View
    {
        $client = Client::where('client_id', $clientId)->firstOrFail();

        return view('dashboard.client-live', compact('client'));
    }

    public function historyActivity(Request $request): View
    {
        // Apply filters
        $from = $request->get('from', today()->subDays(7)->toDateString());
        $to = $request->get('to', today()->toDateString()); // Fixed: don't add extra day

        // Get all clients for dropdown
        $allClients = Client::orderBy('hostname')->get();

        // Build query for clients with their activities
        $query = Client::query();

        // Client filter - fixed to use UUID properly
        if ($request->has('client_id') && $request->client_id) {
            $query->where('client_id', $request->client_id);
        }

        // Load relationships with date filtering
        $clients = $query->with([
            // Basic events (fallback if they exist)
            'browserEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])
                  ->orderBy('created_at', 'desc')
                  ->limit(10);
            },
            'processEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])
                  ->orderBy('created_at', 'desc')
                  ->limit(10);
            },
            'urlEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])
                  ->orderBy('created_at', 'desc')
                  ->limit(10);
            },
            // Enhanced tracking data (primary source)
            'browserSessions' => function($q) use ($from, $to) {
                $q->whereBetween('session_start', [$from . ' 00:00:00', $to . ' 23:59:59'])
                  ->orderBy('session_start', 'desc')
                  ->limit(10);
            },
            'urlActivities' => function($q) use ($from, $to) {
                $q->whereBetween('visit_start', [$from . ' 00:00:00', $to . ' 23:59:59'])
                  ->orderBy('visit_start', 'desc')
                  ->limit(10);
            }
        ])->get();

        // Activity summary with enhanced data
        $activitySummary = [
            'browser_events' => BrowserEvent::whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])->count()
                              + BrowserSession::whereBetween('session_start', [$from . ' 00:00:00', $to . ' 23:59:59'])->count(),
            'process_events' => ProcessEvent::whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])->count(),
            'url_events' => UrlEvent::whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59'])->count()
                           + UrlActivity::whereBetween('visit_start', [$from . ' 00:00:00', $to . ' 23:59:59'])->count(),
            'screenshots' => Screenshot::whereBetween('captured_at', [$from . ' 00:00:00', $to . ' 23:59:59'])->count(),
        ];

        return view('dashboard.history-activity', compact('clients', 'allClients', 'activitySummary', 'from', 'to'));
    }

    public function screenshots(Request $request): View
    {
        $query = Screenshot::with('client');

        // Client filter
        if ($request->has('client_id')) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
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

    public function browserActivity(Request $request): View
    {
        $query = BrowserSession::with('client');

        // Client filter
        if ($request->has('client_id') && $request->client_id) {
            $query->where('client_id', $request->client_id);
        }

        // Date range filter
        $dateRange = $request->get('date_range', 'today');
        switch ($dateRange) {
            case 'yesterday':
                $query->whereDate('created_at', today()->subDay());
                break;
            case 'week':
                $query->whereBetween('created_at', [today()->startOfWeek(), today()->endOfWeek()]);
                break;
            case 'month':
                $query->whereMonth('created_at', today()->month)
                      ->whereYear('created_at', today()->year);
                break;
            default: // today
                $query->whereDate('created_at', today());
        }

        // Browser filter
        if ($request->has('browser') && $request->browser) {
            $query->where('browser_name', 'LIKE', '%' . ucfirst($request->browser) . '%');
        }

        // Get browser sessions (renamed from browserEvents)
        $browserEvents = $query->orderBy('created_at', 'desc')->paginate(20);

        // Generate statistics using BrowserSession
        $statsQuery = BrowserSession::query();

        // Apply same filters for stats
        if ($request->has('client_id') && $request->client_id) {
            $statsQuery->where('client_id', $request->client_id);
        }

        switch ($dateRange) {
            case 'yesterday':
                $statsQuery->whereDate('created_at', today()->subDay());
                break;
            case 'week':
                $statsQuery->whereBetween('created_at', [today()->startOfWeek(), today()->endOfWeek()]);
                break;
            case 'month':
                $statsQuery->whereMonth('created_at', today()->month)
                          ->whereYear('created_at', today()->year);
                break;
            default:
                $statsQuery->whereDate('created_at', today());
        }

        if ($request->has('browser') && $request->browser) {
            $statsQuery->where('browser_name', 'LIKE', '%' . ucfirst($request->browser) . '%');
        }

        // Calculate unique URLs from URL activities
        $uniqueUrls = UrlActivity::query()
            ->when($request->client_id, function($q) use ($request) {
                return $q->where('client_id', $request->client_id);
            })
            ->when($dateRange == 'today', function($q) {
                return $q->whereDate('created_at', today());
            })
            ->when($dateRange == 'yesterday', function($q) {
                return $q->whereDate('created_at', today()->subDay());
            })
            ->when($dateRange == 'week', function($q) {
                return $q->whereBetween('created_at', [today()->startOfWeek(), today()->endOfWeek()]);
            })
            ->when($dateRange == 'month', function($q) {
                return $q->whereMonth('created_at', today()->month)->whereYear('created_at', today()->year);
            })
            ->distinct('url')
            ->count('url');

        $stats = [
            'total_events' => $statsQuery->count(),
            'unique_urls' => $uniqueUrls,
            'avg_session_time' => round($statsQuery->avg('total_duration') / 60, 1), // Convert to minutes
            'active_clients' => $statsQuery->distinct('client_id')->count('client_id'),
        ];

        // Top domains from URL activities (enhanced)
        $topDomains = UrlActivity::query()
            ->when($request->client_id, function($q) use ($request) {
                return $q->where('client_id', $request->client_id);
            })
            ->when($dateRange == 'today', function($q) {
                return $q->whereDate('created_at', today());
            })
            ->when($dateRange == 'yesterday', function($q) {
                return $q->whereDate('created_at', today()->subDay());
            })
            ->when($dateRange == 'week', function($q) {
                return $q->whereBetween('created_at', [today()->startOfWeek(), today()->endOfWeek()]);
            })
            ->when($dateRange == 'month', function($q) {
                return $q->whereMonth('created_at', today()->month)->whereYear('created_at', today()->year);
            })
            ->whereNotNull('domain')
            ->selectRaw('domain, COUNT(*) as visits, SUM(duration) as total_time')
            ->groupBy('domain')
            ->orderByDesc('visits')
            ->take(5)
            ->get()
            ->map(function($item) {
                return [
                    'domain' => $item->domain,
                    'visits' => $item->visits,
                    'total_time' => round($item->total_time / 60, 1) // Convert to minutes
                ];
            });

        // Browser stats
        $browserStats = $statsQuery->whereNotNull('browser_name')
            ->get()
            ->groupBy('browser_name')
            ->map(function($group, $browser) use ($stats) {
                return [
                    'browser' => $browser,
                    'usage' => $stats['total_events'] > 0 ? round(($group->count() / $stats['total_events']) * 100, 1) : 0
                ];
            })
            ->sortByDesc('usage')
            ->take(5)
            ->values();

        $clients = Client::orderBy('hostname')->get();

        return view('dashboard.browser-activity', compact(
            'browserEvents',
            'clients',
            'stats',
            'topDomains',
            'browserStats'
        ));
    }

    public function urlActivity(Request $request): View
    {
        $query = UrlActivity::with('client');

        // Client filter
        if ($request->has('client_id') && $request->client_id) {
            $query->where('client_id', $request->client_id);
        }

        // Date range filter
        $dateRange = $request->get('date_range', 'today');
        switch ($dateRange) {
            case 'yesterday':
                $query->whereDate('visit_start', today()->subDay());
                break;
            case 'week':
                $query->whereBetween('visit_start', [today()->startOfWeek(), today()->endOfWeek()]);
                break;
            case 'month':
                $query->whereMonth('visit_start', today()->month)
                      ->whereYear('visit_start', today()->year);
                break;
            default:
                $query->whereDate('visit_start', today());
        }

        // URL search filter
        if ($request->has('search') && $request->search) {
            $query->where('url', 'LIKE', '%' . $request->search . '%')
                  ->orWhere('page_title', 'LIKE', '%' . $request->search . '%');
        }

        // Remove event_type filter since UrlActivity doesn't have this field

        $urlActivities = $query->orderBy('visit_start', 'desc')->paginate(20);
        $clients = Client::orderBy('hostname')->get();

        // Generate statistics
        $statsQuery = UrlActivity::query();

        // Apply same filters for stats
        if ($request->has('client_id') && $request->client_id) {
            $statsQuery->where('client_id', $request->client_id);
        }

        switch ($dateRange) {
            case 'yesterday':
                $statsQuery->whereDate('visit_start', today()->subDay());
                break;
            case 'week':
                $statsQuery->whereBetween('visit_start', [today()->startOfWeek(), today()->endOfWeek()]);
                break;
            case 'month':
                $statsQuery->whereMonth('visit_start', today()->month)
                          ->whereYear('visit_start', today()->year);
                break;
            default:
                $statsQuery->whereDate('visit_start', today());
        }

        if ($request->has('search') && $request->search) {
            $statsQuery->where('url', 'LIKE', '%' . $request->search . '%')
                      ->orWhere('page_title', 'LIKE', '%' . $request->search . '%');
        }

        // Calculate stats separately to avoid query conflicts
        $totalEvents = $statsQuery->count();

        // Create fresh query for unique URLs count
        $uniqueUrlsQuery = UrlActivity::whereDate('visit_start', today());
        if ($request->has('client_id') && $request->client_id) {
            $uniqueUrlsQuery->where('client_id', $request->client_id);
        }
        $uniqueUrls = $uniqueUrlsQuery->distinct('url')->count();

        // Create fresh query for average duration
        $avgDurationQuery = UrlActivity::whereDate('visit_start', today())
            ->whereNotNull('duration');
        if ($request->has('client_id') && $request->client_id) {
            $avgDurationQuery->where('client_id', $request->client_id);
        }
        $avgDuration = round($avgDurationQuery->avg('duration') / 60, 1) ?? 0;

        // Create fresh query for active clients
        $activeClientsQuery = UrlActivity::whereDate('visit_start', today());
        if ($request->has('client_id') && $request->client_id) {
            $activeClientsQuery->where('client_id', $request->client_id);
        }
        $activeClients = $activeClientsQuery->distinct('client_id')->count();

        $stats = [
            'total_events' => $totalEvents,
            'unique_urls' => $uniqueUrls,
            'avg_duration' => $avgDuration,
            'active_clients' => $activeClients,
        ];

        // Top URLs - optimized with database aggregation
        $topUrlsQuery = clone $statsQuery;
        $topUrls = $topUrlsQuery
            ->select('url', 'page_title')
            ->selectRaw('COUNT(*) as visits')
            ->selectRaw('ROUND(SUM(duration) / 60, 1) as total_duration')
            ->groupBy('url', 'page_title')
            ->orderByDesc('visits')
            ->limit(10)
            ->get()
            ->map(function($item) {
                return [
                    'url' => $item->url,
                    'title' => $item->page_title ?? 'No title',
                    'visits' => $item->visits,
                    'total_duration' => $item->total_duration ?? 0
                ];
            });

        // Top domains - optimized with PostgreSQL-compatible aggregation
        $topDomainsQuery = clone $statsQuery;
        $topDomains = $topDomainsQuery
            ->selectRaw('SPLIT_PART(SPLIT_PART(REPLACE(url, \'www.\', \'\'), \'://\', 2), \'/\', 1) as domain')
            ->selectRaw('COUNT(*) as visits')
            ->selectRaw('ROUND(SUM(duration) / 60, 1) as duration')
            ->groupBy('domain')
            ->orderByDesc('visits')
            ->limit(5)
            ->get()
            ->map(function($item) {
                return [
                    'domain' => $item->domain ?: 'unknown',
                    'visits' => $item->visits,
                    'duration' => $item->duration ?? 0
                ];
            });

        return view('dashboard.url-activity', compact(
            'urlActivities',
            'clients',
            'stats',
            'topUrls',
            'topDomains'
        ));
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

            // Export basic browser events (if any)
            $browserEventsQuery = BrowserEvent::with('client')
                ->whereBetween('created_at', [$from . ' 00:00:00', $to . ' 23:59:59']);

            if ($clientId) {
                $client = Client::where('client_id', $clientId)->first();
                if ($client) {
                    $browserEventsQuery->where('client_id', $client->id);
                }
            }

            foreach ($browserEventsQuery->get() as $event) {
                fputcsv($file, [
                    'Browser Event',
                    $event->client ? $event->client->getDisplayUsername() . ' (' . $event->client->hostname . ')' : 'Unknown',
                    $event->title ?: 'Page Visit',
                    $event->url ?: 'No URL',
                    $event->created_at->format('Y-m-d H:i:s'),
                    $event->duration ? gmdate('H:i:s', $event->duration) : 'N/A'
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
            'browser_sessions' => BrowserEvent::whereBetween('created_at', [$from, $to])->count(),
            'urls_visited' => UrlEvent::whereBetween('created_at', [$from, $to])->count(),
        ];

        return response()->json($reportData);
    }

    public function clientSummary(Request $request)
    {
        // Get date range filter
        $dateRange = $request->get('date_range', 'today');
        $customFrom = $request->get('from');
        $customTo = $request->get('to');

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
            case 'custom':
                $from = $customFrom ? Carbon::parse($customFrom) : today();
                $to = $customTo ? Carbon::parse($customTo)->endOfDay() : today()->endOfDay();
                break;
            default: // today
                $from = today();
                $to = today()->endOfDay();
        }

        // Get all clients with their statistics
        $clients = Client::get()->map(function($client) use ($from, $to) {
            // Screenshot statistics - use integer id for basic tracking
            $screenshots = Screenshot::where('client_id', $client->id)
                ->whereBetween('captured_at', [$from, $to])
                ->count();

            // Browser session statistics using enhanced tracking - use UUID client_id
            $browserSessions = BrowserSession::where('client_id', $client->client_id)
                ->whereBetween('created_at', [$from, $to])
                ->count();

            // URL activity statistics using enhanced tracking - use UUID client_id
            $urlActivities = UrlActivity::where('client_id', $client->client_id)
                ->whereBetween('visit_start', [$from, $to])
                ->count();

            $uniqueUrls = UrlActivity::where('client_id', $client->client_id)
                ->whereBetween('visit_start', [$from, $to])
                ->distinct('url')
                ->count();

            $totalDuration = UrlActivity::where('client_id', $client->client_id)
                ->whereBetween('visit_start', [$from, $to])
                ->whereNotNull('duration')
                ->sum('duration');

            // Top domains
            $topDomainsData = UrlActivity::where('client_id', $client->client_id)
                ->whereBetween('visit_start', [$from, $to])
                ->get()
                ->groupBy(function($item) {
                    return $item->domain ?: 'Unknown';
                })
                ->map(function($group) {
                    return [
                        'count' => $group->count(),
                        'duration' => $group->sum('duration')
                    ];
                })
                ->sortByDesc('count')
                ->take(3);

            $topDomains = $topDomainsData->isEmpty()
                ? 'None'
                : ($topDomainsData->keys()->filter(function($key) {
                    return !empty($key) && $key !== 'Unknown';
                })->implode(', ') ?: 'None');            return [
                'client' => $client,
                'stats' => [
                    'screenshots' => $screenshots,
                    'browser_sessions' => $browserSessions,
                    'url_activities' => $urlActivities,
                    'unique_urls' => $uniqueUrls,
                    'total_duration_minutes' => round($totalDuration / 60, 1),
                    'top_domains' => $topDomains,
                    'last_activity' => $client->last_seen ? Carbon::parse($client->last_seen)->diffForHumans() : 'Never',
                    'status' => $client->isOnline() ? 'Online' : 'Offline'
                ]
            ];
        });

        // Overall statistics
        $overallStats = [
            'total_clients' => $clients->count(),
            'online_clients' => $clients->where('stats.status', 'Online')->count(),
            'total_screenshots' => $clients->sum('stats.screenshots'),
            'total_browser_sessions' => $clients->sum('stats.browser_sessions'),
            'total_url_activities' => $clients->sum('stats.url_activities'),
            'total_unique_urls' => $clients->sum('stats.unique_urls'),
            'total_duration_hours' => round($clients->sum('stats.total_duration_minutes') / 60, 1),
        ];

        // Handle export requests
        if ($request->has('export')) {
            if ($request->export === 'excel') {
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
            'from',
            'to',
            'customFrom',
            'customTo'
        ));
    }
}
