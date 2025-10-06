#!/bin/bash

###############################################################################
# Tenjo Client Update Deployment Script
# Automates the process of:
# 1. Building client package
# 2. Generating version.json with checksum
# 3. Uploading to VPS
# 4. Triggering update to clients (optional)
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VPS_HOST="${VPS_HOST:-tenjo.adilabs.id}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="${VPS_PATH:-/var/www/html/tenjo/public/downloads/client}"
API_URL="${API_URL:-https://tenjo.adilabs.id}"
ADMIN_TOKEN="${TENJO_ADMIN_TOKEN:-}"

# Client configuration
CLIENT_DIR="$(cd "$(dirname "$0")/client" && pwd)"
BUILD_DIR="${CLIENT_DIR}/build"
PACKAGE_NAME=""
VERSION=""
CHANGES_FILE="${CLIENT_DIR}/.update_changes.txt"

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing_deps=0
    
    # Check required commands
    for cmd in tar sha256sum ssh scp curl jq python3; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is not installed"
            missing_deps=1
        else
            print_success "$cmd is available"
        fi
    done
    
    # Check for sha256sum alternative on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && ! command -v sha256sum &> /dev/null; then
        if command -v shasum &> /dev/null; then
            print_info "Using shasum instead of sha256sum on macOS"
            alias sha256sum='shasum -a 256'
        fi
    fi
    
    if [ $missing_deps -eq 1 ]; then
        print_error "Missing required dependencies. Please install them first."
        exit 1
    fi
    
    print_success "All dependencies satisfied"
}

get_version() {
    print_header "Version Information"
    
    # Try to read from .version file
    if [ -f "${CLIENT_DIR}/.version" ]; then
        VERSION=$(cat "${CLIENT_DIR}/.version" | tr -d '[:space:]')
        print_info "Current version from .version file: ${VERSION}"
    else
        VERSION="1.0.0"
        print_warning "No .version file found, using default: ${VERSION}"
    fi
    
    # Prompt for new version
    echo -e "\n${YELLOW}Enter new version number (current: ${VERSION}):${NC} "
    read -r new_version
    
    if [ ! -z "$new_version" ]; then
        VERSION="$new_version"
        echo "$VERSION" > "${CLIENT_DIR}/.version"
        print_success "Version updated to: ${VERSION}"
    else
        print_info "Using current version: ${VERSION}"
    fi
    
    PACKAGE_NAME="tenjo_client_${VERSION}.tar.gz"
}

