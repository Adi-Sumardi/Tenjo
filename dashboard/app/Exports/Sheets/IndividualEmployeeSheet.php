<?php

namespace App\Exports\Sheets;

use App\Models\Client;
use App\Models\Screenshot;
use App\Models\BrowserSession;
use App\Models\UrlActivity;
use App\Services\ActivityCategorizerService;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\WithColumnWidths;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;

class IndividualEmployeeSheet implements FromCollection, WithHeadings, WithStyles, WithTitle, WithColumnWidths
{
    protected $client;
    protected $from;
    protected $to;

    public function __construct(Client $client, Carbon $from, Carbon $to)
    {
        $this->client = $client;
        $this->from = $from;
        $this->to = $to;
    }

    public function title(): string
    {
        // Excel sheet names max 31 chars
        $name = $this->client->getDisplayUsername();
        return substr($name, 0, 31);
    }

    public function collection()
    {
        $data = collect([]);

        // Employee info header
        $data->push(['EMPLOYEE ACTIVITY REPORT']);
        $data->push(['Employee Name', $this->client->getDisplayUsername()]);
        $data->push(['Hostname', $this->client->hostname]);
        $data->push(['Operating System', is_array($this->client->os_info) ? implode(', ', $this->client->os_info) : $this->client->os_info]);
        $data->push(['Report Period', $this->from->format('Y-m-d') . ' to ' . $this->to->format('Y-m-d')]);
        $data->push(['Current Status', $this->client->isOnline() ? 'Online' : 'Offline']);
        $data->push(['Last Seen', $this->client->last_seen ? Carbon::parse($this->client->last_seen)->format('Y-m-d H:i:s') : 'Never']);
        $data->push(['']);

        // Summary statistics
        $screenshots = Screenshot::where('client_id', $this->client->client_id)
            ->whereBetween('captured_at', [$this->from, $this->to])
            ->count();

        $sessions = BrowserSession::where('client_id', $this->client->client_id)
            ->whereBetween('session_start', [$this->from, $this->to])
            ->get();

        $urlActivities = UrlActivity::where('client_id', $this->client->client_id)
            ->whereBetween('visit_start', [$this->from, $this->to])
            ->get();

        $totalDuration = $urlActivities->sum('duration');
        $uniqueUrls = $urlActivities->pluck('url')->unique()->count();

        $data->push(['SUMMARY STATISTICS']);
        $data->push(['Metric', 'Value']);
        $data->push(['Total Screenshots', number_format($screenshots)]);
        $data->push(['Total Browser Sessions', number_format($sessions->count())]);
        $data->push(['Total URL Activities', number_format($urlActivities->count())]);
        $data->push(['Unique URLs Visited', number_format($uniqueUrls)]);
        $data->push(['Total Active Time', gmdate('H:i:s', $totalDuration)]);
        $data->push(['Total Active Hours', round($totalDuration / 3600, 2)]);
        $data->push(['Average Session Duration', $sessions->count() > 0 ? gmdate('H:i:s', $totalDuration / $sessions->count()) : '00:00:00']);
        $data->push(['']);
        $data->push(['']);

        // Activity Category Breakdown
        $data->push(['ACTIVITY CATEGORY BREAKDOWN']);
        $data->push(['']);
        $data->push(['Category', 'Percentage', 'Duration', 'Visit Count']);

        $categorizer = new ActivityCategorizerService();

        // Calculate category statistics
        $workDuration = 0;
        $socialDuration = 0;
        $suspiciousDuration = 0;
        $workCount = 0;
        $socialCount = 0;
        $suspiciousCount = 0;

        foreach ($urlActivities as $activity) {
            $duration = floatval($activity->duration);

            switch ($activity->activity_category) {
                case ActivityCategorizerService::CATEGORY_WORK:
                    $workDuration += $duration;
                    $workCount++;
                    break;
                case ActivityCategorizerService::CATEGORY_SOCIAL:
                    $socialDuration += $duration;
                    $socialCount++;
                    break;
                case ActivityCategorizerService::CATEGORY_SUSPICIOUS:
                    $suspiciousDuration += $duration;
                    $suspiciousCount++;
                    break;
                default:
                    // FIX: Handle NULL or unknown categories as 'work' (benefit of doubt)
                    $workDuration += $duration;
                    $workCount++;
                    break;
            }
        }

        $totalCategoryDuration = $workDuration + $socialDuration + $suspiciousDuration;

        if ($totalCategoryDuration > 0) {
            $workPercentage = round(($workDuration / $totalCategoryDuration) * 100, 1);
            $socialPercentage = round(($socialDuration / $totalCategoryDuration) * 100, 1);
            $suspiciousPercentage = round(($suspiciousDuration / $totalCategoryDuration) * 100, 1);
        } else {
            $workPercentage = $socialPercentage = $suspiciousPercentage = 0;
        }

        $data->push([
            '🟢 Pekerjaan (Work)',
            $workPercentage . '%',
            gmdate('H:i:s', $workDuration),
            $workCount
        ]);
        $data->push([
            '🔴 Media Sosial (Social Media)',
            $socialPercentage . '%',
            gmdate('H:i:s', $socialDuration),
            $socialCount
        ]);
        $data->push([
            '⚫ Tidak Teridentifikasi (Suspicious)',
            $suspiciousPercentage . '%',
            gmdate('H:i:s', $suspiciousDuration),
            $suspiciousCount
        ]);

        $data->push(['']);
        $data->push(['']);

        // Top Work Activities
        $workActivities = $urlActivities->filter(function($activity) {
            return $activity->activity_category === ActivityCategorizerService::CATEGORY_WORK;
        });

        if ($workActivities->count() > 0) {
            $data->push(['TOP 10 WORK ACTIVITIES 🟢']);
            $data->push(['']);

            $topWorkUrls = $workActivities->groupBy('url')->map(function($activities, $url) {
                $first = $activities->first();
                return [
                    'url' => $url,
                    'domain' => $first->domain ?? 'Unknown',
                    'visits' => $activities->count(),
                    'total_duration' => $activities->sum('duration'),
                ];
            })->sortByDesc('total_duration')->take(10)->values();

            foreach ($topWorkUrls as $urlData) {
                $data->push([
                    $urlData['domain'],
                    $urlData['url'],
                    $urlData['visits'],
                    gmdate('H:i:s', $urlData['total_duration']),
                ]);
            }

            $data->push(['']);
            $data->push(['']);
        }

        // Top Social Media Activities
        $socialActivities = $urlActivities->filter(function($activity) {
            return $activity->activity_category === ActivityCategorizerService::CATEGORY_SOCIAL;
        });

        if ($socialActivities->count() > 0) {
            $data->push(['TOP 10 SOCIAL MEDIA ACTIVITIES 🔴']);
            $data->push(['']);

            $topSocialUrls = $socialActivities->groupBy('url')->map(function($activities, $url) {
                $first = $activities->first();
                return [
                    'url' => $url,
                    'domain' => $first->domain ?? 'Unknown',
                    'visits' => $activities->count(),
                    'total_duration' => $activities->sum('duration'),
                ];
            })->sortByDesc('total_duration')->take(10)->values();

            foreach ($topSocialUrls as $urlData) {
                $data->push([
                    $urlData['domain'],
                    $urlData['url'],
                    $urlData['visits'],
                    gmdate('H:i:s', $urlData['total_duration']),
                ]);
            }

            $data->push(['']);
            $data->push(['']);
        }

        // Suspicious Activities
        $suspiciousActivities = $urlActivities->filter(function($activity) {
            return $activity->activity_category === ActivityCategorizerService::CATEGORY_SUSPICIOUS;
        });

        if ($suspiciousActivities->count() > 0) {
            $data->push(['SUSPICIOUS ACTIVITIES ⚫ (Requires Review)']);
            $data->push(['']);

            $suspiciousUrls = $suspiciousActivities->groupBy('url')->map(function($activities, $url) {
                $first = $activities->first();
                return [
                    'url' => $url,
                    'domain' => $first->domain ?? 'Unknown',
                    'visits' => $activities->count(),
                    'total_duration' => $activities->sum('duration'),
                ];
            })->sortByDesc('total_duration')->values();

            foreach ($suspiciousUrls as $urlData) {
                $data->push([
                    $urlData['domain'],
                    $urlData['url'],
                    $urlData['visits'],
                    gmdate('H:i:s', $urlData['total_duration']),
                ]);
            }

            $data->push(['']);
            $data->push(['']);
        }

        // Browser usage breakdown
        $data->push(['BROWSER USAGE BREAKDOWN']);
        $data->push(['']);

        $browserStats = $sessions->groupBy('browser_name')->map(function($sessions, $browser) {
            return [
                'browser' => $browser,
                'sessions' => $sessions->count(),
                'total_duration' => $sessions->sum('total_duration'),
                'avg_duration' => $sessions->avg('total_duration')
            ];
        })->sortByDesc('total_duration')->values();

        foreach ($browserStats as $stat) {
            $data->push([
                $stat['browser'],
                $stat['sessions'] . ' sessions',
                gmdate('H:i:s', $stat['total_duration']),
                gmdate('H:i:s', $stat['avg_duration']),
            ]);
        }

        $data->push(['']);
        $data->push(['']);

        // Top URLs visited
        $data->push(['TOP 20 MOST VISITED URLs']);
        $data->push(['']);

        $topUrls = $urlActivities->groupBy('url')->map(function($activities, $url) {
            $first = $activities->first();
            return [
                'url' => $url,
                'domain' => $first->domain ?? 'Unknown',
                'page_title' => $first->page_title ?? 'No title',
                'visits' => $activities->count(),
                'total_duration' => $activities->sum('duration'),
                'avg_duration' => $activities->avg('duration')
            ];
        })->sortByDesc('total_duration')->take(20)->values();

        foreach ($topUrls as $urlData) {
            $data->push([
                $urlData['url'],
                $urlData['domain'],
                $urlData['page_title'],
                $urlData['visits'],
                gmdate('H:i:s', $urlData['total_duration']),
                gmdate('H:i:s', $urlData['avg_duration'])
            ]);
        }

        $data->push(['']);
        $data->push(['']);

        // Daily activity breakdown
        $data->push(['DAILY ACTIVITY BREAKDOWN']);
        $data->push(['']);

        $dailyStats = $urlActivities->groupBy(function($activity) {
            return Carbon::parse($activity->visit_start)->format('Y-m-d');
        })->map(function($activities, $date) {
            return [
                'date' => $date,
                'url_activities' => $activities->count(),
                'unique_urls' => $activities->pluck('url')->unique()->count(),
                'total_duration' => $activities->sum('duration'),
            ];
        })->sortBy('date')->values();

        foreach ($dailyStats as $dayStat) {
            $data->push([
                $dayStat['date'],
                $dayStat['url_activities'],
                $dayStat['unique_urls'],
                gmdate('H:i:s', $dayStat['total_duration']),
                round($dayStat['total_duration'] / 3600, 2) . ' hours'
            ]);
        }

        $data->push(['']);
        $data->push(['']);

        // Domain analysis
        $data->push(['TOP DOMAINS VISITED']);
        $data->push(['']);

        $domainStats = $urlActivities->groupBy('domain')->map(function($activities, $domain) {
            return [
                'domain' => $domain ?: 'Unknown',
                'visits' => $activities->count(),
                'unique_urls' => $activities->pluck('url')->unique()->count(),
                'total_duration' => $activities->sum('duration'),
            ];
        })->sortByDesc('total_duration')->take(15)->values();

        foreach ($domainStats as $domainData) {
            $data->push([
                $domainData['domain'],
                $domainData['visits'],
                $domainData['unique_urls'],
                gmdate('H:i:s', $domainData['total_duration']),
                round($domainData['total_duration'] / 3600, 2) . ' hours'
            ]);
        }

        return $data;
    }

