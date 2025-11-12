<?php

namespace App\Exports\Sheets;

use App\Services\ActivityCategorizerService;
use App\Models\UrlActivity;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\WithColumnWidths;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;

class KPIDashboardSheet implements FromCollection, WithHeadings, WithStyles, WithTitle, WithColumnWidths
{
    protected $clients;
    protected $period;

    public function __construct($clients, $period)
    {
        $this->clients = $clients;
        $this->period = $period;
    }

    public function title(): string
    {
        return 'KPI Dashboard';
    }

    public function collection()
    {
        $data = collect([]);

        // Header
        $data->push(['KPI DASHBOARD - EMPLOYEE PERFORMANCE METRICS']);
        $data->push(['Period', $this->period['from'] . ' to ' . $this->period['to']]);
        $data->push(['']);

        // Add headers manually (row 4)
        $data->push([
            'Rank',
            'Employee',
            'Active Hours',
            'Work % 🟢',
            'Social % 🔴',
            'Suspicious % ⚫',
            'Productivity Score',
            'Engagement Score',
            'Status',
            'Performance Rating'
        ]);

        // Calculate KPIs for each employee
        $kpiData = [];
        $totalMinutes = 0;
        $totalActivities = 0;

        foreach ($this->clients as $clientData) {
            $stats = $clientData['stats'];
            $activeMinutes = floatval($stats['total_duration_minutes']);
            $activeHours = round($activeMinutes / 60, 2);
            $activities = intval($stats['url_activities']);
            $screenshots = intval($stats['screenshots']);

            $totalMinutes += $activeMinutes;
            $totalActivities += $activities;

            // Calculate KPIs
            $productivityScore = $this->calculateProductivityScore($stats);
            $engagementScore = $this->calculateEngagementScore($stats);
            $activityRate = $activities > 0 ? round($activities / max($activeHours, 0.1), 2) : 0;
            $averageSessionTime = $stats['browser_sessions'] > 0
                ? round($activeMinutes / $stats['browser_sessions'], 2)
                : 0;

            // Calculate activity category percentages
            $categoryPercentages = $this->calculateCategoryPercentages($clientData['client']->client_id);

            $kpiData[] = [
                'employee' => $clientData['client']->getDisplayUsername(),
                'active_hours' => $activeHours,
                'activities' => $activities,
                'screenshots' => $screenshots,
                'browser_sessions' => $stats['browser_sessions'],
                'work_percentage' => $categoryPercentages['work'],
                'social_percentage' => $categoryPercentages['social'],
                'suspicious_percentage' => $categoryPercentages['suspicious'],
                'productivity_score' => $productivityScore,
                'engagement_score' => $engagementScore,
                'activity_rate' => $activityRate,
                'avg_session_time' => $averageSessionTime,
                'status' => $stats['status']
            ];
        }

        // Sort by productivity score
        usort($kpiData, function($a, $b) {
            return $b['productivity_score'] <=> $a['productivity_score'];
        });

        // Add rank
        $rank = 1;
        foreach ($kpiData as $kpi) {
            $data->push([
                $rank++,
                $kpi['employee'],
                $kpi['active_hours'],
                $kpi['work_percentage'] . '%',
                $kpi['social_percentage'] . '%',
                $kpi['suspicious_percentage'] . '%',
                $kpi['productivity_score'],
                $kpi['engagement_score'],
                $kpi['status'],
                $this->getPerformanceRating($kpi['productivity_score'])
            ]);
        }

        // Add summary statistics
        $data->push(['']);
        $data->push(['']);
        $data->push(['SUMMARY STATISTICS']);
        $data->push(['Average Active Hours', round($totalMinutes / 60 / max(count($kpiData), 1), 2)]);
        $data->push(['Total Activities', $totalActivities]);
        $data->push(['Most Productive Employee', $kpiData[0]['employee'] ?? 'N/A']);
        $data->push(['Least Productive Employee', end($kpiData)['employee'] ?? 'N/A']);

        return $data;
    }

    public function headings(): array
    {
        return [
            'Rank',
            'Employee',
            'Active Hours',
            'Work % 🟢',
            'Social % 🔴',
            'Suspicious % ⚫',
            'Productivity Score',
            'Engagement Score',
            'Status',
            'Performance Rating'
        ];
    }

    protected function calculateProductivityScore($stats): float
    {
        // Weighted scoring system
        $activeTime = floatval($stats['total_duration_minutes']);
        $activities = intval($stats['url_activities']);
        $sessions = intval($stats['browser_sessions']);
        $uniqueUrls = intval($stats['unique_urls']);

        // Normalize values (assuming 8 hours = 480 min is 100%)
        $timeScore = min(($activeTime / 480) * 100, 100);
        $activityScore = min(($activities / 100) * 100, 100);
        $sessionScore = min(($sessions / 20) * 100, 100);
        $diversityScore = min(($uniqueUrls / 50) * 100, 100);

        // Weighted average
        $productivityScore = ($timeScore * 0.4) + ($activityScore * 0.3) +
                            ($sessionScore * 0.2) + ($diversityScore * 0.1);

        return round($productivityScore, 2);
    }

    protected function calculateEngagementScore($stats): float
    {
        // Engagement = How actively they're working
        $activities = intval($stats['url_activities']);
        $screenshots = intval($stats['screenshots']);
        $sessions = intval($stats['browser_sessions']);

        // More activities = more engaged
        $activityScore = min(($activities / 100) * 100, 100);
        $captureScore = min(($screenshots / 50) * 100, 100);
        $sessionScore = min(($sessions / 20) * 100, 100);

        $engagementScore = ($activityScore * 0.5) + ($captureScore * 0.3) + ($sessionScore * 0.2);

        return round($engagementScore, 2);
    }

