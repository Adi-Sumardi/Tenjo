#!/bin/bash

# Tenjo Client - Installer Package Preparation Script
# Creates a ready-to-deploy installer package

set -e

echo "=== Tenjo Client Installer Package Preparation ==="
echo ""

# Clean old package
if [ -f "installer_package.tar.gz" ]; then
    echo "🗑️  Removing old package..."
    rm -f installer_package.tar.gz
fi

if [ -d "installer_package" ]; then
    rm -rf installer_package
fi

# Create package directory
echo "📦 Creating package structure..."
mkdir -p installer_package/src

# Copy main files
echo "📄 Copying main files..."
cp main.py installer_package/
cp requirements.txt installer_package/

# Copy source modules
echo "📁 Copying source modules..."
cp -r src/* installer_package/src/

# Create README
echo "📝 Creating installation instructions..."
cat > installer_package/README.md << 'EOF'
# Tenjo Client Installer

## Automatic Installation (Recommended)

### Windows:
```cmd
python main.py
```

### macOS/Linux:
```bash
sudo python3 main.py
```

## What it does:
1. ✅ Installs required dependencies
2. ✅ Configures auto-start (stealth mode)
3. ✅ Connects to dashboard server
4. ✅ Starts monitoring in background

## Requirements:
- Python 3.8+
- Internet connection
- Administrator/root privileges

## Configuration:
Server URL is auto-configured during installation.
Default: https://tenjo.adilabs.id

## Uninstall:
Run `python main.py --uninstall`

---
© 2025 Tenjo Monitoring System
EOF

# Create version file
echo "🏷️  Creating version file..."
echo "2025.10.03" > installer_package/VERSION

# Create archive
echo "📦 Creating tarball..."
tar -czf installer_package.tar.gz installer_package/

# Get size
SIZE=$(du -h installer_package.tar.gz | cut -f1)

echo ""
echo "✅ Package created successfully!"
echo "📦 File: installer_package.tar.gz"
echo "💾 Size: $SIZE"
echo ""
echo "Next steps:"
echo "1. Upload to server: scp installer_package.tar.gz tenjo-app@tenjo-app:/var/www/Tenjo/dashboard/public/downloads/"
echo "2. Trigger update from dashboard"
echo ""
