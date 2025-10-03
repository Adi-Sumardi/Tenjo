<?php

namespace App\Models;

use RuntimeException;

/**
 * @deprecated Legacy model retained only to provide a clear runtime error if referenced.
 *             Browser events have been replaced by BrowserSession and UrlActivity models.
 */
class BrowserEvent
{
    public function __construct()
    {
        throw new RuntimeException(
            'BrowserEvent model has been removed. Use BrowserSession/UrlActivity endpoints instead.'
        );
    }
}
