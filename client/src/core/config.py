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
    # Server Configuration - LOCAL TESTING MODE
    SERVER_URL = os.getenv('TENJO_SERVER_URL', "http://127.0.0.1:8000")  # Development server (LOCAL)
    # SERVER_URL = "http://103.129.149.67"  # Production server IP (COMMENTED FOR TESTING)
    API_ENDPOINT = f"{SERVER_URL}/api"
    API_KEY = os.getenv('TENJO_API_KEY', "tenjo-api-key-2024")

    # Client Identification - Persistent hardware-based ID
    @staticmethod
    def generate_hardware_fingerprint():
        """
        Generate PERSISTENT client ID based on hardware fingerprint.
        This ensures same device always gets same client_id.
        Uses: MAC address + hostname + username for uniqueness
        """
        import hashlib
        
        # Get unique hardware identifiers
        mac_address = ':'.join(['{:02x}'.format((uuid.getnode() >> elements) & 0xff) 
                               for elements in range(0,2*6,2)][::-1])
        hostname = socket.gethostname()
        username = os.getenv('USER', os.getenv('USERNAME', 'unknown'))
        
        # Create deterministic UUID based on hardware + user
        # This ensures same device + same user = same client_id
        unique_string = f"{mac_address}-{hostname}-{username}"
        hash_object = hashlib.sha256(unique_string.encode())
        
        # Convert to UUID format for compatibility
        hex_dig = hash_object.hexdigest()
        client_uuid = f"{hex_dig[:8]}-{hex_dig[8:12]}-{hex_dig[12:16]}-{hex_dig[16:20]}-{hex_dig[20:32]}"
        
        return client_uuid
    
    @staticmethod
    def get_persistent_client_id():
        """
        Get or create persistent client ID from file cache.
        This prevents client_id regeneration on every restart.
        """
        id_file = os.path.join(Config.DATA_DIR, '.client_id')
        
        # Try to read existing ID
        if os.path.exists(id_file):
            try:
                with open(id_file, 'r') as f:
                    stored_id = f.read().strip()
                    if stored_id and len(stored_id) == 36:  # Valid UUID format
                        return stored_id
            except Exception:
                pass
        
        # Generate new ID based on hardware fingerprint
        new_id = Config.generate_hardware_fingerprint()
        
        # Save to file for persistence
        try:
            os.makedirs(Config.DATA_DIR, exist_ok=True)
            with open(id_file, 'w') as f:
                f.write(new_id)
        except Exception:
            pass
        
        return new_id
    
    # Use persistent client ID (will be initialized after DATA_DIR is set)
    CLIENT_ID = None  # Will be set after init_directories()
    CLIENT_NAME = socket.gethostname()
    CLIENT_USER = os.getenv('USER', os.getenv('USERNAME', 'unknown'))
    HOSTNAME = socket.gethostname()
    PLATFORM = platform.system()
    IP_ADDRESS = get_local_ip()  # Get real IP address

    # Monitoring Settings
    SCREENSHOT_INTERVAL = int(os.getenv('TENJO_SCREENSHOT_INTERVAL', '300'))  # seconds (5 minutes) - Smart interval
    BROWSER_CHECK_INTERVAL = 30  # seconds - check browser status more frequently
    PROCESS_CHECK_INTERVAL = 90  # seconds
    HEARTBEAT_INTERVAL = 300  # seconds (5 minutes)

    # Features
    SCREENSHOT_ENABLED = True
    SCREENSHOT_ONLY_WHEN_BROWSER_ACTIVE = True  # Only capture when browser is open (saves storage + privacy)
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
        
        # Initialize CLIENT_ID after directories are ready
        if cls.CLIENT_ID is None:
            cls.CLIENT_ID = cls.get_persistent_client_id()

# Initialize directories and CLIENT_ID
Config.init_directories()
