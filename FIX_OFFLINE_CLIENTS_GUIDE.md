# Fix 19 Offline Clients - Complete Guide

## Problem
- 19 client PCs sudah ter-install Tenjo
- Tidak muncul ONLINE di dashboard
- Root cause: Config masih pointing ke localhost instead of production server

## IP Addresses (19 Clients)
```
192.168.1.26      192.168.1.8       192.168.100.159
192.168.1.21      192.168.1.27      192.168.1.38
192.168.1.25      192.168.1.22      192.168.1.30
192.168.1.2       192.168.100.158   192.168.1.32
192.168.100.165   192.168.1.21      192.168.1.18
192.168.100.216   192.168.1.27
192.168.100.178   192.168.1.29
```

---

## Solution Deployed

### ✅ v1.0.2 Package Created
- **Download**: https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.2.tar.gz
- **Size**: 27.76 MB
- **Checksum**: 246b61b8da934d1d7011c871594dfa4ac378e30265ee30980b4281394705bd80
- **Priority**: HIGH (checks every 5 minutes)
- **Changes**:
  - Fixed DEFAULT_SERVER_URL to https://tenjo.adilabs.id
  - Added check_client_config.py diagnostic tool
  - Added update_server_config.py remote updater

---

## How to Fix - 3 Options

### **Option 1: Mass Remote Update (FASTEST)** ⚡

Use PowerShell script to update all 19 PCs at once.

#### Requirements:
- Admin PC on same network
- PowerShell with admin rights
- Network access to all client PCs
- Admin credentials for remote access

#### Steps:
1. **On Admin PC, open PowerShell as Administrator**
2. **Run mass update script:**
   ```powershell
   cd C:\Tenjo-Deploy  # or your deployment folder
   .\mass_update_clients.ps1
   ```

3. **Script will:**
   - Download update_server_config.py from server
   - Test connection to each client (19 IPs)
   - Copy update script to C:\ProgramData\Tenjo\
   - Run update remotely on each client
   - Schedule restart in 5 minutes
   - Show success/fail summary

4. **Wait 15 minutes, then check dashboard**

#### Expected Output:
```
========================================
📊 SUMMARY
========================================
Total:      19
✅ Success: 17
❌ Failed:  2

IP              Status    Message
--              ------    -------
192.168.1.26    Success   Updated, restart in 5 min
192.168.1.21    Success   Updated, restart in 5 min
192.168.1.25    Offline   Could not connect
...
```

---

### **Option 2: Manual Update Per PC (RELIABLE)** 🔧

For PCs that failed mass update or need individual attention.

#### On Each Client PC:

**Windows:**
1. Open Command Prompt as Administrator
2. Run:
   ```cmd
   cd C:\ProgramData\Tenjo
   curl -O https://tenjo.adilabs.id/downloads/client/update_server_config.py
   python update_server_config.py
   shutdown /r /t 60
   ```

**Linux:**
```bash
cd /opt/tenjo
sudo wget https://tenjo.adilabs.id/downloads/client/update_server_config.py
sudo python3 update_server_config.py
sudo reboot
```

---

### **Option 3: Reinstall with v1.0.2 (CLEANEST)** 🔄

Complete reinstallation ensures clean state.

#### Steps:
1. **Uninstall old client**
   ```powershell
   cd C:\ProgramData\Tenjo
   .\uninstall_autostart.ps1
   ```

2. **Download v1.0.2**
   ```powershell
   curl -O https://tenjo.adilabs.id/downloads/client/tenjo_client_1.0.2.tar.gz
   tar -xzf tenjo_client_1.0.2.tar.gz
   ```

3. **Install**
   ```powershell
   python main.py  # or .\install_autostart.ps1
   ```

4. **Client auto-connects to production**

---

## Verification

### After Update (Any Method):

1. **Wait 10-15 minutes** for clients to restart and connect

2. **Check Dashboard**:
   - Open: https://tenjo.adilabs.id/
   - Go to "Clients" page
   - Should see all 19 clients ONLINE with their IPs

3. **Expected Result**:
   ```
   ┌────────────────────────────────────────────────────┐
   │ CLIENT         │ IP ADDRESS      │ STATUS  │ VER   │
   ├────────────────────────────────────────────────────┤
   │ Office-PC-001  │ 192.168.1.26    │ 🟢ONLINE│ 1.0.2 │
   │ Office-PC-002  │ 192.168.1.21    │ 🟢ONLINE│ 1.0.2 │
   │ Office-PC-003  │ 192.168.1.25    │ 🟢ONLINE│ 1.0.2 │
   │ ...            │ ...             │ ...     │ ...   │
   └────────────────────────────────────────────────────┘
   ```

4. **Verify Streaming**:
   - Click on any client
   - Should see live screen stream
   - Screenshots uploading
   - Browser activity tracked

---

## Troubleshooting

### Client Still Offline After Update?

**Check 1: Is client running?**
```powershell
# On client PC
Get-Process python
# Should show python.exe running
```

**Check 2: Check config**
```powershell
cd C:\ProgramData\Tenjo
python check_client_config.py
# Should show: SERVER_URL = https://tenjo.adilabs.id
```

**Check 3: Check logs**
```powershell
type C:\ProgramData\Tenjo\logs\stealth.log
# Look for connection errors
```

**Check 4: Firewall**
```powershell
# Test connection to server
curl -I https://tenjo.adilabs.id/
# Should return: HTTP/1.1 200 OK
```

**Check 5: Manual restart**
```powershell
# Kill old process
taskkill /F /IM python.exe
# Start new
cd C:\ProgramData\Tenjo
python main.py
```

---

## Mass Update Script Details

The PowerShell script (`mass_update_clients.ps1`) does:

1. **Download update tool** from production server
2. **For each of 19 IPs**:
   - Test if online (ping)
   - Copy update script via network share (\\IP\C$\ProgramData\Tenjo\)
   - Execute remotely via Invoke-Command
   - Schedule restart in 5 minutes
   - Track success/failure

3. **Generate report**:
   - Shows which clients succeeded
   - Which failed and why
   - Summary statistics

---

## Timeline

```
NOW:
  ├─ v1.0.2 deployed to production ✓
  ├─ Package available for download ✓
  └─ Ready to update clients

+5 minutes (Mass Update):
  ├─ Run mass_update_clients.ps1
  ├─ Updates pushed to all 19 PCs
  └─ Restarts scheduled

+10 minutes:
  ├─ Clients restarting with new config
  └─ Connecting to https://tenjo.adilabs.id

+15 minutes:
  ├─ All clients ONLINE ✓
  ├─ Dashboard showing 19 clients ✓
  └─ Streaming active ✓

Result:
  └─ 100% clients visible and monitored ✅
```

---

## Files Created

1. **check_client_config.py** - Diagnostic tool to verify config
2. **update_server_config.py** - Remote config updater
3. **mass_update_clients.ps1** - PowerShell mass deployment script
4. **DEPLOY_V1.0.2_GUIDE.md** - Deployment documentation
5. **AUTO_UPDATE_BEHAVIOR.md** - Auto-update system guide

---

## Summary

- ✅ Root cause identified: localhost config
- ✅ v1.0.2 package created with fix
- ✅ Update tools created (remote config updater)
- ✅ Mass deployment script ready
- ✅ Documentation complete

**Next:** Run `mass_update_clients.ps1` on admin PC to fix all 19 clients at once! 🚀
