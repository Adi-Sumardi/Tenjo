#!/bin/bash

# Tenjo Auto Installer for macOS - FIXED VERSION
# Downloads from GitHub and installs automatically with proper Python environment handling

set -e

echo "======================================"
echo "   TENJO EMPLOYEE MONITORING SYSTEM   "
echo "         macOS Auto Installer         "
echo "         FIXED VERSION v2.0           "
echo "======================================"

# Configuration
GITHUB_REPO="https://github.com/Adi-Sumardi/Tenjo.git"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="com.tenjo.monitoring"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
PYTHON_EXEC=""
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

# Function to check and install dependencies
install_dependencies() {
    print_status "Checking dependencies..."
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Installing Git..."
        if command -v brew &> /dev/null; then
            brew install git
        else
            print_error "Homebrew not found. Please install Git manually"
            exit 1
        fi
    fi
    
    # Check for Python 3
    if command -v python3 &> /dev/null; then
        PYTHON_EXEC="python3"
        print_success "Python 3 found: $(python3 --version)"
    elif command -v python &> /dev/null; then
        PYTHON_VERSION=$(python --version 2>&1)
        if [[ $PYTHON_VERSION == *"Python 3"* ]]; then
            PYTHON_EXEC="python"
            print_success "Python 3 found: $PYTHON_VERSION"
        else
            print_error "Python 3 is required but not found"
            exit 1
        fi
    else
        print_error "Python 3 is required but not found"
        print_status "Installing Python 3 via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install python3
            PYTHON_EXEC="python3"
        else
            print_error "Please install Python 3 manually"
            exit 1
        fi
    fi
}

# Function to stop existing service
stop_existing_service() {
    print_status "Stopping existing Tenjo service..."
    
    # Stop LaunchAgent if running
    if launchctl list | grep -q "$SERVICE_NAME"; then
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
    
    # Try different installation methods
    if $PYTHON_EXEC -m pip install --user -r requirements.txt 2>/dev/null; then
        print_success "Dependencies installed using --user flag"
    elif command -v pipx &> /dev/null && pipx install -r requirements.txt 2>/dev/null; then
        print_success "Dependencies installed using pipx"
    elif $PYTHON_EXEC -m pip install --break-system-packages -r requirements.txt 2>/dev/null; then
        print_warning "Dependencies installed using --break-system-packages (not recommended)"
    else
        print_warning "Creating virtual environment for dependencies..."
        $PYTHON_EXEC -m venv "$INSTALL_DIR/venv"
        source "$INSTALL_DIR/venv/bin/activate"
        
        # Upgrade pip in virtual environment
        "$INSTALL_DIR/venv/bin/python" -m pip install --upgrade pip
        
        # Install requirements in virtual environment
        "$INSTALL_DIR/venv/bin/python" -m pip install -r requirements.txt
        
        PYTHON_EXEC="$INSTALL_DIR/venv/bin/python"
        USE_VENV=true
        print_success "Dependencies installed in virtual environment"
    fi
}

# Function to create autostart service
create_autostart_service() {
    print_status "Creating autostart service..."
    
    # Create LaunchAgent plist
    if [ "$USE_VENV" = true ]; then
        # Use virtual environment Python
        cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/venv/bin/python</string>
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
        <string>$INSTALL_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>VIRTUAL_ENV</key>
        <string>$INSTALL_DIR/venv</string>
    </dict>
</dict>
</plist>
EOF
    else
        # Use system Python
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
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/client/logs/tenjo_stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/client/logs/tenjo_stderr.log</string>
    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>
EOF
    fi

    # Set proper permissions
    chmod 644 "$PLIST_FILE"
    
    print_success "Autostart service created"
}

# Function to start the service
start_service() {
    print_status "Starting Tenjo monitoring service..."
    
    # Create logs directory
    mkdir -p "$INSTALL_DIR/client/logs"
    
    # Load and start the service
    launchctl load "$PLIST_FILE"
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if service is running
    if launchctl list | grep -q "$SERVICE_NAME"; then
        print_success "Tenjo service started successfully"
        print_status "Service is running in background (stealth mode)"
    else
        print_error "Failed to start Tenjo service"
        print_status "Checking logs for errors..."
        if [ -f "$INSTALL_DIR/client/logs/tenjo_stderr.log" ]; then
            tail -10 "$INSTALL_DIR/client/logs/tenjo_stderr.log"
        fi
        return 1
    fi
}

# Function to create uninstaller
create_uninstaller() {
    print_status "Creating uninstaller..."
    
    cat > "$INSTALL_DIR/uninstall_tenjo_macos.sh" << 'EOF'
#!/bin/bash

# Tenjo Uninstaller for macOS

SERVICE_NAME="com.tenjo.monitoring"
INSTALL_DIR="$HOME/.tenjo"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

echo "======================================"
echo "      TENJO UNINSTALLER - macOS       "
echo "======================================"

# Stop service
echo "Stopping Tenjo service..."
if launchctl list | grep -q "$SERVICE_NAME"; then
    launchctl unload "$PLIST_FILE" 2>/dev/null
fi

# Kill processes
pkill -f "tenjo" 2>/dev/null || true
pkill -f "main.py" 2>/dev/null || true

# Remove files
echo "Removing Tenjo files..."
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
fi

if [ -f "$PLIST_FILE" ]; then
    rm -f "$PLIST_FILE"
fi

echo "Tenjo has been completely removed from your system."
EOF

    chmod +x "$INSTALL_DIR/uninstall_tenjo_macos.sh"
    
    print_success "Uninstaller created at: $INSTALL_DIR/uninstall_tenjo_macos.sh"
}

# Function to show completion message
show_completion() {
    echo ""
    echo "======================================"
    print_success "TENJO INSTALLATION COMPLETED!"
    echo "======================================"
    echo ""
    print_status "Installation Details:"
    echo "  • Install Directory: $INSTALL_DIR"
    echo "  • Service Name: $SERVICE_NAME"
    echo "  • Python Environment: $([ "$USE_VENV" = true ] && echo "Virtual Environment" || echo "System Python")"
    echo "  • Python Executable: $PYTHON_EXEC"
    echo "  • Logs Directory: $INSTALL_DIR/client/logs"
    echo "  • Uninstaller: $INSTALL_DIR/uninstall_tenjo_macos.sh"
    echo ""
    print_status "Service Status:"
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo "  ✅ Service is running in background (stealth mode)"
    else
        echo "  ❌ Service is not running"
    fi
    echo ""
    print_warning "IMPORTANT NOTES:"
    echo "  • This software is for authorized monitoring only"
    echo "  • Ensure compliance with local privacy laws"
    echo "  • The service runs automatically at system startup"
    echo ""
    print_status "To uninstall: $INSTALL_DIR/uninstall_tenjo_macos.sh"
    echo ""
}

# Main installation process
main() {
    print_status "Starting Tenjo installation process..."
    
    install_dependencies
    stop_existing_service
    install_tenjo
    create_autostart_service
    start_service
    create_uninstaller
    show_completion
}

# Error handling
trap 'print_error "Installation failed. Check the error messages above."; exit 1' ERR

# Run main installation
main

print_success "Installation completed successfully!"
