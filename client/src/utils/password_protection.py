"""
Password Protection Module for Tenjo Client
Provides password hashing, validation, and management for uninstall protection.
"""

import hashlib
import os
import json
from pathlib import Path
from typing import Optional, Tuple

class PasswordProtection:
    """Manages password protection for uninstall operations"""
    
    def __init__(self, config_dir: Optional[Path] = None):
        """
        Initialize password protection
        
        Args:
            config_dir: Directory to store password config (default: C:\\ProgramData\\Tenjo on Windows)
        """
        if config_dir is None:
            if os.name == 'nt':
                config_dir = Path("C:\\ProgramData\\Tenjo")
            else:
                config_dir = Path.home() / ".tenjo"
        
        self.config_dir = Path(config_dir)
        self.password_file = self.config_dir / ".password_hash"
        self.config_dir.mkdir(parents=True, exist_ok=True)
    
    def _hash_password(self, password: str) -> str:
        """
        Hash password using SHA256
        
        Args:
            password: Plain text password
            
        Returns:
            Hashed password (hex string)
        """
        return hashlib.sha256(password.encode('utf-8')).hexdigest()
    
    def set_password(self, password: str) -> bool:
        """
        Set new password (hashed and saved)
        
        Args:
            password: Plain text password to set
            
        Returns:
            True if successful, False otherwise
        """
        try:
            password_hash = self._hash_password(password)
            
            # Save hash to file with restricted permissions
            with open(self.password_file, 'w') as f:
                json.dump({
                    'password_hash': password_hash,
                    'version': '1.0'
                }, f)
            
            # Set file permissions (read-only for current user)
            if os.name == 'nt':
                # Windows: Use icacls to restrict access
                os.system(f'icacls "{self.password_file}" /inheritance:r /grant:r "%USERNAME%":R')
            else:
                # Unix: chmod 400
                os.chmod(self.password_file, 0o400)
            
            return True
        except Exception as e:
            print(f"Error setting password: {e}")
            return False
    
    def verify_password(self, password: str) -> bool:
        """
        Verify if password is correct
        
        Args:
            password: Plain text password to verify
            
        Returns:
            True if password matches, False otherwise
        """
        try:
            if not self.password_file.exists():
                # No password set yet, deny by default
                return False
            
            with open(self.password_file, 'r') as f:
                data = json.load(f)
                stored_hash = data.get('password_hash', '')
            
            input_hash = self._hash_password(password)
            return input_hash == stored_hash
        except Exception as e:
            print(f"Error verifying password: {e}")
            return False
    
    def change_password(self, old_password: str, new_password: str) -> Tuple[bool, str]:
        """
        Change password (requires old password verification)
        
        Args:
            old_password: Current password
            new_password: New password to set
            
        Returns:
            Tuple of (success: bool, message: str)
        """
        if not self.verify_password(old_password):
            return False, "Password lama salah"
        
        if len(new_password) < 6:
            return False, "Password baru minimal 6 karakter"
        
        if self.set_password(new_password):
            return True, "Password berhasil diubah"
        else:
            return False, "Gagal mengubah password"
    
    def is_password_set(self) -> bool:
        """
        Check if password has been set
        
        Returns:
            True if password file exists, False otherwise
        """
        return self.password_file.exists()
    
    def reset_password(self, new_password: str, force: bool = False) -> Tuple[bool, str]:
        """
        Reset password (for admin use only)
        
        Args:
            new_password: New password to set
            force: If True, reset without verification (admin override)
            
        Returns:
            Tuple of (success: bool, message: str)
        """
        if not force:
            return False, "Reset password memerlukan mode force (admin only)"
        
        if len(new_password) < 6:
            return False, "Password minimal 6 karakter"
        
        if self.set_password(new_password):
            return True, "Password berhasil direset"
        else:
            return False, "Gagal mereset password"


def main():
    """Test password protection"""
    import sys
    
    pp = PasswordProtection()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python password_protection.py set <password>")
        print("  python password_protection.py verify <password>")
        print("  python password_protection.py change <old_password> <new_password>")
        print("  python password_protection.py reset <new_password>")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "set":
        if len(sys.argv) < 3:
            print("Error: Password required")
            sys.exit(1)
        password = sys.argv[2]
        if pp.set_password(password):
            print("[OK] Password berhasil diset")
        else:
            print("[ERROR] Gagal set password")
    
    elif command == "verify":
        if len(sys.argv) < 3:
            print("Error: Password required")
            sys.exit(1)
        password = sys.argv[2]
        if pp.verify_password(password):
            print("[OK] Password benar")
            sys.exit(0)
        else:
            print("[ERROR] Password salah")
            sys.exit(1)
    
    elif command == "change":
        if len(sys.argv) < 4:
            print("Error: Old and new password required")
            sys.exit(1)
        old_password = sys.argv[2]
        new_password = sys.argv[3]
        success, message = pp.change_password(old_password, new_password)
        print(message)
        sys.exit(0 if success else 1)
    
    elif command == "reset":
        if len(sys.argv) < 3:
            print("Error: New password required")
            sys.exit(1)
        new_password = sys.argv[2]
        success, message = pp.reset_password(new_password, force=True)
        print(message)
        sys.exit(0 if success else 1)
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
