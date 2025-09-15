#!/bin/bash
# Tenjo Client Stealth Uninstaller
# Removes client and autostart configuration

set -e

INSTALL_DIR="$HOME/.tenjo"
LOG_FILE="/tmp/tenjo_uninstall.log"

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

# Stop running processes
stop_client() {
    log "Stopping Tenjo client processes..."
    
    # Kill any running python processes with main.py
    pkill -f "python.*main.py.*tenjo" 2>/dev/null || true
    pkill -f "python.*\.tenjo" 2>/dev/null || true
    
    # Wait a moment for processes to stop
    sleep 2
    
    success "Client processes stopped"
}

# Remove macOS autostart
remove_macos_autostart() {
    log "Removing macOS autostart..."
    
    PLIST_FILE="$HOME/Library/LaunchAgents/com.tenjo.client.plist"
    
    if [ -f "$PLIST_FILE" ]; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        rm -f "$PLIST_FILE"
        success "macOS autostart removed"
    else
        warn "macOS autostart not found"
    fi
}

# Remove Linux autostart
remove_linux_autostart() {
    log "Removing Linux autostart..."
    
    SERVICE_FILE="$HOME/.config/systemd/user/tenjo-client.service"
    
    if [ -f "$SERVICE_FILE" ]; then
        systemctl --user stop tenjo-client.service 2>/dev/null || true
        systemctl --user disable tenjo-client.service 2>/dev/null || true
        rm -f "$SERVICE_FILE"
        systemctl --user daemon-reload 2>/dev/null || true
        success "Linux autostart removed"
    else
        warn "Linux autostart not found"
    fi
}

# Remove installation directory
remove_installation() {
    log "Removing installation directory..."
    
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        success "Installation directory removed"
    else
        warn "Installation directory not found"
    fi
}

# Clean up system traces
cleanup_traces() {
    log "Cleaning up system traces..."
    
    # Remove any logs that might have been created elsewhere
    rm -f "$HOME/Library/Logs/tenjo"* 2>/dev/null || true
    rm -f "/tmp/tenjo"* 2>/dev/null || true
    rm -f "/var/log/tenjo"* 2>/dev/null || true
    
    # Clear any cached Python bytecode
    find "$HOME" -name "*.pyc" -path "*tenjo*" -delete 2>/dev/null || true
    find "$HOME" -name "__pycache__" -path "*tenjo*" -type d -exec rm -rf {} + 2>/dev/null || true
    
    success "System traces cleaned"
}

# Main uninstall process
main() {
    log "Starting Tenjo Client Stealth Uninstall..."
    
    # Ask for confirmation
    echo -e "${YELLOW}This will completely remove the Tenjo client from your system.${NC}"
    echo -e "${YELLOW}Are you sure you want to continue? (y/N)${NC}"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "Uninstall cancelled by user"
        exit 0
    fi
    
    stop_client
    
    # Platform-specific autostart removal
    case "$(uname -s)" in
        Darwin)
            remove_macos_autostart
            ;;
        Linux)
            remove_linux_autostart
            ;;
        *)
            warn "Platform not recognized for autostart removal"
            ;;
    esac
    
    remove_installation
    cleanup_traces
    
    success "Tenjo Client has been completely removed from your system"
    log "Uninstall completed successfully!"
    log "Log file saved to: $LOG_FILE"
}

# Run main function
main "$@"
