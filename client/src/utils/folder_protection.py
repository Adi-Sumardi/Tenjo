"""
Folder Protection Module for Tenjo Client
Protects C:\ProgramData\Tenjo folder from unauthorized access and deletion.
"""

import os
import sys
import subprocess
import hashlib
from pathlib import Path
from typing import Tuple, Optional

# Master password for folder protection
MASTER_PASSWORD_HASH = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"  # SHA256 of "TenjoAdilabs96"

class FolderProtection:
    """Manages folder protection for Tenjo installation directory"""
    
    def __init__(self, folder_path: Optional[Path] = None):
        """
        Initialize folder protection
        
        Args:
            folder_path: Path to protect (default: C:\\ProgramData\\Tenjo on Windows)
        """
        if folder_path is None:
            if os.name == 'nt':
                folder_path = Path("C:\\ProgramData\\Tenjo")
            else:
                folder_path = Path.home() / ".tenjo"
        
        self.folder_path = Path(folder_path)
        self.is_windows = os.name == 'nt'
    
    def _verify_password(self, password: str) -> bool:
        """
        Verify master password
        
        Args:
            password: Password to verify
            
        Returns:
            True if password matches, False otherwise
        """
        password_hash = hashlib.sha256(password.encode('utf-8')).hexdigest()
        return password_hash == MASTER_PASSWORD_HASH
    
    def _run_command(self, command: str, shell: bool = True) -> Tuple[bool, str]:
        """
        Run system command
        
        Args:
            command: Command to run
            shell: Whether to run in shell
            
        Returns:
            Tuple of (success, output)
        """
        try:
            result = subprocess.run(
                command,
                shell=shell,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)
    
    def protect_folder(self, password: str) -> Tuple[bool, str]:
        """
        Apply folder protection (restrict access, deny delete)
        
        Args:
            password: Master password for verification
            
        Returns:
            Tuple of (success, message)
        """
        if not self._verify_password(password):
            return False, "Password salah!"
        
        if not self.folder_path.exists():
            return False, f"Folder tidak ditemukan: {self.folder_path}"
        
        if not self.is_windows:
            # Unix: Set strict permissions (700)
            try:
                os.chmod(self.folder_path, 0o700)
                return True, "Folder berhasil diproteksi (Unix mode)"
            except Exception as e:
                return False, f"Gagal proteksi folder: {e}"
        
        # Windows: Use ICACLS to restrict access
        commands = [
            # Remove inheritance
            f'icacls "{self.folder_path}" /inheritance:r',
            
            # Grant full control to SYSTEM
            f'icacls "{self.folder_path}" /grant:r "SYSTEM:(OI)(CI)F"',
            
            # Grant full control to Administrators
            f'icacls "{self.folder_path}" /grant:r "Administrators:(OI)(CI)F"',
            
            # Deny delete to current user (but allow read/execute)
            f'icacls "{self.folder_path}" /deny "%USERNAME%:(DE,DC)"',
        ]
        
        for cmd in commands:
            success, output = self._run_command(cmd)
            if not success:
                return False, f"Gagal execute: {cmd}\n{output}"
        
        # Set hidden + system attributes on critical files
        self._protect_critical_files()
        
        return True, "Folder berhasil diproteksi!"
    
    def unprotect_folder(self, password: str) -> Tuple[bool, str]:
        """
        Remove folder protection (for maintenance/uninstall)
        
        Args:
            password: Master password for verification
            
        Returns:
            Tuple of (success, message)
        """
        if not self._verify_password(password):
            return False, "Password salah!"
        
        if not self.folder_path.exists():
            return False, f"Folder tidak ditemukan: {self.folder_path}"
        
        if not self.is_windows:
            # Unix: Set normal permissions (755)
            try:
                os.chmod(self.folder_path, 0o755)
                return True, "Proteksi folder dihapus (Unix mode)"
            except Exception as e:
                return False, f"Gagal hapus proteksi: {e}"
        
        # Windows: Restore normal permissions
        commands = [
            # Reset to default inheritance
            f'icacls "{self.folder_path}" /reset /T',
            
            # Restore inheritance
            f'icacls "{self.folder_path}" /inheritance:e',
            
            # Grant full control to current user
            f'icacls "{self.folder_path}" /grant:r "%USERNAME%:(OI)(CI)F"',
        ]
        
        for cmd in commands:
            success, output = self._run_command(cmd)
            if not success:
                return False, f"Gagal execute: {cmd}\n{output}"
        
        # Remove hidden + system attributes
        self._unprotect_critical_files()
        
        return True, "Proteksi folder berhasil dihapus!"
    
    def _protect_critical_files(self):
        """Set hidden + system + read-only attributes on critical files"""
        if not self.is_windows:
            return
        
        critical_files = [
            ".password_hash",
            ".client_id",
            "config.json",
            "watchdog.py",
            "main.py",
        ]
        
        for filename in critical_files:
            filepath = self.folder_path / filename
            if filepath.exists():
                # Set hidden + system + read-only
                self._run_command(f'attrib +H +S +R "{filepath}"')
    
    def _unprotect_critical_files(self):
        """Remove hidden + system + read-only attributes"""
        if not self.is_windows:
            return
        
        critical_files = [
            ".password_hash",
            ".client_id",
            "config.json",
            "watchdog.py",
            "main.py",
        ]
        
        for filename in critical_files:
            filepath = self.folder_path / filename
            if filepath.exists():
                # Remove hidden + system + read-only
                self._run_command(f'attrib -H -S -R "{filepath}"')
    
    def check_protection(self) -> Tuple[bool, str]:
        """
        Check if folder is currently protected
        
        Returns:
            Tuple of (is_protected, details)
        """
        if not self.folder_path.exists():
            return False, "Folder tidak ditemukan"
        
        if not self.is_windows:
            # Unix: Check permissions
            perms = oct(os.stat(self.folder_path).st_mode)[-3:]
            if perms == "700":
                return True, f"Folder diproteksi (permissions: {perms})"
            else:
                return False, f"Folder tidak diproteksi (permissions: {perms})"
        
        # Windows: Check ICACLS
        cmd = f'icacls "{self.folder_path}"'
        success, output = self._run_command(cmd)
        
        if not success:
            return False, "Gagal check proteksi"
        
        # Check if current user has deny delete
        if "DENY" in output and "DE" in output:
            return True, "Folder diproteksi (deny delete aktif)"
        else:
            return False, "Folder tidak diproteksi"
    
    def get_folder_status(self) -> dict:
        """
        Get detailed folder protection status
        
        Returns:
            Dictionary with status information
        """
        status = {
            'exists': self.folder_path.exists(),
            'protected': False,
            'details': '',
            'size': 0,
            'file_count': 0,
        }
        
        if not status['exists']:
            return status
        
        # Check protection
        status['protected'], status['details'] = self.check_protection()
        
        # Get folder size and file count
        try:
            total_size = 0
            file_count = 0
            for path in self.folder_path.rglob('*'):
                if path.is_file():
                    total_size += path.stat().st_size
                    file_count += 1
            status['size'] = total_size
            status['file_count'] = file_count
        except:
            pass
        
        return status


