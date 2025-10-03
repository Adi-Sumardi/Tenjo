<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create or update default admin user
        $admin = User::updateOrCreate(
            ['email' => 'admin@tenjo.com'],
            [
                'name' => 'Admin',
                'password' => Hash::make('password123'), // Change this in production!
            ]
        );

        echo "Default admin user ready:\n";
        echo "Email: {$admin->email}\n";
        echo "Password: password123\n\n";
        echo "⚠️  IMPORTANT: Please change this password after first login!\n";

        if (app()->environment('local', 'testing')) {
            $this->call(ClientSeeder::class);
            echo "Sample client data generated for dashboard testing.\n";
        }
    }
}
