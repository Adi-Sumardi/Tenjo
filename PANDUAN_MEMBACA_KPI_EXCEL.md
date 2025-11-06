# 📊 PANDUAN LENGKAP: Cara Membaca Export KPI Excel

## 🎯 Untuk Client/Manager

Panduan ini akan membantu Anda memahami laporan KPI karyawan dalam format Excel yang di-export dari sistem Tenjo.

---

## 📥 Cara Export Excel

### 1. Login ke Dashboard
```
URL: https://tenjo.adilabs.id/dashboard
```

### 2. Masuk ke Menu "Client Summary"
- Klik menu **"Client Summary"** di sidebar kiri
- Atau akses langsung: `https://tenjo.adilabs.id/dashboard/client-summary`

### 3. Pilih Periode Waktu
Anda bisa memilih salah satu dari:
- **Today** - Aktivitas hari ini
- **Yesterday** - Aktivitas kemarin
- **This Week** - Aktivitas minggu ini (Senin-Minggu)
- **This Month** - Aktivitas bulan ini
- **Custom Range** - Pilih tanggal sendiri (contoh: 1 Okt - 31 Okt 2025)

### 4. Klik Tombol "Export Excel"
- File akan otomatis ter-download
- Nama file: `Employee_KPI_Report_YYYY-MM-DD.xlsx`
- Contoh: `Employee_KPI_Report_2025-10-30.xlsx`

### 5. Buka File Excel
- Buka dengan **Microsoft Excel** atau **Google Sheets**
- File terdiri dari **4 sheet** (tab di bawah)

---

## 📋 Struktur File Excel (4 Sheets)

File Excel yang di-export memiliki **4 sheet utama**:

```
┌─────────────────────────────────────────┐
│ Sheet 1: Summary                        │  ← Overview semua karyawan
│ Sheet 2: KPI Dashboard                  │  ← Ranking & skor performa
│ Sheet 3-N: Individual Employees         │  ← Detail per karyawan (1 sheet per orang)
│ Last Sheet: Analytics                   │  ← Insights & rekomendasi
└─────────────────────────────────────────┘
```

---

## 📊 SHEET 1: SUMMARY (Ringkasan Semua Karyawan)

### Apa yang ada di Sheet ini?

#### A. Header Laporan
```
┌──────────────────────────────────────────┐
│ EMPLOYEE ACTIVITY SUMMARY REPORT         │
│ Period: 2025-10-01 to 2025-10-30        │
│ Generated On: 2025-10-30 22:15:00       │
└──────────────────────────────────────────┘
```

**Cara Membaca:**
- **Period**: Periode waktu yang Anda pilih saat export
- **Generated On**: Tanggal dan jam laporan dibuat

---

#### B. Overall Statistics (Statistik Keseluruhan)

```
┌──────────────────────────────────────────┐
│ Total Employees: 15                      │
│ Currently Online: 8                      │
│ Total Screenshots: 1,234                 │
│ Total Browser Sessions: 456              │
│ Total URL Activities: 5,678              │
│ Total Active Hours: 120.5 hours          │
│ Average Hours per Employee: 8.0 hours    │
└──────────────────────────────────────────┘
```

**Penjelasan Kolom:**

| Kolom | Arti | Cara Membaca |
|-------|------|--------------|
| **Total Employees** | Jumlah total karyawan yang dipantau | Semakin banyak = semakin besar tim |
| **Currently Online** | Jumlah karyawan yang aktif saat ini | Menunjukkan berapa orang yang sedang bekerja |
| **Total Screenshots** | Total tangkapan layar yang diambil | Semakin banyak = semakin aktif karyawan |
| **Total Browser Sessions** | Total sesi browser yang dibuka | Chrome/Firefox/Safari yang digunakan |
| **Total URL Activities** | Total aktivitas website yang dikunjungi | Berapa kali karyawan membuka/menggunakan website |
| **Total Active Hours** | Total jam kerja semua karyawan (gabungan) | Contoh: 15 orang x 8 jam = 120 jam |
| **Average Hours per Employee** | Rata-rata jam kerja per karyawan | **Ini angka penting!** Target: 8 jam/hari |

**🎯 Cara Evaluasi:**
- ✅ **Average Hours ≥ 8 jam** = Tim bekerja dengan baik
- ⚠️ **Average Hours 6-8 jam** = Cukup baik, bisa ditingkatkan
- ❌ **Average Hours < 6 jam** = Perlu perhatian, produktivitas rendah

---

#### C. Tabel Detail Karyawan

Tabel ini menampilkan ringkasan aktivitas **setiap karyawan**:

| Kolom | Arti | Cara Membaca |
|-------|------|--------------|
| **Employee Name** | Nama karyawan | Identitas karyawan |
| **Hostname** | Nama komputer | Contoh: LAPTOP-ABC123, DESKTOP-JOHN |
| **OS** | Sistem operasi | Windows 10, macOS, Linux |
| **Status** | Status saat ini | Online (hijau) / Offline (merah) |
| **Screenshots** | Jumlah screenshot | Semakin banyak = semakin sering dipantau |
| **Browser Sessions** | Jumlah sesi browser | Berapa kali buka Chrome/Firefox/Safari |
| **URL Activities** | Aktivitas website | Berapa banyak website yang dikunjungi |
| **Unique URLs** | Website unik | Berapa banyak website berbeda yang dibuka |
| **Active Time** | Total waktu aktif | **PENTING!** Contoh: "8h 23m" = 8 jam 23 menit |
| **Top Domains** | Website paling sering dikunjungi | Contoh: "github.com, google.com, chatgpt.com" |
| **Last Activity** | Aktivitas terakhir | Kapan terakhir kali aktif |

**🎯 Cara Membaca Active Time:**
- `8h 23m` = 8 jam 23 menit (EXCELLENT!)
- `6h 45m` = 6 jam 45 menit (GOOD)
- `4h 12m` = 4 jam 12 menit (AVERAGE - perlu ditingkatkan)
- `2h 30m` = 2 jam 30 menit (BELOW AVERAGE - perlu perhatian!)

**🔍 Contoh Interpretasi:**

```
┌────────────────────────────────────────────────────────────────────┐
│ John Doe  │ DESKTOP-JOHN │ Online │ 123 │ 45 │ 567 │ 8h 23m │ ...  │
│ Jane Doe  │ LAPTOP-JANE  │ Online │ 98  │ 32 │ 421 │ 6h 45m │ ...  │
│ Bob Smith │ DESKTOP-BOB  │ Offline│ 45  │ 15 │ 156 │ 3h 12m │ ...  │
└────────────────────────────────────────────────────────────────────┘
```

**Analisis:**
- **John Doe**: EXCELLENT! 8h 23m active time, 567 URL activities → Sangat produktif
- **Jane Doe**: GOOD! 6h 45m active time, 421 activities → Produktif
- **Bob Smith**: BELOW AVERAGE! 3h 12m only → Perlu follow-up, mungkin ada kendala

---

## 🏆 SHEET 2: KPI DASHBOARD (Ranking Performa)

### Apa itu KPI Dashboard?

Sheet ini adalah **INTI DARI LAPORAN**. Berisi ranking dan skor performa setiap karyawan.

### Struktur KPI Dashboard

```
┌─────────────────────────────────────────────────────────────────────┐
│ Rank │ Employee    │ Active  │ Prod  │ Eng   │ Act   │ Performance  │
│      │             │ Hours   │ Score │ Score │ Rate  │ Rating       │
├─────────────────────────────────────────────────────────────────────┤
│  1   │ John Doe    │ 8.5     │ 95.5  │ 88.2  │ 15.3  │ Excellent    │
│  2   │ Jane Smith  │ 7.8     │ 87.2  │ 82.1  │ 12.8  │ Good         │
│  3   │ Bob K.      │ 7.2     │ 76.8  │ 71.5  │ 10.2  │ Good         │
│  4   │ Alice W.    │ 6.5     │ 68.4  │ 65.3  │  9.1  │ Average      │
│  5   │ Mike T.     │ 5.2     │ 55.1  │ 52.8  │  7.3  │ Below Avg    │
│ ...  │             │         │       │       │       │              │
│ 15   │ Tom B.      │ 3.1     │ 42.1  │ 39.5  │  4.8  │ Poor         │
└─────────────────────────────────────────────────────────────────────┘

SUMMARY STATISTICS:
- Average Active Hours: 6.8
- Total Activities: 5,678
- Most Productive: John Doe (95.5)
- Least Productive: Tom B. (42.1)
```

