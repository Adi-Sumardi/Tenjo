# Windows Testing Guide - Live Update & Self-Healing System

## 📋 Overview

Panduan ini untuk testing semua fitur live update dan self-healing di Windows. Tiga test script disediakan untuk menguji berbagai aspek sistem.

## 🔧 Test Scripts

### 1. **test_windows_live_update.py** - Comprehensive System Test

Test lengkap untuk semua komponen sistem.

**Tests:**
- ✅ Python installation detection
- ✅ Dependency checking
- ✅ File integrity verification (8 critical files)
- ✅ Backup functionality
- ✅ Live updater initialization
- ✅ Windows-specific features (CREATE_NO_WINDOW)
- ✅ Stealth mode configuration

**Run:**
```bash
cd client
python test_windows_live_update.py
```

**Expected Output:**
```
✅ Python Installation Check: PASS
✅ Dependency Checker: PASS
✅ File Integrity Check: PASS
✅ Backup Functionality: PASS
✅ Live Updater Initialization: PASS
✅ Windows-Specific Features: PASS
✅ Stealth Mode Configuration: PASS

Passed: 7/7
🎉 ALL TESTS PASSED - SYSTEM READY FOR PRODUCTION
```

---

### 2. **test_dependency_autoinstall.py** - Dependency Auto-Install Test

Test khusus untuk silent pip install dengan CREATE_NO_WINDOW.

**Tests:**
- ✅ Silent install with CREATE_NO_WINDOW flag
- ✅ DependencyChecker.auto_install_missing()
- ✅ No terminal pop-up verification (manual observation)
- ✅ Package availability after install

**Run:**
```bash
cd client
python test_dependency_autoinstall.py
```

**Expected Output:**
```
✅ Silent Install with CREATE_NO_WINDOW: PASS
✅ DependencyChecker Auto-Install: PASS
✅ No Terminal Pop-up (Manual): PASS

Passed: 3/3
🎉 ALL TESTS PASSED - AUTO-INSTALL WORKING
```

**Manual Observation:**
- Test akan install package 'colorama'
- WATCH untuk terminal window pop-up
- Jika tidak ada window muncul = STEALTH SUCCESS ✅
- Jika ada terminal terlihat = STEALTH FAILED ❌

---

### 3. **test_file_integrity_restore.py** - File Integrity & Restore Test

Test untuk file integrity check dan auto-restore from backup.

**Tests:**
- ✅ Initial integrity check (8 critical files)
- ✅ Backup creation and verification
- ✅ File deletion simulation
- ✅ Missing file detection
- ✅ Restore from backup (simulation)
- ✅ Backup rotation policy

**Run:**
```bash
cd client
python test_file_integrity_restore.py
```

**Expected Output:**
```
✅ Initial Integrity Check: PASS
✅ Create Backup: PASS
✅ Simulate File Deletion: PASS
✅ Detect Missing Critical File: PASS
✅ Restore from Backup (Simulation): PASS
✅ Backup Rotation Policy: PASS

Passed: 6/6
🎉 ALL TESTS PASSED - INTEGRITY & RESTORE WORKING
```

**⚠️ WARNING:**
- Test #4 akan delete `requirements.txt` sementara
- File akan di-restore immediately
- Confirm dengan "yes" untuk proceed

---

## 🎯 Testing Checklist

### **Before Testing:**
- [ ] Client installed di Windows machine
- [ ] Python 3.10+ installed
- [ ] All dependencies installed (`pip install -r requirements.txt`)
- [ ] Backup important data (optional, tapi recommended)

### **Test Sequence:**

#### **Step 1: Run Comprehensive Test**
```bash
python test_windows_live_update.py
```
- Verify semua 7 tests PASS
- Check log file di `%LOCALAPPDATA%\Tenjo\logs\windows_test_*.log`

#### **Step 2: Run Dependency Auto-Install Test**
```bash
python test_dependency_autoinstall.py
```
- **IMPORTANT:** Watch screen for terminal pop-ups
- Test akan uninstall/install 'colorama'
- Verify NO terminal window muncul
- Confirm stealth mode working

#### **Step 3: Run File Integrity Test**
```bash
python test_file_integrity_restore.py
```
- Backup akan dibuat otomatis
- Accept destructive test (type "yes")
- Verify restore working

---

## 🔍 What to Look For

### **✅ SUCCESS Indicators:**

1. **No Terminal Pop-ups**
   - Saat dependency install, TIDAK ADA terminal window
   - CREATE_NO_WINDOW flag bekerja
   - Karyawan TIDAK AKAN TAHU

2. **All Files Present**
   ```
   ✅ main.py
   ✅ src/core/config.py
   ✅ src/utils/api_client.py
   ✅ src/utils/auto_update.py
   ✅ src/modules/browser_tracker.py
   ✅ src/modules/screen_capture.py
   ✅ src/modules/process_monitor.py
   ✅ requirements.txt
   ```

