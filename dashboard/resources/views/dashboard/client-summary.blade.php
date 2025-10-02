@extends('layouts.app')

@section('title', 'Client Summary - Tenjo Dashboard')

@section('styles')
<style>
.stats-card {
    border: none;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    transition: transform 0.2s;
}

.stats-card:hover {
    transform: translateY(-2px);
}

.stats-icon {
    width: 50px;
    height: 50px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.2rem;
    color: white;
}

.client-row {
    transition: background-color 0.2s;
}

.client-row:hover {
    background-color: #f8f9fa;
}

.status-badge {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
}

.export-buttons {
    gap: 0.5rem;
}

@media print {
    .no-print {
        display: none !important;
    }

    .table {
        font-size: 0.8rem;
    }
}
</style>
@endsection

@section('content')
<div class="container-fluid">
    <!-- Page Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h1 class="h3 mb-0">Client Summary</h1>
            <p class="text-muted mb-0">Comprehensive overview of all clients and their activities</p>
        </div>
        <div class="d-flex export-buttons no-print">
            <button type="button" class="btn btn-success btn-sm" onclick="exportToExcel()">
                <i class="fas fa-file-excel me-1"></i>Export Excel
            </button>
            <button type="button" class="btn btn-danger btn-sm" onclick="exportToPDF()">
                <i class="fas fa-file-pdf me-1"></i>Export PDF
            </button>
            <button type="button" class="btn btn-info btn-sm" onclick="window.print()">
                <i class="fas fa-print me-1"></i>Print
            </button>
        </div>
    </div>

    <!-- Overall Statistics -->
    <div class="row mb-4">
        <div class="col-md-2">
            <div class="card stats-card h-100">
                <div class="card-body text-center">
                    <div class="stats-icon bg-primary mx-auto mb-2">
                        <i class="fas fa-desktop"></i>
                    </div>
                    <h3 class="mb-1">{{ $overallStats['total_clients'] }}</h3>
                    <small class="text-muted">Total Clients</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stats-card h-100">
                <div class="card-body text-center">
                    <div class="stats-icon bg-success mx-auto mb-2">
                        <i class="fas fa-circle"></i>
                    </div>
                    <h3 class="mb-1">{{ $overallStats['online_clients'] }}</h3>
                    <small class="text-muted">Online Now</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stats-card h-100">
                <div class="card-body text-center">
                    <div class="stats-icon bg-info mx-auto mb-2">
                        <i class="fas fa-camera"></i>
                    </div>
                    <h3 class="mb-1">{{ number_format($overallStats['total_screenshots']) }}</h3>
                    <small class="text-muted">Screenshots</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stats-card h-100">
                <div class="card-body text-center">
                    <div class="stats-icon bg-warning mx-auto mb-2">
                        <i class="fas fa-window-maximize"></i>
                    </div>
                    <h3 class="mb-1">{{ number_format($overallStats['total_browser_sessions']) }}</h3>
                    <small class="text-muted">Browser Sessions</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stats-card h-100">
                <div class="card-body text-center">
                    <div class="stats-icon bg-purple mx-auto mb-2">
                        <i class="fas fa-link"></i>
                    </div>
                    <h3 class="mb-1">{{ number_format($overallStats['total_url_activities']) }}</h3>
                    <small class="text-muted">URL Activities</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card stats-card h-100">
                <div class="card-body text-center">
                    <div class="stats-icon bg-dark mx-auto mb-2">
                        <i class="fas fa-clock"></i>
                    </div>
                    <h3 class="mb-1">{{ $overallStats['total_duration_hours'] }}h</h3>
                    <small class="text-muted">Total Time</small>
                </div>
            </div>
        </div>
    </div>

    <!-- Filters -->
    <div class="card mb-4 no-print">
        <div class="card-body">
            <form method="GET" action="{{ route('dashboard.client-summary') }}">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">Date Range</label>
                        <select name="date_range" class="form-select" onchange="toggleCustomDate(this.value)">
                            <option value="today" {{ $dateRange == 'today' ? 'selected' : '' }}>Today</option>
                            <option value="yesterday" {{ $dateRange == 'yesterday' ? 'selected' : '' }}>Yesterday</option>
                            <option value="week" {{ $dateRange == 'week' ? 'selected' : '' }}>This Week</option>
                            <option value="month" {{ $dateRange == 'month' ? 'selected' : '' }}>This Month</option>
                            <option value="custom" {{ $dateRange == 'custom' ? 'selected' : '' }}>Custom Range</option>
                        </select>
                    </div>
                    <div class="col-md-3" id="custom-from" style="display: {{ $dateRange == 'custom' ? 'block' : 'none' }}">
                        <label class="form-label">From Date</label>
                        <input type="date" name="from" class="form-control" value="{{ $customFrom }}">
                    </div>
                    <div class="col-md-3" id="custom-to" style="display: {{ $dateRange == 'custom' ? 'block' : 'none' }}">
                        <label class="form-label">To Date</label>
                        <input type="date" name="to" class="form-control" value="{{ $customTo }}">
                    </div>
                    <div class="col-md-3 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-filter me-1"></i>Apply Filter
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Period Info -->
    <div class="alert alert-info mb-4">
        <i class="fas fa-info-circle me-2"></i>
        <strong>Report Period:</strong> {{ $from->format('M d, Y') }} to {{ $to->format('M d, Y') }}
    </div>

    <!-- Client Summary Table -->
    <div class="card">
        <div class="card-header">
            <h5 class="mb-0">
                <i class="fas fa-table me-2"></i>Client Details Summary
            </h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-dark">
                        <tr>
                            <th>Client</th>
                            <th>Status</th>
                            <th>Screenshots</th>
                            <th>Browser Sessions</th>
                            <th>URL Activities</th>
                            <th>Unique URLs</th>
                            <th>Time Active</th>
                            <th>Top Domains</th>
                            <th>Last Activity</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($clients as $clientData)
                            <tr class="client-row">
                                <td>
                                    <div class="d-flex align-items-center">
                                        <div class="me-3">
                                            <div class="rounded-circle bg-primary text-white d-flex align-items-center justify-content-center"
                                                 style="width: 40px; height: 40px;">
                                                <i class="fas fa-desktop"></i>
                                            </div>
                                        </div>
                                        <div>
                                            <div class="fw-bold">{{ $clientData['client']->getDisplayUsername() }}</div>
                                            <small class="text-muted">{{ $clientData['client']->hostname }}</small>
                                            <br>
                                            <small class="text-muted">{{ is_array($clientData['client']->os_info) ? implode(', ', $clientData['client']->os_info) : $clientData['client']->os_info }}</small>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <span class="badge status-badge {{ $clientData['stats']['status'] == 'Online' ? 'bg-success' : 'bg-secondary' }}">
                                        <i class="fas fa-circle me-1" style="font-size: 0.6rem;"></i>
                                        {{ $clientData['stats']['status'] }}
                                    </span>
                                </td>
                                <td>
                                    <a href="#" class="text-decoration-none" onclick="showScreenshotsModal('{{ $clientData['client']->client_id }}', '{{ $clientData['client']->getDisplayUsername() }}', event)">
                                        <span class="badge bg-info">{{ number_format($clientData['stats']['screenshots']) }}</span>
                                    </a>
                                </td>
                                <td>
                                    <a href="#" class="text-decoration-none" onclick="showBrowserSessionsModal('{{ $clientData['client']->client_id }}', '{{ $clientData['client']->getDisplayUsername() }}', event)">
                                        <span class="badge bg-warning">{{ number_format($clientData['stats']['browser_sessions']) }}</span>
                                    </a>
                                </td>
                                <td>
                                    <a href="#" class="text-decoration-none" onclick="showUrlActivitiesModal('{{ $clientData['client']->client_id }}', '{{ $clientData['client']->getDisplayUsername() }}', event)">
                                        <span class="badge bg-purple">{{ number_format($clientData['stats']['url_activities']) }}</span>
                                    </a>
                                </td>
                                <td>
                                    <a href="#" class="text-decoration-none" onclick="showUniqueUrlsModal('{{ $clientData['client']->client_id }}', '{{ $clientData['client']->getDisplayUsername() }}', event)">
                                        <span class="badge bg-primary">{{ number_format($clientData['stats']['unique_urls']) }}</span>
                                    </a>
                                </td>
                                <td>
                                    <span class="text-muted">{{ $clientData['stats']['total_duration_minutes'] }}m</span>
                                </td>
                                <td>
                                    <small class="text-muted">{{ Str::limit(is_string($clientData['stats']['top_domains']) ? $clientData['stats']['top_domains'] : 'None', 30) }}</small>
                                </td>
                                <td>
                                    <small class="text-muted">{{ $clientData['stats']['last_activity'] }}</small>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="9" class="text-center py-4">
                                    <div class="text-muted">
                                        <i class="fas fa-inbox fa-2x mb-2"></i>
                                        <p>No clients found for the selected period.</p>
                                    </div>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Summary Footer -->
    <div class="mt-4 text-center text-muted">
        <small>
            Report generated on {{ now()->format('M d, Y \a\t H:i:s') }} |
            Total {{ $clients->count() }} clients analyzed
        </small>
    </div>
