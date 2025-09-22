@extends('layouts.app')

@section('title', 'Client Details - ' . $client->hostname)

@section('styles')
<style>
.browser-activity-table .table td {
    vertical-align: middle;
}

.browser-activity-table .badge {
    font-size: 0.75rem;
}

.page-details {
    max-width: 200px;
}

.page-title {
    color: #495057;
    font-weight: 500;
}

.page-url {
    color: #6c757d;
    font-size: 0.8rem;
    word-break: break-all;
}

.browser-icon {
    margin-right: 4px;
}

.time-info {
    font-family: 'Monaco', 'Menlo', monospace;
    font-size: 0.875rem;
}

.duration-info {
    font-family: 'Monaco', 'Menlo', monospace;
    font-size: 0.875rem;
    color: #28a745;
}

.event-badge-page_visit {
    background-color: #007bff !important;
}

.event-badge-browser_started {
    background-color: #28a745 !important;
}

.event-badge-browser_closed {
    background-color: #dc3545 !important;
}

.fa-chrome {
    color: #4285f4;
}

.fa-firefox {
    color: #ff7139;
}

.fa-safari {
    color: #006cff;
}

.fa-edge {
    color: #0078d4;
}
</style>
@endsection

@section('breadcrumb')
<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Dashboard</a></li>
        <li class="breadcrumb-item active">{{ $client->hostname }}</li>
    </ol>
</nav>
@endsection

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h1 class="h3 mb-0">{{ $client->hostname }}</h1>
        <p class="text-muted mb-0">Client Details & Activity</p>
    </div>
    <div>
        <a href="{{ route('client.live', $client->client_id) }}" class="btn btn-primary">
            <i class="fas fa-video"></i> Live View
        </a>
    </div>
</div>

<!-- Client Info -->
<div class="row mb-4">
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <h6 class="mb-0">Client Information</h6>
            </div>
            <div class="card-body">
                <dl class="row">
                    <dt class="col-sm-4">Hostname:</dt>
                    <dd class="col-sm-8">{{ $client->hostname }}</dd>

                    <dt class="col-sm-4">User:</dt>
                    <dd class="col-sm-8">{{ $client->getDisplayUsername() }}</dd>

                    <dt class="col-sm-4">IP Address:</dt>
                    <dd class="col-sm-8">{{ $client->ip_address }}</dd>

                    <dt class="col-sm-4">Status:</dt>
                    <dd class="col-sm-8">
                        <span class="badge {{ $client->isOnline() ? 'bg-success' : 'bg-secondary' }}">
                            {{ $client->isOnline() ? 'Online' : 'Offline' }}
                        </span>
                    </dd>

                    <dt class="col-sm-4">OS:</dt>
                    <dd class="col-sm-8">{{ $client->getOsDisplayName() }}</dd>

                    <dt class="col-sm-4">Last Seen:</dt>
                    <dd class="col-sm-8">{{ $client->last_seen ? $client->last_seen->diffForHumans() : 'Never' }}</dd>
                </dl>
            </div>
        </div>
    </div>

    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h6 class="mb-0">Today's Activity Summary</h6>
            </div>
            <div class="card-body">
                <div class="row text-center">
                    <div class="col-md-3">
                        <div class="border-end">
                            <h4 class="text-primary mb-0">{{ $client->screenshots->count() }}</h4>
                            <small class="text-muted">Screenshots</small>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="border-end">
                            <h4 class="text-success mb-0">{{ $browserStats->sum('sessions') ?: $enhancedBrowserStats->sum('session_count') }}</h4>
                            <small class="text-muted">Browser Sessions</small>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="border-end">
                            <h4 class="text-info mb-0">{{ $client->urlEvents->count() ?: $recentUrlActivities->count() }}</h4>
                            <small class="text-muted">URLs Visited</small>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <h4 class="text-warning mb-0">{{ $client->processEvents->count() }}</h4>
                        <small class="text-muted">Process Events</small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Browser Usage Stats -->
