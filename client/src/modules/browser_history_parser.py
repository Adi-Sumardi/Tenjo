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

    def get_chrome_history_path(self) -> Optional[str]:
        """Get Chrome history database path based on OS"""
        if self.system == 'Windows':
            # Windows Chrome history path
            local_appdata = os.getenv('LOCALAPPDATA')
            if local_appdata:
                return os.path.join(local_appdata, 'Google', 'Chrome', 'User Data', 'Default', 'History')
        elif self.system == 'Darwin':
            # macOS Chrome history path
            home = os.path.expanduser('~')
            return os.path.join(home, 'Library', 'Application Support', 'Google', 'Chrome', 'Default', 'History')
        elif self.system == 'Linux':
            # Linux Chrome history path
            home = os.path.expanduser('~')
            return os.path.join(home, '.config', 'google-chrome', 'Default', 'History')
        return None

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

    def copy_history_db(self, source_path: str) -> Optional[str]:
        """
        Copy history database to temp location
        (Chrome/Edge locks the DB while running)
        """
        try:
            if not os.path.exists(source_path):
                return None

            # Create temp file
            temp_fd, temp_path = tempfile.mkstemp(suffix='.db')
            os.close(temp_fd)

            # Copy database
            shutil.copy2(source_path, temp_path)
            return temp_path

        except Exception as e:
            self.logger.debug(f"Failed to copy history DB: {e}")
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
            self.logger.debug(f"Database locked or corrupted: {e}")
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

    def get_recent_activities(self, minutes_back: int = 5) -> List[Dict]:
        """
        Get recent browser activities from all supported browsers

        Args:
            minutes_back: How many minutes back to look

        Returns:
            List of URL activities from all browsers
        """
        all_activities = []

        # Parse Chrome history
        chrome_path = self.get_chrome_history_path()
        if chrome_path:
            chrome_activities = self.parse_history_db(chrome_path, 'Chrome', minutes_back)
            all_activities.extend(chrome_activities)
            if chrome_activities:
                self.logger.debug(f"Found {len(chrome_activities)} Chrome activities")

        # Parse Edge history
        edge_path = self.get_edge_history_path()
        if edge_path:
            edge_activities = self.parse_history_db(edge_path, 'Edge', minutes_back)
            all_activities.extend(edge_activities)
            if edge_activities:
                self.logger.debug(f"Found {len(edge_activities)} Edge activities")

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