</div>
@endsection

@section('scripts')
<script>
function toggleCustomDate(value) {
    const customFrom = document.getElementById('custom-from');
    const customTo = document.getElementById('custom-to');

    if (value === 'custom') {
        customFrom.style.display = 'block';
        customTo.style.display = 'block';
    } else {
        customFrom.style.display = 'none';
        customTo.style.display = 'none';
    }
}

function exportToExcel() {
    const params = new URLSearchParams(window.location.search);
    params.set('export', 'excel');
    window.location.href = '{{ route("dashboard.client-summary") }}?' + params.toString();
}

function exportToPDF() {
    const params = new URLSearchParams(window.location.search);
    params.set('export', 'pdf');
    window.location.href = '{{ route("dashboard.client-summary") }}?' + params.toString();
}

// Add custom purple color for badges
const style = document.createElement('style');
style.textContent = `
    .bg-purple {
        background-color: #6f42c1 !important;
    }
    .badge {
        cursor: pointer;
    }
    .badge:hover {
        opacity: 0.8;
    }
`;
document.head.appendChild(style);

// Modal functions
function showScreenshotsModal(clientId, username, event) {
    event.preventDefault();

    // Show loading modal
    const modalHtml = `
        <div class="modal fade" id="screenshotsModal" tabindex="-1">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-camera me-2"></i>Screenshots - ${username}
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="text-center py-5">
                            <div class="spinner-border text-primary" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                            <p class="mt-3 text-muted">Loading screenshots...</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;

    // Remove existing modal
    document.getElementById('screenshotsModal')?.remove();

    // Add modal to DOM
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    const modal = new bootstrap.Modal(document.getElementById('screenshotsModal'));
    modal.show();

    // Fetch data
    const params = new URLSearchParams(window.location.search);
    const from = params.get('from') || '{{ $from->format("Y-m-d") }}';
    const to = params.get('to') || '{{ $to->format("Y-m-d") }}';

    loadScreenshotsPage(clientId, from, to, 1);
}

function loadScreenshotsPage(clientId, from, to, page = 1) {
    fetch(`/api/screenshots?client_id=${clientId}&from=${from}&to=${to}&per_page=20&page=${page}`)
        .then(response => response.json())
        .then(data => {
            const screenshots = data.screenshots?.data || data.data || [];
            const pagination = data.screenshots || data;
            let content = '';

            if (screenshots.length === 0 && page === 1) {
                content = '<div class="alert alert-info">No screenshots found in this period.</div>';
            } else {
                content = `
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Preview</th>
                                    <th>Filename</th>
                                    <th>Resolution</th>
                                    <th>File Size</th>
                                    <th>Captured At</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                `;

                screenshots.forEach(screenshot => {
                    const imageUrl = screenshot.file_path ? '/storage/' + screenshot.file_path : '';
                    const fileSize = screenshot.file_size ? (screenshot.file_size / 1024).toFixed(0) + ' KB' : 'N/A';
                    const capturedAt = new Date(screenshot.captured_at || screenshot.created_at).toLocaleString();

                    content += `
                        <tr>
                            <td>
                                ${imageUrl ? `<img src="${imageUrl}" alt="Screenshot" style="width: 80px; height: 50px; object-fit: cover; cursor: pointer;" onclick="window.open('${imageUrl}', '_blank')">` : 'N/A'}
                            </td>
                            <td><small>${screenshot.filename || 'N/A'}</small></td>
                            <td><small>${screenshot.resolution || 'N/A'}</small></td>
                            <td><small>${fileSize}</small></td>
                            <td><small>${capturedAt}</small></td>
                            <td>
                                ${imageUrl ? `<a href="${imageUrl}" target="_blank" class="btn btn-sm btn-outline-primary"><i class="fas fa-eye"></i></a>` : ''}
                            </td>
                        </tr>
                    `;
                });

                content += `
                            </tbody>
                        </table>
                    </div>
                    <div class="d-flex justify-content-between align-items-center mt-3">
                        <div>
                            <strong>Total Screenshots:</strong> ${pagination.total || screenshots.length}
                            <span class="text-muted ms-2">(Showing ${pagination.from || 1} to ${pagination.to || screenshots.length})</span>
                        </div>
                        <nav>
                            <ul class="pagination pagination-sm mb-0">
                `;

                // Pagination buttons
                if (pagination.prev_page_url) {
                    content += `<li class="page-item"><a class="page-link" href="#" onclick="loadScreenshotsPage('${clientId}', '${from}', '${to}', ${page - 1}); return false;">Previous</a></li>`;
                }

                // Page numbers
                const currentPage = pagination.current_page || page;
                const lastPage = pagination.last_page || 1;
                const startPage = Math.max(1, currentPage - 2);
                const endPage = Math.min(lastPage, currentPage + 2);

                for (let i = startPage; i <= endPage; i++) {
                    const activeClass = i === currentPage ? 'active' : '';
                    content += `<li class="page-item ${activeClass}"><a class="page-link" href="#" onclick="loadScreenshotsPage('${clientId}', '${from}', '${to}', ${i}); return false;">${i}</a></li>`;
                }

                if (pagination.next_page_url) {
                    content += `<li class="page-item"><a class="page-link" href="#" onclick="loadScreenshotsPage('${clientId}', '${from}', '${to}', ${page + 1}); return false;">Next</a></li>`;
                }

                content += `
                            </ul>
                        </nav>
                    </div>
                `;
            }

            document.querySelector('#screenshotsModal .modal-body').innerHTML = content;
        })
        .catch(error => {
            console.error('Error loading screenshots:', error);
            document.querySelector('#screenshotsModal .modal-body').innerHTML =
                '<div class="alert alert-danger">Failed to load screenshots data.</div>';
        });
}

function showBrowserSessionsModal(clientId, username, event) {
    event.preventDefault();

    const modalHtml = `
        <div class="modal fade" id="browserSessionsModal" tabindex="-1">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-browser me-2"></i>Browser Sessions - ${username}
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="text-center py-5">
                            <div class="spinner-border text-warning" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                            <p class="mt-3 text-muted">Loading browser sessions...</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;

    document.getElementById('browserSessionsModal')?.remove();
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    const modal = new bootstrap.Modal(document.getElementById('browserSessionsModal'));
    modal.show();

    const params = new URLSearchParams(window.location.search);
    const from = params.get('from') || '{{ $from->format("Y-m-d") }}';
    const to = params.get('to') || '{{ $to->format("Y-m-d") }}';

    fetch(`/api/browser-events?client_id=${clientId}&from=${from}&to=${to}`)
        .then(response => response.json())
        .then(data => {
            const sessions = data.data || [];
            let content = '';

            if (sessions.length === 0) {
                content = '<div class="alert alert-info">No browser sessions found in this period.</div>';
            } else {
                content = `
                    <div class="table-responsive">
                        <table class="table table-hover table-sm">
                            <thead>
                                <tr>
                                    <th>Browser</th>
                                    <th>Event Type</th>
                                    <th>Timestamp</th>
                                    <th>Details</th>
                                </tr>
                            </thead>
                            <tbody>
                `;

                sessions.forEach(session => {
                    const timestamp = new Date(session.created_at).toLocaleString();
                    const browser = session.browser_name || 'Unknown';
                    const eventType = session.event_type || 'N/A';

                    content += `
                        <tr>
                            <td><i class="fab fa-${browser.toLowerCase()} me-1"></i>${browser}</td>
                            <td><span class="badge bg-secondary">${eventType}</span></td>
                            <td><small>${timestamp}</small></td>
                            <td><small>${session.url ? session.url.substring(0, 50) + '...' : 'N/A'}</small></td>
                        </tr>
                    `;
                });

                content += `
                            </tbody>
                        </table>
                    </div>
                    <div class="mt-3">
                        <strong>Total Sessions:</strong> ${sessions.length}
                    </div>
                `;
            }

            document.querySelector('#browserSessionsModal .modal-body').innerHTML = content;
        })
        .catch(error => {
            console.error('Error loading browser sessions:', error);
            document.querySelector('#browserSessionsModal .modal-body').innerHTML =
                '<div class="alert alert-danger">Failed to load browser sessions data.</div>';
        });
}

