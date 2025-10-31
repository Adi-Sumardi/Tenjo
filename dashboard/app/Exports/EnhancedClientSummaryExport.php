<?php

namespace App\Exports;

use App\Exports\Sheets\SummarySheet;
use App\Exports\Sheets\KPIDashboardSheet;
use App\Exports\Sheets\IndividualEmployeeSheet;
use App\Exports\Sheets\AnalyticsSheet;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;
use Carbon\Carbon;

class EnhancedClientSummaryExport implements WithMultipleSheets
{
    protected $clients;
    protected $overallStats;
    protected $period;
    protected $from;
    protected $to;

    public function __construct($clients, $overallStats, $period)
    {
        $this->clients = $clients;
        $this->overallStats = $overallStats;
        $this->period = $period;
        $this->from = Carbon::parse($period['from']);
        $this->to = Carbon::parse($period['to']);
    }

    public function sheets(): array
    {
        $sheets = [];

        // Sheet 1: Summary of all employees
        $sheets[] = new SummarySheet($this->clients, $this->overallStats, $this->period);

        // Sheet 2: KPI Dashboard
        $sheets[] = new KPIDashboardSheet($this->clients, $this->period);

        // Sheet 3+: Individual employee sheets
        foreach ($this->clients as $clientData) {
            $sheets[] = new IndividualEmployeeSheet(
                $clientData['client'],
                $this->from,
                $this->to
            );
        }

        // Last sheet: Charts & Analytics
        $sheets[] = new AnalyticsSheet($this->clients, $this->period);

        return $sheets;
    }
}
