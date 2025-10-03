#!/bin/bash
# Remote Silent Deploy using PsExec (no WinRM needed)
# Downloads PsExec and deploys to all clients

SERVER_URL="https://tenjo.adilabs.id"
DASHBOARD_PATH="/var/www/Tenjo/dashboard"
PACKAGE_URL="$SERVER_URL/downloads/installer_package.tar.gz"

# Windows admin credentials
WIN_USER="Administrator"
WIN_PASS="YourAdminPassword"

echo "=== Tenjo PsExec Remote Deployment ==="

# Download PsExec if not exists
if [ ! -f "/tmp/PsExec.exe" ]; then
    echo "Downloading PsExec..."
    wget -O /tmp/PsTools.zip https://download.sysinternals.com/files/PSTools.zip
    unzip -j /tmp/PsTools.zip PsExec.exe -d /tmp/
fi

# Get clients from database
CLIENTS=$(cd $DASHBOARD_PATH && php artisan tinker --execute="
echo json_encode(\App\Models\Client::where('os_info->platform', 'Windows')
    ->where('ip_address', '!=', '172.16.7.215')
    ->get(['client_id', 'hostname', 'ip_address'])->toArray());
")

echo "Found $(echo "$CLIENTS" | jq length) clients"
echo "$CLIENTS" | jq -r '.[] | "\(.hostname) - \(.ip_address)"'

# Create batch installer script
cat > /tmp/install_tenjo.bat << 'BATEOF'
@echo off
set PACKAGE_URL=%1
set INSTALL_DIR=%APPDATA%\Tenjo

echo Downloading Tenjo client...
powershell -Command "Invoke-WebRequest -Uri '%PACKAGE_URL%' -OutFile '%TEMP%\tenjo.tar.gz'"

echo Extracting package...
mkdir "%INSTALL_DIR%" 2>NUL
cd /d "%TEMP%"
tar -xzf tenjo.tar.gz -C "%INSTALL_DIR%"

echo Installing to startup...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v TenjoClient /t REG_SZ /d "\"%INSTALL_DIR%\pythonw.exe\" \"%INSTALL_DIR%\main.py\"" /f

echo Starting client...
start /B pythonw "%INSTALL_DIR%\main.py"

echo Installation completed!
del /Q "%TEMP%\tenjo.tar.gz"
BATEOF

# Deploy to each client
echo "$CLIENTS" | jq -c '.[]' | while read -r client; do
    IP=$(echo "$client" | jq -r '.ip_address')
    HOSTNAME=$(echo "$client" | jq -r '.hostname')
    
    echo ""
    echo "=== Deploying to $HOSTNAME ($IP) ==="
    
    # Copy installer script to remote PC
    smbclient //$IP/C$ -U "$WIN_USER%$WIN_PASS" -c "put /tmp/install_tenjo.bat Windows\Temp\install_tenjo.bat"
    
    # Execute remotely with PsExec
    wine /tmp/PsExec.exe \\\\$IP -u "$WIN_USER" -p "$WIN_PASS" -d -accepteula \
        cmd /c "C:\\Windows\\Temp\\install_tenjo.bat $PACKAGE_URL"
    
    if [ $? -eq 0 ]; then
        echo "✅ Deployment successful to $HOSTNAME"
        
        # Update database
        cd $DASHBOARD_PATH && php artisan tinker --execute="
        \$client = \App\Models\Client::where('ip_address', '$IP')->first();
        if (\$client) {
            \$client->update(['pending_update' => false, 'update_completed_at' => now()]);
            echo 'Database updated';
        }
        "
    else
        echo "❌ Failed to deploy to $HOSTNAME"
    fi
    
    sleep 2
done

echo ""
echo "=== Deployment Complete ==="
