<?php

namespace App\Exports\Sheets;

use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\WithColumnWidths;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Color;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;

class SummarySheet implements FromCollection, WithHeadings, WithStyles, WithTitle, WithColumnWidths
{
    protected $clients;
    protected $overallStats;
    protected $period;

    public function __construct($clients, $overallStats, $period)
    {
        $this->clients = $clients;
        $this->overallStats = $overallStats;
        $this->period = $period;
    }

    public function title(): string
    {
        return 'Summary';
    }

    public function collection()
    {
        $data = collect([]);

        // Header section
        $data->push(['EMPLOYEE ACTIVITY SUMMARY REPORT']);
        $data->push(['Report Period', $this->period['from'] . ' to ' . $this->period['to']]);
        $data->push(['Generated On', now()->format('Y-m-d H:i:s')]);
        $data->push(['']);

        // Overall statistics
        $data->push(['OVERALL STATISTICS']);
        $data->push(['Metric', 'Value']);
        $data->push(['Total Employees Monitored', $this->overallStats['total_clients']]);
        $data->push(['Currently Online', $this->overallStats['online_clients']]);
        $data->push(['Total Screenshots Captured', number_format($this->overallStats['total_screenshots'])]);
        $data->push(['Total Browser Sessions', number_format($this->overallStats['total_browser_sessions'])]);
        $data->push(['Total URL Activities', number_format($this->overallStats['total_url_activities'])]);
        $data->push(['Total Unique URLs Visited', number_format($this->overallStats['total_unique_urls'] ?? 0)]);
        $data->push(['Total Active Hours', number_format($this->overallStats['total_duration_hours'] ?? 0, 1) . ' hours']);
        $data->push(['Average Hours per Employee', number_format(($this->overallStats['total_duration_hours'] ?? 0) / max($this->overallStats['total_clients'], 1), 1) . ' hours']);
        $data->push(['']);
        $data->push(['']);

        // Employee details header
        $data->push(['EMPLOYEE DETAILS']);
        $data->push(['']);

        // Add employee data rows
        foreach ($this->clients as $clientData) {
            $client = $clientData['client'];
            $stats = $clientData['stats'];

            $data->push([
                $client->getDisplayUsername(),
                $client->hostname,
                is_array($client->os_info) ? implode(', ', $client->os_info) : $client->os_info,
                $stats['status'],
                $stats['screenshots'],
                $stats['browser_sessions'],
                $stats['url_activities'],
                $stats['unique_urls'],
                $stats['total_duration_minutes'],
                round($stats['total_duration_minutes'] / 60, 2),
                $stats['top_domains'],
                $stats['last_activity']
            ]);
        }

        return $data;
    }

    public function headings(): array
    {
        return [
            'Employee Name',
            'Hostname',
            'OS',
            'Status',
            'Screenshots',
            'Browser Sessions',
            'URL Activities',
            'Unique URLs',
            'Active Time (min)',
            'Active Time (hours)',
            'Top Domains',
            'Last Activity'
        ];
    }

    public function styles(Worksheet $sheet)
    {
        // Title styling
        $sheet->mergeCells('A1:L1');
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
                'vertical' => Alignment::VERTICAL_CENTER
            ]
        ]);

        // Period info styling
        $sheet->getStyle('A2:A3')->applyFromArray([
            'font' => ['bold' => true]
        ]);

        // Overall statistics title
        $sheet->getStyle('A5')->applyFromArray([
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

        // Statistics headers
        $sheet->getStyle('A6:B6')->applyFromArray([
            'font' => ['bold' => true],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => 'E2EFDA']
            ]
        ]);

        // Employee details title
        $sheet->getStyle('A16')->applyFromArray([
            'font' => [
                'bold' => true,
                'size' => 14,
                'color' => ['rgb' => 'FFFFFF']
            ],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => 'ED7D31']
            ]
        ]);

        // Column headers (row 18)
        $sheet->getStyle('A18:L18')->applyFromArray([
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

        // Data rows - alternating colors
        $lastRow = 18 + $this->clients->count();
        for ($i = 19; $i <= $lastRow; $i++) {
            if ($i % 2 == 0) {
                $sheet->getStyle("A{$i}:L{$i}")->applyFromArray([
                    'fill' => [
                        'fillType' => Fill::FILL_SOLID,
                        'startColor' => ['rgb' => 'F2F2F2']
                    ]
                ]);
            }
        }

        // Add borders to data
        $sheet->getStyle("A18:L{$lastRow}")->applyFromArray([
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
            'A' => 25, // Employee Name
            'B' => 20, // Hostname
            'C' => 30, // OS
            'D' => 10, // Status
            'E' => 12, // Screenshots
            'F' => 15, // Browser Sessions
            'G' => 15, // URL Activities
            'H' => 12, // Unique URLs
            'I' => 15, // Active Time (min)
            'J' => 15, // Active Time (hours)
            'K' => 35, // Top Domains
            'L' => 20, // Last Activity
        ];
    }
}
