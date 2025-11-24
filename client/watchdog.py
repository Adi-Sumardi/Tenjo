#!/usr/bin/env python3
"""
Tenjo Watchdog Service
Monitors and restarts Tenjo client if it dies
"""

import psutil
import subprocess
import time
import sys
import os
import logging
from pathlib import Path

# Configuration
CLIENT_DIR = Path("C:/ProgramData/Tenjo") if os.name == 'nt' else Path.home() / ".tenjo"
CLIENT_SCRIPT = CLIENT_DIR / "main.py"
CHECK_INTERVAL = 30  # seconds
RESTART_DELAY = 10  # seconds
LOG_FILE = CLIENT_DIR / "logs" / "watchdog.log"

# Setup logging
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

def is_client_running():
    """Check if Tenjo client is running"""
    try:
        for proc in psutil.process_iter(['name', 'cmdline', 'cwd']):
            try:
                name = proc.info['name']
                if not name:
                    continue
                    
                # Check if it's Python process
                if 'python' in name.lower():
                    cmdline = proc.info['cmdline']
                    if not cmdline:
                        continue
                    
                    # Check if running our main.py
                    cmdline_str = ' '.join(cmdline)
                    if 'main.py' in cmdline_str:
                        # Check if it's in Tenjo directory
                        cwd = proc.info.get('cwd', '')
                        if 'Tenjo' in cwd or 'tenjo' in cwd:
                            return True, proc.pid
                            
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                continue
                
    except Exception as e:
        logging.error(f"Error checking client status: {e}")
        
    return False, None

def start_client():
    """Start Tenjo client"""
    try:
        if not CLIENT_SCRIPT.exists():
            logging.error(f"Client script not found: {CLIENT_SCRIPT}")
            return False
            
        logging.info(f"Starting Tenjo client from {CLIENT_DIR}")
        
        if os.name == 'nt':
            # FIX #54: Use getattr() for CREATE_NO_WINDOW (Python 3.6 compatibility)
            creation_flags = getattr(subprocess, 'CREATE_NO_WINDOW', 0)
            # Windows: Start hidden
            subprocess.Popen(
                [sys.executable, str(CLIENT_SCRIPT)],
                cwd=str(CLIENT_DIR),
                creationflags=creation_flags,
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        else:
            # Unix: Start detached
            subprocess.Popen(
                [sys.executable, str(CLIENT_SCRIPT)],
                cwd=str(CLIENT_DIR),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                preexec_fn=os.setpgrp
            )
            
        logging.info("Client started successfully")
        return True
        
    except Exception as e:
        logging.error(f"Failed to start client: {e}")
        return False

def main():
    """Main watchdog loop"""
    logging.info("=" * 50)
    logging.info("Tenjo Watchdog Service Started")
    logging.info(f"Client directory: {CLIENT_DIR}")
    logging.info(f"Check interval: {CHECK_INTERVAL}s")
    logging.info("=" * 50)
    
    consecutive_failures = 0
    max_failures = 5
    
    while True:
        try:
            is_running, pid = is_client_running()
            
            if is_running:
                if consecutive_failures > 0:
                    logging.info(f"Client recovered (PID: {pid})")
                    consecutive_failures = 0
                else:
                    logging.debug(f"Client running normally (PID: {pid})")
            else:
                consecutive_failures += 1
                logging.warning(f"Client not running! (Attempt {consecutive_failures}/{max_failures})")
                
                if consecutive_failures >= max_failures:
                    logging.error("Client failed to start after multiple attempts")
                    logging.error("Waiting 5 minutes before retry...")
                    time.sleep(300)  # 5 minutes
                    consecutive_failures = 0
                    continue
                
                logging.info(f"Waiting {RESTART_DELAY}s before restart...")
                time.sleep(RESTART_DELAY)
                
                if start_client():
                    logging.info("Client restarted successfully")
                    time.sleep(5)  # Give it time to start
                else:
                    logging.error("Failed to restart client")
                    
        except KeyboardInterrupt:
            logging.info("Watchdog stopped by user")
            break
        except Exception as e:
            logging.error(f"Watchdog error: {e}")
            
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.critical(f"Watchdog crashed: {e}")
        sys.exit(1)
