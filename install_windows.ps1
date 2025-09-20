# Tenjo Windows Installer - PowerShell Version
# More robust alternative to batch file

Write-Host ""
Write-Host "============================================"
Write-Host "   TENJO - Employee Monitoring System"
Write-Host "   PowerShell Installer v2.0"
Write-Host "============================================"
Write-Host ""

# Set variables
$InstallDir = "$env:USERPROFILE\.tenjo"
$GitHubRepo = "https://github.com/Adi-Sumardi/Tenjo.git"
$TempDir = "$env:TEMP\tenjo_install_$(Get-Random)"

Write-Host "[INFO] Installation directory: $InstallDir"
Write-Host "[INFO] Temporary directory: $TempDir"
Write-Host ""

# Create temp directory
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # Check Python
    Write-Host "[1/6] Checking Python installation..."
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Python found: $pythonVersion"
        } else {
            throw "Python not found"
        }
    } catch {
        Write-Host "[WARNING] Python not found! Downloading Python 3.13..."
        
        $pythonUrl = "https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe"
        $pythonInstaller = "$TempDir\python_installer.exe"
        
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -ErrorAction Stop
        Write-Host "[INFO] Installing Python 3.13..."
        
        Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=0", "PrependPath=1", "Include_test=0" -Wait
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Check again
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Python installation failed"
        }
        Write-Host "[OK] Python installed: $pythonVersion"
    }

    # Check Git
    Write-Host ""
    Write-Host "[2/6] Checking Git installation..."
    try {
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Git found: $gitVersion"
        } else {
            throw "Git not found"
        }
    } catch {
        Write-Host "[WARNING] Git not found! Downloading Git for Windows..."
        
        $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
        $gitInstaller = "$TempDir\git_installer.exe"
        
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -ErrorAction Stop
        Write-Host "[INFO] Installing Git for Windows..."
        
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS" -Wait
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Check again
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Git installation failed"
        }
        Write-Host "[OK] Git installed: $gitVersion"
    }

    # Remove existing installation
    Write-Host ""
    Write-Host "[3/6] Preparing installation directory..."
    if (Test-Path $InstallDir) {
        Write-Host "[INFO] Removing existing installation..."
        Stop-Process -Name "python" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Clone repository
    Write-Host ""
    Write-Host "[4/6] Downloading Tenjo from GitHub..."
    git clone $GitHubRepo $InstallDir
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to download from GitHub"
    }
    Write-Host "[OK] Repository downloaded"

    # Install dependencies
    Write-Host ""
    Write-Host "[5/6] Installing Python dependencies..."
    Set-Location "$InstallDir\client"
    
    Write-Host "[INFO] Upgrading pip..."
    python -m pip install --upgrade pip | Out-Null
    
    Write-Host "[INFO] Installing requirements..."
    python -m pip install -r requirements.txt | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install dependencies"
    }
    Write-Host "[OK] Dependencies installed"

    # Test installation
    Write-Host ""
    Write-Host "[6/6] Testing installation..."
    python -c "from src.core.config import Config; print('[TEST] Config loaded successfully')" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] Config test failed, but Python is working"
        python -c "print('[TEST] Python is working')"
    } else {
        Write-Host "[OK] Installation test passed"
    }

    # Create startup script
    $startupScript = "$InstallDir\start_tenjo.bat"
    @"
@echo off
cd /d "$InstallDir\client"
python main.py
"@ | Out-File -FilePath $startupScript -Encoding ASCII

    # Add to Windows startup
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $startupLink = "$startupFolder\Tenjo.bat"
    
    @"
@echo off
start /min "" "$startupScript"
"@ | Out-File -FilePath $startupLink -Encoding ASCII

    Write-Host "[INFO] Auto-start configured"

    # Create uninstaller
    $uninstaller = "$InstallDir\uninstall.bat"
    @"
@echo off
echo Stopping Tenjo service...
taskkill /f /im python.exe 2>nul
echo Removing startup entry...
del "$startupLink" 2>nul
echo Removing installation directory...
rmdir /s /q "$InstallDir"
echo Tenjo uninstalled successfully
pause
"@ | Out-File -FilePath $uninstaller -Encoding ASCII

    # Start service
    Write-Host "[INFO] Starting Tenjo monitoring service..."
    Start-Process -FilePath $startupScript -WindowStyle Minimized

    # Cleanup
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

    # Success message
    Write-Host ""
    Write-Host "============================================"
    Write-Host "         INSTALLATION COMPLETED!"
    Write-Host "============================================"
    Write-Host ""
    Write-Host "[✓] Python verified"
    Write-Host "[✓] Git verified"
    Write-Host "[✓] Tenjo installed to: $InstallDir"
    Write-Host "[✓] Service started and configured for auto-start"
    Write-Host "[✓] Running in stealth mode"
    Write-Host ""
    Write-Host "MANAGEMENT:"
    Write-Host "- Dashboard: http://103.129.149.67"
    Write-Host "- Uninstall: Run $InstallDir\uninstall.bat"
    Write-Host "- Logs: $InstallDir\client\logs\"
    Write-Host ""
    Write-Host "Your device will appear in the dashboard shortly."
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "[ERROR] Installation failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "MANUAL INSTALLATION STEPS:"
    Write-Host "1. Install Python 3.13+ from: https://www.python.org/downloads/"
    Write-Host "2. Install Git from: https://git-scm.com/download/win"
    Write-Host "3. Run this installer again"
    Write-Host ""
    
    # Cleanup on error
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
} finally {
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}