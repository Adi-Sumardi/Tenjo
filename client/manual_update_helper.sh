#!/bin/bash
# Manual Update Helper for 19 Tenjo Clients
# Run this to get step-by-step instructions for each client

# List of client IPs
CLIENT_IPS=(
    "192.168.1.26"
    "192.168.1.21"
    "192.168.1.25"
    "192.168.1.2"
    "192.168.100.165"
    "192.168.100.216"
    "192.168.100.178"
    "192.168.1.29"
    "192.168.1.8"
    "192.168.1.27"
    "192.168.1.22"
    "192.168.100.158"
    "192.168.100.159"
    "192.168.1.38"
    "192.168.1.30"
    "192.168.1.32"
    "192.168.1.18"
)

PRODUCTION_SERVER="https://tenjo.adilabs.id"

echo "========================================"
echo "🔧 TENJO CLIENT MANUAL UPDATE HELPER"
echo "========================================"
echo ""
echo "Total clients to update: ${#CLIENT_IPS[@]}"
echo ""

# Check which clients are online
echo "📡 Checking which clients are online..."
echo ""

ONLINE_CLIENTS=()
OFFLINE_CLIENTS=()

for ip in "${CLIENT_IPS[@]}"; do
    echo -n "Testing $ip ... "
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo "✅ ONLINE"
        ONLINE_CLIENTS+=("$ip")
    else
        echo "❌ OFFLINE"
        OFFLINE_CLIENTS+=("$ip")
    fi
done

echo ""
echo "========================================"
echo "📊 CONNECTION STATUS"
echo "========================================"
echo "✅ Online:  ${#ONLINE_CLIENTS[@]} clients"
echo "❌ Offline: ${#OFFLINE_CLIENTS[@]} clients"
echo ""

if [ ${#ONLINE_CLIENTS[@]} -eq 0 ]; then
    echo "⚠️  No clients are reachable from this network"
    echo "   Make sure you're connected to the same network as the clients"
    echo "   Or use RDP/TeamViewer to access each PC"
    exit 1
fi

echo "========================================"
echo "📝 UPDATE INSTRUCTIONS"
echo "========================================"
echo ""
echo "For WINDOWS clients, run these commands on each PC:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "# Open Command Prompt as Administrator, then:"
echo ""
echo "cd C:\\ProgramData\\Tenjo"
echo "curl -O $PRODUCTION_SERVER/downloads/client/update_server_config.py"
echo "python update_server_config.py"
echo "shutdown /r /t 60"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create individual update script for each online client
echo "🔧 Creating individual update commands..."
echo ""

UPDATE_DIR="$HOME/Desktop/tenjo_client_updates"
mkdir -p "$UPDATE_DIR"

cat > "$UPDATE_DIR/UPDATE_INSTRUCTIONS.txt" << 'EOF'
═══════════════════════════════════════════════════════════
TENJO CLIENT UPDATE INSTRUCTIONS
═══════════════════════════════════════════════════════════

For each client PC, follow these steps:

METHOD 1: Remote Desktop (RDP)
──────────────────────────────────────────────────────────
1. Connect via RDP to client PC:
   - Open "Remote Desktop" app
   - Enter client IP address
   - Login with admin credentials

2. Once connected, open Command Prompt as Administrator:
   - Press Win + X
   - Select "Command Prompt (Admin)" or "PowerShell (Admin)"

3. Copy-paste this command block:
   ─────────────────────────────────────────────────────
   cd C:\ProgramData\Tenjo
   curl -O https://tenjo.adilabs.id/downloads/client/update_server_config.py
   python update_server_config.py
   shutdown /r /t 60
   ─────────────────────────────────────────────────────

4. PC will restart in 60 seconds
5. Move to next client

METHOD 2: TeamViewer / AnyDesk
──────────────────────────────────────────────────────────
Same as RDP, but connect via TeamViewer/AnyDesk instead

METHOD 3: Physical Access
──────────────────────────────────────────────────────────
If you're physically at the PC:
1. Open Command Prompt as Administrator
2. Run the commands above
3. Move to next PC

═══════════════════════════════════════════════════════════
EOF

# Create checklist
cat > "$UPDATE_DIR/UPDATE_CHECKLIST.txt" << EOF
TENJO CLIENT UPDATE CHECKLIST
══════════════════════════════════════════════════════════

Update these clients (mark ✓ when done):

ONLINE CLIENTS (${#ONLINE_CLIENTS[@]}):
EOF

for ip in "${ONLINE_CLIENTS[@]}"; do
    echo "[ ] $ip - ONLINE (Priority)" >> "$UPDATE_DIR/UPDATE_CHECKLIST.txt"
done

if [ ${#OFFLINE_CLIENTS[@]} -gt 0 ]; then
    cat >> "$UPDATE_DIR/UPDATE_CHECKLIST.txt" << EOF

OFFLINE CLIENTS (${#OFFLINE_CLIENTS[@]}):
(Update when they come back online)
EOF
    for ip in "${OFFLINE_CLIENTS[@]}"; do
        echo "[ ] $ip - OFFLINE" >> "$UPDATE_DIR/UPDATE_CHECKLIST.txt"
    done
fi

cat >> "$UPDATE_DIR/UPDATE_CHECKLIST.txt" << EOF

══════════════════════════════════════════════════════════
After updating all clients:
1. Wait 15 minutes
2. Open dashboard: https://tenjo.adilabs.id/
3. Check if all clients show ONLINE with version 1.0.2
══════════════════════════════════════════════════════════
EOF

# Create quick command file
cat > "$UPDATE_DIR/QUICK_COMMAND.txt" << EOF
═══════════════════════════════════════════════════════════
QUICK COMMAND (Copy-paste on each client)
═══════════════════════════════════════════════════════════

cd C:\\ProgramData\\Tenjo && curl -O https://tenjo.adilabs.id/downloads/client/update_server_config.py && python update_server_config.py && shutdown /r /t 60

═══════════════════════════════════════════════════════════
This single line does everything:
- Changes to Tenjo directory
- Downloads update script
- Runs update
- Restarts PC in 60 seconds
═══════════════════════════════════════════════════════════
EOF

echo "✅ Files created in: $UPDATE_DIR"
echo ""
echo "📁 Created files:"
echo "   - UPDATE_INSTRUCTIONS.txt (detailed guide)"
echo "   - UPDATE_CHECKLIST.txt (track progress)"
echo "   - QUICK_COMMAND.txt (one-line command)"
echo ""
echo "========================================"
echo "🚀 NEXT STEPS"
echo "========================================"
echo ""
echo "1. Open folder: $UPDATE_DIR"
echo "2. Read UPDATE_INSTRUCTIONS.txt"
echo "3. Use QUICK_COMMAND.txt for fast copy-paste"
echo "4. Check off each IP in UPDATE_CHECKLIST.txt"
echo ""
echo "Estimated time: 5-10 minutes per client"
echo "Total time: ~2 hours for all ${#ONLINE_CLIENTS[@]} online clients"
echo ""
echo "TIP: Use Remote Desktop for faster access!"
echo "     Open multiple RDP windows to update in parallel"
echo ""
echo "========================================"

# Open the folder
open "$UPDATE_DIR"
