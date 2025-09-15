# macOS Screen Recording Permission Helper

import platform
import logging
import subprocess

def check_screen_recording_permission():
    """Check if screen recording permission is granted on macOS"""
    if platform.system() != 'Darwin':
        return True  # Not macOS, assume permission is granted
    
    try:
        # Try importing macOS specific modules
        from Quartz import CGMainDisplayID, CGDisplayCreateImage, CGImageRelease
        from ApplicationServices import kCGNullWindowID
        
        # Try to capture a small area of the screen
        display_id = CGMainDisplayID()
        image = CGDisplayCreateImage(display_id)
        
        if image:
            CGImageRelease(image)
            logging.info("macOS screen recording permission: GRANTED")
            return True
        else:
            logging.warning("macOS screen recording permission: DENIED")
            return False
            
    except ImportError:
        logging.warning("pyobjc not available, cannot check macOS permissions")
        return True  # Assume permission if we can't check
    except Exception as e:
        logging.error(f"Error checking macOS screen recording permission: {e}")
        return False

def request_screen_recording_permission():
    """Show dialog to request screen recording permission"""
    if platform.system() != 'Darwin':
        return True
    
    try:
        from AppKit import NSAlert, NSAlertFirstButtonReturn
        
        alert = NSAlert.alloc().init()
        alert.setMessageText_("Screen Recording Permission Required")
        alert.setInformativeText_(
            "Tenjo needs permission to record your screen for monitoring.\n\n"
            "Please go to:\n"
            "System Preferences → Security & Privacy → Privacy → Screen Recording\n\n"
            "Then check the box next to this application."
        )
        alert.addButtonWithTitle_("Open System Preferences")
        alert.addButtonWithTitle_("Continue Anyway")
        
        response = alert.runModal()
        
        if response == NSAlertFirstButtonReturn:
            # Open System Preferences
            subprocess.run([
                'open', 
                'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture'
            ])
            
        return True
        
    except ImportError:
        logging.info("AppKit not available for permission dialog")
        # Fallback: open system preferences via command line
        try:
            subprocess.run([
                'open', 
                'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture'
            ])
            logging.info("Opened System Preferences for screen recording permission")
        except Exception as e:
            logging.error(f"Could not open System Preferences: {e}")
        
        return True
    except Exception as e:
        logging.error(f"Error requesting screen recording permission: {e}")
        return False

def get_macos_info():
    """Get macOS version and system info"""
    if platform.system() != 'Darwin':
        return None
    
    try:
        import subprocess
        result = subprocess.run(['sw_vers'], capture_output=True, text=True)
        return result.stdout.strip()
    except Exception as e:
        logging.error(f"Error getting macOS info: {e}")
        return None