---

### Cara Membaca Setiap Kolom

#### 1. **Rank (Peringkat)**
- Peringkat dari yang **TERBAIK** (1) ke **TERBURUK**
- Diurutkan berdasarkan **Productivity Score**
- Baris pertama = karyawan terbaik (**highlight hijau**)
- Baris terakhir = karyawan terburuk (**highlight merah**)

**💡 Cara Pakai:**
- Gunakan untuk **bonus/reward** → beri bonus ke top 3
- Gunakan untuk **coaching** → beri training ke bottom 3

---

#### 2. **Active Hours (Jam Kerja Aktif)**
**Format:** Angka desimal (contoh: 8.5 = 8 jam 30 menit)

**Cara Membaca:**
- `8.0 - 10.0` jam = **EXCELLENT** ✅
- `6.0 - 7.9` jam = **GOOD** ✅
- `4.0 - 5.9` jam = **AVERAGE** ⚠️
- `< 4.0` jam = **POOR** ❌

**⚠️ PERHATIAN:**
- Ini adalah **WAKTU AKTIF PRODUKTIF**, bukan total jam di kantor
- Waktu aktif = waktu dimana karyawan benar-benar bekerja (buka aplikasi, klik mouse, ketik, dll)
- Jika jam kerja 8 jam tapi active time hanya 4 jam = **50% waktu tidak produktif**

**🎯 Target yang Sehat:**
- Untuk jam kerja 8 jam → Target active time: **6-8 jam** (75-100%)
- Untuk jam kerja 6 jam → Target active time: **4.5-6 jam** (75-100%)

---

#### 3. **Productivity Score (Skor Produktivitas) - PENTING!**
**Format:** Angka 0-100

**Cara Membaca:**
- `90-100` = **Excellent** 🌟🌟🌟🌟🌟
- `75-89` = **Good** 🌟🌟🌟🌟
- `60-74` = **Average** 🌟🌟🌟
- `40-59` = **Below Average** 🌟🌟
- `0-39` = **Poor** 🌟

**📐 Cara Perhitungan Productivity Score:**

```
Productivity Score dihitung berdasarkan 4 faktor:

1. Active Time (40%)
   - Berapa lama waktu aktif bekerja
   - Target: 8 jam = 100%, 4 jam = 50%

2. URL Activities (30%)
   - Berapa banyak website/aplikasi yang digunakan untuk kerja
   - Semakin banyak aktivitas = semakin produktif

3. Browser Sessions (20%)
   - Berapa kali buka browser untuk kerja
   - Menunjukkan intensitas penggunaan tools

4. URL Diversity (10%)
   - Berapa banyak website berbeda yang dikunjungi
   - Menunjukkan variasi pekerjaan

Formula:
Productivity Score = (Time × 40%) + (Activity × 30%) + (Session × 20%) + (Diversity × 10%)
```

**🎯 Cara Evaluasi:**

| Score | Rating | Aksi yang Perlu Dilakukan |
|-------|--------|---------------------------|
| **90-100** | Excellent | ✅ Beri **bonus/reward**<br>✅ Jadikan contoh untuk tim<br>✅ Pertahankan performa |
| **75-89** | Good | ✅ Beri **apresiasi**<br>✅ Tingkatkan ke Excellent dengan coaching<br>✅ Identifikasi area improvement |
| **60-74** | Average | ⚠️ **Monitor lebih ketat**<br>⚠️ Berikan target spesifik<br>⚠️ 1-on-1 meeting untuk evaluasi |
| **40-59** | Below Average | ❌ **Perlu action segera!**<br>❌ Meeting dengan supervisor<br>❌ Buat Performance Improvement Plan (PIP) |
| **0-39** | Poor | ❌❌ **CRITICAL!**<br>❌ Investigasi penyebab (sakit? masalah personal?)<br>❌ Pertimbangkan konsekuensi (warning/SP) |

---

#### 4. **Engagement Score (Skor Keterlibatan)**
**Format:** Angka 0-100

**Cara Membaca:**
- `80-100` = Sangat engaged (aktif bekerja)
- `60-79` = Engaged (cukup aktif)
- `40-59` = Kurang engaged (butuh motivasi)
- `0-39` = Tidak engaged (ada masalah)

**📐 Cara Perhitungan Engagement Score:**

```
Engagement Score dihitung berdasarkan 3 faktor:

1. URL Activities (50%)
   - Berapa banyak aktivitas online untuk kerja
   - Semakin banyak = semakin engaged

2. Screenshots (30%)
   - Berapa banyak screenshot yang diambil
   - Menunjukkan konsistensi kerja

3. Browser Sessions (20%)
   - Berapa kali buka browser
   - Menunjukkan intensitas kerja

Formula:
Engagement Score = (Activities × 50%) + (Screenshots × 30%) + (Sessions × 20%)
```

**💡 Perbedaan Productivity vs Engagement:**
- **Productivity Score** = Seberapa **PRODUKTIF** (hasil kerja, waktu aktif, output)
- **Engagement Score** = Seberapa **TERLIBAT** (aktif, konsisten, intensitas)

Contoh:
- Productivity 90, Engagement 60 = **Pintar tapi kurang motivasi**
- Productivity 60, Engagement 90 = **Rajin tapi kurang efektif**
- Productivity 90, Engagement 90 = **PERFECT! Pintar DAN rajin** ⭐

---

#### 5. **Activity Rate (Aktivitas per Jam)**
**Format:** Angka (contoh: 15.3 = 15.3 aktivitas per jam)

**Cara Membaca:**
- `> 15` activities/hour = **Sangat aktif** (buka website, klik, ketik, scroll)
- `10-15` activities/hour = **Aktif**
- `5-10` activities/hour = **Cukup aktif**
- `< 5` activities/hour = **Kurang aktif**

**📊 Cara Hitung:**
```
Activity Rate = Total URL Activities ÷ Active Hours

Contoh:
- 120 activities dalam 8 jam = 15 activities/hour (GOOD!)
- 40 activities dalam 8 jam = 5 activities/hour (TOO LOW!)
```

**💡 Interpretasi:**
- Activity Rate tinggi + Productivity tinggi = **Karyawan produktif** ✅
- Activity Rate tinggi + Productivity rendah = **Sibuk tapi tidak produktif** (buka terlalu banyak website tidak penting)
- Activity Rate rendah + Productivity rendah = **Tidak produktif** ❌

---

#### 6. **Performance Rating (Rating Performa)**

Kategori performa berdasarkan **Productivity Score**:

```
┌────────────────────────────────────────┐
│ Rating          │ Score Range          │
├────────────────────────────────────────┤
│ Excellent       │ 90-100               │ 🌟🌟🌟🌟🌟
│ Good            │ 75-89                │ 🌟🌟🌟🌟
│ Average         │ 60-74                │ 🌟🌟🌟
│ Below Average   │ 40-59                │ 🌟🌟
│ Poor            │ 0-39                 │ 🌟
└────────────────────────────────────────┘
```

**🎯 Cara Pakai untuk Evaluasi:**

| Rating | % Tim yang Ideal | Aksi |
|--------|------------------|------|
| **Excellent** | 20% | Top performers, beri reward |
| **Good** | 30% | Solid performers, maintain |
| **Average** | 30% | Need coaching, bisa naik |
| **Below Average** | 15% | Need attention, PIP |
| **Poor** | 5% | Critical, investigate |

**Contoh Interpretasi:**

