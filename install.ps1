# Tenjo Windows Quick Installer
# One-liner installation script

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TENJO - Employee Monitoring System" -ForegroundColor Cyan
Write-Host "   Quick Installer - Downloading Latest..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Try to download robust installer first
    Write-Host "[INFO] Downloading robust installer..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows_robust.ps1' -OutFile "$env:TEMP\tenjo_installer.ps1" -UseBasicParsing -TimeoutSec 60
    
    if (Test-Path "$env:TEMP\tenjo_installer.ps1") {
        Write-Host "[OK] Robust installer downloaded, executing..." -ForegroundColor Green
        & "$env:TEMP\tenjo_installer.ps1"
    } else {
        throw "Robust installer download failed"
    }
} catch {
    Write-Host "[WARNING] Robust installer failed, trying standard installer..." -ForegroundColor Yellow
    
    try {
        # Fallback to standard installer
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1' -OutFile "$env:TEMP\tenjo_installer_standard.ps1" -UseBasicParsing -TimeoutSec 60
        
        if (Test-Path "$env:TEMP\tenjo_installer_standard.ps1") {
            Write-Host "[OK] Standard installer downloaded, executing..." -ForegroundColor Green
            & "$env:TEMP\tenjo_installer_standard.ps1"
        } else {
            throw "Standard installer download failed"
        }
    } catch {
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Red
        Write-Host "    INSTALLER DOWNLOAD FAILED!" -ForegroundColor Red
        Write-Host "============================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual Installation Options:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Option 1 - Direct download:" -ForegroundColor Cyan
        Write-Host "1. Visit: https://github.com/Adi-Sumardi/Tenjo" -ForegroundColor White
        Write-Host "2. Download install_windows.ps1" -ForegroundColor White
        Write-Host "3. Right-click → Run with PowerShell" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 2 - Manual commands:" -ForegroundColor Cyan
        Write-Host "git clone https://github.com/Adi-Sumardi/Tenjo.git" -ForegroundColor Gray
        Write-Host "cd Tenjo\client" -ForegroundColor Gray
        Write-Host "python -m pip install -r requirements.txt" -ForegroundColor Gray
        Write-Host "python main.py" -ForegroundColor Gray
        Write-Host ""
        Write-Host "For support: https://github.com/Adi-Sumardi/Tenjo/issues" -ForegroundColor White
    }
}