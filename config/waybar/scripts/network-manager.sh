#!/bin/bash

# Advanced Network Manager
# Provides WiFi management, VPN control, and network monitoring

# Configuration
CONFIG_DIR="$HOME/.config/network-manager"
VPN_DIR="$CONFIG_DIR/vpn"
PROFILES_DIR="$CONFIG_DIR/profiles"

# Create directories
mkdir -p "$VPN_DIR" "$PROFILES_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons
ICON_WIFI_FULL="📶"
ICON_WIFI_GOOD="📶"
ICON_WIFI_WEAK="📶"
ICON_WIFI_OFF="📵"
ICON_ETHERNET="🌐"
ICON_VPN="🔒"
ICON_HOTSPOT="📡"

# Logging
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if NetworkManager is available
check_nm() {
    if ! command -v nmcli &> /dev/null; then
        error "NetworkManager not found. Please install network-manager."
        exit 1
    fi
}

# Get WiFi status
get_wifi_status() {
    nmcli radio wifi
}

# Toggle WiFi
toggle_wifi() {
    local current_status=$(get_wifi_status)
    
    if [ "$current_status" = "enabled" ]; then
        nmcli radio wifi off
        notify-send "WiFi" "Disabled" -i network-wireless-disabled -t 2000
        log "WiFi disabled"
    else
        nmcli radio wifi on
        notify-send "WiFi" "Enabled" -i network-wireless -t 2000
        log "WiFi enabled"
    fi
}

# Scan for WiFi networks
scan_wifi() {
    log "Scanning for WiFi networks..."
    nmcli device wifi rescan
    sleep 2
    nmcli device wifi list
}

# List available WiFi networks
list_wifi() {
    nmcli device wifi list --rescan yes | tail -n +2 | while read -r line; do
        local ssid=$(echo "$line" | awk '{print $2}')
        local signal=$(echo "$line" | awk '{print $7}')
        local security=$(echo "$line" | awk '{print $8}')
        
        if [ "$signal" -gt 70 ]; then
            local icon="$ICON_WIFI_FULL"
        elif [ "$signal" -gt 40 ]; then
            local icon="$ICON_WIFI_GOOD"
        else
            local icon="$ICON_WIFI_WEAK"
        fi
        
        echo "$icon $ssid ($signal%) [$security]"
    done
}

# Connect to WiFi network
connect_wifi() {
    local ssid="$1"
    local password="$2"
    
    if [ -z "$ssid" ]; then
        local networks=$(list_wifi)
        local selection=$(echo "$networks" | rofi -dmenu -p "Select WiFi network")
        
        if [ -z "$selection" ]; then
            return 1
        fi
        
        ssid=$(echo "$selection" | awk '{print $2}')
    fi
    
    if [ -z "$password" ]; then
        # Check if network requires password
        local security=$(nmcli device wifi list | grep "$ssid" | awk '{print $8}')
        
        if [ "$security" != "--" ]; then
            password=$(rofi -dmenu -password -p "Password for $ssid")
            
            if [ -z "$password" ]; then
                return 1
            fi
        fi
    fi
    
    log "Connecting to $ssid..."
    
    if [ -n "$password" ]; then
        nmcli device wifi connect "$ssid" password "$password"
    else
        nmcli device wifi connect "$ssid"
    fi
    
    if [ $? -eq 0 ]; then
        notify-send "WiFi" "Connected to $ssid" -i network-wireless -t 3000
        log "Successfully connected to $ssid"
    else
        notify-send "WiFi" "Failed to connect to $ssid" -i network-error -t 3000
        error "Failed to connect to $ssid"
    fi
}

# Disconnect from current network
disconnect_wifi() {
    local current_connection=$(nmcli connection show --active | grep wifi | awk '{print $1}')
    
    if [ -n "$current_connection" ]; then
        nmcli connection down "$current_connection"
        notify-send "WiFi" "Disconnected from $current_connection" -i network-wireless-disconnected -t 2000
        log "Disconnected from $current_connection"
    else
        warn "No active WiFi connection found"
    fi
}

