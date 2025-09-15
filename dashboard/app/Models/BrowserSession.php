<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Carbon\Carbon;

class BrowserSession extends Model
{
    protected $fillable = [
        'client_id',
        'browser_name',
        'browser_version',
        'browser_executable_path',
        'window_count',
        'tab_count',
        'session_start',
        'session_end',
        'total_duration',
        'is_active',
        'window_titles',
    ];

    protected $casts = [
        'session_start' => 'datetime',
        'session_end' => 'datetime',
        'window_titles' => 'array',
        'is_active' => 'boolean',
    ];

    /**
     * Get the URL activities for this browser session
     */
    public function urlActivities(): HasMany
    {
        return $this->hasMany(UrlActivity::class);
    }

    /**
     * Get the client that owns this browser session
     */
    public function client()
    {
        return $this->belongsTo(Client::class, 'client_id', 'client_id');
    }

    /**
     * Update session duration
     */
    public function updateDuration()
    {
        if ($this->session_start && $this->session_end) {
            $this->total_duration = $this->session_start->diffInSeconds($this->session_end);
            $this->save();
        }
    }

    /**
     * End the browser session
     */
    public function endSession()
    {
        $this->session_end = now();
        $this->is_active = false;
        $this->updateDuration();
    }

    /**
     * Get formatted duration
     */
    public function getFormattedDurationAttribute()
    {
        return gmdate('H:i:s', $this->total_duration);
    }
}
