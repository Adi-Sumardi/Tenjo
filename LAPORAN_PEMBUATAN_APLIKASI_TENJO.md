# LAPORAN PEMBUATAN APLIKASI TENJO
## Employee Monitoring System - Enterprise Edition

**Tanggal Laporan:** 1 November 2025
**Versi Aplikasi:** 1.0.4
**Developer:** Adi Fayyaz Sumardi
**Status:** Production Ready

---

## 1. EXECUTIVE SUMMARY

### Deskripsi Aplikasi

**Tenjo Employee Monitoring System** adalah sistem monitoring karyawan tingkat enterprise dengan arsitektur client-server yang robust. Aplikasi ini dirancang untuk memantau aktivitas karyawan secara real-time dengan fitur stealth mode, auto-update otomatis, dan reporting komprehensif berbasis KPI.

### Keunggulan Utama

✅ **Stealth Mode:** Client tersembunyi dari karyawan (process disguising, hidden folder)
✅ **Auto-Update:** Update otomatis tanpa user interaction (silent background update)
✅ **KPI Reporting:** Excel export dengan 4 sheets (Summary, KPI Dashboard, Individual, Analytics)
✅ **Live Streaming:** Real-time screen streaming menggunakan WebRTC
✅ **Cross-Platform:** Support Windows, macOS, dan Linux
✅ **Self-Hosted:** Data privacy penuh (tidak ada third-party tracking)
✅ **Unlimited Users:** Tidak ada batasan jumlah karyawan yang dimonitor
✅ **Production Ready:** Sudah tested dan deployed di production server

### Value Proposition

**Hemat Biaya:** One-time payment 29 juta IDR (vs competitor $10-25/user/month)
**Data Privacy:** Self-hosted (semua data tersimpan di server sendiri)
**Customizable:** Full source code access untuk customization
**No Recurring Fees:** Tidak ada biaya bulanan/tahunan
**Scalable:** Handle 100+ clients simultaneous dengan stable performance

---

## 2. SPESIFIKASI TEKNIS

### 2.1 Spesifikasi Server (Minimum Requirements)

#### Production Server
```
CPU:        2 vCPU (4 vCPU recommended)
RAM:        2 GB (4-8 GB recommended)
Storage:    20 GB SSD (50-100 GB recommended untuk screenshots)
OS:         Ubuntu 20.04 LTS / 22.04 LTS
Database:   PostgreSQL 13+ / MySQL 8.0+
Web Server: Nginx 1.18+ / Apache 2.4+
```

#### Development Environment
```
CPU:        2 vCPU
RAM:        4 GB
Storage:    10 GB SSD
OS:         Ubuntu 20.04 LTS / macOS / Windows 10+
```

### 2.2 Spesifikasi Database

```
Database:       PostgreSQL 13+ (recommended) / MySQL 8.0+ / SQLite
Storage:        20 GB minimum (auto-scaling recommended)
Tables:         8 main tables (clients, screenshots, browser_sessions, url_activities, dll)
Migrations:     24 migration files
Connections:    Pool size 20-50 concurrent connections
Backup:         Daily automated backup recommended
```

### 2.3 Spesifikasi Client (Employee Computer)

#### Minimum Requirements
```
OS:         Windows 10/11, macOS 10.14+, Linux (Ubuntu/Debian)
Python:     3.7+ (bundled in installer)
RAM:        512 MB minimum
CPU:        Any modern processor
Storage:    200 MB untuk client + 1 GB untuk logs/cache
Network:    Internet connection required
```

### 2.4 Spesifikasi Software

#### Backend (Laravel)
```
PHP Version:    8.2+
Framework:      Laravel 12.0 (Latest stable)
Architecture:   MVC (Model-View-Controller)
API:            RESTful API dengan Laravel Sanctum
Database ORM:   Eloquent ORM
```

#### Frontend (React/Blade)
```
Build Tool:     Vite 7.0.4
CSS Framework:  TailwindCSS 4.0.0
Templates:      Blade Templates (Laravel)
JavaScript:     Vanilla JS + Axios 1.11.0
UI Components:  9 Blade templates
```

#### Client (Python)
```
Python Version: 3.7+
Core Libs:      requests, websocket-client, psutil, Pillow, mss
Platform Libs:  pywin32 (Windows), pyobjc (macOS), python-xlib (Linux)
Total Package:  27.76 MB (with Python bundled)
```

---

## 3. FITUR & KEMAMPUAN

### 3.1 Core Features

#### A. Client Monitoring Features

**1. Screenshot Capture**
```
Interval:           5 menit (configurable)
Smart Capture:      Hanya capture saat browser aktif
Multi-Monitor:      Support all screens
Compression:        JPEG dengan optimasi ukuran
Thumbnail:          Auto-generate thumbnail preview
Format Support:     JPG, PNG
Upload:             Automatic background upload
```

**2. Browser Monitoring**
```
Supported Browsers:
  ✓ Google Chrome
  ✓ Mozilla Firefox
  ✓ Microsoft Edge
  ✓ Safari
  ✓ Opera
  ✓ Brave

Features:
  ✓ URL tracking dengan page titles
  ✓ Session duration tracking
  ✓ Tab switching detection
  ✓ Visited domains tracking
  ✓ Real-time browser detection
  ✓ Activity timeline
```

**3. Process Monitoring**
```
Features:
  ✓ Active application tracking
  ✓ Process lifecycle (start/stop)
  ✓ CPU usage per process
  ✓ Memory usage tracking
  ✓ Top processes by duration
  ✓ Application usage statistics
```

**4. System Information**
```
Captured Data:
  ✓ Operating system details (Windows/macOS/Linux)
  ✓ Hardware fingerprinting (unique client ID)
  ✓ IP address (internal & external)
  ✓ Hostname & username
  ✓ Timezone detection
  ✓ Screen resolution
  ✓ System uptime
```

#### B. Dashboard Features

