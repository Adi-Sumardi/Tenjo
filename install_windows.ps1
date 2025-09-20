# Tenjo Windows PowerShell Installer
# Employee Monitoring System - Clean Installation Script

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TENJO - Employee Monitoring System" -ForegroundColor Cyan
Write-Host "   Windows PowerShell Installer v1.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$InstallDir = "$env:USERPROFILE\.tenjo"
$GitHubRepo = "https://github.com/Adi-Sumardi/Tenjo.git"
$TempDir = "$env:TEMP\tenjo_install_$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "[INFO] Installation directory: $InstallDir" -ForegroundColor White
Write-Host "[INFO] Temporary directory: $TempDir" -ForegroundColor White
Write-Host ""

# Function to refresh environment variables
function Refresh-Environment {
    try {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Host "[WARNING] Could not refresh environment variables" -ForegroundColor Yellow
    }
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri "http://google.com" -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Function to download file
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
            throw "File not found after download"
        }
    } catch {
        Write-Host "[ERROR] Failed to download $Description : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

try {
    # Create temp directory
    Write-Host "[0/6] Preparing installation environment..." -ForegroundColor Cyan
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    Write-Host "[OK] Temporary directory created" -ForegroundColor Green
    
    # Test internet connection
    Write-Host ""
    Write-Host "[1/6] Testing internet connectivity..." -ForegroundColor Cyan
    if (-not (Test-InternetConnection)) {
        throw "No internet connection detected. Please check your connection and try again."
    }
    Write-Host "[OK] Internet connection verified" -ForegroundColor Green
    
    # Check Python
    Write-Host ""
    Write-Host "[2/6] Checking Python installation..." -ForegroundColor Cyan
    
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
        
        Start-Sleep -Seconds 10
        Refresh-Environment
        
        try {
            $pythonVersion = & python --version 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Python installation completed but python command not found"
            }
            Write-Host "[OK] Python installed successfully: $pythonVersion" -ForegroundColor Green
        } catch {
            throw "Python installation completed but python command not accessible. Please restart PowerShell and try again."
        }
    }
    
    # Check Git
    Write-Host ""
    Write-Host "[3/6] Checking Git installation..." -ForegroundColor Cyan
    
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
        
        Start-Sleep -Seconds 10
        Refresh-Environment
        
        try {
            $gitVersion = & git --version 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Git installation completed but git command not found"
            }
            Write-Host "[OK] Git installed successfully: $gitVersion" -ForegroundColor Green
        } catch {
            throw "Git installation completed but git command not accessible. Please restart PowerShell and try again."
        }
    }
    
    # Clean existing installation
    Write-Host ""
    Write-Host "[4/6] Preparing installation directory..." -ForegroundColor Cyan
    
    if (Test-Path $InstallDir) {
        Write-Host "[INFO] Removing existing installation..." -ForegroundColor Yellow
        
        Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        try {
            Remove-Item -Path $InstallDir -Recurse -Force
        } catch {
            Write-Host "[WARNING] Could not fully remove existing installation: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "[OK] Installation directory prepared" -ForegroundColor Green
    
    # Clone repository
    Write-Host ""
    Write-Host "[5/6] Downloading Tenjo from GitHub..." -ForegroundColor Cyan
    
    try {
        $gitOutput = & git clone $GitHubRepo $InstallDir 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Git clone failed with output:" -ForegroundColor Red
            Write-Host $gitOutput -ForegroundColor Red
            
            # Try alternative methods
            Write-Host "[INFO] Trying alternative download method..." -ForegroundColor Yellow
            
            # Method 1: Try with --depth 1 for faster clone
            Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
            $gitOutput = & git clone --depth 1 $GitHubRepo $InstallDir 2>&1
            if ($LASTEXITCODE -ne 0) {
                # Method 2: Try downloading as ZIP
                Write-Host "[INFO] Trying ZIP download method..." -ForegroundColor Yellow
                $zipUrl = "https://github.com/Adi-Sumardi/Tenjo/archive/refs/heads/master.zip"
                $zipFile = "$TempDir\tenjo-master.zip"
                
                if (Download-File -Url $zipUrl -OutputPath $zipFile -Description "Tenjo ZIP archive") {
                    # Extract ZIP
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $TempDir)
                    
                    # Move extracted folder
                    $extractedDir = "$TempDir\Tenjo-master"
                    if (Test-Path $extractedDir) {
                        Move-Item $extractedDir $InstallDir
                        Write-Host "[OK] Downloaded via ZIP method" -ForegroundColor Green
                    } else {
                        throw "ZIP extraction failed"
                    }
                } else {
                    throw "All download methods failed. Git output: $gitOutput"
                }
            } else {
                Write-Host "[OK] Shallow clone successful" -ForegroundColor Green
            }
        } else {
            Write-Host "[OK] Repository cloned successfully" -ForegroundColor Green
        }
    } catch {
        throw "Failed to download repository: $($_.Exception.Message)"
    }
    
    if (-not (Test-Path "$InstallDir\client")) {
        throw "Repository downloaded but client directory not found"
    }
    
    # Install Python dependencies
    Write-Host ""
    Write-Host "[6/6] Installing Python dependencies..." -ForegroundColor Cyan
    
    Set-Location "$InstallDir\client"
    
    if (-not (Test-Path "requirements.txt")) {
        throw "requirements.txt not found in client directory"
    }
    
    Write-Host "[INFO] Upgrading pip..." -ForegroundColor Yellow
    & python -m pip install --upgrade pip 2>&1 | Out-Null
    
    Write-Host "[INFO] Installing requirements..." -ForegroundColor Yellow
    $pipOutput = & python -m pip install -r requirements.txt 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] Some packages failed to install:" -ForegroundColor Yellow
        Write-Host $pipOutput -ForegroundColor Red
        
        & python -m pip install -r requirements.txt
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install Python dependencies"
        }
    }
    
    Write-Host "[OK] Dependencies installed successfully" -ForegroundColor Green
    
    # Test installation
    Write-Host ""
    Write-Host "[INFO] Testing installation..." -ForegroundColor Cyan
    
    $pythonTest = & python -c "import sys; print('Python executable:', sys.executable)" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python test failed: $pythonTest"
    }
    
    # Create startup script
    Write-Host "[INFO] Creating startup script..." -ForegroundColor Yellow
    $startupScript = "$InstallDir\start_tenjo.bat"
    $scriptContent = @"
