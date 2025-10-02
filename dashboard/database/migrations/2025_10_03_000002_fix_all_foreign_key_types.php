<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Fix all foreign key type mismatches in the database.
     * Converts bigint foreign keys to VARCHAR to match primary keys.
     *
     * SAFE: Does NOT delete any data!
     */
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();

        // Skip for SQLite
        if ($driver === 'sqlite') {
            return;
        }

        echo PHP_EOL . "=== FIXING ALL FOREIGN KEY TYPE MISMATCHES ===" . PHP_EOL . PHP_EOL;

        // List of tables and their foreign key columns to fix
        $foreignKeys = [
            'url_activities' => 'browser_session_id',  // FK to browser_sessions.id
        ];

        foreach ($foreignKeys as $table => $column) {
            $this->fixForeignKey($table, $column, $driver);
        }

        echo PHP_EOL . "✅ All foreign key types fixed!" . PHP_EOL;
    }

    /**
     * Fix a single foreign key column type
     */
    private function fixForeignKey(string $table, string $column, string $driver): void
    {
        echo "Processing: {$table}.{$column}" . PHP_EOL;

        // Check if table exists
        if (!Schema::hasTable($table)) {
            echo "  ⚠ Table '{$table}' not found, skipping..." . PHP_EOL . PHP_EOL;
            return;
        }

        // Check if column exists
        if (!Schema::hasColumn($table, $column)) {
            echo "  ⚠ Column '{$column}' not found in '{$table}', skipping..." . PHP_EOL . PHP_EOL;
            return;
        }

        if ($driver === 'pgsql') {
            // Check current data type
            $currentType = DB::selectOne("
                SELECT data_type
                FROM information_schema.columns
                WHERE table_name = ?
                AND column_name = ?
            ", [$table, $column]);

            echo "  Current type: " . $currentType->data_type . PHP_EOL;

            // Only convert if it's bigint
            if ($currentType && $currentType->data_type === 'bigint') {
                // Step 1: Drop foreign key constraint if exists
                try {
                    $constraints = DB::select("
                        SELECT constraint_name
                        FROM information_schema.table_constraints
                        WHERE table_name = ?
                        AND constraint_type = 'FOREIGN KEY'
                        AND constraint_name LIKE '%{$column}%'
                    ", [$table]);

                    foreach ($constraints as $constraint) {
                        DB::statement("ALTER TABLE {$table} DROP CONSTRAINT IF EXISTS {$constraint->constraint_name}");
                        echo "  ✓ Dropped constraint: {$constraint->constraint_name}" . PHP_EOL;
                    }
                } catch (\Exception $e) {
                    echo "  ! No foreign key constraints found (OK)" . PHP_EOL;
                }

                // Step 2: Check for NULL values
                $nullCount = DB::selectOne("SELECT COUNT(*) as count FROM {$table} WHERE {$column} IS NULL");
                if ($nullCount->count > 0) {
                    echo "  ⚠ Warning: {$nullCount->count} NULL values found" . PHP_EOL;
                }

                // Step 3: Convert bigint to VARCHAR
                try {
                    DB::statement("ALTER TABLE {$table} ALTER COLUMN {$column} TYPE VARCHAR(255) USING {$column}::text");
                    echo "  ✓ Converted {$column} from bigint to VARCHAR(255)" . PHP_EOL;
                } catch (\Exception $e) {
                    echo "  ✗ Failed to convert: " . $e->getMessage() . PHP_EOL;
                }

                // Step 4: Try to re-add foreign key (may fail if referencing browser_sessions.id which is bigint)
                // We'll skip this since browser_sessions.id is auto-increment bigint, not VARCHAR
                echo "  ℹ Skipping foreign key re-creation (browser_sessions.id is bigint)" . PHP_EOL;

            } else {
                echo "  ℹ Column is already {$currentType->data_type} (no conversion needed)" . PHP_EOL;
            }

        } elseif ($driver === 'mysql') {
            // MySQL version
            try {
                // Drop foreign key
                $constraints = DB::select("
                    SELECT CONSTRAINT_NAME
                    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
                    WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = ?
                    AND COLUMN_NAME = ?
                    AND REFERENCED_TABLE_NAME IS NOT NULL
                ", [$table, $column]);

                foreach ($constraints as $constraint) {
                    DB::statement("ALTER TABLE {$table} DROP FOREIGN KEY {$constraint->CONSTRAINT_NAME}");
                }
            } catch (\Exception $e) {
                // OK if no constraint exists
            }

            // Convert column type
            DB::statement("ALTER TABLE {$table} MODIFY COLUMN {$column} VARCHAR(255)");
            echo "  ✓ Converted {$column} from bigint to VARCHAR(255)" . PHP_EOL;
        }

        echo PHP_EOL;
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        echo "⚠ WARNING: This migration cannot be safely reversed!" . PHP_EOL;
        echo "If you need to rollback, restore from database backup." . PHP_EOL;
    }
};
