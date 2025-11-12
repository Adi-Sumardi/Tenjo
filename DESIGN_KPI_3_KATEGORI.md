# 🎯 DESIGN KPI BARU: 3 Kategori Aktivitas

## 📊 Konsep Sistem

System akan **mengkategorikan** semua aktivitas karyawan menjadi **3 kategori** berdasarkan URL/aplikasi yang dibuka:

```
┌─────────────────────────────────────────────────────────────┐
│                    TOTAL AKTIVITAS 100%                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🟢 PEKERJAAN        🔴 MEDIA SOSIAL      ⚫ TIDAK           │
│     (Work)              (Distraction)        TERIDENTIFIKASI│
│                                              (Suspicious)    │
│     60%                 30%                  10%            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**KPI Score** = Persentase waktu di kategori **PEKERJAAN**

---

## 🎨 Kategori Aktivitas

### 🟢 Kategori 1: PEKERJAAN (Work Activities)

**Definisi:** Aktivitas yang berhubungan dengan pekerjaan

**Keywords/Patterns:**

#### Aplikasi Office
- `excel`, `xls`, `xlsx`, `spreadsheet`
- `word`, `doc`, `docx`, `document`
- `powerpoint`, `ppt`, `pptx`, `presentation`
- `pdf`, `adobe`, `acrobat`

#### Tools Akuntansi/Keuangan
- `accurate` (Accurate Online)
- `coretax` (DJP Coretax)
- `pajak.go.id` (Pajak online)
- `e-faktur`
- `jurnal.id`, `zahir`, `myob`
- `accounting`, `finance`

#### Email & Communication
- `mail.google.com`, `gmail`
- `outlook.com`, `office.com`
- `email`, `inbox`

#### Tools Produktivitas
- `drive.google.com`, `docs.google.com`
- `dropbox`, `onedrive`
- `notion`, `trello`, `asana`
- `slack`, `teams`, `zoom` (untuk meeting)

#### Development/IT (jika ada developer)
- `github`, `gitlab`, `bitbucket`
- `stackoverflow`
- `localhost`

**Warna:** 🟢 Hijau (Good)
**Impact:** Positive (+) untuk KPI Score

---

### 🔴 Kategori 2: MEDIA SOSIAL (Social Media / Distraction)

**Definisi:** Aktivitas hiburan/sosial media yang tidak produktif

**Keywords/Patterns:**

#### Social Media
- `youtube`, `youtu.be`
- `instagram`, `ig`
- `tiktok`
- `facebook`, `fb.com`
- `twitter`, `x.com`
- `whatsapp.com` (WhatsApp Web)
- `telegram.org`
- `linkedin.com` (kecuali untuk recruitment)

#### Entertainment
- `netflix`, `disney+`, `hbo`
- `spotify`, `soundcloud`, `music`
- `twitch`
- `reddit`

#### Shopping
- `tokopedia`, `shopee`, `lazada`, `bukalapak`
- `amazon`, `ebay`
- `olx`, `carousell`

#### News/Portal (non-work)
- `detik.com`, `kompas.com`, `tribun`
- `cnn`, `bbc` (kecuali untuk pekerjaan terkait)

**Warna:** 🔴 Merah (Warning)
**Impact:** Negative (-) untuk KPI Score

---

### ⚫ Kategori 3: TIDAK TERIDENTIFIKASI (Suspicious Activities)

**Definisi:** Aktivitas mencurigakan atau tidak wajar

**Keywords/Patterns:**

#### Gambling/Betting
- `judi`, `taruhan`, `betting`
- `slot`, `casino`, `poker`
- `sbobet`, `maxbet`
- `togel`
- Keywords: `deposit`, `withdraw`, `jackpot`

#### Gaming (Online Games)
- `mobile legends`, `ml`, `mobilelegends`
- `free fire`, `freefire`, `garena`
- `pubg`, `fortnite`
- `steam`, `epicgames`
- `roblox`, `minecraft`
- `genshin`, `honkai`

#### Adult Content (Optional - tergantung policy)
- Blocked by keyword filtering

#### Suspicious Domains
- Unknown domains dengan traffic tinggi
- Sites dengan SSL certificate error
- Domains dengan reputation score rendah

**Warna:** ⚫ Hitam/Abu-abu (Critical)
**Impact:** Very Negative (--) untuk KPI Score

---

## 📐 Formula KPI Baru

### 1. **Work Percentage (Persentase Pekerjaan)**

```
Work % = (Work Duration / Total Duration) × 100