Jika tim Anda punya:
- 5 orang Excellent (33%) ✅ **BAGUS!** Tim sangat produktif
- 5 orang Good (33%) ✅ **BAGUS!**
- 3 orang Average (20%) ✅ **WAJAR**
- 2 orang Below Average (13%) ⚠️ **Perlu coaching**
- 0 orang Poor (0%) ✅ **EXCELLENT!**

**Total: 15 orang → 66% tim adalah Good atau Excellent = TIM SEHAT!**

---

### 📈 Summary Statistics (Statistik Ringkasan)

Di bagian bawah KPI Dashboard ada ringkasan:

```
┌──────────────────────────────────────────┐
│ SUMMARY STATISTICS                       │
├──────────────────────────────────────────┤
│ Average Active Hours: 6.8                │
│ Total Activities: 5,678                  │
│ Most Productive Employee: John Doe       │
│ Least Productive Employee: Tom B.        │
└──────────────────────────────────────────┘
```

**Cara Membaca:**

1. **Average Active Hours**
   - Rata-rata jam kerja aktif seluruh tim
   - **Target: ≥ 6.5 jam** (untuk jam kerja 8 jam)
   - Jika < 5 jam = ada masalah sistemik di tim

2. **Total Activities**
   - Total semua aktivitas website dari seluruh tim
   - Semakin tinggi = semakin aktif tim bekerja

3. **Most Productive Employee**
   - Karyawan dengan skor tertinggi
   - **Jadikan role model** untuk tim

4. **Least Productive Employee**
   - Karyawan dengan skor terendah
   - **Perlu perhatian khusus** (coaching/PIP)

---

## 👤 SHEET 3-N: INDIVIDUAL EMPLOYEE SHEETS

### Apa itu Individual Employee Sheets?

Setiap karyawan punya **sheet sendiri** dengan detail lengkap aktivitasnya.

**Contoh:** Jika ada 15 karyawan, maka ada 15 sheet individual (Sheet 3 sampai Sheet 17).

---

### Struktur Individual Sheet

```
┌──────────────────────────────────────────┐
│ EMPLOYEE: John Doe                       │
├──────────────────────────────────────────┤
│ [A] Employee Info                        │
│ [B] Summary Statistics                   │
│ [C] Browser Usage Breakdown              │
│ [D] Top 20 Most Visited URLs             │
│ [E] Daily Activity Breakdown             │
│ [F] Top Domains Visited                  │
└──────────────────────────────────────────┘
```

---

### [A] Employee Info (Informasi Karyawan)

```
Employee: John Doe
Hostname: DESKTOP-JOHN
OS: Windows 10
Status: Online
Last Seen: 2025-10-30 14:32:00
```

**Cara Membaca:**
- **Hostname**: Nama komputer yang dipakai (untuk identifikasi device)
- **OS**: Sistem operasi (Windows 10, macOS Sonoma, Ubuntu Linux)
- **Status**: Online (aktif sekarang) atau Offline (tidak aktif)
- **Last Seen**: Kapan terakhir kali karyawan aktif

---

### [B] Summary Statistics (Statistik Ringkasan)

```
┌──────────────────────────────────────────┐
│ Total Screenshots: 123                   │
│ Total Browser Sessions: 45               │
│ Total URL Activities: 567                │
│ Unique URLs: 89                          │
│ Total Active Time: 8.5 hours             │
│ Average Session Duration: 11.3 minutes   │
└──────────────────────────────────────────┘
```

**Cara Membaca:**

| Metrik | Arti | Target yang Baik |
|--------|------|------------------|
| **Total Screenshots** | Berapa kali screenshot diambil | > 100 per hari |
| **Total Browser Sessions** | Berapa kali buka Chrome/Firefox/Safari | 20-50 per hari |
| **Total URL Activities** | Berapa kali buka/gunakan website | > 200 per hari |
| **Unique URLs** | Berapa website berbeda yang dikunjungi | 30-100 (tergantung pekerjaan) |
| **Total Active Time** | Total waktu aktif produktif | ≥ 6 jam per hari |
| **Average Session Duration** | Rata-rata durasi per sesi browser | 10-20 menit |

**🎯 Interpretasi:**
- Screenshot banyak = karyawan konsisten bekerja
- URL Activities tinggi + Active Time tinggi = **Produktif** ✅
- Unique URLs terlalu tinggi (> 200) = mungkin terlalu banyak distraksi
- Average Session terlalu pendek (< 5 menit) = mungkin sering ganti-ganti task

---

### [C] Browser Usage Breakdown (Penggunaan Browser)

```
┌──────────────────────────────────────────┐
│ Browser    │ Sessions │ Total Time       │
├──────────────────────────────────────────┤
│ Chrome     │ 30       │ 5h 23m           │
│ Firefox    │ 10       │ 2h 15m           │
│ Edge       │ 5        │ 0h 52m           │
└──────────────────────────────────────────┘
```

**Cara Membaca:**
- Menunjukkan browser apa saja yang dipakai karyawan
- Berapa lama waktu di tiap browser

**💡 Use Case:**
- Chrome dominan = karyawan pakai tools berbasis web (Gmail, Google Docs, dll)
- Firefox + Chrome = karyawan testing di multiple browser (developer/QA)
- Edge banyak = karyawan pakai tools Microsoft

---

### [D] Top 20 Most Visited URLs (20 Website Paling Sering Dikunjungi)

Tabel ini menunjukkan website yang **PALING SERING** dikunjungi karyawan.

```
┌────────────────────────────────────────────────────────────────────┐
│ Rank │ URL                              │ Domain        │ Visits │ Duration │
├────────────────────────────────────────────────────────────────────┤
│  1   │ https://github.com/project-x     │ github.com    │  45    │ 2h 15m   │
│  2   │ https://chatgpt.com              │ chatgpt.com   │  38    │ 1h 52m   │
│  3   │ https://mail.google.com          │ gmail.com     │  32    │ 1h 23m   │
│  4   │ https://docs.google.com/...      │ docs.google   │  28    │ 1h 05m   │
│  5   │ https://stackoverflow.com/...    │ stackoverflow │  22    │ 0h 45m   │
│ ...  │                                  │               │        │          │
│ 20   │ https://youtube.com/...          │ youtube.com   │  5     │ 0h 12m   │
└────────────────────────────────────────────────────────────────────┘
```

**Cara Membaca:**

1. **Rank**: Urutan berdasarkan berapa kali dikunjungi (visits)
2. **URL**: Alamat website lengkap
3. **Domain**: Nama website (lebih mudah dibaca)
4. **Visits**: Berapa kali karyawan buka/kunjungi website ini
5. **Duration**: Total waktu yang dihabiskan di website ini

**🎯 Cara Analisis:**

**GOOD SIGNS (Karyawan Produktif):**
✅ Top 5 adalah website kerja (GitHub, Google Docs, Jira, Slack, dll)
✅ Duration seimbang (tidak ada 1 website yang terlalu dominan)
✅ Visits tinggi di tools produktivitas

**BAD SIGNS (Karyawan Tidak Produktif):**
❌ Top 5 adalah website hiburan (YouTube, Facebook, TikTok, Netflix, dll)
❌ Duration terlalu lama di 1 website (contoh: 5 jam di YouTube)
❌ Visits rendah di tools kerja

**Contoh Interpretasi:**

**Karyawan A (Developer):**
```
1. github.com (45 visits, 2h 15m) ✅ GOOD - coding
2. stackoverflow.com (38 visits, 1h 52m) ✅ GOOD - problem solving
3. chatgpt.com (32 visits, 1h 23m) ✅ GOOD - AI assistance
4. localhost:3000 (28 visits, 1h 05m) ✅ GOOD - testing
5. docs.google.com (22 visits, 0h 45m) ✅ GOOD - documentation
```
**Analisis: EXCELLENT! Semua aktivitas produktif untuk developer.**

**Karyawan B (Marketing):**
```
1. facebook.com/business (40 visits, 2h 30m) ✅ GOOD - social media management
2. canva.com (35 visits, 1h 45m) ✅ GOOD - design
3. mail.google.com (30 visits, 1h 20m) ✅ GOOD - email
4. analytics.google.com (25 visits, 1h 10m) ✅ GOOD - analytics
5. hootsuite.com (20 visits, 0h 55m) ✅ GOOD - scheduling
```
**Analisis: EXCELLENT! Semua aktivitas sesuai job desc marketing.**

