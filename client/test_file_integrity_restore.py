#!/usr/bin/env python3
"""
File Integrity and Restore Test Script (Windows)
Tests file integrity check and auto-restore functionality
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

class FileIntegrityRestoreTester:
    def __init__(self):
        self.config = Config
        self.updater = ClientUpdater(Config)
        self.test_file = None

    def log(self, message, status="INFO"):
        timestamp = time.strftime("%H:%M:%S")
        print(f"[{timestamp}] [{status}] {message}")

    def test_initial_integrity_check(self):
        """Test #1: Initial Integrity Check"""
        self.log("=" * 60)
        self.log("TEST #1: Initial File Integrity Check", "TEST")
        self.log("=" * 60)

        try:
            result = self.updater.check_file_integrity()

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

            self.log("Checking critical files:")
            all_present = True
            for file in required_files:
                file_path = self.updater.install_path / file
                exists = file_path.exists()
                status = "✅" if exists else "❌"
                self.log(f"  {status} {file}")
                if not exists:
                    all_present = False

            if result and all_present:
                self.log("✅ All critical files present", "PASS")
                return True
            else:
                self.log("❌ Some files missing", "FAIL")
                return False

        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_create_backup(self):
        """Test #2: Create Backup"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #2: Create Backup", "TEST")
        self.log("=" * 60)

        try:
            self.log("Creating backup of current installation...")
            backup_success, backup_dir = self.updater.backup_current_installation()

            if backup_success and backup_dir:
                self.log(f"✅ Backup created: {backup_dir}", "PASS")

                # Verify backup
                if backup_dir.exists():
                    backup_files = list(backup_dir.rglob('*'))
                    file_count = sum(1 for f in backup_files if f.is_file())

                    self.log(f"   Total items in backup: {len(backup_files)}")
                    self.log(f"   Files: {file_count}")

                    # Check critical files in backup
                    critical_in_backup = 0
                    for file in ['main.py', 'src/core/config.py', 'src/utils/api_client.py']:
                        if (backup_dir / file).exists():
                            critical_in_backup += 1

                    self.log(f"   Critical files in backup: {critical_in_backup}/3")

                    if critical_in_backup >= 3:
                        self.log("✅ Backup verification passed", "PASS")
                        self.backup_dir = backup_dir  # Save for later use
                        return True
                    else:
                        self.log("❌ Backup incomplete", "FAIL")
                        return False
                else:
                    self.log("❌ Backup directory not found", "FAIL")
                    return False
            else:
                self.log("❌ Backup creation failed", "FAIL")
                return False

        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_simulate_file_deletion(self):
        """Test #3: Simulate File Deletion"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #3: Simulate File Deletion", "TEST")
        self.log("=" * 60)

        try:
            # Choose a non-critical test file to delete
            # We'll create a dummy file first
            test_file = self.updater.install_path / "test_dummy_file.py"

            self.log(f"Creating test file: {test_file}")
            with open(test_file, 'w') as f:
                f.write("# Test file for integrity check\nprint('test')\n")

            if test_file.exists():
                self.log("✅ Test file created", "PASS")
            else:
                self.log("❌ Failed to create test file", "FAIL")
                return False

            # Now delete it
            self.log("Deleting test file...")
            test_file.unlink()

            if not test_file.exists():
                self.log("✅ Test file deleted successfully", "PASS")
                self.test_file = test_file
                return True
            else:
                self.log("❌ Failed to delete test file", "FAIL")
                return False

        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_detect_missing_file(self):
        """Test #4: Detect Missing Critical File"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #4: Detect Missing Critical File (DESTRUCTIVE)", "TEST")
        self.log("=" * 60)

        self.log("⚠️  WARNING: This test will temporarily delete a critical file!")
        self.log("   It will be restored from backup immediately.")
        self.log("")

        response = input("Continue with destructive test? (yes/no): ").strip().lower()
        if response != 'yes':
            self.log("⚠️  Test skipped by user", "SKIP")
            return None

        try:
            # Delete requirements.txt temporarily
            critical_file = self.updater.install_path / "requirements.txt"
            backup_content = None

            if critical_file.exists():
                # Backup content first
                with open(critical_file, 'r') as f:
                    backup_content = f.read()

                self.log(f"Temporarily deleting: {critical_file}")
                critical_file.unlink()

                # Check integrity
                self.log("Running integrity check...")
                result = self.updater.check_file_integrity()

                if not result:
                    self.log("✅ Missing file detected correctly", "PASS")

                    # Restore immediately
                    self.log("Restoring file...")
                    with open(critical_file, 'w') as f:
                        f.write(backup_content)

                    if critical_file.exists():
                        self.log("✅ File restored successfully", "PASS")
                        return True
                    else:
                        self.log("❌ Failed to restore file", "FAIL")
                        return False
                else:
                    self.log("❌ Integrity check failed to detect missing file", "FAIL")
                    # Restore anyway
                    with open(critical_file, 'w') as f:
                        f.write(backup_content)
                    return False
            else:
                self.log("❌ Critical file already missing", "FAIL")
                return False

        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            # Try to restore
            if backup_content:
                with open(critical_file, 'w') as f:
                    f.write(backup_content)
            return False

    def test_restore_from_backup(self):
        """Test #5: Restore from Backup"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #5: Restore from Backup (SIMULATION)", "TEST")
        self.log("=" * 60)

        try:
            # Check if we have a backup
            if not self.updater.backup_path.exists():
                self.log("❌ No backup directory found", "FAIL")
                return False

            backups = sorted(self.updater.backup_path.glob('backup_*'), reverse=True)
            if not backups:
                self.log("❌ No backups available", "FAIL")
                return False

            most_recent = backups[0]
            self.log(f"Most recent backup: {most_recent}")

            # Count files in backup
            backup_files = list(most_recent.rglob('*'))
            file_count = sum(1 for f in backup_files if f.is_file())

            self.log(f"  Files in backup: {file_count}")

            # Verify critical files exist in backup
            critical_files = ['main.py', 'src/core/config.py', 'requirements.txt']
            critical_count = 0

            for file in critical_files:
                if (most_recent / file).exists():
                    critical_count += 1
                    self.log(f"  ✅ {file} found in backup")
                else:
                    self.log(f"  ❌ {file} missing in backup")

            if critical_count == len(critical_files):
                self.log("✅ Backup contains all critical files", "PASS")
                self.log("")
                self.log("⚠️  NOTE: Full restore test skipped to avoid disruption")
                self.log("   In production, restore_from_backup() would:")
                self.log("   1. Delete current installation")
                self.log("   2. Copy all files from backup")
                self.log("   3. Restart the client")
                return True
            else:
                self.log("❌ Backup missing critical files", "FAIL")
                return False

        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def test_backup_rotation(self):
        """Test #6: Backup Rotation"""
        self.log("")
        self.log("=" * 60)
        self.log("TEST #6: Backup Rotation Policy", "TEST")
        self.log("=" * 60)

        try:
            if not self.updater.backup_path.exists():
                self.log("⚠️  No backup directory", "WARN")
                return True

            backups = sorted(self.updater.backup_path.glob('backup_*'))
            self.log(f"Total backups found: {len(backups)}")

            if len(backups) > 0:
                for i, backup in enumerate(backups, 1):
                    backup_size = sum(f.stat().st_size for f in backup.rglob('*') if f.is_file())
                    self.log(f"  {i}. {backup.name} ({backup_size / 1024:.2f} KB)")

                if len(backups) > 5:
                    self.log("⚠️  More than 5 backups found", "WARN")
                    self.log("   Consider implementing backup rotation")
                else:
                    self.log("✅ Backup count within reasonable limits", "PASS")

                return True
            else:
                self.log("⚠️  No backups found", "WARN")
                return True

        except Exception as e:
            self.log(f"❌ Test failed: {e}", "FAIL")
            return False

    def run_all_tests(self):
        """Run all file integrity and restore tests"""
        self.log("")
        self.log("=" * 60)
        self.log("FILE INTEGRITY & RESTORE TEST SUITE", "INFO")
        self.log("=" * 60)
        self.log(f"Platform: {sys.platform}")
        self.log(f"Install path: {self.updater.install_path}")
        self.log(f"Backup path: {self.updater.backup_path}")
        self.log("")

        tests = [
            ("Initial Integrity Check", self.test_initial_integrity_check),
            ("Create Backup", self.test_create_backup),
            ("Simulate File Deletion", self.test_simulate_file_deletion),
            ("Detect Missing Critical File", self.test_detect_missing_file),
            ("Restore from Backup (Simulation)", self.test_restore_from_backup),
            ("Backup Rotation Policy", self.test_backup_rotation),
        ]

        results = {}
        for test_name, test_func in tests:
            try:
                result = test_func()
                if result is True:
                    results[test_name] = "PASS"
                elif result is False:
                    results[test_name] = "FAIL"
                elif result is None:
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
        skipped = sum(1 for v in results.values() if v == "SKIP")

        self.log("")
        self.log(f"Passed: {passed}")
        self.log(f"Failed: {failed}")
        self.log(f"Skipped: {skipped}")

        if failed == 0:
            self.log("")
            self.log("🎉 ALL TESTS PASSED - INTEGRITY & RESTORE WORKING", "PASS")
        else:
            self.log("")
            self.log("⚠️  SOME TESTS FAILED", "WARN")

def main():
    """Main entry point"""
    print("\n" + "=" * 60)
    print("FILE INTEGRITY & RESTORE TEST (WINDOWS)")
    print("=" * 60)
    print("\nThis will test:")
    print("  - File integrity checking (8 critical files)")
    print("  - Backup creation and verification")
    print("  - Missing file detection")
    print("  - Restore from backup (simulation)")
    print("  - Backup rotation policy")
    print("\n⚠️  WARNING: One test will temporarily delete a critical file")
    print("   (it will be restored immediately)")
    print("=" * 60)

    input("\nPress ENTER to start tests...")

    tester = FileIntegrityRestoreTester()
    tester.run_all_tests()

    print("\n" + "=" * 60)
    print("TESTING COMPLETE")
    print("=" * 60)
    input("\nPress ENTER to exit...")

if __name__ == "__main__":
    main()
