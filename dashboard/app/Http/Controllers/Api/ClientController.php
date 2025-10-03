<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Traits\ClientValidation;
use App\Models\Client;
use App\Models\Screenshot;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Validator;

class ClientController extends Controller
{
    use ClientValidation;
    public function register(Request $request): JsonResponse
    {
        try {
            $request->validate([
                'client_id' => 'required|string|max:255',
                'hostname' => 'required|string|max:255',
                'ip_address' => 'required|ip',
                'username' => 'required|string|max:255',
                'os_info' => 'required|array',
                'timezone' => 'string|max:100'
            ]);

            // Check if client already exists by client_id
            $existingClient = Client::where('client_id', $request->client_id)->first();

            if ($existingClient) {
                // Update existing client data including IP address
                $existingClient->update([
                    'ip_address' => $request->ip_address,
                    'hostname' => $request->hostname,
                    'username' => $request->username,
                    'os_info' => $request->os_info,
                    'timezone' => $request->timezone ?? 'Asia/Jakarta',
                    'last_seen' => now()
                ]);

                Log::info('Client registration - existing client updated', [
                    'client_id' => $existingClient->client_id,
                    'old_ip' => $existingClient->getOriginal('ip_address'),
                    'new_ip' => $request->ip_address,
                    'hostname' => $request->hostname
                ]);

                return response()->json([
                    'success' => true,
                    'client_id' => $existingClient->client_id,
                    'message' => 'Client already registered and updated'
                ]);
            }

            // Create new client with provided client_id
            $client = Client::create([
                'client_id' => $request->client_id,
                'hostname' => $request->hostname,
                'ip_address' => $request->ip_address,
                'username' => $request->username,
                'os_info' => $request->os_info,
                'status' => 'active',
                'first_seen' => now(),  // Fixed: use first_seen instead of first_seen_at
                'last_seen' => now(),   // Fixed: use last_seen instead of last_seen_at
                'timezone' => $request->timezone ?? 'Asia/Jakarta'
            ]);

            Log::info('Client registration - new client created', [
                'client_id' => $client->client_id,
                'ip_address' => $client->ip_address,
                'hostname' => $client->hostname,
                'username' => $client->username
            ]);

            return response()->json([
                'success' => true,
                'client_id' => $client->client_id,
                'message' => 'Client registered successfully'
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::warning('Client registration validation failed', [
                'errors' => $e->errors(),
                'input' => $request->except(['os_info'])  // Don't log full os_info for security
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);

        } catch (\Exception $e) {
            Log::error('Client registration failed', [
                'error' => $e->getMessage(),
                'client_id' => $request->client_id ?? 'unknown',
                'ip_address' => $request->ip_address ?? 'unknown',
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Registration failed: ' . $e->getMessage()
            ], 500);
        }
    }

    public function heartbeat(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'status' => 'string|in:active,inactive'
        ]);

        $client = $this->validateAndGetClient($request);

        if ($this->clientValidationFailed($client)) {
            return $client; // Return the error response
        }

        $client->updateLastSeen();

        return response()->json([
            'success' => true,
            'message' => 'Heartbeat received'
        ]);
    }

    public function getSettings(Request $request, string $clientId): JsonResponse
    {
        $client = Client::where('client_id', $clientId)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'settings' => [
                'screenshot_interval' => 120,  // 2 minutes
                'stream_quality' => 'medium',
                'upload_batch_size' => 10
            ]
        ]);
    }

    public function updateStatus(Request $request, string $clientId): JsonResponse
    {
        $request->validate([
            'status' => 'required|string|in:active,inactive,offline'
        ]);

        $client = Client::where('client_id', $clientId)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        $client->update([
            'status' => $request->status,
            'last_seen' => now()
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Status updated'
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        // Add pagination to prevent memory issues with large datasets
        $perPage = $request->get('per_page', 50); // Default 50, max 100
        $perPage = min($perPage, 100); // Enforce max limit

        $clients = Client::with(['screenshots' => function($query) {
                $query->latest()->limit(1);
            }])
            ->orderBy('last_seen', 'desc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'clients' => $clients->items(),
            'pagination' => [
                'total' => $clients->total(),
                'per_page' => $clients->perPage(),
                'current_page' => $clients->currentPage(),
                'last_page' => $clients->lastPage(),
                'from' => $clients->firstItem(),
                'to' => $clients->lastItem()
            ]
        ]);
    }

    public function show(string $clientId): JsonResponse
    {
        $client = Client::with([
                'screenshots' => function($query) {
                    $query->latest()->limit(10);
                },
                'browserSessions' => function($query) {
                    $query->latest()->limit(20);
                },
                'urlActivities' => function($query) {
                    $query->latest()->limit(20);
                }
            ])
            ->where('client_id', $clientId)
            ->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'client' => $client
        ]);
    }

    public function getLatestScreenshot(string $clientId): JsonResponse
    {
        $client = Client::where('client_id', $clientId)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        $latestScreenshot = $client->screenshots()
            ->orderBy('captured_at', 'desc')
            ->first();

        if (!$latestScreenshot) {
            return response()->json([
                'success' => false,
                'message' => 'No screenshots available'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'screenshot' => [
                'id' => $latestScreenshot->id,
                'url' => $latestScreenshot->hasValidFilePath() ? asset('storage/' . $latestScreenshot->file_path) : null,
                'resolution' => $latestScreenshot->resolution,
                'captured_at' => $latestScreenshot->captured_at,
                'file_size' => $latestScreenshot->file_size
            ]
        ]);
    }

    public function health(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'API is healthy',
            'timestamp' => now()->toISOString()
        ]);
    }

    public function exportActivities(Request $request): JsonResponse
    {
        $from = $request->get('from', today()->subDays(7)->toDateString());
        $to = $request->get('to', today()->addDay()->toDateString());

        $query = Client::with([
            'browserSessions' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to])
                  ->orderBy('created_at', 'desc');
            },
            'urlActivities' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to])
                  ->orderBy('created_at', 'desc');
            },
            'screenshots' => function($q) use ($from, $to) {
                $q->whereBetween('captured_at', [$from, $to])
                  ->orderBy('captured_at', 'desc');
            }
        ]);

        if ($request->has('client_id') && $request->client_id) {
            $query->where('client_id', $request->client_id);
        }

        $clients = $query->get();

        $exportData = [
            'export_date' => now()->toISOString(),
            'date_range' => [
                'from' => $from,
                'to' => $to
            ],
            'total_clients' => $clients->count(),
            'summary' => [
                'browser_sessions' => $clients->sum(fn($c) => $c->browserSessions->count()),
                'process_events' => 0, // Process events not implemented yet
                'url_activities' => $clients->sum(fn($c) => $c->urlActivities->count()),
                'screenshots' => $clients->sum(fn($c) => $c->screenshots->count()),
            ],
            'clients' => $clients->map(function($client) {
                return [
                    'client_id' => $client->client_id,
                    'hostname' => $client->hostname,
                    'username' => $client->getDisplayUsername(),
                    'original_username' => $client->username,
                    'custom_username' => $client->custom_username,
                    'ip_address' => $client->ip_address,
                    'os_info' => $client->os_info,
                    'browser_sessions' => $client->browserSessions->map(function($session) {
                        return [
                            'id' => $session->id,
                            'browser_name' => $session->browser_name,
                            'session_id' => $session->session_id,
                            'created_at' => $session->created_at->toISOString()
                        ];
                    }),
                    'process_events' => [], // Process events not implemented yet
                    'url_activities' => $client->urlActivities->map(function($activity) {
                        return [
                            'id' => $activity->id,
                            'url' => $activity->url,
                            'title' => $activity->title,
                            'visit_count' => $activity->visit_count,
                            'total_duration' => $activity->total_duration,
                            'created_at' => $activity->created_at->toISOString()
                        ];
                    }),
                    'screenshots' => $client->screenshots->map(function($screenshot) {
                        return [
                            'id' => $screenshot->id,
                            'filename' => $screenshot->filename,
                            'resolution' => $screenshot->resolution,
                            'file_size' => $screenshot->file_size,
                            'captured_at' => $screenshot->captured_at->toISOString()
                        ];
                    })
                ];
            })
        ];

        return response()->json($exportData)
            ->header('Content-Disposition', 'attachment; filename="tenjo-activities-' . date('Y-m-d') . '.json"');
    }

    /**
     * Update client's custom username
     */
    public function updateUsername(Request $request, string $clientId): JsonResponse
    {
        try {
            $request->validate([
                'username' => 'required|string|max:255|min:2'
            ]);

            $client = Client::where('client_id', $clientId)->first();

            if (!$client) {
                return response()->json([
                    'success' => false,
                    'message' => 'Client not found'
                ], 404);
            }

            // Sanitize username
            $newUsername = trim($request->username);

            // Additional validation
            if (empty($newUsername)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Username cannot be empty'
                ], 422);
            }

            if (strlen($newUsername) > 50) {
                return response()->json([
                    'success' => false,
                    'message' => 'Username must be less than 50 characters'
                ], 422);
            }

            $result = $client->updateCustomUsername($newUsername);

            if (!$result) {
                throw new \Exception('Failed to save username to database');
            }

            Log::info('Client username updated', [
                'client_id' => $clientId,
                'old_username' => $client->username,
                'old_custom_username' => $client->getOriginal('custom_username'),
                'new_custom_username' => $newUsername,
                'ip_address' => $request->ip()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Username updated successfully',
                'data' => [
                    'client_id' => $client->client_id,
                    'original_username' => $client->username,
                    'custom_username' => $client->custom_username,
                    'display_username' => $client->getDisplayUsername()
                ]
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::warning('Username update validation failed', [
                'client_id' => $clientId,
                'errors' => $e->errors(),
                'ip_address' => $request->ip()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error updating client username', [
                'client_id' => $clientId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'ip_address' => $request->ip()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating username. Please try again.'
            ], 500);
        }
    }

    /**
     * Delete client and all associated data
     */
    public function deleteClient(Request $request, string $clientId): JsonResponse
    {
        $validator = Validator::make(['client_id' => $clientId], [
            'client_id' => 'required|string|max:255'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Client ID must be a non-empty string.',
                'errors' => $validator->errors()
            ], 400);
        }

        try {
            $client = Client::where('client_id', $clientId)->first();

            if (!$client) {
                return response()->json([
                    'success' => false,
                    'message' => 'Client not found'
                ], 404);
            }

            // Store client info for logging before deletion
            $clientInfo = [
                'client_id' => $client->client_id,
                'hostname' => $client->hostname,
                'username' => $client->username,
                'custom_username' => $client->custom_username,
                'ip_address' => $client->ip_address,
                'last_seen' => $client->last_seen
            ];

            // Use database transaction for data integrity
            DB::transaction(function () use ($client, $clientInfo) {
                // Delete associated data using relationships for consistency and safety
                $screenshotCount = $client->screenshots()->count();
                $browserSessionCount = $client->browserSessions()->count();
                $urlActivityCount = $client->urlActivities()->count();

                // Eloquent will handle cascading deletes if set up, but explicit deletion is safer.
                $client->urlActivities()->delete();
                $client->browserSessions()->delete();

                // Finally delete the client
                $client->delete();

                Log::info('Client deleted successfully', array_merge($clientInfo, [
                    'deleted_screenshots' => $screenshotCount,
                    'deleted_browser_sessions' => $browserSessionCount,
                    'deleted_url_activities' => $urlActivityCount,
                    'deleted_by_ip' => request()->ip()
                ]));
            });

            return response()->json([
                'success' => true,
                'message' => 'Client and all associated data deleted successfully',
                'data' => $clientInfo
            ]);

        } catch (\Exception $e) {
            Log::error('Error deleting client', [
                'client_id' => $clientId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'ip_address' => $request->ip()
            ]);

            // Check if it's a database constraint error
            if (str_contains($e->getMessage(), 'foreign key constraint')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete client due to data dependencies. Please contact administrator.'
                ], 409);
            }

            return response()->json([
                'success' => false,
                'message' => 'An error occurred while deleting client. Please try again.'
            ], 500);
        }
    }

    /**
     * Check if client has pending update (for silent push deployment)
     */
    public function checkUpdate(string $clientId): JsonResponse
    {
        try {
            $client = Client::where('client_id', $clientId)->first();

            if (!$client) {
                return response()->json([
                    'has_update' => false
                ]);
            }

            // Check if there's a pending update
            if ($client->pending_update) {
                return response()->json([
                    'has_update' => true,
                    'version' => $client->update_version,
                    'update_url' => $client->update_url,
                    'changes' => $client->update_changes ? json_decode($client->update_changes) : []
                ]);
            }

            return response()->json([
                'has_update' => false
            ]);

        } catch (\Exception $e) {
            Log::error('Error checking update', [
                'client_id' => $clientId,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'has_update' => false
            ]);
        }
    }

    /**
     * Mark update as completed (client notifies after successful update)
     */
    public function updateCompleted(Request $request, string $clientId): JsonResponse
    {
        try {
            $client = Client::where('client_id', $clientId)->first();

            if (!$client) {
                return response()->json([
                    'success' => false,
                    'message' => 'Client not found'
                ], 404);
            }

            // Update client record
            $client->pending_update = false;
            $client->current_version = $request->input('version');
            $client->update_completed_at = now();
            $client->save();

            Log::info('Client update completed', [
                'client_id' => $clientId,
                'hostname' => $client->hostname,
                'version' => $request->input('version')
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Update completion recorded'
            ]);

        } catch (\Exception $e) {
            Log::error('Error recording update completion', [
                'client_id' => $clientId,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error recording update completion'
            ], 500);
        }
    }
}
