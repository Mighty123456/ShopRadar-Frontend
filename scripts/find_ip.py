#!/usr/bin/env python3
"""
ShopRadar Network Configuration - IP Address Finder
This script helps find your computer's IP address for network configuration.
"""

import socket
import subprocess
import platform
import sys

def get_local_ip():
    """Get the local IP address of the computer."""
    try:
        # Create a socket to get local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        return None

def get_all_ips():
    """Get all available IP addresses."""
    ips = []
    
    try:
        if platform.system() == "Windows":
            # Windows: use ipconfig
            result = subprocess.run(['ipconfig'], capture_output=True, text=True)
            lines = result.stdout.split('\n')
            
            for line in lines:
                if 'IPv4' in line and ':' in line:
                    ip = line.split(':')[-1].strip()
                    if ip and not ip.startswith(('127.', '169.254.', '10.0.2.')):
                        ips.append(ip)
                        
        elif platform.system() == "Darwin":  # macOS
            # macOS: use ifconfig
            result = subprocess.run(['ifconfig'], capture_output=True, text=True)
            lines = result.stdout.split('\n')
            
            for line in lines:
                if 'inet ' in line and '127.0.0.1' not in line:
                    parts = line.split()
                    for part in parts:
                        if '.' in part and part.count('.') == 3:
                            ip = part.strip()
                            if ip and not ip.startswith(('127.', '169.254.', '10.0.2.')):
                                ips.append(ip)
                                
        else:  # Linux
            # Linux: use ip addr
            result = subprocess.run(['ip', 'addr'], capture_output=True, text=True)
            lines = result.stdout.split('\n')
            
            for line in lines:
                if 'inet ' in line and '127.0.0.1' not in line:
                    parts = line.split()
                    for part in parts:
                        if '.' in part and part.count('.') == 3:
                            ip = part.strip()
                            if ip and not ip.startswith(('127.', '169.254.', '10.0.2.')):
                                ips.append(ip)
                                
    except Exception as e:
        print(f"Error getting IP addresses: {e}")
    
    return ips

def main():
    """Main function to display IP information."""
    print("=" * 50)
    print("    ShopRadar Network Configuration")
    print("=" * 50)
    print()
    
    print("Finding your computer's IP address...")
    print()
    
    # Get local IP (most reliable)
    local_ip = get_local_ip()
    if local_ip:
        print(f"🌐 Primary IP (Local): {local_ip}")
        print(f"🔗 Backend URL: http://{local_ip}:3000")
        print()
    
    # Get all available IPs
    all_ips = get_all_ips()
    if all_ips:
        print("📡 All available IP addresses:")
        for ip in all_ips:
            if ip != local_ip:  # Don't show primary IP twice
                print(f"   • {ip}")
                print(f"     Backend URL: http://{ip}:3000")
        print()
    
    if not local_ip and not all_ips:
        print("❌ No IP addresses found.")
        return
    
    print("=" * 50)
    print()
    print("📋 Next steps:")
    print("1. Update your network_config.dart with one of the IPs above")
    print("2. Make sure your backend is running on port 3000")
    print("3. Ensure your phone and computer are on the same network")
    print("4. Check if port 3000 is not blocked by firewall")
    print()
    
    if local_ip:
        print("💡 Recommended configuration:")
        print(f"   physicalDevice: 'http://{local_ip}:3000',")
        print()
    
    print("🚀 To start your backend server:")
    print("   cd backend_node && npm start")
    print()
    
    print("🔧 To test backend connectivity:")
    if local_ip:
        print(f"   curl http://{local_ip}:3000/health")
    print()
    
    input("Press Enter to continue...")

if __name__ == "__main__":
    main()