Contoh:
- Total active time: 8 jam (480 menit)
- Work activities: 6 jam (360 menit)
- Social media: 1.5 jam (90 menit)
- Suspicious: 0.5 jam (30 menit)

Work % = (360 / 480) × 100 = 75%
```

**Rating:**
- **90-100%** = Excellent (hampir semua waktu untuk kerja) 🌟🌟🌟🌟🌟
- **75-89%** = Good (sebagian besar kerja) 🌟🌟🌟🌟
- **60-74%** = Average (cukup fokus) 🌟🌟🌟
- **40-59%** = Below Average (banyak distraksi) 🌟🌟
- **0-39%** = Poor (mayoritas tidak kerja) 🌟

---

### 2. **Productivity Score (0-100)**

```
Productivity Score = (Work % × 0.7) + (Active Hours Score × 0.3)

Components:
1. Work % (70%) - Kualitas aktivitas
2. Active Hours Score (30%) - Kuantitas waktu

Active Hours Score:
- 8+ hours = 100
- 6-8 hours = 75
- 4-6 hours = 50
- <4 hours = 25

Contoh:
- Work % = 75%
- Active hours = 7.5 hours (score = 90)

Productivity Score = (75 × 0.7) + (90 × 0.3)
                   = 52.5 + 27
                   = 79.5 (GOOD)
```

---

### 3. **Risk Score (Skor Risiko)**

```
Risk Score = (Social Media % × 1) + (Suspicious % × 3)

Suspicious activities diberi bobot 3x karena lebih serius.

Contoh:
- Social Media: 20% (1.5 jam dari 8 jam)
- Suspicious: 5% (0.5 jam dari 8 jam)

Risk Score = (20 × 1) + (5 × 3)
           = 20 + 15
           = 35

Risk Level:
- 0-10 = Low Risk (aman) 🟢
- 11-25 = Medium Risk (perlu perhatian) 🟡
- 26-50 = High Risk (warning) 🟠
- >50 = Critical Risk (urgent action) 🔴
```

---

## 📊 Tampilan Excel Baru

### Sheet 2: KPI Dashboard (NEW DESIGN)

| Rank | Employee | Active Hours | Work % | Social % | Suspicious % | Productivity Score | Risk Score | Rating |
|------|----------|--------------|--------|----------|--------------|--------------------|-----------|----|
| 1 | John Doe | 8.5 | 92% 🟢 | 7% 🔴 | 1% ⚫ | 95.5 | 8 🟢 | Excellent |
| 2 | Jane Smith | 7.8 | 85% 🟢 | 12% 🔴 | 3% ⚫ | 87.2 | 21 🟡 | Good |
| 3 | Bob K. | 7.2 | 78% 🟢 | 18% 🔴 | 4% ⚫ | 76.8 | 30 🟠 | Good |
| 4 | Alice W. | 6.5 | 68% 🟢 | 28% 🔴 | 4% ⚫ | 68.4 | 40 🟠 | Average |
| 5 | Mike T. | 5.2 | 55% 🟢 | 35% 🔴 | 10% ⚫ | 55.1 | 65 🔴 | Below Avg |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |
| 15 | Tom B. | 3.1 | 40% 🟢 | 45% 🔴 | 15% ⚫ | 42.1 | 90 🔴 | Poor |

**Summary Statistics:**
```
Team Average:
- Work Activities: 72% (Target: >70%)
- Social Media: 22% (Target: <20%)
- Suspicious: 6% (Target: <5%)
- Avg Risk Score: 28 (Medium Risk)

Recommendations:
⚠️ 3 employees have High Risk Score (>50) - Immediate action needed
⚠️ 5 employees spend >30% on social media - Coaching required
✅ 7 employees meet productivity standards (>75%)
```

---

### Sheet 3: Category Breakdown (NEW!)

**Per Employee Breakdown:**

```
EMPLOYEE: John Doe
Period: 2025-11-01 to 2025-11-30

┌──────────────────────────────────────────────────────┐
│ ACTIVITY DISTRIBUTION                                │
├──────────────────────────────────────────────────────┤
│ 🟢 Pekerjaan:           92.0% (7h 50m / 8h 30m)      │
│ 🔴 Media Sosial:         7.0% (35m / 8h 30m)         │
│ ⚫ Tidak Teridentifikasi: 1.0% (5m / 8h 30m)         │
└──────────────────────────────────────────────────────┘

