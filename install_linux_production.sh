#!/bin/bash

# Tenjo Production Installer for Linux
# Compatible with Python 3.13+ and modern Linux distributions
# Includes OS detection and stealth installation

set -e

echo "=================================================="
echo "    TENJO EMPLOYEE MONITORING SYSTEM v2.0        "
echo "         Production Linux Installer              "
echo "         Python 3.13+ Compatible                 "
echo "=================================================="

# Configuration
GITHUB_REPO="https://github.com/Adi-Sumardi/Tenjo.git"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="tenjo-monitoring"
SYSTEMD_SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME.service"
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

# Function to detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="rhel"
    else
        DISTRO="unknown"
    fi
    
    print_status "Detected distribution: $DISTRO $DISTRO_VERSION"
}

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

# Function to install system dependencies
install_system_dependencies() {
    print_status "Installing system dependencies..."
    
    case $DISTRO in
        ubuntu|debian)
            print_status "Installing dependencies for Ubuntu/Debian..."
            if ! command -v git &> /dev/null; then
                sudo apt update && sudo apt install -y git
            fi
            
            # Install development packages for Python compilation if needed
            sudo apt install -y build-essential python3-dev libxcb1-dev libxcb-xinerama0-dev libx11-dev
            ;;
        rhel|centos|fedora)
            print_status "Installing dependencies for RHEL/CentOS/Fedora..."
            if ! command -v git &> /dev/null; then
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y git
                else
                    sudo yum install -y git
                fi
            fi
            
            # Install development packages
            if command -v dnf &> /dev/null; then
                sudo dnf groupinstall -y "Development Tools"
                sudo dnf install -y python3-devel libX11-devel
            else
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y python3-devel libX11-devel
            fi
            ;;
        arch)
            print_status "Installing dependencies for Arch Linux..."
            if ! command -v git &> /dev/null; then
                sudo pacman -S --noconfirm git
            fi
            sudo pacman -S --noconfirm base-devel python libxcb libx11
            ;;
        *)
            print_warning "Unknown distribution. Please install git and development tools manually."
            ;;
    esac
}

# Function to install dependencies
install_dependencies() {
    print_status "Checking dependencies..."
    
    detect_distro
    install_system_dependencies
    
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
        print_status "Installing Python..."
        
        case $DISTRO in
            ubuntu|debian)
                sudo apt update && sudo apt install -y python3.13 python3.13-pip python3.13-venv
                PYTHON_EXEC="python3.13"
                ;;
            rhel|centos|fedora)
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y python3.13 python3.13-pip
                else
                    print_error "Python 3.13 not available in repositories. Please install manually."
                    exit 1
                fi
                PYTHON_EXEC="python3.13"
                ;;
            arch)
                sudo pacman -S --noconfirm python python-pip
                PYTHON_EXEC="python3"
                ;;
            *)
                print_error "Please install Python $PYTHON_MINIMUM_VERSION manually"
                exit 1
                ;;
        esac
    fi
    
    print_success "Using Python: $($PYTHON_EXEC --version)"
    
    # Check for pip
    if ! $PYTHON_EXEC -m pip --version &> /dev/null; then
        print_warning "pip not found. Installing pip..."
        case $DISTRO in
            ubuntu|debian)
                sudo apt install -y python3-pip
                ;;
            rhel|centos|fedora)
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y python3-pip
                else
                    sudo yum install -y python3-pip
                fi
                ;;
            arch)
                sudo pacman -S --noconfirm python-pip
                ;;
        esac
    fi
}

# Function to stop existing service
stop_existing_service() {
    print_status "Stopping existing Tenjo service..."
    
    # Kill any running Tenjo processes
    pkill -f "python.*main.py" 2>/dev/null || true
    pkill -f "Tenjo" 2>/dev/null || true
    
    # Stop systemd service if running
    if systemctl --user is-active "$SERVICE_NAME" &> /dev/null; then
        systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
        systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
        print_success "Existing service stopped"
    fi
    
    # Remove existing service file
    if [[ -f "$SYSTEMD_SERVICE_FILE" ]]; then
        rm "$SYSTEMD_SERVICE_FILE"
        systemctl --user daemon-reload
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

# Function to create systemd service
create_service() {
    print_status "Creating systemd user service..."
    
    # Create systemd user directory if it doesn't exist
    mkdir -p "$(dirname "$SYSTEMD_SERVICE_FILE")"
    
    # Create systemd service file
    cat > "$SYSTEMD_SERVICE_FILE" << EOF
[Unit]
Description=Tenjo Employee Monitoring Service
After=network.target

[Service]
Type=simple
ExecStart=$PYTHON_EXEC $INSTALL_DIR/client/main.py
WorkingDirectory=$INSTALL_DIR/client
Restart=always
RestartSec=10
Environment=DISPLAY=:0
StandardOutput=append:$INSTALL_DIR/client/logs/service.log
StandardError=append:$INSTALL_DIR/client/logs/service.log

[Install]
WantedBy=default.target
EOF

    # Reload systemd and enable service
    systemctl --user daemon-reload
    
    if systemctl --user enable "$SERVICE_NAME"; then
        print_success "Service enabled"
        
        if systemctl --user start "$SERVICE_NAME"; then
            print_success "Service started"
        else
            print_error "Failed to start service"
            exit 1
        fi
    else
        print_error "Failed to enable service"
        exit 1
    fi
}

# Function to create uninstaller
create_uninstaller() {
    print_status "Creating uninstaller..."
    
    cat > "$INSTALL_DIR/uninstall_tenjo_linux.sh" << 'EOF'
#!/bin/bash

echo "======================================="
echo "       Tenjo Uninstaller for Linux     "
echo "======================================="

SERVICE_NAME="tenjo-monitoring"
INSTALL_DIR="$HOME/.tenjo"
SYSTEMD_SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME.service"

echo "[INFO] Stopping Tenjo service..."
systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true

echo "[INFO] Removing service configuration..."
rm -f "$SYSTEMD_SERVICE_FILE"
systemctl --user daemon-reload

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

    chmod +x "$INSTALL_DIR/uninstall_tenjo_linux.sh"
    print_success "Uninstaller created at: $INSTALL_DIR/uninstall_tenjo_linux.sh"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if service is running
    sleep 3
    if systemctl --user is-active "$SERVICE_NAME" &> /dev/null; then
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
    echo "   • Service: $SERVICE_NAME (systemd user service)"
    echo "   • Logs: $INSTALL_DIR/client/logs/"
    echo "   • Uninstaller: $INSTALL_DIR/uninstall_tenjo_linux.sh"
    echo
    echo "🔒 Security Notes:"
    echo "   • Service runs as user service (not system-wide)"
    echo "   • Auto-starts at user login"
    echo "   • Logs are stored locally"
    echo
    echo "⚠️  Important:"
    echo "   • This software is for authorized monitoring only"
    echo "   • Ensure compliance with local privacy laws"
    echo "   • Keep installation directory secure"
    echo
    echo "🗑️  To uninstall: $INSTALL_DIR/uninstall_tenjo_linux.sh"
    echo
    echo "📊 Service Management:"
    echo "   • Status: systemctl --user status $SERVICE_NAME"
    echo "   • Stop: systemctl --user stop $SERVICE_NAME"
    echo "   • Start: systemctl --user start $SERVICE_NAME"
    echo "   • Restart: systemctl --user restart $SERVICE_NAME"
    echo
    print_success "Installation completed! Tenjo is now running as a user service."
}

# Run main installation
main

exit 0