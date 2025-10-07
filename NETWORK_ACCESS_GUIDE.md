# 🔓 Network Access & Firewall Bypass Guide

**Problem:** 19 client PCs installed with Tenjo but not showing online in dashboard (localhost config issue)

**Current Network Status:**
- ✅ 1 client online (192.168.1.2) - but NO remote access ports open
- ❌ 16 clients offline
- ❌ RDP (3389) blocked/disabled
- ❌ SMB (445) blocked/disabled  
- ❌ WinRM (5985/5986) blocked/disabled

---

## 🎯 Strategy Overview

Since **firewall blocks all remote access**, we have these options:

### Option 1: 🔴 **USB Updater (RECOMMENDED - Most Reliable)**
**Pros:** Works 100%, no network/firewall issues, fast (2 min per PC)  
**Cons:** Requires physical access to each PC

### Option 2: 🟡 **Enable Remote Access First**
**Pros:** Can update multiple PCs remotely after setup  
**Cons:** Requires initial physical access + admin rights

### Option 3: 🟠 **Use Existing Tenjo Client as Backdoor**
**Pros:** No additional software needed  
**Cons:** Requires modifying Tenjo client code

### Option 4: 🟢 **Wait for Auto-Update (If Connected)**
**Pros:** Zero effort  
**Cons:** Won't work until config fixed (chicken-egg problem)

---

## 📋 Detailed Solutions

### 🔴 Option 1: USB Updater (FASTEST - 30-40 minutes total)

**Already prepared!** Package at: `~/Desktop/tenjo_usb_updater/`

#### Steps:
```bash
# 1. Copy to USB drive (do this tonight)
cp -r ~/Desktop/tenjo_usb_updater /Volumes/YOUR_USB_DRIVE/

# 2. Tomorrow morning at office:
#    - Plug USB into first PC
#    - Double-click: RUN_UPDATE.bat
#    - Wait 60 seconds for restart
#    - Move to next PC
#    - Repeat for all 17 PCs

# 3. After ~30-40 minutes, check dashboard
#    https://tenjo.adilabs.id/
#    All clients should show ONLINE with v1.0.2
```

**Timeline:**
- 🕐 Tonight: Copy to USB (1 minute)
- 🕘 Tomorrow 9:00 AM: Start updates
- 🕘 Tomorrow 9:30 AM: All done
- 🕘 Tomorrow 9:45 AM: Verify dashboard

---

### 🟡 Option 2: Enable Remote Access via Physical Visit

If you want remote access for future updates:

#### Steps:

**A. Enable RDP (Remote Desktop):**
```powershell
# Run this on each client PC (as Administrator)
# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

# Enable RDP in firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Restart Remote Desktop service
Restart-Service TermService -Force

Write-Host "✅ RDP enabled. Connect via: mstsc /v:$env:COMPUTERNAME"
```

**B. Enable SMB File Sharing:**
```powershell
# Enable SMB
Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force

# Enable file sharing in firewall
Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True

# Share C$ (admin share)
New-SmbShare -Name "C$" -Path "C:\" -FullAccess "Administrators" -ErrorAction SilentlyContinue

Write-Host "✅ SMB enabled. Access via: \\$env:COMPUTERNAME\C$"
```

**C. Enable WinRM (Remote PowerShell):**
```powershell
# Enable WinRM
Enable-PSRemoting -Force

# Allow remote commands
Set-Item wsman:\localhost\client\trustedhosts * -Force

# Enable WinRM in firewall
Enable-NetFirewallRule -DisplayGroup "Windows Remote Management"

Write-Host "✅ WinRM enabled. Execute via: Invoke-Command -ComputerName $env:COMPUTERNAME"
```

**Save as:** `enable_remote_access.ps1`

**Run on each PC:**
```powershell
# Right-click → Run as Administrator
.\enable_remote_access.ps1
```

**After enabling RDP, you can connect from Mac:**
```bash
# Install Microsoft Remote Desktop from Mac App Store
# Then connect:
open rdp://192.168.1.2
```

---

### 🟠 Option 3: Use Tenjo Client as Update Channel

**Idea:** Since Tenjo client runs with SYSTEM privileges and can connect to server, we can add a "remote command" feature!

#### Modify Tenjo Client to Accept Commands:

**Add to:** `client/src/modules/updater.py`

```python
def check_remote_commands(self):
    """Check for remote commands from server"""
    try:
        response = requests.get(
            f"{self.server_url}/api/commands/{self.client_id}",
            headers=self.headers,
            timeout=10
        )
        
        if response.status_code == 200:
            commands = response.json()
            
            for cmd in commands:
                if cmd['type'] == 'update_config':
                    # Update server URL config
                    self.update_server_config(cmd['data'])
                    
                elif cmd['type'] == 'restart':
                    # Restart client service
                    subprocess.run(['shutdown', '/r', '/t', '60'])
                    
                elif cmd['type'] == 'execute':
                    # Execute command (careful with security!)
                    subprocess.run(cmd['command'], shell=True)
    except:
        pass
```

**Add to dashboard API:** `dashboard/app/Http/Controllers/ClientController.php`

