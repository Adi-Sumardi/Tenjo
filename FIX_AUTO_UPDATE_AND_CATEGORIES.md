# 🔧 FIX: Auto-Update & 3 Kategori KPI

**Issues Found:**
1. ❌ Auto-update tidak berfungsi - client tidak check updates
2. ❌ Client summary tidak menampilkan 3 kategori (Work, Social Media, Suspicious)

**Status:** 🔴 CRITICAL - Both features broken

---

## 🎯 ISSUE #1: AUTO-UPDATE TIDAK BERFUNGSI

### Root Causes:

**1. Config Missing AUTO_UPDATE Settings**
```python
# /app/client/src/core/config.py
# MISSING:
AUTO_UPDATE_ENABLED = True
AUTO_UPDATE_CHECK_INTERVAL = 86400  # 24 hours
```

**2. main.py Tidak Call Auto-Update Check**
```python
# /app/client/main.py line 336-350
# Only checks file integrity, NOT updates!
updater = ClientUpdater(Config)
if not updater.check_file_integrity():  # Only integrity check
    ...

# MISSING:
# updater.check_and_apply_updates()  # Should check for updates
```

**3. Server-Side Update Endpoint Mungkin Belum di-Deploy**
- UpdateController.php created ✓
- Routes registered ✓
- BUT: Update package belum di-upload
- CLIENT_VERSION di .env belum di-set

---

## 🎯 ISSUE #2: 3 KATEGORI TIDAK DITAMPILKAN

### Root Causes:

**1. DashboardController Tidak Query Category Stats**
```php
// Line 314-328: Query url stats
$urlStats = UrlActivity::whereBetween('visit_start', [$from, $to])
    ->select(
        'client_id',
        DB::raw('count(*) as activities_count'),
        // ... other stats
    )
    ->groupBy('client_id')
    ->get();

// MISSING: activity_category aggregation!
// No: DB::raw('sum(case when activity_category = "work" then 1 else 0 end) as work_count')
```

**2. View Tidak Display Category Stats**
```blade
// client-summary.blade.php
// Only shows: screenshots, browser_sessions, url_activities
// MISSING: work activities, social media, suspicious
```

**3. No Visual Indicators**
- No color coding
- No icons for categories
- No percentage breakdown

---

## ✅ FIXES REQUIRED

### Fix #1: Enable Auto-Update in Client

**A. Add Config Settings**
File: `/app/client/src/core/config.py`

```python
# Auto-Update Configuration (after line 181)
AUTO_UPDATE_ENABLED = True
AUTO_UPDATE_CHECK_INTERVAL = 86400  # Check every 24 hours
AUTO_UPDATE_RANDOMIZE = True  # Randomize check time
AUTO_UPDATE_EXECUTION_WINDOWS = [
    {"start": "22:00", "end": "06:00"}  # Update between 10pm-6am
]
```

**B. Add Update Check in main.py**
File: `/app/client/main.py`

```python
# After line 350, add:

# AUTO-UPDATE v2: Check for updates
if getattr(Config, 'AUTO_UPDATE_ENABLED', False):
    try:
        from src.utils.auto_update import ClientUpdater
        updater = ClientUpdater(Config)
        
        # Check for updates in background thread
        import threading
        def check_updates():
            try:
                updater.check_and_apply_updates()
            except Exception as e:
                logging.error(f"Auto-update check failed: {e}")
        
        update_thread = threading.Thread(target=check_updates, daemon=True)
        update_thread.start()
        
        if not Config.STEALTH_MODE:
            print(f"Auto-update enabled. Current version: {Config.VERSION}")
    except Exception as e:
        logging.error(f"Failed to initialize auto-updater: {e}")
```

---

### Fix #2: Add Category Stats to Dashboard

**A. Update DashboardController.php**
File: `/app/dashboard/app/Http/Controllers/DashboardController.php`

