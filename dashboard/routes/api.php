<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ClientController;
use App\Http\Controllers\Api\ScreenshotController;
use App\Http\Controllers\Api\BrowserSessionController;
use App\Http\Controllers\Api\UrlActivityController;
use App\Http\Controllers\StreamController;
use App\Http\Controllers\BrowserTrackingController;

// Public routes (no authentication required)
// Health check - public for monitoring
Route::get('/health', [ClientController::class, 'health']);

// ============================================================================
// CLIENT OPERATIONS - NO RATE LIMITING (clients need unrestricted access)
// ============================================================================

// Streaming endpoints - NO throttling for smooth video streaming
Route::prefix('stream')->group(function () {
    // Client endpoints - unlimited for 30+ fps video streaming
    Route::get('/request/{clientId}', [StreamController::class, 'getStreamRequest']);
    Route::post('/chunk/{clientId}', [StreamController::class, 'uploadStreamChunk']);
    Route::get('/status/{clientId}', [StreamController::class, 'getStreamStatus']);

    // Dashboard endpoints - NO AUTH for local testing, add auth later for production
    Route::post('/start/{clientId}', [StreamController::class, 'startStream']);
    Route::post('/stop/{clientId}', [StreamController::class, 'stopStream']);
    Route::get('/latest/{clientId}', [StreamController::class, 'getLatestChunk']);
    Route::get('/video/{clientId}', [StreamController::class, 'getVideoStream']);
});

// Client registration and heartbeat - NO throttling (critical for monitoring)
Route::prefix('clients')->group(function () {
    Route::post('/register', [ClientController::class, 'register']);
    Route::post('/heartbeat', [ClientController::class, 'heartbeat']);

    // Silent update endpoints - NO AUTH (clients check automatically)
    Route::get('/{clientId}/check-update', [ClientController::class, 'checkUpdate']);
    Route::post('/{clientId}/update-completed', [ClientController::class, 'updateCompleted']);

    // Protected routes - require authentication
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/', [ClientController::class, 'index']);
        Route::get('/{clientId}', [ClientController::class, 'show']);
        Route::get('/{clientId}/settings', [ClientController::class, 'getSettings']);
        Route::get('/{clientId}/latest-screenshot', [ClientController::class, 'getLatestScreenshot']);
        Route::put('/{clientId}/status', [ClientController::class, 'updateStatus']);
    });
});

// Screenshot upload - NO throttling (clients upload every 5 minutes)
Route::prefix('screenshots')->group(function () {
    Route::post('/', [ScreenshotController::class, 'store']);
    Route::post('/upload', [ScreenshotController::class, 'upload']);

    // NO AUTH for local testing - fetch screenshots by client
    Route::get('/', [ScreenshotController::class, 'index']);
    Route::get('/{screenshot}', [ScreenshotController::class, 'show']);

    // View/manage endpoints - require authentication
    Route::middleware('auth:sanctum')->group(function () {
        Route::delete('/{screenshot}', [ScreenshotController::class, 'destroy']);
    });
});

// Enhanced Browser Tracking - NO throttling (continuous monitoring)
Route::prefix('browser-tracking')->group(function () {
    Route::post('/', [BrowserTrackingController::class, 'storeBrowserTracking']);
    Route::middleware('auth:sanctum')->get('/{clientId}/summary', [BrowserTrackingController::class, 'getBrowserSummary']);
});

Route::prefix('browser-sessions')->group(function () {
    Route::get('/', [BrowserSessionController::class, 'index']);
    Route::get('/{browserSession}', [BrowserSessionController::class, 'show']);
    Route::post('/', [BrowserTrackingController::class, 'storeBrowserSession']);
});

Route::prefix('url-activities')->group(function () {
    Route::get('/', [UrlActivityController::class, 'index']);
    Route::get('/{urlActivity}', [UrlActivityController::class, 'show']);
    Route::post('/', [BrowserTrackingController::class, 'storeUrlActivity']);
});

// System stats - NO throttling (continuous monitoring)
Route::post('/system-stats', function (Request $request) {
    $request->validate(['client_id' => 'required|string']);

    return response()->json([
        'success' => true,
        'message' => 'System stats received'
    ]);
});

// ============================================================================
// DASHBOARD OPERATIONS - WITH AUTHENTICATION & RATE LIMITING
// ============================================================================

// Activity export - requires authentication + rate limiting
Route::middleware(['auth:sanctum', 'throttle:60,1'])->get('/activities/export', [ClientController::class, 'exportActivities']);

// Protected routes (with Sanctum authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
