#!/bin/bash
#
# Mass Deployment Script for Tenjo Clients
# Deploy updates to all registered PCs from VPS
# Usage: sudo ./mass_deploy.sh [version]
#

set -e

VERSION="${1:-latest}"
VPS_PATH="/var/www/Tenjo"
DOWNLOAD_URL="https://tenjo.adilabs.id/downloads/client"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║        Tenjo Mass Deployment - Version ${VERSION}       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if running on VPS
if [ ! -d "${VPS_PATH}/dashboard" ]; then
    echo "ERROR: This script must be run on the VPS server"
    exit 1
fi

# Get list of all active clients from database
echo "[1/4] Fetching active clients from database..."

cd "${VPS_PATH}/dashboard"

CLIENTS=$(php artisan tinker --execute="
\$clients = \App\Models\Client::where('last_seen', '>', now()->subHours(24))
    ->orderBy('hostname')
    ->get(['id', 'hostname', 'ip_address', 'os_info', 'client_id']);

foreach (\$clients as \$client) {
    \$os = json_decode(\$client->os_info, true);
    \$os_type = \$os['system'] ?? 'unknown';
    echo \$client->hostname . '|' . \$client->ip_address . '|' . \$os_type . '|' . \$client->client_id . PHP_EOL;
}
")

if [ -z "$CLIENTS" ]; then
    echo "ERROR: No active clients found in database"
    exit 1
fi

CLIENT_COUNT=$(echo "$CLIENTS" | wc -l | tr -d ' ')
echo "✓ Found ${CLIENT_COUNT} active clients"
echo ""

# Display clients
echo "[2/4] Active clients:"
echo "─────────────────────────────────────────────────────────────"
echo "$CLIENTS" | while IFS='|' read -r hostname ip os_type client_id; do
    printf "  %-25s %-15s %-10s\n" "$hostname" "$ip" "$os_type"
done
echo "─────────────────────────────────────────────────────────────"
echo ""

# Confirm deployment
read -p "Deploy update to all ${CLIENT_COUNT} clients? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "[3/4] Deploying to clients..."
echo ""

# Deploy to each client
SUCCESS_COUNT=0
FAIL_COUNT=0

echo "$CLIENTS" | while IFS='|' read -r hostname ip os_type client_id; do
    echo "Deploying to: $hostname ($ip) [$os_type]"
    
    if [ "$os_type" = "Windows" ]; then
        # Windows deployment via PowerShell remoting (if configured)
        # Note: Requires PSRemoting enabled on target
        INSTALL_CMD="irm ${DOWNLOAD_URL}/install.ps1 | iex"
        
        echo "  → Windows auto-update URL sent via API"
        # Trigger update via API (client will auto-download on next heartbeat)
        curl -s -X POST "https://tenjo.adilabs.id/api/clients/${client_id}/update" \
            -H "Content-Type: application/json" \
            -d "{\"version\": \"${VERSION}\"}" > /dev/null
        
        echo "  ✓ Update trigger sent (client will auto-update)"
        ((SUCCESS_COUNT++))
        
    elif [ "$os_type" = "Darwin" ] || [ "$os_type" = "Linux" ]; then
        # macOS/Linux deployment via SSH (if configured)
        # Note: Requires SSH key authentication
        
        echo "  → Unix auto-update URL sent via API"
        curl -s -X POST "https://tenjo.adilabs.id/api/clients/${client_id}/update" \
            -H "Content-Type: application/json" \
            -d "{\"version\": \"${VERSION}\"}" > /dev/null
        
        echo "  ✓ Update trigger sent (client will auto-update)"
        ((SUCCESS_COUNT++))
        
    else
        echo "  ✗ Unknown OS type: $os_type"
        ((FAIL_COUNT++))
    fi
    
    echo ""
done

echo ""
echo "[4/4] Deployment Summary"
echo "─────────────────────────────────────────────────────────────"
echo "  Total clients:    ${CLIENT_COUNT}"
echo "  Successfully deployed: ${SUCCESS_COUNT}"
echo "  Failed:           ${FAIL_COUNT}"
echo "─────────────────────────────────────────────────────────────"
echo ""

if [ $SUCCESS_COUNT -eq $CLIENT_COUNT ]; then
    echo "✅ All clients will auto-update on next startup/heartbeat"
else
    echo "⚠️  Some clients may need manual update"
fi

echo ""
echo "Monitor update status:"
echo "  cd ${VPS_PATH}/dashboard"
echo "  php artisan tinker --execute=\"\\"
echo "    \$clients = \App\Models\Client::all();"
echo "    foreach (\$clients as \$c) {"
echo "      echo \$c->hostname . ': v' . (\$c->version ?? 'unknown') . PHP_EOL;"
echo "    }"
echo "  \""
echo ""