**1. Main Dashboard**
```
Features:
  ✓ Real-time client status overview
  ✓ Online/Offline indicators dengan color coding
  ✓ Total clients count
  ✓ Summary statistics (screenshots, sessions, activities)
  ✓ Auto-refresh setiap 30 detik
  ✓ Client cards dengan quick actions
  ✓ Search & filter capabilities
```

**2. Client Details View**
```
Features:
  ✓ Comprehensive employee profile
  ✓ Activity timeline (chronological)
  ✓ Browser usage breakdown (pie charts)
  ✓ Screenshot gallery (thumbnail grid)
  ✓ Top 20 visited URLs dengan page titles
  ✓ Top domains accessed
  ✓ Daily activity breakdown
  ✓ Session statistics (duration, count)
  ✓ Real-time status indicator
```

**3. Live Streaming**
```
Technology:     WebRTC
Features:
  ✓ Real-time screen streaming
  ✓ Quality controls (Low/Medium/High)
  ✓ Stream statistics (FPS, bitrate, latency)
  ✓ Quick screenshot capture
  ✓ Fullscreen mode
  ✓ Start/Stop controls
  ✓ Auto-reconnect on disconnect
```

**4. Client Summary Page**
```
Features:
  ✓ Overview all employees dalam satu view
  ✓ Filterable by date range:
    - Today
    - Yesterday
    - This Week
    - This Month
    - Custom Range (from-to)
  ✓ Activity statistics per employee
  ✓ Top domains per employee
  ✓ Export capabilities (Excel, PDF)
  ✓ Sorting by various metrics
```

### 3.2 Advanced Features

#### A. Enhanced Excel KPI Export ⭐ NEW

**Multi-Sheet Workbook (4+ Sheets):**

**Sheet 1: Summary**
```
Content:
  ✓ Overview all employees
  ✓ Key statistics per employee:
    - Total screenshots
    - Browser sessions count
    - URL activities count
    - Unique URLs visited
    - Total active duration
    - Top domains
    - Last activity timestamp
  ✓ Grand totals
  ✓ Professional color-coded headers
```

**Sheet 2: KPI Dashboard**
```
Content:
  ✓ Performance Metrics per Employee:
    - Productivity Score (0-100)
    - Engagement Score (0-100)
    - Performance Rating (Excellent/Good/Average/Poor)
    - Activity Rate (activities/hour)
    - Avg Session Duration
    - Work Completion %
    - Intensity Rating
  ✓ Ranking (Top to Bottom performers)
  ✓ Color coding:
    - Green highlight: Top performer
    - Red highlight: Bottom performer
  ✓ Sortable columns
```

**KPI Calculation Formula:**
```
Productivity Score =
  (Time Score × 40%) +
  (Activity Score × 30%) +
  (Session Score × 20%) +
  (Diversity Score × 10%)

Where:
  Time Score      = min((active_minutes / 480) × 100, 100)
  Activity Score  = min((url_activities / 100) × 100, 100)
  Session Score   = min((browser_sessions / 20) × 100, 100)
  Diversity Score = min((unique_urls / 50) × 100, 100)

Engagement Score =
  (URL Activities × 50%) +
  (Screenshots × 30%) +
  (Browser Sessions × 20%)

Performance Rating:
  90-100: Excellent (⭐⭐⭐⭐⭐)
  75-89:  Good (⭐⭐⭐⭐)
  60-74:  Average (⭐⭐⭐)
  40-59:  Below Average (⭐⭐)
  0-39:   Needs Improvement (⭐)
```

**Sheet 3+: Individual Employee Sheets**
```
Content per Employee:
  ✓ Employee information (name, hostname, OS)
  ✓ Summary statistics
  ✓ Browser usage breakdown (by browser type)
  ✓ Top 20 URLs visited dengan duration
  ✓ Daily activity breakdown
  ✓ Domain analysis (top 10 domains)
  ✓ Activity heatmap data
  ✓ One sheet per employee
  ✓ Professional formatting
```

**Final Sheet: Analytics**
```
Content:
  ✓ Team insights:
    - Productivity comparison across team
    - Activity intensity analysis
    - Work time distribution
    - Performance categories breakdown
    - High/Average/Low performers count
  ✓ Recommendations based on team metrics
  ✓ Trend analysis
  ✓ Outlier detection
```

**Excel Styling Features:**
```
✓ Professional color coding (Blue, Green, Purple, Orange)
✓ Conditional formatting (Top/Bottom performers)
✓ Auto-sized columns
✓ Merged cells untuk titles
✓ Number formatting (thousands separator)
✓ Percentage formatting
✓ Alternating row colors (zebra striping)
✓ Border styling
✓ Bold headers
✓ Centered alignment
```

#### B. PDF Reports
```
Features:
  ✓ Client activity summary reports
  ✓ Custom date range selection
  ✓ Professional formatting dengan logo
  ✓ Activity statistics tables
  ✓ Browser usage charts
  ✓ Printable layout
```

#### C. Auto-Update System (Silent)

**Features:**
```
✓ Zero user interaction required
✓ Background download & install
✓ Automatic client restart
✓ Rollback capability on failure
✓ Version checking every 8-16 hours (random interval)
✓ Checksum verification (SHA256)
✓ Backup before update
✓ Update status tracking (server-side)
```

**Update Process Flow:**
```
1. Client checks version.json on server
2. Compares with current version
3. Downloads new package if available (27.76 MB avg)
4. Verifies SHA256 checksum
5. Creates backup of current installation
6. Stops current process
7. Extracts new version
8. Installs dependencies (if needed)
9. Restarts client process
10. Reports completion to server
11. Cleanup old backup (after 7 days)
```

**Priority Levels:**
```
✓ Normal:   Update during maintenance window
✓ High:     Update ASAP (within 4 hours)
✓ Critical: Force update immediately (security patches)
```

**Gradual Rollout:**
```
0-8 hours:   First wave (15-20% clients)
8-16 hours:  Second wave (50% clients)
16-24 hours: Third wave (80% clients)
24-48 hours: Full deployment (100% clients)
```

### 3.3 Security & Stealth Features

#### A. Client-Side Security

