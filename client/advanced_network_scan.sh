#!/bin/bash
# Advanced Client Network Scanner & Remote Access Helper
# Scans clients, checks ports, suggests access methods

# Client IPs
CLIENT_IPS=(
    "192.168.1.26" "192.168.1.21" "192.168.1.25" "192.168.1.2"
    "192.168.100.165" "192.168.100.216" "192.168.100.178"
    "192.168.1.29" "192.168.1.8" "192.168.1.27" "192.168.1.22"
    "192.168.100.158" "192.168.100.159" "192.168.1.38"
    "192.168.1.30" "192.168.1.32" "192.168.1.18"
)

echo "========================================"
echo "🔍 TENJO CLIENT NETWORK SCANNER"
echo "========================================"
echo ""
echo "Scanning ${#CLIENT_IPS[@]} clients..."
echo ""

# Check if we have necessary tools
check_tools() {
    local missing=0
    
    if ! command -v nmap &> /dev/null; then
        echo "⚠️  nmap not installed (optional, for deep scan)"
        echo "   Install: brew install nmap"
        missing=1
    fi
    
    if ! command -v nc &> /dev/null; then
        echo "⚠️  netcat not installed (optional, for port check)"
        missing=1
    fi
    
    if [ $missing -eq 0 ]; then
        echo "✅ All tools available"
    fi
    echo ""
}

