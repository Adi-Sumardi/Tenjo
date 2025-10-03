<?php

namespace Tests\Feature;

use App\Models\Client;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class DashboardClientApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_fetch_client_details(): void
    {
        $user = User::factory()->create();
        $client = $this->createClient();

        $this->actingAs($user);

        $response = $this->get(route('api.clients.show', ['clientId' => $client->client_id]));

        $response->assertOk()
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonPath('client.client_id', $client->client_id)
            ->assertJsonPath('client.hostname', $client->hostname)
            ->assertJsonPath('client.status', 'active');
    }

    public function test_guest_can_fetch_client_details_without_authentication(): void
    {
        $client = $this->createClient();

        $response = $this->get(route('api.clients.show', ['clientId' => $client->client_id]));

        $response->assertOk()
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonPath('client.client_id', $client->client_id)
            ->assertJsonPath('client.hostname', $client->hostname)
            ->assertJsonPath('client.status', 'active');
    }

    public function test_authenticated_user_can_update_client_username(): void
    {
        $user = User::factory()->create();
        $client = $this->createClient();

        $response = $this->withSession(['_token' => 'test-token'])
            ->actingAs($user)
            ->withHeader('X-CSRF-TOKEN', 'test-token')
            ->putJson(route('api.clients.updateUsername', ['clientId' => $client->client_id]), [
                '_token' => 'test-token',
                'username' => 'Renamed Agent'
            ]);

        $response->assertOk()
            ->assertJsonPath('data.custom_username', 'Renamed Agent')
            ->assertJsonPath('data.display_username', 'Renamed Agent');

        $this->assertDatabaseHas('clients', [
            'client_id' => $client->client_id,
            'custom_username' => 'Renamed Agent',
        ]);
    }

    public function test_guest_cannot_update_client_username(): void
    {
        $client = $this->createClient();

        $response = $this->withSession(['_token' => 'test-token'])
            ->withHeader('X-CSRF-TOKEN', 'test-token')
            ->putJson(route('api.clients.updateUsername', ['clientId' => $client->client_id]), [
                '_token' => 'test-token',
            'username' => 'Guest Update Attempt'
        ]);

        $response->assertStatus(401);

        $this->assertDatabaseHas('clients', [
            'client_id' => $client->client_id,
            'custom_username' => null,
        ]);
    }

    public function test_authenticated_user_can_delete_client(): void
    {
        $user = User::factory()->create();
        $client = $this->createClient();

        $response = $this->withSession(['_token' => 'test-token'])
            ->actingAs($user)
            ->withHeader('X-CSRF-TOKEN', 'test-token')
            ->deleteJson(route('api.clients.delete', ['clientId' => $client->client_id]), [
                '_token' => 'test-token',
            ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseMissing('clients', [
            'client_id' => $client->client_id,
        ]);
    }

    private function createClient(): Client
    {
        return Client::create([
            'client_id' => (string) Str::uuid(),
            'hostname' => 'test-host',
            'ip_address' => '192.168.1.10',
            'username' => 'agent',
            'custom_username' => null,
            'os_info' => [
                'name' => 'Windows',
                'version' => '11',
                'platform' => 'Windows'
            ],
            'status' => 'active',
            'last_seen' => now(),
            'first_seen' => now()->subDay(),
            'timezone' => 'Asia/Jakarta',
        ]);
    }
}
