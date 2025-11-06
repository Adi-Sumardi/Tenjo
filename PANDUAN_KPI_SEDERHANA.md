# 📊 Panduan Cepat: Cara Baca Laporan KPI Excel

> **Versi Sederhana** - Panduan praktis untuk manager/client dalam 10 menit

---

## 🎯 Quick Start (3 Langkah)

### 1. Export Excel
- Login ke: `https://tenjo.adilabs.id/dashboard`
- Klik menu **"Client Summary"**
- Pilih periode: **This Month** (atau Custom Range)
- Klik **"Export Excel"**
- Download file: `Employee_KPI_Report_2025-XX-XX.xlsx`

### 2. Buka File
- Buka dengan **Microsoft Excel** atau **Google Sheets**
- File punya **4 sheet** (tab di bawah)

### 3. Lihat Ranking
- Langsung buka **Sheet 2: KPI Dashboard**
- Lihat ranking karyawan dari terbaik → terburuk

---

## 📋 Struktur File (4 Sheets)

```
Sheet 1: Summary           → Overview semua karyawan (optional)
Sheet 2: KPI Dashboard     → ⭐ PALING PENTING! Ranking & Score
Sheet 3-N: Individual      → Detail per karyawan (untuk deep dive)
Sheet Last: Analytics      → Insights tim (untuk planning)
```

**Yang paling sering dipakai: Sheet 2 (KPI Dashboard)**

---

## 🏆 Sheet 2: KPI Dashboard (INTI LAPORAN)

### Tampilan Excel:

| Rank | Employee | Active Hours | Productivity Score | Performance Rating |
|------|----------|--------------|--------------------|--------------------|
| 1 | John Doe | 8.5 | 95.5 | Excellent |
| 2 | Jane Smith | 7.8 | 87.2 | Good |
| 3 | Bob K. | 7.2 | 76.8 | Good |
| 4 | Alice W. | 6.5 | 68.4 | Average |
| 5 | Mike T. | 5.2 | 55.1 | Below Average |
| ... | ... | ... | ... | ... |
| 15 | Tom B. | 3.1 | 42.1 | Poor |

---

## 💡 Cara Baca Kolom Penting

### 1. **Rank (Peringkat)**
- Nomor 1 = Karyawan terbaik
- Nomor terakhir = Karyawan terburuk
- **Yang perlu dilakukan:**
  - Top 3 → Beri reward/bonus
  - Bottom 3 → Perlu coaching/meeting

---

### 2. **Active Hours (Jam Kerja Aktif)**

**Cara Baca:**
- **8.5 hours** = 8 jam 30 menit aktif bekerja
- Ini waktu **benar-benar produktif** (bukan jam duduk di kantor)

**Target:**
- ✅ **6-8 jam** = BAGUS! (75-100% produktif)
- ⚠️ **4-6 jam** = Cukup (50-75% produktif)
- ❌ **< 4 jam** = Rendah (perlu perhatian)

**Contoh:**
- John Doe: 8.5 jam → **EXCELLENT!**
- Mike T: 5.2 jam → **Perlu ditingkatkan**
- Tom B: 3.1 jam → **PROBLEM! Perlu meeting segera**

---

### 3. **Productivity Score (Skor 0-100)** ⭐ PALING PENTING

**Cara Baca:**
- **90-100** = Excellent (bintang 5) 🌟🌟🌟🌟🌟
- **75-89** = Good (bintang 4) 🌟🌟🌟🌟
- **60-74** = Average (bintang 3) 🌟🌟🌟
- **40-59** = Below Average (bintang 2) 🌟🌟
- **0-39** = Poor (bintang 1) 🌟

**Dihitung dari:**
- Waktu aktif (40%)
- Aktivitas website (30%)
- Browser sessions (20%)
- Variasi website (10%)

**Action Plan:**

| Score | Rating | Action |
|-------|--------|--------|
| 90-100 | Excellent | 💰 Beri bonus/reward |
| 75-89 | Good | 👏 Beri apresiasi |
| 60-74 | Average | 📊 Set target improvement |
| 40-59 | Below Avg | ⚠️ Meeting + coaching |
| 0-39 | Poor | 🚨 Meeting urgent + PIP |

---

### 4. **Performance Rating (Kategori)**

Ringkasan dari Productivity Score dalam bentuk label:

- **Excellent** → Top performer (promosi/bonus)
- **Good** → Solid performer (maintain)
- **Average** → Need coaching (bisa naik)
- **Below Average** → Need attention (PIP)
- **Poor** → Critical (investigasi)

---

## 🔍 Cara Pakai untuk Performance Review

### Step 1: Identifikasi Top & Bottom

**Top 3:**
```
1. John Doe - 95.5 (Excellent)
2. Jane Smith - 87.2 (Good)
3. Bob K. - 76.8 (Good)
```
**Action:** Beri reward, jadikan role model

