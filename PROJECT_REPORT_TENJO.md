LAPORAN PEMBUATAN APLIKASI DOCSCAN - AI
AI Document Scanner & Smart Mapper AI
Processing System
Tanggal Laporan: 15 Oktober 2025 Versi Aplikasi: 1.0.0 Developer: Adi Sumardi Status:
Production Ready
1. EXECUTIVE SUMMARY
Deskripsi Aplikasi
AI Document Scanner adalah sistem profesional untuk pemrosesan dokumen otomatis
menggunakan teknologi OCR (Optical Character Recognition) dan AI (Artificial
Intelligence). Aplikasi ini dirancang khusus untuk mengekstrak data dari dokumen
perpajakan Indonesia dan dokumen bisnis lainnya dengan akurasi tinggi.
Keunggulan Utama
Akurasi Tinggi: 95-99.6% akurasi OCR menggunakan Google Document AI Multi-Document
Support: 5 jenis dokumen (Faktur Pajak, PPh21, PPh23, Rekening Koran, Invoice) Smart
AI Mapping: Otomatis mapping field menggunakan GPT-4 Batch Processing: Upload hingga
100 dokumen sekaligus (untuk dokumen pajak) Multi-Format Export: Excel dan PDF
professional Production Ready: Sudah tested dan optimized untuk production
Value Proposition
Hemat Waktu: Proses 100 dokumen dalam 15-20 menit (vs 2-3 hari manual)
Hemat Biaya: Eliminasi manual data entry (save 80% biaya tenaga kerja)
Akurat: Reduce human error dari 5-10% menjadi < 1%
Scalable: Handle massive batches (1000+ halaman)
2. SPESIFIKASI TEKNIS
2.1 Spesifikasi Server (Minimum Requirements)
Production Server
CPU: 8 vCPU (Intel Xeon atau AMD EPYC)
RAM: 16 GB (16 GB recommended)
Storage: 90 GB SSD (100 GB recommended untuk data)
OS: Ubuntu 22.04 LTS
Development Environment
CPU: 2 vCPU
RAM: 4 GB
Storage: 20 GB SSD
OS: Ubuntu 20.04 LTS / macOS / Windows 10+
2.2 Spesifikasi Database
Database: Storage: MySQL 8.0+ atau MariaDB 10.6+
90 GB minimum (auto-scaling recommended)
Connections: Pool size 20-50 concurrent connections
Backup: Daily automated backup recommended
2.3 Spesifikasi Software
Backend (Python)
Python Version: 3.10+
Framework: FastAPI 0.116.1
ASGI Server: Uvicorn 0.35.0
Process Manager: PM2 atau Supervisor
Frontend (React + TypeScript)
Node.js Version: 18.x LTS
Framework: React 18.3.1
Build Tool: Vite 7.1.5
UI Library: TailwindCSS 3.4.1
2.4 Cloud Services
OCR Engine: Google Document AI
AI Mapping: OpenAI GPT-4o
File Storage: Local file system (can be upgraded to S3)
Database: MySQL (can be upgraded to managed service)
3. FITUR & KEMAMPUAN
3.1 Core Features
A. Document Processing
Supported Document Types:
1. Faktur Pajak (Tax Invoice)
Akurasi: 99.6%
Fields: 30+ fields termasuk DPP, PPN, Total, Vendor, Customer
Format: PDF, PNG, JPG, TIFF
Pages: 1-2 halaman per dokumen
2. PPh21 (Income Tax)
Akurasi: 95%+
Fields: 25+ fields termasuk NPWP, Nama, Penghasilan, Pajak
Format: PDF, PNG, JPG
Pages: 1-2 halaman per dokumen
3. PPh23 (Withholding Tax)
Akurasi: 95%+
Fields: 20+ fields termasuk DPP, Tarif, Jumlah Pajak
Format: PDF, PNG, JPG
Pages: 1-2 halaman per dokumen
4. Rekening Koran (Bank Statements)
Akurasi: 90%+
Fields: Unlimited transactions per page
Support: BCA, Mandiri, BNI, BRI, dan bank lainnya
Format: PDF (multi-page support)
Pages: 1-100+ halaman per dokumen
5. Invoice (Business Invoices)
Akurasi: 85%+
Fields: Universal template for all invoice types
Format: PDF, PNG, JPG
Pages: 1-50 halaman per dokumen
B. Upload Capabilities
Single File Upload:
Max: 50 files per upload
Size limit: 50 MB per file
All document types supported
ZIP Batch Upload: (RESTRICTED to tax documents only)
Max: 100 files per ZIP
Size limit: 200 MB per ZIP
Allowed: Faktur Pajak, PPh21, PPh23, SPT, NPWP only
Restricted: Rekening Koran, Invoice (to prevent token waste)
Why ZIP Restriction?
Tax documents: 1-3 pages each → Efficient batch processing
Bank statements: 50+ pages each → Upload individually to control costs
Token savings: 90% reduction in potential waste
C. Processing Features
1. Smart AI Mapping
Automatic field detection using GPT-4o
Intelligent data extraction for complex layouts
Fallback to rule-based extraction if needed
Support for handwritten notes (limited)
2. Batch Processing
Parallel processing: 10 concurrent documents
Page chunking: 10 pages per chunk for memory efficiency
Real-time progress tracking
Page-level progress: "Processing page 385/1000"
3. Data Validation
Format validation (currency, date, NPWP)
Completeness checking
Confidence scoring per field
Error detection and reporting
4. Export Formats
Excel Export:
Professional formatting dengan headers
Conditional formatting (colors, borders)
Auto-fit columns
Multiple sheets untuk complex documents
Formula support untuk calculations
Compatible dengan Microsoft Excel dan Google Sheets
PDF Export:
Professional layout dengan logo
Table formatting untuk structured data
Page numbering dan timestamps
Watermark support
Multi-page support untuk large datasets
3.2 User Management
Authentication & Authorization:
JWT-based authentication (secure token system)
Role-based access control (Admin, User)
Session management
Password encryption (bcrypt)
Login/logout functionality
Token expiration: 30 minutes (configurable)
User Features:
User registration dengan email validation
Password reset functionality
Profile management
Activity tracking
Batch history per user
3.3 Performance Features
Optimization:
Redis caching untuk frequently accessed data
Database connection pooling
Lazy loading untuk large datasets
Pagination untuk list views
Background processing untuk heavy tasks
Memory-efficient PDF processing
Monitoring:
Request logging
Error tracking
Performance metrics
API usage statistics
Database query logging
4. TEKNOLOGI YANG DIGUNAKAN
4.1 Backend Stack
Core Framework
FastAPI 0.116.1 - Modern async web framework
Uvicorn 0.35.0 - ASGI server
Pydantic 2.5.0 - Data validation
Python-dotenv 1.0.1 - Environment management
Database & ORM
SQLAlchemy 2.0.36 - ORM for database operations
PyMySQL 1.1.1 - MySQL driver
Alembic 1.14.0 - Database migrations
MySQL-connector 9.1.0 - Alternative MySQL driver
Authentication & Security
Python-jose 3.5.0 - JWT token handling
Passlib 1.7.4 - Password hashing
Bcrypt 4.1.2 - Password encryption
Python-magic 0.4.27 - File type validation
Slowapi 0.1.9 - Rate limiting
OCR & AI Services
Google Cloud Document AI 2.26.0 - Primary OCR engine (99.6% akurasi)
Google Cloud Storage 2.10.0 - Cloud storage integration
OpenAI 1.50.2 - GPT-4o for smart mapping
Anthropic 0.34.1 - Claude as backup AI
PDF Processing
PyPDF2 3.0.1 - PDF manipulation
PDFPlumber 0.11.7 - PDF text extraction
PyMuPDF 1.24.5 - Fast PDF processing & page counting
PDF2Image 1.17.0 - PDF to image conversion
PDFMiner.six 20250506 - Advanced PDF parsing
Export Libraries
OpenPyXL 3.1.5 - Excel file generation
ReportLab 4.4.3 - PDF report generation
Pandas 2.1.3 - Data manipulation
Utilities
Requests 2.32.5 - HTTP client
AioFiles 24.1.0 - Async file operations
Python-multipart 0.0.20 - File upload handling
Redis (optional) - Caching layer
4.2 Frontend Stack
Core Framework
React 18.3.1 - UI framework
TypeScript 5.5.3 - Type-safe JavaScript
Vite 7.1.5 - Build tool & dev server
React Router 7.8.2 - Client-side routing
UI Libraries
TailwindCSS 3.4.1 - Utility-first CSS framework
Lucide React 0.344.0 - Icon library (1000+ icons)
React Hot Toast 2.6.0 - Toast notifications
SweetAlert2 11.26.1 - Beautiful alerts & modals
HTTP & State Management
Axios 1.11.0 - HTTP client
React Context (built-in) - State management
Development Tools
ESLint 9.9.1 - Code linting
PostCSS 8.4.35 - CSS processing
Autoprefixer 10.4.18 - CSS vendor prefixes
4.3 DevOps & Deployment
Git - - Version control
GitHub - - Code repository
PM2 (optional) - Process manager
Nginx (optional) - Reverse proxy & load balancer
Certbot (optional) - SSL/TLS certificates (Let's Encrypt)
Docker (optional) - Containerization
4.4 Cloud Services (Required)
Google Cloud Platform
Service: Google Document AI
Purpose: OCR text extraction
Pricing: $1.50 per 1000 pages (first 1000 free monthly)
Required: Yes (primary OCR engine)
Credentials: JSON key file
OpenAI
Service: GPT-4o API
Purpose: Smart field mapping
Pricing: $0.0025 per 1K input tokens
Required: Yes (for Smart Mapper feature)
API Key: Required
Anthropic (Optional)
Service: Claude API
Purpose: Backup AI for field mapping
Pricing: Similar to OpenAI
Required: No (fallback only)
API Key: Optional
5. ARSITEKTUR SISTEM
5.1 System Architecture Diagram
┌─────────────────────────────────────────────────────────────┐
│ CLIENT BROWSER │
│ (React + TypeScript + TailwindCSS) │
└────────────────────┬────────────────────────────────────────┘
│ HTTPS
│ (API Requests + JWT Token)
▼
┌─────────────────────────────────────────────────────────────┐
│ NGINX (Optional) │
│ - Reverse Proxy │
│ - SSL/TLS Termination │
│ - Load Balancing │
│ - Static File Serving │
└────────────────────┬────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│ FASTAPI BACKEND SERVER │
│ (Python 3.10 + FastAPI + Uvicorn) │
│ │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ API Routes │ │
│ │ - /api/upload (file upload) │ │
│ │ - /api/upload-zip (batch upload - tax docs only) │ │
│ │ - /api/documents (document management) │ │
│ │ - /api/batches (batch processing) │ │
│ │ - /api/export/excel (export to Excel) │ │
│ │ - /api/export/pdf (export to PDF) │ │
│ │ - /api/auth (authentication) │ │
│ └──────────────────────────────────────────────────────┘ │
│ │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Core Processing Modules │ │
│ │ │ │
│ │ ┌─────────────────────────────────────────────┐ │ │
│ │ │ AI Processor (ai
_processor.py) │ │ │
│ │ │ - Coordinate all processing │ │ │
│ │ │ - Route to appropriate processor │ │ │
│ │ └─────────────────────────────────────────────┘ │ │
│ │ │ │
│ │ ┌─────────────────────────────────────────────┐ │ │
│ │ │ Cloud AI Processor │ │ │
│ │ │ - Google Document AI integration │ │ │
│ │ │ - OCR text extraction │ │ │
│ │ │ - 99.6% accuracy │ │ │
│ │ └─────────────────────────────────────────────┘ │ │
│ │ │ │
│ │ ┌─────────────────────────────────────────────┐ │ │
│ │ │ Smart Mapper (smart
_
mapper.py) │ │ │
│ │ │ - GPT-4o integration │ │ │
│ │ │ - Intelligent field mapping │ │ │
│ │ │ - Template-based extraction │ │ │
│ │ └─────────────────────────────────────────────┘ │ │
│ │ │ │
│ │ ┌─────────────────────────────────────────────┐ │ │
│ │ │ Batch Processor (batch
_processor.py) │ │ │
│ │ │ - Parallel processing (10 concurrent) │ │ │
│ │ │ - Page chunking (10 pages/chunk) │ │ │
│ │ │ - Progress tracking │ │ │
│ │ └─────────────────────────────────────────────┘ │ │
│ │ │ │
│ │ ┌─────────────────────────────────────────────┐ │ │
│ │ │ PDF Page Analyzer │ │ │
│ │ │ - Page counting │ │ │
│ │ │ - Memory-efficient processing │ │ │
│ │ │ - Support 100+ pages per PDF │ │ │
│ │ └─────────────────────────────────────────────┘ │ │
│ │ │ │
│ │ ┌─────────────────────────────────────────────┐ │ │
│ │ │ Exporters (exporters/*
.py) │ │ │
│ │ │ - Excel generation (OpenPyXL) │ │ │
│ │ │ - PDF generation (ReportLab) │ │ │
│ │ │ - Data formatting & styling │ │ │
│ │ └─────────────────────────────────────────────┘ │ │
│ └──────────────────────────────────────────────────────┘ │
└────────────────────┬────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│ MYSQL DATABASE │
│ (MySQL 8.0+ or MariaDB 10.6+) │
│ │
│ Tables: │
│ - users (authentication & profiles) │
│ - batches (batch processing jobs) │
│ - document
_
files (uploaded documents) │
│ - scan
_
results (OCR results & extracted data) │
│ - processing_
logs (activity logs) │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ EXTERNAL SERVICES │
│ │
│ ┌──────────────────┐ ┌──────────────────┐ │
│ │ Google Cloud │ │ OpenAI API │ │
│ │ Document AI │ │ (GPT-4o) │ │
│ │ │ │ │ │
│ │ OCR Processing │ │ Smart Mapping │ │
│ │ $1.50/1K pages │ │ $0.0025/1K token │ │
│ └──────────────────┘ └──────────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ FILE STORAGE │
│ (Local filesystem or S3-compatible) │
│ │
│ /uploads/ - Uploaded documents │
│ /exports/ - Generated Excel/PDF exports │
│ /logs/ - Application logs │
└─────────────────────────────────────────────────────────────┘
5.2 Data Flow
Upload & Processing Flow
1. User uploads document(s) via web interface
↓
2. Frontend sends file(s) to /api/upload or /api/upload-zip
↓
3. Backend validates files (type, size, security)
↓
4. Files saved to /uploads/ directory
↓
5. Batch created in database
↓
6. Background processing starts:
a. PDF page analysis (if PDF)
b. Send to Google Document AI for OCR
c. Receive OCR text response
d. Send to GPT-4o Smart Mapper for field extraction
e. Parse and validate extracted data
f. Store results in database
↓
7. User can view results in real-time
↓
8. User exports to Excel or PDF
5.3 Security Architecture
Multi-Layer Security:
1. Transport Security
HTTPS/TLS encryption (Let's Encrypt)
Secure headers (HSTS, CSP, X-Frame-Options)
2. Authentication Security
JWT tokens with 30-minute expiration
Bcrypt password hashing (cost factor 12)
Rate limiting: 5 login attempts per minute
3. File Upload Security
File type validation (magic bytes)
Size limits: 50MB per file, 200MB per ZIP
Path traversal protection
Virus scanning support (ClamAV optional)
4. API Security
Rate limiting: 10 uploads/minute, 5 ZIP/minute
CORS configuration
Request validation (Pydantic)
SQL injection protection (ORM)
5. Data Security
Database credentials in environment variables
Sensitive data not logged
Automatic session timeout
Secure file deletion after processing (configurable)
6. BIAYA DEVELOPMENT
6.1 Breakdown Biaya Development
A. Development Time & Cost
Fase Durasi Biaya (IDR)
1. Research & Planning 1 hari Rp 0
- Requirement gathering
- Technology selection
- Architecture design
2. Backend Development 1 minggu Rp 18,000,000
- FastAPI setup & structure
- Database design & ORM
- Google Document AI integration
- OpenAI GPT-4o Smart Mapper
- Batch processing system
- Export modules (Excel/PDF)
- Authentication & security
3. Frontend Development 1 minggu Rp 15,000,000
- React + TypeScript setup
- UI/UX design & implementation
- Upload interface
- Document management
- Export functionality
- Responsive design
4. Testing & QA 1 minggu Rp 7,000,000
- Unit testing
- Integration testing
- Performance testing
- Security testing
- User acceptance testing
5. Optimization & Deployment 4 hari Rp 5,000,000
- Performance optimization
- Production deployment setup
- Documentation
- Training materials
6. Bug Fixes & Revisions 3 hari Rp 4,000,000
- Post-launch bug fixes
- Feature refinements
- User feedback implementation
Total Development Time: 4 minggu (1 bulan) Total Development Cost: Rp 49,000,000
12. KESIMPULAN
12.1 Ringkasan Sistem
AI Document Scanner adalah solusi profesional untuk otomasi pemrosesan dokumen dengan
teknologi terkini:
Technology Stack:
Backend: Python 3.10 + FastAPI (modern, fast, async)
Frontend: React 18 + TypeScript (type-safe, maintainable)
OCR: Google Document AI (99.6% accuracy)
AI: OpenAI GPT-4o (intelligent field mapping)
Database: MySQL 8.0 (reliable, scalable)
Key Features:
5 document types supported (tax documents + business docs)
Batch processing (up to 100 tax documents in ZIP)
Smart AI mapping with GPT-4o
Professional Excel & PDF export
Real-time progress tracking
Page-level processing for massive PDFs (1000+ pages)
Performance:
Process 200+ documents per hour
10 concurrent tasks
Memory-efficient (stable at ~500MB)
99.6% OCR accuracy
Security:
JWT authentication
Rate limiting
File validation
HTTPS/TLS encryption
Secure password hashing