get_changes() {
    print_header "Update Changes"
    
    # Check if changes file exists from previous run
    if [ -f "$CHANGES_FILE" ]; then
        print_info "Previous changes found:"
        cat "$CHANGES_FILE"
        echo -e "\n${YELLOW}Use previous changes? (y/n):${NC} "
        read -r use_previous
        
        if [[ "$use_previous" =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Create new changes
    echo -e "\n${YELLOW}Enter update changes (one per line, empty line to finish):${NC}"
    > "$CHANGES_FILE"
    
    while true; do
        read -r change
        if [ -z "$change" ]; then
            break
        fi
        echo "$change" >> "$CHANGES_FILE"
    done
    
    if [ ! -s "$CHANGES_FILE" ]; then
        echo "Bug fixes and improvements" > "$CHANGES_FILE"
        print_warning "No changes entered, using default message"
    else
        print_success "Changes recorded"
    fi
}

build_package() {
    print_header "Building Client Package"
    
    # Clean build directory
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    print_info "Cleaning Python cache files..."
    find "$CLIENT_DIR" -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find "$CLIENT_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true
    find "$CLIENT_DIR" -type f -name "*.pyo" -delete 2>/dev/null || true
    
    print_info "Creating package structure..."
    
    # Create temporary staging directory
    local staging_dir="${BUILD_DIR}/tenjo_client"
    mkdir -p "$staging_dir"
    
    # Copy necessary files
    cp "${CLIENT_DIR}/main.py" "$staging_dir/"
    cp "${CLIENT_DIR}/requirements.txt" "$staging_dir/"
    cp -r "${CLIENT_DIR}/src" "$staging_dir/"
    
    # Copy platform-specific autostart scripts
    cp "${CLIENT_DIR}/install_autostart.sh" "$staging_dir/" 2>/dev/null || true
    cp "${CLIENT_DIR}/install_autostart.ps1" "$staging_dir/" 2>/dev/null || true
    cp "${CLIENT_DIR}/uninstall_autostart.sh" "$staging_dir/" 2>/dev/null || true
    cp "${CLIENT_DIR}/uninstall_autostart.ps1" "$staging_dir/" 2>/dev/null || true
    
    # Create version file
    echo "$VERSION" > "${staging_dir}/.version"
    
    # Create package
    print_info "Creating tarball..."
    cd "$BUILD_DIR"
    tar -czf "$PACKAGE_NAME" tenjo_client/
    
    local package_size=$(stat -f%z "$PACKAGE_NAME" 2>/dev/null || stat -c%s "$PACKAGE_NAME")
    print_success "Package created: ${PACKAGE_NAME} ($(numfmt --to=iec-i --suffix=B $package_size 2>/dev/null || echo ${package_size} bytes))"
}

generate_checksum() {
    print_header "Generating Checksum"
    
    cd "$BUILD_DIR"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CHECKSUM=$(shasum -a 256 "$PACKAGE_NAME" | awk '{print $1}')
    else
        CHECKSUM=$(sha256sum "$PACKAGE_NAME" | awk '{print $1}')
    fi
    
    print_success "SHA256: ${CHECKSUM}"
}

generate_version_json() {
    print_header "Generating version.json"
    
    local package_size=$(stat -f%z "${BUILD_DIR}/${PACKAGE_NAME}" 2>/dev/null || stat -c%s "${BUILD_DIR}/${PACKAGE_NAME}")
    
    # Read changes from file and convert to JSON array
    local changes_json=$(python3 -c "
import json
with open('$CHANGES_FILE', 'r') as f:
    changes = [line.strip() for line in f if line.strip()]
print(json.dumps(changes))
")
    
    # Generate version.json
    cat > "${BUILD_DIR}/version.json" <<EOF
{
  "version": "${VERSION}",
  "download_url": "${API_URL}/downloads/client/${PACKAGE_NAME}",
  "server_url": "${API_URL}",
  "changes": ${changes_json},
  "checksum": "${CHECKSUM}",
  "package_size": ${package_size},
  "priority": "normal",
  "release_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    print_success "version.json generated"
    print_info "Content:"
    cat "${BUILD_DIR}/version.json" | jq '.' 2>/dev/null || cat "${BUILD_DIR}/version.json"
}

upload_to_vps() {
    print_header "Uploading to VPS"
    
    print_info "Target: ${VPS_USER}@${VPS_HOST}:${VPS_PATH}"
    
    # Check SSH connection
    if ! ssh -o ConnectTimeout=5 "${VPS_USER}@${VPS_HOST}" "echo 'Connection OK'" &>/dev/null; then
        print_error "Cannot connect to VPS via SSH"
        print_warning "Make sure SSH key is configured or provide password"
        return 1
    fi
    
    print_success "SSH connection established"
    
    # Create directory on VPS if not exists
    print_info "Ensuring directory exists on VPS..."
    ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p ${VPS_PATH}"
    
    # Upload package
    print_info "Uploading ${PACKAGE_NAME}..."
    scp "${BUILD_DIR}/${PACKAGE_NAME}" "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/"
    print_success "Package uploaded"
    
    # Upload version.json
    print_info "Uploading version.json..."
    scp "${BUILD_DIR}/version.json" "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/"
    print_success "version.json uploaded"
    
    # Set proper permissions
    print_info "Setting permissions..."
    ssh "${VPS_USER}@${VPS_HOST}" "chmod 644 ${VPS_PATH}/${PACKAGE_NAME} ${VPS_PATH}/version.json"
    print_success "Permissions set"
    
    print_success "Upload completed successfully!"
}

trigger_update() {
    print_header "Trigger Client Updates"
    
    if [ -z "$ADMIN_TOKEN" ]; then
        print_warning "TENJO_ADMIN_TOKEN not set, skipping automatic update trigger"
        print_info "You can manually trigger updates from the dashboard"
        return
    fi
    
    echo -e "\n${YELLOW}Update deployment mode:${NC}"
    echo "  1) Trigger specific client (requires client_id)"
    echo "  2) Trigger all clients"
    echo "  3) Skip (manual trigger from dashboard)"
    echo -e "\n${YELLOW}Select option (1-3):${NC} "
    read -r trigger_mode
    
    case $trigger_mode in
        1)
            echo -e "\n${YELLOW}Enter client_id:${NC} "
            read -r client_id
            
            if [ -z "$client_id" ]; then
                print_error "No client_id provided"
                return 1
            fi
            
            print_info "Triggering update for client: ${client_id}"
            
            response=$(curl -s -X POST "${API_URL}/api/clients/${client_id}/trigger-update" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{
                    \"version\": \"${VERSION}\",
                    \"update_url\": \"${API_URL}/downloads/client/${PACKAGE_NAME}\",
                    \"changes\": $(cat "$CHANGES_FILE" | python3 -c "import sys, json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))"),
                    \"checksum\": \"${CHECKSUM}\",
                    \"priority\": \"normal\"
                }")
            
            if echo "$response" | jq -e '.success' &>/dev/null; then
                print_success "Update triggered successfully for ${client_id}"
            else
                print_error "Failed to trigger update: $response"
                return 1
            fi
            ;;
            
        2)
            print_warning "This will trigger update for ALL registered clients!"
            echo -e "${YELLOW}Are you sure? (yes/no):${NC} "
            read -r confirm
            
            if [ "$confirm" != "yes" ]; then
                print_info "Bulk update cancelled"
                return
            fi
            
            print_info "Triggering bulk update..."
            
            response=$(curl -s -X POST "${API_URL}/api/clients/schedule-update" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{
                    \"version\": \"${VERSION}\",
                    \"update_url\": \"${API_URL}/downloads/client/${PACKAGE_NAME}\",
                    \"changes\": $(cat "$CHANGES_FILE" | python3 -c "import sys, json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))"),
                    \"checksum\": \"${CHECKSUM}\",
                    \"priority\": \"normal\"
                }")
            
            if echo "$response" | jq -e '.success' &>/dev/null; then
                targets=$(echo "$response" | jq -r '.targets')
                print_success "Bulk update triggered for ${targets} clients"
            else
                print_error "Failed to trigger bulk update: $response"
                return 1
            fi
            ;;
            
        3)
            print_info "Skipping automatic trigger"
            print_info "You can manually trigger updates from: ${API_URL}/dashboard"
            ;;
            
        *)
            print_warning "Invalid option, skipping trigger"
            ;;
    esac
}