**Bottom 3:**
```
13. Mike T. - 55.1 (Below Average)
14. Sarah L. - 48.3 (Below Average)
15. Tom B. - 42.1 (Poor)
```
**Action:** Perlu meeting 1-on-1 segera

---

### Step 2: Check Detail Karyawan Bermasalah

Jika ada karyawan score rendah:

1. **Buka Individual Sheet (Sheet 3-N)**
2. **Cari nama karyawan** (tab dengan nama mereka)
3. **Lihat "Top 20 Most Visited URLs"**

**Contoh Analisis:**

**Karyawan Produktif:**
```
Top URLs:
1. github.com (2h 15m) → Kerja coding ✅
2. chatgpt.com (1h 52m) → Pakai AI tools ✅
3. stackoverflow.com (1h 23m) → Problem solving ✅
```
**Kesimpulan:** BAGUS! Semua website untuk kerja

**Karyawan Bermasalah:**
```
Top URLs:
1. youtube.com (5h 30m) → Nonton video ❌
2. facebook.com (3h 45m) → Social media ❌
3. tiktok.com (2h 20m) → Entertainment ❌
```
**Kesimpulan:** PROBLEM! Sebagian besar waktu untuk hiburan

---

### Step 3: Buat Action Plan

**Template Meeting dengan Karyawan Score Rendah:**

```
Meeting Agenda:

1. Tunjukkan data KPI:
   "Score kamu bulan ini: 42.1 (Poor)"
   "Active time hanya 3.1 jam per hari"

2. Tanya kenapa:
   "Ada masalah? Sakit? Workload terlalu berat/ringan?"

3. Lihat Top URLs:
   "Kelihatannya banyak waktu di YouTube/Facebook"

4. Set target jelas:
   "Target bulan depan: 6 jam active time per hari"
   "Score minimal: 60 (Average)"

5. Buat follow-up:
   "Kita review lagi 2 minggu lagi"
```

---

## 👥 Sheet Last: Analytics (Untuk Team Review)

Buka sheet **Analytics** untuk lihat performa tim secara keseluruhan.

### Yang Penting Dilihat:

#### 1. Performance Distribution
```
High Performers (>6h):      8 orang (53%) ✅
Average Performers (4-6h):  5 orang (33%) ⚠️
Low Performers (<4h):       2 orang (13%) ❌

Total: 15 orang
```

**Cara Evaluasi:**
- ✅ **> 50% High Performers** = Tim sehat
- ⚠️ **30-50% High Performers** = Tim cukup baik
- ❌ **< 30% High Performers** = Tim bermasalah

#### 2. Team Average
```
Average Active Hours: 6.8 hours
```

**Target:**
- ✅ **≥ 6.5 jam** = Tim produktif
- ⚠️ **5-6.5 jam** = Tim cukup
- ❌ **< 5 jam** = Ada masalah sistemik

#### 3. Top & Bottom Performer
```
Most Productive: John Doe (95.5)
Least Productive: Tom B. (42.1)
```

**Action:**
- John Doe → Jadikan mentor untuk tim
- Tom B. → Perlu intervention segera

---

## 📊 Sheet 1: Summary (Optional)

Sheet ini untuk overview cepat semua karyawan dalam 1 tabel.

**Gunakan untuk:**
- Quick scan status online/offline
- Lihat active hours semua karyawan sekilas
- Export ke format lain jika perlu

**Tidak perlu dibaca detail**, fokus ke Sheet 2 (KPI Dashboard) saja.

---

## 🎯 Cheat Sheet: Decision Making

### Skenario 1: Review Bulanan Rutin

```
1. Buka Sheet 2 (KPI Dashboard)
2. Lihat ranking 1-15
3. Beri reward ke top 3
4. Buat meeting ke bottom 3
5. Done! (15 menit)
```

---

### Skenario 2: Ada Komplain Karyawan Tidak Produktif

```
1. Buka Sheet 2 → Cari nama karyawan
2. Cek score: < 60? Ada masalah!
3. Buka Individual Sheet karyawan tersebut
4. Lihat "Top 20 URLs" → website apa yang dibuka?
5. Lihat "Daily Activity" → konsisten rendah atau turun tiba-tiba?
6. Meeting 1-on-1 dengan data ini
```

---

### Skenario 3: Mau Promosi/Bonus Karyawan

```
1. Buka Sheet 2 (KPI Dashboard)
2. Filter score > 85 (Good/Excellent)
3. Check consistency di Individual Sheet:
   - Active hours konsisten > 7 jam?
   - Top URLs work-related?
4. Jika YA → Layak promosi/bonus
5. Jika TIDAK → Tunggu 1-2 bulan lagi
```

---

### Skenario 4: Perbandingan Antar Tim

```
1. Export Excel untuk Tim A, Tim B, Tim C
2. Buka Sheet Last (Analytics) tiap file
3. Compare "Team Average" dan "% High Performers"
4. Tim dengan average tertinggi → Best practices sharing
5. Tim dengan average terendah → Perlu improvement plan
```

