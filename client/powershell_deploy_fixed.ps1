# Tenjo Client - Emergency Fixed Deployment Script
# This script deploys the FIXED version that resolves dashboard visibility issues

# Enhanced error handling
$ErrorActionPreference = 'Continue'

Write-Host "=== TENJO CLIENT - FIXED DEPLOYMENT ===" -ForegroundColor Green
Write-Host "This version fixes Windows PC registration issues!" -ForegroundColor Yellow

# Step 1: Install Python 3.10 if needed
Write-Host "Step 1: Checking Python installation..." -ForegroundColor Cyan

$pythonPath = $null
$pythonPaths = @(
    "C:\Python310\python.exe",
    "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python310\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
    "$env:APPDATA\..\Local\Programs\Python\Python310\python.exe"
)

foreach ($path in $pythonPaths) {
    if (Test-Path $path) {
        $pythonPath = $path
        Write-Host "Found Python at: $pythonPath" -ForegroundColor Green
        break
    }
}

if (-not $pythonPath) {
    Write-Host "Python not found. Installing Python 3.10..." -ForegroundColor Yellow
    
    try {
        $pythonUrl = "https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe"
        $pythonInstaller = "$env:TEMP\python-installer.exe"
        
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
        
        Write-Host "Installing Python silently..." -ForegroundColor Yellow
        Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=0", "PrependPath=1", "Include_test=0" -Wait
        
        Remove-Item $pythonInstaller -Force
        
        # Re-check for Python
        foreach ($path in $pythonPaths) {
            if (Test-Path $path) {
                $pythonPath = $path
                Write-Host "Python installed successfully at: $pythonPath" -ForegroundColor Green
                break
            }
        }
        
        if (-not $pythonPath) {
            Write-Host "Python installation verification failed. Trying system path..." -ForegroundColor Yellow
            $pythonPath = "python"
        }
        
    } catch {
        Write-Host "Python installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Trying to use system python..." -ForegroundColor Yellow
        $pythonPath = "python"
    }
}

# Step 2: Download and extract the FIXED installer package
Write-Host "Step 2: Downloading FIXED Tenjo client package..." -ForegroundColor Cyan

$tempDir = "$env:TEMP\tenjo_deploy_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $packageUrl = "https://raw.github.com/Adi-Sumardi/Tenjo/master/client/installer_package.tar.gz"
    $packageFile = "$tempDir\installer_package.tar.gz"
    
    Invoke-WebRequest -Uri $packageUrl -OutFile $packageFile -UseBasicParsing
    Write-Host "Package downloaded successfully!" -ForegroundColor Green
    
    # Extract using tar (available in Windows 10+)
    Write-Host "Extracting package..." -ForegroundColor Cyan
    Set-Location $tempDir
    tar -zxf "installer_package.tar.gz"
    
    if (Test-Path "$tempDir\installer_package") {
        Write-Host "Package extracted successfully!" -ForegroundColor Green
    } else {
        throw "Extraction failed - installer_package directory not found"
    }
    
} catch {
    Write-Host "Download/extraction error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check internet connection and try again." -ForegroundColor Yellow
    exit 1
}

# Step 3: Install to Tenjo directory
Write-Host "Step 3: Installing Tenjo client..." -ForegroundColor Cyan

$installDir = "C:\Tenjo"
try {
    if (Test-Path $installDir) {
        Write-Host "Stopping existing Tenjo service..." -ForegroundColor Yellow
        try { Stop-Process -Name "python" -Force -ErrorAction SilentlyContinue } catch {}
        Start-Sleep 2
        Remove-Item $installDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Copy-Item "$tempDir\installer_package\*" -Destination $installDir -Recurse -Force
    
    Write-Host "Files copied to $installDir" -ForegroundColor Green
    
} catch {
    Write-Host "Installation error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Install dependencies
Write-Host "Step 4: Installing Python dependencies..." -ForegroundColor Cyan

Set-Location $installDir
try {
    & $pythonPath -m pip install --upgrade pip --quiet
    & $pythonPath -m pip install -r requirements.txt --quiet
    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Dependency installation warning: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Continuing with installation..." -ForegroundColor Yellow
}

# Step 5: Create startup script
Write-Host "Step 5: Creating startup script..." -ForegroundColor Cyan

$startupScript = @"
@echo off
cd /d C:\Tenjo
$pythonPath main.py
"@

$startupScript | Out-File -FilePath "$installDir\start_tenjo.bat" -Encoding ASCII

# Step 6: Start the service
Write-Host "Step 6: Starting Tenjo client service..." -ForegroundColor Cyan

try {
    Start-Process -FilePath "$installDir\start_tenjo.bat" -WindowStyle Hidden
    Write-Host "Tenjo client started successfully!" -ForegroundColor Green
    
    Start-Sleep 3
    Write-Host "Verifying service..." -ForegroundColor Cyan
    
    $tenjoProcess = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*Tenjo*" -or $_.CommandLine -like "*main.py*" }
    if ($tenjoProcess) {
        Write-Host "✓ Tenjo client is running (PID: $($tenjoProcess.Id))" -ForegroundColor Green
    } else {
        Write-Host "⚠ Service verification incomplete - check manually" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Service start error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try running manually: $installDir\start_tenjo.bat" -ForegroundColor Yellow
}

# Cleanup
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== DEPLOYMENT COMPLETED ===" -ForegroundColor Green
Write-Host "✓ FIXED Tenjo client installed to: $installDir" -ForegroundColor Green
Write-Host "✓ Service should now register properly in dashboard" -ForegroundColor Green
Write-Host "✓ Check dashboard in 1-2 minutes for this PC" -ForegroundColor Green
Write-Host "`nIf issues persist, check logs at: $installDir\logs\" -ForegroundColor Yellow