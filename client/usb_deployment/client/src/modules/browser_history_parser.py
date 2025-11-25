"""
Browser History Parser Module
Parses Chrome/Edge browser history database to extract URLs
Specifically designed for Windows where AppleScript is not available
"""

import os
import sqlite3
import shutil
import tempfile
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import platform
import logging


class BrowserHistoryParser:
    """Parse browser history from Chrome/Edge SQLite databases"""

    def __init__(self, logger=None):
        self.logger = logger or logging.getLogger(__name__)
        self.system = platform.system()
        self.last_check_time = datetime.now() - timedelta(minutes=5)

    def get_chrome_history_paths(self) -> List[tuple]:
        """
        Get ALL Chrome history database paths (supports multiple profiles)
        Returns list of tuples: (path, profile_name) for Default + Profile 1, 2, 3, etc.
        FIX #11: Now returns profile names for better tracking
        """
        paths = []

        if self.system == 'Windows':
            local_appdata = os.getenv('LOCALAPPDATA')
            if local_appdata:
                user_data_dir = os.path.join(local_appdata, 'Google', 'Chrome', 'User Data')
                if os.path.exists(user_data_dir):
                    # Check Default profile
                    default_path = os.path.join(user_data_dir, 'Default', 'History')
                    if os.path.exists(default_path):
                        paths.append((default_path, 'Default'))

                    # Check Profile 1, 2, 3, ... up to 10
                    for i in range(1, 11):
                        profile_path = os.path.join(user_data_dir, f'Profile {i}', 'History')
                        if os.path.exists(profile_path):
                            paths.append((profile_path, f'Profile {i}'))

        elif self.system == 'Darwin':
            home = os.path.expanduser('~')
            user_data_dir = os.path.join(home, 'Library', 'Application Support', 'Google', 'Chrome')
            if os.path.exists(user_data_dir):
                # Check Default profile
                default_path = os.path.join(user_data_dir, 'Default', 'History')
                if os.path.exists(default_path):
                    paths.append((default_path, 'Default'))

                # Check Profile 1, 2, 3, ...
                for i in range(1, 11):
                    profile_path = os.path.join(user_data_dir, f'Profile {i}', 'History')
                    if os.path.exists(profile_path):
                        paths.append((profile_path, f'Profile {i}'))

        elif self.system == 'Linux':
            home = os.path.expanduser('~')
            user_data_dir = os.path.join(home, '.config', 'google-chrome')
            if os.path.exists(user_data_dir):
                # Check Default profile
                default_path = os.path.join(user_data_dir, 'Default', 'History')
                if os.path.exists(default_path):
                    paths.append((default_path, 'Default'))

                # Check Profile 1, 2, 3, ...
                for i in range(1, 11):
                    profile_path = os.path.join(user_data_dir, f'Profile {i}', 'History')
                    if os.path.exists(profile_path):
                        paths.append((profile_path, f'Profile {i}'))

        return paths

    def get_chrome_history_path(self) -> Optional[str]:
        """Get first available Chrome history path (backward compatibility)"""
        paths = self.get_chrome_history_paths()
        return paths[0][0] if paths else None  # Return path only, not tuple

    def get_edge_history_path(self) -> Optional[str]:
        """Get Edge history database path based on OS"""
        if self.system == 'Windows':
            # Windows Edge history path
            local_appdata = os.getenv('LOCALAPPDATA')
            if local_appdata:
                return os.path.join(local_appdata, 'Microsoft', 'Edge', 'User Data', 'Default', 'History')
        elif self.system == 'Darwin':
            # macOS Edge history path
            home = os.path.expanduser('~')
            return os.path.join(home, 'Library', 'Application Support', 'Microsoft Edge', 'Default', 'History')
        return None

    def get_firefox_history_path(self) -> Optional[str]:
        """Get Firefox history database path based on OS"""
        if self.system == 'Windows':
            # Windows Firefox history path (places.sqlite)
            appdata = os.getenv('APPDATA')
            if appdata:
                firefox_dir = os.path.join(appdata, 'Mozilla', 'Firefox', 'Profiles')
                if os.path.exists(firefox_dir):
                    # Find default profile directory (ends with .default or .default-release)
                    for profile in os.listdir(firefox_dir):
                        if '.default' in profile:
                            return os.path.join(firefox_dir, profile, 'places.sqlite')
        elif self.system == 'Darwin':
            # macOS Firefox history path
            home = os.path.expanduser('~')
            firefox_dir = os.path.join(home, 'Library', 'Application Support', 'Firefox', 'Profiles')
            if os.path.exists(firefox_dir):
                for profile in os.listdir(firefox_dir):
                    if '.default' in profile:
                        return os.path.join(firefox_dir, profile, 'places.sqlite')
        elif self.system == 'Linux':
            # Linux Firefox history path
            home = os.path.expanduser('~')
            firefox_dir = os.path.join(home, '.mozilla', 'firefox')
            if os.path.exists(firefox_dir):
                for profile in os.listdir(firefox_dir):
                    if '.default' in profile:
                        return os.path.join(firefox_dir, profile, 'places.sqlite')
        return None

    def get_brave_history_path(self) -> Optional[str]:
        """Get Brave history database path based on OS"""
        if self.system == 'Windows':
            # Windows Brave history path (same structure as Chrome)
            local_appdata = os.getenv('LOCALAPPDATA')
            if local_appdata:
                return os.path.join(local_appdata, 'BraveSoftware', 'Brave-Browser', 'User Data', 'Default', 'History')
        elif self.system == 'Darwin':
            # macOS Brave history path
            home = os.path.expanduser('~')
            return os.path.join(home, 'Library', 'Application Support', 'BraveSoftware', 'Brave-Browser', 'Default', 'History')
        elif self.system == 'Linux':
            # Linux Brave history path
            home = os.path.expanduser('~')
            return os.path.join(home, '.config', 'BraveSoftware', 'Brave-Browser', 'Default', 'History')
        return None

    def get_opera_history_path(self) -> Optional[str]:
        """Get Opera history database path based on OS"""
        if self.system == 'Windows':
            # Windows Opera history path (same structure as Chrome)
            appdata = os.getenv('APPDATA')
            if appdata:
                return os.path.join(appdata, 'Opera Software', 'Opera Stable', 'History')
        elif self.system == 'Darwin':
            # macOS Opera history path
            home = os.path.expanduser('~')
            return os.path.join(home, 'Library', 'Application Support', 'com.operasoftware.Opera', 'History')
        elif self.system == 'Linux':
            # Linux Opera history path
            home = os.path.expanduser('~')
            return os.path.join(home, '.config', 'opera', 'History')
        return None

    def copy_history_db(self, source_path: str) -> Optional[str]:
        """
        Copy history database to temp location
        (Chrome/Edge locks the DB while running)

        FIX: Use SQLite backup API instead of file copy to handle locked files
        """
        try:
            if not os.path.exists(source_path):
                self.logger.warning(f"History database not found: {source_path}")
                return None

            # Create temp file
            temp_fd, temp_path = tempfile.mkstemp(suffix='.db')
            os.close(temp_fd)

            # FIX: Use SQLite backup API to copy locked database
            # This works even when Chrome has the file locked
            try:
                # Connect to source DB in read-only mode with immutable flag
                # URI mode allows us to open locked files
                source_uri = f"file:{source_path}?mode=ro&immutable=1"
                source_conn = sqlite3.connect(source_uri, uri=True)

                # Connect to destination
                dest_conn = sqlite3.connect(temp_path)

                # Use SQLite backup API (works on locked files!)
                source_conn.backup(dest_conn)

                # Close connections
                source_conn.close()
                dest_conn.close()

                return temp_path

            except sqlite3.OperationalError as e:
                # Fallback: Try regular copy if backup fails
                self.logger.debug(f"SQLite backup failed, trying file copy: {e}")
                try:
                    shutil.copy2(source_path, temp_path)
                    return temp_path
                except Exception as copy_error:
                    self.logger.error(f"Both backup and copy failed: {copy_error}")
                    return None

        except Exception as e:
            self.logger.error(f"Failed to copy history DB: {e}")
            return None

    def parse_history_db(self, db_path: str, browser_name: str, minutes_back: int = 5) -> List[Dict]:
        """
        Parse browser history database and extract recent URLs

        Args:
            db_path: Path to history SQLite database
            browser_name: 'Chrome' or 'Edge'
            minutes_back: How many minutes back to look (default: 5)

        Returns:
            List of URL activities with metadata
        """
        activities = []
        temp_db = None

        try:
            # Copy DB to temp (browser locks the original)
            temp_db = self.copy_history_db(db_path)
            if not temp_db:
                return activities

            # Connect to SQLite database
            conn = sqlite3.connect(temp_db)
            cursor = conn.cursor()

            # Chrome/Edge use webkit time (microseconds since Jan 1, 1601)
            # We need to convert to Python datetime
            current_time = datetime.now()
            cutoff_time = current_time - timedelta(minutes=minutes_back)

            # Convert Python datetime to Chrome time (webkit microseconds)
            # Chrome epoch: 1601-01-01, Unix epoch: 1970-01-01
            # Difference: 11644473600 seconds
            epoch_diff = 11644473600
            cutoff_chrome_time = int((cutoff_time.timestamp() + epoch_diff) * 1000000)

            # Query recent URLs from history
            query = """
                SELECT
                    urls.url,
                    urls.title,
                    urls.visit_count,
                    urls.last_visit_time
                FROM urls
                WHERE urls.last_visit_time > ?
                ORDER BY urls.last_visit_time DESC
            """

            cursor.execute(query, (cutoff_chrome_time,))
            rows = cursor.fetchall()

            for row in rows:
                url, title, visit_count, last_visit_time = row

                # Convert Chrome time back to Python datetime
                visit_timestamp = datetime.fromtimestamp(
                    (last_visit_time / 1000000) - epoch_diff
                )

                # Extract domain
                domain = self._extract_domain(url)

                activities.append({
                    'browser_name': browser_name,
                    'url': url,
                    'title': title or self._extract_title_from_url(url),
                    'domain': domain,
                    'visit_time': visit_timestamp,
                    'visit_count': visit_count
                })

            conn.close()

        except sqlite3.OperationalError as e:
            self.logger.warning(f"Database locked or corrupted: {e}")
        except Exception as e:
            self.logger.error(f"Error parsing history DB: {e}")
        finally:
            # Clean up temp file
            if temp_db and os.path.exists(temp_db):
                try:
                    os.remove(temp_db)
                except:
                    pass

        return activities

    def parse_firefox_history_db(self, db_path: str, minutes_back: int = 5) -> List[Dict]:
        """
        Parse Firefox history database (places.sqlite)
        Firefox uses different schema and Unix timestamps (not webkit)
        """
        activities = []
        temp_db = None

        try:
            temp_db = self.copy_history_db(db_path)
            if not temp_db:
                return activities

            conn = sqlite3.connect(temp_db)
            cursor = conn.cursor()

            # Firefox uses Unix timestamps (microseconds since 1970-01-01)
            current_time = datetime.now()
            cutoff_time = current_time - timedelta(minutes=minutes_back)
            cutoff_firefox_time = int(cutoff_time.timestamp() * 1000000)  # Microseconds

            # Firefox schema: moz_places (url, title) + moz_historyvisits (visit_date)
            query = """
                SELECT
                    p.url,
                    p.title,
                    p.visit_count,
                    h.visit_date
                FROM moz_places p
                JOIN moz_historyvisits h ON p.id = h.place_id
                WHERE h.visit_date > ?
                ORDER BY h.visit_date DESC
            """

            cursor.execute(query, (cutoff_firefox_time,))
            rows = cursor.fetchall()

            for row in rows:
                url, title, visit_count, visit_date = row

                # Convert Firefox time to Python datetime
                visit_timestamp = datetime.fromtimestamp(visit_date / 1000000)

                # Extract domain
                domain = self._extract_domain(url)

                activities.append({
                    'browser_name': 'Firefox',
                    'url': url,
                    'title': title or self._extract_title_from_url(url),
                    'domain': domain,
                    'visit_time': visit_timestamp,
                    'visit_count': visit_count
                })

            conn.close()

        except sqlite3.OperationalError as e:
            self.logger.warning(f"Firefox database locked or corrupted: {e}")
        except Exception as e:
            self.logger.error(f"Error parsing Firefox history: {e}")
        finally:
            if temp_db and os.path.exists(temp_db):
                try:
                    os.remove(temp_db)
                except:
                    pass

        return activities

    def get_recent_activities(self, minutes_back: int = 5) -> List[Dict]:
        """
        Get recent browser activities from all supported browsers

        Args:
            minutes_back: How many minutes back to look

        Returns:
            List of URL activities from all browsers
        """
        all_activities = []

        # Parse Chrome history (ALL profiles) - FIX #2 & #11: Multiple profiles with names
        chrome_paths = self.get_chrome_history_paths()
        if chrome_paths:
            self.logger.info(f"Found {len(chrome_paths)} Chrome profile(s)")
            for chrome_path, profile_name in chrome_paths:
                # FIX #11: Include profile name in browser_name for tracking
                browser_name = f"Chrome ({profile_name})" if profile_name != 'Default' else 'Chrome'
                chrome_activities = self.parse_history_db(chrome_path, browser_name, minutes_back)
                all_activities.extend(chrome_activities)
                if chrome_activities:
                    self.logger.info(f"Found {len(chrome_activities)} activities from {browser_name}")
        else:
            self.logger.debug("Chrome not found or no profiles available")

        # Parse Edge history - FIX #5: Add file existence check
        edge_path = self.get_edge_history_path()
        if edge_path and os.path.exists(edge_path):
            edge_activities = self.parse_history_db(edge_path, 'Edge', minutes_back)
            all_activities.extend(edge_activities)
            if edge_activities:
                self.logger.debug(f"Found {len(edge_activities)} Edge activities")

        # Parse Firefox history (uses different schema) - FIX #5: Add file existence check
        firefox_path = self.get_firefox_history_path()
        if firefox_path and os.path.exists(firefox_path):
            firefox_activities = self.parse_firefox_history_db(firefox_path, minutes_back)
            all_activities.extend(firefox_activities)
            if firefox_activities:
                self.logger.info(f"Found {len(firefox_activities)} Firefox activities")

        # Parse Brave history (same as Chrome) - FIX #5: Add file existence check
        brave_path = self.get_brave_history_path()
        if brave_path and os.path.exists(brave_path):
            brave_activities = self.parse_history_db(brave_path, 'Brave', minutes_back)
            all_activities.extend(brave_activities)
            if brave_activities:
                self.logger.info(f"Found {len(brave_activities)} Brave activities")

        # Parse Opera history (same as Chrome) - FIX #5: Add file existence check
        opera_path = self.get_opera_history_path()
        if opera_path and os.path.exists(opera_path):
            opera_activities = self.parse_history_db(opera_path, 'Opera', minutes_back)
            all_activities.extend(opera_activities)
            if opera_activities:
                self.logger.info(f"Found {len(opera_activities)} Opera activities")

        # Update last check time
        self.last_check_time = datetime.now()

        return all_activities

    def _extract_domain(self, url: str) -> str:
        """Extract domain from URL"""
        try:
            from urllib.parse import urlparse
            parsed = urlparse(url)
            domain = parsed.netloc

            # Remove www. prefix
            if domain.startswith('www.'):
                domain = domain[4:]

            return domain if domain else 'unknown'
        except:
            return 'unknown'

    def _extract_title_from_url(self, url: str) -> str:
        """Extract a readable title from URL"""
        try:
            from urllib.parse import urlparse
            parsed = urlparse(url)
            domain = parsed.netloc

            # Remove www. prefix
            if domain.startswith('www.'):
                domain = domain[4:]

            # Capitalize first letter
            return domain.capitalize()
        except:
            return "Unknown Page"

    def is_browser_running(self, browser_name: str) -> bool:
        """Check if a browser is currently running"""
        try:
            browser_processes = {
                'Chrome': ['chrome.exe', 'chrome', 'Google Chrome'],
                'Edge': ['msedge.exe', 'msedge', 'Microsoft Edge']
            }

            if browser_name not in browser_processes:
                return False

            for proc in psutil.process_iter(['name']):
                try:
                    proc_name = proc.info['name'].lower()
                    for browser_proc in browser_processes[browser_name]:
                        if browser_proc.lower() in proc_name:
                            return True
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue

            return False

        except Exception as e:
            self.logger.debug(f"Error checking browser process: {e}")
            return False

    def filter_youtube_activities(self, activities: List[Dict]) -> List[Dict]:
        """Filter only YouTube activities from list"""
        youtube_keywords = ['youtube.com', 'youtu.be']

        youtube_activities = []
        for activity in activities:
            url_lower = activity['url'].lower()
            domain_lower = activity['domain'].lower()

            if any(keyword in url_lower or keyword in domain_lower for keyword in youtube_keywords):
                youtube_activities.append(activity)

        return youtube_activities

    def filter_social_media_activities(self, activities: List[Dict]) -> List[Dict]:
        """Filter only social media activities from list"""
        social_keywords = [
            'youtube.com', 'youtu.be', 'instagram.com', 'tiktok.com',
            'facebook.com', 'fb.com', 'twitter.com', 'x.com'
        ]

        social_activities = []
        for activity in activities:
            url_lower = activity['url'].lower()
            domain_lower = activity['domain'].lower()

            if any(keyword in url_lower or keyword in domain_lower for keyword in social_keywords):
                social_activities.append(activity)

        return social_activities