#!/bin/bash
# Tenjo Client - Autostart Uninstaller

set -e

echo "===================================="
echo "Tenjo Client - Autostart Uninstaller"
echo "===================================="
echo ""

OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
    PLIST_NAME="com.tenjo.client"
    PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
    
    if [ ! -f "$PLIST_PATH" ]; then
        echo "⚠️  Tenjo client autostart not found"
        exit 0
    fi
    
    echo "Stopping and removing LaunchAgent..."
    launchctl stop "$PLIST_NAME" 2>/dev/null || true
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    
    echo "✅ Tenjo client autostart removed"
    echo ""
    echo "Log files preserved at:"
    echo "  ~/Library/Logs/tenjo-client-*.log"
    echo ""
    
elif [ "$OS" = "Linux" ]; then
    SERVICE_NAME="tenjo-client"
    
    if [ "$EUID" -eq 0 ]; then
        # System service
        systemctl stop $SERVICE_NAME 2>/dev/null || true
        systemctl disable $SERVICE_NAME 2>/dev/null || true
        rm -f "/etc/systemd/system/$SERVICE_NAME.service"
        systemctl daemon-reload
        echo "✅ System service removed"
    else
        # User service
        systemctl --user stop $SERVICE_NAME 2>/dev/null || true
        systemctl --user disable $SERVICE_NAME 2>/dev/null || true
        rm -f "$HOME/.config/systemd/user/$SERVICE_NAME.service"
        systemctl --user daemon-reload
        echo "✅ User service removed"
    fi
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

echo ""
echo "To reinstall, run: ./install_autostart.sh"
