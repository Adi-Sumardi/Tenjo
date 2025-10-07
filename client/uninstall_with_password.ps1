# Tenjo Client - Uninstall with Password Protection
# Requires password to uninstall client

# Color codes
$GREEN = "Green"
$RED = "Red"
$YELLOW = "Yellow"

Write-Host "========================================" -ForegroundColor $YELLOW
Write-Host "  TENJO CLIENT - UNINSTALL" -ForegroundColor $YELLOW
Write-Host "========================================" -ForegroundColor $YELLOW
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] ERROR: Script harus dijalankan sebagai Administrator" -ForegroundColor $RED
    Write-Host ""
    Write-Host "Cara menjalankan sebagai Admin:" -ForegroundColor $YELLOW
    Write-Host "1. Klik kanan PowerShell" -ForegroundColor $YELLOW
    Write-Host "2. Pilih 'Run as Administrator'" -ForegroundColor $YELLOW
    Write-Host "3. Jalankan script ini lagi" -ForegroundColor $YELLOW
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Installation directory
$INSTALL_DIR = "C:\ProgramData\Realtek 786"
$PASSWORD_FILE = "$INSTALL_DIR\.password_hash"

Write-Host "[1/5] Checking installation..." -ForegroundColor $YELLOW

# Check if client is installed
if (-not (Test-Path $INSTALL_DIR)) {
    Write-Host "[!] ERROR: Tenjo client tidak terinstall" -ForegroundColor $RED
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Installation found" -ForegroundColor $GREEN

# Check if password is set
if (-not (Test-Path $PASSWORD_FILE)) {
    Write-Host "[!] ERROR: Password belum diset" -ForegroundColor $RED
    Write-Host ""
    Write-Host "Silakan hubungi administrator untuk set password terlebih dahulu" -ForegroundColor $YELLOW
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[2/5] Password verification..." -ForegroundColor $YELLOW
Write-Host ""

# Prompt for password (max 3 attempts)
$MAX_ATTEMPTS = 3
$attempt = 0
$verified = $false

while ($attempt -lt $MAX_ATTEMPTS) {
    $attempt++
    Write-Host "Attempt $attempt/$MAX_ATTEMPTS" -ForegroundColor $YELLOW
    $password = Read-Host "Masukkan password" -AsSecureString
    $password_plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    
    # Verify password using Python module
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        $result = & python "$INSTALL_DIR\src\utils\password_protection.py" verify "$password_plain" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $verified = $true
            Write-Host ""
            Write-Host "[OK] Password benar!" -ForegroundColor $GREEN
            break
        } else {
            Write-Host ""
            Write-Host "[!] Password salah!" -ForegroundColor $RED
            if ($attempt -lt $MAX_ATTEMPTS) {
                Write-Host "Silakan coba lagi..." -ForegroundColor $YELLOW
                Write-Host ""
            }
        }
    } else {
        Write-Host "[!] ERROR: Python tidak ditemukan" -ForegroundColor $RED
        Read-Host "Press Enter to exit"
        exit 1
    }
}

if (-not $verified) {
    Write-Host ""
    Write-Host "[!] FAILED: Password salah 3 kali" -ForegroundColor $RED
    Write-Host "Uninstall dibatalkan untuk keamanan" -ForegroundColor $RED
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "[3/6] Unlocking folder protection..." -ForegroundColor $YELLOW

# Unlock folder first
$masterPassword = "TenjoAdilabs96"
& python "$INSTALL_DIR\src\utils\folder_protection.py" unprotect "$masterPassword" | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Folder unlocked" -ForegroundColor $GREEN
} else {
    Write-Host "[!] WARNING: Gagal unlock folder (akan coba lanjut)" -ForegroundColor $YELLOW
}

Write-Host "[4/6] Stopping client..." -ForegroundColor $YELLOW

# Stop any running client processes
Get-Process -Name python -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like "*$INSTALL_DIR*"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2
Write-Host "[OK] Client stopped" -ForegroundColor $GREEN

Write-Host "[5/6] Removing scheduled tasks..." -ForegroundColor $YELLOW

# Remove scheduled tasks
$tasks = @("TenjoMonitor", "TenjoWatchdog")
foreach ($task in $tasks) {
    try {
        Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  - Removed: $task" -ForegroundColor $GREEN
    } catch {
        Write-Host "  - Task not found: $task" -ForegroundColor $YELLOW
    }
}

# Remove from Registry (startup)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
try {
    Remove-ItemProperty -Path $regPath -Name "TenjoMonitor" -ErrorAction SilentlyContinue
    Write-Host "  - Removed Registry startup" -ForegroundColor $GREEN
} catch {
    Write-Host "  - Registry entry not found" -ForegroundColor $YELLOW
}

Write-Host "[6/6] Removing files..." -ForegroundColor $YELLOW

# Remove installation directory
try {
    Remove-Item -Path $INSTALL_DIR -Recurse -Force -ErrorAction Stop
    Write-Host "[OK] Files removed" -ForegroundColor $GREEN
} catch {
    Write-Host "[!] WARNING: Tidak bisa hapus semua file" -ForegroundColor $YELLOW
    Write-Host "Mungkin ada file yang sedang digunakan" -ForegroundColor $YELLOW
}

Write-Host ""
Write-Host "========================================" -ForegroundColor $GREEN
Write-Host "  UNINSTALL COMPLETED" -ForegroundColor $GREEN
Write-Host "========================================" -ForegroundColor $GREEN
Write-Host ""
Write-Host "Tenjo client berhasil di-uninstall" -ForegroundColor $GREEN
Write-Host ""

Read-Host "Press Enter to exit"