# Ping scan
ping_scan() {
    local ip=$1
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Port scan using bash built-in
port_scan() {
    local ip=$1
    local port=$2
    local timeout=1
    
    if command -v nc &> /dev/null; then
        nc -z -w "$timeout" "$ip" "$port" 2>/dev/null
        return $?
    else
        # Fallback using bash
        timeout 1 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null
        return $?
    fi
}

# Scan common remote access ports
scan_remote_ports() {
    local ip=$1
    local results=""
    
    # RDP (3389)
    if port_scan "$ip" 3389; then
        results="${results}RDP:✅ "
    fi
    
    # SSH (22)
    if port_scan "$ip" 22; then
        results="${results}SSH:✅ "
    fi
    
    # VNC (5900)
    if port_scan "$ip" 5900; then
        results="${results}VNC:✅ "
    fi
    
    # TeamViewer (5938)
    if port_scan "$ip" 5938; then
        results="${results}TV:✅ "
    fi
    
    # WinRM (5985 - HTTP, 5986 - HTTPS)
    if port_scan "$ip" 5985 || port_scan "$ip" 5986; then
        results="${results}WinRM:✅ "
    fi
    
    # SMB (445)
    if port_scan "$ip" 445; then
        results="${results}SMB:✅ "
    fi
    
    echo "$results"
}

check_tools

ONLINE=()
OFFLINE=()
RDP_AVAILABLE=()
SSH_AVAILABLE=()
SMB_AVAILABLE=()
WINRM_AVAILABLE=()

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-16s %-8s %-40s\n" "IP ADDRESS" "STATUS" "REMOTE ACCESS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for ip in "${CLIENT_IPS[@]}"; do
    printf "%-16s " "$ip"
    
    if ping_scan "$ip"; then
        printf "%-8s " "🟢 ON"
        ONLINE+=("$ip")
        
        # Scan ports
        ports=$(scan_remote_ports "$ip")
        printf "%-40s\n" "$ports"
        
        # Categorize by access method
        if [[ $ports == *"RDP:✅"* ]]; then
            RDP_AVAILABLE+=("$ip")
        fi
        if [[ $ports == *"SSH:✅"* ]]; then
            SSH_AVAILABLE+=("$ip")
        fi
        if [[ $ports == *"SMB:✅"* ]]; then
            SMB_AVAILABLE+=("$ip")
        fi
        if [[ $ports == *"WinRM:✅"* ]]; then
            WINRM_AVAILABLE+=("$ip")
        fi
    else
        printf "%-8s %-40s\n" "❌ OFF" "N/A"
        OFFLINE+=("$ip")
    fi
    
    sleep 0.1
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "========================================"
echo "📊 SCAN RESULTS"
echo "========================================"
echo "🟢 Online:  ${#ONLINE[@]} clients"
echo "❌ Offline: ${#OFFLINE[@]} clients"
echo ""
echo "🔓 Remote Access Available:"
echo "   RDP:   ${#RDP_AVAILABLE[@]} clients"
echo "   SSH:   ${#SSH_AVAILABLE[@]} clients"
echo "   SMB:   ${#SMB_AVAILABLE[@]} clients"
echo "   WinRM: ${#WINRM_AVAILABLE[@]} clients"
echo ""

# Generate access methods
if [ ${#RDP_AVAILABLE[@]} -gt 0 ]; then
    echo "========================================"
    echo "🖥️  RDP ACCESS AVAILABLE (${#RDP_AVAILABLE[@]} clients)"
    echo "========================================"
    echo ""
    echo "Use Remote Desktop to connect:"
    echo ""
    for ip in "${RDP_AVAILABLE[@]}"; do
        echo "  open rdp://$ip"
        echo "  or: Microsoft Remote Desktop → Add PC → $ip"
        echo ""
    done
fi

if [ ${#SMB_AVAILABLE[@]} -gt 0 ]; then
    echo "========================================"
    echo "📁 SMB/FILE SHARING AVAILABLE (${#SMB_AVAILABLE[@]} clients)"
    echo "========================================"
    echo ""
    echo "💡 YOU CAN UPDATE VIA SMB!"
    echo ""
    echo "Access network share from macOS:"
    echo ""
    for ip in "${SMB_AVAILABLE[@]}"; do
        echo "  smb://$ip/C$/ProgramData/Tenjo"
        echo "  Finder → Go → Connect to Server → smb://$ip"
        echo ""
    done
fi

if [ ${#WINRM_AVAILABLE[@]} -gt 0 ]; then
    echo "========================================"
    echo "⚡ WINRM ACCESS AVAILABLE (${#WINRM_AVAILABLE[@]} clients)"
    echo "========================================"
    echo ""
    echo "Remote PowerShell execution possible!"
    echo "Install pywinrm: pip3 install pywinrm"
    echo ""
fi

# Save results
RESULTS_FILE="$HOME/Desktop/tenjo_scan_results.txt"
{
    echo "TENJO CLIENT SCAN RESULTS"
    echo "Date: $(date)"
    echo "========================================"
    echo ""
    echo "ONLINE CLIENTS (${#ONLINE[@]}):"
    for ip in "${ONLINE[@]}"; do
        echo "  $ip"
    done
    echo ""
    echo "OFFLINE CLIENTS (${#OFFLINE[@]}):"
    for ip in "${OFFLINE[@]}"; do
        echo "  $ip"
    done
    echo ""
    echo "RDP ACCESS (${#RDP_AVAILABLE[@]}):"
    for ip in "${RDP_AVAILABLE[@]}"; do
        echo "  $ip"
    done
    echo ""
    echo "SMB ACCESS (${#SMB_AVAILABLE[@]}):"
    for ip in "${SMB_AVAILABLE[@]}"; do
        echo "  $ip"
    done
    echo ""
    echo "WinRM ACCESS (${#WINRM_AVAILABLE[@]}):"
    for ip in "${WINRM_AVAILABLE[@]}"; do
        echo "  $ip"
    done
} > "$RESULTS_FILE"

echo "========================================"
echo "📁 Results saved to: $RESULTS_FILE"
echo "========================================"
echo ""

# Next steps
echo "========================================"
echo "⏭️  NEXT STEPS"
echo "========================================"
echo ""

if [ ${#ONLINE[@]} -eq 0 ]; then
    echo "❌ No clients online on this network"
    echo ""
    echo "Possible reasons:"
    echo "  1. Mac not on same network as client PCs"
    echo "  2. Clients turned off (outside work hours?)"
    echo "  3. Firewall blocking from Mac"
    echo "  4. Different subnet/VLAN"
    echo ""
    echo "Solutions:"
    echo "  1. Connect Mac to office network via Ethernet"
    echo "  2. Use USB updater method (most reliable)"
    echo "  3. Wait until tomorrow morning at office"
else
    echo "✅ Found ${#ONLINE[@]} online clients!"
    echo ""
    
    if [ ${#SMB_AVAILABLE[@]} -gt 0 ]; then
        echo "🚀 RECOMMENDED: SMB Network Update"
        echo ""
        echo "From your Mac, you can directly copy files via network:"
        echo ""
        echo "1. Connect to SMB share:"
        echo "   Finder → Go → Connect to Server"
        echo "   Enter: smb://192.168.1.2/C$"
        echo "   Username: Administrator"
        echo "   Password: (ask IT or use cached credentials)"
        echo ""
        echo "2. Navigate to: C$ → ProgramData → Tenjo"
        echo ""
        echo "3. Copy update_server_config.py to that folder"
        echo ""
        echo "4. Connect via RDP to execute, or schedule via WinRM"
        echo ""
    elif [ ${#RDP_AVAILABLE[@]} -gt 0 ]; then
        echo "🚀 RECOMMENDED: RDP Manual Update"
        echo ""
        echo "1. Download Microsoft Remote Desktop from Mac App Store"
        echo "2. Connect to each IP"
        echo "3. Run update command in PowerShell"
        echo ""
    else
        echo "⚠️  No remote access available"
        echo ""
        echo "Use USB updater method instead"
    fi
fi

echo ""
echo "========================================"