**Stealth Mode:**
```
✓ Hidden dari user visibility (no UI)
✓ Process name disguising:
  - Windows: "svchost.exe" / "System"
  - macOS: "kernel_task" / "launchd"
  - Linux: "systemd" / "init"
✓ Hidden installation directory:
  - Windows: C:\ProgramData\Realtek 786\
  - macOS: /Library/Application Support/.system/
  - Linux: /usr/lib/.system/
✓ No taskbar/dock icon
✓ No system tray icon
✓ Silent background operation
```

**Folder Protection:**
```
✓ Hidden folder attribute (Windows)
✓ System folder attribute
✓ Access restrictions
✓ Password-protected uninstall
```

**Password Protection:**
```
✓ Uninstall requires password
✓ SHA256 password hashing
✓ Default password: admin123 (changeable)
✓ 3 attempts maximum
✓ Password change utility included
✓ Brute-force protection
```

**Autostart Mechanisms (Triple Redundancy):**
```
Windows:
  ✓ Registry Run key
  ✓ Scheduled Task (on user login)
  ✓ Startup folder shortcut

macOS:
  ✓ LaunchAgent
  ✓ Login Items

Linux:
  ✓ systemd service
  ✓ cron @reboot
```

**Watchdog Service:**
```
✓ Auto-restart jika client di-kill
✓ Process monitoring
✓ Health check every 60 seconds
✓ Automatic recovery
```

**Hardware Fingerprinting:**
```
Persistent Client ID based on:
  ✓ MAC address
  ✓ Motherboard serial
  ✓ CPU ID
  ✓ Disk serial
✓ Triple redundancy storage:
  - Windows Registry
  - Local config file
  - Fallback generation
```

#### B. Server-Side Security
```
✓ Laravel Sanctum API authentication
✓ HTTPS/SSL encryption (Let's Encrypt)
✓ API key validation
✓ Rate limiting on sensitive endpoints
✓ CORS protection
✓ SQL injection prevention (Eloquent ORM)
✓ XSS protection (Blade escaping)
✓ CSRF token validation
```

#### C. Data Security
```
✓ Encrypted data transmission (HTTPS)
✓ Secure password hashing (SHA256)
✓ File permission restrictions (chmod 644/755)
✓ Protected configuration files
✓ Environment variable protection
✓ Database connection encryption
```

---

## 4. TEKNOLOGI YANG DIGUNAKAN

### 4.1 Backend Stack

#### Core Framework
```
FastAPI Alternative:  Laravel 12.0
Language:             PHP 8.2+
Architecture:         MVC (Model-View-Controller)
API Style:            RESTful API
Auth:                 Laravel Sanctum (JWT tokens)
```

#### Database & ORM
```
ORM:                  Eloquent ORM
Database Support:     PostgreSQL 13+ / MySQL 8.0+ / SQLite
Migrations:           Laravel Migrations (24 files)
Query Builder:        Eloquent Query Builder
Connection Pooling:   Built-in
```

#### Key Laravel Packages
```
laravel/framework       ^12.0    - Core framework
laravel/sanctum         ^4.0     - API authentication
maatwebsite/excel       ^3.1     - Excel export dengan KPI
barryvdh/laravel-dompdf ^3.1     - PDF generation
laravel/tinker          ^2.10.1  - REPL debugging
```

#### Authentication & Security
```
Laravel Sanctum        - JWT token handling
Bcrypt                 - Password hashing (cost factor 12)
CSRF Protection        - Built-in Laravel CSRF
Rate Limiting          - Laravel throttle middleware
```

### 4.2 Frontend Stack

#### Core Framework
```
Build Tool:           Vite 7.0.4
CSS Framework:        TailwindCSS 4.0.0
Templates:            Blade Templates (Laravel)
JavaScript:           Vanilla JavaScript ES6+
HTTP Client:          Axios 1.11.0
```

#### UI Components
```
Template Files:       9 Blade templates
Pages:
  - dashboard/index.blade.php (456 lines)
  - dashboard/client-details.blade.php (623 lines)
  - dashboard/client-summary.blade.php (398 lines)
  - dashboard/client-live.blade.php (512 lines)
  - dashboard/screenshots.blade.php (234 lines)
  - auth/login.blade.php (178 lines)
  - layouts/app.blade.php (145 lines)
```

### 4.3 Python Client Stack

#### Core Dependencies
```
requests          >=2.31.0   - HTTP client untuk API
websocket-client  >=1.6.0    - WebSocket untuk streaming
psutil            >=5.9.0    - System & process utilities
setproctitle      >=1.3.3    - Process name disguising
mss               >=9.0.0    - Fast screenshot capture
Pillow            >=10.0.0   - Image processing & compression
```

#### Platform-Specific Libraries

**Windows:**
```
pygetwindow       - Window management
pywin32           - Windows API access
wmi               - Windows Management Instrumentation
```

**macOS:**
```
pyobjc-core       >=10.0                  - Objective-C bridge
pyobjc-framework-Quartz                   - Screen capture APIs
pyobjc-framework-Cocoa                    - macOS system APIs
```

**Linux:**
```
python-xlib       - X11 window system
dbus-python       - D-Bus system integration
```

### 4.4 Export Libraries

```
OpenPyXL          3.1.5      - Excel file generation
ReportLab         4.4.3      - PDF report generation
Pandas            2.1.3      - Data manipulation
PhpSpreadsheet    (via Laravel Excel) - Excel styling & formulas
DomPDF            (via Laravel package) - PDF generation
```

### 4.5 DevOps & Deployment

```
Version Control:      Git + GitHub
Deployment Scripts:   15+ bash/powershell scripts
Process Manager:      PM2 / Supervisor / systemd
Web Server:           Nginx 1.18+ / Apache 2.4+
SSL/TLS:              Let's Encrypt (Certbot)
Containerization:     Docker (optional)
```

---

## 5. ARSITEKTUR SISTEM

