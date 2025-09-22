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
        ({{ $from->diffInDays($to) + 1 }} days)
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
                                    <span class="badge bg-info">{{ number_format($clientData['stats']['screenshots']) }}</span>
                                </td>
                                <td>
                                    <span class="badge bg-warning">{{ number_format($clientData['stats']['browser_sessions']) }}</span>
                                </td>
                                <td>
                                    <span class="badge bg-purple">{{ number_format($clientData['stats']['url_activities']) }}</span>
                                </td>
                                <td>
                                    <span class="badge bg-primary">{{ number_format($clientData['stats']['unique_urls']) }}</span>
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
`;
document.head.appendChild(style);
</script>
@endsection
