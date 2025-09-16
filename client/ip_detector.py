#!/usr/bin/env python3
"""
IP Address Detection Utility
Deteksi IP address sebenarnya dari network interface
"""

import socket
import subprocess
import platform
import sys
import os

def get_local_ip_socket():
    """Get local IP using socket connection method"""
    try:
        # Connect to external address to determine local IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception:
        return None

def get_local_ip_ifconfig():
    """Get local IP using ifconfig (macOS/Linux)"""
    try:
        if platform.system() == "Darwin":  # macOS
            result = subprocess.run(['ifconfig'], capture_output=True, text=True)
            lines = result.stdout.split('\n')
            
            for line in lines:
                if 'inet ' in line and '127.0.0.1' not in line and 'inet 169.254' not in line:
                    parts = line.strip().split()
                    for i, part in enumerate(parts):
                        if part == 'inet' and i+1 < len(parts):
                            ip = parts[i+1]
                            # Validate IP format
                            if '.' in ip and len(ip.split('.')) == 4:
                                return ip
        return None
    except Exception:
        return None

def get_local_ip_windows():
    """Get local IP for Windows"""
    try:
        result = subprocess.run(['ipconfig'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        
        for line in lines:
            if 'IPv4 Address' in line and '127.0.0.1' not in line:
                ip = line.split(':')[-1].strip()
                if '.' in ip and len(ip.split('.')) == 4:
                    return ip
        return None
    except Exception:
        return None

def get_best_local_ip():
    """Get the best available local IP address"""
    
    # Method 1: Socket connection (most reliable)
    ip = get_local_ip_socket()
    if ip and ip != '127.0.0.1':
        return ip
    
    # Method 2: Platform-specific commands
    if platform.system() == "Darwin":  # macOS
        ip = get_local_ip_ifconfig()
        if ip:
            return ip
    elif platform.system() == "Windows":
        ip = get_local_ip_windows()
        if ip:
            return ip
    
    # Method 3: Fallback to hostname resolution
    try:
        hostname = socket.gethostname()
        ip = socket.gethostbyname(hostname)
        if ip != '127.0.0.1':
            return ip
    except Exception:
        pass
    
    # Last resort
    return '127.0.0.1'

def get_all_network_interfaces():
    """Get all network interfaces and their IPs"""
    interfaces = {}
    
    try:
        if platform.system() == "Darwin":  # macOS
            result = subprocess.run(['ifconfig'], capture_output=True, text=True)
            current_interface = None
            
            for line in result.stdout.split('\n'):
                line = line.strip()
                if line and not line.startswith(' ') and ':' in line:
                    current_interface = line.split(':')[0]
                    interfaces[current_interface] = []
                elif 'inet ' in line and current_interface:
                    parts = line.split()
                    for i, part in enumerate(parts):
                        if part == 'inet' and i+1 < len(parts):
                            ip = parts[i+1]
                            if '.' in ip and len(ip.split('.')) == 4:
                                interfaces[current_interface].append(ip)
    except Exception as e:
        print(f"Error getting interfaces: {e}")
    
    return interfaces

def main():
    print("🌐 MacBook Network Interface Detection")
    print("=" * 45)
    
    # Get best IP
    best_ip = get_best_local_ip()
    print(f"🎯 Best Local IP: {best_ip}")
    
    # Show all interfaces
    print(f"\n📡 All Network Interfaces:")
    interfaces = get_all_network_interfaces()
    
    for interface, ips in interfaces.items():
        if ips:
            print(f"   {interface}: {', '.join(ips)}")
    
    # System info
    print(f"\n💻 System Info:")
    print(f"   Platform: {platform.system()}")
    print(f"   Hostname: {socket.gethostname()}")
    
    # Recommendations
    print(f"\n💡 Recommendations:")
    if best_ip.startswith('192.168.'):
        print("   ✅ Private network IP detected (good for local network)")
    elif best_ip.startswith('10.'):
        print("   ✅ Private network IP detected (good for corporate network)")
    elif best_ip == '127.0.0.1':
        print("   ⚠️  Only localhost detected - check network connection")
    else:
        print("   ✅ Public/assigned IP detected")

if __name__ == "__main__":
    main()