#!/bin/bash

# Tenjo Remote Installer for macOS/Linux
# One-liner installer that downloads and installs from GitHub

# Usage: curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install.sh | bash

set -e

# Configuration
GITHUB_REPO="https://github.com/Adi-Sumardi/Tenjo"
RAW_URL="https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master"
TEMP_DIR="/tmp/tenjo_installer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux" 
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    print_status "Detected OS: $OS"
}

# Main installer
main() {
    clear
    echo "======================================"
    echo "   TENJO EMPLOYEE MONITORING SYSTEM   "
    echo "        Remote Auto Installer         "
    echo "======================================"
    echo ""
    
    detect_os
    
    print_status "Downloading installer from GitHub..."
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Download the appropriate installer
    if [[ "$OS" == "macos" ]]; then
        curl -sSL "$RAW_URL/auto_install_macos.sh" -o installer.sh
    else
        curl -sSL "$RAW_URL/auto_install_linux.sh" -o installer.sh
    fi
    
    # Make executable and run
    chmod +x installer.sh
    print_status "Running installer..."
    ./installer.sh
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
    
    print_success "Remote installation completed!"
}

# Error handling
trap 'print_error "Installation failed!"; exit 1' ERR

# Run main
main
