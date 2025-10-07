# Analisis Celah Keamanan Tenjo Client

## ⚠️ CELAH YANG DITEMUKAN

### 1. ❌ Uninstall Mudah
**Severity: HIGH**

**Masalah:**
- File `uninstall_autostart.ps1` tersedia di folder client
- User bisa stop service dengan mudah
- Scheduled task bisa dihapus via Task Scheduler
- Registry entry bisa dihapus via regedit
- Folder `C:\ProgramData\Tenjo` bisa dihapus manual

**Cara Eksploit:**
```powershell
# Method 1: Jalankan uninstall script
PowerShell -File "C:\ProgramData\Tenjo\uninstall_autostart.ps1"

# Method 2: Task Manager
taskkill /F /IM python.exe

# Method 3: Task Scheduler
schtasks /Delete /TN "TenjoMonitor" /F

# Method 4: Registry
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitor" /f

# Method 5: Delete folder
rmdir /S /Q "C:\ProgramData\Tenjo"
```

**Impact:**
- Client berhenti monitoring
- Tidak muncul di dashboard
- User bebas dari monitoring

---

### 2. ❌ Process Visible di Task Manager
**Severity: MEDIUM**

**Masalah:**
- Process `python.exe` terlihat di Task Manager
- Command line argument terlihat (`main.py`)
- User bisa End Task

**Cara Eksploit:**
```
Task Manager → Details → python.exe → End Task
```

**Impact:**
- Monitoring berhenti
- Client offline di dashboard

---

### 3. ❌ Logs Tidak Terenkripsi
**Severity: MEDIUM**

**Masalah:**
- Log files di `C:\ProgramData\Tenjo\logs\` plain text
- Screenshot tersimpan unencrypted
- User bisa baca/hapus logs

**Cara Eksploit:**
```
type C:\ProgramData\Tenjo\logs\stealth.log
del C:\ProgramData\Tenjo\screenshots\*.*
```

**Impact:**
- User tahu sedang dimonitor
- Evidence bisa dihapus

---

### 4. ❌ Tidak Ada Watchdog
**Severity: HIGH**

**Masalah:**
- Tidak ada process yang monitor jika client mati
- Tidak ada auto-restart jika killed
- User kill sekali = mati permanent

**Impact:**
- Client tidak restart otomatis
- Monitoring berhenti total

---

### 5. ❌ Antivirus Bisa Block
**Severity: MEDIUM**

**Masalah:**
- Stealth mode mungkin trigger antivirus
- Screen capture flagged as suspicious
- Bisa di-quarantine

**Impact:**
- Installation gagal
- Client tidak jalan

---

### 6. ❌ Network Detection
**Severity: LOW**

**Masalah:**
- Connection ke server visible di firewall
- Network traffic tidak ter-obfuscate
- Admin bisa block domain `tenjo.adilabs.id`

**Cara Eksploit:**
```
netsh advfirewall firewall add rule name="Block Tenjo" dir=out action=block remoteip=<server_ip>
```

**Impact:**
- Client tidak bisa connect
- Data tidak terupload

---

### 7. ❌ File Permissions Weak
**Severity: LOW**

**Masalah:**
- Folder `C:\ProgramData\Tenjo` accessible
- Config files bisa diubah user
- `server_override.json` bisa di-tamper

**Cara Eksploit:**
```powershell
echo {"server_url": "http://localhost:8000"} > C:\ProgramData\Tenjo\server_override.json
```

**Impact:**
- Data tidak sampai ke server asli
- Monitoring bypass

---

### 8. ❌ Scheduled Task Disabled
**Severity: MEDIUM**

**Masalah:**
- User bisa disable task via Task Scheduler
- Tidak ada protection

**Cara Eksploit:**
```
Task Scheduler → TenjoMonitor → Disable
```

**Impact:**
- Auto-start tidak jalan
- Setelah reboot, client tidak jalan

---

## ✅ SOLUSI & MITIGASI

### Solusi 1: Hapus Uninstall Script ⭐
**Priority: HIGH**

```bash
# Jangan sertakan uninstall script di production
# Hapus dari installer:
rm client/uninstall_autostart.ps1
rm client/uninstall_autostart.sh
```

### Solusi 2: Service Watchdog ⭐⭐⭐
**Priority: CRITICAL**

Buat service kedua yang monitor client:

```python
# watchdog.py - Monitor dan restart client jika mati
import psutil
import subprocess
import time

def check_client_running():
    for proc in psutil.process_iter(['name', 'cmdline']):
        if 'python' in proc.info['name'].lower():
            cmdline = ' '.join(proc.info['cmdline'] or [])
            if 'main.py' in cmdline and 'Tenjo' in cmdline:
                return True
    return False

