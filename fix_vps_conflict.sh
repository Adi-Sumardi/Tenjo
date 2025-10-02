#!/bin/bash
# Quick fix for git pull conflict on VPS

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          Git Pull Conflict Fix - VPS                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

cd /var/www/Tenjo/dashboard

# Step 1: Backup conflicting files
echo "Step 1: Backing up conflicting files..."
if [ -f "../cleanup_duplicate_clients.php" ]; then
    cp ../cleanup_duplicate_clients.php ../cleanup_duplicate_clients.php.backup
    echo "✅ Backed up: cleanup_duplicate_clients.php → cleanup_duplicate_clients.php.backup"
fi

# Step 2: Remove conflicting files
echo ""
echo "Step 2: Removing conflicting files..."
if [ -f "../cleanup_duplicate_clients.php" ]; then
    rm ../cleanup_duplicate_clients.php
    echo "✅ Removed: cleanup_duplicate_clients.php"
fi

# Step 3: Pull latest code
echo ""
echo "Step 3: Pulling latest code from GitHub..."
git pull origin master

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Git pull successful!"
    
    # Step 4: Verify new files
    echo ""
    echo "Step 4: Verifying new files..."
    
    if [ -f "../cleanup_duplicate_clients.php" ]; then
        echo "✅ cleanup_duplicate_clients.php (from GitHub)"
    fi
    
    if [ -f "../vps_deploy_commands.sh" ]; then
        echo "✅ vps_deploy_commands.sh"
    fi
    
    if [ -f "../silent_push_deploy.sh" ]; then
        echo "✅ silent_push_deploy.sh"
    fi
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              ✅ CONFLICT RESOLVED!                       ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "You can now continue with deployment:"
    echo "  cd /var/www/Tenjo"
    echo "  chmod +x vps_deploy_commands.sh"
    echo "  ./vps_deploy_commands.sh"
    
else
    echo ""
    echo "❌ Git pull failed!"
    echo ""
    echo "If you still have conflicts, try:"
    echo "  git reset --hard origin/master"
    exit 1
fi
