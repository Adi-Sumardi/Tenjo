# Tenjo Client Update v1.0.2 - Production Server Configuration Fix

## Changes in v1.0.2
- **CRITICAL FIX**: Changed DEFAULT_SERVER_URL from localhost to https://tenjo.adilabs.id
- Clients will now connect to production server by default
- Added automatic server configuration update tool
- Fixed client connectivity issues

## Deployment via Termius

### Quick Deploy Script

Copy-paste this entire script in Termius:

```bash
#!/bin/bash
echo "========================================"
echo "🚀 TENJO UPDATE v1.0.2 DEPLOYMENT"
echo "   Production Server Configuration Fix"
echo "========================================"
echo ""

# Configuration
VERSION="1.0.2"
PACKAGE_NAME="tenjo_client_${VERSION}.tar.gz"

# Step 1: Pull latest code from GitHub
cd /var/www/Tenjo/client || exit 1
echo "📥 Pulling latest code from GitHub..."
git pull origin master
echo ""

# Step 2: Clean cache
echo "🧹 Cleaning Python cache..."
find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null
find . -name "*.pyc" -delete 2>/dev/null

# Step 3: Create version file
echo "${VERSION}" > .version

# Step 4: Create package
echo "📦 Creating package..."
PACKAGE_PATH="../dashboard/public/downloads/client/${PACKAGE_NAME}"
tar -czf "${PACKAGE_PATH}" \
    main.py \
    requirements.txt \
    src/ \
    install_autostart.sh \
    install_autostart.ps1 \
    uninstall_autostart.sh \
    uninstall_autostart.ps1 \
    check_client_config.py \
    update_server_config.py

if [ ! -f "${PACKAGE_PATH}" ]; then
    echo "❌ Failed to create package"
    exit 1
fi
echo "✅ Package created: ${PACKAGE_PATH}"
ls -lh "${PACKAGE_PATH}"
echo ""

# Step 5: Generate metadata
cd ../dashboard/public/downloads/client/ || exit 1
echo "📊 Generating metadata..."

CHECKSUM=$(sha256sum "${PACKAGE_NAME}" | awk '{print $1}')
PACKAGE_SIZE=$(stat -c%s "${PACKAGE_NAME}")
RELEASE_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "   Version: ${VERSION}"
echo "   Size: ${PACKAGE_SIZE} bytes ($(echo "scale=2; ${PACKAGE_SIZE}/1024/1024" | bc) MB)"
echo "   Checksum: ${CHECKSUM:0:16}..."
echo "   Release: ${RELEASE_DATE}"
echo ""

# Step 6: Create version.json
cat > version.json << EOF
{
    "version": "${VERSION}",
    "download_url": "https://tenjo.adilabs.id/downloads/client/${PACKAGE_NAME}",
    "server_url": "https://tenjo.adilabs.id",
    "changes": [
        "CRITICAL FIX: Changed default server to production (https://tenjo.adilabs.id)",
        "Fixed client connectivity - clients will now connect to production by default",
        "Added automatic server configuration update tool",
        "All clients should reinstall or run update_server_config.py"
    ],
    "checksum": "${CHECKSUM}",
    "package_size": ${PACKAGE_SIZE},
    "priority": "high",
    "release_date": "${RELEASE_DATE}"
}
EOF

# Step 7: Set permissions
chmod 644 "${PACKAGE_NAME}" version.json

# Step 8: Verify
echo "✅ version.json created:"
cat version.json | python3 -m json.tool
echo ""

echo "🔍 Testing download URL..."
HTTP_CODE=$(curl -I -s -o /dev/null -w "%{http_code}" "https://tenjo.adilabs.id/downloads/client/${PACKAGE_NAME}")
if [ "${HTTP_CODE}" = "200" ]; then
    echo "✅ Download URL accessible (HTTP ${HTTP_CODE})"
else
    echo "⚠️  HTTP ${HTTP_CODE} - Check nginx configuration"
fi
echo ""

echo "🧪 Testing API endpoint..."
curl -s "https://tenjo.adilabs.id/api/clients/test-client/check-update" | python3 -m json.tool
echo ""

echo "========================================"
echo "✅ DEPLOYMENT COMPLETE - v1.0.2"
echo "========================================"
echo ""
echo "📦 Package: ${PACKAGE_NAME}"
echo "🔗 Download: https://tenjo.adilabs.id/downloads/client/${PACKAGE_NAME}"
echo "⚡ Priority: HIGH (will check every 5 minutes)"
echo ""
echo "⚠️  IMPORTANT:"
echo "   Existing clients (19 PCs) need to either:"
echo "   1. Reinstall with new package, OR"
echo "   2. Run: python3 update_server_config.py"
echo ""
echo "========================================"
```

## For Existing 19 Clients

### Option 1: Reinstall (Recommended)
1. Uninstall old client on each PC
2. Install new v1.0.2 package
3. Client will automatically connect to production

### Option 2: Update Configuration (Faster)
On each client PC, run:

**Windows (as Administrator):**
```powershell
cd C:\ProgramData\Tenjo
python update_server_config.py
# Then restart computer
```

**macOS/Linux (as root):**
```bash
cd /usr/local/tenjo  # or /opt/tenjo on Linux
sudo python3 update_server_config.py
# Then restart computer
```

## Expected Result

After deployment + client update:
- ✅ All 19 clients will connect to https://tenjo.adilabs.id
- ✅ Dashboard will show clients ONLINE
- ✅ Clients will appear with their respective IPs:
  - 192.168.1.26, 192.168.1.21, 192.168.1.25, etc.

## Verification

Check dashboard after 5-10 minutes:
https://tenjo.adilabs.id/

Should see:
```
┌──────────────────────────────────────────────────────┐
│ CLIENT          │ IP ADDRESS      │ STATUS  │ VERSION│
├──────────────────────────────────────────────────────┤
│ Office-PC-001   │ 192.168.1.26    │ 🟢ONLINE│ 1.0.2  │
│ Office-PC-002   │ 192.168.1.21    │ 🟢ONLINE│ 1.0.2  │
│ Office-PC-003   │ 192.168.1.25    │ 🟢ONLINE│ 1.0.2  │
│ ...             │ ...             │ ...     │ ...    │
└──────────────────────────────────────────────────────┘
```