3. **Backup Created**
   - Location: `C:\tenjo_backups\backup_*\`
   - Contains all client files
   - Ready for restore

4. **Silent Operations**
   - Logging level: WARNING or higher (stealth mode)
   - No console output
   - All operations background

### **❌ FAILURE Indicators:**

1. **Terminal Window Appears**
   - Black cmd window pops up during install
   - CREATE_NO_WINDOW not working
   - STEALTH COMPROMISED

2. **Missing Files**
   - Any critical file not found
   - Integrity check fails
   - Need to fix installation

3. **Import Errors**
   - Package installed but can't import
   - Path issues
   - Python environment problem

---

## 🐛 Troubleshooting

### **Issue: CREATE_NO_WINDOW not available**
```python
AttributeError: module 'subprocess' has no attribute 'CREATE_NO_WINDOW'
```
**Solution:**
- Upgrade Python to 3.7+
- CREATE_NO_WINDOW added in Python 3.7
- Check: `python --version`

### **Issue: Permission Denied during backup**
```python
PermissionError: [WinError 5] Access is denied
```
**Solution:**
- Run as Administrator (for system-wide install)
- Or install di user directory
- Check file permissions

### **Issue: Pip not found**
```python
No module named 'pip'
```
**Solution:**
```bash
python -m ensurepip --upgrade
python -m pip install --upgrade pip
```

### **Issue: Package install fails**
```python
ERROR: Could not install packages due to an OSError
```
**Solution:**
- Check internet connection
- Try with admin privileges
- Check antivirus blocking pip

---

## 📊 Expected Performance

### **Timing Benchmarks (Windows 10):**

| Operation | Expected Time | Notes |
|-----------|---------------|-------|
| Integrity Check | < 1s | Checks 8 files |
| Create Backup | 2-5s | Depends on install size |
| Dependency Check | 1-2s | Parse requirements.txt |
| Silent Install (1 pkg) | 5-30s | Depends on package size |
| Restore from Backup | 3-10s | Copy all files |

### **Resource Usage:**

| Resource | During Normal | During Update |
|----------|---------------|---------------|
| CPU | < 1% | 5-10% |
| RAM | 50-100 MB | 100-200 MB |
| Disk I/O | Minimal | Moderate |
| Network | 0 | During download only |

---

## 🎯 Production Readiness Criteria

System ready for production jika:

- [ ] ✅ All 7 comprehensive tests PASS
- [ ] ✅ No terminal pop-ups during dependency install
- [ ] ✅ File integrity check detects missing files
- [ ] ✅ Backup created successfully
- [ ] ✅ Restore works correctly
- [ ] ✅ Stealth mode enabled
- [ ] ✅ CREATE_NO_WINDOW flag working
- [ ] ✅ All 8 critical files present

---

## 📝 Test Results Template

Copy template ini untuk report hasil testing:

```
WINDOWS LIVE UPDATE TEST RESULTS
================================

Date: ___________
Tester: ___________
Windows Version: ___________
Python Version: ___________

Test 1: Comprehensive System Test
[ ] PASS  [ ] FAIL  Notes: ___________

Test 2: Dependency Auto-Install
[ ] PASS  [ ] FAIL  Notes: ___________

Test 3: File Integrity & Restore
[ ] PASS  [ ] FAIL  Notes: ___________

Manual Verification:
[ ] No terminal pop-ups observed
[ ] Stealth mode confirmed
[ ] All files present
[ ] Backup functional

Issues Found:
___________
___________

Recommendation:
[ ] Ready for production
[ ] Needs fixes
[ ] Needs further testing

Signature: ___________
```

---

## 🚀 Next Steps After Testing

Jika semua tests PASS:

1. **Deploy to test environment**
   - Install di 1-2 Windows machines
   - Monitor for 24 hours
   - Check logs for errors

2. **Gradual rollout**
   - Deploy to 10% karyawan
   - Monitor for 1 week
   - If stable, deploy to rest

3. **Monitor production**
   - Check auto-update logs
   - Verify silent operation
   - Confirm no karyawan complaints

4. **Celebrate! 🎉**
   - System fully operational
   - Karyawan tidak tahu
   - Monitoring 100% stealth

---

## 📞 Support

Jika ada issues atau questions:

1. Check logs:
   - Windows: `%LOCALAPPDATA%\Tenjo\logs\`
   - Test logs: `windows_test_*.log`
   - Auto-update logs: `auto_update.log`

2. Review documentation:
   - `LIVE_UPDATE_IMPLEMENTATION.md`
   - `AUTO_UPDATE_SYSTEM.md`

3. Debug mode:
   ```bash
   set TENJO_UPDATE_DEBUG=1
   python main.py
   ```

---

**Last Updated:** 2025-11-24
**Version:** Phase 1-3 Complete
**Status:** Ready for Windows Testing
