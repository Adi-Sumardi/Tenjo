#!/bin/bash
# Remote Silent Deploy to Windows PCs via PowerShell Remoting
# Menggunakan IP dan client_id dari database

SERVER_URL="https://tenjo.adilabs.id"
DASHBOARD_PATH="/var/www/Tenjo/dashboard"
PACKAGE_URL="$SERVER_URL/downloads/installer_package.tar.gz"

# Windows admin credentials (ganti dengan credentials yang benar)
WIN_USER="Administrator"
WIN_PASS="YourAdminPassword"

echo "=== Tenjo Remote Deployment Tool ==="
echo "Fetching client list from database..."

# Get all Windows clients from database
CLIENTS=$(cd $DASHBOARD_PATH && php artisan tinker --execute="
\$clients = \App\Models\Client::where('os_info->platform', 'Windows')
    ->where('ip_address', '!=', '172.16.7.215')
    ->get(['client_id', 'hostname', 'ip_address', 'username']);
    
echo json_encode(\$clients->map(function(\$c) {
    return [
        'client_id' => \$c->client_id,
        'hostname' => \$c->hostname,
        'ip' => \$c->ip_address,
        'username' => \$c->username
    ];
}));
")

echo "Clients to deploy:"
echo "$CLIENTS" | jq -r '.[] | "\(.hostname) - \(.ip)"'

echo ""
read -p "Continue with deployment? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Create PowerShell remote installation script
cat > /tmp/remote_install.ps1 << 'PSEOF'
param(
    [string]$PackageUrl,
    [string]$ClientId
)

# Download installer package
$TempDir = "$env:TEMP\tenjo_update"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
$PackageFile = "$TempDir\installer.tar.gz"

Write-Host "Downloading package from $PackageUrl..."
Invoke-WebRequest -Uri $PackageUrl -OutFile $PackageFile -UseBasicParsing

# Extract (requires tar on Windows 10+)
Write-Host "Extracting package..."
tar -xzf $PackageFile -C $TempDir

# Install silently
$InstallDir = "$env:APPDATA\Tenjo"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -Path "$TempDir\*" -Destination $InstallDir -Recurse -Force

# Create startup script
$StartupScript = "$InstallDir\start_tenjo.vbs"
@"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "$InstallDir\main.py" & chr(34), 0
Set WshShell = Nothing
"@ | Out-File -FilePath $StartupScript -Encoding ASCII

# Add to startup (Registry)
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $RegPath -Name "TenjoClient" -Value "wscript.exe `"$StartupScript`""

# Start the client
Start-Process pythonw -ArgumentList "$InstallDir\main.py" -WindowStyle Hidden

Write-Host "Installation completed successfully!"
Remove-Item -Path $TempDir -Recurse -Force
PSEOF

# Deploy to each client
echo "$CLIENTS" | jq -r '.[]' | while read -r client; do
    CLIENT_ID=$(echo "$client" | jq -r '.client_id')
    HOSTNAME=$(echo "$client" | jq -r '.hostname')
    IP=$(echo "$client" | jq -r '.ip')
    
    echo ""
    echo "=== Deploying to $HOSTNAME ($IP) ==="
    
    # Method 1: Try PowerShell Remoting (WinRM)
    if command -v pwsh &> /dev/null; then
        echo "Attempting PowerShell remoting..."
        pwsh -Command "
        \$SecPass = ConvertTo-SecureString '$WIN_PASS' -AsPlainText -Force
        \$Cred = New-Object System.Management.Automation.PSCredential('$WIN_USER', \$SecPass)
        
        try {
            Invoke-Command -ComputerName $IP -Credential \$Cred -FilePath /tmp/remote_install.ps1 -ArgumentList '$PACKAGE_URL','$CLIENT_ID'
            Write-Host '✅ Deployment successful to $HOSTNAME'
        } catch {
            Write-Host '❌ Failed: ' \$_.Exception.Message
        }
        "
    else
        echo "⚠️ PowerShell not available, skipping $HOSTNAME"
    fi
    
    sleep 2
done

echo ""
echo "=== Deployment Complete ==="
echo "Check dashboard to verify clients are online"