TOP WORK ACTIVITIES (🟢 Pekerjaan):
1. accurate.id            - 2h 30m (Accurate Online)
2. coretax.pajak.go.id   - 1h 45m (Coretax)
3. mail.google.com       - 1h 20m (Email)
4. excel (local file)    - 1h 10m (Excel)
5. docs.google.com       - 1h 05m (Google Docs)
Total: 7h 50m

SOCIAL MEDIA USAGE (🔴 Media Sosial):
1. youtube.com           - 20m (YouTube)
2. whatsapp.com          - 10m (WhatsApp Web)
3. instagram.com         - 5m (Instagram)
Total: 35m

SUSPICIOUS ACTIVITIES (⚫ Tidak Teridentifikasi):
1. unknown-domain.xyz    - 5m (Unknown site)
Total: 5m
```

---

### Sheet 4: Daily Breakdown (NEW!)

**Daily Activity by Category:**

| Date | Total Active | Work | Social Media | Suspicious | Work % | Status |
|------|--------------|------|--------------|------------|--------|--------|
| 2025-11-01 | 8h 15m | 7h 30m | 40m | 5m | 91% | ✅ Excellent |
| 2025-11-02 | 7h 45m | 6h 50m | 50m | 5m | 88% | ✅ Good |
| 2025-11-03 | 7h 30m | 6h 20m | 1h | 10m | 84% | ✅ Good |
| 2025-11-04 | 6h 30m | 4h 50m | 1h 30m | 10m | 74% | ⚠️ Average |
| 2025-11-05 | 5h 20m | 3h 10m | 2h | 10m | 59% | ⚠️ Below Avg |
| ... | ... | ... | ... | ... | ... | ... |

**Trend Analysis:**
```
Week 1 (Nov 1-7):   Avg Work % = 87% ✅
Week 2 (Nov 8-14):  Avg Work % = 82% ✅
Week 3 (Nov 15-21): Avg Work % = 76% ⚠️
Week 4 (Nov 22-28): Avg Work % = 71% ⚠️

⚠️ Warning: Declining trend detected
   Recommendation: Meeting with employee to discuss
```

---

## 🎨 Visualisasi (Pie Chart)

### Per Employee:

```
      John Doe Activity Distribution

           🟢 Work (92%)
          ╱─────────────╲
         │               │
         │   📊 KPI      │
         │   Score: 95   │
         │               │
          ╲─────────────╱
    🔴 Social (7%)  ⚫ Suspicious (1%)
```

### Team Overview:

```
Team Average Distribution

🟢 Pekerjaan (72%)          ████████████████████████████████░░░░░░░░
🔴 Media Sosial (22%)       ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
⚫ Tidak Teridentifikasi (6%) ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Target: 🟢 >70% | 🔴 <20% | ⚫ <5%
Status: ✅ Work | ⚠️ Social | ⚠️ Suspicious
```

---

## 🔍 Detection Logic (Backend)

### URL Classification Algorithm:

```php
class ActivityCategorizer
{
    const CATEGORY_WORK = 'work';
    const CATEGORY_SOCIAL = 'social_media';
    const CATEGORY_SUSPICIOUS = 'suspicious';

    protected $workKeywords = [
        // Office Apps
        'excel', 'xls', 'xlsx', 'spreadsheet',
        'word', 'doc', 'docx', 'document',
        'powerpoint', 'ppt', 'pptx', 'presentation',
        'pdf', 'adobe', 'acrobat',

        // Accounting/Finance
        'accurate', 'coretax', 'pajak.go.id', 'e-faktur',
        'jurnal.id', 'zahir', 'myob', 'accounting', 'finance',

        // Email
        'mail.google.com', 'gmail', 'outlook', 'email', 'inbox',

        // Productivity
        'drive.google.com', 'docs.google.com', 'sheets.google.com',
        'dropbox', 'onedrive', 'notion', 'trello', 'asana',

        // Communication (work)
        'slack', 'teams', 'zoom', 'meet.google.com',

        // Development (if applicable)
        'github', 'gitlab', 'stackoverflow', 'localhost',
    ];

