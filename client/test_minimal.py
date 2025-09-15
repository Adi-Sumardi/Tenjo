#!/usr/bin/env python3
# Test minimal client functionality

import sys
import os
sys.path.append('src')

from src.utils.api_client import APIClient
from src.core.config import Config

print("=== MINIMAL CLIENT TEST ===")
print(f"Server URL: {Config.SERVER_URL}")
print(f"Client ID: {Config.CLIENT_ID}")
print(f"Auto-start: {Config.AUTO_START_VIDEO_STREAMING}")

# Test API connection
try:
    api_client = APIClient(Config.SERVER_URL, Config.API_KEY)
    response = api_client.get("/")
    print(f"Server connection: OK")
except Exception as e:
    print(f"Server connection: FAILED - {e}")

# Test stream handler import
try:
    from src.modules.stream_handler import StreamHandler
    handler = StreamHandler(api_client)
    print(f"Stream handler: OK")
except Exception as e:
    print(f"Stream handler: FAILED - {e}")

print("=== TEST COMPLETED ===")
