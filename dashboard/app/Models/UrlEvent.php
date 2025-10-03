<?php

namespace App\Models;

use RuntimeException;

/**
 * @deprecated Legacy model stub retained for clarity. URL events moved to UrlActivity.
 */
class UrlEvent
{
    public function __construct()
    {
        throw new RuntimeException(
            'UrlEvent model has been removed. Use UrlActivity records instead.'
        );
    }
}
