# Mass Remote Update Script for 19 Tenjo Clients (PowerShell)
# Run this from your admin Windows computer to update all clients

# List of client IPs
$clientIPs = @(
    "192.168.1.26",
    "192.168.1.21",
    "192.168.1.25",
    "192.168.1.2",
    "192.168.100.165",
    "192.168.100.216",
    "192.168.100.178",
    "192.168.1.29",
    "192.168.1.8",
    "192.168.1.27",
    "192.168.1.22",
    "192.168.100.158",
    "192.168.100.159",
    "192.168.1.38",
    "192.168.1.30",
    "192.168.1.32",
    "192.168.1.18"
)

# Configuration
$productionServer = "https://tenjo.adilabs.id"
$username = "Administrator"  # Change to your admin username
$tenjoPath = "C:\ProgramData\Tenjo"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🔧 MASS TENJO CLIENT UPDATE" -ForegroundColor Yellow
Write-Host "   Updating clients to production server" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Download update script
$updateScriptUrl = "$productionServer/downloads/client/update_server_config.py"
$localUpdateScript = ".\update_server_config.py"

Write-Host "📥 Downloading update script..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $updateScriptUrl -OutFile $localUpdateScript -ErrorAction Stop
    Write-Host "✅ Update script downloaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔄 Starting mass update for $($clientIPs.Count) clients..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failCount = 0
$results = @()

foreach ($ip in $clientIPs) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "📍 Processing: $ip" -ForegroundColor White
    
    try {
        # Test connection
        if (-not (Test-Connection -ComputerName $ip -Count 1 -Quiet)) {
            Write-Host "   ⚠️  Offline or unreachable" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                IP = $ip
                Status = "Offline"
                Message = "Could not connect"
            }
            $failCount++
            continue
        }
        
        # Copy update script
        Write-Host "   📤 Copying update script..." -ForegroundColor Cyan
        $remotePath = "\\$ip\C$\ProgramData\Tenjo"
        
        if (Test-Path $remotePath) {
            Copy-Item -Path $localUpdateScript -Destination "$remotePath\update_server_config.py" -Force
            
            # Execute update remotely
            Write-Host "   🔧 Running update..." -ForegroundColor Cyan
            $scriptBlock = {
                param($path)
                Set-Location $path
                python update_server_config.py
            }
            
            Invoke-Command -ComputerName $ip -ScriptBlock $scriptBlock -ArgumentList $tenjoPath
            
            Write-Host "   ✅ Updated successfully" -ForegroundColor Green
            Write-Host "   🔄 Scheduling restart..." -ForegroundColor Cyan
            
            # Restart in 5 minutes
            Invoke-Command -ComputerName $ip -ScriptBlock { 
                shutdown /r /t 300 /c "Tenjo update - restarting in 5 min"
            }
            
            $results += [PSCustomObject]@{
                IP = $ip
                Status = "Success"
                Message = "Updated, restart in 5 min"
            }
            $successCount++
            
        } else {
            Write-Host "   ⚠️  Tenjo not installed" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                IP = $ip
                Status = "Not Installed"
                Message = "Path not found"
            }
            $failCount++
        }
        
    } catch {
        Write-Host "   ❌ Failed: $_" -ForegroundColor Red
        $results += [PSCustomObject]@{
            IP = $ip
            Status = "Failed"
            Message = $_.Exception.Message
        }
        $failCount++
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 SUMMARY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total:      $($clientIPs.Count)" -ForegroundColor White
Write-Host "✅ Success: $successCount" -ForegroundColor Green
Write-Host "❌ Failed:  $failCount" -ForegroundColor Red
Write-Host ""

$results | Format-Table -AutoSize

Write-Host ""
Write-Host "⏰ Clients will restart in 5 minutes" -ForegroundColor Yellow
Write-Host "📊 Check dashboard after 15 minutes:" -ForegroundColor Yellow
Write-Host "   $productionServer/" -ForegroundColor Cyan
Write-Host ""

Remove-Item -Path $localUpdateScript -Force -ErrorAction SilentlyContinue
