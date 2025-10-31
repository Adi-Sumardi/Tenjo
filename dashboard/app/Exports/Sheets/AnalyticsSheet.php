<?php

namespace App\Exports\Sheets;

use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\WithColumnWidths;
use Maatwebsite\Excel\Concerns\WithCharts;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Chart\Chart;
use PhpOffice\PhpSpreadsheet\Chart\DataSeries;
use PhpOffice\PhpSpreadsheet\Chart\DataSeriesValues;
use PhpOffice\PhpSpreadsheet\Chart\Legend;
use PhpOffice\PhpSpreadsheet\Chart\PlotArea;
use PhpOffice\PhpSpreadsheet\Chart\Title as ChartTitle;

class AnalyticsSheet implements FromCollection, WithHeadings, WithStyles, WithTitle, WithColumnWidths
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
        return 'Analytics';
    }

    public function collection()
    {
        $data = collect([]);

        // Header
        $data->push(['ANALYTICS & INSIGHTS']);
        $data->push(['Period', $this->period['from'] . ' to ' . $this->period['to']]);
        $data->push(['']);

        // Productivity comparison
        $data->push(['PRODUCTIVITY COMPARISON (Active Hours)']);
        $data->push(['']);

        $productivityData = $this->clients->map(function($clientData) {
            return [
                'employee' => $clientData['client']->getDisplayUsername(),
                'active_hours' => round($clientData['stats']['total_duration_minutes'] / 60, 2),
                'activities' => $clientData['stats']['url_activities'],
                'screenshots' => $clientData['stats']['screenshots'],
            ];
        })->sortByDesc('active_hours')->values();

        foreach ($productivityData as $row) {
            $data->push([
                $row['employee'],
                $row['active_hours'],
                $row['activities'],
                $row['screenshots']
            ]);
        }

        $data->push(['']);
        $data->push(['']);

        // Activity intensity analysis
        $data->push(['ACTIVITY INTENSITY ANALYSIS']);
        $data->push(['']);
        $data->push(['Employee', 'Activities per Hour', 'Screenshots per Hour', 'Browser Sessions', 'Intensity Rating']);

        foreach ($productivityData as $row) {
            $activitiesPerHour = $row['active_hours'] > 0 ? round($row['activities'] / $row['active_hours'], 2) : 0;
            $screenshotsPerHour = $row['active_hours'] > 0 ? round($row['screenshots'] / $row['active_hours'], 2) : 0;

            // Calculate intensity rating
            $intensityScore = ($activitiesPerHour * 0.6) + ($screenshotsPerHour * 0.4);
            $intensityRating = $this->getIntensityRating($intensityScore);

            $data->push([
                $row['employee'],
                $activitiesPerHour,
                $screenshotsPerHour,
                $row['activities'], // Browser sessions placeholder
                $intensityRating
            ]);
        }

        $data->push(['']);
        $data->push(['']);

        // Work distribution analysis
        $data->push(['WORK TIME DISTRIBUTION']);
        $data->push(['']);
        $data->push(['Employee', 'Active Time %', 'Idle Time %', 'Work Hours', 'Expected Hours', 'Completion %']);

        $expectedHours = 8; // Assuming 8 hour workday
        foreach ($productivityData as $row) {
            $activeHours = $row['active_hours'];
            $workCompletion = min(($activeHours / $expectedHours) * 100, 100);
            $activePercent = round($workCompletion, 1);
            $idlePercent = round(100 - $activePercent, 1);

            $data->push([
                $row['employee'],
                $activePercent . '%',
                $idlePercent . '%',
                $activeHours,
                $expectedHours,
                round($workCompletion, 1) . '%'
            ]);
        }

        $data->push(['']);
        $data->push(['']);

        // Performance categories
        $data->push(['PERFORMANCE CATEGORIES']);
        $data->push(['']);
        $data->push(['Category', 'Count', 'Percentage']);

        $totalEmployees = $productivityData->count();
        $categories = [
            'High Performers (>6h)' => $productivityData->filter(fn($e) => $e['active_hours'] > 6)->count(),
            'Average Performers (4-6h)' => $productivityData->filter(fn($e) => $e['active_hours'] >= 4 && $e['active_hours'] <= 6)->count(),
            'Low Performers (<4h)' => $productivityData->filter(fn($e) => $e['active_hours'] < 4)->count(),
        ];

        foreach ($categories as $category => $count) {
            $percentage = $totalEmployees > 0 ? round(($count / $totalEmployees) * 100, 1) : 0;
            $data->push([
                $category,
                $count,
                $percentage . '%'
            ]);
        }

        $data->push(['']);
        $data->push(['']);

        // Recommendations
        $data->push(['RECOMMENDATIONS & INSIGHTS']);
        $data->push(['']);

        // Find top and bottom performers
        $topPerformer = $productivityData->first();
        $bottomPerformer = $productivityData->last();
        $avgHours = $productivityData->avg('active_hours');

        $data->push(['Top Performer', $topPerformer['employee'] ?? 'N/A', $topPerformer['active_hours'] ?? 0 . ' hours']);
        $data->push(['Bottom Performer', $bottomPerformer['employee'] ?? 'N/A', $bottomPerformer['active_hours'] ?? 0 . ' hours']);
        $data->push(['Team Average', '', round($avgHours, 2) . ' hours']);
        $data->push(['']);
        $data->push(['Insights']);

        if ($avgHours < 6) {
            $data->push(['⚠️ Warning', 'Team average is below 6 hours. Consider investigating low productivity.']);
        } else {
            $data->push(['✓ Good', 'Team average is healthy at ' . round($avgHours, 2) . ' hours per day.']);
        }

        $highPerformers = $categories['High Performers (>6h)'];
        if ($highPerformers < $totalEmployees * 0.5) {
            $data->push(['⚠️ Concern', 'Less than 50% are high performers. Team coaching may be needed.']);
        } else {
            $data->push(['✓ Positive', round(($highPerformers / $totalEmployees) * 100) . '% are high performers.']);
        }

        return $data;
    }

    public function headings(): array
    {
        return [];
    }

    protected function getIntensityRating($score): string
    {
        if ($score >= 20) return 'Very High';
        if ($score >= 15) return 'High';
        if ($score >= 10) return 'Medium';
        if ($score >= 5) return 'Low';
        return 'Very Low';
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
                'startColor' => ['rgb' => '9C27B0'] // Purple
            ],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
            ]
        ]);

        // Section headers - multiple rows
        $sectionRows = [4, 15, 25, 35, 45];
        foreach ($sectionRows as $row) {
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

        // Table headers
        $headerRows = [6, 17, 27, 37];
        foreach ($headerRows as $row) {
            $sheet->getStyle("A{$row}:F{$row}")->applyFromArray([
                'font' => ['bold' => true],
                'fill' => [
                    'fillType' => Fill::FILL_SOLID,
                    'startColor' => ['rgb' => 'E2EFDA']
                ],
                'borders' => [
                    'allBorders' => [
                        'borderStyle' => Border::BORDER_THIN
                    ]
                ]
            ]);
        }

        return [];
    }

    public function columnWidths(): array
    {
        return [
            'A' => 30, // Employee/Category
            'B' => 18, // Value 1
            'C' => 18, // Value 2
            'D' => 18, // Value 3
            'E' => 18, // Value 4
            'F' => 25, // Rating/Notes
        ];
    }
}