@if($browserStats->count() > 0)
<div class="card mb-4">
    <div class="card-header">
        <h6 class="mb-0">Browser Usage Today</h6>
    </div>
    <div class="card-body">
        <div class="row">
            <div class="col-md-8">
                <canvas id="browserChart" height="100"></canvas>
            </div>
            <div class="col-md-4">
                @foreach($browserStats as $browser)
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <div>
                        <strong>{{ $browser->browser_name }}</strong>
                        <br>
                        <small class="text-muted">{{ $browser->sessions }} sessions</small>
                    </div>
                    <div class="text-end">
                        <span class="badge bg-primary">{{ gmdate('H:i:s', $browser->total_duration) }}</span>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
    </div>
</div>
@endif

<!-- Screenshots -->
<div class="card mb-4">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h6 class="mb-0">Screenshots (Today)</h6>
        <a href="{{ route('screenshots', ['client_id' => $client->client_id]) }}" class="btn btn-sm btn-outline-primary">
            View All
        </a>
    </div>
    <div class="card-body">
        @if($client->screenshots->count() > 0)
            <div class="row">
                @foreach($client->screenshots->take(6) as $screenshot)
                <div class="col-md-2 mb-3">
                    <div class="position-relative">
                        <img src="{{ $screenshot->url }}"
                             class="img-fluid rounded screenshot-thumbnail"
                             style="width: 100%; height: 100px; object-fit: cover;"
                             data-bs-toggle="modal"
                             data-bs-target="#screenshotModal"
                             data-screenshot="{{ $screenshot->url }}"
                             data-time="{{ $screenshot->captured_at->format('H:i:s') }}">
                        <div class="position-absolute bottom-0 start-0 end-0 bg-dark bg-opacity-75 text-white text-center py-1">
                            <small>{{ $screenshot->captured_at->format('H:i') }}</small>
                        </div>
                    </div>
                </div>
                @endforeach
            </div>
        @else
            <p class="text-muted text-center">No screenshots available for today.</p>
        @endif
    </div>
</div>

<!-- Top URLs -->
@if($topUrls->count() > 0)
<div class="card mb-4">
    <div class="card-header">
        <h6 class="mb-0">Top URLs Visited Today</h6>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-sm">
                <thead>
                    <tr>
                        <th>URL</th>
                        <th>Visits</th>
                        <th>Total Time</th>
                        <th>Average Time</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($topUrls as $url)
                    <tr>
                        <td>
                            <div class="text-truncate" style="max-width: 300px;">
                                <a href="{{ $url->url }}" target="_blank" class="text-decoration-none">
                                    {{ $url->url }}
                                </a>
                            </div>
                        </td>
                        <td>{{ $url->visits }}</td>
                        <td>{{ gmdate('H:i:s', $url->total_duration) }}</td>
                        <td>{{ gmdate('H:i:s', $url->total_duration / $url->visits) }}</td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endif