def main():
    """Command-line interface for folder protection"""
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python folder_protection.py protect <password>")
        print("  python folder_protection.py unprotect <password>")
        print("  python folder_protection.py check")
        print("  python folder_protection.py status")
        sys.exit(1)
    
    fp = FolderProtection()
    command = sys.argv[1]
    
    if command == "protect":
        if len(sys.argv) < 3:
            print("Error: Password required")
            sys.exit(1)
        password = sys.argv[2]
        success, message = fp.protect_folder(password)
        print(message)
        sys.exit(0 if success else 1)
    
    elif command == "unprotect":
        if len(sys.argv) < 3:
            print("Error: Password required")
            sys.exit(1)
        password = sys.argv[2]
        success, message = fp.unprotect_folder(password)
        print(message)
        sys.exit(0 if success else 1)
    
    elif command == "check":
        is_protected, details = fp.check_protection()
        print(f"Protected: {'Yes' if is_protected else 'No'}")
        print(f"Details: {details}")
        sys.exit(0 if is_protected else 1)
    
    elif command == "status":
        status = fp.get_folder_status()
        print(f"Folder: {fp.folder_path}")
        print(f"Exists: {status['exists']}")
        print(f"Protected: {status['protected']}")
        print(f"Details: {status['details']}")
        print(f"Files: {status['file_count']}")
        print(f"Size: {status['size'] / 1024 / 1024:.2f} MB")
        sys.exit(0)
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
