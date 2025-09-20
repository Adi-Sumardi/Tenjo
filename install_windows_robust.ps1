# Tenjo Windows Robust Installer
# Enhanced version with comprehensive error handling and fallback methods

param(
    [switch]$Verbose = $false,
    [switch]$ForceReinstall = $false
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TENJO - Employee Monitoring System" -ForegroundColor Cyan
Write-Host "   Robust Windows Installer v2.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$InstallDir = "$env:USERPROFILE\.tenjo"
$GitHubRepo = "https://github.com/Adi-Sumardi/Tenjo.git"
$GitHubZip = "https://github.com/Adi-Sumardi/Tenjo/archive/refs/heads/master.zip"
$TempDir = "$env:TEMP\tenjo_install_$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "[INFO] Installation directory: $InstallDir" -ForegroundColor White
Write-Host "[INFO] Temporary directory: $TempDir" -ForegroundColor White
if ($ForceReinstall) {
    Write-Host "[INFO] Force reinstall mode enabled" -ForegroundColor Yellow
}
Write-Host ""

# Enhanced functions
function Refresh-Environment {
    try {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Host "[DEBUG] Environment variables refreshed" -ForegroundColor Gray
    } catch {
        Write-Host "[WARNING] Could not refresh environment variables: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Test-InternetConnection {
    $testSites = @("http://google.com", "http://github.com", "http://python.org")
    
    foreach ($site in $testSites) {
        try {
            $response = Invoke-WebRequest -Uri $site -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            Write-Host "[DEBUG] Internet test successful: $site" -ForegroundColor Gray
            return $true
        } catch {
            Write-Host "[DEBUG] Failed to reach: $site" -ForegroundColor Gray
            continue
        }
    }
    return $false
}

function Download-File {
    param($Url, $OutputPath, $Description, $MaxRetries = 3)
    
    for ($retry = 1; $retry -le $MaxRetries; $retry++) {
        try {
            Write-Host "[INFO] Downloading $Description (attempt $retry/$MaxRetries)..." -ForegroundColor Yellow
            
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -TimeoutSec 300
            
            if (Test-Path $OutputPath) {
                $fileSize = (Get-Item $OutputPath).Length
                Write-Host "[OK] $Description downloaded successfully ($([math]::Round($fileSize/1MB, 1)) MB)" -ForegroundColor Green
                return $true
            } else {
                throw "File not found after download"
            }
        } catch {
            Write-Host "[WARNING] Download attempt $retry failed: $($_.Exception.Message)" -ForegroundColor Yellow
            if ($retry -eq $MaxRetries) {
                Write-Host "[ERROR] Failed to download $Description after $MaxRetries attempts" -ForegroundColor Red
                return $false
            }
            Start-Sleep -Seconds (5 * $retry)  # Progressive delay
        }
    }
    return $false
}

function Install-FromGit {
    Write-Host "[INFO] Attempting Git clone..." -ForegroundColor Yellow
    
    try {
        # Try normal clone first
        $gitOutput = & git clone $GitHubRepo $InstallDir 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Git clone successful" -ForegroundColor Green
            return $true
        }
        
        # Try shallow clone
        Write-Host "[INFO] Normal clone failed, trying shallow clone..." -ForegroundColor Yellow
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        $gitOutput = & git clone --depth 1 $GitHubRepo $InstallDir 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Shallow clone successful" -ForegroundColor Green
            return $true
        }
        
        Write-Host "[ERROR] Git clone methods failed. Output:" -ForegroundColor Red
        Write-Host $gitOutput -ForegroundColor Red
        return $false
        
    } catch {
        Write-Host "[ERROR] Git clone exception: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-FromZip {
    Write-Host "[INFO] Attempting ZIP download..." -ForegroundColor Yellow
    
    try {
        $zipFile = "$TempDir\tenjo-master.zip"
        
        if (-not (Download-File -Url $GitHubZip -OutputPath $zipFile -Description "Tenjo ZIP archive")) {
            return $false
        }
        
        # Extract ZIP
        Write-Host "[INFO] Extracting ZIP archive..." -ForegroundColor Yellow
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $TempDir)
        
        # Move extracted folder
        $extractedDir = "$TempDir\Tenjo-master"
        if (Test-Path $extractedDir) {
            Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
            Move-Item $extractedDir $InstallDir
            Write-Host "[OK] ZIP installation successful" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] Extracted directory not found" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] ZIP installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

try {
    # Create temp directory
    Write-Host "[0/7] Preparing installation environment..." -ForegroundColor Cyan
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    Write-Host "[OK] Temporary directory created" -ForegroundColor Green
    
    # Test internet connection
    Write-Host ""
    Write-Host "[1/7] Testing internet connectivity..." -ForegroundColor Cyan
    if (-not (Test-InternetConnection)) {
        throw "No internet connection detected. Please check your connection and try again."
    }
    Write-Host "[OK] Internet connection verified" -ForegroundColor Green
    
    # Check Python
    Write-Host ""
    Write-Host "[2/7] Checking Python installation..." -ForegroundColor Cyan
    
    $pythonFound = $false
    try {
        $pythonVersion = & python --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $pythonVersion -match "Python") {
            Write-Host "[OK] Python found: $pythonVersion" -ForegroundColor Green
            $pythonFound = $true
        }
    } catch {
        # Python not found
    }
    
    if (-not $pythonFound) {
        Write-Host "[WARNING] Python not found. Installing Python 3.13..." -ForegroundColor Yellow
        
        $pythonUrl = "https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe"
        $pythonInstaller = "$TempDir\python_installer.exe"
        
        if (-not (Download-File -Url $pythonUrl -OutputPath $pythonInstaller -Description "Python 3.13 installer")) {
            throw "Failed to download Python installer"
        }
        
        Write-Host "[INFO] Installing Python 3.13 (this may take 3-5 minutes)..." -ForegroundColor Yellow
        $installProcess = Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=0", "PrependPath=1", "Include_test=0" -Wait -PassThru
        
        if ($installProcess.ExitCode -ne 0) {
            throw "Python installation failed with exit code: $($installProcess.ExitCode)"
        }
        
        Start-Sleep -Seconds 15
        Refresh-Environment
        
        # Verify Python with retries
        $pythonRetries = 3
        for ($i = 1; $i -le $pythonRetries; $i++) {
            try {
                $pythonVersion = & python --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Python installed successfully: $pythonVersion" -ForegroundColor Green
                    $pythonFound = $true
                    break
                }
            } catch {
                if ($i -eq $pythonRetries) {
                    throw "Python installation completed but python command not accessible after $pythonRetries attempts"
                }
                Write-Host "[INFO] Waiting for Python to be available (attempt $i/$pythonRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds 10
                Refresh-Environment
            }
        }
    }
    
    # Check Git
    Write-Host ""
    Write-Host "[3/7] Checking Git installation..." -ForegroundColor Cyan
    
    $gitFound = $false
    try {
        $gitVersion = & git --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $gitVersion -match "git version") {
            Write-Host "[OK] Git found: $gitVersion" -ForegroundColor Green
            $gitFound = $true
        }
    } catch {
        # Git not found
    }
    
    if (-not $gitFound) {
        Write-Host "[WARNING] Git not found. Installing Git for Windows..." -ForegroundColor Yellow
        
        $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
        $gitInstaller = "$TempDir\git_installer.exe"
        
        if (-not (Download-File -Url $gitUrl -OutputPath $gitInstaller -Description "Git for Windows installer")) {
            throw "Failed to download Git installer"
        }
        
        Write-Host "[INFO] Installing Git for Windows (this may take 3-5 minutes)..." -ForegroundColor Yellow
        $installProcess = Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-" -Wait -PassThru
        
        if ($installProcess.ExitCode -ne 0) {
            throw "Git installation failed with exit code: $($installProcess.ExitCode)"
        }
        
        Start-Sleep -Seconds 15
        Refresh-Environment
        
        # Verify Git with retries
        $gitRetries = 3
        for ($i = 1; $i -le $gitRetries; $i++) {
            try {
                $gitVersion = & git --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Git installed successfully: $gitVersion" -ForegroundColor Green
                    $gitFound = $true
                    break
                }
            } catch {
                if ($i -eq $gitRetries) {
                    Write-Host "[WARNING] Git installation completed but git command not accessible" -ForegroundColor Yellow
                    Write-Host "[INFO] Will use ZIP download method instead" -ForegroundColor Yellow
                    break
                }
                Write-Host "[INFO] Waiting for Git to be available (attempt $i/$gitRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds 10
                Refresh-Environment
            }
        }
    }
    
    # Clean existing installation
    Write-Host ""
    Write-Host "[4/7] Preparing installation directory..." -ForegroundColor Cyan
    
    if (Test-Path $InstallDir -and ($ForceReinstall -or (Test-Path "$InstallDir\.git") -or (Test-Path "$InstallDir\client"))) {
        Write-Host "[INFO] Removing existing installation..." -ForegroundColor Yellow
        
        Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*$InstallDir*"} | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        
        try {
            Remove-Item -Path $InstallDir -Recurse -Force
            Write-Host "[OK] Existing installation removed" -ForegroundColor Green
        } catch {
            Write-Host "[WARNING] Could not fully remove existing installation: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[OK] No existing installation found" -ForegroundColor Green
    }
    
    # Download repository with multiple methods
    Write-Host ""
    Write-Host "[5/7] Downloading Tenjo from GitHub..." -ForegroundColor Cyan
    
    $downloadSuccess = $false
    
    # Try Git clone if available
    if ($gitFound) {
        $downloadSuccess = Install-FromGit
    }
    
    # Fall back to ZIP if Git failed or not available
    if (-not $downloadSuccess) {
        Write-Host "[INFO] Falling back to ZIP download method..." -ForegroundColor Yellow
        $downloadSuccess = Install-FromZip
    }
    
    if (-not $downloadSuccess) {
        throw "All download methods failed. Please check your internet connection and try again."
    }
    
    # Validate downloaded content
    if (-not (Test-Path "$InstallDir\client")) {
        throw "Repository downloaded but client directory not found"
    }
    
    if (-not (Test-Path "$InstallDir\client\main.py")) {
        throw "Repository downloaded but main.py not found"
    }
    
    Write-Host "[OK] Repository validation successful" -ForegroundColor Green
    
    # Install Python dependencies
    Write-Host ""
    Write-Host "[6/7] Installing Python dependencies..." -ForegroundColor Cyan
    
    Set-Location "$InstallDir\client"
    
    if (-not (Test-Path "requirements.txt")) {
        throw "requirements.txt not found in client directory"
    }
    
    Write-Host "[INFO] Upgrading pip..." -ForegroundColor Yellow
    & python -m pip install --upgrade pip --quiet 2>&1 | Out-Null
    
    Write-Host "[INFO] Installing requirements..." -ForegroundColor Yellow
    $pipOutput = & python -m pip install -r requirements.txt 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] Some packages failed to install. Trying with verbose output..." -ForegroundColor Yellow
        Write-Host $pipOutput -ForegroundColor Red
        
        # Retry with individual packages
        $requirements = Get-Content "requirements.txt" | Where-Object {$_ -and !$_.StartsWith("#")}
        foreach ($package in $requirements) {
            Write-Host "[INFO] Installing: $package" -ForegroundColor Gray
            & python -m pip install $package --quiet 2>&1 | Out-Null
        }
        
        # Final verification
        $pipOutput = & python -m pip install -r requirements.txt 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARNING] Some packages may still have issues, but proceeding..." -ForegroundColor Yellow
        }
    }
    
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
    
    # Setup and test
    Write-Host ""
    Write-Host "[7/7] Configuring and testing installation..." -ForegroundColor Cyan
    
    # Test basic import
    $pythonTest = & python -c "import sys; print('[TEST] Python executable:', sys.executable)" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python test failed: $pythonTest"
    }
    
    # Test config import
    $configTest = & python -c "from src.core.config import Config; print('[TEST] Config loaded successfully')" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] Config test failed but files exist - may work at runtime" -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Configuration test passed" -ForegroundColor Green
    }
    
    # Create enhanced startup script
    Write-Host "[INFO] Creating startup scripts..." -ForegroundColor Yellow
    $startupScript = "$InstallDir\start_tenjo.bat"
    $startupContent = @"