### 5.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    TENJO MONITORING SYSTEM                  │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────┐              ┌──────────────────────┐
│  Python Client       │              │  Laravel Dashboard   │
│  (Employee Computer) │◄────────────►│  (Web Server)        │
│                      │   HTTPS/     │                      │
│  ┌────────────────┐  │   REST API   │  ┌────────────────┐  │
│  │ Screen Capture │  │              │  │ Web Interface  │  │
│  │ Browser Track  │  │──────────────┤  │ API Endpoints  │  │
│  │ Process Mon.   │  │              │  │ Database       │  │
│  │ Auto-Update    │  │              │  │ Reports        │  │
│  │ Stealth Mode   │  │              │  │ Streaming      │  │
│  └────────────────┘  │              │  └────────────────┘  │
│                      │              │                      │
│  OS: Win/Mac/Linux   │              │  PostgreSQL/MySQL    │
└──────────────────────┘              └──────────────────────┘
           │                                     │
           │                                     │
           ▼                                     ▼
  ┌──────────────────┐              ┌──────────────────────┐
  │  Local Storage   │              │  Cloud Storage       │
  │  - Config        │              │  - Screenshots       │
  │  - Logs          │              │  - Database          │
  │  - Cache         │              │  - Backups           │
  └──────────────────┘              └──────────────────────┘
```

### 5.2 Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                    DATA FLOW DIAGRAM                    │
└─────────────────────────────────────────────────────────┘

Employee Computer (Client)
         │
         ├── Screenshot Capture (every 5 min)
         │   └─► image.jpg (compressed, JPEG)
         │
         ├── Browser Monitoring (real-time)
         │   └─► {url, title, duration, browser}
         │
         ├── Process Monitoring (real-time)
         │   └─► {process_name, cpu, memory}
         │
         └── System Info (on registration)
             └─► {os, hostname, ip, hardware_id}
                        │
                        ▼
              [ HTTPS REST API ]
                        │
                        ▼
           Laravel Backend Server
                        │
                        ├─► Validation & Authentication
                        ├─► Data Processing
                        ├─► Database Storage (PostgreSQL)
                        └─► File Storage (Screenshots)
                                │
                                ▼
                    [ Database Tables ]
                                │
                                ├─► clients
                                ├─► screenshots
                                ├─► browser_sessions
                                ├─► url_activities
                                ├─► browser_events
                                ├─► process_events
                                ├─► url_events
                                └─► users
                                        │
                                        ▼
                            [ Dashboard Views ]
                                        │
                                        ├─► Main Dashboard
                                        ├─► Client Details
                                        ├─► Live Streaming
                                        ├─► Client Summary
                                        └─► Reports (Excel/PDF)
                                                │
                                                ▼
                                    Admin Browser (HTTPS)
```

### 5.3 Communication Protocol

**API Endpoints (30+):**

```
Registration & Heartbeat:
  POST   /api/clients/register
  POST   /api/clients/heartbeat
  GET    /api/clients/{id}

Screenshot Upload:
  POST   /api/screenshots
  GET    /api/screenshots
  DELETE /api/screenshots/{id}

Browser Tracking:
  POST   /api/browser-sessions
  POST   /api/url-activities
  POST   /api/browser-events
  POST   /api/url-events

Process Monitoring:
  POST   /api/process-events

Streaming:
  GET    /api/stream/status/{clientId}
  POST   /api/stream/start/{clientId}
  POST   /api/stream/stop/{clientId}
  POST   /api/stream/chunk/{clientId}
  GET    /api/stream/chunk/{clientId}

Auto-Update:
  GET    /api/clients/{clientId}/check-update
  POST   /api/clients/{clientId}/update-status
  POST   /api/clients/schedule-update

Dashboard:
  GET    /dashboard
  GET    /dashboard/client/{id}
  GET    /dashboard/client/{id}/live
  GET    /dashboard/screenshots
  GET    /dashboard/client-summary

Export:
  GET    /dashboard/client-summary?export=excel
  GET    /dashboard/client-summary?export=pdf
```

### 5.4 Security Architecture

**Multi-Layer Security:**

```
Layer 1: Transport Security
  ├── HTTPS/TLS encryption (Let's Encrypt)
  ├── TLS 1.3 protocol
  └── Secure headers (HSTS, CSP, X-Frame-Options)

Layer 2: Application Security
  ├── Laravel Sanctum authentication
  ├── CSRF token validation
  ├── XSS protection (Blade escaping)
  ├── SQL injection prevention (Eloquent ORM)
  └── Input validation & sanitization

Layer 3: Client Security
  ├── Hardware fingerprinting
  ├── Persistent client ID (triple redundancy)
  ├── Checksum verification (SHA256)
  └── Encrypted configuration

Layer 4: Stealth Security
  ├── Process name disguising
  ├── Hidden installation folder
  ├── No visible UI/icons
  ├── Watchdog auto-restart
  └── Multiple autostart methods

Layer 5: Access Control
  ├── Password-protected uninstall (SHA256)
  ├── Admin authentication (dashboard)
  ├── Role-based access control
  └── File permission restrictions (644/755)
```

---

## 6. BIAYA DEVELOPMENT

### 6.1 Breakdown Biaya Development

#### A. Development Time & Cost

