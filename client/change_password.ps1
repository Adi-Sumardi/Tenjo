# Tenjo Client - Change Password Utility

# Color codes
$GREEN = "Green"
$RED = "Red"
$YELLOW = "Yellow"

Write-Host "========================================" -ForegroundColor $YELLOW
Write-Host "  TENJO CLIENT - CHANGE PASSWORD" -ForegroundColor $YELLOW
Write-Host "========================================" -ForegroundColor $YELLOW
Write-Host ""

# Installation directory
$INSTALL_DIR = "C:\ProgramData\Realtek 786"
$PASSWORD_FILE = "$INSTALL_DIR\.password_hash"

Write-Host "[1/3] Checking installation..." -ForegroundColor $YELLOW

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
    Write-Host ""
    Write-Host "[!] Password belum diset, akan set password baru..." -ForegroundColor $YELLOW
    Write-Host ""
    Write-Host "[2/3] Setting new password..." -ForegroundColor $YELLOW
    
    $newPassword = Read-Host "Masukkan password baru (min 6 karakter)" -AsSecureString
    $newPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newPassword))
    
    if ($newPasswordPlain.Length -lt 6) {
        Write-Host "[!] ERROR: Password minimal 6 karakter" -ForegroundColor $RED
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Set password using Python module
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        & python "$INSTALL_DIR\src\utils\password_protection.py" set "$newPasswordPlain" | Out-Null
        Write-Host "[OK] Password berhasil diset!" -ForegroundColor $GREEN
    } else {
        Write-Host "[!] ERROR: Python tidak ditemukan" -ForegroundColor $RED
        Read-Host "Press Enter to exit"
        exit 1
    }
    
} else {
    Write-Host ""
    Write-Host "[2/3] Verifying old password..." -ForegroundColor $YELLOW
    
    $oldPassword = Read-Host "Masukkan password lama" -AsSecureString
    $oldPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($oldPassword))
    
    # Verify old password
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        & python "$INSTALL_DIR\src\utils\password_protection.py" verify "$oldPasswordPlain" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[!] ERROR: Password lama salah!" -ForegroundColor $RED
            Write-Host ""
            Read-Host "Press Enter to exit"
            exit 1
        }
        Write-Host "[OK] Password lama benar" -ForegroundColor $GREEN
    } else {
        Write-Host "[!] ERROR: Python tidak ditemukan" -ForegroundColor $RED
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host ""
    Write-Host "[3/3] Setting new password..." -ForegroundColor $YELLOW
    
    $newPassword = Read-Host "Masukkan password baru (min 6 karakter)" -AsSecureString
    $newPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newPassword))
    
    if ($newPasswordPlain.Length -lt 6) {
        Write-Host "[!] ERROR: Password minimal 6 karakter" -ForegroundColor $RED
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Change password
    $result = & python "$INSTALL_DIR\src\utils\password_protection.py" change "$oldPasswordPlain" "$newPasswordPlain" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Password berhasil diubah!" -ForegroundColor $GREEN
    } else {
        Write-Host "[!] ERROR: $result" -ForegroundColor $RED
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor $GREEN
Write-Host "  PASSWORD CHANGE COMPLETED" -ForegroundColor $GREEN
Write-Host "========================================" -ForegroundColor $GREEN
Write-Host ""
Write-Host "Password berhasil diubah!" -ForegroundColor $GREEN
Write-Host "Simpan password baru untuk uninstall client" -ForegroundColor $YELLOW
Write-Host ""

Read-Host "Press Enter to exit"
