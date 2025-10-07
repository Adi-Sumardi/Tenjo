# Manual Folder Protection Script
# Run this if folder protection failed during installation

# Color codes
$GREEN = "Green"
$RED = "Red"
$YELLOW = "Yellow"

Write-Host "========================================" -ForegroundColor $YELLOW
Write-Host "  MANUAL FOLDER PROTECTION" -ForegroundColor $YELLOW
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
$INSTALL_DIR = "C:\ProgramData\Tenjo"
$MASTER_PASSWORD = "TenjoAdilabs96"

Write-Host "[1/3] Checking installation..." -ForegroundColor $YELLOW

if (-not (Test-Path $INSTALL_DIR)) {
    Write-Host "[!] ERROR: Tenjo tidak terinstall di $INSTALL_DIR" -ForegroundColor $RED
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Installation found" -ForegroundColor $GREEN

Write-Host "[2/3] Checking folder_protection.py..." -ForegroundColor $YELLOW

$PROTECTION_SCRIPT = "$INSTALL_DIR\src\utils\folder_protection.py"
if (-not (Test-Path $PROTECTION_SCRIPT)) {
    Write-Host "[!] ERROR: folder_protection.py tidak ditemukan" -ForegroundColor $RED
    Write-Host "  Path: $PROTECTION_SCRIPT" -ForegroundColor $RED
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Protection script found" -ForegroundColor $GREEN

Write-Host "[3/3] Applying folder protection..." -ForegroundColor $YELLOW
Write-Host ""

# Check Python
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "[!] ERROR: Python tidak ditemukan" -ForegroundColor $RED
    Write-Host "  Pastikan Python terinstall dan ada di PATH" -ForegroundColor $RED
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Apply folder protection
try {
    $result = & python "$PROTECTION_SCRIPT" protect "$MASTER_PASSWORD" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Folder protection berhasil diterapkan!" -ForegroundColor $GREEN
        Write-Host ""
        Write-Host "Proteksi aktif:" -ForegroundColor $GREEN
        Write-Host "  - Folder tidak bisa dihapus paksa" -ForegroundColor $GREEN
        Write-Host "  - Critical files di-hidden" -ForegroundColor $GREEN
        Write-Host "  - ICACLS deny delete" -ForegroundColor $GREEN
        Write-Host ""
        
        # Show protection status
        Write-Host "Status:" -ForegroundColor $YELLOW
        & python "$PROTECTION_SCRIPT" status
        
    } else {
        Write-Host "[!] ERROR: Gagal apply folder protection" -ForegroundColor $RED
        Write-Host ""
        Write-Host "Output:" -ForegroundColor $YELLOW
        Write-Host $result -ForegroundColor $YELLOW
        Write-Host ""
        Write-Host "Kemungkinan penyebab:" -ForegroundColor $YELLOW
        Write-Host "1. Tidak dijalankan sebagai Administrator" -ForegroundColor $YELLOW
        Write-Host "2. Password salah (seharusnya: TenjoAdilabs96)" -ForegroundColor $YELLOW
        Write-Host "3. ICACLS tidak bisa dijalankan" -ForegroundColor $YELLOW
        Write-Host ""
    }
} catch {
    Write-Host "[!] ERROR: Exception saat apply protection" -ForegroundColor $RED
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor $RED
    Write-Host ""
}

Write-Host ""
Read-Host "Press Enter to exit"
