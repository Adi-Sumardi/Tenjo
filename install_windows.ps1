# Tenjo Windows PowerShell Installer v1.0.3
# One-liner: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1" -OutFile "install.ps1"; PowerShell -ExecutionPolicy Bypass -File "install.ps1"

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   TENJO - Remote Installer v1.0.5" -ForegroundColor Cyan
Write-Host "   With Password + Folder Protection" -ForegroundColor Cyan
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
    Write-Host "[1/6] Checking Python..." -ForegroundColor Cyan
    $pythonOk = $false
    try {
        $pythonVersion = & python --version 2>&1
        if ($pythonVersion -match "Python (\d+)\.(\d+)") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
                Write-Host "[!] Python $major.$minor too old! Need 3.10+" -ForegroundColor Yellow
            } else {
                Write-Host "[OK] Python $major.$minor detected" -ForegroundColor Green
                $pythonOk = $true
            }
        }
    } catch {
        Write-Host "[!] Python not found" -ForegroundColor Yellow
    }
    
    if (-not $pythonOk) {
        Write-Host ""
        Write-Host "[AUTO-INSTALL] Installing Python 3.10.11..." -ForegroundColor Cyan
        
        # Download Python
        $pythonUrl = "https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe"
        $pythonInstaller = "$env:TEMP\python_installer.exe"
        
        Write-Host "  Downloading... (this may take 1-2 minutes)" -ForegroundColor Yellow
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
        } catch {
            Write-Host "[ERROR] Failed to download Python installer!" -ForegroundColor Red
            Write-Host "Please install Python 3.10+ manually from python.org" -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Install Python
        Write-Host "  Installing... (this may take 2-3 minutes)" -ForegroundColor Yellow
        $process = Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet","InstallAllUsers=1","PrependPath=1","Include_test=0" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            Write-Host "[ERROR] Python installation failed!" -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Cleanup
        Remove-Item $pythonInstaller -Force -ErrorAction SilentlyContinue
        
        # Verify
        Start-Sleep -Seconds 2
        try {
            $pythonVersion = & python --version 2>&1
            if ($pythonVersion -match "Python (\d+)\.(\d+)") {
                Write-Host "[OK] Python $($matches[1]).$($matches[2]) installed successfully!" -ForegroundColor Green
            } else {
                throw "Verification failed"
            }
        } catch {
            Write-Host "[ERROR] Python installed but not accessible" -ForegroundColor Red
            Write-Host "Please restart PowerShell and run installer again" -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
    
    # Download
    Write-Host ""
    Write-Host "[2/6] Downloading from GitHub..." -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $GitHubZip -OutFile $TempZip -UseBasicParsing
    Write-Host "[OK] Downloaded" -ForegroundColor Green
    
    # Extract
    Write-Host ""
    Write-Host "[3/6] Extracting files..." -ForegroundColor Cyan
    if (Test-Path $TempExtract) { Remove-Item -Path $TempExtract -Recurse -Force }
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
    
    # Copy client files
    if (Test-Path $InstallDir) { Remove-Item -Path $InstallDir -Recurse -Force }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -Path "$TempExtract\Tenjo-master\client\*" -Destination $InstallDir -Recurse -Force
    Write-Host "[OK] Files extracted to $InstallDir" -ForegroundColor Green
    
    # Install dependencies
    Write-Host ""
    Write-Host "[4/6] Installing Python packages..." -ForegroundColor Cyan
    Set-Location $InstallDir
    & python -m pip install --upgrade pip --quiet 2>&1 | Out-Null
    & python -m pip install -r requirements.txt --quiet 2>&1 | Out-Null
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
    
    # Configure
    Write-Host ""
    Write-Host "[5/6] Configuring service..." -ForegroundColor Cyan
    
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
    
    # Scheduled task XML for main client
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
    
    # Scheduled task XML for watchdog
    $watchdogXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers><LogonTrigger><Enabled>true</Enabled></LogonTrigger></Triggers>
  <Principals><Principal><LogonType>InteractiveToken</LogonType><RunLevel>HighestAvailable</RunLevel></Principal></Principals>
  <Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries></Settings>
  <Actions><Exec><Command>python.exe</Command><Arguments>watchdog.py</Arguments><WorkingDirectory>$InstallDir</WorkingDirectory></Exec></Actions>
</Task>
"@
    $watchdogXmlPath = "$env:TEMP\tenjo_watchdog.xml"
    $watchdogXml | Set-Content $watchdogXmlPath
    & schtasks /Create /TN "TenjoWatchdog" /XML $watchdogXmlPath /F | Out-Null
    Remove-Item $watchdogXmlPath -Force
    
    # Set password protection
    Write-Host ""
    Write-Host "[6/7] Setting up password protection..." -ForegroundColor Cyan
    $defaultPassword = "admin123"
    
    # Ask if user wants custom password
    Write-Host ""
    Write-Host "Password default: admin123" -ForegroundColor Yellow
    $useCustom = Read-Host "Gunakan password custom? (Y/N, default: N)"
    
    if ($useCustom -eq "Y" -or $useCustom -eq "y") {
        $customPass = Read-Host "Masukkan password baru (min 6 karakter)" -AsSecureString
        $customPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($customPass))
        if ($customPassPlain.Length -ge 6) {
            $defaultPassword = $customPassPlain
            Write-Host "[OK] Password custom diset" -ForegroundColor Green
        } else {
            Write-Host "[!] Password terlalu pendek, menggunakan default" -ForegroundColor Yellow
        }
    }
    
    # Set password
    & python "$InstallDir\src\utils\password_protection.py" set "$defaultPassword" | Out-Null
    Write-Host "[OK] Password protection aktif" -ForegroundColor Green
    Write-Host ""
    Write-Host "PENTING: Simpan password ini untuk uninstall client!" -ForegroundColor Yellow
    Write-Host "Password: $defaultPassword" -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Seconds 2
    
    # Apply folder protection
    Write-Host "[7/8] Protecting folder..." -ForegroundColor Cyan
    $masterPassword = "TenjoAdilabs96"
    $protectResult = & python "$InstallDir\src\utils\folder_protection.py" protect "$masterPassword" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Folder protection aktif" -ForegroundColor Green
        Write-Host "  - Folder tidak bisa dihapus paksa" -ForegroundColor Green
        Write-Host "  - File critical di-hidden" -ForegroundColor Green
    } else {
        Write-Host "[!] WARNING: Gagal apply folder protection" -ForegroundColor Yellow
    }
    
    # Start service
    Write-Host "[8/8] Starting service..." -ForegroundColor Cyan
    Start-Process -FilePath "$InstallDir\start_tenjo.bat" -WindowStyle Hidden
    Write-Host "[OK] Service started" -ForegroundColor Green
    
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
