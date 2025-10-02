<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Fix client_id type mismatch in browser_sessions table.
     * Changes client_id from bigint to VARCHAR to match clients table.
     *
     * SAFE: Does NOT delete any data!
     */
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();

        // Skip for SQLite (testing only)
        if ($driver === 'sqlite') {
            return;
        }

        // Check if browser_sessions table exists
        if (!Schema::hasTable('browser_sessions')) {
            return;
        }

        // Check if client_id column exists
        if (!Schema::hasColumn('browser_sessions', 'client_id')) {
            return;
        }

        echo "Fixing browser_sessions.client_id type mismatch..." . PHP_EOL;

        if ($driver === 'pgsql') {
            // PostgreSQL: Change bigint to VARCHAR
            // Step 1: Drop foreign key constraint if exists
            try {
                DB::statement('ALTER TABLE browser_sessions DROP CONSTRAINT IF EXISTS fk_browser_sessions_client_id');
                DB::statement('ALTER TABLE browser_sessions DROP CONSTRAINT IF EXISTS browser_sessions_client_id_foreign');
                echo "  ✓ Dropped foreign key constraints" . PHP_EOL;
            } catch (\Exception $e) {
                echo "  ! No foreign key to drop (OK)" . PHP_EOL;
            }

            // Step 2: Check current data type
            $currentType = DB::selectOne("
                SELECT data_type
                FROM information_schema.columns
                WHERE table_name = 'browser_sessions'
                AND column_name = 'client_id'
            ");

            echo "  Current type: " . $currentType->data_type . PHP_EOL;

            // Step 3: Only convert if it's bigint
            if ($currentType && $currentType->data_type === 'bigint') {
                // First, check if there's any data that would be lost
                $count = DB::table('browser_sessions')->count();
                echo "  Records in browser_sessions: $count" . PHP_EOL;

                if ($count > 0) {
                    // Check for orphaned records (client_id not in clients table)
                    $orphaned = DB::select("
                        SELECT COUNT(*) as count
                        FROM browser_sessions bs
                        WHERE NOT EXISTS (
                            SELECT 1 FROM clients c WHERE c.client_id = bs.client_id::text
                        )
                    ");

                    if ($orphaned[0]->count > 0) {
                        echo "  ⚠ Warning: {$orphaned[0]->count} orphaned records found" . PHP_EOL;
                        echo "  These will remain but may cause issues" . PHP_EOL;
                    }
                }

                // Convert bigint to VARCHAR
                DB::statement('ALTER TABLE browser_sessions ALTER COLUMN client_id TYPE VARCHAR(255) USING client_id::text');
                echo "  ✓ Converted client_id from bigint to VARCHAR(255)" . PHP_EOL;
            } else {
                echo "  ! client_id is already {$currentType->data_type} (no conversion needed)" . PHP_EOL;
            }

            // Step 4: Re-add foreign key constraint
            try {
                DB::statement('
                    ALTER TABLE browser_sessions
                    ADD CONSTRAINT fk_browser_sessions_client_id
                    FOREIGN KEY (client_id)
                    REFERENCES clients(client_id)
                    ON DELETE CASCADE
                ');
                echo "  ✓ Re-added foreign key constraint" . PHP_EOL;
            } catch (\Exception $e) {
                echo "  ! Could not add foreign key: " . $e->getMessage() . PHP_EOL;
                echo "  (This is OK if there are orphaned records)" . PHP_EOL;
            }

        } elseif ($driver === 'mysql') {
            // MySQL: Similar approach
            try {
                DB::statement('ALTER TABLE browser_sessions DROP FOREIGN KEY fk_browser_sessions_client_id');
                DB::statement('ALTER TABLE browser_sessions DROP FOREIGN KEY browser_sessions_client_id_foreign');
            } catch (\Exception $e) {
                // OK if constraint doesn't exist
            }

            // Check current type
            $currentType = DB::selectOne("
                SELECT DATA_TYPE
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                AND TABLE_NAME = 'browser_sessions'
                AND COLUMN_NAME = 'client_id'
            ");

            if ($currentType && $currentType->DATA_TYPE === 'bigint') {
                DB::statement('ALTER TABLE browser_sessions MODIFY COLUMN client_id VARCHAR(255)');
                echo "  ✓ Converted client_id from bigint to VARCHAR(255)" . PHP_EOL;
            }

            // Re-add foreign key
            try {
                DB::statement('
                    ALTER TABLE browser_sessions
                    ADD CONSTRAINT fk_browser_sessions_client_id
                    FOREIGN KEY (client_id)
                    REFERENCES clients(client_id)
                    ON DELETE CASCADE
                ');
                echo "  ✓ Re-added foreign key constraint" . PHP_EOL;
            } catch (\Exception $e) {
                echo "  ! Could not add foreign key: " . $e->getMessage() . PHP_EOL;
            }
        }

        echo "✅ Migration complete!" . PHP_EOL;
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Cannot safely reverse this migration as it would require
        // converting UUIDs back to bigint, which would lose data.
        // If you need to rollback, restore from backup.

        echo "⚠ WARNING: This migration cannot be safely reversed!" . PHP_EOL;
        echo "If you need to rollback, restore from database backup." . PHP_EOL;
    }
};
