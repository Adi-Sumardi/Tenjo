# Tenjo Client Configuration for Yayasans-MacBook-Air.local
import json
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
    # Server Configuration - AUTO-DETECT MODE
    # Priority: ENV VAR > server_override.json > local dev > production
    DEFAULT_SERVER_URL = os.getenv('TENJO_SERVER_URL', "http://127.0.0.1:8000")  # Local development default
    PRODUCTION_SERVER_URL = "https://tenjo.adilabs.id"  # Production domain
    LEGACY_SERVER_URLS = [
        "http://103.129.149.67",
        "https://103.129.149.67",
    ]
    SERVER_OVERRIDE_FILE = 'server_override.json'

    SERVER_URL = DEFAULT_SERVER_URL.rstrip('/')
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
        Get or create persistent client ID using multiple fallback methods.
        Tries multiple approaches to ensure persistence across restarts.
        """
        
        # Method 1: Try Windows Registry (Windows only - most reliable)
        if platform.system() == 'Windows':
            try:
                import winreg
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Tenjo", 0, winreg.KEY_READ)
                client_id, _ = winreg.QueryValueEx(key, "ClientID")
                winreg.CloseKey(key)
                
                if client_id and len(client_id) == 36:
                    return client_id
            except Exception:
                # Catch all exceptions (ImportError, WindowsError, FileNotFoundError, OSError, etc.)
                pass
        
        # Method 2: Try file cache in DATA_DIR
        id_file = os.path.join(Config.DATA_DIR, '.client_id')
        if os.path.exists(id_file):
            try:
                with open(id_file, 'r') as f:
                    stored_id = f.read().strip()
                    if stored_id and len(stored_id) == 36:  # Valid UUID format
                        # If found in file, also save to registry (Windows) for redundancy
                        if platform.system() == 'Windows':
                            try:
                                import winreg
                                key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, r"Software\Tenjo")
                                winreg.SetValueEx(key, "ClientID", 0, winreg.REG_SZ, stored_id)
                                winreg.CloseKey(key)
                            except:
                                pass
                        return stored_id
            except Exception:
                pass
        
        # Method 3: Generate new ID using hardware fingerprint (deterministic)
        # This ensures same hardware always gets same ID even if file/registry lost
        new_id = Config.generate_hardware_fingerprint()
        
        # Save using ALL available methods for maximum redundancy
        
        # Save to file
        try:
            os.makedirs(Config.DATA_DIR, exist_ok=True)
            with open(id_file, 'w') as f:
                f.write(new_id)
            # Make file read-only to prevent accidental deletion (Unix-like systems)
            if platform.system() != 'Windows':
                os.chmod(id_file, 0o444)
        except Exception:
            pass
        
        # Save to Windows Registry
        if platform.system() == 'Windows':
            try:
                import winreg
                key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, r"Software\Tenjo")
                winreg.SetValueEx(key, "ClientID", 0, winreg.REG_SZ, new_id)
                winreg.CloseKey(key)
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
    HEARTBEAT_INTERVAL = int(os.getenv('TENJO_HEARTBEAT_INTERVAL', '300'))  # seconds

    # Features
    SCREENSHOT_ENABLED = True
    SCREENSHOT_ONLY_WHEN_BROWSER_ACTIVE = True  # Only capture when browser is open (saves storage + privacy)
    BROWSER_MONITORING = True
    PROCESS_MONITORING = True
    STEALTH_MODE = os.getenv('TENJO_STEALTH_MODE', 'true').lower() == 'true'
    AUTO_START_VIDEO_STREAMING = True  # ENABLED for production

    # Paths - Use absolute paths based on OS
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    @staticmethod
    def get_data_directory():
        """
        Get platform-specific data directory that's always writable.
        Uses OS-appropriate locations that don't require admin permissions.
        """
        if platform.system() == 'Windows':
            # Use %APPDATA%\Tenjo (e.g., C:\Users\Username\AppData\Roaming\Tenjo)
            return os.path.join(os.getenv('APPDATA', ''), 'Tenjo')
        elif platform.system() == 'Darwin':  # macOS
            # Use ~/Library/Application Support/Tenjo
            from pathlib import Path
            return os.path.join(Path.home(), 'Library', 'Application Support', 'Tenjo')
        else:  # Linux
            # Use ~/.tenjo
            from pathlib import Path
            return os.path.join(Path.home(), '.tenjo')
    
    @staticmethod
    def get_log_directory():
        """Get platform-specific log directory"""
        if platform.system() == 'Windows':
            # Use %LOCALAPPDATA%\Tenjo\logs
            return os.path.join(os.getenv('LOCALAPPDATA', ''), 'Tenjo', 'logs')
        else:
            # Use DATA_DIR/logs for Unix-like systems
            return os.path.join(Config.get_data_directory(), 'logs')
    
    LOG_DIR = None  # Will be set in init_directories()
    DATA_DIR = None  # Will be set in init_directories()

    # Logging
    LOG_LEVEL = os.getenv("TENJO_LOG_LEVEL", "ERROR")
    LOG_FILE = None  # Will be set in init_directories()

    @classmethod
    def init_directories(cls):
        """Create directories if they don't exist"""
        # Set directory paths based on OS
        cls.DATA_DIR = cls.get_data_directory()
        cls.LOG_DIR = cls.get_log_directory()
        
        # Create directories
        os.makedirs(cls.LOG_DIR, exist_ok=True)
        os.makedirs(cls.DATA_DIR, exist_ok=True)
        
        # Refresh server settings based on overrides (if available)
        cls.refresh_server_settings()

        # Update LOG_FILE path after LOG_DIR is set
        cls.LOG_FILE = os.path.join(cls.LOG_DIR, f"tenjo_client_{datetime.now().strftime('%Y%m%d')}.log")
        
        # Initialize CLIENT_ID after directories are ready
        if cls.CLIENT_ID is None:
            cls.CLIENT_ID = cls.get_persistent_client_id()

    @classmethod
    def refresh_server_settings(cls, server_url=None, persist=False):
        """Refresh server URL and API endpoint, optionally persisting override."""
        candidate_url = server_url or cls._load_server_override() or cls.DEFAULT_SERVER_URL
        sanitized = cls._sanitize_server_url(candidate_url)

        cls.SERVER_URL = sanitized
        cls.API_ENDPOINT = f"{cls.SERVER_URL}/api"

        if persist:
            cls.persist_server_override(cls.SERVER_URL)

        return cls.SERVER_URL

    @classmethod
    def persist_server_override(cls, server_url):
        """Persist preferred server URL to override file."""
        try:
            override_path = cls._resolve_override_path()
            os.makedirs(os.path.dirname(override_path), exist_ok=True)
            with open(override_path, 'w', encoding='utf-8') as fh:
                json.dump({'server_url': cls._sanitize_server_url(server_url)}, fh)
            return True
        except Exception:
            return False

    @classmethod
    def _load_server_override(cls):
        override_path = cls._resolve_override_path()
        if not os.path.exists(override_path):
            return None

        try:
            with open(override_path, 'r', encoding='utf-8') as fh:
                data = json.load(fh)
                override_url = data.get('server_url')
                if override_url:
                    return override_url
        except Exception:
            return None

        return None

    @classmethod
    def _resolve_override_path(cls):
        base_dir = cls.DATA_DIR or cls.get_data_directory()
        return os.path.join(base_dir, cls.SERVER_OVERRIDE_FILE)

    @staticmethod
    def _sanitize_server_url(url):
        if not url:
            return Config.DEFAULT_SERVER_URL.rstrip('/')

        sanitized = url.strip()
        if not sanitized.startswith(('http://', 'https://')):
            sanitized = f"https://{sanitized.lstrip('/')}"

        return sanitized.rstrip('/')

# Initialize directories and CLIENT_ID
Config.init_directories()
