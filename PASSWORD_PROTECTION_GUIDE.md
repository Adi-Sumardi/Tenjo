# Password Protection - Tenjo Client

## 📋 Fitur Password Protection

Tenjo Client v1.0.4 sekarang dilengkapi dengan **Password Protection** untuk mencegah uninstall yang tidak sah.

### ✅ Fitur:
- Password wajib untuk uninstall client
- Default password: `admin123` (bisa custom saat install)
- 3 kali percobaan, setelah itu uninstall dibatalkan
- SHA256 password hashing (secure)
- File password dengan restricted permissions
- Utility untuk ganti password

---

## 🔧 Cara Kerja

### 1. Instalasi (Set Password Otomatis)

**Via PowerShell (Remote):**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1" -OutFile "install.ps1"
PowerShell -ExecutionPolicy Bypass -File "install.ps1"
```

**Via Batch:**
```cmd
curl -L -o install.bat https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat
install.bat
```

Saat instalasi, akan ditanya:
```
Password default: admin123
Gunakan password custom? (Y/N, default: N):
```

- Ketik `N` = Pakai password default: `admin123`
- Ketik `Y` = Masukkan password custom (min 6 karakter)

**PENTING:** Simpan password ini! Diperlukan untuk uninstall client.

---

### 2. Uninstall Client (Butuh Password)

**Via PowerShell:**
```powershell
cd C:\ProgramData\Tenjo
.\uninstall_with_password.ps1
```

**Via Batch:**
```cmd
cd C:\ProgramData\Tenjo
uninstall_with_password.bat
```

Akan muncul prompt:
```
Attempt 1/3
Masukkan password: ********
```

- Password benar → Uninstall berjalan
- Password salah 3 kali → Uninstall dibatalkan

---

### 3. Ganti Password

**Via PowerShell:**
```powershell
cd C:\ProgramData\Tenjo
.\change_password.ps1
```

**Via Batch:**
```cmd
cd C:\ProgramData\Tenjo
change_password.bat
```

Akan muncul prompt:
```
Masukkan password lama: ********
Masukkan password baru (min 6 karakter): ********
```

---

## 📂 File Structure

```
C:\ProgramData\Tenjo\
├── .password_hash              # Password hash (SHA256)
├── uninstall_with_password.ps1 # Uninstall script (PowerShell)
├── uninstall_with_password.bat # Uninstall script (Batch)
├── change_password.ps1         # Change password (PowerShell)
├── change_password.bat         # Change password (Batch)
└── src\utils\
    └── password_protection.py  # Password module
```

---

## 🔐 Keamanan

### Password Hashing
- Algorithm: **SHA256**
- Plain text password → Hash → Simpan hash only
- Password tidak bisa di-reverse (one-way hash)

### File Protection
- File `.password_hash` dengan restricted permissions
- Windows: `icacls` untuk limit access
- Unix: `chmod 400` (read-only for owner)

### Brute Force Protection
- Max 3 percobaan per run
- Setelah 3 kali salah → Uninstall dibatalkan
- Tidak ada delay/timeout → User bisa coba lagi (tapi harus run script ulang)

---

## 📖 Command Reference

### Password Protection Module
```bash
# Set password
python password_protection.py set <password>

# Verify password
python password_protection.py verify <password>

# Change password
python password_protection.py change <old_password> <new_password>

