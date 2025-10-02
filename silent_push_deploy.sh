#!/bin/bash
#
# Tenjo Silent Push Deployment
# Deploy updates to all clients WITHOUT user interaction
# Clients receive update via API trigger, download & install silently
#
# Usage: ./silent_push_deploy.sh [version]
#

set -e

VERSION="${1:-$(date +%Y%m%d_%H%M)}"
VPS_PATH="/var/www/Tenjo"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      Tenjo Silent Push Deployment v${VERSION}           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if running on VPS
if [ ! -d "${VPS_PATH}/dashboard" ]; then
    echo "❌ ERROR: This script must be run on VPS (103.129.149.67)"
    exit 1
fi

echo "[1/5] Fetching active clients from database..."
cd "${VPS_PATH}/dashboard"

# Get all active clients (seen in last 24 hours)
CLIENTS_DATA=$(php artisan tinker --execute="
\$clients = \App\Models\Client::where('last_seen', '>', now()->subHours(24))
    ->orderBy('hostname')
    ->get(['id', 'hostname', 'ip_address', 'client_id', 'os_info']);

foreach (\$clients as \$client) {
    \$os = json_decode(\$client->os_info, true);
    \$os_type = \$os['system'] ?? 'unknown';
    echo \$client->id . '|' . \$client->hostname . '|' . \$client->ip_address . '|' . \$os_type . '|' . \$client->client_id . PHP_EOL;
}
")

if [ -z "$CLIENTS_DATA" ]; then
    echo "❌ No active clients found"
    exit 1
fi

CLIENT_COUNT=$(echo "$CLIENTS_DATA" | wc -l | tr -d ' ')
echo "✓ Found ${CLIENT_COUNT} active clients"
echo ""

# Display clients
echo "[2/5] Target clients:"
echo "─────────────────────────────────────────────────────────────"
printf "%-5s %-25s %-15s %-10s\n" "ID" "Hostname" "IP Address" "OS"
echo "─────────────────────────────────────────────────────────────"
echo "$CLIENTS_DATA" | while IFS='|' read -r id hostname ip os_type client_id; do
    printf "%-5s %-25s %-15s %-10s\n" "$id" "$hostname" "$ip" "$os_type"
done
echo "─────────────────────────────────────────────────────────────"
echo ""

# Confirm deployment
read -p "🚀 Silent push update to ${CLIENT_COUNT} clients? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "[3/5] Creating silent update triggers..."

# Create update trigger for each client in database
SUCCESS_COUNT=0
FAIL_COUNT=0

echo "$CLIENTS_DATA" | while IFS='|' read -r id hostname ip os_type client_id; do
    echo "→ Triggering: $hostname ($ip)"
    
    # Insert update command into database (client will check on next heartbeat)
    php artisan tinker --execute="
    \$client = \App\Models\Client::find($id);
    if (\$client) {
        // Set update flag
        \$client->pending_update = true;
        \$client->update_version = '${VERSION}';
        \$client->update_url = 'https://tenjo.adilabs.id/downloads/client/tenjo_client_${VERSION}.tar.gz';
        \$client->save();
        echo '  ✓ Update trigger set' . PHP_EOL;
    }
    " > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Queued for silent update"
        ((SUCCESS_COUNT++))
    else
        echo "  ✗ Failed to queue"
        ((FAIL_COUNT++))
    fi
done

echo ""
echo "[4/5] Adding database migration for update tracking..."

# Check if migration exists, create if not
php artisan make:migration add_update_fields_to_clients_table --quiet 2>/dev/null || true

# Add columns if they don't exist
php artisan tinker --execute="
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;

if (!Schema::hasColumn('clients', 'pending_update')) {
    Schema::table('clients', function (Blueprint \$table) {
        \$table->boolean('pending_update')->default(false)->after('status');
        \$table->string('update_version', 50)->nullable()->after('pending_update');
        \$table->text('update_url')->nullable()->after('update_version');
        \$table->timestamp('update_triggered_at')->nullable()->after('update_url');
        \$table->timestamp('update_completed_at')->nullable()->after('update_triggered_at');
    });
    echo '✓ Update tracking columns added' . PHP_EOL;
} else {
    echo '✓ Update tracking already configured' . PHP_EOL;
}
" 2>/dev/null

echo ""
echo "[5/5] Deployment summary"
echo "─────────────────────────────────────────────────────────────"
echo "  Version:          ${VERSION}"
echo "  Total clients:    ${CLIENT_COUNT}"
echo "  Update triggered: ${SUCCESS_COUNT}"
echo "  Failed:           ${FAIL_COUNT}"
echo "─────────────────────────────────────────────────────────────"
echo ""

if [ $SUCCESS_COUNT -eq $CLIENT_COUNT ]; then
    echo "✅ All clients queued for silent update"
    echo ""
    echo "📊 Clients will update automatically when they:"
    echo "   • Send next heartbeat (every 5 minutes)"
    echo "   • Restart application"
    echo "   • Check in with server"
    echo ""
    echo "🔍 Monitor update progress:"
    echo "   watch -n 5 'cd ${VPS_PATH}/dashboard && php artisan tinker --execute=\""
    echo "     \\\$pending = \\\App\\\Models\\\Client::where('pending_update', true)->count();"
    echo "     \\\$completed = \\\App\\\Models\\\Client::whereNotNull('update_completed_at')->count();"
    echo "     echo \\\"Pending: \\\$pending | Completed: \\\$completed\\\" . PHP_EOL;"
    echo "   \"'"
else
    echo "⚠️  Some clients may need manual attention"
fi

echo ""
echo "💡 Update process is COMPLETELY SILENT - users won't see anything!"
echo ""