function showUrlActivitiesModal(clientId, username, event) {
    event.preventDefault();

    const modalHtml = `
        <div class="modal fade" id="urlActivitiesModal" tabindex="-1">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-link me-2"></i>URL Activities - ${username}
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="text-center py-5">
                            <div class="spinner-border text-purple" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                            <p class="mt-3 text-muted">Loading URL activities...</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;

    document.getElementById('urlActivitiesModal')?.remove();
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    const modal = new bootstrap.Modal(document.getElementById('urlActivitiesModal'));
    modal.show();

    const params = new URLSearchParams(window.location.search);
    const from = params.get('from') || '{{ $from->format("Y-m-d") }}';
    const to = params.get('to') || '{{ $to->format("Y-m-d") }}';

    fetch(`/api/url-events?client_id=${clientId}&from=${from}&to=${to}`)
        .then(response => response.json())
        .then(data => {
            const activities = data.data || [];
            let content = '';

            if (activities.length === 0) {
                content = '<div class="alert alert-info">No URL activities found in this period.</div>';
            } else {
                content = `
                    <div class="table-responsive">
                        <table class="table table-hover table-sm">
                            <thead>
                                <tr>
                                    <th style="width: 50%">URL</th>
                                    <th>Title</th>
                                    <th>Visit Count</th>
                                    <th>Duration</th>
                                    <th>Last Visit</th>
                                </tr>
                            </thead>
                            <tbody>
                `;

                activities.forEach(activity => {
                    const lastVisit = new Date(activity.created_at).toLocaleString();
                    const url = activity.url || 'N/A';
                    const title = activity.title || 'No title';
                    const duration = activity.duration ? Math.round(activity.duration / 60) + ' min' : 'N/A';

                    content += `
                        <tr>
                            <td><small><a href="${url}" target="_blank" class="text-decoration-none">${url.substring(0, 60)}${url.length > 60 ? '...' : ''}</a></small></td>
                            <td><small>${title.substring(0, 30)}${title.length > 30 ? '...' : ''}</small></td>
                            <td><span class="badge bg-info">${activity.visit_count || 1}</span></td>
                            <td><small>${duration}</small></td>
                            <td><small>${lastVisit}</small></td>
                        </tr>
                    `;
                });

                content += `
                            </tbody>
                        </table>
                    </div>
                    <div class="mt-3">
                        <strong>Total Activities:</strong> ${activities.length}
                    </div>
                `;
            }

            document.querySelector('#urlActivitiesModal .modal-body').innerHTML = content;
        })
        .catch(error => {
            console.error('Error loading URL activities:', error);
            document.querySelector('#urlActivitiesModal .modal-body').innerHTML =
                '<div class="alert alert-danger">Failed to load URL activities data.</div>';
        });
}

function showUniqueUrlsModal(clientId, username, event) {
    event.preventDefault();

    const modalHtml = `
        <div class="modal fade" id="uniqueUrlsModal" tabindex="-1">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-list me-2"></i>Unique URLs - ${username}
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="text-center py-5">
                            <div class="spinner-border text-primary" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                            <p class="mt-3 text-muted">Loading unique URLs...</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;

    document.getElementById('uniqueUrlsModal')?.remove();
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    const modal = new bootstrap.Modal(document.getElementById('uniqueUrlsModal'));
    modal.show();

    const params = new URLSearchParams(window.location.search);
    const from = params.get('from') || '{{ $from->format("Y-m-d") }}';
    const to = params.get('to') || '{{ $to->format("Y-m-d") }}';

    fetch(`/api/url-events?client_id=${clientId}&from=${from}&to=${to}`)
        .then(response => response.json())
        .then(data => {
            const urlEvents = data.data || [];

            // Get unique URLs
            const uniqueUrls = {};
            urlEvents.forEach(event => {
                const url = event.url;
                if (url) {
                    if (!uniqueUrls[url]) {
                        uniqueUrls[url] = {
                            url: url,
                            title: event.title || 'No title',
                            count: 0,
                            totalDuration: 0,
                            lastVisit: event.created_at
                        };
                    }
                    uniqueUrls[url].count++;
                    uniqueUrls[url].totalDuration += event.duration || 0;
                    if (new Date(event.created_at) > new Date(uniqueUrls[url].lastVisit)) {
                        uniqueUrls[url].lastVisit = event.created_at;
                    }
                }
            });

            const uniqueUrlsArray = Object.values(uniqueUrls).sort((a, b) => b.count - a.count);
            let content = '';

            if (uniqueUrlsArray.length === 0) {
                content = '<div class="alert alert-info">No unique URLs found in this period.</div>';
            } else {
                content = `
                    <div class="table-responsive">
                        <table class="table table-hover table-sm">
                            <thead>
                                <tr>
                                    <th style="width: 50%">URL</th>
                                    <th>Title</th>
                                    <th>Visits</th>
                                    <th>Total Duration</th>
                                    <th>Last Visit</th>
                                </tr>
                            </thead>
                            <tbody>
                `;

                uniqueUrlsArray.forEach(urlData => {
                    const lastVisit = new Date(urlData.lastVisit).toLocaleString();
                    const totalDuration = Math.round(urlData.totalDuration / 60) + ' min';

                    content += `
                        <tr>
                            <td><small><a href="${urlData.url}" target="_blank" class="text-decoration-none">${urlData.url.substring(0, 60)}${urlData.url.length > 60 ? '...' : ''}</a></small></td>
                            <td><small>${urlData.title.substring(0, 30)}${urlData.title.length > 30 ? '...' : ''}</small></td>
                            <td><span class="badge bg-success">${urlData.count}</span></td>
                            <td><small>${totalDuration}</small></td>
                            <td><small>${lastVisit}</small></td>
                        </tr>
                    `;
                });

                content += `
                            </tbody>
                        </table>
                    </div>
                    <div class="mt-3">
                        <strong>Total Unique URLs:</strong> ${uniqueUrlsArray.length}
                    </div>
                `;
            }

            document.querySelector('#uniqueUrlsModal .modal-body').innerHTML = content;
        })
        .catch(error => {
            console.error('Error loading unique URLs:', error);
            document.querySelector('#uniqueUrlsModal .modal-body').innerHTML =
                '<div class="alert alert-danger">Failed to load unique URLs data.</div>';
        });
}
</script>
@endsection
