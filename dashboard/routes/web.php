<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\Auth\AuthController;

// Authentication routes (public)
Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Protected dashboard routes (require authentication)
Route::middleware(['auth'])->group(function () {
    // Dashboard routes
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/client/{clientId}/details', [DashboardController::class, 'clientDetails'])->name('client.details');
    Route::get('/client/{clientId}/live', [DashboardController::class, 'clientLive'])->name('client.live');

    // Activity pages
    Route::get('/screenshots', [DashboardController::class, 'screenshots'])->name('screenshots');
    Route::get('/client-summary', [DashboardController::class, 'clientSummary'])->name('dashboard.client-summary');

    // Export
    Route::get('/activities/export', [DashboardController::class, 'exportActivities'])->name('activities.export');
    Route::get('/export-report', [DashboardController::class, 'exportReport'])->name('export.report');
});
