#!/bin/bash

# VPN Manager Script for Hyprland
# Manages OpenVPN and WireGuard connections

VPN_DIR="/etc/NetworkManager/system-connections"
CONFIG_DIR="$HOME/.config/vpn"
ROFI_THEME="$HOME/.config/rofi/themes/vpn-menu.rasi"

# Colors
RED="#ff5555"
GREEN="#50fa7b"
YELLOW="#f1fa8c"
BLUE="#8be9fd"

# Create config directory
mkdir -p "$CONFIG_DIR"

# Get available VPN connections
get_vpn_connections() {
    nmcli connection show | grep -E "(vpn|wireguard)" | awk '{print $1}' | sort
}

# Get active VPN connection
get_active_vpn() {
    nmcli connection show --active | grep -E "(vpn|wireguard)" | awk '{print $1}' | head -1
}

# Check VPN status
check_vpn_status() {
    local active_vpn=$(get_active_vpn)
    if [ -n "$active_vpn" ]; then
        echo "Connected to: $active_vpn"
        return 0
    else
        echo "Not connected"
        return 1
    fi
}

# Connect to VPN
connect_vpn() {
    local vpn_name="$1"
    
    if [ -z "$vpn_name" ]; then
        echo "Error: VPN name required"
        return 1
    fi
    
    echo "Connecting to $vpn_name..."
    
    if nmcli connection up "$vpn_name"; then
        notify-send "VPN Connected" "Successfully connected to $vpn_name" -t 3000 -u normal
        echo "Successfully connected to $vpn_name"
        
        # Save as default VPN
        echo "$vpn_name" > "$CONFIG_DIR/default_vpn"
        return 0
    else
        notify-send "VPN Error" "Failed to connect to $vpn_name" -t 5000 -u critical
        echo "Failed to connect to $vpn_name"
        return 1
    fi
}

# Disconnect VPN
disconnect_vpn() {
    local active_vpn=$(get_active_vpn)
    
    if [ -n "$active_vpn" ]; then
        echo "Disconnecting from $active_vpn..."
        
        if nmcli connection down "$active_vpn"; then
            notify-send "VPN Disconnected" "Disconnected from $active_vpn" -t 3000 -u normal
            echo "Successfully disconnected from $active_vpn"
            return 0
        else
            notify-send "VPN Error" "Failed to disconnect from $active_vpn" -t 5000 -u critical
            echo "Failed to disconnect from $active_vpn"
            return 1
        fi
    else
        echo "No active VPN connection"
        return 1
    fi
}

# Toggle VPN (connect to default or disconnect)
toggle_vpn() {
    local active_vpn=$(get_active_vpn)
    
    if [ -n "$active_vpn" ]; then
        disconnect_vpn
    else
        local default_vpn=""
        if [ -f "$CONFIG_DIR/default_vpn" ]; then
            default_vpn=$(cat "$CONFIG_DIR/default_vpn")
        fi
        
        if [ -n "$default_vpn" ]; then
            connect_vpn "$default_vpn"
        else
            echo "No default VPN set. Use 'set-default' command first."
            return 1
        fi
    fi
}

# Set default VPN
set_default_vpn() {
    local vpn_name="$1"
    
    if [ -z "$vpn_name" ]; then
        # Show menu to select VPN
        local vpns=$(get_vpn_connections)
        if [ -z "$vpns" ]; then
            echo "No VPN connections found"
            return 1
        fi
        
        echo "Available VPN connections:"
        echo "$vpns" | nl
        read -p "Select VPN number: " selection
        
        vpn_name=$(echo "$vpns" | sed -n "${selection}p")
    fi
    
    if [ -n "$vpn_name" ]; then
        echo "$vpn_name" > "$CONFIG_DIR/default_vpn"
        echo "Default VPN set to: $vpn_name"
        notify-send "VPN Manager" "Default VPN set to $vpn_name" -t 3000
    else
        echo "Invalid VPN name"
        return 1
    fi
}

# Show VPN menu using rofi
show_vpn_menu() {
    local vpns=$(get_vpn_connections)
    local active_vpn=$(get_active_vpn)
    
    if [ -z "$vpns" ]; then
        notify-send "VPN Manager" "No VPN connections configured" -t 3000 -u normal
        return 1
    fi
    
    # Create menu options
    local menu_options=""
    if [ -n "$active_vpn" ]; then
        menu_options="🔴 Disconnect ($active_vpn)\n"
    fi
    
    while IFS= read -r vpn; do
        if [ "$vpn" = "$active_vpn" ]; then
            menu_options="${menu_options}✅ $vpn (connected)\n"
        else
            menu_options="${menu_options}🔵 $vpn\n"
        fi
    done <<< "$vpns"
    
    menu_options="${menu_options}⚙️ Settings\n📊 Status"
    
    # Show rofi menu
    local selection
    if [ -f "$ROFI_THEME" ]; then
        selection=$(echo -e "$menu_options" | rofi -dmenu -p "VPN Manager" -theme "$ROFI_THEME")
    else
        selection=$(echo -e "$menu_options" | rofi -dmenu -p "VPN Manager")
    fi
    
    # Process selection
    case "$selection" in
        "🔴 Disconnect"*)
            disconnect_vpn
            ;;
        "✅ "*" (connected)")
            # Already connected, show status
            check_vpn_status
            ;;
        "🔵 "*)
            local vpn_name=$(echo "$selection" | sed 's/🔵 //')
            connect_vpn "$vpn_name"
            ;;
        "⚙️ Settings")
            show_settings_menu
            ;;
        "📊 Status")
            show_status_notification
            ;;
    esac
}