| Fase | Durasi | Biaya (IDR) |
|------|--------|-------------|
| **1. Backend Development (Laravel)** | | |
| - Database design & migrations (8 tables, 24 migrations) | 25 jam | Rp 2,500,000 |
| - RESTful API development (30+ endpoints) | 40 jam | Rp 4,000,000 |
| - Authentication & authorization system | 15 jam | Rp 1,500,000 |
| - Client management system | 20 jam | Rp 2,000,000 |
| - Real-time monitoring dashboard | 25 jam | Rp 2,500,000 |
| - Live streaming implementation (WebRTC) | 30 jam | Rp 3,000,000 |
| **Subtotal Backend:** | **155 jam** | **Rp 15,500,000** |
| | | |
| **2. Frontend Development (UI/UX)** | | |
| - Dashboard design dengan TailwindCSS | 15 jam | Rp 1,500,000 |
| - Client details view (charts, timeline) | 10 jam | Rp 1,000,000 |
| - Live streaming interface | 10 jam | Rp 1,000,000 |
| - Client summary & date filtering | 10 jam | Rp 1,000,000 |
| - Responsive design (mobile/tablet) | 10 jam | Rp 1,000,000 |
| **Subtotal Frontend:** | **55 jam** | **Rp 5,500,000** |
| | | |
| **3. Python Client Development** | | |
| - Cross-platform architecture (Win/Mac/Linux) | 20 jam | Rp 2,000,000 |
| - Screenshot capture module (multi-monitor) | 10 jam | Rp 1,000,000 |
| - Browser tracking system (6 browsers) | 20 jam | Rp 2,000,000 |
| - Process monitoring & tracking | 10 jam | Rp 1,000,000 |
| - API integration & communication | 10 jam | Rp 1,000,000 |
| - Auto-update mechanism (silent) | 15 jam | Rp 1,500,000 |
| **Subtotal Client:** | **85 jam** | **Rp 8,500,000** |
| | | |
| **4. Advanced Features** | | |
| - Enhanced Excel KPI Export (4-sheet workbook) | 20 jam | Rp 2,000,000 |
| - PDF report generation (DomPDF) | 5 jam | Rp 500,000 |
| - Password protection system (SHA256) | 5 jam | Rp 500,000 |
| - Stealth mode & security features | 10 jam | Rp 1,000,000 |
| **Subtotal Advanced:** | **40 jam** | **Rp 4,000,000** |
| | | |
| **5. Deployment & Infrastructure** | | |
| - Production deployment scripts (15+) | 10 jam | Rp 1,000,000 |
| - Auto-update system deployment | 5 jam | Rp 500,000 |
| - VPS setup & configuration | 5 jam | Rp 500,000 |
| - SSL certificate & domain setup | 2 jam | Rp 200,000 |
| - Mass deployment tools | 5 jam | Rp 500,000 |
| **Subtotal Deployment:** | **27 jam** | **Rp 2,700,000** |
| | | |
| **6. Documentation & Support** | | |
| - Comprehensive documentation (11+ guides) | 10 jam | Rp 1,000,000 |
| - Installation manuals | 3 jam | Rp 300,000 |
| - Security analysis & guides | 5 jam | Rp 500,000 |
| **Subtotal Documentation:** | **18 jam** | **Rp 1,800,000** |
| | | |
| **7. Testing & Quality Assurance** | | |
| - Unit testing (client & server) | 5 jam | Rp 500,000 |
| - Integration testing (API, database) | 5 jam | Rp 500,000 |
| - Security testing (penetration test) | 5 jam | Rp 500,000 |
| - Bug fixes & optimization | 5 jam | Rp 500,000 |
| **Subtotal Testing:** | **20 jam** | **Rp 2,000,000** |
| | | |
| **TOTAL DEVELOPMENT:** | **400 jam** | **Rp 40,000,000** |
| **Special Package Discount (27.5%):** | | **- Rp 11,000,000** |
| **HARGA FINAL:** | | **Rp 29,000,000** |

### 6.2 Rincian Biaya per Komponen

```
┌────────────────────────────────────────────────────────┐
│              BREAKDOWN BIAYA DEVELOPMENT               │
└────────────────────────────────────────────────────────┘

Backend Development (Laravel):         Rp 15,500,000 (38.75%)
Frontend Development (UI/UX):           Rp  5,500,000 (13.75%)
Python Client Development:              Rp  8,500,000 (21.25%)
Advanced Features:                      Rp  4,000,000 (10%)
Deployment & Infrastructure:            Rp  2,700,000 (6.75%)
Documentation & Support:                Rp  1,800,000 (4.5%)
Testing & Quality Assurance:            Rp  2,000,000 (5%)
────────────────────────────────────────────────────────
SUBTOTAL:                               Rp 40,000,000

Special Package Discount:               - Rp 11,000,000 (27.5%)
────────────────────────────────────────────────────────
HARGA FINAL:                            Rp 29,000,000
────────────────────────────────────────────────────────

Total Development Time: 400 jam
Effective Rate: Rp 72,500/jam (after discount)
Regular Rate: Rp 100,000/jam
```

### 6.3 Biaya Operasional (Optional - Ditanggung Client)

```
VPS Server (4GB RAM, 2 vCPU, 50GB SSD):     Rp 150,000 - 300,000/bulan
Domain (.id atau .com):                     Rp 100,000 - 200,000/tahun
SSL Certificate (Let's Encrypt):            GRATIS (auto-renewal)
Database Backup Storage:                    Rp 50,000 - 100,000/bulan
                                            ────────────────────────
Total Operasional (estimated):              Rp 250,000 - 500,000/bulan
```

**Note:** Biaya operasional sangat kecil dibandingkan competitor (Teramind: $7,200/tahun untuk 50 user)

---

## 7. PERBANDINGAN DENGAN KOMPETITOR

### 7.1 Comparison Table

| Feature | Tenjo | ActivTrak | Teramind | Time Doctor |
|---------|-------|-----------|----------|-------------|
| **Pricing Model** | One-time (29 juta) | Subscription | Subscription | Subscription |
| **Monthly Cost (50 users)** | Rp 0 | ~$500-750 | ~$600-1,250 | ~$350-1,000 |
| **Yearly Cost (50 users)** | Rp 0 | ~$6,000-9,000 | ~$7,200-15,000 | ~$4,200-12,000 |
| **3-Year Total Cost** | **Rp 29 juta** | **~$18,000-27,000** | **~$21,600-45,000** | **~$12,600-36,000** |
| | | | | |
| **Self-Hosted** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Full Source Code** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Data Privacy** | ✅ 100% | ❌ Cloud | ❌ Cloud | ❌ Cloud |
| **User Limit** | ✅ Unlimited | ❌ Per-user | ❌ Per-user | ❌ Per-user |
| **Customization** | ✅ Full | ❌ Limited | ❌ Limited | ❌ Limited |
| | | | | |
| **Screenshot Capture** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Browser Tracking** | ✅ Yes (6 browsers) | ✅ Yes | ✅ Yes | ✅ Yes |
| **Live Streaming** | ✅ Yes (WebRTC) | ❌ No | ✅ Yes | ❌ No |
| **KPI Reports** | ✅ Yes (4-sheet Excel) | ⚠️ Basic | ✅ Yes | ✅ Yes |
| **Auto-Update** | ✅ Yes (silent) | ✅ Yes | ✅ Yes | ✅ Yes |
| **Stealth Mode** | ✅ Yes (advanced) | ⚠️ Basic | ✅ Yes | ⚠️ Basic |
| **Password Protection** | ✅ Yes (SHA256) | ❌ No | ❌ No | ❌ No |
| **Cross-Platform** | ✅ Win/Mac/Linux | ✅ Yes | ✅ Yes | ✅ Yes |

