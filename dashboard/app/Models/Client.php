<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Carbon\Carbon;

class Client extends Model
{
    use HasFactory;
    protected $fillable = [
        'hostname',
        'client_id',
        'ip_address',
        'username',
        'custom_username',
        'os_info',
        'status',
        'last_seen',
        'first_seen',
        'timezone'
    ];

    protected $casts = [
        'os_info' => 'array',
        'last_seen' => 'datetime',
        'first_seen' => 'datetime'
    ];

    public function screenshots(): HasMany
    {
        return $this->hasMany(Screenshot::class, 'client_id', 'client_id');
    }

    // Enhanced tracking relationships - using client_id (UUID) as foreign key
    public function browserSessions(): HasMany
    {
        return $this->hasMany(BrowserSession::class, 'client_id', 'client_id');
    }

    public function urlActivities(): HasMany
    {
        return $this->hasMany(UrlActivity::class, 'client_id', 'client_id');
    }

    public function isOnline(): bool
    {
        if (!$this->last_seen) {
            return false;
        }

        return $this->last_seen->diffInMinutes(now()) <= 5;
    }

    public function getStatusAttribute(): string
    {
        if ($this->isOnline()) {
            return 'active';
        }

        return 'offline';
    }

    public function updateLastSeen(): void
    {
        $this->update([
            'last_seen' => now(),
            'status' => 'active'
        ]);
    }

    public function getTodayScreenshots()
    {
        return $this->screenshots()
            ->whereDate('captured_at', today())
            ->orderBy('captured_at', 'desc');
    }

    public function getTodayBrowserActivity()
    {
        return $this->browserSessions()
            ->whereDate('created_at', today())
            ->orderBy('created_at', 'desc');
    }

    public function getTodayProcessActivity()
    {
        // Process events not implemented yet
        return collect([]);
    }

    public function getOsDisplayName(): string
    {
        if (!$this->os_info || !is_array($this->os_info)) {
            return 'Unknown';
        }

        $name = $this->os_info['name'] ?? 'Unknown';
        $version = $this->os_info['version'] ?? '';
        $platform = $this->os_info['platform'] ?? '';

        if ($version) {
            return $name . ' ' . $version;
        }

        return $name;
    }

    public function getOsPlatform(): string
    {
        if (!$this->os_info || !is_array($this->os_info)) {
            return 'Unknown';
        }

        return $this->os_info['platform'] ?? $this->os_info['name'] ?? 'Unknown';
    }

    /**
     * Get the display username (custom if set, otherwise original)
     */
    public function getDisplayUsername(): string
    {
        return $this->custom_username ?: $this->username;
    }

    /**
     * Update custom username
     */
    public function updateCustomUsername(string $customUsername): bool
    {
        $this->custom_username = $customUsername;
        return $this->save();
    }
}
