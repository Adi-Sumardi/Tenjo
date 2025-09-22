<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithColumnWidths;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Font;

class ClientSummaryExport implements FromCollection, WithHeadings, WithStyles, WithColumnWidths, ShouldAutoSize
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

    public function collection()
    {
        $data = collect([
            // Overall Statistics Section
            ['OVERALL STATISTICS'],
            [''],
            ['Total Clients', $this->overallStats['total_clients']],
            ['Online Clients', $this->overallStats['online_clients']],
            ['Total Screenshots', number_format($this->overallStats['total_screenshots'])],
            ['Total Browser Sessions', number_format($this->overallStats['total_browser_sessions'])],
            ['Total URL Activities', number_format($this->overallStats['total_url_activities'])],
            ['Total Unique URLs', number_format($this->overallStats['total_unique_urls'])],
            ['Total Duration (Hours)', $this->overallStats['total_duration_hours']],
            [''],
            ['Report Period', $this->period['from'] . ' to ' . $this->period['to']],
            [''],
            [''],
            // Client Details Section
            ['CLIENT DETAILS'],
            [''],
        ]);

        // Add client data
        foreach ($this->clients as $clientData) {
            $data->push([
                $clientData['client']->getDisplayUsername(),
                $clientData['client']->hostname,
                $clientData['client']->os_info,
                $clientData['stats']['status'],
                $clientData['stats']['screenshots'],
                $clientData['stats']['browser_sessions'],
                $clientData['stats']['url_activities'],
                $clientData['stats']['unique_urls'],
                $clientData['stats']['total_duration_minutes'] . ' minutes',
                $clientData['stats']['top_domains'],
                $clientData['stats']['last_activity'],
            ]);
        }

        return $data;
    }

    public function headings(): array
    {
        return [
            'Client Name',
            'Hostname',
            'OS Info',
            'Status',
            'Screenshots',
            'Browser Sessions',
            'URL Activities',
            'Unique URLs',
            'Time Active',
            'Top Domains',
            'Last Activity',
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            // Header row styling
            16 => [
                'font' => [
                    'bold' => true,
                    'size' => 12,
                ],
                'alignment' => [
                    'horizontal' => Alignment::HORIZONTAL_CENTER,
                ],
            ],
            // Overall statistics title
            1 => [
                'font' => [
                    'bold' => true,
                    'size' => 14,
                ],
            ],
            // Client details title
            15 => [
                'font' => [
                    'bold' => true,
                    'size' => 14,
                ],
            ],
        ];
    }

    public function columnWidths(): array
    {
        return [
            'A' => 20,
            'B' => 20,
            'C' => 25,
            'D' => 10,
            'E' => 12,
            'F' => 15,
            'G' => 15,
            'H' => 12,
            'I' => 15,
            'J' => 30,
            'K' => 20,
        ];
    }
}
