#!/usr/bin/env python3
"""
Check Client Configuration - Diagnostic Tool
Shows what server URL the client is configured to use
"""

import sys
import os

sys.path.append('src')

from src.core.config import Config

print("="*70)
print("🔍 TENJO CLIENT CONFIGURATION CHECK")
print("="*70)
print()

print("📋 Current Configuration:")
print(f"  • Client ID:       {Config.CLIENT_ID}")
print(f"  • Hostname:        {Config.HOSTNAME}")
print(f"  • Platform:        {Config.PLATFORM}")
print(f"  • IP Address:      {Config.IP_ADDRESS}")
print(f"  • Username:        {Config.CLIENT_USER}")
print()

print("🌐 Server Configuration:")
print(f"  • DEFAULT_SERVER_URL: {Config.DEFAULT_SERVER_URL}")
print(f"  • SERVER_URL:         {Config.SERVER_URL}")
print(f"  • API_ENDPOINT:       {Config.API_ENDPOINT}")
print()

print("🔧 Environment Variables:")
env_vars = ['TENJO_SERVER_URL', 'TENJO_API_ENDPOINT', 'TENJO_PREFERRED_SERVER_URL']
for var in env_vars:
    value = os.getenv(var, 'Not set')
    print(f"  • {var}: {value}")
print()

print("="*70)
print("💡 EXPECTED FOR PRODUCTION:")
print("="*70)
print("  • SERVER_URL should be: https://tenjo.adilabs.id")
print("  • API_ENDPOINT should be: https://tenjo.adilabs.id/api")
print()

# Check if configuration is correct
is_correct = (
    Config.SERVER_URL == "https://tenjo.adilabs.id" or
    Config.DEFAULT_SERVER_URL == "https://tenjo.adilabs.id"
)

if is_correct:
    print("✅ Configuration looks CORRECT for production!")
else:
    print("❌ Configuration INCORRECT - Client will not connect to production!")
    print()
    print("🔧 FIX:")
    print("  Set environment variable:")
    print("  export TENJO_SERVER_URL=https://tenjo.adilabs.id")
    print()
    print("  Or update src/core/config.py:")
    print("  DEFAULT_SERVER_URL = 'https://tenjo.adilabs.id'")

print("="*70)
