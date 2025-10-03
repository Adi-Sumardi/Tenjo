<?php

namespace Database\Seeders;

use App\Models\Client;
use Illuminate\Database\Seeder;

class ClientSeeder extends Seeder
{
    /**
     * Seed the application's database with demo clients for local testing.
     */
    public function run(): void
    {
        if (Client::count() > 0) {
            return;
        }

        $namedClients = [
            [
                'client_id' => 'ops-center-win-01',
                'hostname' => 'OPS-WIN-01',
                'username' => 'ops.agent',
                'custom_username' => 'Windows Ops',
                'os_info' => [
                    'name' => 'Windows',
                    'version' => '11 Pro',
                    'platform' => 'Windows'
                ],
            ],
            [
                'client_id' => 'studio-linux-qa',
                'hostname' => 'STUDIO-LNX-QA',
                'username' => 'qa.pipeline',
                'custom_username' => 'Linux QA',
                'os_info' => [
                    'name' => 'Ubuntu',
                    'version' => '22.04 LTS',
                    'platform' => 'Linux'
                ],
            ],
            [
                'client_id' => 'macbook-pro-adi',
                'hostname' => 'ADI-MBP-2025',
                'username' => 'adi.sumardi',
                'custom_username' => 'Adi MacBook',
                'os_info' => [
                    'name' => 'macOS',
                    'version' => '14.5 Sonoma',
                    'platform' => 'Darwin'
                ],
            ],
        ];

        foreach ($namedClients as $clientData) {
            Client::factory()->create($clientData);
        }

        Client::factory()->offline()->create([
            'client_id' => 'field-laptop-backlog',
            'hostname' => 'FIELD-OFFLINE',
            'username' => 'support.field',
            'custom_username' => 'Laptop Offline',
            'os_info' => [
                'name' => 'Windows',
                'version' => '10 Enterprise',
                'platform' => 'Windows'
            ],
        ]);
    }
}