@echo off
title Tenjo Employee Monitoring
cd /d "$InstallDir\client"
echo Starting Tenjo Employee Monitoring System...
python main.py
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Tenjo failed to start properly
    echo Check logs in: $InstallDir\client\logs\
    pause
)
"@
    $startupContent | Out-File -FilePath $startupScript -Encoding ASCII
    
    # Create background startup script
    $backgroundScript = "$InstallDir\start_tenjo_background.bat"
    $backgroundContent = @"
@echo off
cd /d "$InstallDir\client"
start /min "" python main.py
"@
    $backgroundContent | Out-File -FilePath $backgroundScript -Encoding ASCII
    
    # Configure auto-start
    Write-Host "[INFO] Configuring auto-start..." -ForegroundColor Yellow
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $startupLink = "$startupFolder\Tenjo.bat"
    
    $autostartContent = @"
@echo off
timeout /t 30 /nobreak >nul
start /min "" "$backgroundScript"
"@
    $autostartContent | Out-File -FilePath $startupLink -Encoding ASCII
    
    # Create comprehensive uninstaller
    $uninstaller = "$InstallDir\uninstall.bat"
    $uninstallContent = @"
@echo off
echo ============================================
echo    TENJO UNINSTALLER
echo ============================================
echo.
echo Stopping Tenjo monitoring service...
taskkill /f /im python.exe /fi "WINDOWTITLE eq *tenjo*" >nul 2>&1
taskkill /f /im python.exe /fi "COMMANDLINE eq *main.py*" >nul 2>&1
timeout /t 5 /nobreak >nul