    public function headings(): array
    {
        return [];
    }

    public function styles(Worksheet $sheet)
    {
        // Title
        $sheet->mergeCells('A1:F1');
        $sheet->getStyle('A1')->applyFromArray([
            'font' => [
                'bold' => true,
                'size' => 16,
                'color' => ['rgb' => 'FFFFFF']
            ],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => '4472C4']
            ],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
            ]
        ]);

        // Employee info section (rows 2-7)
        $sheet->getStyle('A2:A7')->applyFromArray([
            'font' => ['bold' => true]
        ]);

        // Section headers styling
        $sectionHeaders = [9, 20, 30]; // Approximate rows for sections
        foreach ($sectionHeaders as $row) {
            $sheet->getStyle("A{$row}")->applyFromArray([
                'font' => [
                    'bold' => true,
                    'size' => 14,
                    'color' => ['rgb' => 'FFFFFF']
                ],
                'fill' => [
                    'fillType' => Fill::FILL_SOLID,
                    'startColor' => ['rgb' => '70AD47']
                ]
            ]);
        }

        // Summary statistics headers
        $sheet->getStyle('A10:B10')->applyFromArray([
            'font' => ['bold' => true],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => 'E2EFDA']
            ]
        ]);

        return [];
    }

    public function columnWidths(): array
    {
        return [
            'A' => 40, // URLs/Labels
            'B' => 20, // Values/Domain
            'C' => 30, // Page Title
            'D' => 12, // Visits/Count
            'E' => 15, // Duration
            'F' => 15, // Additional info
        ];
    }
}
