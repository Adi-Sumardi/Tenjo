# Tenjo Windows Quick Installer
# One-liner installation script

Write-Host "Tenjo Employee Monitoring - Quick Installer" -ForegroundColor Cyan
Write-Host "Downloading and executing main installer..." -ForegroundColor Yellow

try {
    # Download and execute main installer
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1' -OutFile "$env:TEMP\tenjo_installer.ps1" -UseBasicParsing
    
    if (Test-Path "$env:TEMP\tenjo_installer.ps1") {
        & "$env:TEMP\tenjo_installer.ps1"
    } else {
        throw "Failed to download installer"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Manual installation: https://github.com/Adi-Sumardi/Tenjo" -ForegroundColor Yellow
}