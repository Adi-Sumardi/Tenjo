<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class UrlActivity extends Model
{
    protected $fillable = [
        'client_id',
        'browser_session_id',
        'url',
        'domain',
        'page_title',
        'tab_id',
        'visit_start',
        'visit_end',
        'duration',
        'scroll_depth',
        'clicks',
        'keystrokes',
        'is_active',
        'referrer_url',
        'metadata',
        'activity_category',  // FIX: Add missing field for categorization (YouTube, games, etc.)
    ];

    protected $casts = [
        'visit_start' => 'datetime',
        'visit_end' => 'datetime',
        'metadata' => 'array',
        'is_active' => 'boolean',
    ];

    /**
     * Get the browser session that owns this URL activity
     */
    public function browserSession(): BelongsTo
    {
        return $this->belongsTo(BrowserSession::class);
    }

    /**
     * Get the client that owns this URL activity
     */
    public function client()
    {
        return $this->belongsTo(Client::class, 'client_id', 'client_id');
    }

    /**
     * Update visit duration
     */
    public function updateDuration()
    {
        if ($this->visit_start && $this->visit_end) {
            $this->duration = $this->visit_start->diffInSeconds($this->visit_end);
            $this->save();
        }
    }

    /**
     * End the URL visit
     */
    public function endVisit()
    {
        $this->visit_end = now();
        $this->is_active = false;
        $this->updateDuration();
    }

    /**
     * Get formatted duration
     */
    public function getFormattedDurationAttribute()
    {
        return gmdate('H:i:s', $this->duration);
    }

    /**
     * Get domain from URL
     */
    public static function extractDomain($url)
    {
        $parsed = parse_url($url);
        return $parsed['host'] ?? 'unknown';
    }
}
