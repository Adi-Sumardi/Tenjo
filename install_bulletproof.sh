#!/bin/bash

# Tenjo Universal Installer - BULLETPROOF PYTHON VERSION
# Works on any macOS system with automatic Python detection and fallback

set -e
trap 'handle_error $? $LINENO' ERR

echo "============================================"
echo "   TENJO EMPLOYEE MONITORING SYSTEM        "
echo "       UNIVERSAL AUTO INSTALLER            "
echo "    BULLETPROOF PYTHON VERSION v4.0        "
echo "============================================"

# Configuration
GITHUB_REPO="https://github.com/Adi-Sumardi/Tenjo.git"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="com.tenjo.monitoring"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
LOG_FILE="$INSTALL_DIR/install.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variables
PYTHON_EXEC=""
PYTHON_PATH=""
USE_VENV=false
INSTALL_METHOD=""

print_status() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }

handle_error() {
    print_error "Installation failed at line $2 with exit code $1"
    if [ -f "$LOG_FILE" ]; then
        print_status "Full log available at: $LOG_FILE"
    fi
    exit $1
}

# Create log directory early
mkdir -p "$INSTALL_DIR"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Function to test Python installation with requirements
test_python_requirements() {
    local python_cmd="$1"
    local test_dir=$(mktemp -d)
    
    # Create minimal requirements for testing
    cat > "$test_dir/test_requirements.txt" << EOF
requests>=2.31.0
psutil>=5.9.0
EOF
    
    print_status "Testing Python installation: $python_cmd"
    
    # Test basic Python functionality
    if ! "$python_cmd" -c "import sys; print(f'Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')" 2>/dev/null; then
        rm -rf "$test_dir"
        return 1
    fi
    
    # Test pip installation methods
    cd "$test_dir"
    
    # Method 1: --user
    if "$python_cmd" -m pip install --user -r test_requirements.txt >/dev/null 2>&1; then
        INSTALL_METHOD="user"
        rm -rf "$test_dir"
        return 0
    fi
    
    # Method 2: --break-system-packages
    if "$python_cmd" -m pip install --break-system-packages -r test_requirements.txt >/dev/null 2>&1; then
        INSTALL_METHOD="break_system"
        rm -rf "$test_dir"
        return 0
    fi
    
    # Method 3: virtual environment
    if "$python_cmd" -m venv test_venv && source test_venv/bin/activate && pip install -r test_requirements.txt >/dev/null 2>&1; then
        INSTALL_METHOD="venv"
        rm -rf "$test_dir"
        return 0
    fi
    
    rm -rf "$test_dir"
    return 1
}

# Function to find working Python
find_working_python() {
    print_status "Scanning for compatible Python installations..."
    
    # Comprehensive list of Python locations
    local python_candidates=(
        # Homebrew (Apple Silicon)
        "/opt/homebrew/bin/python3"
        "/opt/homebrew/bin/python3.13"
        "/opt/homebrew/bin/python3.12"
        "/opt/homebrew/bin/python3.11"
        
        # Homebrew (Intel)
        "/usr/local/bin/python3"
        "/usr/local/bin/python3.13"
        "/usr/local/bin/python3.12"
        "/usr/local/bin/python3.11"
        
        # System Python
        "/usr/bin/python3"
        
        # PyEnv
        "$HOME/.pyenv/shims/python3"
        
        # Python.org
        "/usr/local/bin/python3"
        "/Library/Frameworks/Python.framework/Versions/3.13/bin/python3"
        "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3"
        "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3"
        
        # Conda/Miniconda
        "$HOME/miniconda3/bin/python"
        "$HOME/anaconda3/bin/python"
        "/opt/miniconda3/bin/python"
        "/opt/anaconda3/bin/python"
        
        # PATH search
        "$(command -v python3 2>/dev/null || echo '')"
        "$(command -v python 2>/dev/null || echo '')"
    )
    
    # Add glob expansions for versioned Homebrew installations
    for pattern in "/opt/homebrew/Cellar/python@3.*/*/Frameworks/Python.framework/Versions/*/bin/python3" \
                   "/usr/local/Cellar/python@3.*/*/Frameworks/Python.framework/Versions/*/bin/python3"; do
        for path in $pattern; do
            if [ -x "$path" ]; then
                python_candidates+=("$path")
            fi
        done
    done
    
    # Test each candidate
    for candidate in "${python_candidates[@]}"; do
        if [ -x "$candidate" ] && test_python_requirements "$candidate"; then
            PYTHON_EXEC="$candidate"
            PYTHON_PATH="$candidate"
            print_success "Found working Python: $candidate (Method: $INSTALL_METHOD)"
            return 0
        fi
    done
    
    return 1
}

