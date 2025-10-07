#!/usr/bin/env python3
"""
Remote Update Deployer via WinRM/SMB
Automatically deploys update to online clients via network
"""

import subprocess
import socket
import sys
import os
from pathlib import Path

# Client IPs
CLIENT_IPS = [
    "192.168.1.26", "192.168.1.21", "192.168.1.25", "192.168.1.2",
    "192.168.100.165", "192.168.100.216", "192.168.100.178",
    "192.168.1.29", "192.168.1.8", "192.168.1.27", "192.168.1.22",
    "192.168.100.158", "192.168.100.159", "192.168.1.38",
    "192.168.1.30", "192.168.1.32", "192.168.1.18"
]

UPDATE_SCRIPT_URL = "https://tenjo.adilabs.id/downloads/client/update_server_config.py"
REMOTE_PATH = r"C:\ProgramData\Tenjo\update_server_config.py"

def check_port(ip: str, port: int, timeout: int = 1) -> bool:
    """Check if port is open on remote host"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, port))
        sock.close()
        return result == 0
    except:
        return False

def ping_host(ip: str) -> bool:
    """Ping host to check if online"""
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "1", ip],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=2
        )
        return result.returncode == 0
    except:
        return False

def scan_clients():
    """Scan all clients for online status and open ports"""
    print("=" * 60)
    print("🔍 SCANNING CLIENT NETWORK")
    print("=" * 60)
    print()
    
    results = []
    
    for ip in CLIENT_IPS:
        print(f"Scanning {ip}...", end=" ", flush=True)
        
        online = ping_host(ip)
        
        if online:
            rdp = check_port(ip, 3389)
            smb = check_port(ip, 445)
            winrm_http = check_port(ip, 5985)
            winrm_https = check_port(ip, 5986)
            
            access = []
            if rdp:
                access.append("RDP")
            if smb:
                access.append("SMB")
            if winrm_http or winrm_https:
                access.append("WinRM")
            
            access_str = ", ".join(access) if access else "None"
            print(f"🟢 ONLINE - Access: {access_str}")
            
            results.append({
                "ip": ip,
                "online": True,
                "rdp": rdp,
                "smb": smb,
                "winrm": winrm_http or winrm_https,
                "winrm_port": 5986 if winrm_https else 5985 if winrm_http else None
            })
        else:
            print("❌ OFFLINE")
            results.append({"ip": ip, "online": False})
    
    print()
    return results

def deploy_via_smb(ip: str, username: str, password: str):
    """Deploy update script via SMB share"""
    print(f"\n📁 Deploying to {ip} via SMB...")
    
    # Download update script locally
    local_script = "/tmp/update_server_config.py"
    print("  → Downloading update script...")
    result = subprocess.run(
        ["curl", "-s", "-o", local_script, UPDATE_SCRIPT_URL],
        capture_output=True
    )
    
    if result.returncode != 0:
        print(f"  ❌ Failed to download script")
        return False
    
    # Mount SMB share
    print(f"  → Mounting SMB share...")
    mount_point = f"/tmp/tenjo_smb_{ip.replace('.', '_')}"
    os.makedirs(mount_point, exist_ok=True)
    
    # Try mounting via macOS
    smb_url = f"smb://{username}:{password}@{ip}/C$"
    mount_cmd = ["mount_smbfs", smb_url, mount_point]
    
    result = subprocess.run(mount_cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"  ❌ Failed to mount: {result.stderr}")
        return False
    
    # Copy file
    try:
        print("  → Copying update script...")
        dest_path = os.path.join(mount_point, "ProgramData", "Tenjo", "update_server_config.py")
        subprocess.run(["cp", local_script, dest_path], check=True)
        print("  ✅ File copied successfully")
        
        # Unmount
        subprocess.run(["umount", mount_point], stdout=subprocess.DEVNULL)
        
        return True
    except Exception as e:
        print(f"  ❌ Failed to copy: {e}")
        subprocess.run(["umount", mount_point], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return False

def deploy_via_winrm(ip: str, port: int, username: str, password: str):
    """Deploy and execute via WinRM"""
    try:
        import winrm
    except ImportError:
        print("❌ winrm module not installed")
        print("   Install: pip3 install pywinrm")
        return False
    
    print(f"\n⚡ Deploying to {ip} via WinRM...")
    
    try:
        protocol = "https" if port == 5986 else "http"
        endpoint = f"{protocol}://{ip}:{port}/wsman"
        
        session = winrm.Session(
            endpoint,
            auth=(username, password),
            server_cert_validation='ignore'
        )
        
        # Download and execute update script
        commands = [
            f"cd C:\\ProgramData\\Tenjo",
            f"curl -o update_server_config.py {UPDATE_SCRIPT_URL}",
            f"python update_server_config.py",
            f"shutdown /r /t 60"
        ]
        
        for cmd in commands:
            print(f"  → Running: {cmd}")
            result = session.run_cmd(cmd)
            if result.status_code != 0:
                print(f"  ❌ Failed: {result.std_err.decode('utf-8')}")
                return False
        
        print("  ✅ Update deployed and scheduled restart")
        return True
        
    except Exception as e:
        print(f"  ❌ WinRM error: {e}")
        return False

def main():
    print("""
