<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create default admin user
        User::create([
            'name' => 'Admin',
            'email' => 'admin@tenjo.com',
            'password' => bcrypt('password123'), // Change this in production!
        ]);

        echo "Default admin user created:\n";
        echo "Email: admin@tenjo.com\n";
        echo "Password: password123\n\n";
        echo "⚠️  IMPORTANT: Please change this password after first login!\n";
    }
}
