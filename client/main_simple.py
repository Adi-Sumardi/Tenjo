#!/usr/bin/env python3
# Tenjo Client - SIMPLE VERSION (NO HANG)

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
from src.modules.stream_handler import StreamHandler

# Global flag for graceful shutdown
shutdown_flag = False

def signal_handler(signum, frame):
    """Handle shutdown signals gracefully"""
    global shutdown_flag
    logging.info(f"Received signal {signum}, initiating graceful shutdown...")
    shutdown_flag = True

class SimpleClient:
    def __init__(self):
        self.api_client = APIClient(Config.SERVER_URL, Config.API_KEY)
        self.stream_handler = StreamHandler(self.api_client)
        
        # Set up logging
        logging.basicConfig(
            level=getattr(logging, Config.LOG_LEVEL),
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger('SimpleClient')

    def register_client(self):
        """Register client with server"""
        try:
            client_info = {
                'client_id': Config.CLIENT_ID,
                'hostname': Config.HOSTNAME,
                'platform': Config.PLATFORM,
                'version': '1.0.0',
                'capabilities': ['streaming', 'monitoring'],
                'ip_address': '127.0.0.1',  # Required field
                'username': Config.CLIENT_USER,  # Required field  
                'os_info': f"{Config.PLATFORM} {Config.HOSTNAME}"  # Required field
            }
            
            response = self.api_client.post('/api/clients/register', client_info)
            self.logger.info("Client registered successfully")
            return True
        except Exception as e:
            self.logger.error(f"Registration failed: {e}")
            return False

    def send_heartbeat(self):
        """Send heartbeat to server"""
        try:
            heartbeat_data = {
                'client_id': Config.CLIENT_ID,
                'timestamp': time.time(),
                'status': 'active'
            }
            
            response = self.api_client.post('/api/clients/heartbeat', heartbeat_data)
            self.logger.debug("Heartbeat sent")
            return True
        except Exception as e:
            self.logger.debug(f"Heartbeat failed: {e}")
            return False

    def run(self):
        """Main execution loop - SIMPLE VERSION"""
        global shutdown_flag
        
        self.logger.info("=== SIMPLE TENJO CLIENT STARTING ===")
        
        # Register with server (optional - skip if fails)
        if not self.register_client():
            self.logger.warning("Client registration failed, but continuing anyway...")
        
        # Start stream handler in separate thread
        stream_thread = None
        try:
            stream_thread = threading.Thread(
                target=self.stream_handler.start_streaming,
                daemon=True,
                name="StreamHandler"
            )
            stream_thread.start()
            self.logger.info("Stream handler started")
        except Exception as e:
            self.logger.error(f"Failed to start stream handler: {e}")
        
        # Simple main loop
        heartbeat_counter = 0
        while not shutdown_flag:
            try:
                heartbeat_counter += 1
                
                # Send heartbeat every 30 seconds
                if heartbeat_counter % 6 == 0:  # 6 * 5 = 30 seconds
                    self.send_heartbeat()
                
                # Log status every 5 minutes
                if heartbeat_counter % 60 == 0:  # 60 * 5 = 300 seconds = 5 minutes
                    self.logger.info(f"Simple client running - {heartbeat_counter} cycles completed")
                
                time.sleep(5)  # 5 second intervals
                
            except KeyboardInterrupt:
                self.logger.info("Received keyboard interrupt")
                break
            except Exception as e:
                self.logger.error(f"Main loop error: {e}")
                time.sleep(10)
        
        self.logger.info("Simple client shutting down...")

def main():
    """Entry point"""
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Create and run simple client
    client = SimpleClient()
    client.run()

if __name__ == "__main__":
    main()