cleanup() {
    print_header "Cleanup"
    
    echo -e "${YELLOW}Keep build directory? (y/n):${NC} "
    read -r keep_build
    
    if [[ ! "$keep_build" =~ ^[Yy]$ ]]; then
        rm -rf "$BUILD_DIR"
        print_success "Build directory cleaned"
    else
        print_info "Build directory kept at: ${BUILD_DIR}"
    fi
}

show_summary() {
    print_header "Deployment Summary"
    
    echo -e "${GREEN}Version:${NC}      ${VERSION}"
    echo -e "${GREEN}Package:${NC}      ${PACKAGE_NAME}"
    echo -e "${GREEN}Checksum:${NC}     ${CHECKSUM}"
    echo -e "${GREEN}VPS Path:${NC}     ${VPS_USER}@${VPS_HOST}:${VPS_PATH}"
    echo -e "${GREEN}Download URL:${NC} ${API_URL}/downloads/client/${PACKAGE_NAME}"
    
    echo -e "\n${BLUE}Changes:${NC}"
    cat "$CHANGES_FILE"
    
    echo -e "\n${GREEN}Deployment completed successfully! 🚀${NC}\n"
}

###############################################################################
# Main Script
###############################################################################

main() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   ████████╗███████╗███╗   ██╗     ██╗ ██████╗             ║
║   ╚══██╔══╝██╔════╝████╗  ██║     ██║██╔═══██╗            ║
║      ██║   █████╗  ██╔██╗ ██║     ██║██║   ██║            ║
║      ██║   ██╔══╝  ██║╚██╗██║██   ██║██║   ██║            ║
║      ██║   ███████╗██║ ╚████║╚█████╔╝╚██████╔╝            ║
║      ╚═╝   ╚══════╝╚═╝  ╚═══╝ ╚════╝  ╚═════╝             ║
║                                                            ║
║            Client Update Deployment Script                ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    check_dependencies
    get_version
    get_changes
    build_package
    generate_checksum
    generate_version_json
    upload_to_vps
    trigger_update
    cleanup
    show_summary
}

# Run main function
main
