# Tenjo Windows PowerShell Installer v1.0.3
# One-liner: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1" -OutFile "install.ps1"; PowerShell -ExecutionPolicy Bypass -File "install.ps1"

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   TENJO - Remote Installer v1.0.3" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$InstallDir = "C:\ProgramData\Tenjo"
$GitHubZip = "https://github.com/Adi-Sumardi/Tenjo/archive/refs/heads/master.zip"
$TempZip = "$env:TEMP\tenjo.zip"
$TempExtract = "$env:TEMP\tenjo_extracted"

try {
    # Check Admin
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "[ERROR] Administrator privileges required!" -ForegroundColor Red
        Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Check Python
    Write-Host "[1/5] Checking Python..." -ForegroundColor Cyan
    try {
        $pythonVersion = & python --version 2>&1
        if ($pythonVersion -match "Python (\d+)\.(\d+)") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
                throw "Python $major.$minor too old! Need 3.10+"
            }
            Write-Host "[OK] Python $major.$minor detected" -ForegroundColor Green
        } else {
            throw "Python not found"
        }
    } catch {
        Write-Host "[ERROR] Python 3.10+ required!" -ForegroundColor Red
        Write-Host "Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Download
    Write-Host ""
    Write-Host "[2/5] Downloading from GitHub..." -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $GitHubZip -OutFile $TempZip -UseBasicParsing
    Write-Host "[OK] Downloaded" -ForegroundColor Green
    
    # Extract
    Write-Host ""
    Write-Host "[3/5] Extracting files..." -ForegroundColor Cyan
    if (Test-Path $TempExtract) { Remove-Item -Path $TempExtract -Recurse -Force }
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
    
    # Copy client files
    if (Test-Path $InstallDir) { Remove-Item -Path $InstallDir -Recurse -Force }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -Path "$TempExtract\Tenjo-master\client\*" -Destination $InstallDir -Recurse -Force
    Write-Host "[OK] Files extracted to $InstallDir" -ForegroundColor Green
    
    # Install dependencies
    Write-Host ""
    Write-Host "[4/5] Installing Python packages..." -ForegroundColor Cyan
    Set-Location $InstallDir
    & python -m pip install --upgrade pip --quiet 2>&1 | Out-Null
    & python -m pip install -r requirements.txt --quiet 2>&1 | Out-Null
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
    
    # Configure
    Write-Host ""
    Write-Host "[5/5] Configuring service..." -ForegroundColor Cyan
    
    # Server override
    @{server_url = "https://tenjo.adilabs.id"} | ConvertTo-Json | Set-Content "$InstallDir\server_override.json"
    
    # Batch wrapper
    @"
@echo off
cd /d "C:\ProgramData\Tenjo"
python.exe main.py
"@ | Set-Content "$InstallDir\start_tenjo.bat"
    
    # Registry autostart
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $regPath -Name "TenjoMonitor" -Value "$InstallDir\start_tenjo.bat" -Force
    
    # Scheduled task XML
    $taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers><LogonTrigger><Enabled>true</Enabled></LogonTrigger></Triggers>
  <Principals><Principal><LogonType>InteractiveToken</LogonType><RunLevel>HighestAvailable</RunLevel></Principal></Principals>
  <Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries></Settings>
  <Actions><Exec><Command>$InstallDir\start_tenjo.bat</Command></Exec></Actions>
</Task>
"@
    $taskXmlPath = "$env:TEMP\tenjo_task.xml"
    $taskXml | Set-Content $taskXmlPath
    & schtasks /Create /TN "TenjoMonitor" /XML $taskXmlPath /F | Out-Null
    Remove-Item $taskXmlPath -Force
    
    # Start service
    Start-Process -FilePath "$InstallDir\start_tenjo.bat" -WindowStyle Hidden
    Write-Host "[OK] Service configured and started" -ForegroundColor Green
    
    # Cleanup
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force }
    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   INSTALLATION COMPLETE!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Client installed to: $InstallDir" -ForegroundColor White
    Write-Host "Dashboard: https://tenjo.adilabs.id" -ForegroundColor White
    Write-Host ""
    Write-Host "Client should appear in dashboard within 2 minutes" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "   INSTALLATION FAILED!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

Read-Host "Press Enter to exit"
