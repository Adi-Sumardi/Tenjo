# 🎯 KPI 3 KATEGORI - SIMPLIFIED FOR REPORTING ONLY

## 📊 Overview

System akan categorize aktivitas karyawan ke **3 kategori** untuk **REPORTING ONLY** (no automation, no alerts, no blocking).

**Purpose:** Catatan & pertimbangan untuk diskusi performance review.

---

## 🎨 3 Kategori

### 🟢 1. PEKERJAAN (Work)
- Accurate, Coretax, E-Faktur
- Excel, Word, PDF
- Email (Gmail, Outlook)
- Google Docs, Drive, Sheets

### 🔴 2. MEDIA SOSIAL (Social Media)
- YouTube, Instagram, TikTok, Facebook
- WhatsApp Web, Telegram
- Netflix, Spotify
- Tokopedia, Shopee, Lazada

### ⚫ 3. TIDAK TERIDENTIFIKASI (Suspicious)
- Judi Online (slot, casino, betting)
- Game Online (Mobile Legends, Free Fire, PUBG)

---

## 📊 Excel Report Structure

### Sheet 2: KPI Dashboard

| Rank | Employee | Active Hours | Work % | Social % | Suspicious % | Productivity Score | Rating |
|------|----------|--------------|--------|----------|--------------|--------------------|----|
| 1 | John Doe | 8.5 | 92% 🟢 | 7% 🔴 | 1% ⚫ | 95.5 | Excellent |
| 2 | Jane Smith | 7.8 | 85% 🟢 | 12% 🔴 | 3% ⚫ | 87.2 | Good |
| 3 | Bob K. | 7.2 | 78% 🟢 | 18% 🔴 | 4% ⚫ | 76.8 | Good |

**Simple Summary:**
```
Team Average:
- Work: 72%
- Social Media: 22%
- Suspicious: 6%
```

---

### Sheet 3: Category Breakdown (NEW)

Per employee breakdown:

```
EMPLOYEE: John Doe

DISTRIBUTION:
🟢 Pekerjaan:            92% (7h 50m)
🔴 Media Sosial:          7% (35m)
⚫ Tidak Teridentifikasi:  1% (5m)

TOP WORK ACTIVITIES:
1. accurate.id         - 2h 30m
2. coretax.pajak.go.id - 1h 45m
3. mail.google.com     - 1h 20m

TOP SOCIAL MEDIA:
1. youtube.com         - 20m
2. whatsapp.com        - 10m

SUSPICIOUS (if any):
1. slot-gacor.com      - 5m
```

---

## 📐 Formula (Simplified)

### Work Percentage
```
Work % = (Work Duration / Total Duration) × 100
```

### Productivity Score (Updated)
```
Productivity Score = (Work % × 0.7) + (Active Hours Score × 0.3)

Active Hours Score:
- 8+ hours = 100
- 6-8 hours = 80
- 4-6 hours = 50
- <4 hours = 25
```

**No Risk Score!** - Just show the percentages for manager to review.

---

## 🎯 Usage (Manager Perspective)

### During Performance Review:

**Manager:** "Saya lihat KPI kamu bulan ini..."

**Good Case:**
```
Work: 85% | Social: 12% | Suspicious: 3%
→ "Bagus! Sebagian besar waktu untuk kerja."
→ "Social media masih wajar (break time)."
```

**Need Discussion:**
```
Work: 55% | Social: 40% | Suspicious: 5%
→ "Kenapa social media 40%? Ada masalah?"
→ "Mari kita diskusi gimana cara tingkatkan produktivitas."
```

**Serious Issue:**
```
Work: 60% | Social: 20% | Suspicious: 20%
→ "Ada aktivitas mencurigakan (judi/game) 20%."
→ "Ini against company policy. Kita perlu bahas ini."
```

**Purpose:** Data sebagai **STARTING POINT** diskusi, bukan sebagai punishment otomatis.

---

## 🔧 Implementation

### 1. ActivityCategorizer Class

```php
class ActivityCategorizer
{
    protected $workKeywords = [
        'accurate', 'coretax', 'pajak.go.id', 'e-faktur',
        'excel', 'xls', 'word', 'doc', 'pdf',
        'mail.google.com', 'gmail', 'outlook',
        'docs.google.com', 'drive.google.com', 'sheets.google.com',
    ];

    protected $socialKeywords = [
        'youtube', 'instagram', 'tiktok', 'facebook',
        'whatsapp.com', 'telegram', 'netflix', 'spotify',
        'tokopedia', 'shopee', 'lazada',
    ];

    protected $suspiciousKeywords = [
        'judi', 'slot', 'casino', 'poker', 'betting',
        'mobile legends', 'ml.', 'free fire', 'freefire',
        'pubg', 'fortnite', 'steam', 'epicgames',
    ];

    public function categorize($url, $domain, $pageTitle): string
    {
        $text = strtolower($url . ' ' . $domain . ' ' . $pageTitle);

        // Check suspicious first
        foreach ($this->suspiciousKeywords as $keyword) {
            if (strpos($text, $keyword) !== false) {
                return 'suspicious';
            }
        }

        // Check work
        foreach ($this->workKeywords as $keyword) {
            if (strpos($text, $keyword) !== false) {
                return 'work';
            }
        }

        // Check social
        foreach ($this->socialKeywords as $keyword) {
            if (strpos($text, $keyword) !== false) {
                return 'social_media';
            }
        }

        // Default: work (benefit of the doubt)
        return 'work';
    }
}
```

