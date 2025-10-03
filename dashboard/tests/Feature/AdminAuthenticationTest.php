<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminAuthenticationTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_login_with_default_credentials(): void
    {
        $this->seed();

        $response = $this->withSession(['_token' => 'test-token'])
            ->post('/login', [
                '_token' => 'test-token',
            'email' => 'admin@tenjo.com',
            'password' => 'password123',
            ]);

        $response->assertRedirect(route('dashboard'));
        $this->assertAuthenticated();
        $this->assertAuthenticatedAs(User::where('email', 'admin@tenjo.com')->first());
    }

    public function test_invalid_credentials_are_rejected(): void
    {
        $this->seed();

        $response = $this->withSession(['_token' => 'test-token'])
            ->from(route('login'))
            ->post('/login', [
                '_token' => 'test-token',
            'email' => 'admin@tenjo.com',
            'password' => 'wrong-password',
            ]);

        $response->assertRedirect(route('login'))
            ->assertSessionHasErrors('email');

        $this->assertGuest();
    }
}
