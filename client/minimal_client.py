#!/usr/bin/env python3
# Ultra minimal client - no hanging version

import sys
import os
import time
import logging

sys.path.append('src')

# Set up basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

try:
    from src.core.config import Config
    from src.utils.api_client import APIClient
    
    logger.info("=== ULTRA MINIMAL CLIENT START ===")
    logger.info(f"Server: {Config.SERVER_URL}")
    
    # Create API client
    api_client = APIClient(Config.SERVER_URL, Config.API_KEY)
    
    # Simple heartbeat loop - NO STREAMING
    loop_count = 0
    while True:
        try:
            loop_count += 1
            logger.info(f"Heartbeat loop #{loop_count}")
            
            # Simple heartbeat only
            try:
                response = api_client.post("/api/clients/heartbeat", {
                    "client_id": Config.CLIENT_ID,
                    "timestamp": time.time()
                })
                logger.info("Heartbeat sent successfully")
            except Exception as e:
                logger.debug(f"Heartbeat failed: {e}")
            
            time.sleep(30)  # 30 second interval
            
        except KeyboardInterrupt:
            logger.info("Interrupted by user")
            break
        except Exception as e:
            logger.error(f"Loop error: {e}")
            time.sleep(60)
            
except Exception as e:
    logger.error(f"Fatal error: {e}")
    sys.exit(1)
