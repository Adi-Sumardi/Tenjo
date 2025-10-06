#!/bin/bash
###############################################################################
# Quick Deploy Script - Upload package ke VPS dan trigger update
# Usage: ./quick_deploy.sh [version]
###############################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration (edit sesuai VPS Anda)
VPS_HOST="${VPS_HOST:-tenjo.adilabs.id}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="/var/www/html/tenjo/public/downloads/client"
API_URL="https://${VPS_HOST}"

# Get version
VERSION=${1:-"1.0.1"}
PACKAGE_NAME="tenjo_client_${VERSION}.tar.gz"

echo -e "${GREEN}🚀 Tenjo Quick Deploy${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Step 1: Check if package exists
if [ ! -f "client/build/${PACKAGE_NAME}" ]; then
    echo -e "${RED}✗ Package not found: client/build/${PACKAGE_NAME}${NC}"
    echo -e "${YELLOW}Run full deploy script first: ./deploy_update.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Package found: ${PACKAGE_NAME}"

# Step 2: Upload to VPS
echo -e "\n${YELLOW}📤 Uploading to VPS...${NC}"
scp "client/build/${PACKAGE_NAME}" "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/" || {
    echo -e "${RED}✗ Upload failed${NC}"
    exit 1
}
echo -e "${GREEN}✓${NC} Package uploaded"

# Step 3: Upload version.json if exists
if [ -f "client/build/version.json" ]; then
    scp "client/build/version.json" "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/" || {
        echo -e "${RED}✗ version.json upload failed${NC}"
    }
    echo -e "${GREEN}✓${NC} version.json uploaded"
fi

# Step 4: Set permissions on VPS
echo -e "\n${YELLOW}🔐 Setting permissions...${NC}"
ssh "${VPS_USER}@${VPS_HOST}" "chmod 644 ${VPS_PATH}/${PACKAGE_NAME} ${VPS_PATH}/version.json 2>/dev/null"
echo -e "${GREEN}✓${NC} Permissions set"

# Step 5: Verify upload
echo -e "\n${YELLOW}✅ Verifying...${NC}"
ssh "${VPS_USER}@${VPS_HOST}" "ls -lh ${VPS_PATH}/${PACKAGE_NAME}"

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo -e "\n${YELLOW}Download URL:${NC} ${API_URL}/downloads/client/${PACKAGE_NAME}"
echo -e "${YELLOW}Trigger update from dashboard or API${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
