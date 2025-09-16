#!/usr/bin/env python3
"""
OS Detection Utility
Deteksi sistem operasi untuk semua platform (Windows, macOS, Linux)
"""

import platform
import sys
import os
import subprocess

def get_windows_version():
    """Get detailed Windows version information"""
    try:
        import winreg
        
        # Get Windows version from registry
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, 
                           r"SOFTWARE\Microsoft\Windows NT\CurrentVersion")
        
        product_name = winreg.QueryValueEx(key, "ProductName")[0]
        build_number = winreg.QueryValueEx(key, "CurrentBuild")[0]
        
        winreg.CloseKey(key)
        
        return {
            'name': product_name,
            'version': build_number,
            'platform': 'Windows',
            'architecture': platform.machine()
        }
    except Exception:
        # Fallback for older Windows or if registry access fails
        version = platform.win32_ver()
        return {
            'name': f"Windows {version[0]}" if version[0] else "Windows",
            'version': version[1] if version[1] else platform.release(),
            'platform': 'Windows',
            'architecture': platform.machine()
        }

def get_macos_version():
    """Get detailed macOS version information"""
    try:
        # Get macOS version
        mac_version = platform.mac_ver()[0]
        
        # Convert version to name
        version_parts = mac_version.split('.')
        major = int(version_parts[0]) if version_parts else 0
        
        if major >= 15:
            name = "macOS Sequoia"
        elif major >= 14:
            name = "macOS Sonoma"
        elif major >= 13:
            name = "macOS Ventura"
        elif major >= 12:
            name = "macOS Monterey"
        elif major >= 11:
            name = "macOS Big Sur"
        elif major >= 10:
            minor = int(version_parts[1]) if len(version_parts) > 1 else 0
            if minor >= 15:
                name = "macOS Catalina"
            elif minor >= 14:
                name = "macOS Mojave"
            elif minor >= 13:
                name = "macOS High Sierra"
            else:
                name = "macOS"
        else:
            name = "macOS"
            
        return {
            'name': name,
            'version': mac_version,
            'platform': 'Darwin',
            'architecture': platform.machine()
        }
    except Exception:
        return {
            'name': 'macOS',
            'version': platform.release(),
            'platform': 'Darwin',
            'architecture': platform.machine()
        }

def get_linux_version():
    """Get detailed Linux distribution information"""
    try:
        # Try to get distribution info
        import distro
        
        return {
            'name': f"{distro.name()} {distro.version()}",
            'version': distro.version(),
            'platform': 'Linux',
            'distribution': distro.name(),
            'architecture': platform.machine()
        }
    except ImportError:
        try:
            # Fallback without distro package
            with open('/etc/os-release', 'r') as f:
                lines = f.readlines()
                
            os_info = {}
            for line in lines:
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    os_info[key] = value.strip('"')
            
            name = os_info.get('PRETTY_NAME', os_info.get('NAME', 'Linux'))
            version = os_info.get('VERSION_ID', platform.release())
            
            return {
                'name': name,
                'version': version,
                'platform': 'Linux',
                'distribution': os_info.get('NAME', 'Unknown'),
                'architecture': platform.machine()
            }
        except Exception:
            return {
                'name': 'Linux',
                'version': platform.release(),
                'platform': 'Linux',
                'architecture': platform.machine()
            }

def detect_os():
    """Detect operating system with detailed information"""
    system = platform.system()
    
    if system == 'Windows':
        return get_windows_version()
    elif system == 'Darwin':
        return get_macos_version()
    elif system == 'Linux':
        return get_linux_version()
    else:
        # Fallback for other systems
        return {
            'name': system,
            'version': platform.release(),
            'platform': system,
            'architecture': platform.machine()
        }

def get_os_info_for_client():
    """Get OS info formatted for Tenjo client registration"""
    os_info = detect_os()
    
    return {
        'name': os_info['name'],
        'version': os_info['version'],
        'platform': os_info['platform'],
        'architecture': os_info.get('architecture', 'unknown'),
        'hostname': platform.node(),
        'user': os.getenv('USER', os.getenv('USERNAME', 'unknown'))
    }

def main():
    """Test OS detection"""
    print("🔍 TENJO OS DETECTION TEST")
    print("=" * 40)
    
    os_info = detect_os()
    
    print("📋 Detected OS Information:")
    for key, value in os_info.items():
        print(f"   {key.title()}: {value}")
    
    print(f"\n📤 Client Registration Format:")
    client_os_info = get_os_info_for_client()
    
    import json
    print(json.dumps(client_os_info, indent=2))
    
    print(f"\n💡 Summary:")
    print(f"   OS: {client_os_info['name']}")
    print(f"   Version: {client_os_info['version']}")
    print(f"   Platform: {client_os_info['platform']}")
    print(f"   Architecture: {client_os_info['architecture']}")

if __name__ == "__main__":
    main()