```php
// Replace line 313-321 with:
$urlStats = UrlActivity::whereBetween('visit_start', [$from, $to])
    ->select(
        'client_id',
        DB::raw('count(*) as activities_count'),
        DB::raw('count(distinct url) as unique_urls_count'),
        DB::raw('sum(duration) as total_duration_sum'),
        // ADD CATEGORY STATS:
        DB::raw('sum(case when activity_category = "work" then 1 else 0 end) as work_count'),
        DB::raw('sum(case when activity_category = "social_media" then 1 else 0 end) as social_count'),
        DB::raw('sum(case when activity_category = "suspicious" then 1 else 0 end) as suspicious_count'),
        DB::raw('sum(case when activity_category = "work" then duration else 0 end) as work_duration'),
        DB::raw('sum(case when activity_category = "social_media" then duration else 0 end) as social_duration'),
        DB::raw('sum(case when activity_category = "suspicious" then duration else 0 end) as suspicious_duration')
    )
    ->groupBy('client_id')
    ->get()->keyBy('client_id');
```

**B. Update Client Stats Mapping**
```php
// Update line 336-349 to include categories:
return [
    'client' => $client,
    'stats' => [
        'screenshots' => $screenshotStats->get($client->client_id) ?? 0,
        'browser_sessions' => $sessionStats->get($client->client_id)?->count ?? 0,
        'url_activities' => $urlStats->get($client->client_id)?->activities_count ?? 0,
        'unique_urls' => $urlStats->get($client->client_id)?->unique_urls_count ?? 0,
        'total_duration_minutes' => round(($urlStats->get($client->client_id)?->total_duration_sum ?? 0) / 60, 1),
        
        // ADD CATEGORY STATS:
        'work_count' => $urlStats->get($client->client_id)?->work_count ?? 0,
        'social_count' => $urlStats->get($client->client_id)?->social_count ?? 0,
        'suspicious_count' => $urlStats->get($client->client_id)?->suspicious_count ?? 0,
        'work_duration_minutes' => round(($urlStats->get($client->client_id)?->work_duration ?? 0) / 60, 1),
        'social_duration_minutes' => round(($urlStats->get($client->client_id)?->social_duration ?? 0) / 60, 1),
        'suspicious_duration_minutes' => round(($urlStats->get($client->client_id)?->suspicious_duration ?? 0) / 60, 1),
        
        // Calculate percentages
        'work_percentage' => $this->calculatePercentage(
            $urlStats->get($client->client_id)?->work_count ?? 0,
            $urlStats->get($client->client_id)?->activities_count ?? 0
        ),
        'social_percentage' => $this->calculatePercentage(
            $urlStats->get($client->client_id)?->social_count ?? 0,
            $urlStats->get($client->client_id)?->activities_count ?? 0
        ),
        'suspicious_percentage' => $this->calculatePercentage(
            $urlStats->get($client->client_id)?->suspicious_count ?? 0,
            $urlStats->get($client->client_id)?->activities_count ?? 0
        ),
        
        'top_domains' => $topDomainsString,
        'last_activity' => $client->last_seen ? Carbon::parse($client->last_seen)->diffForHumans() : 'Never',
        'status' => $client->isOnline() ? 'Online' : 'Offline'
    ]
];
```

**C. Add Helper Method**
```php
// Add to DashboardController class:
private function calculatePercentage($part, $total)
{
    if ($total == 0) return 0;
    return round(($part / $total) * 100, 1);
}
```

---

### Fix #3: Update Client Summary View

**A. Add Category Stats Cards**
File: `/app/dashboard/resources/views/dashboard/client-summary.blade.php`