    protected function getPerformanceRating($score): string
    {
        if ($score >= 90) return 'Excellent';
        if ($score >= 75) return 'Good';
        if ($score >= 60) return 'Average';
        if ($score >= 40) return 'Below Average';
        return 'Poor';
    }

    /**
     * Calculate category percentages for a client
     */
    protected function calculateCategoryPercentages($clientId): array
    {
        $categorizer = new ActivityCategorizerService();

        // Get all URL activities for this client in the period
        $activities = UrlActivity::where('client_id', $clientId)
            ->whereBetween('visit_start', [$this->period['from'], $this->period['to']])
            ->get();

        if ($activities->isEmpty()) {
            return [
                'work' => 0,
                'social' => 0,
                'suspicious' => 0
            ];
        }

        // Calculate total duration by category
        $workDuration = 0;
        $socialDuration = 0;
        $suspiciousDuration = 0;
        $totalDuration = 0;

        foreach ($activities as $activity) {
            $duration = floatval($activity->duration);
            $totalDuration += $duration;

            switch ($activity->activity_category) {
                case ActivityCategorizerService::CATEGORY_WORK:
                    $workDuration += $duration;
                    break;
                case ActivityCategorizerService::CATEGORY_SOCIAL:
                    $socialDuration += $duration;
                    break;
                case ActivityCategorizerService::CATEGORY_SUSPICIOUS:
                    $suspiciousDuration += $duration;
                    break;
            }
        }

        // Calculate percentages
        if ($totalDuration > 0) {
            return [
                'work' => round(($workDuration / $totalDuration) * 100, 1),
                'social' => round(($socialDuration / $totalDuration) * 100, 1),
                'suspicious' => round(($suspiciousDuration / $totalDuration) * 100, 1)
            ];
        }

        return [
            'work' => 0,
            'social' => 0,
            'suspicious' => 0
        ];
    }

    public function styles(Worksheet $sheet)
    {
        // Title
        $sheet->mergeCells('A1:J1');
        $sheet->getStyle('A1')->applyFromArray([
            'font' => [
                'bold' => true,
                'size' => 16,
                'color' => ['rgb' => 'FFFFFF']
            ],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => '5B9BD5']
            ],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
            ]
        ]);

        // Headers (row 4)
        $sheet->getStyle('A4:J4')->applyFromArray([
            'font' => [
                'bold' => true,
                'color' => ['rgb' => 'FFFFFF']
            ],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => '4472C4']
            ],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
            ],
            'borders' => [
                'allBorders' => [
                    'borderStyle' => Border::BORDER_THIN
                ]
            ]
        ]);

        // Data rows - conditional formatting
        $lastRow = 4 + $this->clients->count();
        for ($i = 5; $i <= $lastRow; $i++) {
            // Format productivity score
            $sheet->getStyle("G{$i}")->getNumberFormat()
                ->setFormatCode(NumberFormat::FORMAT_NUMBER_00);

            // Color code category columns
            // Work % (D) - Green background if > 70%
            $sheet->getStyle("D{$i}")->applyFromArray([
                'fill' => [
                    'fillType' => Fill::FILL_SOLID,
                    'startColor' => ['rgb' => 'E2EFDA'] // Light green
                ]
            ]);

            // Social % (E) - Orange background
            $sheet->getStyle("E{$i}")->applyFromArray([
                'fill' => [
                    'fillType' => Fill::FILL_SOLID,
                    'startColor' => ['rgb' => 'FFF2CC'] // Light orange
                ]
            ]);

            // Suspicious % (F) - Red background
            $sheet->getStyle("F{$i}")->applyFromArray([
                'fill' => [
                    'fillType' => Fill::FILL_SOLID,
                    'startColor' => ['rgb' => 'FCE4D6'] // Light red
                ]
            ]);

            // Color code based on rank
            if ($i == 5) { // Top performer
                $sheet->getStyle("A{$i}:C{$i}")->applyFromArray([
                    'fill' => [
                        'fillType' => Fill::FILL_SOLID,
                        'startColor' => ['rgb' => 'C6EFCE'] // Light green
                    ]
                ]);
                $sheet->getStyle("G{$i}:J{$i}")->applyFromArray([
                    'fill' => [
                        'fillType' => Fill::FILL_SOLID,
                        'startColor' => ['rgb' => 'C6EFCE'] // Light green
                    ]
                ]);
            } elseif ($i == $lastRow) { // Last performer
                $sheet->getStyle("A{$i}:C{$i}")->applyFromArray([
                    'fill' => [
                        'fillType' => Fill::FILL_SOLID,
                        'startColor' => ['rgb' => 'FFC7CE'] // Light red
                    ]
                ]);
                $sheet->getStyle("G{$i}:J{$i}")->applyFromArray([
                    'fill' => [
                        'fillType' => Fill::FILL_SOLID,
                        'startColor' => ['rgb' => 'FFC7CE'] // Light red
                    ]
                ]);
            }
        }

        // Add borders
        $sheet->getStyle("A4:J{$lastRow}")->applyFromArray([
            'borders' => [
                'allBorders' => [
                    'borderStyle' => Border::BORDER_THIN,
                    'color' => ['rgb' => 'CCCCCC']
                ]
            ]
        ]);

        return [];
    }

    public function columnWidths(): array
    {
        return [
            'A' => 8,  // Rank
            'B' => 25, // Employee
            'C' => 12, // Active Hours
            'D' => 15, // Work %
            'E' => 15, // Social %
            'F' => 18, // Suspicious %
            'G' => 18, // Productivity Score
            'H' => 18, // Engagement Score
            'I' => 10, // Status
            'J' => 20, // Performance Rating
        ];
    }
}
