<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ClientController;
use App\Http\Controllers\Api\ScreenshotController;
use App\Http\Controllers\Api\BrowserEventController;
use App\Http\Controllers\Api\ProcessEventController;
use App\Http\Controllers\Api\UrlEventController;
use App\Http\Controllers\StreamController;
use App\Http\Controllers\BrowserTrackingController;

// Public routes (no authentication required)
// Health check - public for monitoring
Route::get('/health', [ClientController::class, 'health']);

// Streaming endpoints with HIGH rate limiting (OUTSIDE throttle:api group)
Route::prefix('stream')->group(function () {
    // Client endpoints - allow higher rate for video streaming
    Route::middleware('throttle:240,1')->group(function () {
        Route::get('/request/{clientId}', [StreamController::class, 'getStreamRequest']);
        Route::post('/chunk/{clientId}', [StreamController::class, 'uploadStreamChunk']);
        Route::get('/status/{clientId}', [StreamController::class, 'getStreamStatus']);
    });

    // Dashboard endpoints - NO AUTH for local testing, add auth later for production
    Route::middleware('throttle:240,1')->group(function () {
        Route::post('/start/{clientId}', [StreamController::class, 'startStream']);
        Route::post('/stop/{clientId}', [StreamController::class, 'stopStream']);
        Route::get('/latest/{clientId}', [StreamController::class, 'getLatestChunk']);
        Route::get('/video/{clientId}', [StreamController::class, 'getVideoStream']);
    });
});

// Add CORS middleware with rate limiting for API security
Route::middleware(['throttle:api'])->group(function () {

// Activity export - requires authentication
Route::middleware('auth:sanctum')->get('/activities/export', [ClientController::class, 'exportActivities']);

// Client routes with authentication
Route::prefix('clients')->group(function () {
    // Client registration and heartbeat - use API key validation instead of sanctum
    Route::middleware('throttle:120,1')->post('/register', [ClientController::class, 'register']);
    Route::middleware('throttle:120,1')->post('/heartbeat', [ClientController::class, 'heartbeat']);

    // Protected routes - require authentication
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/', [ClientController::class, 'index']);
        Route::get('/{clientId}', [ClientController::class, 'show']);
        Route::get('/{clientId}/settings', [ClientController::class, 'getSettings']);
        Route::get('/{clientId}/latest-screenshot', [ClientController::class, 'getLatestScreenshot']);
        Route::put('/{clientId}/status', [ClientController::class, 'updateStatus']);

        // Client management routes
        Route::put('/{clientId}/username', [ClientController::class, 'updateUsername']);
        Route::delete('/{clientId}', [ClientController::class, 'deleteClient']);

        // Add status endpoint for dashboard
        Route::get('/status', function () {
            $clients = \App\Models\Client::all()->map(function($client) {
                return [
                    'client_id' => $client->client_id,
                    'is_online' => $client->isOnline(),
                    'last_seen_human' => $client->last_seen ? $client->last_seen->diffForHumans() : 'Never'
                ];
            });

            return response()->json($clients);
        });
    });
});

// Screenshot routes with rate limiting and authentication
Route::prefix('screenshots')->group(function () {
    // Upload endpoints - rate limited to prevent abuse (max 60 per minute)
    Route::middleware('throttle:60,1')->group(function () {
        Route::post('/', [ScreenshotController::class, 'store']);
        Route::post('/upload', [ScreenshotController::class, 'upload']);
    });

    // View/manage endpoints - require authentication
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/', [ScreenshotController::class, 'index']);
        Route::get('/{screenshot}', [ScreenshotController::class, 'show']);
        Route::delete('/{screenshot}', [ScreenshotController::class, 'destroy']);
    });
});

// Browser Events routes with rate limiting
Route::prefix('browser-events')->group(function () {
    Route::middleware('throttle:120,1')->post('/', [BrowserEventController::class, 'store']);
    Route::middleware('auth:sanctum')->get('/', [BrowserEventController::class, 'index']);
    Route::middleware('auth:sanctum')->get('/{event}', [BrowserEventController::class, 'show']);
});

// Process Events routes with rate limiting
Route::prefix('process-events')->group(function () {
    Route::middleware('throttle:120,1')->post('/', [ProcessEventController::class, 'store']);
    Route::middleware('auth:sanctum')->get('/', [ProcessEventController::class, 'index']);
    Route::middleware('auth:sanctum')->get('/{event}', [ProcessEventController::class, 'show']);
});

// URL Events routes with rate limiting
Route::prefix('url-events')->group(function () {
    Route::middleware('throttle:120,1')->post('/', [UrlEventController::class, 'store']);
    Route::middleware('auth:sanctum')->get('/', [UrlEventController::class, 'index']);
    Route::middleware('auth:sanctum')->get('/{event}', [UrlEventController::class, 'show']);
});

// Enhanced Browser Tracking routes with rate limiting
Route::prefix('browser-tracking')->group(function () {
    Route::middleware('throttle:120,1')->post('/', [BrowserTrackingController::class, 'storeBrowserTracking']);
    Route::middleware('auth:sanctum')->get('/{clientId}/summary', [BrowserTrackingController::class, 'getBrowserSummary']);
});

Route::prefix('browser-sessions')->group(function () {
    Route::middleware('throttle:120,1')->post('/', [BrowserTrackingController::class, 'storeBrowserSession']);
});

Route::prefix('url-activities')->group(function () {
    Route::middleware('throttle:120,1')->post('/', [BrowserTrackingController::class, 'storeUrlActivity']);
});

// System stats endpoint with rate limiting
Route::middleware('throttle:120,1')->post('/system-stats', function (Request $request) {
    $request->validate(['client_id' => 'required|string']);

    return response()->json([
        'success' => true,
        'message' => 'System stats received'
    ]);
});

// Protected routes (with Sanctum authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});

}); // End rate limiting middleware group
