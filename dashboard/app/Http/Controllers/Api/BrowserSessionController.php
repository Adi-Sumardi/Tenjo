<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BrowserSession;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class BrowserSessionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = BrowserSession::query();

        // Filter by client_id
        if ($request->has('client_id')) {
            $query->where('client_id', $request->client_id);
        }

        // Filter by browser name
        if ($request->has('browser_name')) {
            $query->where('browser_name', 'like', '%' . $request->browser_name . '%');
        }

        // Filter by date range using session_start
        if ($request->has('from')) {
            $query->where('session_start', '>=', $request->from . ' 00:00:00');
        }

        if ($request->has('to')) {
            $query->where('session_start', '<=', $request->to . ' 23:59:59');
        }

        // Load URL activities relationship
        $browserSessions = $query->with('urlActivities')
            ->orderBy('session_start', 'desc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'browser_sessions' => $browserSessions
        ]);
    }

    public function show($id): JsonResponse
    {
        $browserSession = BrowserSession::with('urlActivities')->find($id);

        if (!$browserSession) {
            return response()->json([
                'success' => false,
                'message' => 'Browser session not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'browser_session' => $browserSession
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        // Keep original store method for client API
        $request->validate([
            'client_id' => 'required|string',
            'browser_name' => 'required|string',
            'browser_version' => 'nullable|string',
            'browser_executable_path' => 'nullable|string',
            'session_start' => 'required|date',
        ]);

        try {
            $browserSession = BrowserSession::create([
                'client_id' => $request->client_id,
                'browser_name' => $request->browser_name,
                'browser_version' => $request->browser_version,
                'browser_executable_path' => $request->browser_executable_path,
                'session_start' => $request->session_start,
                'is_active' => true,
            ]);

            return response()->json([
                'success' => true,
                'browser_session_id' => $browserSession->id,
                'message' => 'Browser session created successfully'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create browser session: ' . $e->getMessage()
            ], 500);
        }
    }
}
