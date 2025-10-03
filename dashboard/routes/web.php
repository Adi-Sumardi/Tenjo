<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\Auth\AuthController;

// Authentication routes (public)
Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth')->name('logout');

// Public dashboard routes
Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
Route::get('/client/{clientId}/details', [DashboardController::class, 'clientDetails'])->name('client.details');
Route::get('/client/{clientId}/live', [DashboardController::class, 'clientLive'])->name('client.live');

// Activity pages (public view)
Route::get('/screenshots', [DashboardController::class, 'screenshots'])->name('screenshots');
Route::get('/client-summary', [DashboardController::class, 'clientSummary'])->name('dashboard.client-summary');

// Statistics API endpoints
Route::get('/api/client/{clientId}/browser-usage', [DashboardController::class, 'browserUsageStats'])->name('api.browser-usage');
Route::get('/api/client/{clientId}/url-duration', [DashboardController::class, 'urlDurationStats'])->name('api.url-duration');

// Export endpoints
Route::get('/activities/export', [DashboardController::class, 'exportActivities'])->name('activities.export');
Route::get('/export-report', [DashboardController::class, 'exportReport'])->name('export.report');

// Dashboard API routes
Route::prefix('api')->group(function () {
    Route::get('/clients/status', function () {
        $clients = \App\Models\Client::all()->map(function($client) {
            return [
                'client_id' => $client->client_id,
                'is_online' => $client->isOnline(),
                'last_seen_human' => $client->last_seen ? $client->last_seen->diffForHumans() : 'Never'
            ];
        });
        return response()->json($clients);
    })->name('api.clients.status');

    Route::get('/clients/{clientId}', [\App\Http\Controllers\Api\ClientController::class, 'show'])
        ->name('api.clients.show');

    Route::middleware('auth')->group(function () {
        Route::put('/clients/{clientId}/username', [\App\Http\Controllers\Api\ClientController::class, 'updateUsername'])->name('api.clients.updateUsername');
        Route::delete('/clients/{clientId}', [\App\Http\Controllers\Api\ClientController::class, 'deleteClient'])->name('api.clients.delete');
    });
});