```blade
<!-- Add after line 100 (after online clients card) -->
<div class="col-md-2">
    <div class="card stats-card h-100">
        <div class="card-body text-center">
            <div class="stats-icon bg-success mx-auto mb-2">
                <i class="fas fa-briefcase"></i>
            </div>
            <h3 class="mb-1">{{ number_format($overallStats['total_work_activities'] ?? 0) }}</h3>
            <small class="text-muted">Work Activities</small>
        </div>
    </div>
</div>
<div class="col-md-2">
    <div class="card stats-card h-100">
        <div class="card-body text-center">
            <div class="stats-icon bg-warning mx-auto mb-2">
                <i class="fas fa-users"></i>
            </div>
            <h3 class="mb-1">{{ number_format($overallStats['total_social_activities'] ?? 0) }}</h3>
            <small class="text-muted">Social Media</small>
        </div>
    </div>
</div>
<div class="col-md-2">
    <div class="card stats-card h-100">
        <div class="card-body text-center">
            <div class="stats-icon bg-danger mx-auto mb-2">
                <i class="fas fa-exclamation-triangle"></i>
            </div>
            <h3 class="mb-1">{{ number_format($overallStats['total_suspicious_activities'] ?? 0) }}</h3>
            <small class="text-muted">Suspicious</small>
        </div>
    </div>
</div>
```

**B. Add Category Columns to Table**
```blade
<!-- Find table headers (around line 150), add after URL Activities column: -->
<th>Work</th>
<th>Social Media</th>
<th>Suspicious</th>
<th>Productivity</th>

<!-- Add data cells (around line 180): -->
<td>
    <span class="badge bg-success">
        {{ $item['stats']['work_count'] }} ({{ $item['stats']['work_percentage'] }}%)
    </span>
    <br><small class="text-muted">{{ $item['stats']['work_duration_minutes'] }}m</small>
</td>
<td>
    <span class="badge bg-warning">
        {{ $item['stats']['social_count'] }} ({{ $item['stats']['social_percentage'] }}%)
    </span>
    <br><small class="text-muted">{{ $item['stats']['social_duration_minutes'] }}m</small>
</td>
<td>
    <span class="badge bg-danger">
        {{ $item['stats']['suspicious_count'] }} ({{ $item['stats']['suspicious_percentage'] }}%)
    </span>
    <br><small class="text-muted">{{ $item['stats']['suspicious_duration_minutes'] }}m</small>
</td>
<td>
    <div class="progress" style="height: 20px;">
        <div class="progress-bar bg-success" style="width: {{ $item['stats']['work_percentage'] }}%" 
             title="Work: {{ $item['stats']['work_percentage'] }}%">
            {{ $item['stats']['work_percentage'] > 10 ? $item['stats']['work_percentage'].'%' : '' }}
        </div>
        <div class="progress-bar bg-warning" style="width: {{ $item['stats']['social_percentage'] }}%"
             title="Social: {{ $item['stats']['social_percentage'] }}%">
            {{ $item['stats']['social_percentage'] > 10 ? $item['stats']['social_percentage'].'%' : '' }}
        </div>
        <div class="progress-bar bg-danger" style="width: {{ $item['stats']['suspicious_percentage'] }}%"
             title="Suspicious: {{ $item['stats']['suspicious_percentage'] }}%">
            {{ $item['stats']['suspicious_percentage'] > 10 ? $item['stats']['suspicious_percentage'].'%' : '' }}
        </div>
    </div>
</td>
```

---

### Fix #4: Calculate Overall Stats with Categories

**Update DashboardController clientSummary()**

```php
// After line 350, calculate overall stats:
$overallStats = [
    'total_clients' => $clients->count(),
    'online_clients' => $clients->where('stats.status', 'Online')->count(),
    'total_screenshots' => $clients->sum('stats.screenshots'),
    'total_browser_sessions' => $clients->sum('stats.browser_sessions'),
    'total_url_activities' => $clients->sum('stats.url_activities'),
    'total_duration_hours' => round($clients->sum('stats.total_duration_minutes') / 60, 1),
    
    // ADD CATEGORY TOTALS:
    'total_work_activities' => $clients->sum('stats.work_count'),
    'total_social_activities' => $clients->sum('stats.social_count'),
    'total_suspicious_activities' => $clients->sum('stats.suspicious_count'),
    'total_work_duration_hours' => round($clients->sum('stats.work_duration_minutes') / 60, 1),
    'total_social_duration_hours' => round($clients->sum('stats.social_duration_minutes') / 60, 1),
    'total_suspicious_duration_hours' => round($clients->sum('stats.suspicious_duration_minutes') / 60, 1),
];
```

