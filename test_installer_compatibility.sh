#!/bin/bash

# Tenjo Installer Compatibility Test
# Test semua installer untuk memastikan compatibility dengan sistem

echo "🧪 TENJO INSTALLER COMPATIBILITY TEST"
echo "====================================="

# Test environment
echo "📋 System Information:"
echo "   OS: $(uname -s) $(uname -r)"
echo "   Architecture: $(uname -m)"
echo "   Python: $(python3 --version 2>/dev/null || echo 'Not found')"
echo "   Git: $(git --version 2>/dev/null || echo 'Not found')"
echo

# Test Python version compatibility
echo "🐍 Python Compatibility Test:"
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    major=$(echo $python_version | cut -d. -f1)
    minor=$(echo $python_version | cut -d. -f2)
    
    if [[ $major -eq 3 && $minor -ge 13 ]]; then
        echo "   ✅ Python $python_version is compatible (>= 3.13)"
        python_compatible=true
    else
        echo "   ❌ Python $python_version is too old (requires >= 3.13)"
        python_compatible=false
    fi
else
    echo "   ❌ Python 3 not found"
    python_compatible=false
fi
echo

# Test OS Detection
echo "🔍 OS Detection Test:"
if [[ -f "client/os_detector.py" ]]; then
    cd client
    if python3 -c "from os_detector import get_os_info_for_client; print('✅ OS Detection working')" 2>/dev/null; then
        os_info=$(python3 -c "from os_detector import get_os_info_for_client; info = get_os_info_for_client(); print(f\"{info['name']} {info['version']} ({info['architecture']})\")")
        echo "   ✅ OS Detection: $os_info"
        os_detection_working=true
    else
        echo "   ❌ OS Detection failed"
        os_detection_working=false
    fi
    cd ..
else
    echo "   ❌ OS detector not found"
    os_detection_working=false
fi
echo

# Test Dependencies
echo "📦 Dependencies Test:"
if [[ -f "client/requirements.txt" ]]; then
    echo "   📋 Testing required modules:"
    
    modules=("requests" "websocket" "psutil" "mss" "PIL")
    all_modules_available=true
    
    for module in "${modules[@]}"; do
        if python3 -c "import $module" 2>/dev/null; then
            echo "   ✅ $module"
        else
            echo "   ❌ $module (missing)"
            all_modules_available=false
        fi
    done
else
    echo "   ❌ requirements.txt not found"
    all_modules_available=false
fi
echo

# Test Application Startup
echo "🚀 Application Startup Test:"
if [[ -f "client/main.py" ]]; then
    cd client
    # Use different timeout method for macOS vs Linux
    if command -v timeout &> /dev/null; then
        # Linux/GNU timeout
        timeout_cmd="timeout 5"
    elif command -v gtimeout &> /dev/null; then
        # macOS with GNU coreutils
        timeout_cmd="gtimeout 5"
    else
        # No timeout available, just run directly
        timeout_cmd=""
    fi
    
    if $timeout_cmd python3 -c "
import sys
sys.path.append('src')
try:
    from src.core.config import Config
    print('✅ Configuration loading works')
except Exception as e:
    print(f'❌ Configuration loading failed: {e}')
    exit(1)
" 2>/dev/null; then
        echo "   ✅ Application can initialize"
        app_startup_working=true
    else
        echo "   ❌ Application initialization failed"
        app_startup_working=false
    fi
    cd ..
else
    echo "   ❌ main.py not found"
    app_startup_working=false
fi
echo

# Test Installer Syntax
echo "📝 Installer Syntax Test:"

installers=("install_macos_production.sh" "install_windows_production.bat" "install_linux_production.sh")
installer_syntax_ok=true

for installer in "${installers[@]}"; do
    if [[ -f "$installer" ]]; then
        case $installer in
            *.sh)
                if bash -n "$installer" 2>/dev/null; then
                    echo "   ✅ $installer (syntax OK)"
                else
                    echo "   ❌ $installer (syntax error)"
                    installer_syntax_ok=false
                fi
                ;;
            *.bat)
                # Basic check for Windows batch file
                if grep -q "@echo off" "$installer"; then
                    echo "   ✅ $installer (basic structure OK)"
                else
                    echo "   ❌ $installer (missing basic structure)"
                    installer_syntax_ok=false
                fi
                ;;
        esac
    else
        echo "   ❌ $installer (not found)"
        installer_syntax_ok=false
    fi
done
echo

# Overall Compatibility Assessment
echo "🎯 COMPATIBILITY ASSESSMENT:"
echo "=============================="

total_tests=5
passed_tests=0

if [[ $python_compatible == true ]]; then
    echo "✅ Python Compatibility: PASS"
    ((passed_tests++))
else
    echo "❌ Python Compatibility: FAIL"
fi

if [[ $os_detection_working == true ]]; then
    echo "✅ OS Detection: PASS"
    ((passed_tests++))
else
    echo "❌ OS Detection: FAIL"
fi

if [[ $all_modules_available == true ]]; then
    echo "✅ Dependencies: PASS"
    ((passed_tests++))
else
    echo "❌ Dependencies: FAIL"
fi

if [[ $app_startup_working == true ]]; then
    echo "✅ Application Startup: PASS"
    ((passed_tests++))
else
    echo "❌ Application Startup: FAIL"
fi

if [[ $installer_syntax_ok == true ]]; then
    echo "✅ Installer Syntax: PASS"
    ((passed_tests++))
else
    echo "❌ Installer Syntax: FAIL"
fi

echo
echo "📊 Test Results: $passed_tests/$total_tests tests passed"

if [[ $passed_tests -eq $total_tests ]]; then
    echo "🎉 ALL TESTS PASSED - Installers are production ready!"
    exit 0
elif [[ $passed_tests -ge 3 ]]; then
    echo "⚠️  MOSTLY COMPATIBLE - Minor issues need fixing"
    exit 1
else
    echo "❌ COMPATIBILITY ISSUES - Major problems detected"
    exit 2
fi