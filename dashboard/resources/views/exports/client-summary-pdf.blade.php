<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Client Summary Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 12px;
            margin: 0;
            padding: 20px;
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 2px solid #333;
            padding-bottom: 20px;
        }

        .header h1 {
            margin: 0;
            color: #333;
            font-size: 24px;
        }

        .header p {
            margin: 5px 0;
            color: #666;
        }

        .stats-section {
            margin-bottom: 30px;
        }

        .stats-title {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 15px;
            color: #333;
            border-bottom: 1px solid #ddd;
            padding-bottom: 5px;
        }

        .stats-grid {
            display: table;
            width: 100%;
            margin-bottom: 20px;
        }

        .stats-row {
            display: table-row;
        }

        .stats-item {
            display: table-cell;
            width: 16.66%;
            text-align: center;
            padding: 15px 10px;
            border: 1px solid #ddd;
            background-color: #f8f9fa;
        }

        .stats-value {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            display: block;
        }

        .stats-label {
            font-size: 10px;
            color: #666;
            margin-top: 5px;
        }

        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        .table th {
            background-color: #343a40;
            color: white;
            padding: 10px 8px;
            text-align: left;
            font-size: 11px;
            border: 1px solid #ddd;
        }

        .table td {
            padding: 8px;
            border: 1px solid #ddd;
            font-size: 10px;
            vertical-align: top;
        }

        .table tr:nth-child(even) {
            background-color: #f8f9fa;
        }

        .status-online {
            color: #28a745;
            font-weight: bold;
        }

        .status-offline {
            color: #6c757d;
            font-weight: bold;
        }

        .client-name {
            font-weight: bold;
            color: #007bff;
        }

        .footer {
            margin-top: 30px;
            text-align: center;
            color: #666;
            font-size: 10px;
            border-top: 1px solid #ddd;
            padding-top: 15px;
        }

        .period-info {
            background-color: #d1ecf1;
            border: 1px solid #bee5eb;
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 4px;
        }

        .text-truncate {
            overflow: hidden;
            white-space: nowrap;
            text-overflow: ellipsis;
            max-width: 150px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Client Summary Report</h1>
        <p>Comprehensive overview of all clients and their activities</p>
        <p><strong>Generated on:</strong> {{ now()->format('M d, Y \a\t H:i:s') }}</p>
    </div>

    <div class="period-info">
        <strong>Report Period:</strong> {{ $from->format('M d, Y') }} to {{ $to->format('M d, Y') }}
        ({{ $from->diffInDays($to) + 1 }} days)
    </div>

    <div class="stats-section">
        <div class="stats-title">Overall Statistics</div>
        <div class="stats-grid">
            <div class="stats-row">
                <div class="stats-item">
                    <span class="stats-value">{{ $overallStats['total_clients'] }}</span>
                    <div class="stats-label">Total Clients</div>
                </div>
                <div class="stats-item">
                    <span class="stats-value">{{ $overallStats['online_clients'] }}</span>
                    <div class="stats-label">Online Now</div>
                </div>
                <div class="stats-item">
                    <span class="stats-value">{{ number_format($overallStats['total_screenshots']) }}</span>
                    <div class="stats-label">Screenshots</div>
                </div>
                <div class="stats-item">
                    <span class="stats-value">{{ number_format($overallStats['total_browser_sessions']) }}</span>
                    <div class="stats-label">Browser Sessions</div>
                </div>
                <div class="stats-item">
                    <span class="stats-value">{{ number_format($overallStats['total_url_activities']) }}</span>
                    <div class="stats-label">URL Activities</div>
                </div>
                <div class="stats-item">
                    <span class="stats-value">{{ $overallStats['total_duration_hours'] }}h</span>
                    <div class="stats-label">Total Time</div>
                </div>
            </div>
        </div>
    </div>

    <div class="stats-section">
        <div class="stats-title">Client Details</div>
        <table class="table">
            <thead>
                <tr>
                    <th>Client Name</th>
                    <th>Hostname</th>
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
                @foreach($clients as $clientData)
                    <tr>
                        <td>
                            <div class="client-name">{{ $clientData['client']->getDisplayUsername() }}</div>
                            <div style="font-size: 9px; color: #666;">{{ is_array($clientData['client']->os_info) ? implode(', ', $clientData['client']->os_info) : $clientData['client']->os_info }}</div>
                        </td>
                        <td>{{ $clientData['client']->hostname }}</td>
                        <td>
                            <span class="{{ $clientData['stats']['status'] == 'Online' ? 'status-online' : 'status-offline' }}">
                                {{ $clientData['stats']['status'] }}
                            </span>
                        </td>
                        <td style="text-align: center;">{{ number_format($clientData['stats']['screenshots']) }}</td>
                        <td style="text-align: center;">{{ number_format($clientData['stats']['browser_sessions']) }}</td>
                        <td style="text-align: center;">{{ number_format($clientData['stats']['url_activities']) }}</td>
                        <td style="text-align: center;">{{ number_format($clientData['stats']['unique_urls']) }}</td>
                        <td style="text-align: center;">{{ $clientData['stats']['total_duration_minutes'] }}m</td>
                        <td>
                            <div class="text-truncate">{{ $clientData['stats']['top_domains'] }}</div>
                        </td>
                        <td>{{ $clientData['stats']['last_activity'] }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>

    <div class="footer">
        <p>Report generated by Tenjo Employee Monitoring System</p>
        <p>Total {{ $clients->count() }} clients analyzed</p>
    </div>
</body>
</html>