# Reset password (admin only)
python password_protection.py reset <new_password>
```

### Uninstall dengan Password
```powershell
# PowerShell (as Administrator)
cd C:\ProgramData\Tenjo
.\uninstall_with_password.ps1
```

```cmd
# Batch (as Administrator)
cd C:\ProgramData\Tenjo
uninstall_with_password.bat
```

### Ganti Password
```powershell
# PowerShell
cd C:\ProgramData\Tenjo
.\change_password.ps1
```

```cmd
# Batch
cd C:\ProgramData\Tenjo
change_password.bat
```

---

## ⚠️ Troubleshooting

### Password Lupa
**Solusi 1: Reset via Python (as Administrator)**
```cmd
cd C:\ProgramData\Tenjo
python src\utils\password_protection.py reset <new_password>
```

**Solusi 2: Hapus manual (as Administrator)**
```cmd
del C:\ProgramData\Tenjo\.password_hash
# Password akan kosong, jalankan change_password untuk set password baru
```

### Uninstall Tidak Bisa
**Penyebab:**
- Password salah 3 kali
- File password corrupt

**Solusi:**
```cmd
# Reset password dulu
cd C:\ProgramData\Tenjo
python src\utils\password_protection.py reset admin123

# Coba uninstall lagi
uninstall_with_password.bat
```

---

## 🎯 Use Cases

### 1. Instalasi Mass Deployment dengan Password Custom
```powershell
# Edit install_windows.ps1, ganti default password
$defaultPassword = "YourCompanyPass2024"
```

### 2. Remote Password Change (via SSH/RDP)
```powershell
# Connect ke client PC
ssh user@client-pc

# Ganti password
cd C:\ProgramData\Tenjo
.\change_password.ps1
```

### 3. Uninstall untuk Maintenance
```cmd
# Login as Administrator
cd C:\ProgramData\Tenjo
uninstall_with_password.bat
# Masukkan password saat diminta
```

---

## 📊 Security Improvement

**Before Password Protection:**
- Security Score: 7/10
- User bisa kill process → Watchdog restart
- User bisa uninstall → TIDAK ADA PROTECTION ❌

**After Password Protection:**
- Security Score: 8/10
- User bisa kill process → Watchdog restart
- User TIDAK BISA uninstall tanpa password ✅
- Password requirement: min 6 karakter
- Brute force protection: 3 attempts max

---

## 🚀 Quick Start

### Installation dengan Password Default
```cmd
curl -L -o install.bat https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.bat
install.bat
# Pilih N untuk pakai default password: admin123
```

### Uninstall
```cmd
cd C:\ProgramData\Tenjo
uninstall_with_password.bat
# Masukkan password: admin123
```

### Change Password
```cmd
cd C:\ProgramData\Tenjo
change_password.bat
# Old password: admin123
# New password: NewSecurePass2024
```

---

## 📝 Notes

1. **Password adalah kunci untuk uninstall** - Simpan dengan aman!
2. **Default password: admin123** - Disarankan ganti untuk production
3. **3 attempts max** - Setelah itu harus run script ulang
4. **SHA256 hashing** - Password tidak bisa di-reverse
5. **File protection** - `.password_hash` dengan restricted permissions

---

## 🔗 Related Files

- `/client/src/utils/password_protection.py` - Password module
- `/client/uninstall_with_password.ps1` - Uninstall script (PowerShell)
- `/client/uninstall_with_password.bat` - Uninstall script (Batch)
- `/client/change_password.ps1` - Change password utility (PowerShell)
- `/client/change_password.bat` - Change password utility (Batch)
- `/install_windows.ps1` - Installer with password setup
- `/install_windows.bat` - Installer with password setup

---

## 📞 Support

Jika ada masalah dengan password protection:
1. Cek file `.password_hash` ada di `C:\ProgramData\Tenjo`
2. Coba reset password via Python module
3. Jika masih gagal, hapus file `.password_hash` dan set ulang

**Emergency Uninstall (jika lupa password):**
```cmd
# As Administrator
cd C:\ProgramData\Tenjo

# 1. Stop process
taskkill /F /IM python.exe

# 2. Remove scheduled tasks
schtasks /delete /tn TenjoMonitor /f
schtasks /delete /tn TenjoWatchdog /f

# 3. Remove registry
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v TenjoMonitor /f

# 4. Delete files
rmdir /S /Q "C:\ProgramData\Tenjo"
```

⚠️ **Catatan:** Emergency uninstall hanya bisa dilakukan dengan admin privileges.