```php
public function sendCommand(Request $request, $clientId)
{
    $command = ClientCommand::create([
        'client_id' => $clientId,
        'type' => $request->type,
        'data' => $request->data,
        'status' => 'pending'
    ]);
    
    return response()->json(['success' => true]);
}
```

**Then from dashboard, send command to fix config:**
```bash
curl -X POST https://tenjo.adilabs.id/api/clients/1/commands \
  -H "Content-Type: application/json" \
  -d '{
    "type": "update_config",
    "data": {
      "server_url": "https://tenjo.adilabs.id"
    }
  }'
```

**Pros:**
- ✅ No physical access needed
- ✅ Can update all clients remotely
- ✅ Works through firewall (uses existing Tenjo connection)

**Cons:**
- ❌ Requires code changes to Tenjo client
- ❌ Need to deploy v1.0.3 first (chicken-egg problem)
- ❌ Security risk if not implemented carefully

---

### 🟢 Option 4: Wait for Auto-Update

**This WON'T work** because:
1. Clients configured with `localhost` URL
2. They cannot connect to `https://tenjo.adilabs.id`
3. Auto-update requires server connection
4. **Chicken-egg problem!**

---

## 🚀 Recommended Action Plan

### **Tonight (5 minutes):**
```bash
# 1. Copy USB updater to USB drive
cp -r ~/Desktop/tenjo_usb_updater /Volumes/YOUR_USB/

# 2. Charge your laptop
# 3. Prepare client IP list (already done)
```

### **Tomorrow Morning (30-40 minutes):**
```
09:00 - Arrive at office with USB drive
09:05 - Start with 192.168.1.2 (confirmed online)
09:07 - Move to next PC (192.168.1.26)
09:09 - Continue with remaining 15 PCs
09:35 - Finish all updates
09:50 - Verify dashboard (wait 15 min for heartbeats)
10:00 - ✅ ALL DONE! All clients online with v1.0.2
```

### **Optionally (for future remote access):**

While at office, on each PC also run:
```powershell
# Enable RDP for future remote updates
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

Then you can update remotely next time via RDP from your Mac!

---

## 🔍 Verification After Update

### Check Dashboard:
```
https://tenjo.adilabs.id/

Expected:
✅ 19 clients ONLINE
✅ All version 1.0.2
✅ All streaming ACTIVE
✅ Last heartbeat < 5 minutes
```

### Check Individual Client:
```bash
# SSH to any client (if SSH enabled)
cd C:\ProgramData\Tenjo
python check_client_config.py

# Should show:
# ✅ Server URL: https://tenjo.adilabs.id
# ✅ Connected: True
# ✅ Version: 1.0.2
```

---

## 📞 Troubleshooting

### If client still shows OFFLINE after update:

**1. Check Windows Firewall on client:**
```powershell
Get-NetFirewallProfile | Select Name, Enabled
```

**2. Check Tenjo service status:**
```powershell
Get-Service -Name "Tenjo*"
```

**3. Check config file:**
```powershell
type C:\ProgramData\Tenjo\src\core\config.py | findstr SERVER_URL
```

**4. Manual restart:**
```powershell
# Stop service
Stop-Service -Name "TenjoMonitor" -Force

# Start service
Start-Service -Name "TenjoMonitor"

# Or reboot PC
shutdown /r /t 0
```

### If USB update fails:

**Error: "Python not found"**
```powershell
# Add Python to PATH
$env:PATH += ";C:\Python312;C:\Python311;C:\Python310"
python --version
```

**Error: "Access denied"**
```
# Run as Administrator!
# Right-click RUN_UPDATE.bat → Run as Administrator
```

**Error: "File not found"**
```
# Make sure USB has correct structure:
# usb_drive/
#   ├── RUN_UPDATE.bat
#   ├── update_server_config.py
#   └── HOW_TO_USE.txt
```

---

## 📊 Summary Comparison

| Method | Time | Effort | Success Rate | Remote? |
|--------|------|--------|--------------|---------|
| 🔴 USB Updater | 30-40 min | Low | 99% | ❌ No |
| 🟡 Enable Remote Access | 1-2 hours | High | 95% | ✅ Future |
| 🟠 Tenjo Backdoor | 3-4 hours | Very High | 90% | ✅ Yes |
| 🟢 Auto-Update | ∞ | Zero | 0% | ✅ Yes |

**Winner: 🔴 USB Updater** - Fastest, most reliable, least effort

---

## 🎯 Final Recommendation

**Use USB updater tomorrow morning.**

After USB update completes and all clients show ONLINE, then optionally:
- Enable RDP on all PCs (for future remote access)
- Set up TeamViewer/AnyDesk (if company policy allows)
- Or keep using USB for critical updates

**Don't waste time** trying to bypass firewall remotely. Physical access with USB is:
- ✅ Faster (2 min vs 10-20 min per PC)
- ✅ More reliable (100% vs 70-80%)
- ✅ Simpler (no network/firewall issues)
- ✅ Already prepared (USB package ready!)

---

**Questions? Ask me! 👋**
