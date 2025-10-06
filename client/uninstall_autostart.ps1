# Tenjo Client - Windows Autostart Uninstaller

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Tenjo Client - Autostart Uninstaller" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$StartupRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$AppName = "TenjoClient"

# Check if exists
$Exists = Get-ItemProperty -Path $StartupRegPath -Name $AppName -ErrorAction SilentlyContinue

if (-not $Exists) {
    Write-Host "⚠️  Tenjo client autostart not found in registry" -ForegroundColor Yellow
} else {
    # Remove from registry
    try {
        Remove-ItemProperty -Path $StartupRegPath -Name $AppName
        Write-Host "✓ Removed from Windows Startup (Registry)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to remove from registry: $_" -ForegroundColor Red
    }
}

# Stop running instances
Write-Host ""
Write-Host "Stopping running Tenjo client processes..." -ForegroundColor Yellow
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClientScript = Join-Path $ScriptDir "main.py"

Get-WmiObject Win32_Process -Filter "name='python.exe' OR name='pythonw.exe'" | ForEach-Object {
    $cmdLine = $_.CommandLine
    if ($cmdLine -like "*main.py*" -and $cmdLine -like "*Tenjo*") {
        Write-Host "  Stopping PID $($_.ProcessId)..." -ForegroundColor Gray
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "✅ Tenjo client autostart removed" -ForegroundColor Green
Write-Host ""
Write-Host "Log files preserved at:" -ForegroundColor Yellow
Write-Host "  %APPDATA%\Tenjo\logs\" -ForegroundColor White
Write-Host ""
Write-Host "To reinstall, run: install_autostart.ps1" -ForegroundColor Yellow
