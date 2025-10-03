"""
Enhanced Browser Tracker Module
Tracks browser activity, tabs, URLs, and time spent on each URL
"""

import time
import json
import threading
import subprocess
import platform
import re
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Set
from dataclasses import dataclass, asdict
import psutil

@dataclass
class BrowserTab:
    """Represents a browser tab"""
    tab_id: str
    url: str
    title: str
    domain: str
    is_active: bool
    created_at: datetime
    last_accessed: datetime
    time_spent: int = 0  # seconds

@dataclass
class BrowserWindow:
    """Represents a browser window"""
    window_id: str
    browser_name: str
    window_title: str
    tabs: List[BrowserTab]
    is_active: bool
    created_at: datetime

@dataclass
class BrowserSession:
    """Represents a browser session"""
    session_id: str
    browser_name: str
    browser_version: str
    executable_path: str
    windows: List[BrowserWindow]
    start_time: datetime
    end_time: Optional[datetime] = None
    total_time: int = 0

class BrowserTracker:
    """Enhanced browser tracking with real-time tab and URL monitoring + activity detection"""
    
    def __init__(self, api_client, logger):
        self.api_client = api_client
        self.logger = logger
        self.running = False
        
        # Browser sessions tracking
        self.active_sessions: Dict[str, BrowserSession] = {}
        self.url_activities: Dict[str, Dict] = {}  # url -> activity data
        
        # Activity detector integration
        self.activity_detector = None
        self.tracking_paused = False  # Flag to pause duration tracking when user inactive
        
        # Platform-specific browser detection
        self.system = platform.system()
        self.browser_processes = {
            'Chrome': ['chrome', 'Google Chrome', 'chrome.exe'],
            'Firefox': ['firefox', 'Firefox', 'firefox.exe'],
            'Safari': ['Safari'],
            'Edge': ['msedge', 'Microsoft Edge', 'msedge.exe'],
            'Opera': ['opera', 'Opera', 'opera.exe'],
            'Brave': ['brave', 'Brave Browser', 'brave.exe']
        }
        
        # Tracking thread
        self.tracker_thread = None
        self.last_check = datetime.now()
        
    def start_tracking(self):
        """Start browser tracking with activity detection"""
        self.logger.info("Starting enhanced browser tracking with smart activity detection...")
        self.running = True
        
        # Initialize and start activity detector
        try:
            from .activity_detector import ActivityDetector
            self.activity_detector = ActivityDetector(self.logger, inactivity_timeout=300)
            
            # Register callbacks for pause/resume
            self.activity_detector.register_activity_paused_callback(self._on_tracking_paused)
            self.activity_detector.register_activity_started_callback(self._on_tracking_resumed)
            
            self.activity_detector.start_monitoring()
            self.logger.info("✓ Activity detection enabled (auto-pause after 5min inactivity)")
        except Exception as e:
            self.logger.warning(f"⚠ Could not initialize activity detection: {e}")
            self.activity_detector = None
        
        self.tracker_thread = threading.Thread(target=self._tracking_loop, daemon=True)
        self.tracker_thread.start()
        
    def stop_tracking(self):
        """Stop browser tracking and activity detection"""
        self.logger.info("Stopping browser tracking...")
        self.running = False
        
        # Stop activity detector
        if self.activity_detector:
            self.activity_detector.stop_monitoring()
            
        if self.tracker_thread:
            self.tracker_thread.join(timeout=5)
            
        # End all active sessions
        for session in self.active_sessions.values():
            self._end_browser_session(session)
    
    def _on_tracking_paused(self):
        """Callback when user activity pauses"""
        self.tracking_paused = True
        self.logger.info("⏸ Duration tracking paused (user inactive)")
    
    def _on_tracking_resumed(self):
        """Callback when user activity resumes"""
        self.tracking_paused = False
        self.logger.info("▶ Duration tracking resumed (user active)")
            
    def _tracking_loop(self):
        """Main tracking loop"""
        while self.running:
            try:
                current_time = datetime.now()
                
                # Detect active browsers
                active_browsers = self._detect_active_browsers()
                
                # Update browser sessions
                self._update_browser_sessions(active_browsers)
                
                # Track tab activities (if browser supports it)
                if self.system == "Darwin":  # macOS
                    self._track_macos_tabs()
                elif self.system == "Windows":
                    self._track_windows_tabs()
                elif self.system == "Linux":
                    self._track_linux_tabs()
                
                # Send data to server
                self._send_tracking_data()
                
                # Update URL activity durations
                self._update_url_durations(current_time)
                
                # Clean up old activities to prevent memory leaks
                self._cleanup_old_activities(current_time)
                
                self.last_check = current_time
                time.sleep(300)  # Check every 5 minutes (optimized from 60s to reduce 80% database growth)
                
            except Exception as e:
                self.logger.error(f"Error in browser tracking loop: {e}")
                time.sleep(10)
                
    def _detect_active_browsers(self) -> Dict[str, List[psutil.Process]]:
        """Detect all active browser processes"""
        active_browsers = {}
        
        try:
            for proc in psutil.process_iter(['pid', 'name', 'exe', 'cmdline']):
                try:
                    proc_info = proc.info
                    proc_name = proc_info['name'] or ''
                    
                    for browser_name, process_names in self.browser_processes.items():
                        if any(pname.lower() in proc_name.lower() for pname in process_names):
                            if browser_name not in active_browsers:
                                active_browsers[browser_name] = []
                            active_browsers[browser_name].append(proc)
                            break
                            
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
                    
        except Exception as e:
            self.logger.error(f"Error detecting browsers: {e}")
            
        return active_browsers
        
    def _update_browser_sessions(self, active_browsers: Dict[str, List[psutil.Process]]):
        """Update browser sessions based on active processes"""
        current_time = datetime.now()
        
        # Track new sessions
        for browser_name, processes in active_browsers.items():
            session_id = f"{browser_name}_{len(processes)}"
            
            if session_id not in self.active_sessions:
                # Create new session
                try:
                    browser_version = self._get_browser_version(browser_name, processes[0])
                    executable_path = processes[0].info.get('exe', 'unknown')
                    
                    session = BrowserSession(
                        session_id=session_id,
                        browser_name=browser_name,
                        browser_version=browser_version,
                        executable_path=executable_path,
                        windows=[],
                        start_time=current_time
                    )
                    
                    self.active_sessions[session_id] = session
                    self.logger.info(f"Started new browser session: {browser_name}")
                    
                except Exception as e:
                    self.logger.error(f"Error creating browser session: {e}")
                    
        # End inactive sessions
        active_session_ids = set()
        for browser_name, processes in active_browsers.items():
            session_id = f"{browser_name}_{len(processes)}"
            active_session_ids.add(session_id)
            
        for session_id in list(self.active_sessions.keys()):
            if session_id not in active_session_ids:
                session = self.active_sessions[session_id]
                self._end_browser_session(session)
                del self.active_sessions[session_id]
                
    def _track_macos_tabs(self):
        """Track browser tabs on macOS using AppleScript"""
        try:
            # Chrome tabs
            self._track_chrome_tabs_macos()
            
            # Safari tabs
            self._track_safari_tabs_macos()
            
        except Exception as e:
            self.logger.error(f"Error tracking macOS tabs: {e}")
            
    def _track_chrome_tabs_macos(self):
        """Track Chrome tabs on macOS"""
        try:
            # Get URLs and titles separately for better accuracy
            url_script = '''
            tell application "Google Chrome"
                set tabInfo to {}
                repeat with w in windows
                    repeat with t in tabs of w
                        set end of tabInfo to (URL of t)
                    end repeat
                end repeat
                return tabInfo
            end tell
            '''
            
            title_script = '''
            tell application "Google Chrome"
                set tabInfo to {}
                repeat with w in windows
                    repeat with t in tabs of w
                        set end of tabInfo to (title of t)
                    end repeat
                end repeat
                return tabInfo
            end tell
            '''
            
            # Get URLs
            url_result = subprocess.run(
                ['osascript', '-e', url_script],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            # Get titles
            title_result = subprocess.run(
                ['osascript', '-e', title_script],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if url_result.returncode == 0 and url_result.stdout.strip():
                urls = [url.strip() for url in url_result.stdout.split(',') if url.strip()]
                titles = []
                
                if title_result.returncode == 0 and title_result.stdout.strip():
                    titles = [title.strip() for title in title_result.stdout.split(',') if title.strip()]
                
                # Match URLs with titles
                current_time = datetime.now()
                for i, url in enumerate(urls):
                    clean_url = url.strip().strip('"').strip("'")
                    if clean_url.startswith('http'):
                        title = titles[i] if i < len(titles) else self._extract_title_from_url(clean_url)
                        title = title.strip().strip('"').strip("'")
                        self._track_url_activity('Chrome', clean_url, title, current_time)
                
        except Exception as e:
            self.logger.debug(f"Chrome tabs not accessible: {e}")
            
    def _track_safari_tabs_macos(self):
        """Track Safari tabs on macOS"""
        try:
            # Get URLs and titles separately for better accuracy
            url_script = '''
            tell application "Safari"
                set tabInfo to {}
                repeat with w in windows
                    repeat with t in tabs of w
                        set end of tabInfo to (URL of t)
                    end repeat
                end repeat
                return tabInfo
            end tell
            '''
            
            title_script = '''
            tell application "Safari"
                set tabInfo to {}
                repeat with w in windows
                    repeat with t in tabs of w
                        set end of tabInfo to (name of t)
                    end repeat
                end repeat
                return tabInfo
            end tell
            '''
            
            # Get URLs
            url_result = subprocess.run(
                ['osascript', '-e', url_script],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            # Get titles
            title_result = subprocess.run(
                ['osascript', '-e', title_script],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if url_result.returncode == 0 and url_result.stdout.strip():
                urls = [url.strip() for url in url_result.stdout.split(',') if url.strip()]
                titles = []
                
                if title_result.returncode == 0 and title_result.stdout.strip():
                    titles = [title.strip() for title in title_result.stdout.split(',') if title.strip()]
                
                # Match URLs with titles
                current_time = datetime.now()
                for i, url in enumerate(urls):
                    clean_url = url.strip().strip('"').strip("'")
                    if clean_url.startswith('http'):
                        title = titles[i] if i < len(titles) else self._extract_title_from_url(clean_url)
                        title = title.strip().strip('"').strip("'")
                        self._track_url_activity('Safari', clean_url, title, current_time)
                
        except Exception as e:
            self.logger.debug(f"Safari tabs not accessible: {e}")
            
    def _track_windows_tabs(self):
        """Track browser tabs on Windows"""
        # Windows tab tracking would require browser-specific APIs
        # For now, we'll track window titles which often contain URLs
        try:
            import win32gui
            import win32process
            
            def enum_windows_callback(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    window_title = win32gui.GetWindowText(hwnd)
                    _, pid = win32process.GetWindowThreadProcessId(hwnd)
                    
                    try:
                        process = psutil.Process(pid)
                        proc_name = process.name().lower()
                        
                        # Check if it's a browser window
                        for browser_name, process_names in self.browser_processes.items():
                            if any(pname.lower() in proc_name for pname in process_names):
                                windows.append({
                                    'browser': browser_name,
                                    'title': window_title,
                                    'pid': pid
                                })
                                break
                                
                    except psutil.NoSuchProcess:
                        pass
                        
                return True
                
            windows = []
            win32gui.EnumWindows(enum_windows_callback, windows)
            
            for window in windows:
                self._extract_url_from_title(window['browser'], window['title'])
                
        except ImportError:
            self.logger.debug("Windows-specific libraries not available")
        except Exception as e:
            self.logger.error(f"Error tracking Windows tabs: {e}")
            
    def _track_linux_tabs(self):
        """Track browser tabs on Linux"""
        # Linux tab tracking is complex and browser-specific
        # For now, we'll track window titles
        try:
            result = subprocess.run(
                ['wmctrl', '-l'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                for line in result.stdout.split('\n'):
                    if line.strip():
                        parts = line.split(None, 3)
                        if len(parts) >= 4:
                            window_title = parts[3]
                            
                            # Check if it's a browser window
                            for browser_name in self.browser_processes.keys():
                                if browser_name.lower() in window_title.lower():
                                    self._extract_url_from_title(browser_name, window_title)
                                    break
                                    
        except FileNotFoundError:
            self.logger.debug("wmctrl not available on this Linux system")
        except Exception as e:
            self.logger.error(f"Error tracking Linux tabs: {e}")
            
    def _parse_chrome_tabs_output(self, output: str):
        """Parse Chrome tabs output from AppleScript"""
        try:
            # AppleScript returns URLs separated by commas
            # Example: "https://google.com, https://github.com, https://stackoverflow.com"
            
            current_time = datetime.now()
            
            # Split by comma and clean each URL
            urls = [url.strip() for url in output.split(',') if url.strip()]
            
            for url in urls:
                # Clean up the URL (remove any quotes or extra spaces)
                clean_url = url.strip().strip('"').strip("'")
                
                if clean_url.startswith('http'):
                    # Extract title from URL or use domain as title
                    title = self._extract_title_from_url(clean_url)
                    self._track_url_activity('Chrome', clean_url, title, current_time)
                
        except Exception as e:
            self.logger.error(f"Error parsing Chrome tabs: {e}")
            
    def _parse_safari_tabs_output(self, output: str):
        """Parse Safari tabs output from AppleScript"""
        try:
            # AppleScript returns URLs separated by commas
            # Example: "https://google.com, https://github.com, https://stackoverflow.com"
            
            current_time = datetime.now()
            
            # Split by comma and clean each URL
            urls = [url.strip() for url in output.split(',') if url.strip()]
            
            for url in urls:
                # Clean up the URL (remove any quotes or extra spaces)
                clean_url = url.strip().strip('"').strip("'")
                
                if clean_url.startswith('http'):
                    # Extract title from URL or use domain as title
                    title = self._extract_title_from_url(clean_url)
                    self._track_url_activity('Safari', clean_url, title, current_time)
                
        except Exception as e:
            self.logger.error(f"Error parsing Safari tabs: {e}")
            
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
            
        except Exception:
            return "Unknown Page"
            
    def _extract_url_from_title(self, browser_name: str, window_title: str):
        """Extract URL from window title where possible"""
        try:
            current_time = datetime.now()
            
            # Common patterns for extracting URLs from titles
            url_patterns = [
                r'https?://[^\s\)]+',  # Direct URL
                r'([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}',  # Domain pattern
            ]
            
            for pattern in url_patterns:
                matches = re.findall(pattern, window_title)
                for match in matches:
                    if not match.startswith('http'):
                        match = f"http://{match}"
                    self._track_url_activity(browser_name, match, window_title, current_time)
                    break
                    
        except Exception as e:
            self.logger.error(f"Error extracting URL from title: {e}")
            
    def _track_url_activity(self, browser_name: str, url: str, title: str, current_time: datetime):
        """Track URL activity"""
        try:
            domain = self._extract_domain(url)
            url_key = f"{browser_name}_{url}"
            
            if url_key not in self.url_activities:
                # New URL activity
                self.url_activities[url_key] = {
                    'browser_name': browser_name,
                    'url': url,
                    'domain': domain,
                    'title': title,
                    'start_time': current_time,
                    'last_seen': current_time,
                    'total_time': 0,
                    'is_active': True
                }
            else:
                # Update existing activity
                activity = self.url_activities[url_key]
                activity['last_seen'] = current_time
                activity['title'] = title  # Update title in case it changed
                
        except Exception as e:
            self.logger.error(f"Error tracking URL activity: {e}")
            
    def _update_url_durations(self, current_time: datetime):
        """Update durations for active URL activities (smart pause when user inactive)"""
        try:
            # Skip duration updates if user is inactive (activity detector paused)
            if self.tracking_paused:
                return
            
            for url_key, activity in self.url_activities.items():
                if activity['is_active']:
                    # Check if URL is still active (seen in last 30 seconds)
                    time_since_seen = (current_time - activity['last_seen']).total_seconds()
                    
                    if time_since_seen > 30:  # Mark as inactive if not seen for 30 seconds
                        activity['is_active'] = False
                        activity['end_time'] = activity['last_seen']
                    else:
                        # Update total time ONLY if user is active
                        time_since_start = (current_time - activity['start_time']).total_seconds()
                        activity['total_time'] = int(time_since_start)
                        
                        # Add activity stats if activity detector is available
                        if self.activity_detector:
                            stats = self.activity_detector.get_activity_stats()
                            activity['clicks'] = stats.get('mouse_clicks', 0)
                            activity['keystrokes'] = stats.get('key_presses', 0)
                            activity['scroll_events'] = stats.get('scroll_events', 0)
                        
        except Exception as e:
            self.logger.error(f"Error updating URL durations: {e}")
            
    def _cleanup_old_activities(self, current_time: datetime):
        """Remove old activities to prevent memory leaks"""
        try:
            cutoff_time = current_time - timedelta(hours=1)
            
            # Clean old URL activities (keep only last 1 hour)
            self.url_activities = {
                key: activity 
                for key, activity in self.url_activities.items()
                if activity.get('last_seen', activity['start_time']) > cutoff_time
            }
            
            # Clean old browser sessions that have ended
            self.active_sessions = {
                session_id: session 
                for session_id, session in self.active_sessions.items()
                if session.end_time is None or (current_time - session.end_time).total_seconds() < 3600
            }
            
            # Log cleanup stats every hour
            if hasattr(self, '_last_cleanup_log'):
                time_since_log = (current_time - self._last_cleanup_log).total_seconds()
                if time_since_log > 3600:  # Log every hour
                    self.logger.info(f"Memory cleanup: {len(self.url_activities)} URL activities, {len(self.active_sessions)} sessions in memory")
                    self._last_cleanup_log = current_time
            else:
                self._last_cleanup_log = current_time
                
        except Exception as e:
            self.logger.error(f"Error cleaning up old activities: {e}")
            
    def _send_tracking_data(self):
        """Send tracking data to server"""
        try:
            # Prepare browser sessions data
            sessions_data = []
            for session in self.active_sessions.values():
                session_data = {
                    'session_id': session.session_id,
                    'browser_name': session.browser_name,
                    'browser_version': session.browser_version,
                    'executable_path': session.executable_path,
                    'start_time': session.start_time.isoformat(),
                    'window_count': len(session.windows),
                    'is_active': True
                }
                sessions_data.append(session_data)
                
            # Prepare URL activities data
            url_data = []
            for activity in self.url_activities.values():
                if activity['total_time'] > 30:  # Only send activities > 30 seconds (optimized from 0 to reduce 60% database growth)
                    url_activity = {
                        'browser_name': activity['browser_name'],
                        'url': activity['url'],
                        'domain': activity['domain'],
                        'title': activity['title'],
                        'start_time': activity['start_time'].isoformat(),
                        'duration': activity['total_time'],
                        'is_active': activity['is_active']
                    }
                    
                    if not activity['is_active'] and 'end_time' in activity:
                        url_activity['end_time'] = activity['end_time'].isoformat()
                        
                    url_data.append(url_activity)
                    
            # Send to server
            if sessions_data or url_data:
                # Import Config using absolute import
                import sys
                import os
                sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
                from core.config import Config
                
                tracking_data = {
                    'client_id': Config.CLIENT_ID,
                    'browser_sessions': sessions_data,
                    'url_activities': url_data,
                    'timestamp': datetime.now().isoformat()
                }
                
                self.api_client.send_browser_tracking(tracking_data)
                
        except Exception as e:
            self.logger.error(f"Error sending tracking data: {e}")
            
    def _get_browser_version(self, browser_name: str, process: psutil.Process) -> str:
        """Get browser version"""
        try:
            if self.system == "Darwin":  # macOS
                if browser_name == "Chrome":
                    result = subprocess.run(
                        ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', '--version'],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    return result.stdout.strip()
                elif browser_name == "Safari":
                    # Safari version detection on macOS
                    return "Safari (macOS)"
                    
            elif self.system == "Windows":
                # Windows version detection
                if hasattr(process, 'exe'):
                    try:
                        import win32api
                        version_info = win32api.GetFileVersionInfo(process.exe(), "\\")
                        version = f"{version_info['FileVersionLS'] >> 16}.{version_info['FileVersionLS'] & 0xFFFF}"
                        return version
                    except:
                        pass
                        
            return "Unknown"
            
        except Exception as e:
            self.logger.debug(f"Could not get browser version: {e}")
            return "Unknown"
            
    def _extract_domain(self, url: str) -> str:
        """Extract domain from URL"""
        try:
            from urllib.parse import urlparse
            parsed = urlparse(url)
            return parsed.netloc or 'unknown'
        except:
            return 'unknown'
            
    def _end_browser_session(self, session: BrowserSession):
        """End a browser session"""
        try:
            session.end_time = datetime.now()
            session.total_time = int((session.end_time - session.start_time).total_seconds())
            
            self.logger.info(f"Ended browser session: {session.browser_name} (Duration: {session.total_time}s)")
            
        except Exception as e:
            self.logger.error(f"Error ending browser session: {e}")
            
    def get_current_activity_summary(self) -> Dict:
        """Get current browser activity summary"""
        try:
            summary = {
                'active_browsers': len(self.active_sessions),
                'browser_sessions': [],
                'active_urls': 0,
                'total_tabs': 0
            }
            
            for session in self.active_sessions.values():
                session_info = {
                    'browser_name': session.browser_name,
                    'session_duration': int((datetime.now() - session.start_time).total_seconds()),
                    'window_count': len(session.windows)
                }
                summary['browser_sessions'].append(session_info)
                
            # Count active URLs
            active_urls = sum(1 for activity in self.url_activities.values() if activity['is_active'])
            summary['active_urls'] = active_urls
            
            return summary
            
        except Exception as e:
            self.logger.error(f"Error getting activity summary: {e}")
            return {}
