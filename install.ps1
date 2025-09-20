# Tenjo Windows Quick Installer
# Download and execute main installer

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TENJO - Employee Monitoring System" -ForegroundColor Cyan
Write-Host "   Quick Installer v3.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "[INFO] Downloading main installer..." -ForegroundColor Yellow
    
    # Download main installer
    $installerUrl = 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1'
    $installerPath = "$env:TEMP\tenjo_main_installer.ps1"
    
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing -TimeoutSec 60
    
    if (Test-Path $installerPath) {
        Write-Host "[OK] Main installer downloaded successfully" -ForegroundColor Green
        Write-Host "[INFO] Executing main installer..." -ForegroundColor Yellow
        Write-Host ""
        
        # Execute main installer
        & $installerPath
        
        # Cleanup
        Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
    } else {
        throw "Failed to download main installer"
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
    
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}