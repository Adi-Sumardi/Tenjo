#!/usr/bin/env python3
"""
Remote Configuration Update Tool
Updates server URL on already-installed clients without reinstallation
"""

import os
import sys
import json
from pathlib import Path
import platform

def get_config_path():
    """Get the client configuration file path based on OS"""
    system = platform.system()
    
    if system == 'Windows':
        base_path = Path("C:/ProgramData/Tenjo")
    elif system == 'Darwin':
        base_path = Path("/usr/local/tenjo")
    else:  # Linux
        base_path = Path("/opt/tenjo")
    
    config_file = base_path / "src" / "core" / "config.py"
    override_file = base_path / "server_override.json"
    
    return config_file, override_file

def create_server_override(server_url):
    """Create server_override.json to force production server"""
    _, override_file = get_config_path()
    
    override_data = {
        "server_url": server_url,
        "api_endpoint": f"{server_url}/api",
        "updated_at": "2025-10-07T00:00:00Z",
        "reason": "Production server migration"
    }
    
    try:
        override_file.parent.mkdir(parents=True, exist_ok=True)
        with open(override_file, 'w') as f:
            json.dump(override_data, f, indent=2)
        print(f"✅ Created server override: {override_file}")
        print(f"   Server URL: {server_url}")
        return True
    except Exception as e:
        print(f"❌ Failed to create override: {e}")
        return False

def update_config_file(server_url):
    """Update DEFAULT_SERVER_URL in config.py"""
    config_file, _ = get_config_path()
    
    if not config_file.exists():
        print(f"❌ Config file not found: {config_file}")
        return False
    
    try:
        # Read current config
        with open(config_file, 'r') as f:
            content = f.read()
        
        # Replace DEFAULT_SERVER_URL
        if 'DEFAULT_SERVER_URL' in content:
            # Find and replace the line
            lines = content.split('\n')
            new_lines = []
            for line in lines:
                if 'DEFAULT_SERVER_URL = os.getenv' in line:
                    # Replace with production URL
                    new_line = f'    DEFAULT_SERVER_URL = os.getenv(\'TENJO_SERVER_URL\', "{server_url}")  # Updated to production'
                    new_lines.append(new_line)
                    print(f"✅ Updated DEFAULT_SERVER_URL to: {server_url}")
                else:
                    new_lines.append(line)
            
            # Write back
            with open(config_file, 'w') as f:
                f.write('\n'.join(new_lines))
            
            return True
        else:
            print("❌ DEFAULT_SERVER_URL not found in config")
            return False
            
    except Exception as e:
        print(f"❌ Failed to update config: {e}")
        return False

def restart_client_service():
    """Restart the Tenjo client service"""
    system = platform.system()
    
    print("\n🔄 Restarting client service...")
    
    try:
        if system == 'Windows':
            os.system('net stop "Tenjo Client" >nul 2>&1')
            os.system('net start "Tenjo Client" >nul 2>&1')
        elif system == 'Darwin':
            os.system('launchctl unload ~/Library/LaunchAgents/com.tenjo.client.plist 2>/dev/null')
            os.system('launchctl load ~/Library/LaunchAgents/com.tenjo.client.plist 2>/dev/null')
        else:  # Linux
            os.system('systemctl --user restart tenjo-client 2>/dev/null')
            os.system('systemctl restart tenjo-client 2>/dev/null')
        
        print("✅ Service restart initiated")
        return True
    except Exception as e:
        print(f"⚠️  Service restart may have failed: {e}")
        print("   Please restart manually or reboot the computer")
        return False

def main():
    print("="*70)
    print("🔧 TENJO CLIENT - SERVER URL UPDATE TOOL")
    print("="*70)
    print()
    
    # Target production server
    production_url = "https://tenjo.adilabs.id"
    
    print(f"📡 Target Server: {production_url}")
    print(f"💻 Operating System: {platform.system()}")
    print()
    
    # Check if running with admin/root privileges
    is_admin = os.getuid() == 0 if hasattr(os, 'getuid') else False
    if not is_admin and platform.system() != 'Windows':
        print("⚠️  WARNING: Not running as admin/root")
        print("   Some operations may fail without proper permissions")
        print()
    
    # Method 1: Create server_override.json (safer, doesn't modify code)
    print("📝 Method 1: Creating server override file...")
    override_success = create_server_override(production_url)
    print()
    
    # Method 2: Update config.py directly (more permanent)
    print("📝 Method 2: Updating configuration file...")
    config_success = update_config_file(production_url)
    print()
    
    if override_success or config_success:
        print("✅ Configuration updated successfully!")
        print()
        
        # Restart service
        restart_success = restart_client_service()
        print()
        
        if restart_success:
            print("="*70)
            print("✅ UPDATE COMPLETE!")
            print("="*70)
            print()
            print("Client will now connect to: https://tenjo.adilabs.id")
            print("Check dashboard in 1-2 minutes to see client ONLINE")
        else:
            print("="*70)
            print("⚠️  UPDATE COMPLETE (Manual Restart Required)")
            print("="*70)
            print()
            print("Please restart the computer or restart Tenjo service manually")
            print(f"After restart, client will connect to: {production_url}")
    else:
        print("❌ Configuration update failed!")
        print()
        print("Manual steps required:")
        print("1. Open terminal/cmd as admin")
        print("2. Navigate to Tenjo installation directory")
        print(f"3. Edit config.py: DEFAULT_SERVER_URL = '{production_url}'")
        print("4. Restart computer")
    
    print()
    print("="*70)

if __name__ == "__main__":
    main()
