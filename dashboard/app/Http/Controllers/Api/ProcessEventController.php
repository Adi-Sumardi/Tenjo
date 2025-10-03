<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

class ProcessEventController extends Controller
{
    /**
     * Legacy endpoint retained for backward compatibility. Always responds with GONE.
     */
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Process event ingestion has been removed. Update clients to stop sending process event payloads.'
        ], Response::HTTP_GONE);
    }
}
