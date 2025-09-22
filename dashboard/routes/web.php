<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;

// Dashboard routes
Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
Route::get('/client/{clientId}/details', [DashboardController::class, 'clientDetails'])->name('client.details');
Route::get('/client/{clientId}/live', [DashboardController::class, 'clientLive'])->name('client.live');

// Activity pages
Route::get('/history-activity', [DashboardController::class, 'historyActivity'])->name('history.activity');
Route::get('/screenshots', [DashboardController::class, 'screenshots'])->name('screenshots');
Route::get('/browser-activity', [DashboardController::class, 'browserActivity'])->name('browser.activity');
Route::get('/url-activity', [DashboardController::class, 'urlActivity'])->name('url.activity');
Route::get('/client-summary', [DashboardController::class, 'clientSummary'])->name('dashboard.client-summary');

// Export
Route::get('/activities/export', [DashboardController::class, 'exportActivities'])->name('activities.export');
Route::get('/export-report', [DashboardController::class, 'exportReport'])->name('export.report');