    protected $socialKeywords = [
        // Social Media
        'youtube', 'youtu.be', 'instagram', 'tiktok', 'facebook',
        'twitter', 'x.com', 'whatsapp.com', 'telegram',

        // Entertainment
        'netflix', 'disney', 'hbo', 'spotify', 'soundcloud',
        'twitch', 'reddit',

        // Shopping
        'tokopedia', 'shopee', 'lazada', 'bukalapak', 'amazon',
        'olx', 'carousell',

        // News (if not work related)
        'detik.com', 'kompas.com', 'tribun', 'cnn', 'bbc',
    ];

    protected $suspiciousKeywords = [
        // Gambling
        'judi', 'taruhan', 'betting', 'slot', 'casino', 'poker',
        'sbobet', 'maxbet', 'togel', 'deposit', 'withdraw', 'jackpot',

        // Gaming
        'mobile legends', 'mobilelegends', 'ml.', 'free fire', 'freefire',
        'pubg', 'fortnite', 'steam', 'epicgames', 'roblox', 'minecraft',
        'genshin', 'honkai',
    ];

    public function categorize($url, $domain, $pageTitle): string
    {
        $searchText = strtolower($url . ' ' . $domain . ' ' . $pageTitle);

        // Check suspicious first (highest priority)
        foreach ($this->suspiciousKeywords as $keyword) {
            if (strpos($searchText, $keyword) !== false) {
                return self::CATEGORY_SUSPICIOUS;
            }
        }

        // Check work keywords
        foreach ($this->workKeywords as $keyword) {
            if (strpos($searchText, $keyword) !== false) {
                return self::CATEGORY_WORK;
            }
        }

        // Check social media keywords
        foreach ($this->socialKeywords as $keyword) {
            if (strpos($searchText, $keyword) !== false) {
                return self::CATEGORY_SOCIAL;
            }
        }

        // Default: work (benefit of the doubt)
        return self::CATEGORY_WORK;
    }
}
```

---

## 📊 Database Schema Changes

### New Column in `url_activities` table:

```sql
ALTER TABLE url_activities ADD COLUMN activity_category VARCHAR(50) DEFAULT 'work';

-- Possible values: 'work', 'social_media', 'suspicious'

-- Add index for faster queries
CREATE INDEX idx_activity_category ON url_activities(activity_category);
CREATE INDEX idx_client_category ON url_activities(client_id, activity_category);
```

### New Aggregate Table (Optional - for performance):

```sql
CREATE TABLE client_activity_summary (
    id BIGSERIAL PRIMARY KEY,
    client_id VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    work_duration INT DEFAULT 0, -- seconds
    social_media_duration INT DEFAULT 0,
    suspicious_duration INT DEFAULT 0,
    total_duration INT DEFAULT 0,
    work_percentage DECIMAL(5,2) DEFAULT 0,
    social_percentage DECIMAL(5,2) DEFAULT 0,
    suspicious_percentage DECIMAL(5,2) DEFAULT 0,
    productivity_score DECIMAL(5,2) DEFAULT 0,
    risk_score DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, date)
);

CREATE INDEX idx_client_date ON client_activity_summary(client_id, date);
```

---

## 🎯 KPI Interpretation Guide (Simplified)

### Skenario 1: Karyawan Ideal

```
Work: 90% | Social: 8% | Suspicious: 2%
Productivity Score: 94 (Excellent)
Risk Score: 14 (Low Risk)

Interpretasi:
✅ Hampir semua waktu untuk pekerjaan
✅ Social media dalam batas wajar (break time)
✅ Suspicious activities minimal
👉 Action: Beri reward/bonus
```

---

### Skenario 2: Karyawan Distraksi Tinggi

```
Work: 55% | Social: 40% | Suspicious: 5%
Productivity Score: 58 (Below Average)
Risk Score: 55 (Critical Risk)

Interpretasi:
⚠️ Hanya setengah waktu untuk kerja
⚠️ 40% waktu untuk social media
⚠️ Ada aktivitas suspicious
👉 Action: Meeting urgent + warning
```

---

### Skenario 3: Karyawan Suspicious Activities

```
Work: 70% | Social: 15% | Suspicious: 15%
Productivity Score: 72 (Average)
Risk Score: 60 (Critical Risk)