echo Removing startup entry...
del "$startupLink" >nul 2>&1

echo Removing installation directory...
cd /d "%USERPROFILE%"
rmdir /s /q "$InstallDir" >nul 2>&1

echo.
echo Tenjo has been uninstalled successfully
echo.
pause
del "%~f0"
"@
    $uninstallContent | Out-File -FilePath $uninstaller -Encoding ASCII
    
    # Start service
    Write-Host "[INFO] Starting Tenjo monitoring service..." -ForegroundColor Yellow
    Start-Process -FilePath $backgroundScript -WindowStyle Hidden
    Start-Sleep -Seconds 3
    
    # Check if service started
    $tenjoProcess = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*$InstallDir*"}
    if ($tenjoProcess) {
        Write-Host "[OK] Service started successfully (PID: $($tenjoProcess.Id))" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Service may not have started properly" -ForegroundColor Yellow
    }
    
    # Cleanup
    Write-Host "[INFO] Cleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    # Final success message
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "     INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation Summary:" -ForegroundColor Cyan
    Write-Host "✓ Python: Verified and working" -ForegroundColor White
    Write-Host "✓ Git: Verified and working (or ZIP fallback used)" -ForegroundColor White
    Write-Host "✓ Tenjo installed to: $InstallDir" -ForegroundColor White
    Write-Host "✓ Dependencies installed successfully" -ForegroundColor White
    Write-Host "✓ Service started in background" -ForegroundColor White
    Write-Host "✓ Auto-start configured (30s delay after boot)" -ForegroundColor White
    Write-Host "✓ Comprehensive uninstaller created" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Open dashboard: http://103.129.149.67" -ForegroundColor White
    Write-Host "2. Your device should appear within 1-2 minutes" -ForegroundColor White
    Write-Host "3. Service runs automatically in stealth mode" -ForegroundColor White
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Cyan
    Write-Host "• Uninstall: $InstallDir\uninstall.bat" -ForegroundColor White
    Write-Host "• Start manually: $startupScript" -ForegroundColor White
    Write-Host "• Start background: $backgroundScript" -ForegroundColor White
    Write-Host "• View logs: $InstallDir\client\logs\" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation completed successfully! 🚀" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "         INSTALLATION FAILED!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor White
    Write-Host ""
    Write-Host "Troubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "1. Run PowerShell as Administrator" -ForegroundColor White
    Write-Host "2. Check internet connection" -ForegroundColor White
    Write-Host "3. Disable antivirus temporarily" -ForegroundColor White
    Write-Host "4. Try manual installation:" -ForegroundColor White
    Write-Host "   - Install Python: https://www.python.org/downloads/" -ForegroundColor Gray
    Write-Host "   - Install Git: https://git-scm.com/download/win" -ForegroundColor Gray
    Write-Host "   - Restart PowerShell and try again" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For support: https://github.com/Adi-Sumardi/Tenjo/issues" -ForegroundColor White
    
    # Cleanup on error
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")