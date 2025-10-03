"""
Tenjo Client Auto-Update Module
Checks for updates from server and auto-updates if new version available
"""

import os
import sys
import json
import hashlib
import tarfile
import shutil
import platform
import subprocess
from pathlib import Path
from datetime import datetime
import requests


class ClientUpdater:
    """Handles automatic client updates from server"""
    
    # Current client version
    CURRENT_VERSION = "2025.10.02"  # Format: YYYY.MM.DD[.patch]
    
    def __init__(self, config):
        self.config = config
        self.server_url = config.SERVER_URL
        self.version_check_url = f"{self.server_url}/downloads/client/version.json"
        self.download_base_url = f"{self.server_url}/downloads/client"
        
        # Update paths based on OS
        if platform.system() == 'Windows':
            self.install_path = Path("C:/ProgramData/Tenjo")
            self.backup_path = Path("C:/ProgramData/Tenjo_backups")
        elif platform.system() == 'Darwin':  # macOS
            self.install_path = Path("/usr/local/tenjo")
            self.backup_path = Path("/usr/local/tenjo_backups")
        else:  # Linux
            self.install_path = Path("/opt/tenjo")
            self.backup_path = Path("/opt/tenjo_backups")
        
        self.temp_path = Path("/tmp/tenjo_update") if platform.system() != 'Windows' else Path(os.getenv('TEMP')) / "tenjo_update"
    
    def check_for_updates(self):
        """
        Check if newer version is available on server
        Checks TWO sources:
        1. Server push trigger (via API - PRIORITY)
        2. Public version.json file (fallback)
        Returns: (has_update: bool, version_info: dict)
        """
        try:
            # Method 1: Check if server pushed an update trigger (SILENT PUSH)
            push_update = self._check_push_update()
            if push_update:
                return True, push_update
            
            # Method 2: Check public version file (AUTO-UPDATE)
            response = requests.get(self.version_check_url, timeout=10)
            response.raise_for_status()
            
            version_info = response.json()
            server_version = version_info.get('version', '')
            
            # Compare versions
            if self._is_newer_version(server_version, self.CURRENT_VERSION):
                return True, version_info
            
            return False, None
            
        except Exception as e:
            # Silent fail - don't show errors to user
            return False, None
    
    def _check_push_update(self):
        """
        Check if server has pushed an update trigger via API
        This is for SILENT deployment from VPS
        Returns: version_info dict or None
        """
        try:
            # Get client_id
            client_id = self.config.CLIENT_ID
            
            # Check server for pending update
            check_url = f"{self.config.API_ENDPOINT}/clients/{client_id}/check-update"
            response = requests.get(check_url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('has_update', False):
                    # Server has pushed an update
                    return {
                        'version': data.get('version'),
                        'download_url': data.get('update_url'),
                        'changes': data.get('changes', []),
                        'pushed': True  # Mark as server-pushed
                    }
            
            return None
            
        except Exception:
            return None
    
    def _is_newer_version(self, server_version, current_version):
        """Compare version strings (format: YYYY.MM.DD or YYYYMMDD_HHMM)"""
        try:
            # Normalize versions to comparable format
            server_parts = server_version.replace('_', '.').replace('-', '.').split('.')
            current_parts = current_version.replace('_', '.').replace('-', '.').split('.')
            
            # Pad to same length
            max_len = max(len(server_parts), len(current_parts))
            server_parts += ['0'] * (max_len - len(server_parts))
            current_parts += ['0'] * (max_len - len(current_parts))
            
            # Compare numerically
            for s, c in zip(server_parts, current_parts):
                try:
                    s_int = int(''.join(filter(str.isdigit, s)) or '0')
                    c_int = int(''.join(filter(str.isdigit, c)) or '0')
                    if s_int > c_int:
                        return True
                    elif s_int < c_int:
                        return False
                except ValueError:
                    continue
            
            return False
            
        except Exception:
            return False
    
    def download_update(self, version_info):
        """
        Download update package from server
        Supports both pushed updates and auto-updates
        Returns: (success: bool, package_path: Path)
        """
        try:
            # Check if this is a pushed update with direct URL
            if version_info.get('pushed') and version_info.get('download_url'):
                download_url = version_info['download_url']
            else:
                # Regular auto-update
                version = version_info.get('version', 'latest')
                package_name = f"tenjo_client_{version}.tar.gz"
                download_url = f"{self.download_base_url}/{package_name}"
            
            # SILENT MODE - no output to user
            # (only print if not in stealth mode)
            
            # Create temp directory
            self.temp_path.mkdir(parents=True, exist_ok=True)
            package_path = self.temp_path / "client.tar.gz"
            
            # Download silently (no progress output in production)
            response = requests.get(download_url, stream=True, timeout=30)
            response.raise_for_status()
            
            with open(package_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            
            return True, package_path
            
        except Exception as e:
            # Silent fail - log but don't show to user
            return False, None
    
    def backup_current_installation(self):
        """Backup current installation before update"""
        try:
            # Create backup directory
            self.backup_path.mkdir(parents=True, exist_ok=True)
            
            # Create timestamped backup
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_dir = self.backup_path / f"backup_{timestamp}"
            
            print(f"Creating backup: {backup_dir}")
            
            # Copy current installation
            if self.install_path.exists():
                shutil.copytree(self.install_path, backup_dir, 
                              ignore=shutil.ignore_patterns('*.pyc', '__pycache__', 'logs', 'data'))
                print("✓ Backup created")
                return True, backup_dir
            
            return True, None
            
        except Exception as e:
            print(f"✗ Backup failed: {e}")
            return False, None
    
    def apply_update(self, package_path):
        """
        Apply downloaded update
        Returns: success: bool
        """
        try:
            print("Applying update...")
            
            # Extract to temp location
            extract_path = self.temp_path / "extracted"
            extract_path.mkdir(parents=True, exist_ok=True)
            
            with tarfile.open(package_path, 'r:gz') as tar:
                tar.extractall(extract_path)
            
            print("✓ Package extracted")
            
            # Stop current process (will restart automatically)
            print("Preparing to restart...")
            
            # Copy new files to install path
            for item in extract_path.iterdir():
                dest = self.install_path / item.name
                if item.is_file():
                    shutil.copy2(item, dest)
                elif item.is_dir():
                    if dest.exists():
                        shutil.rmtree(dest)
                    shutil.copytree(item, dest)
            
            print("✓ Update applied")
            
            # Update version file
            version_file = self.install_path / ".version"
            with open(version_file, 'w') as f:
                f.write(datetime.now().strftime('%Y.%m.%d'))
            
            return True
            
        except Exception as e:
            print(f"✗ Update failed: {e}")
            return False
    
    def restart_client(self):
        """Restart client application"""
        try:
            print("Restarting client...")
            
            # Get path to main.py
            main_py = self.install_path / "main.py"
            
            if platform.system() == 'Windows':
                # Windows: Use pythonw.exe to run hidden
                subprocess.Popen(
                    ['pythonw.exe', str(main_py)],
                    cwd=str(self.install_path),
                    creationflags=subprocess.CREATE_NO_WINDOW
                )
            else:
                # Unix: Fork and detach
                subprocess.Popen(
                    ['python3', str(main_py)],
                    cwd=str(self.install_path),
                    start_new_session=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
            
            print("✓ Client restarted")
            
            # Exit current process
            sys.exit(0)
            
        except Exception as e:
            print(f"✗ Restart failed: {e}")
            return False
    
    def cleanup_temp(self):
        """Remove temporary update files"""
        try:
            if self.temp_path.exists():
                shutil.rmtree(self.temp_path)
        except Exception:
            pass
    
    def notify_update_completed(self, version):
        """
        Notify server that update was completed successfully
        This is for tracking pushed updates
        """
        try:
            client_id = self.config.CLIENT_ID
            notify_url = f"{self.config.API_ENDPOINT}/clients/{client_id}/update-completed"
            
            requests.post(
                notify_url,
                json={'version': version, 'completed_at': datetime.now().isoformat()},
                timeout=5
            )
        except Exception:
            pass  # Silent fail
    
    def perform_update(self, silent=True):
        """
        Main update flow: check → download → backup → apply → restart
        Args:
            silent: If True, no output to user (STEALTH MODE)
        Returns: success: bool
        """
        try:
            # Step 1: Check for updates
            has_update, version_info = self.check_for_updates()
            
            if not has_update:
                return False
            
            version = version_info.get('version', 'unknown')
            is_pushed = version_info.get('pushed', False)
            
            # Step 2: Download update (SILENT - no output)
            success, package_path = self.download_update(version_info)
            if not success:
                return False
            
            # Step 3: Backup current installation (SILENT)
            success, backup_dir = self.backup_current_installation()
            # Continue even if backup fails
            
            # Step 4: Apply update (SILENT)
            success = self.apply_update(package_path)
            if not success:
                return False
            
            # Step 5: Notify server (if this was a pushed update)
            if is_pushed:
                self.notify_update_completed(version)
            
            # Step 6: Cleanup
            self.cleanup_temp()
            
            # Step 7: Restart (SILENT - no countdown)
            self.restart_client()
            
            return True
            
        except Exception as e:
            # Silent fail - log but don't show to user
            self.cleanup_temp()
            return False


def check_and_update_if_needed(config):
    """
    Helper function to check and update client if needed
    Call this on client startup
    """
    updater = ClientUpdater(config)
    
    # Only check for updates once per day
    last_check_file = Path(config.DATA_DIR) / ".last_update_check"
    
    try:
        if last_check_file.exists():
            last_check = datetime.fromtimestamp(last_check_file.stat().st_mtime)
            hours_since_check = (datetime.now() - last_check).total_seconds() / 3600
            
            if hours_since_check < 24:
                # Checked recently, skip
                return False
    except Exception:
        pass
    
    # Update last check time
    last_check_file.touch()
    
    # Perform update if available
    return updater.perform_update()
