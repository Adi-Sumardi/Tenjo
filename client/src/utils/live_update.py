"""
Live Update Module - Hot reload without restart
Updates code modules in-memory without process restart
"""

import importlib
import sys
import os
import logging
import threading
from pathlib import Path
from typing import Dict, List, Optional, Set
import time


class LiveUpdater:
    """Hot reload modules without restart for stealth updates"""

    def __init__(self, logger: Optional[logging.Logger] = None):
        self.logger = logger or logging.getLogger("LiveUpdater")
        self.reloadable_modules: Set[str] = set()
        self.update_lock = threading.Lock()

    def register_reloadable_module(self, module_name: str):
        """Register module that can be hot reloaded"""
        self.reloadable_modules.add(module_name)

    def apply_live_update(self, updated_files: List[Path]) -> bool:
        """
        Apply updates to running process without restart

        Args:
            updated_files: List of file paths that were updated

        Returns:
            bool: True if update applied successfully
        """
        try:
            with self.update_lock:
                # Group files by module
                modules_to_reload = self._get_modules_from_files(updated_files)

                if not modules_to_reload:
                    self.logger.debug("No modules to reload")
                    return True

                # Reload modules in dependency order
                for module_name in modules_to_reload:
                    if module_name in self.reloadable_modules:
                        self._reload_module(module_name)
                    else:
                        self.logger.warning(f"Module {module_name} not registered as reloadable")

                self.logger.info(f"Live update applied: {len(modules_to_reload)} modules reloaded")
                return True

        except Exception as exc:
            self.logger.error(f"Live update failed: {exc}")
            return False

    def _get_modules_from_files(self, file_paths: List[Path]) -> List[str]:
        """Convert file paths to Python module names"""
        modules = []

        for file_path in file_paths:
            if not file_path.suffix == '.py':
                continue

            # Convert file path to module name
            # e.g., src/utils/api_client.py -> src.utils.api_client
            parts = file_path.parts

            # Find 'src' in path
            try:
                src_index = parts.index('src')
                module_parts = parts[src_index:]
                module_name = '.'.join(module_parts).replace('.py', '')
                modules.append(module_name)
            except (ValueError, IndexError):
                continue

        return modules

    def _reload_module(self, module_name: str) -> bool:
        """Reload a single module"""
        try:
            if module_name in sys.modules:
                module = sys.modules[module_name]
                importlib.reload(module)
                self.logger.debug(f"Reloaded module: {module_name}")
                return True
            else:
                self.logger.warning(f"Module {module_name} not in sys.modules")
                return False
        except Exception as exc:
            self.logger.error(f"Failed to reload {module_name}: {exc}")
            return False

    def can_update_live(self, version_info: Dict) -> bool:
        """
        Check if update can be applied live without restart

        Some updates REQUIRE restart:
        - main.py changes
        - Config changes
        - Core architecture changes
        """
        changes = version_info.get('changes', [])

        # Keywords that indicate restart is needed
        restart_keywords = [
            'main.py',
            'config',
            'architecture',
            'core',
            'breaking change',
            'migration',
            'requires restart'
        ]

        for change in changes:
            change_lower = str(change).lower()
            for keyword in restart_keywords:
                if keyword in change_lower:
                    return False

        return True


class DependencyChecker:
    """Check and auto-install missing dependencies"""

    def __init__(self, requirements_file: Path, logger: Optional[logging.Logger] = None):
        self.requirements_file = requirements_file
        self.logger = logger or logging.getLogger("DependencyChecker")

    def check_dependencies(self) -> Dict[str, bool]:
        """Check if all required packages are installed"""
        import subprocess

        missing = {}

        if not self.requirements_file.exists():
            self.logger.warning(f"Requirements file not found: {self.requirements_file}")
            return missing

        with open(self.requirements_file, 'r') as f:
            for line in f:
                line = line.strip()

                # Skip comments and empty lines
                if not line or line.startswith('#'):
                    continue

                # Extract package name (before >= or ==)
                package_name = line.split('>=')[0].split('==')[0].split(';')[0].strip()

                try:
                    __import__(package_name.replace('-', '_'))
                    missing[package_name] = True  # Installed
                except ImportError:
                    missing[package_name] = False  # Missing

        return missing

    def auto_install_missing(self, silent: bool = True) -> bool:
        """Automatically install missing packages"""
        import subprocess
        import sys

        missing = self.check_dependencies()
        to_install = [pkg for pkg, installed in missing.items() if not installed]

        if not to_install:
            self.logger.debug("All dependencies installed")
            return True

        self.logger.warning(f"Missing packages: {to_install}")

        try:
            for package in to_install:
                self.logger.info(f"Installing {package}...")

                # Silent install with no output
                if silent:
                    result = subprocess.run(
                        [sys.executable, '-m', 'pip', 'install', package, '--quiet'],
                        capture_output=True,
                        timeout=300,
                        creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0
                    )
                else:
                    result = subprocess.run(
                        [sys.executable, '-m', 'pip', 'install', package],
                        timeout=300
                    )

                if result.returncode == 0:
                    self.logger.info(f"Installed {package}")
                else:
                    self.logger.error(f"Failed to install {package}: {result.stderr}")

            return True

        except Exception as exc:
            self.logger.error(f"Auto-install failed: {exc}")
            return False


class PythonInstallationChecker:
    """Check Python installation and auto-fix if needed"""

    @staticmethod
    def check_python_installation() -> bool:
        """Check if Python is properly installed"""
        import sys
        import subprocess

        try:
            # Check if running Python
            if not sys.executable:
                return False

            # Check pip is available
            result = subprocess.run(
                [sys.executable, '-m', 'pip', '--version'],
                capture_output=True,
                timeout=10
            )

            return result.returncode == 0

        except Exception:
            return False

    @staticmethod
    def get_python_installer_url() -> str:
        """Get Python installer URL based on OS"""
        import platform

        system = platform.system()

        if system == 'Windows':
            # Python 3.10 Windows installer (silent install supported)
            return "https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe"
        elif system == 'Darwin':
            # macOS - Python should be pre-installed or via Homebrew
            return "https://www.python.org/ftp/python/3.10.11/python-3.10.11-macos11.pkg"
        else:
            # Linux - use system package manager
            return None