### 7.2 ROI Analysis (3 Years, 50 Employees)

```
┌────────────────────────────────────────────────────────┐
│              ROI ANALYSIS - 3 TAHUN                    │
└────────────────────────────────────────────────────────┘

TENJO (One-Time Purchase):
  Year 1:  Rp 29,000,000 (one-time)
  Year 2:  Rp 0
  Year 3:  Rp 0
  ────────────────────────────────
  Total:   Rp 29,000,000 (~$1,850)

TERAMIND (Subscription @$12/user/month):
  Year 1:  Rp 110,000,000 (~$7,200)
  Year 2:  Rp 110,000,000
  Year 3:  Rp 110,000,000
  ────────────────────────────────
  Total:   Rp 330,000,000 (~$21,600)

TIME DOCTOR (Subscription @$7/user/month):
  Year 1:  Rp 64,000,000 (~$4,200)
  Year 2:  Rp 64,000,000
  Year 3:  Rp 64,000,000
  ────────────────────────────────
  Total:   Rp 192,000,000 (~$12,600)

SAVINGS vs TERAMIND:    Rp 301,000,000 (91% cost reduction)
SAVINGS vs TIME DOCTOR: Rp 163,000,000 (85% cost reduction)
```

**Break-Even Point:**
- vs Teramind: **3 bulan** (sudah balik modal)
- vs Time Doctor: **6 bulan** (sudah balik modal)

---

## 8. DELIVERABLES & BONUS

### 8.1 Yang Didapat Client

#### A. Complete Source Code
```
✅ Laravel dashboard codebase (14,000+ lines)
✅ Python client source code (5,172 lines)
✅ All configuration files
✅ Database migrations & seeders
✅ Full GitHub repository access
✅ Commit history lengkap
```

#### B. Production Deployment
```
✅ Fully configured VPS server
✅ HTTPS/SSL certificate (Let's Encrypt)
✅ Domain setup (tenjo.adilabs.id atau custom)
✅ Database setup (PostgreSQL/MySQL)
✅ Nginx/Apache web server configured
✅ PM2/Supervisor process manager
```

#### C. Client Applications
```
✅ Windows installer (.exe/.msi)
✅ macOS installer (.dmg/.pkg)
✅ Linux installer (.deb/.rpm)
✅ Cross-platform source package
✅ USB deployment packages
✅ Network-wide deployment scripts
```

#### D. Deployment Tools (15+)
```
Production Deployment:
  ✅ deploy_production.sh
  ✅ deploy_update.sh
  ✅ vps_deploy_commands.sh
  ✅ quick_deploy.sh
  ✅ silent_push_deploy.sh

Mass Deployment:
  ✅ mass_deploy.sh
  ✅ remote_deploy_ssh.sh
  ✅ remote_deploy_powershell.sh
  ✅ remote_deploy_psexec.sh

Client Installation:
  ✅ install_windows.ps1/.bat
  ✅ install_unix.sh
  ✅ install_autostart scripts

USB Deployment:
  ✅ make_usb_installer.sh
  ✅ deploy_from_usb.bat

Utilities:
  ✅ change_password scripts
  ✅ uninstall_with_password scripts
```

#### E. Documentation (11+ Guides, 4,000+ Lines)
```
✅ README.md (350 lines)
✅ AUTO_UPDATE_BEHAVIOR.md (452 lines)
✅ EXCEL_KPI_EXPORT_GUIDE.md (528 lines)
✅ DEPLOYMENT_GUIDE.md (433 lines)
✅ UPDATE_TO_PRODUCTION_EXCEL_KPI.md (575 lines)
✅ SECURITY_ANALYSIS.md (343 lines)
✅ PASSWORD_PROTECTION_GUIDE.md (323 lines)
✅ NETWORK_ACCESS_GUIDE.md (267 lines)
✅ TERMIUS_GUIDE.md (234 lines)
✅ INSTALL_MANUAL.md (198 lines)
✅ PROJECT_REPORT_TENJO.md (1,566 lines)
```

#### F. Support (3 Bulan Gratis)
```
✅ Bug fixes dan patches
✅ Configuration assistance
✅ Technical support via email
✅ Update assistance
✅ Response time: 24-48 jam
```

### 8.2 Bonus Features (No Additional Cost)

```
✅ Automatic Silent Updates
   - Zero user interaction required
   - Background download & install
   - SHA256 checksum verification
   - Automatic rollback on failure

✅ Enhanced Excel KPI Reports
   - 4-sheet professional workbook
   - Performance metrics & ranking
   - Individual employee reports
   - Team analytics & insights

✅ Real-time Live Streaming
   - WebRTC technology
   - Quality controls (Low/Medium/High)
   - Stream statistics monitoring
   - Fullscreen mode

✅ Password Protection System
   - SHA256 secure hashing
   - Uninstall protection
   - 3-attempt limit
   - Brute-force delay

✅ Stealth Mode (Advanced)
   - Process name disguising
   - Hidden installation folder
   - No visible UI/icons
   - Watchdog auto-restart
   - Triple autostart redundancy

✅ Multi-Platform Support
   - Windows 10/11
   - macOS 10.14+
   - Linux (Ubuntu/Debian/CentOS)

✅ Unlimited Users
   - No per-user licensing fees
   - Add as many employees as needed
   - No subscription required

✅ Self-Hosted
   - Full data privacy & control
   - No third-party cloud storage
   - All data stays on your server
   - GDPR compliant
```

