"""
Smart Activity Detector Module
Tracks user interactions: mouse movements, clicks, keyboard typing
Auto-pauses tracking after 5 minutes of inactivity
"""

import time
import threading
from datetime import datetime, timedelta
from typing import Dict, Optional, Callable
import platform

class ActivityDetector:
    """
    Detects user activity (mouse, keyboard, clicks) and manages
    auto-pause/resume functionality for activity tracking.
    """

    def __init__(self, logger, inactivity_timeout: int = 300):
        """
        Initialize Activity Detector

        Args:
            logger: Logger instance
            inactivity_timeout: Seconds of inactivity before auto-pause (default: 300 = 5 minutes)
        """
        self.logger = logger
        self.inactivity_timeout = inactivity_timeout
        self.running = False

        # Activity tracking
        self.last_activity_time = datetime.now()
        self.is_active = True  # User is currently active

        # Activity statistics
        self.activity_stats = {
            'mouse_movements': 0,
            'mouse_clicks': 0,
            'key_presses': 0,
            'scroll_events': 0,
            'last_reset': datetime.now()
        }

        # Callbacks
        self.on_activity_started: Optional[Callable] = None
        self.on_activity_paused: Optional[Callable] = None

        # Monitoring thread
        self.monitor_thread = None

        # Platform-specific setup
        self.system = platform.system()
        self._setup_platform_monitoring()

    def _setup_platform_monitoring(self):
        """Setup platform-specific activity monitoring"""
        try:
            if self.system == "Darwin":  # macOS
                # Try to import AppKit for macOS event monitoring
                try:
                    from AppKit import NSEvent
                    from Quartz import CGEventSourceSecondsSinceLastEventType, kCGEventSourceStateHIDSystemState
                    self.has_native_monitor = True
                    self.event_types = {
                        'mouse_move': 5,  # kCGEventMouseMoved
                        'mouse_down': 1,  # kCGEventLeftMouseDown
                        'key_down': 10    # kCGEventKeyDown
                    }
                    self.logger.info("✓ Using native macOS activity monitoring")
                except ImportError:
                    self.has_native_monitor = False
                    self.logger.warning("⚠ AppKit/Quartz not available, using fallback monitoring")

            elif self.system == "Windows":
                # Try to import win32api for Windows event monitoring
                try:
                    import win32api
                    self.has_native_monitor = True
                    self.logger.info("✓ Using native Windows activity monitoring")
                except ImportError:
                    self.has_native_monitor = False
                    self.logger.warning("⚠ win32api not available, using fallback monitoring")
            else:
                self.has_native_monitor = False
                self.logger.info("ℹ Using fallback activity monitoring")

        except Exception as e:
            self.logger.error(f"Error setting up activity monitoring: {e}")
            self.has_native_monitor = False

    def start_monitoring(self):
        """Start activity monitoring"""
        self.logger.info(f"Starting activity detection (auto-pause after {self.inactivity_timeout}s inactivity)...")
        self.running = True
        self.last_activity_time = datetime.now()
        self.is_active = True

        self.monitor_thread = threading.Thread(target=self._monitoring_loop, daemon=True)
        self.monitor_thread.start()

    def stop_monitoring(self):
        """Stop activity monitoring"""
        self.logger.info("Stopping activity detection...")
        self.running = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=3)

    def _monitoring_loop(self):
        """Main monitoring loop - checks for user activity periodically"""
        while self.running:
            try:
                current_time = datetime.now()

                # Check for activity using platform-specific method
                if self._detect_activity():
                    self._on_activity_detected(current_time)

                # Check for inactivity timeout
                seconds_since_activity = (current_time - self.last_activity_time).total_seconds()

                if self.is_active and seconds_since_activity >= self.inactivity_timeout:
                    # User became inactive
                    self._on_inactivity_detected(current_time)
                elif not self.is_active and seconds_since_activity < self.inactivity_timeout:
                    # User became active again
                    self._on_activity_resumed(current_time)

                # Sleep before next check (more frequent checks for responsiveness)
                time.sleep(2)

            except Exception as e:
                self.logger.error(f"Error in activity monitoring loop: {e}")
                time.sleep(5)

    def _detect_activity(self) -> bool:
        """
        Detect if user has been active recently
        Returns True if activity detected in the last check interval
        """
        try:
            if self.system == "Darwin" and self.has_native_monitor:
                return self._detect_activity_macos()
            elif self.system == "Windows" and self.has_native_monitor:
                return self._detect_activity_windows()
            else:
                return self._detect_activity_fallback()
        except Exception as e:
            self.logger.error(f"Error detecting activity: {e}")
            return False

    def _detect_activity_macos(self) -> bool:
        """Detect activity on macOS using Quartz"""
        try:
            from Quartz import CGEventSourceSecondsSinceLastEventType, kCGEventSourceStateHIDSystemState

            # Check seconds since last mouse/keyboard event
            mouse_seconds = CGEventSourceSecondsSinceLastEventType(
                kCGEventSourceStateHIDSystemState, 5  # kCGEventMouseMoved
            )
            key_seconds = CGEventSourceSecondsSinceLastEventType(
                kCGEventSourceStateHIDSystemState, 10  # kCGEventKeyDown
            )
            click_seconds = CGEventSourceSecondsSinceLastEventType(
                kCGEventSourceStateHIDSystemState, 1  # kCGEventLeftMouseDown
            )

            # Activity detected if any event within last 2 seconds
            if mouse_seconds < 2:
                self.activity_stats['mouse_movements'] += 1
                return True
            if key_seconds < 2:
                self.activity_stats['key_presses'] += 1
                return True
            if click_seconds < 2:
                self.activity_stats['mouse_clicks'] += 1
                return True

            return False

        except Exception as e:
            self.logger.error(f"Error detecting macOS activity: {e}")
            return False

    def _detect_activity_windows(self) -> bool:
        """Detect activity on Windows using win32api"""
        try:
            import win32api

            # Get last input info
            last_input_info = win32api.GetLastInputInfo()
            current_tick = win32api.GetTickCount()

            # Calculate seconds since last input
            idle_seconds = (current_tick - last_input_info) / 1000.0

            # Activity detected if input within last 2 seconds
            if idle_seconds < 2:
                # Increment general activity counter
                self.activity_stats['key_presses'] += 1  # Can't differentiate on Windows easily
                return True

            return False

        except Exception as e:
            self.logger.error(f"Error detecting Windows activity: {e}")
            return False

    def _detect_activity_fallback(self) -> bool:
        """
        Fallback activity detection using process monitoring
        Checks if CPU usage indicates user activity
        """
        try:
            import psutil

            # Get CPU usage (activity indicator)
            cpu_percent = psutil.cpu_percent(interval=0.1)

            # Consider active if CPU usage > 5% (user likely doing something)
            if cpu_percent > 5:
                return True

            return False

        except Exception as e:
            self.logger.error(f"Error in fallback activity detection: {e}")
            return False

    def _on_activity_detected(self, current_time: datetime):
        """Called when user activity is detected"""
        self.last_activity_time = current_time

        # If was inactive, resume tracking
        if not self.is_active:
            self._on_activity_resumed(current_time)

    def _on_activity_resumed(self, current_time: datetime):
        """Called when user activity resumes after pause"""
        if not self.is_active:
            self.is_active = True
            self.logger.info("✓ User activity resumed - tracking restarted")

            # Call callback if set
            if self.on_activity_started:
                self.on_activity_started()

    def _on_inactivity_detected(self, current_time: datetime):
        """Called when user becomes inactive (5+ minutes)"""
        if self.is_active:
            self.is_active = False
            inactive_duration = (current_time - self.last_activity_time).total_seconds()
            self.logger.info(f"⏸ User inactive for {inactive_duration:.0f}s - tracking paused")

            # Call callback if set
            if self.on_activity_paused:
                self.on_activity_paused()

    def register_activity_started_callback(self, callback: Callable):
        """Register callback for when activity starts"""
        self.on_activity_started = callback

    def register_activity_paused_callback(self, callback: Callable):
        """Register callback for when activity pauses"""
        self.on_activity_paused = callback

    def get_activity_stats(self) -> Dict:
        """Get current activity statistics"""
        return {
            **self.activity_stats,
            'is_active': self.is_active,
            'last_activity': self.last_activity_time.isoformat(),
            'seconds_since_activity': (datetime.now() - self.last_activity_time).total_seconds()
        }

    def reset_stats(self):
        """Reset activity statistics"""
        self.activity_stats = {
            'mouse_movements': 0,
            'mouse_clicks': 0,
            'key_presses': 0,
            'scroll_events': 0,
            'last_reset': datetime.now()
        }

    def is_user_active(self) -> bool:
        """Check if user is currently active"""
        return self.is_active

    def get_seconds_since_activity(self) -> float:
        """Get seconds since last activity"""
        return (datetime.now() - self.last_activity_time).total_seconds()