**Karyawan C (Problem Case):**
```
1. youtube.com (120 visits, 5h 30m) ❌ BAD - terlalu lama nonton video
2. facebook.com (85 visits, 3h 45m) ❌ BAD - social media pribadi
3. tiktok.com (60 visits, 2h 20m) ❌ BAD - entertainment
4. mail.google.com (15 visits, 0h 30m) ⚠️ OK - email tapi terlalu sedikit
5. netflix.com (12 visits, 1h 15m) ❌ BAD - streaming
```
**Analisis: POOR! Sebagian besar waktu untuk hiburan, bukan kerja. Perlu warning!**

---

### [E] Daily Activity Breakdown (Aktivitas Harian)

Tabel ini menunjukkan aktivitas **per hari** dalam periode yang dipilih.

```
┌────────────────────────────────────────────────────────────────┐
│ Date       │ Activities │ Unique URLs │ Active Time │ Status  │
├────────────────────────────────────────────────────────────────┤
│ 2025-10-01 │ 124        │ 32          │ 8h 15m      │ ✅ Good │
│ 2025-10-02 │ 118        │ 28          │ 7h 45m      │ ✅ Good │
│ 2025-10-03 │ 95         │ 25          │ 6h 30m      │ ⚠️ OK  │
│ 2025-10-04 │ 42         │ 12          │ 3h 10m      │ ❌ Low  │
│ 2025-10-05 │ 0          │ 0           │ 0h 00m      │ 🔴 Off  │
│ 2025-10-06 │ 0          │ 0           │ 0h 00m      │ 🔴 Off  │
│ 2025-10-07 │ 0          │ 0           │ 0h 00m      │ 🔴 Off  │
│ 2025-10-08 │ 132        │ 35          │ 8h 42m      │ ✅ Good │
└────────────────────────────────────────────────────────────────┘
```

**Cara Membaca:**

1. **Date**: Tanggal
2. **Activities**: Jumlah aktivitas website pada hari itu
3. **Unique URLs**: Berapa website berbeda yang dikunjungi
4. **Active Time**: Total waktu aktif pada hari itu
5. **Status**: Evaluasi otomatis (Good/OK/Low/Off)

**🎯 Cara Analisis Pola:**

**Pola Normal (Karyawan Baik):**
```
Senin    - 8h 15m ✅
Selasa   - 7h 45m ✅
Rabu     - 6h 30m ✅
Kamis    - 7h 20m ✅
Jumat    - 6h 00m ✅
Sabtu    - 0h 00m (OFF - weekend)
Minggu   - 0h 00m (OFF - weekend)
```
**Analisis: Konsisten kerja di weekday, libur di weekend = SEHAT**

**Pola Tidak Normal (Perlu Perhatian):**
```
Senin    - 8h 15m ✅
Selasa   - 2h 10m ❌ (kenapa drop drastis?)
Rabu     - 3h 30m ❌
Kamis    - 1h 45m ❌ (ada masalah?)
Jumat    - 0h 00m ❌ (tidak masuk?)
```
**Analisis: Performa drop dari Selasa → Perlu investigasi (sakit? masalah pribadi?)**

**Pola Overwork (Perlu Perhatian):**
```
Senin    - 10h 30m ⚠️
Selasa   - 11h 15m ⚠️
Rabu     - 9h 45m ⚠️
Kamis    - 10h 20m ⚠️
Jumat    - 9h 50m ⚠️
Sabtu    - 6h 30m ⚠️ (kerja di weekend)
Minggu   - 5h 15m ⚠️ (kerja di weekend)
```
**Analisis: Karyawan overwork (> 10 jam per hari + weekend). Resiko burnout!**

---

### [F] Top Domains Visited (Domain Paling Sering Dikunjungi)

Ringkasan website berdasarkan **domain** (tanpa URL detail).

```
┌────────────────────────────────────────────────────────────────┐
│ Domain           │ Total Visits │ Unique URLs │ Total Time    │
├────────────────────────────────────────────────────────────────┤
│ github.com       │ 245          │ 45          │ 12h 35m       │
│ chatgpt.com      │ 189          │ 12          │ 8h 22m        │
│ google.com       │ 156          │ 78          │ 6h 15m        │
│ stackoverflow.com│ 98           │ 52          │ 4h 42m        │
│ docs.google.com  │ 87           │ 23          │ 4h 18m        │
└────────────────────────────────────────────────────────────────┘
```

**Cara Membaca:**

