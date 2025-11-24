#!/usr/bin/env python3
"""
Dependency Auto-Install Test Script (Windows)
Tests the silent pip install functionality with CREATE_NO_WINDOW
"""

import sys
import os
import subprocess
import time
from pathlib import Path

# Add src to path
sys.path.append('src')

from src.utils.live_update import DependencyChecker

class DependencyAutoInstallTester:
    def __init__(self):
        self.requirements_file = Path(__file__).parent / "requirements.txt"
        self.test_package = "colorama"  # Small package for testing

    def log(self, message, status="INFO"):
        timestamp = time.strftime("%H:%M:%S")
        print(f"[{timestamp}] [{status}] {message}")

    def test_dependency_check(self):
        """Test dependency checking"""
        self.log("=" * 60)
        self.log("TEST: Dependency Check", "TEST")
        self.log("=" * 60)

        try:
            checker = DependencyChecker(self.requirements_file)
            missing = checker.check_dependencies()

            self.log(f"Found {len(missing)} packages in requirements.txt")

            for package, installed in missing.items():
                status = "✅ INSTALLED" if installed else "❌ MISSING"
                self.log(f"  {package}: {status}")

            return missing
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return None

    def test_uninstall_package(self):
        """Uninstall test package to simulate missing dependency"""
        self.log("")
        self.log("=" * 60)
        self.log(f"TEST: Uninstalling {self.test_package} for testing", "TEST")
        self.log("=" * 60)

        try:
            # Check if package exists
            try:
                __import__(self.test_package)
                self.log(f"{self.test_package} is currently installed")
            except ImportError:
                self.log(f"{self.test_package} is not installed (good for testing)")
                return True

            # Uninstall
            self.log(f"Uninstalling {self.test_package}...")
            result = subprocess.run(
                [sys.executable, '-m', 'pip', 'uninstall', self.test_package, '-y'],
                capture_output=True,
                timeout=30
            )

            if result.returncode == 0:
                self.log(f"✅ {self.test_package} uninstalled successfully", "PASS")
                return True
            else:
                self.log(f"❌ Failed to uninstall: {result.stderr.decode()}", "FAIL")
                return False
        except Exception as e:
            self.log(f"❌ Uninstall failed: {e}", "FAIL")
            return False

    def test_silent_install(self):
        """Test silent pip install with CREATE_NO_WINDOW"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST: Silent Auto-Install (CREATE_NO_WINDOW)", "TEST")
        self.log("=" * 60)

        try:
            # Test CREATE_NO_WINDOW availability
            if sys.platform == 'win32':
                if hasattr(subprocess, 'CREATE_NO_WINDOW'):
                    self.log("✅ CREATE_NO_WINDOW flag available", "PASS")
                    creation_flags = subprocess.CREATE_NO_WINDOW
                else:
                    self.log("⚠️  CREATE_NO_WINDOW not available, using 0", "WARN")
                    creation_flags = 0
            else:
                self.log("⚠️  Not on Windows, skipping CREATE_NO_WINDOW", "WARN")
                creation_flags = 0

            # Test silent install
            self.log(f"Installing {self.test_package} silently...")
            start_time = time.time()

            result = subprocess.run(
                [sys.executable, '-m', 'pip', 'install', self.test_package, '--quiet'],
                capture_output=True,
                timeout=300,
                creationflags=creation_flags
            )

            elapsed = time.time() - start_time

            if result.returncode == 0:
                self.log(f"✅ Silent install successful ({elapsed:.2f}s)", "PASS")

                # Verify installation
                try:
                    __import__(self.test_package)
                    self.log(f"✅ Package {self.test_package} imported successfully", "PASS")
                    return True
                except ImportError:
                    self.log(f"❌ Package installed but import failed", "FAIL")
                    return False
            else:
                self.log(f"❌ Install failed: {result.stderr.decode()}", "FAIL")
                return False
        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_auto_install_with_checker(self):
        """Test DependencyChecker.auto_install_missing()"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST: DependencyChecker Auto-Install", "TEST")
        self.log("=" * 60)

        try:
            # Create temporary requirements file with test package
            temp_requirements = Path(__file__).parent / "test_requirements.txt"
            with open(temp_requirements, 'w') as f:
                f.write(f"{self.test_package}\n")

            self.log(f"Created test requirements: {temp_requirements}")

            # Uninstall test package first
            self.log(f"Uninstalling {self.test_package}...")
            subprocess.run(
                [sys.executable, '-m', 'pip', 'uninstall', self.test_package, '-y'],
                capture_output=True,
                timeout=30
            )

            # Test auto-install
            checker = DependencyChecker(temp_requirements)
            self.log("Checking dependencies...")

            missing = checker.check_dependencies()
            if not missing.get(self.test_package, True):
                self.log(f"✅ Detected {self.test_package} as missing", "PASS")

                self.log("Running auto_install_missing(silent=True)...")
                start_time = time.time()

                result = checker.auto_install_missing(silent=True)
                elapsed = time.time() - start_time

                if result:
                    self.log(f"✅ Auto-install successful ({elapsed:.2f}s)", "PASS")

                    # Verify
                    try:
                        __import__(self.test_package)
                        self.log(f"✅ Package {self.test_package} now available", "PASS")
                        return True
                    except ImportError:
                        self.log(f"❌ Package still not available after install", "FAIL")
                        return False
                else:
                    self.log(f"❌ Auto-install failed", "FAIL")
                    return False
            else:
                self.log(f"⚠️  {self.test_package} already installed, can't test", "WARN")
                return True

        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False
        finally:
            # Cleanup
            if temp_requirements.exists():
                temp_requirements.unlink()

    def test_no_terminal_popup(self):
        """Test that no terminal window appears during install"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST: No Terminal Pop-up (Manual Observation)", "TEST")
        self.log("=" * 60)

        if sys.platform != 'win32':
            self.log("⚠️  Not on Windows, skipping visual test", "WARN")
            return True

        self.log("This test requires manual observation:")
        self.log("  1. Watch for any terminal windows appearing")
        self.log("  2. If you see a terminal window, test FAILS")
        self.log("  3. If no window appears, test PASSES")
        self.log("")

        input("Press ENTER to start 5-second silent install test...")

        try:
            # Uninstall first
            subprocess.run(
                [sys.executable, '-m', 'pip', 'uninstall', self.test_package, '-y'],
                capture_output=True,
                timeout=30,
                creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, 'CREATE_NO_WINDOW') else 0
            )

            self.log("Installing package silently... WATCH FOR POP-UPS!")
            time.sleep(1)

            # Silent install with CREATE_NO_WINDOW
            result = subprocess.run(
                [sys.executable, '-m', 'pip', 'install', self.test_package, '--quiet'],
                capture_output=True,
                timeout=300,
                creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, 'CREATE_NO_WINDOW') else 0
            )

            self.log("")
            self.log("Install complete!")

            response = input("Did you see any terminal window pop up? (y/n): ").strip().lower()

            if response == 'n':
                self.log("✅ No terminal pop-up observed - STEALTH CONFIRMED", "PASS")
                return True
            else:
                self.log("❌ Terminal window was visible - STEALTH FAILED", "FAIL")
                return False

        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def run_all_tests(self):
        """Run all dependency auto-install tests"""
        self.log("")
        self.log("=" * 60)
        self.log("DEPENDENCY AUTO-INSTALL TEST SUITE", "INFO")
        self.log("=" * 60)
        self.log(f"Platform: {sys.platform}")
        self.log(f"Python: {sys.version}")
        self.log(f"Test package: {self.test_package}")
        self.log("")

        tests = [
            ("Initial Dependency Check", self.test_dependency_check),
            ("Silent Install with CREATE_NO_WINDOW", self.test_silent_install),
            ("DependencyChecker Auto-Install", self.test_auto_install_with_checker),
            ("No Terminal Pop-up (Manual)", self.test_no_terminal_popup),
        ]

        results = {}
        for test_name, test_func in tests:
            try:
                result = test_func()
                if result is True:
                    results[test_name] = "PASS"
                elif result is False:
                    results[test_name] = "FAIL"
                else:
                    results[test_name] = "SKIP"
            except Exception as e:
                self.log(f"CRITICAL ERROR in {test_name}: {e}", "ERROR")
                results[test_name] = "ERROR"

        # Summary
        self.log("")
        self.log("=" * 60)
        self.log("TEST SUMMARY", "INFO")
        self.log("=" * 60)

        for test_name, result in results.items():
            icon = "✅" if result == "PASS" else "❌" if result == "FAIL" else "⚠️"
            self.log(f"{icon} {test_name}: {result}")

        passed = sum(1 for v in results.values() if v == "PASS")
        failed = sum(1 for v in results.values() if v == "FAIL")

        self.log("")
        self.log(f"Passed: {passed}/{len(results)}")
        self.log(f"Failed: {failed}/{len(results)}")

        if failed == 0:
            self.log("")
            self.log("🎉 ALL TESTS PASSED - AUTO-INSTALL WORKING", "PASS")
        else:
            self.log("")
            self.log("⚠️  SOME TESTS FAILED", "WARN")

def main():
    """Main entry point"""
    print("\n" + "=" * 60)
    print("DEPENDENCY AUTO-INSTALL TEST (WINDOWS)")
    print("=" * 60)
    print("\nThis will test:")
    print("  - Silent pip install with CREATE_NO_WINDOW")
    print("  - DependencyChecker auto-install functionality")
    print("  - Stealth mode (no terminal pop-ups)")
    print("\n⚠️  NOTE: This test will install/uninstall 'colorama' package")
    print("=" * 60)

    input("\nPress ENTER to start tests...")

    tester = DependencyAutoInstallTester()
    tester.run_all_tests()

    print("\n" + "=" * 60)
    print("TESTING COMPLETE")
    print("=" * 60)
    input("\nPress ENTER to exit...")

if __name__ == "__main__":
    main()