# Show settings menu
show_settings_menu() {
    local settings_options="Set Default VPN\nImport OpenVPN Config\nImport WireGuard Config\nView Logs"
    
    local selection
    if [ -f "$ROFI_THEME" ]; then
        selection=$(echo -e "$settings_options" | rofi -dmenu -p "VPN Settings" -theme "$ROFI_THEME")
    else
        selection=$(echo -e "$settings_options" | rofi -dmenu -p "VPN Settings")
    fi
    
    case "$selection" in
        "Set Default VPN")
            set_default_vpn
            ;;
        "Import OpenVPN Config")
            import_openvpn_config
            ;;
        "Import WireGuard Config")
            import_wireguard_config
            ;;
        "View Logs")
            view_vpn_logs
            ;;
    esac
}

# Show status notification
show_status_notification() {
    local status=$(check_vpn_status)
    local ip_info=""
    
    if command -v curl &> /dev/null; then
        ip_info=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to get IP")
    fi
    
    notify-send "VPN Status" "$status\nPublic IP: $ip_info" -t 5000
}

# Import OpenVPN config
import_openvpn_config() {
    local config_file=$(zenity --file-selection --title="Select OpenVPN config file" --file-filter="*.ovpn" 2>/dev/null)
    
    if [ -n "$config_file" ] && [ -f "$config_file" ]; then
        local connection_name=$(basename "$config_file" .ovpn)
        
        if nmcli connection import type openvpn file "$config_file"; then
            notify-send "VPN Manager" "OpenVPN config imported: $connection_name" -t 3000
        else
            notify-send "VPN Manager" "Failed to import OpenVPN config" -t 3000 -u critical
        fi
    fi
}

# Import WireGuard config
import_wireguard_config() {
    local config_file=$(zenity --file-selection --title="Select WireGuard config file" --file-filter="*.conf" 2>/dev/null)
    
    if [ -n "$config_file" ] && [ -f "$config_file" ]; then
        local connection_name=$(basename "$config_file" .conf)
        
        if nmcli connection import type wireguard file "$config_file"; then
            notify-send "VPN Manager" "WireGuard config imported: $connection_name" -t 3000
        else
            notify-send "VPN Manager" "Failed to import WireGuard config" -t 3000 -u critical
        fi
    fi
}

# View VPN logs
view_vpn_logs() {
    kitty -e journalctl -u NetworkManager -f &
}

# Get VPN status for waybar
get_vpn_status_json() {
    local active_vpn=$(get_active_vpn)
    
    if [ -n "$active_vpn" ]; then
        echo "{\"text\": \"🔒 $active_vpn\", \"class\": \"connected\", \"tooltip\": \"Connected to $active_vpn\"}"
    else
        echo "{\"text\": \"🔓\", \"class\": \"disconnected\", \"tooltip\": \"Not connected to VPN\"}"
    fi
}

# Main function
case "${1:-menu}" in
    "menu")
        show_vpn_menu
        ;;
    "connect")
        connect_vpn "$2"
        ;;
    "disconnect")
        disconnect_vpn
        ;;
    "toggle")
        toggle_vpn
        ;;
    "status")
        check_vpn_status
        ;;
    "status-json")
        get_vpn_status_json
        ;;
    "set-default")
        set_default_vpn "$2"
        ;;
    "list")
        echo "Available VPN connections:"
        get_vpn_connections
        ;;
    "logs")
        view_vpn_logs
        ;;
    *)
        echo "Usage: $0 {menu|connect|disconnect|toggle|status|status-json|set-default|list|logs}"
        echo ""
        echo "Commands:"
        echo "  menu         - Show interactive VPN menu"
        echo "  connect NAME - Connect to specific VPN"
        echo "  disconnect   - Disconnect current VPN"
        echo "  toggle       - Toggle default VPN connection"
        echo "  status       - Show current VPN status"
        echo "  status-json  - Get status in JSON format (for waybar)"
        echo "  set-default  - Set default VPN connection"
        echo "  list         - List available VPN connections"
        echo "  logs         - View VPN logs"
        exit 1
        ;;
esac
