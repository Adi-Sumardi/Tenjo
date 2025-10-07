# Tenjo Client - Lock Folder Utility
# Re-apply folder protection (requires password)

# Color codes
$GREEN = "Green"
$RED = "Red"
$YELLOW = "Yellow"

Write-Host "========================================" -ForegroundColor $YELLOW
Write-Host "  TENJO CLIENT - LOCK FOLDER" -ForegroundColor $YELLOW
Write-Host "========================================" -ForegroundColor $YELLOW
Write-Host ""

# Installation directory
$INSTALL_DIR = "C:\ProgramData\Realtek 786"

Write-Host "[1/3] Checking installation..." -ForegroundColor $YELLOW

# Check if client is installed
if (-not (Test-Path $INSTALL_DIR)) {
    Write-Host "[!] ERROR: Tenjo client tidak terinstall" -ForegroundColor $RED
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Installation found" -ForegroundColor $GREEN

Write-Host "[2/3] Password verification..." -ForegroundColor $YELLOW
Write-Host ""

# Prompt for master password
$password = Read-Host "Masukkan master password" -AsSecureString
$password_plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Verify and lock folder
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    Write-Host ""
    Write-Host "[3/3] Locking folder..." -ForegroundColor $YELLOW
    
    $result = & python "$INSTALL_DIR\src\utils\folder_protection.py" protect "$password_plain" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Folder berhasil di-lock!" -ForegroundColor $GREEN
        Write-Host ""
        Write-Host "Folder sekarang diproteksi:" -ForegroundColor $GREEN
        Write-Host "- Tidak bisa dihapus tanpa password" -ForegroundColor $GREEN
        Write-Host "- File critical hidden + system" -ForegroundColor $GREEN
    } else {
        Write-Host "[!] ERROR: $result" -ForegroundColor $RED
    }
} else {
    Write-Host "[!] ERROR: Python tidak ditemukan" -ForegroundColor $RED
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Read-Host "Press Enter to exit"
