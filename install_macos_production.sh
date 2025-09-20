#!/bin/bash

# Tenjo Production Installer for macOS
# Compatible with Python 3.13+ and modern macOS versions
# Includes OS detection and stealth installation

set -e

echo "=================================================="
echo "    TENJO EMPLOYEE MONITORING SYSTEM v2.0        "
echo "         Production macOS Installer               "
echo "         Python 3.13+ Compatible                 "
echo "=================================================="

# Configuration
GITHUB_REPO="https://github.com/Adi-Sumardi/Tenjo.git"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="com.tenjo.monitoring"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
PYTHON_EXEC=""
PYTHON_MINIMUM_VERSION="3.13"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Security check
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Function to compare Python versions
version_compare() {
    printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1
}

# Function to check Python version compatibility
check_python_version() {
    local python_cmd="$1"
    local version=$($python_cmd --version 2>&1 | cut -d' ' -f2)
    
    if [[ $(version_compare "$version" "$PYTHON_MINIMUM_VERSION") == "$PYTHON_MINIMUM_VERSION" ]]; then
        print_success "Python $version is compatible (>= $PYTHON_MINIMUM_VERSION)"
        return 0
    else
        print_error "Python $version is too old (requires >= $PYTHON_MINIMUM_VERSION)"
        return 1
    fi
}

# Function to install dependencies
install_dependencies() {
    print_status "Checking system dependencies..."
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Installing Git..."
        if command -v brew &> /dev/null; then
            brew install git
        else
            print_error "Homebrew not found. Please install Git manually from: https://git-scm.com/"
            exit 1
        fi
    fi
    
    # Check for Python 3.13+
    if command -v python3 &> /dev/null; then
        if check_python_version python3; then
            PYTHON_EXEC="python3"
        fi
    fi
    
    if [[ -z "$PYTHON_EXEC" ]] && command -v python &> /dev/null; then
        PYTHON_VERSION=$(python --version 2>&1)
        if [[ $PYTHON_VERSION == *"Python 3"* ]]; then
            if check_python_version python; then
                PYTHON_EXEC="python"
            fi
        fi
    fi
    
    if [[ -z "$PYTHON_EXEC" ]]; then
        print_error "Python $PYTHON_MINIMUM_VERSION or higher is required"
        print_status "Installing Python via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install python@3.13
            PYTHON_EXEC="python3"
        else
            print_error "Please install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            print_error "Then install Python: brew install python@3.13"
            exit 1
        fi
    fi
    
    print_success "Using Python: $($PYTHON_EXEC --version)"
}

# Function to stop existing service
stop_existing_service() {
    print_status "Stopping existing Tenjo service..."
    
    # Kill any running Tenjo processes
    pkill -f "python.*main.py" 2>/dev/null || true
    pkill -f "Tenjo" 2>/dev/null || true
    
    # Stop LaunchAgent if running
    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        print_success "Existing service stopped"
    fi
    
    # Remove existing LaunchAgent
    if [[ -f "$PLIST_FILE" ]]; then
        rm "$PLIST_FILE"
        print_success "Existing service configuration removed"
    fi
}

# Function to download and install Tenjo
install_tenjo() {
    print_status "Downloading Tenjo from GitHub..."
    
    # Remove existing installation
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone repository
    if ! git clone "$GITHUB_REPO" "$INSTALL_DIR"; then
        print_error "Failed to download Tenjo from GitHub"
        exit 1
    fi
    
    print_success "Tenjo downloaded successfully"
    
    # Navigate to client directory
    cd "$INSTALL_DIR/client"
    
    print_status "Installing Python dependencies..."
    
    # Try different installation methods
    if $PYTHON_EXEC -m pip install --user -r requirements.txt 2>/dev/null; then
        print_success "Dependencies installed using pip --user"
    elif $PYTHON_EXEC -m pip install --break-system-packages -r requirements.txt 2>/dev/null; then
        print_success "Dependencies installed using pip --break-system-packages"
    else
        print_warning "Standard pip installation failed. Creating virtual environment..."
        $PYTHON_EXEC -m venv "$INSTALL_DIR/venv"
        source "$INSTALL_DIR/venv/bin/activate"
        "$INSTALL_DIR/venv/bin/python" -m pip install --upgrade pip
        "$INSTALL_DIR/venv/bin/python" -m pip install -r requirements.txt
        PYTHON_EXEC="$INSTALL_DIR/venv/bin/python"
        print_success "Dependencies installed in virtual environment"
    fi
}

