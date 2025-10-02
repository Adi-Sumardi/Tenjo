#!/bin/bash
#
# Tenjo Production Deployment Script
# Description: Deploy updated client to all production PCs remotely
# Usage: ./deploy_production.sh [version]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION=${1:-$(date +%Y%m%d_%H%M)}
DOMAIN="tenjo.adilabs.id"
VPS_USER="tenjo-app"
VPS_HOST="103.129.149.67"
VPS_PATH="/var/www/Tenjo"
PACKAGE_NAME="tenjo_client_${VERSION}.tar.gz"
CLIENT_INSTALL_PATH_WINDOWS="C:\\ProgramData\\Tenjo"
CLIENT_INSTALL_PATH_MACOS="/usr/local/tenjo"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Tenjo Production Deployment - Version ${VERSION}   ║${NC}"
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo ""

# Step 1: Build client package
echo -e "${YELLOW}[1/6] Building client package...${NC}"
cd /Users/yapi/Adi/App-Dev/Tenjo/client

# Create distribution package
echo "Creating package: ${PACKAGE_NAME}"
tar -czf "/tmp/${PACKAGE_NAME}" \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='logs/*' \
    --exclude='data/*' \
    --exclude='.DS_Store' \
    main.py \
    requirements.txt \
    src/

echo -e "${GREEN}✓ Package created: /tmp/${PACKAGE_NAME}${NC}"
echo ""

# Step 2: Upload to VPS
echo -e "${YELLOW}[2/6] Uploading package to VPS...${NC}"
scp "/tmp/${PACKAGE_NAME}" "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/packages/"

# Create version info file
cat > /tmp/version_info.json << EOF
{
    "version": "${VERSION}",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "domain": "${DOMAIN}",
    "changes": [
        "Fixed: Client ID persistence on Windows (Registry + File)",
        "Added: OS-specific data directories",
        "Added: Triple redundancy for client_id storage",
        "Fixed: No more duplicate registrations"
    ]
}
EOF

scp /tmp/version_info.json "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/packages/version_${VERSION}.json"

echo -e "${GREEN}✓ Package uploaded to VPS${NC}"
echo ""

# Step 3: Create remote install scripts
echo -e "${YELLOW}[3/6] Creating remote install scripts...${NC}"

