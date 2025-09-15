<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Client;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class StreamController extends Controller
{
    protected static $streamConnections = [];

    public function startStream(Request $request, $clientId)
    {
        $quality = $request->input('quality', 'medium');

        $client = Client::where('client_id', $clientId)->first();
        if (!$client) {
            return response()->json(['error' => 'Client not found'], 404);
        }

        // Store stream request in cache/database
        cache()->put("stream_request_{$clientId}", [
            'quality' => $quality,
            'timestamp' => now()
        ], 300); // 5 minutes

        return response()->json(['success' => true, 'message' => 'Stream started']);
    }

    public function stopStream(Request $request, $clientId)
    {
        // Remove stream request
        cache()->forget("stream_request_{$clientId}");

        return response()->json(['success' => true, 'message' => 'Stream stopped']);
    }

    public function getStreamRequest($clientId)
    {
        $streamRequest = cache()->get("stream_request_{$clientId}");

        if ($streamRequest) {
            return response()->json($streamRequest);
        }

        return response()->json(['streaming' => false]);
    }

    public function getStreamStatus($clientId)
    {
        $streamRequest = cache()->get("stream_request_{$clientId}");

        return response()->json([
            'should_stream' => !!$streamRequest,
            'quality' => $streamRequest['quality'] ?? 'medium',
            'timestamp' => $streamRequest['timestamp'] ?? null
        ]);
    }

    public function uploadStreamChunk(Request $request, $clientId)
    {
        try {
            $chunk = $request->input('chunk')
                ?? $request->input('chunk_data')
                ?? $request->input('video_chunk')
                ?? $request->input('data');

            $sequence = $request->input('sequence', 0);
            $quality = $request->input('quality', 'medium');

            if (empty($chunk)) {
                Log::warning('uploadStreamChunk missing chunk data', [
                    'client_id' => $clientId,
                    'received_keys' => array_keys($request->all())
                ]);
                return response()->json(['error' => 'No chunk data provided'], 400);
            }

            // Store the latest video frame in cache for the dashboard to fetch.
            // This is the core of the live streaming view.
            cache()->put("latest_video_chunk_{$clientId}", [
                'data' => $chunk,
                'sequence' => $sequence,
                'timestamp' => now(),
                'quality' => $quality,
            ], 10); // Keep for 10 seconds

            // Optional: Log for debugging purposes
            // Log::info("Video chunk received", ['client_id' => $clientId, 'sequence' => $sequence]);

            return response()->json(['success' => true, 'sequence' => $sequence]);

        } catch (\Exception $e) {
            Log::error("Error uploading stream chunk: " . $e->getMessage(), [
                'client_id' => $clientId,
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json(['error' => 'Failed to upload stream chunk'], 500);
        }
    }

    public function getLatestChunk($clientId)
    {
        try {
            // Directly fetch the latest video chunk from the cache.
            // This is the ONLY source for the live view now. No fallbacks.
            $videoChunk = cache()->get("latest_video_chunk_{$clientId}");

            if ($videoChunk) {
                return response()->json([
                    'data' => $videoChunk['data'],
                    'sequence' => $videoChunk['sequence'],
                    'timestamp' => $videoChunk['timestamp'],
                    'type' => 'video_stream', // Hardcoded to video stream
                    'quality' => $videoChunk['quality'] ?? 'medium',
                    'source' => 'cache_video'
                ]);
            }

            // If no data is available, return an empty state.
            // This prevents the frontend from showing old screenshots.
            return response()->json([
                'data' => null,
                'sequence' => 0,
                'timestamp' => now(),
                'type' => 'empty',
                'source' => 'no_data',
                'message' => 'No live stream data available.'
            ]);

        } catch (\Exception $e) {
            Log::error("Error getting latest chunk: " . $e->getMessage(), [
                'client_id' => $clientId,
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'error' => 'Failed to retrieve stream data',
                'client_id' => $clientId
            ], 500);
        }
    }

    public function getVideoStream($clientId)
    {
        try {
            // Get the latest video chunk from cache
            $videoChunk = cache()->get("latest_video_chunk_{$clientId}");

            if ($videoChunk && isset($videoChunk['data'])) {
                // Return the raw video data with appropriate headers
                $videoData = base64_decode($videoChunk['data']);

                return response($videoData, 200, [
                    'Content-Type' => 'video/mp4',
                    'Cache-Control' => 'no-cache, no-store, must-revalidate',
                    'Pragma' => 'no-cache',
                    'Expires' => '0',
                    'Access-Control-Allow-Origin' => '*',
                ]);
            }

            // Return a placeholder or error response
            return response()->json([
                'error' => 'No video stream available',
                'message' => 'Client is not currently streaming'
            ], 404);

        } catch (\Exception $e) {
            Log::error("Error getting video stream: " . $e->getMessage(), [
                'client_id' => $clientId,
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'error' => 'Failed to retrieve video stream',
                'client_id' => $clientId
            ], 500);
        }
    }
}