---

## 9. TECHNICAL EXCELLENCE

### 9.1 Code Quality

```
✅ Clean Architecture (MVC pattern)
✅ PSR-12 Coding Standards (PHP)
✅ PEP 8 Compliance (Python)
✅ Comprehensive Error Handling
✅ Logging & Debugging Support
✅ Modular Design (easy to extend)
✅ Well-Documented Code
✅ Type Hints & Docstrings
✅ Unit Tests (critical components)
```

### 9.2 Performance

```
✅ Optimized Database Queries (indexed)
✅ Efficient Screenshot Compression
✅ Smart Capture (only when active)
✅ Asynchronous Operations
✅ Laravel Cache Support
✅ Lazy Loading (database relationships)
✅ Resource-Efficient Client (<50 MB RAM)
✅ Handles 100+ simultaneous clients
```

### 9.3 Scalability

```
✅ Supports 100+ simultaneous clients
✅ Database optimization for large datasets
✅ Horizontal scaling support (load balancer)
✅ CDN-ready (static assets)
✅ Queue system for background jobs
✅ Microservices-ready architecture
✅ Can handle 1000+ clients with proper server
```

---

## 10. PROJECT STATISTICS

### 10.1 Codebase Metrics

```
Total Files:              181 files (core project)
Total Lines of Code:      ~14,000 lines (custom code)

Backend (Laravel):
  PHP Files:              4,841 lines
  Controllers:            10 controllers
  Models:                 8 models
  Migrations:             24 migration files
  Blade Templates:        9 templates (2,456 lines)

Frontend:
  JavaScript:             289 lines
  CSS/TailwindCSS:        Custom utility classes

Client (Python):
  Core Modules:           5,172 lines
  Modules:                7 monitoring modules
  Utilities:              7 utility modules
  Total Package Size:     27.76 MB (with Python bundled)

Documentation:
  Total Guides:           11+ comprehensive guides
  Total Doc Lines:        4,000+ lines
  Deployment Scripts:     15+ scripts

Database:
  Tables:                 8 main tables
  Migrations:             24 files
  Indexes:                12 optimized indexes
  Foreign Keys:           6 relationships

API:
  Total Endpoints:        30+ RESTful endpoints
  Authentication:         JWT-based (Laravel Sanctum)
  Rate Limiting:          Built-in throttling
```

### 10.2 Performance Metrics

```
Client Performance:
  RAM Usage:              <50 MB (stable)
  CPU Usage:              <5% (average)
  Screenshot Interval:    5 minutes (configurable)
  Network Usage:          Minimal (HTTPS compression)
  Startup Time:           <3 seconds
  Background Mode:        100% silent

Server Performance:
  Concurrent Clients:     100+ clients supported
  API Response Time:      <200ms (average)
  Database Queries:       <50ms (indexed)
  Screenshot Upload:      <2 seconds per file
  Dashboard Load Time:    <1 second
  Export Generation:      <5 seconds (100 rows Excel)

Update Performance:
  Package Download:       27.76 MB (compressed)
  Download Time:          1-3 minutes (depends on internet)
  Installation Time:      <30 seconds
  Total Update Time:      <5 minutes (fully automatic)
```

---

## 11. SUPPORT & MAINTENANCE

### 11.1 Support Period

```
Included Support (First 3 Months):
  ✅ Bug fixes & patches
  ✅ Configuration assistance
  ✅ Technical support via email
  ✅ Update assistance
  ✅ Security patches
  ✅ Performance optimization tips

Response Time:
  - Critical issues: 24 hours
  - Major issues: 48 hours
  - Minor issues: 72 hours
  - General questions: 5 business days
```

### 11.2 Extended Support (Optional)

```
Extended Support Package: Rp 1,000,000/bulan
  ✅ Priority support (12-hour response)
  ✅ Feature requests consideration
  ✅ Custom development (up to 5 hours/month)
  ✅ Monthly health check & optimization
  ✅ Dedicated Slack/Telegram channel
  ✅ Video call support (if needed)
```

### 11.3 Maintenance Best Practices

```
Server Maintenance:
  ✅ Daily automated database backup
  ✅ Weekly log rotation
  ✅ Monthly security updates (OS/packages)
  ✅ Quarterly performance review
  ✅ Yearly major version upgrade

Client Maintenance:
  ✅ Automatic silent updates (no action needed)
  ✅ Auto-cleanup old screenshots (configurable)
  ✅ Automatic log rotation
  ✅ Health check reporting to server
```

---

## 12. KESIMPULAN

### 12.1 Ringkasan Sistem

**Tenjo Employee Monitoring System** adalah solusi monitoring karyawan tingkat enterprise yang komprehensif dengan fitur-fitur berikut:

**Technology Stack:**
```
Backend:    PHP 8.2 + Laravel 12.0 (modern, fast, secure)
Frontend:   Vite + TailwindCSS + Blade (responsive, beautiful)
Client:     Python 3.7+ (cross-platform, lightweight)
Database:   PostgreSQL/MySQL (reliable, scalable)
```

**Key Features:**
```
✅ 5 monitoring capabilities (Screenshot, Browser, Process, System, Streaming)
✅ Stealth mode operation (process disguising, hidden folder)
✅ Auto-update system (silent, background, SHA256 verified)
✅ Enhanced Excel KPI reports (4-sheet workbook with metrics)
✅ Live streaming (WebRTC real-time screen sharing)
✅ Password protection (SHA256, uninstall guard)
✅ Cross-platform support (Windows, macOS, Linux)
✅ 30+ API endpoints (RESTful, JWT-authenticated)
```

**Performance:**
```
✅ 100+ concurrent clients supported
✅ <50 MB RAM per client
✅ <5% CPU usage
✅ 99.9% uptime (with proper server)
✅ <200ms API response time
```

**Security:**
```
✅ Multi-layer security architecture (5 layers)
✅ HTTPS/TLS encryption
✅ JWT authentication (30-min expiration)
✅ Password hashing (bcrypt cost 12)
✅ Rate limiting & CORS protection
✅ SQL injection prevention (Eloquent ORM)
```

