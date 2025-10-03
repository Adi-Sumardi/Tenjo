<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        then: function () {
            // Configure rate limiters after routes are loaded
            RateLimiter::for('api', function (Request $request) {
                return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
            });
        },
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Add custom CORS middleware for API routes
        $middleware->api(prepend: [
            \App\Http\Middleware\HandleApiCors::class,
        ]);

        // Add middleware for production API compatibility
        $middleware->appendToGroup('api', [
            \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
            \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Return JSON for API 429 errors instead of HTML
        $exceptions->render(function (\Illuminate\Http\Exceptions\ThrottleRequestsException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => 'Too many requests',
                    'message' => 'Please slow down and try again in a few seconds.',
                    'retry_after' => $e->getHeaders()['Retry-After'] ?? null,
                ], 429, $e->getHeaders());
            }
        });

        // Return JSON for authentication errors (401)
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => 'Authentication required',
                    'message' => 'Unauthenticated.',
                ], 401);
            }
        });

        // Return JSON for general API errors
        $exceptions->render(function (\Throwable $e, Request $request) {
            if ($request->is('api/*') && !config('app.debug')) {
                return response()->json([
                    'error' => 'Server error',
                    'message' => $e->getMessage(),
                ], 500);
            }
        });
    })->create();
