#!/usr/bin/env python3
"""
Tenjo Client API Tunnel
Since the Tenjo client can connect to server, we can use reverse tunnel!
This script checks if client is reporting to server, then uses client's own API
"""

import requests
import json
from datetime import datetime

SERVER_URL = "https://tenjo.adilabs.id"

def get_online_clients():
    """Get list of online clients from dashboard API"""
    try:
        # Try to get clients list (if API endpoint available)
        response = requests.get(f"{SERVER_URL}/api/clients", timeout=10)
        
        if response.status_code == 200:
            clients = response.json()
            return clients
        else:
            print(f"❌ API returned {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ Cannot connect to server API: {e}")
        return None

def check_client_version(client_id):
    """Check if client has received update"""
    try:
        response = requests.get(f"{SERVER_URL}/api/clients/{client_id}", timeout=10)
        if response.status_code == 200:
            data = response.json()
            return data
        return None
    except:
        return None

def send_update_command(client_id):
    """Send update command to client via server"""
    try:
        response = requests.post(
            f"{SERVER_URL}/api/clients/{client_id}/update",
            json={"force": True, "priority": "high"},
            timeout=10
        )
        return response.status_code == 200
    except:
        return False

def main():
    print("""
╔═══════════════════════════════════════════════════════════╗
║       TENJO CLIENT API TUNNEL                             ║
║       Use server API to communicate with clients          ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    print("🔍 Checking server for online clients...")
    print()
    
    # Try direct API
    clients = get_online_clients()
    
    if clients is None:
        print("⚠️  Cannot access API directly")
        print()
        print("Alternative: Use Tenjo's own heartbeat system!")
        print()
        print("Since clients check for updates every 5 minutes,")
        print("they will auto-update when they see v1.0.2 (priority: HIGH)")
        print()
        print("Expected timeline:")
        print("  ✅ v1.0.2 already deployed to server")
        print("  ⏰ Clients check every 5 minutes")
        print("  📥 Download starts automatically")
        print("  🔄 Update applies on next restart")
        print()
        print("But there's a problem:")
        print("  ❌ Clients are configured with localhost URL")
        print("  ❌ They cannot connect to production server")
        print("  ❌ Auto-update won't work until config is fixed")
        print()
        print("Solution: You MUST update config manually:")
        print("  1. USB updater method (recommended)")
        print("  2. Enable RDP/SMB on client PCs first")
        print("  3. Or ask IT to enable remote access")
        print()
        
        # Check if we can at least verify the update package
        print("🔍 Verifying update package on server...")
        try:
            response = requests.get(f"{SERVER_URL}/downloads/client/version.json", timeout=10)
            if response.status_code == 200:
                version_info = response.json()
                print(f"  ✅ Latest version: {version_info.get('version')}")
                print(f"  📦 Package: {version_info.get('download_url')}")
                print(f"  ⚡ Priority: {version_info.get('priority')}")
                print(f"  📝 Changes: {len(version_info.get('changes', []))} items")
            else:
                print(f"  ❌ Cannot verify ({response.status_code})")
        except Exception as e:
            print(f"  ❌ Error: {e}")
    else:
        print(f"✅ Found {len(clients)} clients")
        print()
        
        for client in clients:
            print(f"Client: {client.get('hostname', 'Unknown')}")
            print(f"  IP: {client.get('ip_address')}")
            print(f"  Version: {client.get('version', 'Unknown')}")
            print(f"  Last seen: {client.get('last_heartbeat')}")
            print(f"  Status: {'🟢 ONLINE' if client.get('is_online') else '❌ OFFLINE'}")
            print()

if __name__ == "__main__":
    main()