# Get current connection info
get_connection_info() {
    local active_connections=$(nmcli connection show --active)
    
    if [ -z "$active_connections" ]; then
        echo "No active connections"
        return
    fi
    
    echo "=== Active Connections ==="
    echo "$active_connections"
    echo ""
    
    # Get detailed info for WiFi connection
    local wifi_connection=$(echo "$active_connections" | grep wifi | awk '{print $1}')
    if [ -n "$wifi_connection" ]; then
        echo "=== WiFi Details ==="
        nmcli connection show "$wifi_connection" | grep -E "(connection.id|802-11-wireless.ssid|ipv4.addresses|ipv4.gateway|ipv4.dns)"
    fi
    
    # Get detailed info for ethernet connection
    local eth_connection=$(echo "$active_connections" | grep ethernet | awk '{print $1}')
    if [ -n "$eth_connection" ]; then
        echo "=== Ethernet Details ==="
        nmcli connection show "$eth_connection" | grep -E "(connection.id|ipv4.addresses|ipv4.gateway|ipv4.dns)"
    fi
}

# Show connection status for status bar
get_status() {
    local wifi_status=$(get_wifi_status)
    local active_wifi=$(nmcli connection show --active | grep wifi | awk '{print $1}')
    local active_eth=$(nmcli connection show --active | grep ethernet | awk '{print $1}')
    
    if [ -n "$active_eth" ]; then
        echo "$ICON_ETHERNET Connected"
    elif [ -n "$active_wifi" ] && [ "$wifi_status" = "enabled" ]; then
        local signal=$(nmcli device wifi list | grep "^\*" | awk '{print $7}')
        
        if [ "$signal" -gt 70 ]; then
            echo "$ICON_WIFI_FULL $active_wifi"
        elif [ "$signal" -gt 40 ]; then
            echo "$ICON_WIFI_GOOD $active_wifi"
        else
            echo "$ICON_WIFI_WEAK $active_wifi"
        fi
    elif [ "$wifi_status" = "enabled" ]; then
        echo "$ICON_WIFI_OFF Disconnected"
    else
        echo "$ICON_WIFI_OFF Disabled"
    fi
}

# List saved connections
list_saved_connections() {
    nmcli connection show | grep -E "(wifi|ethernet)" | while read -r line; do
        local name=$(echo "$line" | awk '{print $1}')
        local type=$(echo "$line" | awk '{print $3}')
        local device=$(echo "$line" | awk '{print $4}')
        
        if [ "$type" = "wifi" ]; then
            echo "📶 $name"
        else
            echo "🌐 $name"
        fi
    done
}

# Connect to saved connection
connect_saved() {
    local connections=$(list_saved_connections)
    local selection=$(echo "$connections" | rofi -dmenu -p "Select saved connection")
    
    if [ -n "$selection" ]; then
        local connection_name=$(echo "$selection" | cut -d' ' -f2-)
        nmcli connection up "$connection_name"
        
        if [ $? -eq 0 ]; then
            notify-send "Network" "Connected to $connection_name" -i network-wireless -t 3000
        else
            notify-send "Network" "Failed to connect to $connection_name" -i network-error -t 3000
        fi
    fi
}

# Forget WiFi network
forget_network() {
    local connections=$(nmcli connection show | grep wifi | awk '{print $1}')
    local selection=$(echo "$connections" | rofi -dmenu -p "Forget network")
    
    if [ -n "$selection" ]; then
        local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Forget network '$selection'?")
        
        if [ "$confirm" = "Yes" ]; then
            nmcli connection delete "$selection"
            log "Forgot network: $selection"
        fi
    fi
}