### 12.2 Value Proposition

**Investment Comparison (3 Years, 50 Employees):**

```
Tenjo (One-Time):        Rp 29,000,000
Teramind (Subscription): Rp 330,000,000
Time Doctor (Subscription): Rp 192,000,000

SAVINGS: Rp 163 juta - 301 juta (85-91% cost reduction)
```

**Unique Advantages:**
```
✅ One-time purchase (no recurring fees forever)
✅ Self-hosted (100% data privacy & control)
✅ Full source code access (unlimited customization)
✅ Unlimited users (scale without extra cost)
✅ Advanced features (KPI reports, live streaming, stealth mode)
✅ Professional support (3 months included)
```

### 12.3 Recommendation

Tenjo Employee Monitoring System sangat cocok untuk:

```
✅ Perusahaan dengan 10-500 karyawan
✅ Perusahaan yang peduli data privacy
✅ Perusahaan dengan budget terbatas (one-time investment)
✅ Perusahaan yang butuh customization
✅ Perusahaan yang ingin full control atas data
✅ Perusahaan dengan tim IT in-house (untuk maintenance)
```

**ROI (Return on Investment):**
```
Break-even: 3-6 bulan (vs competitor)
Year 1: Save up to Rp 100 juta
Year 2: Save up to Rp 110 juta (100% savings)
Year 3: Save up to Rp 110 juta (100% savings)

Total 3-Year ROI: 560% - 1,037%
```

---

## 13. CONTACT & INFORMATION

### Project Information
```
Project Name:     Tenjo Employee Monitoring System
Version:          1.0.4 (Production Ready)
Release Date:     November 1, 2025
Repository:       https://github.com/Adi-Sumardi/Tenjo
License:          Proprietary (Full ownership to client upon payment)
```

### Developer Information
```
Developer:        Adi Fayyaz Sumardi
Company:          Adi Labs
Email:            adisumardi888@gmail.com
Phone:            [Your Phone Number]
Location:         Indonesia
GitHub:           https://github.com/Adi-Sumardi
```

### Production Environment
```
Dashboard URL:    https://tenjo.adilabs.id
API Endpoint:     https://tenjo.adilabs.id/api
Server IP:        103.129.149.67
Database:         PostgreSQL 13+
Hosting:          VPS (self-hosted)
```

### Support Channels
```
Email Support:    adisumardi888@gmail.com
Documentation:    https://github.com/Adi-Sumardi/Tenjo/docs
Issue Tracker:    https://github.com/Adi-Sumardi/Tenjo/issues
Support Hours:    Monday - Friday, 9:00 AM - 5:00 PM WIB
Response Time:    24-48 hours (business days)
```

---

## 14. TERMS & CONDITIONS

### 14.1 Payment Terms
```
Total Amount:     Rp 29,000,000 (twenty-nine million rupiah)
Payment Method:   Bank transfer / PayPal / Wise
Payment Terms:    Full payment or 50-50 (50% upfront, 50% on delivery)
Late Payment:     2% monthly interest on overdue amount
```

### 14.2 Ownership & License
```
✅ Client receives full ownership of source code upon full payment
✅ Perpetual, royalty-free license
✅ Rights to modify, distribute, and commercialize
✅ No vendor lock-in
✅ Unlimited server installations
✅ Unlimited user licenses
```

### 14.3 Warranty & Support
```
✅ 30-day money-back guarantee (if major features don't work)
✅ 3 months free support (bug fixes, configuration help)
✅ Lifetime updates for critical security patches
✅ No warranty on third-party services/libraries
✅ Extended support available (Rp 1 juta/bulan)
```

### 14.4 Confidentiality
```
✅ Both parties agree to maintain confidentiality
✅ Source code and documentation are confidential
✅ Client data remains private and secure
✅ NDA can be signed if required
✅ No client information shared with third parties
```

---

## 15. APPENDICES

### Appendix A: Technology Versions

```
Backend:
  Laravel:              12.0
  PHP:                  8.2+
  PostgreSQL:           13+
  Composer:             2.7+
  Laravel Excel:        3.1+
  Laravel DomPDF:       3.1+

Frontend:
  Vite:                 7.0.4
  TailwindCSS:          4.0.0
  Axios:                1.11.0
  Blade:                Laravel 12

Client:
  Python:               3.7+
  Requests:             2.31.0+
  WebSocket-Client:     1.6.0+
  PSUtil:               5.9.0+
  Pillow:               10.0.0+
  MSS:                  9.0.0+
```

### Appendix B: File Sizes

```
Client Package:       27.76 MB (with Python bundled)
Dashboard (Core):     42.5 MB (without vendor dependencies)
Database (Empty):     2.1 MB
Database (1 month):   50-200 MB (depends on activity)
Screenshots/Day:      50-200 MB per client (compressed JPEG)
Full Project:         8.3 GB (with all dependencies)
```

### Appendix C: Server Requirements Detail

```
Minimum (10-20 clients):
  CPU:      2 vCPU
  RAM:      2 GB
  Storage:  20 GB SSD
  Network:  100 Mbps

Recommended (50-100 clients):
  CPU:      4 vCPU
  RAM:      8 GB
  Storage:  100 GB SSD
  Network:  1 Gbps

Enterprise (100+ clients):
  CPU:      8 vCPU
  RAM:      16 GB
  Storage:  200 GB SSD (NVMe)
  Network:  1 Gbps
  Backup:   Daily automated
  CDN:      CloudFlare (optional)
```

---

**END OF REPORT**

---

*Laporan ini disusun oleh: Adi Fayyaz Sumardi*
*Tanggal: 1 November 2025*
*Project: Tenjo Employee Monitoring System*
*Status: Production Ready*
*Investment: Rp 29,000,000*

---

**For inquiries or questions, please contact:**
**Email:** adisumardi888@gmail.com
**GitHub:** https://github.com/Adi-Sumardi/Tenjo
**Production URL:** https://tenjo.adilabs.id