---

## ⚠️ Pertanyaan Umum (FAQ)

### Q: Kenapa Active Time tidak sama dengan jam kerja?
**A:** Active Time = waktu **benar-benar produktif** (mouse bergerak, keyboard ketik). Tidak termasuk break, toilet, meeting tanpa komputer. Normal: 75-85% dari jam kerja.

---

### Q: Kenapa YouTube/Facebook tidak muncul di report?
**A:** Ada 3 kemungkinan:
1. Dibuka < 30 detik (terlalu sebentar, di-filter)
2. Dibuka di background tab (tidak terdeteksi)
3. Pakai browser selain Chrome/Safari (limited support)

**Solusi:** Fokus pada **total Active Hours** dan **Productivity Score**, bukan individual URLs.

---

### Q: Apakah data real-time?
**A:** Data di-update setiap **5 menit**. Saat export, data adalah snapshot pada waktu export.

---

### Q: Bagaimana cara tahu "fake productivity"?
**A:** Lihat kombinasi:
- ✅ High Active Time + High Score + Work URLs = **Real productivity**
- ❌ High Active Time + Low Score + Entertainment URLs = **Fake productivity**

Buka Individual Sheet → cek Top URLs untuk memastikan.

---

### Q: Apakah karyawan tahu mereka dimonitor?
**A:** **Ya**, dan ini penting untuk transparency. Best practice: inform employees sebelum deploy monitoring.

---

## 🔐 Catatan Privacy

**PENTING untuk Manager:**

1. **Transparency**
   - Inform karyawan bahwa mereka dimonitor
   - Explain tujuannya (productivity improvement, bukan spying)

2. **Gunakan Data dengan Bijak**
   - Untuk coaching, bukan punishment
   - Focus pada pattern, bukan 1x incident
   - Consider context (sakit, personal issue, dll)

3. **Legal Compliance**
   - Pastikan comply dengan labor law Indonesia
   - Get written consent dari employees
   - Have clear monitoring policy

---

## ✅ Quick Checklist

### Saat Export Excel:
- [ ] Pilih periode yang tepat (This Month untuk review bulanan)
- [ ] Download file dan buka dengan Excel/Google Sheets
- [ ] Pastikan semua client sudah online dalam periode tersebut

### Saat Review:
- [ ] Buka Sheet 2 (KPI Dashboard)
- [ ] Identifikasi top 3 dan bottom 3
- [ ] Check Productivity Score < 60 (need attention)
- [ ] Buka Individual Sheet untuk karyawan bermasalah
- [ ] Lihat Top URLs untuk validasi

### After Review:
- [ ] Beri reward/apresiasi ke top performers
- [ ] Meeting dengan low performers (< 60 score)
- [ ] Buat action plan untuk improvement
- [ ] Schedule next review (monthly atau quarterly)
- [ ] Document keputusan (bonus, warning, etc)

---

## 🎓 Kesimpulan

### Yang Harus Diingat:

1. **Focus ke Sheet 2 (KPI Dashboard)** - ini yang paling penting
2. **Productivity Score** adalah metric utama (0-100)
3. **Active Hours** target: 6-8 jam per hari
4. **Top 3** = reward, **Bottom 3** = coaching
5. **Buka Individual Sheet** hanya untuk deep dive karyawan bermasalah

### Action Plan Sederhana:

```
Review Bulanan (15 menit):
1. Export Excel (2 menit)
2. Lihat Sheet 2 ranking (5 menit)
3. Note top 3 & bottom 3 (3 menit)
4. Buat meeting schedule (5 menit)
Done!
```

### Tips:

- ✅ **DO:** Use data untuk improve, bukan punish
- ✅ **DO:** Consider context (sakit, training period, etc)
- ✅ **DO:** Set clear targets untuk improvement
- ❌ **DON'T:** Judge dari 1x data saja (lihat trend)
- ❌ **DON'T:** Compare job roles berbeda (dev vs marketing)
- ❌ **DON'T:** Ignore context (meeting, training tidak tercatat)

---

## 📞 Butuh Bantuan?

**Questions?**
- Email: support@adilabs.id
- WhatsApp: [Your Support Number]

**Ingin dokumentasi lengkap?**
- Baca: [PANDUAN_MEMBACA_KPI_EXCEL.md](PANDUAN_MEMBACA_KPI_EXCEL.md) (versi detail)

---

**Dibuat oleh:** AdiLabs Development Team
**Versi:** Simplified 1.0
**Update:** November 2025

---

## 📖 Next Steps

Setelah baca panduan ini:

1. ✅ **Export Excel** dari dashboard
2. ✅ **Buka Sheet 2** (KPI Dashboard)
3. ✅ **Lihat ranking** karyawan
4. ✅ **Buat action plan** untuk top & bottom performers
5. ✅ **Schedule meeting** dengan karyawan yang perlu improvement

**Selamat menggunakan sistem KPI Tenjo!** 🚀