Interpretasi:
⚠️ Work percentage OK, tapi...
🚨 Suspicious activities sangat tinggi (15%)
🚨 Risk Score critical (gambling/gaming?)
👉 Action: Investigasi segera + kemungkinan SP
```

---

### Skenario 4: Karyawan Konsisten

```
Work: 75-80% consistently
Social: 15-20%
Suspicious: <5%

Interpretasi:
✅ Produktivitas stabil
✅ Break time wajar
✅ Tidak ada red flags
👉 Action: Maintain, no action needed
```

---

## 📈 Reporting & Analytics

### Team Dashboard View:

```
┌────────────────────────────────────────────────────┐
│ TEAM PERFORMANCE OVERVIEW                          │
├────────────────────────────────────────────────────┤
│                                                    │
│ Average Work %:        72% ✅ (Target: >70%)      │
│ Average Social %:      22% ⚠️ (Target: <20%)      │
│ Average Suspicious %:   6% ⚠️ (Target: <5%)       │
│                                                    │
│ Employees Meeting Target:  60% (9 out of 15)      │
│ High Risk Employees:       20% (3 out of 15)      │
│                                                    │
├────────────────────────────────────────────────────┤
│ DISTRIBUTION                                       │
├────────────────────────────────────────────────────┤
│ Work % >80%:      5 employees (33%) ✅            │
│ Work % 70-80%:    4 employees (27%) ✅            │
│ Work % 60-70%:    3 employees (20%) ⚠️            │
│ Work % <60%:      3 employees (20%) ❌            │
│                                                    │
├────────────────────────────────────────────────────┤
│ ACTIONS REQUIRED                                   │
├────────────────────────────────────────────────────┤
│ 🔴 3 employees: Critical risk (>50)               │
│    - Tom B. (Risk: 90)                            │
│    - Sarah L. (Risk: 65)                          │
│    - Mike T. (Risk: 58)                           │
│                                                    │
│ 🟡 4 employees: High social media (>30%)          │
│    - Alice W., Bob K., Jane D., Chris P.          │
│                                                    │
│ ✅ 8 employees: Meeting all targets               │
└────────────────────────────────────────────────────┘
```

---

## 🎨 Color Coding (Excel)

### Work % Column:
- 🟢 Green (90-100%): #C6EFCE
- 🟢 Light Green (75-89%): #E2EFDA
- 🟡 Yellow (60-74%): #FFF2CC
- 🟠 Orange (40-59%): #FFE699
- 🔴 Red (0-39%): #FFC7CE

### Social % Column:
- 🟢 Green (0-10%): #C6EFCE
- 🟡 Yellow (11-20%): #FFF2CC
- 🟠 Orange (21-30%): #FFE699
- 🔴 Red (>30%): #FFC7CE

### Suspicious % Column:
- 🟢 Green (0-5%): #C6EFCE
- 🟠 Orange (6-10%): #FFE699
- 🔴 Red (>10%): #FFC7CE

### Risk Score Column:
- 🟢 Green (0-10): #C6EFCE
- 🟡 Yellow (11-25): #FFF2CC
- 🟠 Orange (26-50): #FFE699
- 🔴 Red (>50): #FFC7CE

---

## 🔄 Implementation Plan

### Phase 1: Backend (Week 1)
1. ✅ Create `ActivityCategorizer` class
2. ✅ Add `activity_category` column to `url_activities`
3. ✅ Run migration to categorize existing data
4. ✅ Update `BrowserTrackingController` to categorize new activities

### Phase 2: KPI Calculation (Week 1)
1. ✅ Create service class: `KPICalculatorService`
2. ✅ Implement Work %, Social %, Suspicious % calculation
3. ✅ Implement Productivity Score (new formula)
4. ✅ Implement Risk Score calculation

### Phase 3: Excel Export (Week 2)
1. ✅ Update `KPIDashboardSheet` with new columns
2. ✅ Create new `CategoryBreakdownSheet`
3. ✅ Update `IndividualEmployeeSheet` with categories
4. ✅ Add color coding based on thresholds

### Phase 4: Dashboard UI (Week 2)
1. ✅ Update Client Summary page with category breakdown
2. ✅ Add pie charts for activity distribution
3. ✅ Add risk score indicators
4. ✅ Add filtering by category

### Phase 5: Documentation (Week 2)
1. ✅ Update user guide with new KPI system
2. ✅ Create interpretation guide for managers
3. ✅ Training materials for client

---

## 📝 Notes & Considerations

### 1. **Keyword Customization**

Client bisa customize keywords sesuai industri:

**Contoh untuk Kantor Akuntan:**
```php
'work' => [
    'accurate', 'coretax', 'e-faktur', 'e-spt',
    'excel', 'word', 'pdf',
    'mail.google.com', 'drive.google.com'
]
```

**Contoh untuk Software House:**
```php
'work' => [
    'github', 'gitlab', 'stackoverflow',
    'localhost', 'docker', 'aws',
    'figma', 'jira', 'confluence'
]
```

### 2. **Whitelist/Blacklist**

Tambah fitur whitelist/blacklist domain:

```php
// Whitelist: Always categorized as WORK
whitelist = ['accurate.id', 'coretax.pajak.go.id']

