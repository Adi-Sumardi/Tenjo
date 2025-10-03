<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UrlActivity;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class UrlActivityController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = UrlActivity::query();

        // Filter by client_id
        if ($request->has('client_id')) {
            $query->where('client_id', $request->client_id);
        }

        // Filter by browser_session_id
        if ($request->has('browser_session_id')) {
            $query->where('browser_session_id', $request->browser_session_id);
        }

        // Filter by URL/domain
        if ($request->has('url')) {
            $query->where('url', 'like', '%' . $request->url . '%');
        }

        if ($request->has('domain')) {
            $query->where('domain', 'like', '%' . $request->domain . '%');
        }

        // Filter by date range using visit_start
        if ($request->has('from')) {
            $query->where('visit_start', '>=', $request->from . ' 00:00:00');
        }

        if ($request->has('to')) {
            $query->where('visit_start', '<=', $request->to . ' 23:59:59');
        }

        // Load browser session relationship
        $urlActivities = $query->with('browserSession')
            ->orderBy('visit_start', 'desc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'url_activities' => $urlActivities
        ]);
    }

    public function show($id): JsonResponse
    {
        $urlActivity = UrlActivity::with('browserSession')->find($id);

        if (!$urlActivity) {
            return response()->json([
                'success' => false,
                'message' => 'URL activity not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'url_activity' => $urlActivity
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        // Keep original store method for client API
        $request->validate([
            'client_id' => 'required|string',
            'browser_session_id' => 'required|integer',
            'url' => 'required|string',
            'domain' => 'required|string',
            'page_title' => 'nullable|string',
            'visit_start' => 'required|date',
        ]);

        try {
            $urlActivity = UrlActivity::create([
                'client_id' => $request->client_id,
                'browser_session_id' => $request->browser_session_id,
                'url' => $request->url,
                'domain' => $request->domain,
                'page_title' => $request->page_title,
                'visit_start' => $request->visit_start,
                'is_active' => true,
            ]);

            return response()->json([
                'success' => true,
                'url_activity_id' => $urlActivity->id,
                'message' => 'URL activity created successfully'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create URL activity: ' . $e->getMessage()
            ], 500);
        }
    }
}