╔═══════════════════════════════════════════════════════════╗
║       TENJO REMOTE UPDATE DEPLOYER                        ║
║       Deploy updates via network (SMB/WinRM)              ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    # Scan network
    results = scan_clients()
    
    # Summary
    online = [r for r in results if r.get("online")]
    smb_available = [r for r in online if r.get("smb")]
    winrm_available = [r for r in online if r.get("winrm")]
    
    print("=" * 60)
    print("📊 SCAN SUMMARY")
    print("=" * 60)
    print(f"🟢 Online:       {len(online)}/{len(CLIENT_IPS)} clients")
    print(f"📁 SMB Access:   {len(smb_available)} clients")
    print(f"⚡ WinRM Access: {len(winrm_available)} clients")
    print()
    
    if not online:
        print("❌ No clients online. Try:")
        print("   1. Connect Mac to office network")
        print("   2. Use USB updater method")
        print("   3. Wait for work hours")
        return
    
    # Ask deployment method
    print("=" * 60)
    print("🚀 DEPLOYMENT OPTIONS")
    print("=" * 60)
    print()
    print("1. Deploy via SMB (copy files, manual execution)")
    print("2. Deploy via WinRM (automatic execution)")
    print("3. Show connection commands for manual RDP")
    print("4. Exit")
    print()
    
    choice = input("Select option (1-4): ").strip()
    
    if choice == "1" and smb_available:
        username = input("Enter Windows admin username [Administrator]: ").strip() or "Administrator"
        password = input("Enter password: ").strip()
        
        print()
        success = 0
        for client in smb_available:
            if deploy_via_smb(client["ip"], username, password):
                success += 1
        
        print()
        print(f"✅ Deployed to {success}/{len(smb_available)} clients")
        print()
        print("⚠️  Next: Connect via RDP to each PC and run:")
        print("   cd C:\\ProgramData\\Tenjo")
        print("   python update_server_config.py")
        
    elif choice == "2" and winrm_available:
        username = input("Enter Windows admin username [Administrator]: ").strip() or "Administrator"
        password = input("Enter password: ").strip()
        
        print()
        success = 0
        for client in winrm_available:
            if deploy_via_winrm(client["ip"], client["winrm_port"], username, password):
                success += 1
        
        print()
        print(f"✅ Deployed to {success}/{len(winrm_available)} clients")
        print("⏰ PCs will restart in 60 seconds")
        
    elif choice == "3":
        print()
        print("=" * 60)
        print("🖥️  RDP CONNECTION COMMANDS")
        print("=" * 60)
        print()
        for client in online:
            if client.get("rdp"):
                print(f"open rdp://{client['ip']}")
        print()
        print("After connecting, run this in PowerShell:")
        print("cd C:\\ProgramData\\Tenjo")
        print("curl -O https://tenjo.adilabs.id/downloads/client/update_server_config.py")
        print("python update_server_config.py")
        
    else:
        print("Exiting...")

if __name__ == "__main__":
    main()