<!-- Enhanced Browser & URL Activity Summary -->
@if(isset($enhancedBrowserStats) && $enhancedBrowserStats->count() > 0)
<div class="card mb-4">
    <div class="card-header">
        <h6 class="mb-0">Enhanced Browser Activity Summary</h6>
    </div>
    <div class="card-body">
        <!-- Daily Usage Overview -->
        <div class="row mb-4">
            <div class="col-md-12">
                <h6 class="text-muted mb-3">Today's Usage Overview</h6>
                <div class="row text-center">
                    <div class="col-md-2">
                        <div class="border-end">
                            <h5 class="text-primary mb-0">{{ gmdate('H:i:s', $dailyUsageSummary['total_browsing_time']) }}</h5>
                            <small class="text-muted">Total Browsing</small>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="border-end">
                            <h5 class="text-success mb-0">{{ $dailyUsageSummary['unique_browsers'] }}</h5>
                            <small class="text-muted">Browsers Used</small>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="border-end">
                            <h5 class="text-info mb-0">{{ $dailyUsageSummary['total_sessions'] }}</h5>
                            <small class="text-muted">Browser Sessions</small>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="border-end">
                            <h5 class="text-warning mb-0">{{ $dailyUsageSummary['unique_domains'] }}</h5>
                            <small class="text-muted">Unique Domains</small>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="border-end">
                            <h5 class="text-secondary mb-0">{{ $dailyUsageSummary['total_url_visits'] }}</h5>
                            <small class="text-muted">URL Visits</small>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <h5 class="text-dark mb-0">{{ gmdate('H:i:s', $dailyUsageSummary['avg_session_time']) }}</h5>
                        <small class="text-muted">Avg Session</small>
                    </div>
                </div>
            </div>
        </div>

        <!-- Browser Sessions Breakdown -->
        <div class="row">
            <div class="col-md-6">
                <h6 class="text-muted mb-3">Browser Sessions</h6>
                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>Browser</th>
                                <th>Sessions</th>
                                <th>Total Time</th>
                                <th>Avg Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($enhancedBrowserStats as $browser)
                            <tr>
                                <td>
                                    @if($browser->browser_name == 'Chrome')
                                        <i class="fab fa-chrome text-warning browser-icon"></i>
                                    @elseif($browser->browser_name == 'Firefox')
                                        <i class="fab fa-firefox text-danger browser-icon"></i>
                                    @elseif($browser->browser_name == 'Safari')
                                        <i class="fab fa-safari text-info browser-icon"></i>
                                    @elseif($browser->browser_name == 'Edge')
                                        <i class="fab fa-edge text-primary browser-icon"></i>
                                    @else
                                        <i class="fas fa-globe browser-icon"></i>
                                    @endif
                                    {{ $browser->browser_name }}
                                </td>
                                <td><span class="badge bg-info">{{ $browser->session_count }}</span></td>
                                <td class="duration-info">{{ gmdate('H:i:s', $browser->total_time) }}</td>
                                <td class="duration-info">{{ gmdate('H:i:s', $browser->avg_session_time) }}</td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Top Domains -->
            <div class="col-md-6">
                <h6 class="text-muted mb-3">Top Domains Visited</h6>
                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>Domain</th>
                                <th>Visits</th>
                                <th>Total Time</th>
                                <th>Avg Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($enhancedUrlStats->take(8) as $domain)
                            <tr>
                                <td>
                                    <div class="text-truncate" style="max-width: 150px;">
                                        <strong>{{ $domain->domain }}</strong>
                                    </div>
                                </td>
                                <td><span class="badge bg-primary">{{ $domain->visit_count }}</span></td>
                                <td class="duration-info">{{ gmdate('H:i:s', $domain->total_time) }}</td>
                                <td class="duration-info">{{ gmdate('H:i:s', $domain->avg_time) }}</td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endif

<!-- Recent URL Activities -->
@if(isset($recentUrlActivities) && $recentUrlActivities->count() > 0)
<div class="card mb-4">
    <div class="card-header">
        <h6 class="mb-0">Recent URL Activities (Real-time Tracking)</h6>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-sm table-striped">
                <thead>
                    <tr>
                        <th width="10%">Time</th>
                        <th width="15%">Browser</th>
                        <th width="35%">URL</th>
                        <th width="25%">Page Title</th>
                        <th width="10%">Duration</th>
                        <th width="5%">Status</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($recentUrlActivities->take(15) as $activity)
                    <tr>
                        <td class="time-info">{{ $activity->visit_start->format('H:i:s') }}</td>
                        <td>
                            @php
                                $browserSession = $activity->browserSession;
                                $browserName = $browserSession ? $browserSession->browser_name : 'Unknown';
                            @endphp
                            @if($browserName == 'Chrome')
                                <i class="fab fa-chrome text-warning browser-icon"></i>
                            @elseif($browserName == 'Firefox')
                                <i class="fab fa-firefox text-danger browser-icon"></i>
                            @elseif($browserName == 'Safari')
                                <i class="fab fa-safari text-info browser-icon"></i>
                            @elseif($browserName == 'Edge')
                                <i class="fab fa-edge text-primary browser-icon"></i>
                            @else
                                <i class="fas fa-globe browser-icon"></i>
                            @endif
                            <small>{{ $browserName }}</small>
                        </td>
                        <td>
                            <div class="text-truncate" style="max-width: 250px;">
                                <a href="{{ $activity->url }}" target="_blank" class="text-decoration-none" title="{{ $activity->url }}">
                                    {{ $activity->url }}
                                </a>
                            </div>
                        </td>
                        <td>
                            <div class="text-truncate" style="max-width: 200px;" title="{{ $activity->page_title }}">
                                {{ $activity->page_title ?: 'No title' }}
                            </div>
                        </td>
                        <td class="duration-info">
                            @if($activity->duration > 0)
                                {{ gmdate('H:i:s', $activity->duration) }}
                            @else
                                <span class="text-muted">-</span>
                            @endif
                        </td>
                        <td>
                            @if($activity->is_active)
                                <span class="badge bg-success">Active</span>
                            @else
                                <span class="badge bg-secondary">Closed</span>
                            @endif
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endif

