#!/usr/bin/env python3
"""
Quick Dashboard & Client Diagnostic
Cek koneksi dan status real-time
"""

import requests
import json
import time
from datetime import datetime

def test_dashboard_endpoints():
    """Test all dashboard endpoints"""
    base_url = "http://127.0.0.1:8000"
    
    endpoints = [
        "/api/health",
        "/api/clients/status", 
        "/api/screenshots",
        "/api/browser-tracking"
    ]
    
    print("🔍 TESTING DASHBOARD ENDPOINTS:")
    print("=" * 40)
    
    for endpoint in endpoints:
        try:
            if endpoint == "/api/screenshots" or endpoint == "/api/browser-tracking":
                # Test POST for these endpoints
                response = requests.post(f"{base_url}{endpoint}", 
                                       json={"test": "data"}, 
                                       timeout=3)
            else:
                # Test GET for others
                response = requests.get(f"{base_url}{endpoint}", timeout=3)
                
            print(f"   {endpoint}: {response.status_code} {'✅' if response.status_code < 400 else '❌'}")
            
        except Exception as e:
            print(f"   {endpoint}: ❌ Error - {str(e)[:50]}")
    
    print()

def check_client_registration():
    """Test client registration"""
    print("🔐 TESTING CLIENT REGISTRATION:")
    print("=" * 40)
    
    registration_data = {
        "client_id": "a50df0a2-d4f6-9c44-f9b9-b480d8f5a88b",
        "hostname": "MacBook-Air",
        "platform": "Darwin",
        "ip_address": "127.0.0.1"
    }
    
    try:
        response = requests.post("http://127.0.0.1:8000/api/clients/register", 
                               json=registration_data, timeout=5)
        print(f"   Registration Status: {response.status_code}")
        if response.status_code == 422:
            print(f"   Error Details: {response.text[:100]}")
        elif response.status_code == 200:
            print("   ✅ Registration successful")
        else:
            print(f"   ⚠️  Status: {response.status_code}")
            
    except Exception as e:
        print(f"   ❌ Registration failed: {e}")
    
    print()

def check_live_clients():
    """Check live clients in dashboard"""
    print("👥 CHECKING LIVE CLIENTS:")
    print("=" * 40)
    
    try:
        response = requests.get("http://127.0.0.1:8000/api/clients/status", timeout=3)
        if response.status_code == 200:
            clients = response.json()
            print(f"   Total Clients: {len(clients)}")
            
            for client in clients:
                client_id = client.get('client_id', 'unknown')[:8]
                is_online = client.get('is_online', False)
                last_seen = client.get('last_seen_human', 'unknown')
                print(f"   Client {client_id}...: {'🟢 Online' if is_online else '🔴 Offline'} (Last: {last_seen})")
        else:
            print(f"   ❌ Failed to get clients: {response.status_code}")
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    print()

def test_live_streaming():
    """Test live streaming endpoints"""
    print("📹 TESTING LIVE STREAMING:")
    print("=" * 40)
    
    client_id = "a50df0a2-d4f6-9c44-f9b9-b480d8f5a88b"
    
    try:
        # Test stream request
        response = requests.get(f"http://127.0.0.1:8000/api/stream/request/{client_id}", timeout=3)
        print(f"   Stream Request: {response.status_code} {'✅' if response.status_code == 200 else '❌'}")
        
        # Test live view URL
        live_url = f"http://127.0.0.1:8000/client/{client_id}/live"
        response = requests.get(live_url, timeout=3)
        print(f"   Live View: {response.status_code} {'✅' if response.status_code == 200 else '❌'}")
        
    except Exception as e:
        print(f"   ❌ Streaming test failed: {e}")
    
    print()

def main():
    print("🛠️  TENJO DASHBOARD & CLIENT DIAGNOSTIC")
    print("=" * 50)
    print(f"🕒 Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Run all tests
    test_dashboard_endpoints()
    check_client_registration()
    check_live_clients()
    test_live_streaming()
    
    print("✅ Diagnostic completed!")
    print("💡 Recommendations:")
    print("   - If endpoints show 422/404: Check Laravel routes")
    print("   - If registration fails: Check ClientController")
    print("   - If no clients online: Restart client with proper registration")
    print("   - If live stream fails: Check StreamController and routes")

if __name__ == "__main__":
    main()