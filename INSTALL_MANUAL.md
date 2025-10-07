# Manual Installation Guide - No GitHub Access

## If GitHub is blocked on target PC:

### Method 1: USB Installer (RECOMMENDED)
1. Copy `tenjo_usb_installer_ULTIMATE/` to USB drive
2. Insert USB on target PC
3. Run `INSTALL_TENJO.bat` as Administrator
4. Done!

### Method 2: Direct Download
1. On a PC with internet, download:
   - Go to: https://github.com/Adi-Sumardi/Tenjo
   - Click "Code" → "Download ZIP"
   - Extract and copy `client/` folder

2. Copy to target PC at: `C:\ProgramData\Tenjo\`

3. Create `server_override.json`:
```json
{"server_url": "https://tenjo.adilabs.id"}
```

4. Create `start_tenjo.bat`:
```batch
@echo off
cd /d "C:\ProgramData\Tenjo"
python.exe main.py
```

5. Install dependencies:
```cmd
cd C:\ProgramData\Tenjo
python -m pip install -r requirements.txt
```

6. Create scheduled task:
```cmd
schtasks /Create /TN "TenjoMonitor" /TR "C:\ProgramData\Tenjo\start_tenjo.bat" /SC ONLOGON /F
```

7. Start service:
```cmd
C:\ProgramData\Tenjo\start_tenjo.bat
```

### Method 3: Alternative Download URL
If raw.githubusercontent.com is blocked, try:
```powershell
Invoke-WebRequest -Uri "https://github.com/Adi-Sumardi/Tenjo/raw/master/install_windows.ps1" -OutFile "install.ps1"
PowerShell -ExecutionPolicy Bypass -File "install.ps1"
```

### Method 4: Use IP Address
If DNS is blocked:
```powershell
# Add to hosts file (as Admin)
Add-Content C:\Windows\System32\drivers\etc\hosts "185.199.108.133 raw.githubusercontent.com"

# Then retry download
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1" -OutFile "install.ps1"
PowerShell -ExecutionPolicy Bypass -File "install.ps1"
```

## Troubleshooting Network Issues

### Check DNS:
```cmd
nslookup raw.githubusercontent.com
nslookup github.com
```

### Check Firewall:
```cmd
netsh advfirewall show currentprofile
```

### Use Proxy (if company network):
```powershell
$proxy = [System.Net.WebProxy]::new("http://proxy.company.com:8080")
$webClient = [System.Net.WebClient]::new()
$webClient.Proxy = $proxy
$webClient.DownloadFile("https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/install_windows.ps1", "install.ps1")
```

## Best Solution: USB INSTALLER
**Location:** `~/Desktop/tenjo_usb_installer_ULTIMATE/`

✅ Works offline
✅ No network required
✅ All fixes included
✅ Complete diagnostic tools