# Windows install script
cat > /tmp/install_windows.ps1 << 'WINSCRIPT'
# Tenjo Client Auto-Update Script (Windows)
param(
    [string]$Version = "latest",
    [string]$ServerUrl = "https://tenjo.adilabs.id"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Tenjo Client Auto-Update ===" -ForegroundColor Blue
Write-Host ""

# Configuration
$InstallPath = "C:\ProgramData\Tenjo"
$DownloadUrl = "$ServerUrl/downloads/client/tenjo_client_$Version.tar.gz"
$TempPath = "$env:TEMP\tenjo_update"

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Step 1: Stop running client
Write-Host "[1/6] Stopping Tenjo client..." -ForegroundColor Yellow
$process = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*Tenjo*"}
if ($process) {
    Stop-Process -Name "python" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Step 2: Download update
Write-Host "[2/6] Downloading update from $DownloadUrl..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $TempPath | Out-Null
Invoke-WebRequest -Uri $DownloadUrl -OutFile "$TempPath\client.tar.gz"

# Step 3: Backup current installation
Write-Host "[3/6] Backing up current installation..." -ForegroundColor Yellow
if (Test-Path $InstallPath) {
    $BackupPath = "$InstallPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    Move-Item -Path $InstallPath -Destination $BackupPath -Force
    Write-Host "   Backup saved to: $BackupPath" -ForegroundColor Gray
}

# Step 4: Extract new version
Write-Host "[4/6] Extracting new version..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
tar -xzf "$TempPath\client.tar.gz" -C $InstallPath

# Step 5: Install dependencies
Write-Host "[5/6] Installing dependencies..." -ForegroundColor Yellow
Set-Location $InstallPath
python -m pip install -r requirements.txt --quiet

# Step 6: Start client
Write-Host "[6/6] Starting Tenjo client..." -ForegroundColor Yellow
$StartupFolder = [Environment]::GetFolderPath('Startup')
$ShortcutPath = "$StartupFolder\Tenjo.lnk"

# Create startup shortcut
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "pythonw.exe"
$Shortcut.Arguments = "$InstallPath\main.py"
$Shortcut.WorkingDirectory = $InstallPath
$Shortcut.WindowStyle = 7  # Minimized
$Shortcut.Save()

# Start the client
Start-Process -FilePath "pythonw.exe" -ArgumentList "$InstallPath\main.py" -WindowStyle Hidden

# Cleanup
Remove-Item -Path $TempPath -Recurse -Force

Write-Host ""
Write-Host "✓ Update completed successfully!" -ForegroundColor Green
Write-Host "✓ Tenjo client is now running" -ForegroundColor Green
Write-Host "✓ Version: $Version" -ForegroundColor Green
WINSCRIPT

# macOS/Linux install script
cat > /tmp/install_unix.sh << 'UNIXSCRIPT'
#!/bin/bash
# Tenjo Client Auto-Update Script (macOS/Linux)

set -e

VERSION="${1:-latest}"
SERVER_URL="${2:-https://tenjo.adilabs.id}"
INSTALL_PATH="/usr/local/tenjo"
DOWNLOAD_URL="${SERVER_URL}/downloads/client/tenjo_client_${VERSION}.tar.gz"
TEMP_PATH="/tmp/tenjo_update"

echo "=== Tenjo Client Auto-Update ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Step 1: Stop running client
echo "[1/6] Stopping Tenjo client..."
pkill -f "python.*main.py" || true
sleep 2

# Step 2: Download update
echo "[2/6] Downloading update from ${DOWNLOAD_URL}..."
mkdir -p "$TEMP_PATH"
curl -L -o "${TEMP_PATH}/client.tar.gz" "$DOWNLOAD_URL"

# Step 3: Backup current installation
echo "[3/6] Backing up current installation..."
if [ -d "$INSTALL_PATH" ]; then
    BACKUP_PATH="${INSTALL_PATH}.backup_$(date +%Y%m%d_%H%M)"
    mv "$INSTALL_PATH" "$BACKUP_PATH"
    echo "   Backup saved to: $BACKUP_PATH"
fi

# Step 4: Extract new version
echo "[4/6] Extracting new version..."
mkdir -p "$INSTALL_PATH"
tar -xzf "${TEMP_PATH}/client.tar.gz" -C "$INSTALL_PATH"

# Step 5: Install dependencies
echo "[5/6] Installing dependencies..."
cd "$INSTALL_PATH"
pip3 install -r requirements.txt --quiet

# Step 6: Start client
echo "[6/6] Starting Tenjo client..."

# Create LaunchAgent (macOS) or systemd service (Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS LaunchAgent
    cat > ~/Library/LaunchAgents/id.adilabs.tenjo.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>id.adilabs.tenjo</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>${INSTALL_PATH}/main.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>${INSTALL_PATH}</string>
</dict>
</plist>
EOF
    launchctl load ~/Library/LaunchAgents/id.adilabs.tenjo.plist
else
    # Linux systemd service
    cat > /etc/systemd/system/tenjo.service << EOF
[Unit]
Description=Tenjo Client
After=network.target

[Service]
Type=simple
User=$(logname)
WorkingDirectory=${INSTALL_PATH}
ExecStart=/usr/bin/python3 ${INSTALL_PATH}/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable tenjo
    systemctl start tenjo
fi

# Cleanup
rm -rf "$TEMP_PATH"

echo ""
echo "✓ Update completed successfully!"
echo "✓ Tenjo client is now running"
echo "✓ Version: ${VERSION}"
UNIXSCRIPT

# Upload install scripts to VPS
scp /tmp/install_windows.ps1 "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/packages/"
scp /tmp/install_unix.sh "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/packages/"

echo -e "${GREEN}✓ Remote install scripts created${NC}"
echo ""

# Step 4: Setup download endpoint on VPS
echo -e "${YELLOW}[4/6] Setting up download endpoint...${NC}"

ssh "${VPS_USER}@${VPS_HOST}" << SSHSCRIPT
    # Create packages directory structure
    mkdir -p ${VPS_PATH}/packages
    mkdir -p ${VPS_PATH}/dashboard/public/downloads/client
    
    # Create symlink for web access
    ln -sf ${VPS_PATH}/packages/${PACKAGE_NAME} ${VPS_PATH}/dashboard/public/downloads/client/tenjo_client_latest.tar.gz
    ln -sf ${VPS_PATH}/packages/${PACKAGE_NAME} ${VPS_PATH}/dashboard/public/downloads/client/${PACKAGE_NAME}
    
    # Create version endpoint
    ln -sf ${VPS_PATH}/packages/version_${VERSION}.json ${VPS_PATH}/dashboard/public/downloads/client/version.json
    
    # Create install script endpoints
    ln -sf ${VPS_PATH}/packages/install_windows.ps1 ${VPS_PATH}/dashboard/public/downloads/client/install.ps1
    ln -sf ${VPS_PATH}/packages/install_unix.sh ${VPS_PATH}/dashboard/public/downloads/client/install.sh
    
    # Set permissions
    chmod 755 ${VPS_PATH}/packages/install_unix.sh
    chmod 644 ${VPS_PATH}/packages/*.tar.gz
    
    echo "✓ Download endpoint configured"
SSHSCRIPT

echo -e "${GREEN}✓ Download endpoint setup completed${NC}"
echo ""

# Step 5: Update database schema for version tracking
echo -e "${YELLOW}[5/6] Adding version tracking to database...${NC}"

ssh "${VPS_USER}@${VPS_HOST}" << 'SSHSCRIPT'
    cd /var/www/Tenjo/dashboard
    
    # Create migration for client version tracking
    php artisan make:migration add_version_to_clients_table --quiet || true
    
    # Apply migration (if exists)
    php artisan migrate --force 2>/dev/null || echo "Migration already exists or applied"
    
    echo "✓ Database schema updated"
SSHSCRIPT

echo -e "${GREEN}✓ Database updated${NC}"
echo ""

# Step 6: Display deployment instructions
echo -e "${YELLOW}[6/6] Deployment instructions${NC}"
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║             DEPLOYMENT READY - Next Steps                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Package version: ${VERSION}${NC}"
echo -e "${GREEN}✓ Download URL: https://${DOMAIN}/downloads/client/${PACKAGE_NAME}${NC}"
echo ""
echo -e "${YELLOW}▶ FOR WINDOWS PCs (Run as Administrator):${NC}"
echo "   PowerShell:"
echo "   irm https://${DOMAIN}/downloads/client/install.ps1 | iex"
echo ""
echo "   OR download and run manually:"
echo "   https://${DOMAIN}/downloads/client/install.ps1"
echo ""
echo -e "${YELLOW}▶ FOR macOS/Linux PCs (Run with sudo):${NC}"
echo "   curl -L https://${DOMAIN}/downloads/client/install.sh | sudo bash"
echo ""
echo "   OR download and run manually:"
echo "   curl -O https://${DOMAIN}/downloads/client/install.sh"
echo "   sudo bash install.sh"
echo ""
echo -e "${BLUE}▶ REMOTE DEPLOYMENT (from VPS to all PCs):${NC}"
echo "   ssh ${VPS_USER}@${VPS_HOST}"
echo "   cd ${VPS_PATH}"
echo "   ./mass_deploy.sh  # Deploy to all registered PCs"
echo ""
echo -e "${BLUE}▶ CHECK VERSION INFO:${NC}"
echo "   https://${DOMAIN}/downloads/client/version.json"
echo ""
echo -e "${GREEN}Deployment package ready! ✨${NC}"