# Function to test OS detection
test_os_detection() {
    print_status "Testing OS detection system..."
    
    cd "$INSTALL_DIR/client"
    
    local os_test_result=$($PYTHON_EXEC -c "
from os_detector import get_os_info_for_client
import json
try:
    os_info = get_os_info_for_client()
    print(f'SUCCESS: {os_info[\"name\"]} {os_info[\"version\"]} ({os_info[\"architecture\"]})')
except Exception as e:
    print(f'ERROR: {e}')
    exit(1)
" 2>&1)
    
    if [[ $os_test_result == SUCCESS:* ]]; then
        print_success "OS Detection: ${os_test_result#SUCCESS: }"
    else
        print_error "OS Detection failed: $os_test_result"
        exit 1
    fi
}

# Function to create stealth service
create_service() {
    print_status "Creating stealth service configuration..."
    
    # Create LaunchAgent plist
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_EXEC</string>
        <string>$INSTALL_DIR/client/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR/client</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/client/logs/service.log</string>
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/client/logs/service.log</string>
    <key>ProcessType</key>
    <string>Background</string>
    <key>LaunchOnlyOnce</key>
    <false/>
</dict>
</plist>
EOF

    # Set proper permissions
    chmod 644 "$PLIST_FILE"
    
    # Load the service
    if launchctl load "$PLIST_FILE"; then
        print_success "Stealth service configured and started"
    else
        print_error "Failed to start service"
        exit 1
    fi
}

# Function to create uninstaller
create_uninstaller() {
    print_status "Creating uninstaller..."
    
    cat > "$INSTALL_DIR/uninstall_tenjo_macos.sh" << 'EOF'
#!/bin/bash

echo "======================================="
echo "       Tenjo Uninstaller for macOS     "
echo "======================================="

SERVICE_NAME="com.tenjo.monitoring"
INSTALL_DIR="$HOME/.tenjo"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

echo "[INFO] Stopping Tenjo service..."
launchctl unload "$PLIST_FILE" 2>/dev/null || true

echo "[INFO] Removing service configuration..."
rm -f "$PLIST_FILE"

echo "[INFO] Killing any running Tenjo processes..."
pkill -f "python.*main.py" 2>/dev/null || true
pkill -f "Tenjo" 2>/dev/null || true

echo "[INFO] Removing Tenjo files..."
sleep 2
rm -rf "$INSTALL_DIR"

echo "[SUCCESS] Tenjo has been completely removed from your system."
echo "Press any key to exit..."
read -n 1
EOF

    chmod +x "$INSTALL_DIR/uninstall_tenjo_macos.sh"
    print_success "Uninstaller created at: $INSTALL_DIR/uninstall_tenjo_macos.sh"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if service is running
    sleep 3
    if launchctl list | grep -q "$SERVICE_NAME"; then
        print_success "Service is running successfully"
    else
        print_warning "Service may not be running properly"
    fi
    
    # Check if client can start
    cd "$INSTALL_DIR/client"
    if timeout 5 $PYTHON_EXEC -c "
import sys
sys.path.append('src')
from src.core.config import Config
from os_detector import get_os_info_for_client
print('✅ Client initialization test passed')
" 2>/dev/null; then
        print_success "Client initialization test passed"
    else
        print_warning "Client initialization test failed"
    fi
}

# Main installation flow
main() {
    print_status "Starting Tenjo production installation..."
    
    install_dependencies
    stop_existing_service
    install_tenjo
    test_os_detection
    create_service
    create_uninstaller
    verify_installation
    
    echo
    echo "=================================================="
    echo "   🎉 TENJO INSTALLATION COMPLETED SUCCESSFULLY!   "
    echo "=================================================="
    echo
    echo "📋 Installation Details:"
    echo "   • Install Directory: $INSTALL_DIR"
    echo "   • Python Version: $($PYTHON_EXEC --version)"
    echo "   • Service: $SERVICE_NAME (running in background)"
    echo "   • Logs: $INSTALL_DIR/client/logs/"
    echo "   • Uninstaller: $INSTALL_DIR/uninstall_tenjo_macos.sh"
    echo
    echo "🔒 Security Notes:"
    echo "   • Service runs in stealth mode (background)"
    echo "   • Auto-starts at system boot"
    echo "   • Logs are stored locally"
    echo
    echo "⚠️  Important:"
    echo "   • This software is for authorized monitoring only"
    echo "   • Ensure compliance with local privacy laws"
    echo "   • Keep installation directory secure"
    echo
    echo "🗑️  To uninstall: $INSTALL_DIR/uninstall_tenjo_macos.sh"
    echo
    print_success "Installation completed! Tenjo is now running in stealth mode."
}

# Run main installation
main

exit 0