1. **Domain**: Nama website (tanpa https:// dan path)
2. **Total Visits**: Total kunjungan ke semua halaman di domain ini
3. **Unique URLs**: Berapa halaman berbeda di domain ini yang dikunjungi
4. **Total Time**: Total waktu di domain ini

**🎯 Cara Evaluasi:**

| Domain | Interpretasi |
|--------|--------------|
| github.com, gitlab.com | Developer - coding |
| chatgpt.com, claude.ai | Using AI tools - modern |
| stackoverflow.com | Developer - problem solving |
| mail.google.com | Email - komunikasi |
| docs.google.com, drive.google.com | Dokumentasi - kolaborasi |
| figma.com, canva.com | Designer - design |
| facebook.com, instagram.com | Marketing atau distraksi? Cek job desc |
| youtube.com, netflix.com | ❌ Hiburan - perlu dikurangi |
| linkedin.com | Recruiting atau job hunting? 🤔 |

---

## 📊 SHEET LAST: ANALYTICS (Insights & Rekomendasi)

### Apa itu Analytics Sheet?

Sheet terakhir berisi **analisis keseluruhan tim** dan **rekomendasi** untuk manager.

---

### Struktur Analytics Sheet

```
┌──────────────────────────────────────────┐
│ [A] Productivity Comparison              │
│ [B] Activity Intensity Analysis          │
│ [C] Work Time Distribution               │
│ [D] Performance Categories               │
│ [E] Recommendations & Insights           │
└──────────────────────────────────────────┘
```

---

### [A] Productivity Comparison (Perbandingan Produktivitas)

Grafik data perbandingan produktivitas antar karyawan.

```
┌────────────────────────────────────────────────────────┐
│ Employee        │ Active Hours │ % of Target (8h)     │
├────────────────────────────────────────────────────────┤
│ John Doe        │ 8.5          │ 106% ████████████    │
│ Jane Smith      │ 7.8          │  97% ██████████      │
│ Bob K.          │ 7.2          │  90% █████████       │
│ Alice W.        │ 6.5          │  81% ████████        │
│ Mike T.         │ 5.2          │  65% ██████          │
│ Tom B.          │ 3.1          │  39% ███             │
└────────────────────────────────────────────────────────┘
```

**Cara Membaca:**
- Bar chart menunjukkan % pencapaian terhadap target 8 jam
- > 100% = Exceed target (sangat bagus)
- 75-100% = Meet target (bagus)
- < 75% = Below target (perlu improvement)

---

### [B] Activity Intensity Analysis (Analisis Intensitas Aktivitas)

```
┌────────────────────────────────────────────────────────┐
│ Employee     │ Act/Hour │ Screenshots/Hour │ Intensity │
├────────────────────────────────────────────────────────┤
│ John Doe     │ 15.3     │ 12.5             │ High 🔥   │
│ Jane Smith   │ 12.8     │ 10.2             │ High 🔥   │
│ Bob K.       │ 10.2     │ 8.5              │ Medium ⚡ │
│ Alice W.     │ 9.1      │ 7.2              │ Medium ⚡ │
│ Mike T.      │ 7.3      │ 5.8              │ Low 💤    │
│ Tom B.       │ 4.8      │ 3.2              │ Very Low 😴│
└────────────────────────────────────────────────────────┘
```

**Cara Membaca:**

| Intensity | Activities/Hour | Arti |
|-----------|-----------------|------|
| **High 🔥** | > 12 | Sangat aktif bekerja |
| **Medium ⚡** | 8-12 | Cukup aktif |
| **Low 💤** | 4-8 | Kurang aktif |
| **Very Low 😴** | < 4 | Hampir tidak aktif |

**💡 Use Case:**
- High intensity + High productivity = **Star performer** ⭐
- High intensity + Low productivity = **Busy but not productive** (banyak aktivitas tapi tidak efektif)
- Low intensity + High productivity = **Efficient worker** (sedikit aktivitas tapi efektif)
- Low intensity + Low productivity = **Need attention** ❌

---

### [C] Work Time Distribution (Distribusi Waktu Kerja)

```
┌──────────────────────────────────────────────────────────┐
│ Employee     │ Active │ Idle  │ Completion  │ Grade     │
├──────────────────────────────────────────────────────────┤
│ John Doe     │ 85%    │ 15%   │ 106% ✅     │ A+        │
│ Jane Smith   │ 78%    │ 22%   │ 97% ✅      │ A         │
│ Bob K.       │ 72%    │ 28%   │ 90% ✅      │ B+        │
│ Alice W.     │ 65%    │ 35%   │ 81% ⚠️      │ B         │
│ Mike T.      │ 52%    │ 48%   │ 65% ⚠️      │ C         │
│ Tom B.       │ 31%    │ 69%   │ 39% ❌      │ D         │
└──────────────────────────────────────────────────────────┘
```

**Cara Membaca:**

1. **Active %**: Persentase waktu benar-benar aktif bekerja
2. **Idle %**: Persentase waktu tidak aktif (idle/break)
3. **Completion %**: Pencapaian terhadap target 8 jam kerja
4. **Grade**: Nilai keseluruhan (A+ sampai D)

**🎯 Interpretasi:**

| Active % | Arti | Evaluasi |
|----------|------|----------|
| **> 80%** | Sangat fokus | ✅ Excellent! Hampir tidak ada waktu terbuang |
| **70-80%** | Fokus | ✅ Good! Normal range |
| **60-70%** | Cukup fokus | ⚠️ Average, bisa ditingkatkan |
| **50-60%** | Kurang fokus | ⚠️ Below average, perlu coaching |
| **< 50%** | Tidak fokus | ❌ Poor! Lebih banyak idle daripada kerja |

**⚠️ CATATAN PENTING:**
- Idle 15-20% adalah **NORMAL** (break, toilet, makan siang)
- Idle > 30% adalah **WARNING** (terlalu banyak waktu terbuang)
- Idle > 50% adalah **CRITICAL** (lebih banyak tidak kerja daripada kerja)

---

### [D] Performance Categories (Kategori Performa)

Distribusi karyawan berdasarkan kategori performa.

```
┌──────────────────────────────────────────────────────────┐
│ PERFORMANCE DISTRIBUTION                                 │
├──────────────────────────────────────────────────────────┤
│ High Performers (>6h):      8 employees (53%) ✅         │
│ Average Performers (4-6h):  5 employees (33%) ⚠️         │
│ Low Performers (<4h):       2 employees (13%) ❌         │
│                                                          │
│ Total Employees: 15                                      │
└──────────────────────────────────────────────────────────┘

Breakdown:
┌────────────────────────────────────────┐
│ Category          │ Count │ % of Team  │
├────────────────────────────────────────┤
│ Excellent (90-100)│   3   │ 20%        │
│ Good (75-89)      │   5   │ 33%        │
│ Average (60-74)   │   4   │ 27%        │
│ Below Avg (40-59) │   2   │ 13%        │
│ Poor (0-39)       │   1   │  7%        │
└────────────────────────────────────────┘
```

**Cara Membaca:**

**HEALTHY TEAM DISTRIBUTION:**
```
Excellent:       20%  ✅
Good:            30%  ✅
Average:         30%  ✅
Below Average:   15%  ✅
Poor:             5%  ✅
```

**UNHEALTHY TEAM DISTRIBUTION:**
```
Excellent:        5%  ❌ (terlalu sedikit star performer)
Good:            10%  ❌
Average:         20%  ⚠️
Below Average:   30%  ❌ (terlalu banyak underperformer)
Poor:            35%  ❌ (CRITICAL! Mayoritas tim tidak produktif)
```

**🎯 Action Plan berdasarkan Distribusi:**

| Jika... | Maka... |
|---------|---------|
| > 50% adalah High Performers | ✅ Tim sehat! Pertahankan |
| 30-50% adalah High Performers | ✅ Tim baik, bisa ditingkatkan |
| < 30% adalah High Performers | ❌ Tim bermasalah, perlu restructuring |
| > 30% adalah Low Performers | ❌ CRITICAL! Perlu intervention |

---

### [E] Recommendations & Insights (Rekomendasi & Insight)

Bagian paling penting untuk **ACTION PLAN**!

```
┌──────────────────────────────────────────────────────────────┐
│ INSIGHTS & RECOMMENDATIONS                                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ ✅ STRENGTHS (Kekuatan Tim)                                  │
│ ─────────────────────────────────────────────────────────── │
│ • Top performer: John Doe (Productivity: 95.5)               │
│   → Consider promoting or giving bonus                       │
│                                                              │
│ • Team average: 6.8 hours (85% of target) - HEALTHY         │
│   → Team productivity is above average                       │
│                                                              │
│ • 53% are high performers (>6h) - EXCELLENT                  │
│   → Majority of team is productive                           │
│                                                              │
│ ⚠️ AREAS FOR IMPROVEMENT (Yang Perlu Diperbaiki)            │
│ ─────────────────────────────────────────────────────────── │
│ • Bottom performer: Tom B. (Productivity: 42.1)              │
│   → ACTION: Schedule 1-on-1 meeting                          │
│   → Investigate: Health issues? Personal problems? Training? │
│   → Consider: Performance Improvement Plan (PIP)             │
│                                                              │
│ • 2 employees (13%) are low performers (<4h)                 │
│   → ACTION: Weekly check-ins for these employees             │
│   → Provide coaching and set clear targets                   │
│                                                              │
│ • Average session duration: 11.3 minutes                     │
│   → May indicate frequent task switching                     │
│   → Consider: Time management training                       │
│                                                              │
│ 💡 ACTIONABLE RECOMMENDATIONS                                │
│ ─────────────────────────────────────────────────────────── │
│ 1. REWARD TOP PERFORMERS                                     │
│    • Give bonus to John Doe, Jane Smith (top 2)              │
│    • Public recognition in team meeting                      │
│    • Consider promotion for consistent high performers       │
│                                                              │
│ 2. COACH AVERAGE PERFORMERS                                  │
│    • Alice W. and Bob K. have potential to be "Good"         │
│    • Provide mentorship from top performers                  │
│    • Set specific, measurable goals for next month           │
│                                                              │
│ 3. INTERVENTION FOR LOW PERFORMERS                           │
│    • Tom B.: Immediate 1-on-1 meeting required               │
│    • Mike T.: Weekly check-ins for 1 month                   │
│    • Document performance issues for HR                      │
│    • Create Performance Improvement Plan (PIP)               │
│                                                              │
│ 4. TEAM-WIDE IMPROVEMENTS                                    │
│    • Consider productivity training/workshop                 │
│    • Review workload distribution (is it fair?)              │
│    • Check if tools/resources are adequate                   │
│    • Survey team for blockers/challenges                     │
│                                                              │
│ 5. NEXT STEPS (30 Days)                                      │
│    ✓ Week 1: Meet with low performers, create action plan    │
│    ✓ Week 2: Announce rewards for top performers             │
│    ✓ Week 3: Provide coaching session for average performers │
│    ✓ Week 4: Re-evaluate and measure improvement             │
│                                                              │
│ 📅 SCHEDULE NEXT REVIEW: November 30, 2025                   │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎯 PANDUAN LENGKAP: Cara Membuat Keputusan Berdasarkan KPI

### Skenario 1: Performance Review Bulanan

**Tujuan:** Evaluasi performa karyawan bulan ini

**Step-by-step:**

1. **Buka Sheet 2: KPI Dashboard**
   - Lihat ranking karyawan
   - Identifikasi top 3 dan bottom 3

2. **Analisis Productivity Score:**
   - Excellent (90-100): Beri reward/bonus
   - Good (75-89): Beri apresiasi
   - Average (60-74): Set target improvement
   - Below Average (40-59): Buat action plan
   - Poor (0-39): Meeting dengan HR

3. **Buka Individual Sheets untuk Bottom 3:**
   - Cek Daily Activity Breakdown: apakah ada pola?
   - Cek Top Visited URLs: apakah banyak distraksi?
   - Cek Browser Usage: apakah terlalu banyak idle?

4. **Buat Action Plan:**
   - Top performers: Reward + promotion consideration
   - Average performers: Coaching + mentoring
   - Low performers: PIP (Performance Improvement Plan)

---

### Skenario 2: Investigating Low Productivity

**Tanda-tanda Low Productivity:**
- Productivity Score < 60
- Active Time < 5 jam per hari
- Activity Rate < 5 per jam
- Top URLs adalah website hiburan

**Langkah Investigasi:**

1. **Buka Individual Sheet karyawan tersebut**

2. **Cek Daily Activity Breakdown:**
   - Apakah konsisten rendah setiap hari?
   - Atau ada hari-hari tertentu yang drop?
   - Pattern: Senin-Jumat produktif vs weekend?

3. **Cek Top 20 Most Visited URLs:**
   - Apakah website kerja atau hiburan?
   - Berapa lama di YouTube/Facebook/TikTok?
   - Apakah ada website mencurigakan?

4. **Cek Browser Usage Breakdown:**
   - Apakah terlalu banyak browser terbuka?
   - Average session terlalu pendek (< 5 min)?

5. **Kemungkinan Penyebab & Solusi:**

| Penyebab | Indikator | Solusi |
|----------|-----------|--------|
| **Lack of Work** | Active time rendah, unique URLs sedikit | Assign more tasks |
| **Distraction** | Banyak YouTube/social media | Block websites, coaching |
| **Health Issues** | Pattern tidak konsisten, sering absent | Medical leave, flexible hours |
| **Lack of Skills** | Banyak StackOverflow, ChatGPT | Training, mentoring |
| **Personal Problems** | Sudden drop dari biasanya | 1-on-1 meeting, support |
| **Wrong Tools** | Banyak time di email, sedikit di tools produktif | Provide better tools |

---

### Skenario 3: Identifying Star Performers for Promotion

**Kriteria Star Performer:**
- Productivity Score > 85
- Active Time > 7 jam consistently
- Engagement Score > 80
- Top URLs adalah work-related

**Langkah Identifikasi:**

1. **Buka Sheet 2: KPI Dashboard**
   - Lihat ranking teratas
   - Filter yang punya score > 85

2. **Buka Individual Sheets untuk kandidat:**
   - Cek consistency di Daily Activity Breakdown
   - Cek Top URLs: apakah semuanya work-related?
   - Cek Browser Usage: apakah efisien (tidak terlalu banyak distraksi)?

3. **Compare dengan Job Description:**
   - Developer: banyak GitHub, StackOverflow, ChatGPT
   - Designer: banyak Figma, Canva, Pinterest
   - Marketing: banyak Facebook Business, Analytics, Email
   - Sales: banyak CRM, Email, LinkedIn

4. **Buat Recommendation:**
   - Consistent high performer (3+ months) → Promosi
   - Good performer with upward trend → Bonus
   - Good performer tapi baru → Monitor 1-2 bulan lagi

---

### Skenario 4: Team Performance Comparison

**Tujuan:** Bandingkan performa antar tim/department

**Langkah:**

1. **Export Excel untuk semua tim:**
   - Tim A: Engineering
   - Tim B: Marketing
   - Tim C: Sales

2. **Buka Sheet 2: KPI Dashboard untuk tiap file**

3. **Compare Key Metrics:**

| Metric | Tim A | Tim B | Tim C |
|--------|-------|-------|-------|
| Average Active Hours | 7.8 | 6.5 | 5.2 |
| Average Productivity | 82.5 | 71.3 | 58.7 |
| % High Performers | 60% | 40% | 25% |
| % Low Performers | 10% | 20% | 35% |

**Analisis:**
- Tim A (Engineering) paling produktif → Best practices sharing
- Tim C (Sales) paling rendah → Investigate (workload? tools? training?)

4. **Buka Sheet Last: Analytics**
   - Compare performance distribution
   - Identify best practices dari top team
   - Apply ke team lain

---

## ⚠️ ANALISIS: Kenapa URL YouTube, Coretax, dll Tidak Tersimpan?

### 🔍 Root Cause Analysis

Setelah menganalisis kode Python client dan Laravel server, gue menemukan **BEBERAPA ALASAN** kenapa beberapa URL tidak tersimpan:

---

### **REASON #1: Filter Durasi Minimum (UTAMA)**

**Lokasi:** `client/src/modules/browser_tracker.py` line 662

```python
if activity['total_time'] > 30:  # Only send activities > 30 seconds
```

**Artinya:**
- URL yang dikunjungi **kurang dari 30 detik** TIDAK akan dikirim ke server
- Ini adalah **optimasi untuk mengurangi 60% database growth**

**Contoh:**
```
YouTube tab dibuka 15 detik → TIDAK DISIMPAN ❌
Coretax dibuka 20 detik → TIDAK DISIMPAN ❌
GitHub dibuka 45 detik → DISIMPAN ✅
ChatGPT dibuka 120 detik → DISIMPAN ✅
```

**Kenapa difilter 30 detik?**
- Mencegah "click-through" traffic (buka tab, langsung tutup)
- Mengurangi noise dalam database
- Focus pada **meaningful activities** (aktivitas yang benar-benar penting)

**💡 SOLUSI:**

**Jika client ingin track SEMUA URL (termasuk yang < 30 detik):**

1. Edit file: `client/src/modules/browser_tracker.py`
2. Cari line 662: `if activity['total_time'] > 30:`
3. Ubah jadi:
   ```python
   if activity['total_time'] > 0:  # Track all activities
   ```

**⚠️ KONSEKUENSI:**
- Database akan **grow 2-3x lebih cepat**
- Banyak "noise" data (URL yang hanya dibuka sebentar)
- Server load meningkat

**Rekomendasi gue:**
- **KEEP 30 seconds filter** untuk production
- Kalo client benar-benar butuh track YouTube/Coretax yang cuma dibuka sebentar, turunin jadi 10 detik:
  ```python
  if activity['total_time'] > 10:  # Track activities > 10 seconds
  ```

---

### **REASON #2: Tracking Interval 5 Menit**

**Lokasi:** `client/src/modules/browser_tracker.py` line 186

```python
time.sleep(300)  # Check every 5 minutes
```

**Artinya:**
- Browser tracker hanya check URL **setiap 5 menit** (bukan real-time)
- Ini juga optimasi untuk reduce database growth **80%**

**Contoh:**
```
10:00 → Check URLs, kirim ke server
10:05 → Check URLs, kirim ke server
10:10 → Check URLs, kirim ke server

Jika user buka YouTube di 10:02 dan tutup di 10:03 (1 menit):
- Di check 10:00 → YouTube belum dibuka
- Di check 10:05 → YouTube sudah ditutup
- RESULT: YouTube TIDAK TERDETEKSI ❌
```

**💡 SOLUSI:**

**Jika client ingin tracking lebih real-time:**

1. Edit file: `client/src/modules/browser_tracker.py`
2. Cari line 186: `time.sleep(300)`
3. Ubah jadi:
   ```python
   time.sleep(60)  # Check every 1 minute (faster tracking)
   ```

**⚠️ KONSEKUENSI:**
- Client akan **send data 5x lebih sering** ke server
- Database akan grow **5x lebih cepat**
- Network bandwidth meningkat
- CPU usage meningkat (client & server)

**Rekomendasi gue:**
- **KEEP 5 minutes** untuk production (balance antara accuracy & performance)
- Jika really needed, turunin ke **2-3 minutes**, JANGAN kurang dari 1 menit

---

### **REASON #3: Browser Tab Detection Limitation**

**Platform-specific limitations:**

#### **macOS (Darwin):**
- Menggunakan **AppleScript** untuk get URLs dari Chrome/Safari
- AppleScript hanya bisa access **active tab** (tab yang sedang di-focus)
- Background tabs **TIDAK TERDETEKSI**

```python
# Line 239-276: macOS Chrome tracking
osascript -e 'tell application "Google Chrome" to get URL of active tab of front window'
```

**Artinya:**
```
Tab 1: GitHub (active) → DETECTED ✅
Tab 2: YouTube (background) → NOT DETECTED ❌
Tab 3: Coretax (background) → NOT DETECTED ❌
```

#### **Windows:**
- Menggunakan **window title** untuk extract URL
- Hanya detect **active window** (window yang di-foreground)
- Background windows/tabs **TIDAK TERDETEKSI**

```python
# Line 400-437: Windows tracking via win32gui
win32gui.GetWindowText(hwnd)  # Only gets FOREGROUND window
```

#### **Linux:**
- Menggunakan `wmctrl` untuk get window titles
- Juga hanya detect **active window**

---

### **REASON #4: URL Extraction Method**

**Untuk beberapa browser, kita hanya bisa extract URL dari window title:**

```python
# Line 532-552: Extract URL from window title
def _extract_url_from_title(self, browser_name: str, window_title: str):
    url_patterns = [
        r'https?://[^\s\)]+',  # Direct URL
        r'([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}',  # Domain pattern
    ]
```

**Problem:**
- Tidak semua browser menampilkan URL di window title
- YouTube: Title = "Rick Astley - Never Gonna Give You Up" (TIDAK ADA URL!)
- Coretax: Title = "Dashboard - Coretax" (TIDAK ADA URL!)

**Yang bisa detect URL di title:**
- GitHub: "user/repo: Pull Requests · GitHub" → Bisa extract `github.com` ✅
- Stack Overflow: "javascript - How to ... - Stack Overflow" → Bisa extract `stackoverflow.com` ✅

**Yang TIDAK bisa:**
- YouTube: "Video Title - YouTube" → URL tidak muncul di title ❌
- Netflix: "Watch Movie X" → URL tidak muncul di title ❌
- Coretax: "Dashboard" → URL tidak muncul di title ❌

---

### **REASON #5: Browser-Specific Limitations**

Beberapa browser **TIDAK MENDUKUNG** external access ke tab information:

```python
self.browser_processes = {
    'Chrome': ['chrome', 'Google Chrome', 'chrome.exe'],      # ✅ Supported (via AppleScript)
    'Firefox': ['firefox', 'Firefox', 'firefox.exe'],         # ⚠️ Limited (no native API)
    'Safari': ['Safari'],                                      # ✅ Supported (via AppleScript)
    'Edge': ['msedge', 'Microsoft Edge', 'msedge.exe'],       # ⚠️ Limited
    'Opera': ['opera', 'Opera', 'opera.exe'],                 # ❌ Not supported
    'Brave': ['brave', 'Brave Browser', 'brave.exe']          # ❌ Not supported
}
```

**Jika user pakai Firefox/Edge/Opera/Brave untuk buka YouTube:**
- Tracking akan **sangat limited** atau **tidak berfungsi**
- Hanya Chrome dan Safari yang fully supported

---

### **REASON #6: Activity Pause saat User Inactive**

```python
# Line 584-586: Pause tracking when user inactive
if self.tracking_paused:
    return  # Skip duration updates if user is inactive
```

**Artinya:**
- Jika user **idle 5 menit** (no mouse/keyboard activity)
- Tracking akan **PAUSE**
- URL yang dibuka saat pause **TIDAK DIHITUNG DURASINYA**

**Contoh:**
```
10:00 → User buka YouTube, mulai nonton video
10:02 → User idle (tidak gerak mouse/keyboard)
10:07 → Activity detector pause tracking (5 min idle)
10:15 → User kembali aktif

Result:
- YouTube duration = 2 minutes (10:00-10:02)
- NOT 15 minutes (10:00-10:15)
```

**Ini adalah FITUR, bukan BUG:**
- Mencegah counting waktu saat user tidak di depan komputer
- Lebih accurate untuk measure **productive time**

---

## 💡 REKOMENDASI & SOLUSI

### Opsi 1: KEEP CURRENT SETTINGS (RECOMMENDED)

**Alasan:**
- Balance antara **accuracy** dan **performance**
- Database growth terkontrol
- Focus pada **meaningful activities** (> 30 seconds)
- Menghindari noise data

**Trade-off:**
- Beberapa short visits (< 30 seconds) tidak tercatat
- Background tabs tidak tercatat
- Hanya active/foreground activities yang tercatat

**Kapan pakai:** Production environment, large team (> 20 people)

---

### Opsi 2: LOWER DURATION FILTER (BALANCED)

**Changes needed:**

```python
# File: client/src/modules/browser_tracker.py
# Line 662: Change from 30 to 10 seconds
if activity['total_time'] > 10:  # Track activities > 10 seconds
```

**Impact:**
- ✅ Capture lebih banyak short visits
- ✅ YouTube/Coretax yang dibuka 10-30 detik akan tercatat
- ⚠️ Database growth meningkat ~40%
- ⚠️ More noise data

**Kapan pakai:** Medium team (10-20 people), need more detailed tracking

---

### Opsi 3: INCREASE TRACKING FREQUENCY (ADVANCED)

**Changes needed:**

```python
# File: client/src/modules/browser_tracker.py
# Line 186: Change from 300 to 120 seconds (2 minutes)
time.sleep(120)  # Check every 2 minutes
```

**Impact:**
- ✅ More frequent checks → less missed activities
- ✅ Better detection of short-lived tabs
- ⚠️ Database growth meningkat ~150%
- ⚠️ Higher CPU and network usage

**Kapan pakai:** Small team (< 10 people), critical monitoring needed

---

### Opsi 4: TRACK ALL ACTIVITIES (NOT RECOMMENDED)

**Changes needed:**

```python
# File: client/src/modules/browser_tracker.py

# Line 662: Remove duration filter
if activity['total_time'] > 0:  # Track ALL activities

# Line 186: More frequent checks
time.sleep(60)  # Check every 1 minute
```

**Impact:**
- ✅ Track EVERYTHING (no missed activities)
- ❌ Database growth 5-10x faster
- ❌ Lots of noise data (click-throughs, accidental opens)
- ❌ High server load
- ❌ High network bandwidth

**Kapan pakai:** ONLY for testing/debugging, NOT for production

---

### Opsi 5: BROWSER EXTENSION (IDEAL but REQUIRES DEVELOPMENT)

**Concept:**
- Develop Chrome Extension/Firefox Add-on
- Track **ALL tabs** in **real-time** (not just active tabs)
- Send data directly to server via WebSocket

**Pros:**
- ✅ Real-time tracking
- ✅ Track all tabs (active + background)
- ✅ No polling needed (event-driven)
- ✅ More accurate

**Cons:**
- ❌ Requires development (2-4 weeks)
- ❌ User must install extension
- ❌ Only works for Chrome/Firefox (not Safari, Edge, etc)

**Kapan pakai:** Enterprise, need 100% accuracy, budget available

---

## 📋 CHECKLIST UNTUK CLIENT

### ✅ Saat Export Excel

- [ ] Pilih periode waktu yang tepat (This Month untuk review bulanan)
- [ ] Pastikan semua client sudah online/termonitor dalam periode tersebut
- [ ] Download file Excel dan simpan dengan nama yang jelas
- [ ] Buka dengan Microsoft Excel atau Google Sheets (bukan Notepad!)

### ✅ Saat Review KPI Dashboard (Sheet 2)

- [ ] Lihat ranking karyawan (top 3 dan bottom 3)
- [ ] Check Productivity Score untuk setiap karyawan
- [ ] Identifikasi karyawan dengan Performance Rating "Poor" atau "Below Average"
- [ ] Bandingkan Active Hours dengan target (8 jam)
- [ ] Check Summary Statistics di bawah

### ✅ Saat Review Individual Sheets

- [ ] Buka sheet karyawan yang score-nya rendah
- [ ] Check Daily Activity Breakdown → cari pola
- [ ] Review Top 20 Most Visited URLs → work-related atau hiburan?
- [ ] Check Browser Usage Breakdown → apakah efisien?
- [ ] Review Top Domains → apakah sesuai job description?

### ✅ Saat Review Analytics Sheet

- [ ] Check Performance Distribution → apakah tim sehat?
- [ ] Review Recommendations & Insights
- [ ] Buat action plan berdasarkan insights
- [ ] Schedule follow-up meeting dengan karyawan yang perlu improvement

### ✅ After Review (Action Items)

- [ ] Meeting dengan top performers → beri reward/apresiasi
- [ ] Meeting dengan low performers → identify blockers, create PIP
- [ ] Meeting dengan manager → discuss team performance
- [ ] Schedule next review (monthly or quarterly)
- [ ] Document decision (bonus, promotion, warning, etc)

---

## 📞 FAQ (Frequently Asked Questions)

### Q1: Kenapa Active Time tidak sama dengan jam kerja?

**A:** Active Time adalah waktu dimana karyawan **benar-benar aktif** (mouse bergerak, keyboard ketik, aplikasi digunakan). Tidak termasuk waktu idle, break, toilet, meeting tanpa komputer, dll.

Normal range: 75-85% dari total jam kerja.

---

### Q2: Apakah data real-time atau delayed?

**A:** Data di-update setiap **5 menit** dari Python client ke server. Jadi ada delay maksimal 5 menit. Saat export Excel, data adalah **snapshot** pada waktu export.

---

### Q3: Kenapa beberapa website tidak muncul di Top URLs?

**A:** Ada 3 kemungkinan:
1. Website hanya dibuka < 30 detik (filtered)
2. Website dibuka di background tab (not detected)
3. Browser tidak support URL tracking (Firefox, Opera, Brave limited support)

---

### Q4: Apakah screenshot diambil terus-menerus?

**A:** Tidak. Screenshot diambil setiap **5 menit** (configurable). Jadi dalam 8 jam kerja = ~96 screenshots. Ini balance antara monitoring dan privacy.

---

### Q5: Bagaimana cara identify "fake productivity"?

**A:** Lihat kombinasi metrics:
- High Active Time + Low URL Activities = Mungkin hanya buka 1 aplikasi lama (watching video?)
- High URL Activities + Low Productivity Score = Banyak buka website tapi tidak work-related
- High Screenshots + Low Active Time = Screenshot terambil tapi tidak ada aktivitas

Cek Individual Sheet → Top 20 URLs untuk confirm.

---

### Q6: Apakah bisa export PDF?

**A:** Saat ini hanya support Excel (`.xlsx`). Untuk PDF, bisa buka Excel di Google Sheets, lalu **File → Download → PDF**.

---

### Q7: Berapa lama data disimpan?

**A:** Semua data disimpan **permanent** (tidak ada auto-delete). Untuk export, client bisa pilih custom date range kapanpun (contoh: data 6 bulan lalu).

---

### Q8: Apakah karyawan bisa tahu mereka dimonitor?

**A:** Ya, karena aplikasi Python client terlihat di system tray (stealth mode bisa diaktifkan tapi **tidak recommended** untuk ethical reasons). Best practice: **inform employees** about monitoring.

---

### Q9: Apakah bisa tracking di mobile/tablet?

**A:** Tidak. Sistem ini hanya support **desktop** (Windows, macOS, Linux). Mobile tracking requires different approach (MDM solution).

---

### Q10: Bagaimana cara handle privacy concerns?

**A:** Best practices:
1. **Inform employees** sebelum deploy (transparency)
2. Fokus pada **productivity metrics**, bukan spying
3. Jangan track **personal devices** (hanya company-owned)
4. Use data untuk **coaching/improvement**, bukan punishment
5. Comply dengan **labor laws** di Indonesia

---

## 📚 Glossary (Istilah Penting)

| Istilah | Definisi |
|---------|----------|
| **Active Time** | Total waktu dimana karyawan benar-benar aktif (mouse/keyboard activity) |
| **Activity Rate** | Jumlah aktivitas per jam (URL visits, clicks, keystrokes) |
| **Browser Session** | Satu sesi browser dari dibuka sampai ditutup |
| **Client** | Komputer/laptop karyawan yang dimonitor |
| **Domain** | Nama website tanpa protocol dan path (contoh: `github.com`) |
| **Duration** | Lama waktu di sebuah URL (dalam detik atau menit) |
| **Engagement Score** | Skor keterlibatan karyawan (0-100) |
| **Idle Time** | Waktu tidak aktif (no mouse/keyboard activity) |
| **KPI** | Key Performance Indicator (indikator performa utama) |
| **Performance Rating** | Kategori performa (Excellent, Good, Average, Below Avg, Poor) |
| **Productivity Score** | Skor produktivitas karyawan (0-100) |
| **Screenshot** | Tangkapan layar komputer karyawan |
| **Session Duration** | Lama waktu satu sesi browser |
| **Unique URLs** | Jumlah website berbeda yang dikunjungi (tidak dihitung duplikat) |
| **URL Activity** | Aktivitas mengunjungi sebuah website |

---

## 📖 Kesimpulan

File Excel KPI Export adalah **tool powerful** untuk:
- ✅ Evaluasi performa karyawan secara **objektif** (berdasarkan data, bukan feeling)
- ✅ Identifikasi **top performers** untuk reward/promosi
- ✅ Identifikasi **low performers** untuk coaching/improvement
- ✅ Analyze **productivity trends** (naik/turun setiap bulan)
- ✅ Bandingkan performa **antar tim/department**
- ✅ Buat **data-driven decisions** untuk HR (bonus, promosi, warning, dll)

**Key Metrics yang Paling Penting:**
1. **Productivity Score** (Sheet 2) → Overall performance indicator
2. **Active Time** (Sheet 2) → Time spent working
3. **Top 20 URLs** (Individual Sheets) → What they're actually doing
4. **Daily Activity Breakdown** (Individual Sheets) → Consistency check

**Action Plan setelah Review:**
1. **Reward** top performers (bonus, promotion, recognition)
2. **Coach** average performers (mentoring, training, goal setting)
3. **Intervene** with low performers (1-on-1, PIP, warning)
4. **Improve** team-wide (training, tools, process optimization)

---

**Questions?**
Jika ada pertanyaan tentang cara membaca laporan KPI, hubungi:
- Email: support@adilabs.id
- WhatsApp: [Your Support Number]

**Dibuat oleh:** AdiLabs Development Team
**Versi:** 1.0
**Tanggal:** November 2025

---

## 🔐 CATATAN PRIVASI & ETIKA

### ⚠️ PENTING untuk Client/Manager:

1. **Transparency is Key**
   - Inform employees bahwa mereka dimonitor
   - Explain WHY monitoring dilakukan (productivity, bukan spying)
   - Show sample reports so they understand

2. **Use Data Wisely**
   - Gunakan untuk **coaching** dan **improvement**, bukan punishment
   - Focus pada patterns (consistent low performance), bukan 1-time incidents
   - Consider context (sakit, personal issues, training period)

3. **Respect Privacy**
   - Jangan monitor **personal devices**
   - Only track during **working hours**
   - Jangan screenshot content yang sensitive (bank account, personal email, etc)

4. **Legal Compliance**
   - Pastikan monitoring comply dengan **Indonesian Labor Law**
   - Get **written consent** dari employees
   - Have clear **monitoring policy** dalam employee handbook

5. **Data Security**
   - Protect KPI data (jangan dishare ke unauthorized persons)
   - Use strong passwords untuk dashboard access
   - Regular backup untuk prevent data loss

**Remember:** Monitoring tool should **EMPOWER** employees to improve, not make them feel surveilled!

---