# Function to install Python with Homebrew
install_homebrew_python() {
    print_status "Installing Python via Homebrew..."
    
    # Install Homebrew if needed
    if ! command -v brew >/dev/null 2>&1; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Configure Homebrew PATH
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Install Python
    brew install python@3.13
    
    # Find newly installed Python
    local new_python
    if [[ $(uname -m) == "arm64" ]]; then
        new_python="/opt/homebrew/bin/python3"
    else
        new_python="/usr/local/bin/python3"
    fi
    
    if test_python_requirements "$new_python"; then
        PYTHON_EXEC="$new_python"
        PYTHON_PATH="$new_python"
        print_success "Python installed and tested successfully"
        return 0
    fi
    
    return 1
}

# Function to setup Python environment
setup_python() {
    print_status "Setting up Python environment..."
    
    if find_working_python; then
        print_success "Using existing Python installation"
    elif install_homebrew_python; then
        print_success "Installed new Python via Homebrew"
    else
        print_error "Failed to setup Python environment"
        print_status "Please install Python 3.8+ manually and run the installer again"
        exit 1
    fi
}

# Function to install Tenjo
install_tenjo() {
    print_status "Installing Tenjo..."
    
    # Stop existing services
    if launchctl list | grep -q "$SERVICE_NAME" 2>/dev/null; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
    fi
    pkill -f "tenjo\|main.py" 2>/dev/null || true
    sleep 2
    
    # Clean install
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Clone repository
    if ! git clone "$GITHUB_REPO" "$INSTALL_DIR"; then
        print_error "Failed to download Tenjo from GitHub"
        exit 1
    fi
    
    # Install dependencies based on method found during Python testing
    cd "$INSTALL_DIR/client"
    mkdir -p logs
    
    case "$INSTALL_METHOD" in
        "user")
            print_status "Installing dependencies with --user flag..."
            "$PYTHON_EXEC" -m pip install --user -r requirements.txt
            ;;
        "break_system")
            print_warning "Installing dependencies with --break-system-packages..."
            "$PYTHON_EXEC" -m pip install --break-system-packages -r requirements.txt
            ;;
        "venv")
            print_status "Installing dependencies in virtual environment..."
            "$PYTHON_EXEC" -m venv "$INSTALL_DIR/venv"
            "$INSTALL_DIR/venv/bin/python" -m pip install --upgrade pip
            "$INSTALL_DIR/venv/bin/python" -m pip install -r requirements.txt
            PYTHON_EXEC="$INSTALL_DIR/venv/bin/python"
            PYTHON_PATH="$INSTALL_DIR/venv/bin/python"
            USE_VENV=true
            ;;
        *)
            print_error "Unknown installation method"
            exit 1
            ;;
    esac
    
    print_success "Dependencies installed successfully"
}

# Function to create service
create_service() {
    print_status "Creating system service..."
    
    # Ensure logs directory
    mkdir -p "$INSTALL_DIR/client/logs"
    
    # Create plist
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

    # Start service
    launchctl load "$PLIST_FILE"
    sleep 3
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        print_success "Service started successfully"
    else
        print_error "Failed to start service"
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    cd "$INSTALL_DIR/client"
    if "$PYTHON_EXEC" -c "
import sys
sys.path.append('src')
from src.core.config import Config
print(f'✓ Client ID: {Config.CLIENT_ID[:20]}...')
print(f'✓ Server: {Config.SERVER_URL}')
" 2>/dev/null; then
        print_success "Installation verified successfully"
        return 0
    else
        print_error "Installation verification failed"
        return 1
    fi
}

# Main installation function
main() {
    print_status "Starting Tenjo installation..."
    
    # Check macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This installer is only for macOS"
        exit 1
    fi
    
    # Install Git if needed
    if ! command -v git >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install git
        else
            print_error "Git is required. Please install Git and run again."
            exit 1
        fi
    fi
    
    # Run installation steps
    setup_python
    install_tenjo
    create_service
    
    if verify_installation; then
        echo ""
        echo "================================================="
        print_success "TENJO INSTALLATION COMPLETED SUCCESSFULLY!"
        echo "================================================="
        echo ""
        print_status "Installation Summary:"
        echo "  📁 Directory: $INSTALL_DIR"
        echo "  🐍 Python: $PYTHON_PATH"
        echo "  📦 Method: $INSTALL_METHOD"
        echo "  🔧 Service: $SERVICE_NAME"
        echo "  📊 Dashboard: http://103.129.149.67"
        echo ""
        print_status "Service Commands:"
        echo "  Status: launchctl list | grep $SERVICE_NAME"
        echo "  Stop:   launchctl unload $PLIST_FILE"
        echo "  Start:  launchctl load $PLIST_FILE"
        echo ""
        print_status "The client is now running and will auto-start on reboot!"
    else
        print_error "Installation completed but verification failed"
        exit 1
    fi
}

# Run installation
main "$@"