# Create hotspot
create_hotspot() {
    local ssid="$1"
    local password="$2"
    
    if [ -z "$ssid" ]; then
        ssid=$(rofi -dmenu -p "Hotspot name (SSID)")
        [ -z "$ssid" ] && return 1
    fi
    
    if [ -z "$password" ]; then
        password=$(rofi -dmenu -password -p "Hotspot password (min 8 chars)")
        [ -z "$password" ] && return 1
    fi
    
    if [ ${#password} -lt 8 ]; then
        error "Password must be at least 8 characters"
        return 1
    fi
    
    log "Creating hotspot: $ssid"
    
    nmcli device wifi hotspot ifname wlan0 ssid "$ssid" password "$password"
    
    if [ $? -eq 0 ]; then
        notify-send "Hotspot" "Created: $ssid" -i network-wireless-hotspot -t 3000
        log "Hotspot created successfully"
    else
        error "Failed to create hotspot"
    fi
}

# Stop hotspot
stop_hotspot() {
    local hotspot_connection=$(nmcli connection show --active | grep "Hotspot" | awk '{print $1}')
    
    if [ -n "$hotspot_connection" ]; then
        nmcli connection down "$hotspot_connection"
        notify-send "Hotspot" "Stopped" -i network-wireless-disconnected -t 2000
        log "Hotspot stopped"
    else
        warn "No active hotspot found"
    fi
}

# VPN management
list_vpn_connections() {
    nmcli connection show | grep vpn | awk '{print $1}'
}

# Connect to VPN
connect_vpn() {
    local vpn_name="$1"
    
    if [ -z "$vpn_name" ]; then
        local vpn_connections=$(list_vpn_connections)
        
        if [ -z "$vpn_connections" ]; then
            warn "No VPN connections configured"
            return 1
        fi
        
        vpn_name=$(echo "$vpn_connections" | rofi -dmenu -p "Select VPN")
        [ -z "$vpn_name" ] && return 1
    fi
    
    log "Connecting to VPN: $vpn_name"
    nmcli connection up "$vpn_name"
    
    if [ $? -eq 0 ]; then
        notify-send "VPN" "Connected to $vpn_name" -i network-vpn -t 3000
        log "VPN connected successfully"
    else
        error "Failed to connect to VPN"
    fi
}

# Disconnect VPN
disconnect_vpn() {
    local active_vpn=$(nmcli connection show --active | grep vpn | awk '{print $1}')
    
    if [ -n "$active_vpn" ]; then
        nmcli connection down "$active_vpn"
        notify-send "VPN" "Disconnected" -i network-vpn-disconnected -t 2000
        log "VPN disconnected"
    else
        warn "No active VPN connection found"
    fi
}

# Get VPN status
get_vpn_status() {
    local active_vpn=$(nmcli connection show --active | grep vpn | awk '{print $1}')
    
    if [ -n "$active_vpn" ]; then
        echo "$ICON_VPN $active_vpn"
    else
        echo "VPN Disconnected"
    fi
}

# Network speed test
speed_test() {
    if command -v speedtest-cli &> /dev/null; then
        log "Running speed test..."
        speedtest-cli --simple
    elif command -v fast &> /dev/null; then
        log "Running speed test..."
        fast
    else
        warn "No speed test tool found. Install speedtest-cli or fast-cli."
    fi
}

# Network diagnostics
network_diagnostics() {
    local target="${1:-8.8.8.8}"
    
    echo "=== Network Diagnostics ==="
    echo "Target: $target"
    echo ""
    
    echo "=== Ping Test ==="
    ping -c 4 "$target"
    echo ""
    
    echo "=== DNS Resolution ==="
    nslookup google.com
    echo ""
    
    echo "=== Route Information ==="
    ip route show
    echo ""
    
    echo "=== Network Interfaces ==="
    ip addr show
}

# Save network profile
save_network_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        profile_name=$(rofi -dmenu -p "Profile name")
        [ -z "$profile_name" ] && return 1
    fi
    
    local profile_file="$PROFILES_DIR/$profile_name.json"
    
    # Get current network state
    local active_connections=$(nmcli connection show --active | grep -E "(wifi|ethernet)" | awk '{print $1}')
    local wifi_status=$(get_wifi_status)
    
    # Create profile
    local profile_data=$(jq -n \
        --arg name "$profile_name" \
        --arg wifi_status "$wifi_status" \
        --argjson connections "$(echo "$active_connections" | jq -R . | jq -s .)" \
        --arg created "$(date -Iseconds)" \
        '{
            name: $name,
            created: $created,
            wifi_enabled: ($wifi_status == "enabled"),
            connections: $connections
        }')
    
    echo "$profile_data" > "$profile_file"
    log "Network profile saved: $profile_name"
}

# Load network profile
load_network_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        local profiles=$(ls "$PROFILES_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
        profile_name=$(echo "$profiles" | rofi -dmenu -p "Select profile")
        [ -z "$profile_name" ] && return 1
    fi
    
    local profile_file="$PROFILES_DIR/$profile_name.json"
    
    if [ ! -f "$profile_file" ]; then
        error "Profile not found: $profile_name"
        return 1
    fi
    
    log "Loading network profile: $profile_name"
    
    # Read profile data
    local profile_data=$(cat "$profile_file")
    local wifi_enabled=$(echo "$profile_data" | jq -r '.wifi_enabled')
    local connections=$(echo "$profile_data" | jq -r '.connections[]')
    
    # Apply WiFi setting
    local current_wifi=$(get_wifi_status)
    if [ "$wifi_enabled" = "true" ] && [ "$current_wifi" = "disabled" ]; then
        nmcli radio wifi on
    elif [ "$wifi_enabled" = "false" ] && [ "$current_wifi" = "enabled" ]; then
        nmcli radio wifi off
    fi
    
    # Connect to saved connections
    echo "$connections" | while read -r connection; do
        if [ -n "$connection" ] && [ "$connection" != "null" ]; then
            nmcli connection up "$connection" 2>/dev/null
        fi
    done
    
    log "Network profile loaded: $profile_name"
}

# Show WiFi menu
show_wifi_menu() {
    local wifi_options="📶 Scan Networks\n🔗 Connect to Network\n💾 Saved Connections\n🔌 Disconnect\n📋 Toggle WiFi\n🗑️ Forget Network"
    
    local selection=$(echo -e "$wifi_options" | rofi -dmenu -p "WiFi Manager")
    
    case "$selection" in
        "📶 Scan Networks")
            local networks=$(list_wifi)
            local network_selection=$(echo "$networks" | rofi -dmenu -p "Available Networks")
            
            if [ -n "$network_selection" ]; then
                local ssid=$(echo "$network_selection" | awk '{print $2}')
                connect_wifi "$ssid"
            fi
            ;;
        "🔗 Connect to Network")
            connect_wifi
            ;;
        "💾 Saved Connections")
            connect_saved
            ;;
        "🔌 Disconnect")
            disconnect_wifi
            ;;
        "📋 Toggle WiFi")
            toggle_wifi
            ;;
        "🗑️ Forget Network")
            forget_network
            ;;
    esac
}