### 2. Database Migration

```sql
-- Add column
ALTER TABLE url_activities
ADD COLUMN activity_category VARCHAR(50) DEFAULT 'work';

-- Add index
CREATE INDEX idx_activity_category
ON url_activities(activity_category);

CREATE INDEX idx_client_category
ON url_activities(client_id, activity_category);
```

### 3. Excel Export Updates

**KPIDashboardSheet:**
- Add columns: Work %, Social %, Suspicious %
- Color coding:
  - Work % > 70% = Green
  - Social % > 30% = Orange
  - Suspicious % > 10% = Red

**CategoryBreakdownSheet (NEW):**
- Per employee breakdown
- Top activities per category
- Daily trend

---

## 📊 Expected Output (Excel)

### Sheet 2: KPI Dashboard (Updated)

**Added Columns:**
- Work % (🟢)
- Social Media % (🔴)
- Suspicious % (⚫)

**Removed:**
- Risk Score (tidak perlu)
- Recommendations (tidak perlu automation)

### Sheet 3: Category Breakdown (NEW)

**Per employee:**
- Distribution pie chart data
- Top 10 work activities
- Top 10 social media activities
- List of suspicious activities (if any)

### Sheet 4-N: Individual Employees (Updated)

**Added section:**
- Category breakdown at the top
- Activities grouped by category

---

## ✅ Benefits (Simplified Approach)

1. **No False Alarms** ✅
   - Manager review data, bukan system otomatis
   - Context matters (maybe work-related YouTube tutorial)

2. **Discussion Material** ✅
   - Data jadi starting point
   - Manager + karyawan diskusi bersama
   - Explain context jika perlu

3. **Privacy Friendly** ✅
   - No automatic punishment
   - No blocking websites
   - Just reporting

4. **Flexible** ✅
   - Manager decide action case-by-case
   - Different standards per department OK
   - Context-aware decisions

---

## 🚀 Implementation Steps

### Phase 1: Backend (3 days)
1. ✅ Create ActivityCategorizer class
2. ✅ Add activity_category column
3. ✅ Migration to categorize existing data
4. ✅ Update BrowserTrackingController

### Phase 2: Excel Export (2 days)
1. ✅ Update KPIDashboardSheet (add 3% columns)
2. ✅ Create CategoryBreakdownSheet
3. ✅ Update IndividualEmployeeSheet

### Phase 3: Testing (1 day)
1. ✅ Test categorization accuracy
2. ✅ Test Excel export
3. ✅ Review sample reports

**Total: ~1 week**

---

## 📝 Notes

### Customization (Future)

Jika di kemudian hari perlu customize:

**Per Department:**
```php
// Marketing: LinkedIn, Facebook Ads = work
// Developer: GitHub, StackOverflow = work
// Finance: Accurate, Coretax = work (already included)
```

**Whitelist/Blacklist:**
```php
// Whitelist: Always work (regardless of keywords)
whitelist = ['specific-internal-tool.com']

// Blacklist: Always suspicious
blacklist = ['known-gambling-site.com']
```

But for now: **SIMPLE IS BETTER** ✅

---

## 🎯 Success Criteria

System dianggap sukses jika:

1. ✅ Manager bisa export Excel
2. ✅ Excel show 3 kategori (Work %, Social %, Suspicious %)
3. ✅ Manager bisa review per employee
4. ✅ Data akurat (keywords detected correctly)
5. ✅ No false positives yang ekstrem
6. ✅ Excel readable & easy to understand

**Purpose:** Tool untuk **DISKUSI**, bukan **PUNISHMENT** otomatis.

---

**Status:** 📋 APPROVED - Ready for Implementation
**Estimated Time:** 1 week
**Start Date:** TBD

---

## 🚀 Let's Implement!

Bro, berdasarkan confirmation lu:
- ✅ Keywords OK
- ✅ Thresholds OK
- ✅ No Risk Score
- ✅ No Actions/Automation
- ✅ Just reporting untuk catatan

**Gue langsung implement sekarang!** 🔨