<!-- Recent Browser Activity -->
<div class="card">
    <div class="card-header">
        <h6 class="mb-0">Recent Browser Activity</h6>
    </div>
    <div class="card-body">
        @if($client->browserEvents->count() > 0)
            <div class="table-responsive browser-activity-table">
                <table class="table table-sm table-striped table-hover">
                    <thead class="table-dark">
                        <tr>
                            <th width="12%">Time</th>
                            <th width="15%">Event Type</th>
                            <th width="18%">Browser</th>
                            <th width="12%">Duration</th>
                            <th width="43%">Page Details</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($client->browserEvents->take(10) as $event)
                        <tr>
                            <td class="time-info">
                                @if($event->start_time)
                                    {{ $event->start_time->format('H:i:s') }}
                                @elseif($event->created_at)
                                    {{ $event->created_at->format('H:i:s') }}
                                @else
                                    <span class="text-muted">-</span>
                                @endif
                            </td>
                            <td>
                                <span class="badge event-badge-{{ $event->event_type }} {{ $event->event_type === 'browser_started' ? 'bg-success' : ($event->event_type === 'browser_closed' ? 'bg-danger' : 'bg-info') }}">
                                    {{ ucfirst(str_replace('_', ' ', $event->event_type)) }}
                                </span>
                            </td>
                            <td>
                                @if($event->browser_name)
                                    <i class="fab fa-{{ strtolower($event->browser_name) === 'chrome' ? 'chrome' : (strtolower($event->browser_name) === 'firefox' ? 'firefox-browser' : (strtolower($event->browser_name) === 'safari' ? 'safari' : (strtolower($event->browser_name) === 'edge' ? 'edge' : 'globe'))) }} browser-icon"></i>
                                    {{ $event->browser_name }}
                                @else
                                    <i class="fas fa-globe browser-icon"></i>
                                    <span class="text-muted">Unknown Browser</span>
                                @endif
                            </td>
                            <td class="duration-info">
                                @if($event->duration)
                                    {{ $event->duration_human }}
                                @elseif($event->start_time && $event->end_time)
                                    {{ gmdate('H:i:s', $event->end_time->diffInSeconds($event->start_time)) }}
                                @else
                                    <span class="text-muted">-</span>
                                @endif
                            </td>
                            <td class="page-details">
                                @if($event->title || $event->url)
                                    <div class="d-flex flex-column">
                                        @if($event->title)
                                            <span class="page-title" title="{{ $event->title }}">{{ Str::limit($event->title, 35) }}</span>
                                        @endif
                                        @if($event->url)
                                            <small class="page-url" title="{{ $event->url }}">{{ Str::limit($event->url, 45) }}</small>
                                        @endif
                                    </div>
                                @else
                                    <span class="text-muted">-</span>
                                @endif
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @else
            <div class="text-center py-4">
                <i class="fas fa-globe fa-3x text-muted mb-3"></i>
                <h6 class="text-muted">No Browser Activity</h6>
                <p class="text-muted">No browser activity recorded for this client yet.</p>
            </div>
        @endif
    </div>
</div>