---

## 🧪 TESTING CHECKLIST

### Test Auto-Update:

1. **Server Side:**
```bash
# Check if controller exists
php artisan route:list | grep updates

# Should show:
# POST /api/updates/check
# GET  /api/updates/download/{version}
# POST /api/updates/status

# Set CLIENT_VERSION
echo "CLIENT_VERSION=2.0.0" >> .env
php artisan config:cache

# Create test update package
cd /app/client
tar -czf update-2.0.1.tar.gz VERSION main.py src/
sha256sum update-2.0.1.tar.gz > update-2.0.1.sha256

# Upload to server
scp update-2.0.1.* server:/path/to/dashboard/storage/app/updates/
```

2. **Client Side:**
```python
# Test update check manually
cd C:\ProgramData\Microsoft\Office365Sync_XXXX
python -c "from src.core.config import Config; from src.utils.auto_update import ClientUpdater; u = ClientUpdater(Config); u.check_and_apply_updates()"

# Should output:
# Checking for updates...
# Current version: 1.0.3
# Latest version: 2.0.0
# Update available!
```

---

### Test 3 Kategori:

1. **Generate Test Data:**
```php
php artisan tinker

# Create test URL activities with categories
$client = \App\Models\Client::first();
$categorizer = new \App\Services\ActivityCategorizerService();

# Work activity
\App\Models\UrlActivity::create([
    'client_id' => $client->client_id,
    'url' => 'https://gmail.com',
    'domain' => 'gmail.com',
    'page_title' => 'Gmail',
    'activity_category' => 'work',
    'duration' => 300,
    'visit_start' => now(),
]);

# Social media activity
\App\Models\UrlActivity::create([
    'client_id' => $client->client_id,
    'url' => 'https://youtube.com/watch?v=123',
    'domain' => 'youtube.com',
    'page_title' => 'YouTube',
    'activity_category' => 'social_media',
    'duration' => 600,
    'visit_start' => now(),
]);

# Suspicious activity
\App\Models\UrlActivity::create([
    'client_id' => $client->client_id,
    'url' => 'https://gambling-site.com',
    'domain' => 'gambling-site.com',
    'page_title' => 'Casino',
    'activity_category' => 'suspicious',
    'duration' => 180,
    'visit_start' => now(),
]);
```

2. **View Client Summary:**
```
Navigate to: /dashboard/client-summary

Should show:
- Work Activities card (green)
- Social Media card (orange/warning)
- Suspicious card (red)
- Table with category columns
- Progress bar showing distribution
```

---

## 📝 IMPLEMENTATION PRIORITY

### Priority 1: Enable Auto-Update (30 min)
1. Add config to config.py
2. Add check in main.py
3. Upload update package to server
4. Test update check

### Priority 2: Add Category Stats (45 min)
1. Update DashboardController query
2. Add category stats to response
3. Update view with new columns
4. Test with sample data

### Priority 3: Visual Improvements (15 min)
1. Add category icons
2. Add color coding
3. Add tooltips
4. Test responsiveness

---

## ✅ SUCCESS CRITERIA

**Auto-Update:**
- [x] Config.AUTO_UPDATE_ENABLED = True
- [ ] main.py calls check_and_apply_updates()
- [ ] Server has update package
- [ ] Client checks for updates daily
- [ ] Update applies successfully (test)

**3 Kategori:**
- [ ] DashboardController queries category stats
- [ ] View displays 3 category cards
- [ ] Table shows Work/Social/Suspicious columns
- [ ] Progress bar shows distribution
- [ ] Colors: Green (Work), Orange (Social), Red (Suspicious)
- [ ] Tooltips show details

---

**Status:** Ready for implementation  
**Estimated Time:** 1.5 hours  
**Risk:** LOW - Isolated changes, can rollback easily

