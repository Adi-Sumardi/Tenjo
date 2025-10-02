# Admin User Setup Guide

## Quick Admin Creation

### Method 1: Automated (via deployment script)
The `vps_deploy_commands.sh` script automatically creates admin user at Step 6.

**Credentials:**
- Email: `admin@tenjo.local`
- Password: `TenjoAdmin2025!`

### Method 2: Manual via Tinker

```bash
cd /var/www/Tenjo/dashboard

php artisan tinker
```

Then run:
```php
$user = App\Models\User::create([
    'name' => 'Tenjo Admin',
    'email' => 'admin@tenjo.local',
    'password' => bcrypt('TenjoAdmin2025!'),
    'email_verified_at' => now()
]);

echo "✅ Admin created: " . $user->email . PHP_EOL;
exit
```

### Method 3: Custom Password

```bash
php artisan tinker
```

```php
$user = App\Models\User::create([
    'name' => 'Your Name',
    'email' => 'your-email@domain.com',
    'password' => bcrypt('YourSecurePassword123!'),
    'email_verified_at' => now()
]);

echo "✅ Admin created!" . PHP_EOL;
exit
```

---

## Check Existing Admin

```bash
php artisan tinker --execute="
\$users = \App\Models\User::all();
echo 'Total users: ' . \$users->count() . PHP_EOL;
foreach (\$users as \$user) {
    echo '  - ' . \$user->email . ' (' . \$user->name . ')' . PHP_EOL;
}
"
```

---

## Reset Admin Password

```bash
php artisan tinker
```

```php
$user = App\Models\User::where('email', 'admin@tenjo.local')->first();
$user->password = bcrypt('NewPassword123!');
$user->save();

echo "✅ Password updated!" . PHP_EOL;
exit
```

---

## Login Access

### Local Testing (HTTP):
```
http://103.129.149.67/login
```

### Production (HTTPS - after SSL setup):
```
https://tenjo.adilabs.id/login
```

**Default Credentials:**
- Email: `admin@tenjo.local`
- Password: `TenjoAdmin2025!`

⚠️ **IMPORTANT**: Change password after first login!

---

## Troubleshooting

### User Model Not Found?

Check if users table exists:
```bash
PGPASSWORD="tenjo_secure_2025" psql -h 127.0.0.1 -U tenjo_user -d tenjo_production -c "\dt users"
```

If not exists, run migrations:
```bash
php artisan migrate
```

### Can't Login?

1. Check user exists:
```bash
php artisan tinker --execute="
echo \App\Models\User::where('email', 'admin@tenjo.local')->exists() ? 'User exists' : 'User NOT found';
"
```

2. Verify email is verified:
```bash
php artisan tinker
```
```php
$user = App\Models\User::where('email', 'admin@tenjo.local')->first();
$user->email_verified_at = now();
$user->save();
echo "✅ Email verified!" . PHP_EOL;
exit
```

3. Check Laravel logs:
```bash
tail -50 /var/www/Tenjo/dashboard/storage/logs/laravel.log
```

---

## Security Best Practices

### 1. Change Default Password Immediately
```bash
php artisan tinker
```
```php
$user = App\Models\User::where('email', 'admin@tenjo.local')->first();
$user->password = bcrypt('YourVerySecurePassword123!@#');
$user->save();
```

### 2. Use Strong Passwords
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, symbols
- Don't use common words or patterns

### 3. Enable 2FA (if available)
Check if Fortify or Jetstream is installed:
```bash
php artisan route:list | grep two-factor
```

### 4. Regular Password Changes
Change admin password every 3-6 months.

---

## Multiple Admin Users

Create additional admins:
```bash
php artisan tinker
```
```php
$admin2 = App\Models\User::create([
    'name' => 'Second Admin',
    'email' => 'admin2@tenjo.local',
    'password' => bcrypt('SecurePassword123!'),
    'email_verified_at' => now()
]);

echo "✅ Second admin created!" . PHP_EOL;
exit
```

---

## Quick Reference Commands

```bash
# Create admin
php artisan tinker --execute="App\Models\User::create(['name' => 'Admin', 'email' => 'admin@tenjo.local', 'password' => bcrypt('password'), 'email_verified_at' => now()]);"

# List all users
php artisan tinker --execute="App\Models\User::all()->each(fn(\$u) => print(\$u->email . PHP_EOL));"

# Delete user
php artisan tinker --execute="App\Models\User::where('email', 'admin@tenjo.local')->delete();"

# Reset password
php artisan tinker --execute="\$u = App\Models\User::where('email', 'admin@tenjo.local')->first(); \$u->password = bcrypt('newpass'); \$u->save();"
```