<!-- Screenshot Modal -->
<div class="modal fade" id="screenshotModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Screenshot</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body text-center">
                <img id="modalScreenshot" src="" class="img-fluid rounded">
                <p id="modalTime" class="mt-2 text-muted"></p>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
    // Initialize tooltips
    document.addEventListener('DOMContentLoaded', function() {
        // Initialize Bootstrap tooltips
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[title]'));
        var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl, {
                trigger: 'hover focus',
                delay: { show: 500, hide: 100 }
            });
        });

        // Auto-refresh dynamic content every 30 seconds
        setInterval(function() {
            const currentUrl = window.location.href;
            if (currentUrl.includes('/details')) {
                // Refresh dynamic content via AJAX
                fetch(currentUrl, {
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'text/html'
                    }
                })
                .then(response => {
                    if (!response.ok) {
                        throw new Error('Network response was not ok');
                    }
                    return response.text();
                })
                .then(html => {
                    // Extract and update dynamic sections
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(html, 'text/html');

                    // Update Client Information section (for username changes)
                    const newClientInfo = doc.querySelector('.card-body dl.row');
                    const currentClientInfo = document.querySelector('.card-body dl.row');
                    if (newClientInfo && currentClientInfo) {
                        currentClientInfo.innerHTML = newClientInfo.innerHTML;
                    }

                    // Update activity summary cards
                    const newSummaryCard = doc.querySelector('.card-body .row.text-center');
                    const currentSummaryCard = document.querySelector('.card-body .row.text-center');
                    if (newSummaryCard && currentSummaryCard) {
                        currentSummaryCard.innerHTML = newSummaryCard.innerHTML;
                    }                    // Update browser activity table if exists
                    const newTable = doc.querySelector('.browser-activity-table');
                    const currentTable = document.querySelector('.browser-activity-table');
                    if (newTable && currentTable) {
                        currentTable.innerHTML = newTable.innerHTML;
                    }

                    // Update enhanced browser stats if exists
                    const newEnhancedStats = doc.querySelector('.row.mb-4 .row.text-center');
                    const currentEnhancedStats = document.querySelector('.row.mb-4 .row.text-center');
                    if (newEnhancedStats && currentEnhancedStats && newEnhancedStats !== newSummaryCard) {
                        currentEnhancedStats.innerHTML = newEnhancedStats.innerHTML;
                    }

                    // Reinitialize tooltips for new content
                    const newTooltips = [].slice.call(document.querySelectorAll('[title]'));
                    newTooltips.map(function (el) {
                        // Dispose existing tooltip if any
                        const existingTooltip = bootstrap.Tooltip.getInstance(el);
                        if (existingTooltip) {
                            existingTooltip.dispose();
                        }
                        return new bootstrap.Tooltip(el, {
                            trigger: 'hover focus',
                            delay: { show: 500, hide: 100 }
                        });
                    });

                    console.log('Dynamic content refreshed successfully');
                })
                .catch(error => {
                    console.warn('Auto-refresh failed:', error);
                    // Optionally show user notification that auto-refresh failed
                });
            }
        }, 30000);
    });

    // Screenshot modal
    document.addEventListener('DOMContentLoaded', function() {
        const modal = document.getElementById('screenshotModal');
        if (modal) {
            modal.addEventListener('show.bs.modal', function(event) {
                const button = event.relatedTarget;
                const screenshot = button.getAttribute('data-screenshot');
                const time = button.getAttribute('data-time');

                document.getElementById('modalScreenshot').src = screenshot;
                document.getElementById('modalTime').textContent = 'Captured at: ' + time;
            });
        }
    });

    // Browser usage chart
    @if($browserStats->count() > 0)
    const ctx = document.getElementById('browserChart').getContext('2d');
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: [
                @foreach($browserStats as $browser)
                '{{ $browser->browser_name }}',
                @endforeach
            ],
            datasets: [{
                data: [
                    @foreach($browserStats as $browser)
                    {{ $browser->total_duration }},
                    @endforeach
                ],
                backgroundColor: [
                    '#FF6384',
                    '#36A2EB',
                    '#FFCE56',
                    '#4BC0C0',
                    '#9966FF',
                    '#FF9F40'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });
    @endif
</script>
@endsection