// Blacklist: Always categorized as SUSPICIOUS
blacklist = ['sbobet.com', 'slot-gacor.com']
```

### 3. **False Positives**

Handle edge cases:
- YouTube for work (tutorial, webinar) → Manual override?
- LinkedIn for recruitment → Count as work?
- WhatsApp for work communication → Count as work?

**Solusi:** Add manual categorization feature untuk specific URLs/employees

### 4. **Privacy & Ethics**

**PENTING:**
- Inform employees tentang kategorisasi
- Explain kenapa website dikategorikan sebagai "suspicious"
- Give warning sebelum SP/termination
- Allow employees to explain context

---

## 🚀 Expected Outcomes

### Benefits:

1. **Lebih Spesifik** ✅
   - Tahu exact karyawan kecenderungannya ke mana
   - Bukan hanya "produktif" atau "tidak", tapi WHY

2. **Actionable Insights** ✅
   - Work % rendah → Perlu coaching
   - Social % tinggi → Perlu policy social media
   - Suspicious % tinggi → Perlu investigasi serius

3. **Early Warning System** ✅
   - Risk Score sebagai indicator early warning
   - Deteksi masalah sebelum jadi serius
   - Prevent gambling/gaming addiction di kantor

4. **Fair Evaluation** ✅
   - Data-driven, bukan subjektif
   - Clear standards (>70% work adalah target)
   - Transparent categorization

---

## ❓ Questions for Client

Sebelum implement, gue perlu konfirmasi:

### 1. **Keywords Accuracy**
- Apakah list keywords sudah sesuai dengan pekerjaan di kantor?
- Ada tools khusus lain yang perlu ditambah ke "Work"?
- Ada website yang seharusnya di whitelist?

### 2. **Thresholds**
- Apakah target Work % = 70% realistic untuk kantor?
- Berapa toleransi Social Media % yang acceptable? (saat ini 20%)
- Berapa threshold Suspicious % untuk trigger warning? (saat ini 5%)

### 3. **Actions**
- Jika Risk Score > 50, action apa yang diambil? (Warning? SP? Meeting?)
- Apakah perlu automatic email alert ke manager jika suspicious % tinggi?
- Apakah perlu block website suspicious otomatis?

### 4. **Customization**
- Apakah perlu fitur manual override categorization?
- Apakah perlu whitelist per employee (ex: Marketing boleh social media)?
- Apakah perlu different targets per department?

---

## 🎯 Next Steps

**After Approval:**

1. ✅ Client review design ini
2. ✅ Client confirm keywords & thresholds
3. ✅ Client answer questions di atas
4. 🔨 Gue implement backend (ActivityCategorizer)
5. 🔨 Gue update database schema
6. 🔨 Gue update Excel export
7. 🔨 Gue update documentation
8. 🧪 Testing di staging
9. 🚀 Deploy to production

**Estimated Time:** 1-2 minggu untuk full implementation

---

**Dibuat oleh:** AdiLabs Development Team
**Tanggal:** November 2025
**Status:** 📋 DESIGN PROPOSAL (Waiting for Client Approval)

---

## 📞 Feedback

Bro, ini design proposal lengkap untuk sistem KPI 3 kategori.

**Yang perlu lu review:**
1. Apakah 3 kategori ini sudah sesuai?
2. Apakah keywords sudah lengkap untuk kantor lu?
3. Apakah formula KPI (Work % × 0.7 + Active Hours × 0.3) masuk akal?
4. Apakah Risk Score perlu ada atau tidak?
5. Apakah threshold 70% work, 20% social, 5% suspicious realistic?

**Setelah lu approve, gue langsung implement!** 🚀