# Show VPN menu
show_vpn_menu() {
    local vpn_options="🔒 Connect VPN\n🔓 Disconnect VPN\n📋 VPN Status\n➕ Add VPN\n⚙️ VPN Settings"
    
    local selection=$(echo -e "$vpn_options" | rofi -dmenu -p "VPN Manager")
    
    case "$selection" in
        "🔒 Connect VPN")
            connect_vpn
            ;;
        "🔓 Disconnect VPN")
            disconnect_vpn
            ;;
        "📋 VPN Status")
            get_vpn_status | rofi -dmenu -p "VPN Status"
            ;;
        "➕ Add VPN")
            warn "Use nm-connection-editor to add VPN connections"
            nm-connection-editor &
            ;;
        "⚙️ VPN Settings")
            nm-connection-editor &
            ;;
    esac
}

# Show hotspot menu
show_hotspot_menu() {
    local hotspot_options="📡 Create Hotspot\n🛑 Stop Hotspot\n📊 Hotspot Status\n⚙️ Hotspot Settings"
    
    local selection=$(echo -e "$hotspot_options" | rofi -dmenu -p "Hotspot Manager")
    
    case "$selection" in
        "📡 Create Hotspot")
            create_hotspot
            ;;
        "🛑 Stop Hotspot")
            stop_hotspot
            ;;
        "📊 Hotspot Status")
            local hotspot_status=$(nmcli connection show --active | grep "Hotspot" | awk '{print $1}')
            if [ -n "$hotspot_status" ]; then
                echo "Hotspot Active: $hotspot_status" | rofi -dmenu -p "Hotspot Status"
            else
                echo "No active hotspot" | rofi -dmenu -p "Hotspot Status"
            fi
            ;;
        "⚙️ Hotspot Settings")
            nm-connection-editor &
            ;;
    esac
}

