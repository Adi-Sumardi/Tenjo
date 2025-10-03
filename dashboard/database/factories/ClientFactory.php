<?php

namespace Database\Factories;

use App\Models\Client;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Client>
 */
class ClientFactory extends Factory
{
    protected $model = Client::class;

    public function definition(): array
    {
        $osVariants = [
            ['name' => 'Windows', 'version' => '11', 'platform' => 'Windows'],
            ['name' => 'macOS', 'version' => '14.3', 'platform' => 'Darwin'],
            ['name' => 'Ubuntu', 'version' => '22.04', 'platform' => 'Linux']
        ];

        $osInfo = $this->faker->randomElement($osVariants);

        return [
            'hostname' => 'DESKTOP-' . strtoupper(Str::random(6)),
            'client_id' => (string) Str::uuid(),
            'ip_address' => $this->faker->ipv4(),
            'username' => $this->faker->userName(),
            'custom_username' => null,
            'os_info' => $osInfo,
            'status' => 'active',
            'last_seen' => now()->subMinutes($this->faker->numberBetween(0, 180)),
            'first_seen' => now()->subDays($this->faker->numberBetween(1, 14)),
            'timezone' => 'Asia/Jakarta',
            'current_version' => '1.0.' . $this->faker->numberBetween(0, 5),
            'last_video_sequence' => null,
            'last_video_chunk' => null,
            'last_video_timestamp' => null,
        ];
    }

    public function offline(): self
    {
        return $this->state(function () {
            return [
                'status' => 'offline',
                'last_seen' => now()->subHours($this->faker->numberBetween(6, 48)),
            ];
        });
    }
}
