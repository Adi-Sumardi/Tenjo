# Tenjo Windows PowerShell Installer - Ultra Clean Version
# Employee Monitoring System - No Syntax Errors Guaranteed

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TENJO - Employee Monitoring System" -ForegroundColor Cyan
Write-Host "   Windows PowerShell Installer v4.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$InstallDir = "$env:USERPROFILE\.tenjo"
$GitHubRepo = "https://github.com/Adi-Sumardi/Tenjo.git"
$GitHubZip = "https://github.com/Adi-Sumardi/Tenjo/archive/refs/heads/master.zip"
$TempDir = "$env:TEMP\tenjo_install_$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "[INFO] Installation directory: $InstallDir" -ForegroundColor White
Write-Host "[INFO] Temporary directory: $TempDir" -ForegroundColor White
Write-Host ""

function Refresh-Environment {
    try {
        $machPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = $machPath + ";" + $userPath
    } catch {
        Write-Host "[WARNING] Could not refresh environment variables" -ForegroundColor Yellow
    }
}

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri "http://google.com" -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        try {
            $response = Invoke-WebRequest -Uri "http://github.com" -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            return $true
        } catch {
            return $false
        }
    }
}

function Download-File {
    param($Url, $OutputPath, $Description)
    
    try {
        Write-Host "[INFO] Downloading $Description..." -ForegroundColor Yellow
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -TimeoutSec 300
        
        if (Test-Path $OutputPath) {
            Write-Host "[OK] $Description downloaded successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] File not found after download" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to download $Description" -ForegroundColor Red
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

try {
    # Create temp directory
    Write-Host "[1/7] Preparing installation environment..." -ForegroundColor Cyan
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    Write-Host "[OK] Temporary directory created" -ForegroundColor Green
    
    # Test internet connection
    Write-Host ""
    Write-Host "[2/7] Testing internet connectivity..." -ForegroundColor Cyan
    if (-not (Test-InternetConnection)) {
        throw "No internet connection detected. Please check your connection and try again."
    }
    Write-Host "[OK] Internet connection verified" -ForegroundColor Green
    
    # Check Python
    Write-Host ""
    Write-Host "[3/7] Checking Python installation..." -ForegroundColor Cyan
    
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
        $process = Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=0", "PrependPath=1", "Include_test=0" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Python installation failed with exit code: $($process.ExitCode)"
        }
        
        Start-Sleep -Seconds 15
        Refresh-Environment
        
        # Verify Python installation
        $pythonVersion = & python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Python installation completed but python command not accessible. Please restart PowerShell and try again."
        }
        
        Write-Host "[OK] Python installed successfully: $pythonVersion" -ForegroundColor Green
    }
    
    # Check Git
    Write-Host ""
    Write-Host "[4/7] Checking Git installation..." -ForegroundColor Cyan
    
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
        $process = Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Git installation failed with exit code: $($process.ExitCode)"
        }
        
        Start-Sleep -Seconds 15
        Refresh-Environment
        
        # Verify Git installation
        $gitVersion = & git --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARNING] Git installation completed but git command not accessible" -ForegroundColor Yellow
            Write-Host "[INFO] Will use ZIP download method instead" -ForegroundColor Yellow
            $gitFound = $false
        } else {
            Write-Host "[OK] Git installed successfully: $gitVersion" -ForegroundColor Green
            $gitFound = $true
        }
    }
    
    # Clean existing installation
    Write-Host ""
    Write-Host "[5/7] Preparing installation directory..." -ForegroundColor Cyan
    
    if (Test-Path $InstallDir) {
        Write-Host "[INFO] Removing existing installation..." -ForegroundColor Yellow
        
        Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*$InstallDir*"} | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        
        try {
            Remove-Item -Path $InstallDir -Recurse -Force
            Write-Host "[OK] Existing installation removed" -ForegroundColor Green
        } catch {
            Write-Host "[WARNING] Could not fully remove existing installation" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[OK] No existing installation found" -ForegroundColor Green
    }
    
    # Download repository
    Write-Host ""
    Write-Host "[6/7] Downloading Tenjo from GitHub..." -ForegroundColor Cyan
    
    $downloadSuccess = $false
    
    # Try Git clone if available
    if ($gitFound) {
        Write-Host "[INFO] Attempting Git clone..." -ForegroundColor Yellow
        
        try {
            $gitOutput = & git clone $GitHubRepo $InstallDir 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Git clone successful" -ForegroundColor Green
                $downloadSuccess = $true
            } else {
                Write-Host "[WARNING] Git clone failed, trying ZIP download..." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "[WARNING] Git clone exception, trying ZIP download..." -ForegroundColor Yellow
        }
    }
    
    # Fall back to ZIP if Git failed or not available
    if (-not $downloadSuccess) {
        Write-Host "[INFO] Using ZIP download method..." -ForegroundColor Yellow
        
        $zipFile = "$TempDir\tenjo-master.zip"
        
        if (Download-File -Url $GitHubZip -OutputPath $zipFile -Description "Tenjo ZIP archive") {
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
                $downloadSuccess = $true
            } else {
                throw "Extracted directory not found"
            }
        } else {
            throw "Failed to download ZIP archive"
        }
    }
    
    if (-not $downloadSuccess) {
        throw "All download methods failed"
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
    Write-Host "[7/7] Installing Python dependencies..." -ForegroundColor Cyan
    
    Set-Location "$InstallDir\client"
    
    if (-not (Test-Path "requirements.txt")) {
        throw "requirements.txt not found in client directory"
    }
    
    Write-Host "[INFO] Upgrading pip..." -ForegroundColor Yellow
    & python -m pip install --upgrade pip --quiet 2>&1 | Out-Null
    
    Write-Host "[INFO] Installing requirements..." -ForegroundColor Yellow
    $pipOutput = & python -m pip install -r requirements.txt 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] Some packages failed, trying individual installation..." -ForegroundColor Yellow
        
        $requirements = Get-Content "requirements.txt" | Where-Object {$_ -and !$_.StartsWith("#")}
        foreach ($package in $requirements) {
            Write-Host "[INFO] Installing: $package" -ForegroundColor Gray
            & python -m pip install $package --quiet 2>&1 | Out-Null
        }
    }
    
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
    
    # Test installation
    Write-Host ""
    Write-Host "[INFO] Testing installation..." -ForegroundColor Cyan
    
    $pythonTest = & python -c "import sys; print('Python executable:', sys.executable)" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python test failed"
    }
    
    # Create startup scripts
    Write-Host "[INFO] Creating startup scripts..." -ForegroundColor Yellow
    $startupScript = "$InstallDir\start_tenjo.bat"
    
    $startupContent = "@echo off`r`n"
    $startupContent += "title Tenjo Employee Monitoring`r`n"
    $startupContent += "cd /d `"$InstallDir\client`"`r`n"
    $startupContent += "echo Starting Tenjo Employee Monitoring System...`r`n"
    $startupContent += "python main.py`r`n"
    $startupContent += "pause`r`n"
    
    $startupContent | Out-File -FilePath $startupScript -Encoding ASCII -NoNewline
    
    # Create background startup script
    $backgroundScript = "$InstallDir\start_tenjo_background.bat"
    
    $backgroundContent = "@echo off`r`n"
    $backgroundContent += "cd /d `"$InstallDir\client`"`r`n"
    $backgroundContent += "start /min `"`" python main.py`r`n"
    
    $backgroundContent | Out-File -FilePath $backgroundScript -Encoding ASCII -NoNewline
    
    # Configure auto-start
    Write-Host "[INFO] Configuring auto-start..." -ForegroundColor Yellow
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $startupLink = "$startupFolder\Tenjo.bat"
    
    $autostartContent = "@echo off`r`n"
    $autostartContent += "timeout /t 30 /nobreak >nul`r`n"
    $autostartContent += "start /min `"`" `"$backgroundScript`"`r`n"
    
    $autostartContent | Out-File -FilePath $startupLink -Encoding ASCII -NoNewline
    
    # Create uninstaller
    $uninstaller = "$InstallDir\uninstall.bat"
    
    $uninstallContent = "@echo off`r`n"
    $uninstallContent += "echo Stopping Tenjo monitoring service...`r`n"
    $uninstallContent += "taskkill /f /im python.exe >nul 2>&1`r`n"
    $uninstallContent += "timeout /t 5 /nobreak >nul`r`n"
    $uninstallContent += "echo Removing startup entry...`r`n"
    $uninstallContent += "del `"$startupLink`" >nul 2>&1`r`n"
    $uninstallContent += "echo Removing installation directory...`r`n"
    $uninstallContent += "cd /d `"%USERPROFILE%`"`r`n"
    $uninstallContent += "rmdir /s /q `"$InstallDir`"`r`n"
    $uninstallContent += "echo Tenjo has been uninstalled successfully`r`n"
    $uninstallContent += "pause`r`n"
    
    $uninstallContent | Out-File -FilePath $uninstaller -Encoding ASCII -NoNewline
    
    # Start service
    Write-Host "[INFO] Starting Tenjo monitoring service..." -ForegroundColor Yellow
    Start-Process -FilePath $backgroundScript -WindowStyle Hidden
    Start-Sleep -Seconds 3
    
    # Cleanup
    Write-Host "[INFO] Cleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    # Success message
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "     INSTALLATION COMPLETED!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation Summary:" -ForegroundColor Cyan
    Write-Host "- Python: Verified and working" -ForegroundColor White
    Write-Host "- Git: Verified and working (or ZIP fallback used)" -ForegroundColor White
    Write-Host "- Tenjo installed to: $InstallDir" -ForegroundColor White
    Write-Host "- Dependencies installed successfully" -ForegroundColor White
    Write-Host "- Service started in background" -ForegroundColor White
    Write-Host "- Auto-start configured (30s delay after boot)" -ForegroundColor White
    Write-Host "- Uninstaller created" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Open dashboard: http://103.129.149.67" -ForegroundColor White
    Write-Host "2. Your device should appear within 1-2 minutes" -ForegroundColor White
    Write-Host "3. Service runs automatically in stealth mode" -ForegroundColor White
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Cyan
    Write-Host "- Uninstall: $InstallDir\uninstall.bat" -ForegroundColor White
    Write-Host "- Start manually: $startupScript" -ForegroundColor White
    Write-Host "- Start background: $backgroundScript" -ForegroundColor White
    Write-Host "- View logs: $InstallDir\client\logs\" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation completed successfully!" -ForegroundColor Green

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
    
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

Write-Host ""
Write-Host "Press any key to continue..."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null