# Show diagnostics menu
show_diagnostics_menu() {
    local diag_options="🏃 Speed Test\n🔍 Network Diagnostics\n📊 Connection Info\n📈 Network Monitor\n🔧 Reset Network"
    
    local selection=$(echo -e "$diag_options" | rofi -dmenu -p "Network Diagnostics")
    
    case "$selection" in
        "🏃 Speed Test")
            speed_test | rofi -dmenu -p "Speed Test Results"
            ;;
        "🔍 Network Diagnostics")
            network_diagnostics | rofi -dmenu -p "Network Diagnostics"
            ;;
        "📊 Connection Info")
            get_connection_info | rofi -dmenu -p "Connection Information"
            ;;
        "📈 Network Monitor")
            if command -v iftop &> /dev/null; then
                x-terminal-emulator -e sudo iftop
            elif command -v nethogs &> /dev/null; then
                x-terminal-emulator -e sudo nethogs
            else
                warn "Install iftop or nethogs for network monitoring"
            fi
            ;;
        "🔧 Reset Network")
            local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Reset network settings?")
            if [ "$confirm" = "Yes" ]; then
                sudo systemctl restart NetworkManager
                log "Network service restarted"
            fi
            ;;
    esac
}

# Show profiles menu
show_profiles_menu() {
    local profile_options="💾 Save Profile\n📂 Load Profile\n📋 List Profiles\n🗑️ Delete Profile"
    
    local selection=$(echo -e "$profile_options" | rofi -dmenu -p "Network Profiles")
    
    case "$selection" in
        "💾 Save Profile")
            save_network_profile
            ;;
        "📂 Load Profile")
            load_network_profile
            ;;
        "📋 List Profiles")
            if [ -d "$PROFILES_DIR" ]; then
                ls "$PROFILES_DIR"/*.json 2>/dev/null | while read -r profile_file; do
                    local profile_name=$(basename "$profile_file" .json)
                    local created=$(jq -r '.created' "$profile_file" 2>/dev/null)
                    local date_str=$(date -d "$created" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "Unknown")
                    echo "$profile_name (created: $date_str)"
                done | rofi -dmenu -p "Available Profiles"
            else
                echo "No profiles found" | rofi -dmenu -p "Profiles"
            fi
            ;;
        "🗑️ Delete Profile")
            local profiles=$(ls "$PROFILES_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
            local profile_name=$(echo "$profiles" | rofi -dmenu -p "Delete profile")
            
            if [ -n "$profile_name" ]; then
                local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Delete profile '$profile_name'?")
                
                if [ "$confirm" = "Yes" ]; then
                    rm -f "$PROFILES_DIR/$profile_name.json"
                    log "Profile deleted: $profile_name"
                fi
            fi
            ;;
    esac
}

# Show main menu
show_menu() {
    local menu_options="📶 WiFi Manager\n🔒 VPN Manager\n📡 Hotspot\n🔍 Diagnostics\n💾 Profiles\n📊 Network Status\n⚙️ Settings"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "Network Manager")
    
    case "$selection" in
        "📶 WiFi Manager")
            show_wifi_menu
            ;;
        "🔒 VPN Manager")
            show_vpn_menu
            ;;
        "📡 Hotspot")
            show_hotspot_menu
            ;;
        "🔍 Diagnostics")
            show_diagnostics_menu
            ;;
        "💾 Profiles")
            show_profiles_menu
            ;;
        "📊 Network Status")
            get_connection_info | rofi -dmenu -p "Network Status"
            ;;
        "⚙️ Settings")
            nm-connection-editor &
            ;;
    esac
}

# Main function
main() {
    check_nm
    
    case "${1:-menu}" in
        "menu") show_menu ;;
        "wifi")
            case "$2" in
                "on") nmcli radio wifi on ;;
                "off") nmcli radio wifi off ;;
                "toggle") toggle_wifi ;;
                "scan") scan_wifi ;;
                "list") list_wifi ;;
                "connect") connect_wifi "$3" "$4" ;;
                "disconnect") disconnect_wifi ;;
                "status") get_wifi_status ;;
                *) show_wifi_menu ;;
            esac
            ;;
        "vpn")
            case "$2" in
                "connect") connect_vpn "$3" ;;
                "disconnect") disconnect_vpn ;;
                "list") list_vpn_connections ;;
                "status") get_vpn_status ;;
                *) show_vpn_menu ;;
            esac
            ;;
        "hotspot")
            case "$2" in
                "create") create_hotspot "$3" "$4" ;;
                "stop") stop_hotspot ;;
                *) show_hotspot_menu ;;
            esac
            ;;
        "profile")
            case "$2" in
                "save") save_network_profile "$3" ;;
                "load") load_network_profile "$3" ;;
                *) show_profiles_menu ;;
            esac
            ;;
        "status") get_status ;;
        "info") get_connection_info ;;
        "speed") speed_test ;;
        "diag") network_diagnostics "$2" ;;
        *)
            echo "Usage: $0 {menu|wifi|vpn|hotspot|profile|status|info|speed|diag}"
            echo ""
            echo "WiFi Management:"
            echo "  wifi on               - Enable WiFi"
            echo "  wifi off              - Disable WiFi"
            echo "  wifi toggle           - Toggle WiFi"
            echo "  wifi scan             - Scan for networks"
            echo "  wifi list             - List available networks"
            echo "  wifi connect [ssid] [pass] - Connect to network"
            echo "  wifi disconnect       - Disconnect from current network"
            echo "  wifi status           - Get WiFi status"
            echo "  wifi                  - WiFi management menu"
            echo ""
            echo "VPN Management:"
            echo "  vpn connect [name]    - Connect to VPN"
            echo "  vpn disconnect        - Disconnect VPN"
            echo "  vpn list              - List VPN connections"
            echo "  vpn status            - Get VPN status"
            echo "  vpn                   - VPN management menu"
            echo ""
            echo "Hotspot Management:"
            echo "  hotspot create [ssid] [pass] - Create hotspot"
            echo "  hotspot stop          - Stop hotspot"
            echo "  hotspot               - Hotspot management menu"
            echo ""
            echo "Profile Management:"
            echo "  profile save [name]   - Save network profile"
            echo "  profile load [name]   - Load network profile"
            echo "  profile               - Profile management menu"
            echo ""
            echo "Utilities:"
            echo "  status                - Get connection status for status bar"
            echo "  info                  - Show connection information"
            echo "  speed                 - Run speed test"
            echo "  diag [target]         - Network diagnostics"
            echo "  menu                  - Show interactive menu"
            exit 1
            ;;
    esac
}

main "$@"
