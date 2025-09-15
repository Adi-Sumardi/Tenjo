#!/bin/bash

# Tenjo Auto Installer for macOS - ROBUST PYTHON VERSION v3.0
# Downloads from GitHub and installs automatically with bulletproof Python environment handling

set -e

echo "======================================"
echo "   TENJO EMPLOYEE MONITORING SYSTEM   "
echo "         macOS Auto Installer         "
echo "      ROBUST PYTHON VERSION v3.0      "
echo "======================================"

# Configuration
GITHUB_REPO="https://github.com/Adi-Sumardi/Tenjo.git"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="com.tenjo.monitoring"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
PYTHON_EXEC=""
PYTHON_PATH=""
USE_VENV=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Function to find the best Python installation
find_best_python() {
    print_status "Searching for the best Python installation..."
    
    # List of Python paths to check in order of preference
    PYTHON_CANDIDATES=(
        "/opt/homebrew/bin/python3"
        "/opt/homebrew/Cellar/python@3.13/*/Frameworks/Python.framework/Versions/3.13/bin/python3"
        "/opt/homebrew/Cellar/python@3.12/*/Frameworks/Python.framework/Versions/3.12/bin/python3"
        "/opt/homebrew/Cellar/python@3.11/*/Frameworks/Python.framework/Versions/3.11/bin/python3"
        "/usr/local/bin/python3"
        "/usr/bin/python3"
        "$(which python3 2>/dev/null || echo '')"
        "$(which python 2>/dev/null || echo '')"
    )
    
    # Check each candidate
    for candidate in "${PYTHON_CANDIDATES[@]}"; do
        # Expand glob patterns
        for python_path in $candidate; do
            if [ -x "$python_path" ]; then
                # Check if it's Python 3.8+
                version=$("$python_path" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
                major=$(echo "$version" | cut -d. -f1)
                minor=$(echo "$version" | cut -d. -f2)
                
                if [ "$major" = "3" ] && [ "$minor" -ge "8" ]; then
                    PYTHON_EXEC="$python_path"
                    PYTHON_PATH="$python_path"
                    print_success "Found suitable Python: $python_path (Python $version)"
                    return 0
                fi
            fi
        done
    done
    
    print_error "No suitable Python 3.8+ installation found"
    return 1
}

# Function to install Python if not found
install_python() {
    print_status "Installing Python via Homebrew..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    # Install Python
    brew install python@3.13
    
    # Set Python path
    if [[ $(uname -m) == "arm64" ]]; then
        PYTHON_PATH="/opt/homebrew/bin/python3"
    else
        PYTHON_PATH="/usr/local/bin/python3"
    fi
    
    PYTHON_EXEC="$PYTHON_PATH"
    print_success "Python installed successfully: $PYTHON_PATH"
}

# Function to check and install dependencies
install_dependencies() {
    print_status "Checking dependencies..."
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Installing Git..."
        if command -v brew &> /dev/null; then
            brew install git
        else
            print_error "Please install Git manually"
            exit 1
        fi
    fi
    
    # Find or install Python
    if ! find_best_python; then
        install_python
    fi
    
    print_success "All dependencies ready"
}

# Function to stop existing service
stop_existing_service() {
    print_status "Stopping existing Tenjo service..."
    
    # Stop LaunchAgent if running
    if launchctl list | grep -q "$SERVICE_NAME" 2>/dev/null; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        print_success "Existing service stopped"
    fi
    
    # Kill any running Tenjo processes
    pkill -f "tenjo" 2>/dev/null || true
    pkill -f "main.py" 2>/dev/null || true
    sleep 2
}

# Function to download and install Tenjo
install_tenjo() {
    print_status "Downloading Tenjo from GitHub..."
    
    # Remove existing installation
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Clone repository
    git clone "$GITHUB_REPO" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    print_success "Tenjo downloaded successfully"
    
    # Install Python dependencies
    print_status "Installing Python dependencies..."
    cd "$INSTALL_DIR/client"
    
    # Create requirements log directory
    mkdir -p logs
    
    # Multi-tier installation strategy
    if install_requirements_user; then
        print_success "Dependencies installed with --user flag"
    elif install_requirements_break_system; then
        print_warning "Dependencies installed with --break-system-packages"
    elif install_requirements_venv; then
        print_success "Dependencies installed in virtual environment"
        USE_VENV=true
    else
        print_error "Failed to install Python dependencies"
        exit 1
    fi
}

# Tier 1: Install with --user flag
install_requirements_user() {
    print_status "Attempting installation with --user flag..."
    "$PYTHON_EXEC" -m pip install --user -r requirements.txt > logs/pip_install.log 2>&1
}

# Tier 2: Install with --break-system-packages
install_requirements_break_system() {
    print_status "Attempting installation with --break-system-packages..."
    "$PYTHON_EXEC" -m pip install --break-system-packages -r requirements.txt > logs/pip_install.log 2>&1
}

# Tier 3: Install in virtual environment
install_requirements_venv() {
    print_status "Creating virtual environment..."
    "$PYTHON_EXEC" -m venv "$INSTALL_DIR/venv"
    
    # Upgrade pip in virtual environment
    "$INSTALL_DIR/venv/bin/python" -m pip install --upgrade pip
    
    # Install requirements in virtual environment
    "$INSTALL_DIR/venv/bin/python" -m pip install -r requirements.txt > logs/pip_install.log 2>&1
    
    # Update Python exec path
    PYTHON_EXEC="$INSTALL_DIR/venv/bin/python"
    PYTHON_PATH="$INSTALL_DIR/venv/bin/python"
    return 0
}

# Function to create autostart service
create_autostart_service() {
    print_status "Creating autostart service..."
    
    # Ensure logs directory exists
    mkdir -p "$INSTALL_DIR/client/logs"
    
    # Create LaunchAgent plist with the correct Python path
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_PATH</string>
        <string>$INSTALL_DIR/client/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR/client</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/client/logs/tenjo_stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/client/logs/tenjo_stderr.log</string>
    <key>ProcessType</key>
    <string>Background</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>PYTHONPATH</key>
        <string>$INSTALL_DIR/client/src</string>
EOF

    # Add virtual environment variables if using venv
    if [ "$USE_VENV" = true ]; then
        cat >> "$PLIST_FILE" << EOF
        <key>VIRTUAL_ENV</key>
        <string>$INSTALL_DIR/venv</string>
EOF
    fi

    cat >> "$PLIST_FILE" << EOF
    </dict>
</dict>
</plist>
EOF

    print_success "Service configuration created"
}

# Function to start service
start_service() {
    print_status "Starting Tenjo service..."
    
    # Load and start the service
    launchctl load "$PLIST_FILE"
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if service is running
    if launchctl list | grep -q "$SERVICE_NAME"; then
        print_success "Tenjo service started successfully"
        
        # Get service PID
        PID=$(launchctl list | grep "$SERVICE_NAME" | awk '{print $1}')
        if [ "$PID" != "-" ]; then
            print_success "Service running with PID: $PID"
        fi
    else
        print_error "Failed to start Tenjo service"
        print_status "Checking logs..."
        if [ -f "$INSTALL_DIR/client/logs/tenjo_stderr.log" ]; then
            echo "Error log:"
            tail -10 "$INSTALL_DIR/client/logs/tenjo_stderr.log"
        fi
        exit 1
    fi
}

# Function to create uninstaller
create_uninstaller() {
    print_status "Creating uninstaller..."
    
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
# Tenjo Uninstaller

SERVICE_NAME="com.tenjo.monitoring"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
INSTALL_DIR="$HOME/.tenjo"

echo "Uninstalling Tenjo..."

# Stop and remove service
launchctl unload "$PLIST_FILE" 2>/dev/null || true
rm -f "$PLIST_FILE"

# Kill any running processes
pkill -f "tenjo" 2>/dev/null || true
pkill -f "main.py" 2>/dev/null || true

# Remove installation directory
rm -rf "$INSTALL_DIR"

echo "Tenjo uninstalled successfully"
EOF
    
    chmod +x "$INSTALL_DIR/uninstall.sh"
    print_success "Uninstaller created at $INSTALL_DIR/uninstall.sh"
}

# Function to test installation
test_installation() {
    print_status "Testing installation..."
    
    # Test Python and imports
    cd "$INSTALL_DIR/client"
    if "$PYTHON_EXEC" -c "
import sys
sys.path.append('src')
from src.core.config import Config
from src.utils.api_client import APIClient
print(f'✓ Client ID: {Config.CLIENT_ID[:20]}...')
print(f'✓ Server: {Config.SERVER_URL}')
api_client = APIClient(Config.SERVER_URL, Config.API_KEY)
print('✓ All components loaded successfully')
" 2>/dev/null; then
        print_success "Installation test passed"
        return 0
    else
        print_error "Installation test failed"
        return 1
    fi
}

# Main installation process
main() {
    print_status "Starting Tenjo installation..."
    
    # Check system compatibility
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This installer is only for macOS"
        exit 1
    fi
    
    # Run installation steps
    install_dependencies
    stop_existing_service
    install_tenjo
    create_autostart_service
    start_service
    create_uninstaller
    
    # Test installation
    if test_installation; then
        echo ""
        echo "======================================"
        print_success "TENJO INSTALLATION COMPLETED!"
        echo "======================================"
        echo ""
        print_status "Installation Details:"
        echo "  📁 Install Directory: $INSTALL_DIR"
        echo "  🐍 Python Path: $PYTHON_PATH"
        echo "  🔧 Service: $SERVICE_NAME"
        echo "  📊 Dashboard: http://103.129.149.67"
        echo ""
        print_status "Service Management:"
        echo "  Status:    launchctl list | grep $SERVICE_NAME"
        echo "  Stop:      launchctl unload $PLIST_FILE"
        echo "  Start:     launchctl load $PLIST_FILE"
        echo "  Uninstall: $INSTALL_DIR/uninstall.sh"
        echo ""
        print_status "The client will automatically start monitoring and will restart on reboot."
        echo ""
    else
        print_error "Installation completed but tests failed. Check logs in $INSTALL_DIR/client/logs/"
        exit 1
    fi
}

# Run main installation
main