@echo off
cd /d "$InstallDir\client"
python main.py
pause
"@
    $scriptContent | Out-File -FilePath $startupScript -Encoding ASCII
    
    # Add to Windows startup
    Write-Host "[INFO] Configuring auto-start..." -ForegroundColor Yellow
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $startupLink = "$startupFolder\Tenjo.bat"
    
    $autostartContent = @"
@echo off
start /min "" "$startupScript"
"@
    $autostartContent | Out-File -FilePath $startupLink -Encoding ASCII
    
    # Create uninstaller
    Write-Host "[INFO] Creating uninstaller..." -ForegroundColor Yellow
    $uninstaller = "$InstallDir\uninstall.bat"
    $uninstallContent = @"
@echo off
echo Stopping Tenjo monitoring service...
taskkill /f /im python.exe 2>nul
timeout /t 3 /nobreak >nul
echo Removing startup entry...
del "$startupLink" 2>nul
echo Removing installation directory...
rmdir /s /q "$InstallDir"
echo Tenjo has been uninstalled successfully
pause
"@
    $uninstallContent | Out-File -FilePath $uninstaller -Encoding ASCII
    
    # Start service
    Write-Host "[INFO] Starting Tenjo monitoring service..." -ForegroundColor Yellow
    Start-Process -FilePath $startupScript -WindowStyle Minimized
    
    # Cleanup
    Write-Host "[INFO] Cleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    # Success message
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "         INSTALLATION COMPLETED!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation Details:" -ForegroundColor Cyan
    Write-Host "- Python: Verified and working" -ForegroundColor White
    Write-Host "- Git: Verified and working" -ForegroundColor White
    Write-Host "- Tenjo installed to: $InstallDir" -ForegroundColor White
    Write-Host "- Service started in background" -ForegroundColor White
    Write-Host "- Auto-start configured for Windows boot" -ForegroundColor White
    Write-Host "- Uninstaller created" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Open dashboard: http://103.129.149.67" -ForegroundColor White
    Write-Host "2. Your device should appear within 1-2 minutes" -ForegroundColor White
    Write-Host "3. Service runs automatically in background" -ForegroundColor White
    Write-Host ""
    Write-Host "Management:" -ForegroundColor Cyan
    Write-Host "- Uninstall: $InstallDir\uninstall.bat" -ForegroundColor White
    Write-Host "- Logs: $InstallDir\client\logs\" -ForegroundColor White
    Write-Host "- Manual start: $startupScript" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation completed successfully!" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "         INSTALLATION FAILED!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual Installation Steps:" -ForegroundColor Yellow
    Write-Host "1. Install Python 3.13+ from: https://www.python.org/downloads/" -ForegroundColor White
    Write-Host "2. Install Git from: https://git-scm.com/download/win" -ForegroundColor White
    Write-Host "3. Restart PowerShell as Administrator" -ForegroundColor White
    Write-Host "4. Run this installer again" -ForegroundColor White
    Write-Host ""
    Write-Host "For support, visit: https://github.com/Adi-Sumardi/Tenjo" -ForegroundColor White
    
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")