while True:
    if not check_client_running():
        # Restart client
        subprocess.Popen(['python', 'main.py'], cwd='C:/ProgramData/Tenjo')
        time.sleep(60)
    time.sleep(30)
```

### Solusi 3: Process Name Obfuscation ⭐⭐
**Priority: HIGH**

```python
# Change process name di Task Manager
import setproctitle
setproctitle.setproctitle('System Service Host')
```

### Solusi 4: File Protection ⭐
**Priority: MEDIUM**

```batch
REM Set folder permissions (Admin only)
icacls "C:\ProgramData\Tenjo" /inheritance:r
icacls "C:\ProgramData\Tenjo" /grant:r "SYSTEM:(OI)(CI)F"
icacls "C:\ProgramData\Tenjo" /grant:r "Administrators:(OI)(CI)F"
```

### Solusi 5: Multiple Autostart Methods ⭐⭐
**Priority: HIGH**

Gunakan 3 metode sekaligus:
1. Scheduled Task (at logon)
2. Registry Run key
3. Windows Service (if admin)

Jika 1 dihapus, 2 lainnya masih jalan.

### Solusi 6: Log Encryption ⭐
**Priority: MEDIUM**

```python
# Encrypt logs
from cryptography.fernet import Fernet

key = Fernet.generate_key()
cipher = Fernet(key)
encrypted_log = cipher.encrypt(log_data.encode())
```

### Solusi 7: Network Obfuscation ⭐
**Priority: LOW**

```python
# Use domain fronting atau proxy
# Encrypt traffic dengan custom protocol
```

### Solusi 8: Task Protection ⭐⭐
**Priority: HIGH**

```powershell
# Set task permissions (SYSTEM only)
$task = Get-ScheduledTask -TaskName "TenjoMonitor"
$task.Principal.UserId = "SYSTEM"
$task | Set-ScheduledTask
```

---

## 🎯 SECURITY SCORE

**Before Fixes:**  
⚠️ **4/10** - Multiple critical vulnerabilities

**After Critical Fixes (Watchdog + Password):**  
✅ **8/10** - Major vulnerabilities addressed + Password protection

**Target (with all improvements):**  
🎯 **9/10** - Enterprise-grade security

---

## ⚡ Quick Fixes (Bisa Diterapkan Sekarang)

### ✅ Fix 1: Password Protection for Uninstall ⭐ IMPLEMENTED
```
✓ Password required to uninstall (3 attempts max)
✓ SHA256 password hashing
✓ Default password: admin123 (customizable during install)
✓ Change password utility: change_password.ps1 / change_password.bat
✓ Uninstall script: uninstall_with_password.ps1 / uninstall_with_password.bat
```

### ✅ Fix 2: Watchdog Service ⭐ IMPLEMENTED
```
✓ Auto-restart client if killed
✓ 30-second check interval
✓ Dual scheduled tasks (Main + Watchdog)
```

### Fix 3: Update Installer - Add Process Name Change
```python
# Di main.py, tambah di awal:
try:
    import setproctitle
    setproctitle.setproctitle('Windows Update Service')
except:
    pass
```

### ✅ Fix 4: Multiple Autostart
Installer sudah pakai 3 metode (Registry + 2 Scheduled Tasks). OK.

---

## 🔒 Kesimpulan

**Celah Yang Sudah Diperbaiki:**
1. ✅ Uninstall sekarang butuh password (3 attempts max)
2. ✅ Watchdog service untuk auto-restart
3. ✅ Multiple autostart methods

**Celah Yang Masih Ada:**
1. Process visible di Task Manager ⚠️
2. User dengan admin bisa kill process ⚠️ (tapi akan auto-restart)
3. Logs tidak terenkripsi ⚠️

**Prioritas Fix Berikutnya:**
1. Obfuscate process name (setproctitle)
2. Log encryption (optional)
3. File permissions hardening (optional)

**Catatan:**
Karena ini user-level install (bukan kernel driver), ada batasan:
- User dengan admin rights bisa kill process (tapi watchdog akan restart)
- User tanpa password TIDAK bisa uninstall
- Best effort: make it hard + password protection

Untuk monitoring karyawan, ini sudah sangat baik asalkan:
- ✅ Karyawan tidak tahu password uninstall
- ✅ Password disimpan aman oleh admin
- ✅ Ada policy perusahaan (legal)
- ✅ Kombinasi technical + policy enforcement
- ✅ Watchdog akan restart jika client di-kill

**Security Level:**
- Before: 4/10 (banyak celah)
- After: 8/10 (password protection + watchdog + multiple autostart)
- Target: 9/10 (tambah process obfuscation + log encryption)
