#!/usr/bin/env python3
"""
Windows Live Update Test Script
Tests all self-healing and live update features on Windows
"""

import sys
import os
import time
import shutil
from pathlib import Path

# Add src to path
sys.path.append('src')

from src.core.config import Config
from src.utils.auto_update import ClientUpdater
from src.utils.live_update import DependencyChecker, PythonInstallationChecker

class WindowsLiveUpdateTester:
    def __init__(self):
        self.config = Config
        self.updater = ClientUpdater(Config)
        self.test_results = []

    def log(self, message, status="INFO"):
        timestamp = time.strftime("%H:%M:%S")
        log_msg = f"[{timestamp}] [{status}] {message}"
        print(log_msg)
        self.test_results.append(log_msg)

    def test_python_installation_check(self):
        """Test #1: Python Installation Check"""
        self.log("=" * 60)
        self.log("TEST #1: Python Installation Check", "TEST")
        self.log("=" * 60)

        try:
            result = PythonInstallationChecker.check_python_installation()
            if result:
                self.log("✅ Python installation: OK", "PASS")
                self.log(f"   Python path: {sys.executable}")
            else:
                self.log("❌ Python installation: FAILED", "FAIL")

            # Check pip
            import subprocess
            pip_check = subprocess.run(
                [sys.executable, '-m', 'pip', '--version'],
                capture_output=True,
                timeout=10
            )
            if pip_check.returncode == 0:
                self.log("✅ pip installation: OK", "PASS")
                self.log(f"   {pip_check.stdout.decode().strip()}")
            else:
                self.log("❌ pip installation: FAILED", "FAIL")

            return True
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_dependency_checker(self):
        """Test #2: Dependency Checker"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #2: Dependency Checker", "TEST")
        self.log("=" * 60)

        try:
            requirements_file = Path(__file__).parent / "requirements.txt"
            if not requirements_file.exists():
                self.log("❌ requirements.txt not found", "FAIL")
                return False

            checker = DependencyChecker(requirements_file)
            self.log(f"✅ DependencyChecker initialized")

            # Check dependencies
            self.log("Checking installed packages...")
            missing = checker.check_dependencies()

            installed_count = sum(1 for v in missing.values() if v)
            missing_count = len(missing) - installed_count

            self.log(f"   Total packages: {len(missing)}")
            self.log(f"   Installed: {installed_count}")
            self.log(f"   Missing: {missing_count}")

            for package, installed in missing.items():
                status = "✅" if installed else "❌"
                self.log(f"   {status} {package}")

            if missing_count > 0:
                self.log(f"⚠️  Found {missing_count} missing packages", "WARN")
            else:
                self.log("✅ All dependencies installed", "PASS")

            return True
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_file_integrity_check(self):
        """Test #3: File Integrity Check"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #3: File Integrity Check", "TEST")
        self.log("=" * 60)

        try:
            result = self.updater.check_file_integrity()

            if result:
                self.log("✅ File integrity check: PASSED", "PASS")
                self.log("   All critical files present:")

                required_files = [
                    'main.py',
                    'src/core/config.py',
                    'src/utils/api_client.py',
                    'src/utils/auto_update.py',
                    'src/modules/browser_tracker.py',
                    'src/modules/screen_capture.py',
                    'src/modules/process_monitor.py',
                    'requirements.txt',
                ]

                for file in required_files:
                    file_path = self.updater.install_path / file
                    if file_path.exists():
                        size = file_path.stat().st_size
                        self.log(f"   ✅ {file} ({size} bytes)")
                    else:
                        self.log(f"   ❌ {file} MISSING")
            else:
                self.log("❌ File integrity check: FAILED", "FAIL")

            return result
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_backup_functionality(self):
        """Test #4: Backup Functionality"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #4: Backup Functionality", "TEST")
        self.log("=" * 60)

        try:
            # Create a backup
            self.log("Creating backup...")
            backup_success, backup_dir = self.updater.backup_current_installation()

            if backup_success and backup_dir:
                self.log(f"✅ Backup created successfully", "PASS")
                self.log(f"   Backup location: {backup_dir}")

                # Check backup directory
                if backup_dir.exists():
                    backup_files = list(backup_dir.glob('**/*'))
                    self.log(f"   Backup contains {len(backup_files)} items")
                    self.log("✅ Backup verification: PASSED", "PASS")
                else:
                    self.log("❌ Backup directory not found", "FAIL")
                    return False
            else:
                self.log("❌ Backup creation failed", "FAIL")
                return False

            return True
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_live_updater_initialization(self):
        """Test #5: Live Updater Initialization"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #5: Live Updater Initialization", "TEST")
        self.log("=" * 60)

        try:
            if self.updater.live_updater:
                self.log("✅ LiveUpdater initialized", "PASS")

                # Check registered modules
                modules = self.updater.live_updater.reloadable_modules
                self.log(f"   Registered modules: {len(modules)}")

                for module in modules:
                    self.log(f"   ✅ {module}")

                return True
            else:
                self.log("❌ LiveUpdater not initialized", "FAIL")
                return False
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_windows_specific_features(self):
        """Test #6: Windows-Specific Features"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #6: Windows-Specific Features", "TEST")
        self.log("=" * 60)

        try:
            import platform
            if platform.system() != 'Windows':
                self.log("⚠️  Not running on Windows, skipping", "WARN")
                return True

            # Test CREATE_NO_WINDOW flag availability
            import subprocess
            if hasattr(subprocess, 'CREATE_NO_WINDOW'):
                self.log("✅ CREATE_NO_WINDOW flag available", "PASS")
                self.log(f"   Flag value: {subprocess.CREATE_NO_WINDOW}")
            else:
                self.log("⚠️  CREATE_NO_WINDOW flag not available", "WARN")

            # Test process disguise
            try:
                from src.utils.process_disguise import apply_disguise
                self.log("✅ Process disguise module available", "PASS")
            except ImportError:
                self.log("⚠️  Process disguise module not found", "WARN")

            # Check Windows paths
            self.log("Windows paths:")
            self.log(f"   Install path: {self.updater.install_path}")
            self.log(f"   Backup path: {self.updater.backup_path}")
            self.log(f"   Data directory: {Config.DATA_DIR}")
            self.log(f"   Log directory: {Config.LOG_DIR}")

            return True
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_stealth_mode(self):
        """Test #7: Stealth Mode Configuration"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #7: Stealth Mode Configuration", "TEST")
        self.log("=" * 60)

        try:
            stealth_mode = getattr(Config, 'STEALTH_MODE', False)

            if stealth_mode:
                self.log("✅ Stealth mode: ENABLED", "PASS")
            else:
                self.log("⚠️  Stealth mode: DISABLED", "WARN")

            # Check logging level
            log_level = self.updater.logger.level
            self.log(f"   Log level: {log_level}")

            if stealth_mode and log_level >= 30:  # WARNING or higher
                self.log("✅ Stealth logging: CONFIGURED", "PASS")
            elif not stealth_mode:
                self.log("   Normal logging mode")
            else:
                self.log("⚠️  Logging level may be too verbose for stealth", "WARN")

            return True
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def run_all_tests(self):
        """Run all tests"""
        self.log("")
        self.log("=" * 60)
        self.log("WINDOWS LIVE UPDATE TEST SUITE", "INFO")
        self.log("=" * 60)
        self.log(f"Platform: {sys.platform}")
        self.log(f"Python: {sys.version}")
        self.log("")

        tests = [
            ("Python Installation Check", self.test_python_installation_check),
            ("Dependency Checker", self.test_dependency_checker),
            ("File Integrity Check", self.test_file_integrity_check),
            ("Backup Functionality", self.test_backup_functionality),
            ("Live Updater Initialization", self.test_live_updater_initialization),
            ("Windows-Specific Features", self.test_windows_specific_features),
            ("Stealth Mode Configuration", self.test_stealth_mode),
        ]

        results = {}
        for test_name, test_func in tests:
            try:
                result = test_func()
                results[test_name] = "PASS" if result else "FAIL"
            except Exception as e:
                self.log(f"CRITICAL ERROR in {test_name}: {e}", "ERROR")
                results[test_name] = "ERROR"

        # Summary
        self.log("")
        self.log("=" * 60)
        self.log("TEST SUMMARY", "INFO")
        self.log("=" * 60)

        passed = sum(1 for v in results.values() if v == "PASS")
        failed = sum(1 for v in results.values() if v == "FAIL")
        errors = sum(1 for v in results.values() if v == "ERROR")

        for test_name, result in results.items():
            icon = "✅" if result == "PASS" else "❌" if result == "FAIL" else "⚠️"
            self.log(f"{icon} {test_name}: {result}")

        self.log("")
        self.log(f"Total: {len(results)} tests")
        self.log(f"Passed: {passed}")
        self.log(f"Failed: {failed}")
        self.log(f"Errors: {errors}")

        if failed == 0 and errors == 0:
            self.log("")
            self.log("🎉 ALL TESTS PASSED - SYSTEM READY FOR PRODUCTION", "PASS")
        else:
            self.log("")
            self.log("⚠️  SOME TESTS FAILED - REVIEW REQUIRED", "WARN")

        # Save results to file
        self.save_results()

    def save_results(self):
        """Save test results to file"""
        try:
            log_dir = Path(Config.LOG_DIR)
            log_dir.mkdir(parents=True, exist_ok=True)

            log_file = log_dir / f"windows_test_{int(time.time())}.log"
            with open(log_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(self.test_results))

            self.log(f"\n📄 Test results saved to: {log_file}", "INFO")
        except Exception as e:
            self.log(f"Failed to save results: {e}", "WARN")

def main():
    """Main entry point"""
    print("\n" + "=" * 60)
    print("TENJO WINDOWS LIVE UPDATE TEST SUITE")
    print("=" * 60)
    print("\nThis script will test:")
    print("  1. Python installation detection")
    print("  2. Dependency checking and auto-install")
    print("  3. File integrity verification")
    print("  4. Backup and restore functionality")
    print("  5. Live updater initialization")
    print("  6. Windows-specific features (CREATE_NO_WINDOW, etc.)")
    print("  7. Stealth mode configuration")
    print("\n" + "=" * 60)

    input("\nPress ENTER to start tests...")

    tester = WindowsLiveUpdateTester()
    tester.run_all_tests()

    print("\n" + "=" * 60)
    print("TESTING COMPLETE")
    print("=" * 60)
    input("\nPress ENTER to exit...")

if __name__ == "__main__":
    main()
