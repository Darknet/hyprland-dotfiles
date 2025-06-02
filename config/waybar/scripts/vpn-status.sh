#!/bin/bash
# VPN Status Script para Waybar

# Función para detectar VPN activa
detect_vpn() {
    local vpn_info=""
    local vpn_type=""
    local vpn_name=""
    local vpn_ip=""
    
    # Detectar OpenVPN
    if pgrep -x openvpn >/dev/null 2>&1; then
        vpn_type="OpenVPN"
        vpn_name=$(ps aux | grep openvpn | grep -v grep | awk '{for(i=1;i<=NF;i++) if($i ~ /\.ovpn$/) print $i}' | xargs basename 2>/dev/null | sed 's/\.ovpn$//')
        vpn_ip=$(ip route | grep tun | awk '/default/ {print $3}' | head -1)
    fi
    
    # Detectar WireGuard
    if command -v wg >/dev/null 2>&1 && [ -n "$(wg show 2>/dev/null)" ]; then
        vpn_type="WireGuard"
        vpn_name=$(wg show | grep interface | awk '{print $2}' | head -1)
        if [ -z "$vpn_name" ]; then
            vpn_name=$(ip link show type wireguard | grep -o 'wg[0-9]*' | head -1)
        fi
        vpn_ip=$(wg show | grep endpoint | awk '{print $2}' | cut -d: -f1 | head -1)
    fi
    
    # Detectar NetworkManager VPN
    local nm_vpn=$(nmcli connection show --active | grep vpn | head -1)
    if [ -n "$nm_vpn" ]; then
        vpn_type="NetworkManager"
        vpn_name=$(echo "$nm_vpn" | awk '{print $1}')
        vpn_ip=$(nmcli connection show "$vpn_name" | grep IP4.ADDRESS | awk '{print $2}' | cut -d/ -f1)
    fi
    
    # Detectar por interfaces de red VPN comunes
    if [ -z "$vpn_type" ]; then
        for interface in tun0 wg0 vpn0 ppp0; do
            if ip link show "$interface" >/dev/null 2>&1; then
                vpn_type="Generic"
                vpn_name="$interface"
                vpn_ip=$(ip addr show "$interface" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
                break
            fi
        done
    fi
    
    # Detectar ProtonVPN
    if pgrep -f protonvpn >/dev/null 2>&1; then
        vpn_type="ProtonVPN"
        vpn_name="ProtonVPN"
        vpn_ip=$(protonvpn status 2>/dev/null | grep "IP:" | awk '{print $2}')
    fi
    
    # Detectar NordVPN
    if command -v nordvpn >/dev/null 2>&1; then
        local nord_status=$(nordvpn status 2>/dev/null)
        if echo "$nord_status" | grep -q "Connected"; then
            vpn_type="NordVPN"
            vpn_name=$(echo "$nord_status" | grep "Current server:" | cut -d: -f2 | xargs)
            vpn_ip=$(echo "$nord_status" | grep "Your new IP:" | cut -d: -f2 | xargs)
        fi
    fi
    
    # Detectar ExpressVPN
    if command -v expressvpn >/dev/null 2>&1; then
        local express_status=$(expressvpn status 2>/dev/null)
        if echo "$express_status" | grep -q "Connected"; then
            vpn_type="ExpressVPN"
            vpn_name=$(echo "$express_status" | grep "Connected to" | cut -d: -f2 | xargs)
        fi
    fi
    
    # Retornar información
    if [ -n "$vpn_type" ]; then
        echo "connected|$vpn_type|$vpn_name|$vpn_ip"
    else
        echo "disconnected|||"
    fi
}

# Función para obtener información de geolocalización
get_location_info() {
    local ip="$1"
    if [ -n "$ip" ]; then
        # Usar servicio de geolocalización (con timeout)
        local location=$(timeout 3 curl -s "http://ip-api.com/json/$ip" 2>/dev/null | jq -r '.country, .city' 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
        echo "$location"
    fi
}

# Función principal
main() {
    local format="$1"
    local vpn_status=$(detect_vpn)
    
    IFS='|' read -r status type name ip <<< "$vpn_status"
    
    case "$format" in
        "waybar")
            if [ "$status" = "connected" ]; then
                local tooltip="VPN: $type"
                if [ -n "$name" ] && [ "$name" != "$type" ]; then
                    tooltip="$tooltip\nServidor: $name"
                fi
                if [ -n "$ip" ]; then
                    tooltip="$tooltip\nIP: $ip"
                    # Obtener ubicación si es posible
                    local location=$(get_location_info "$ip")
                    if [ -n "$location" ]; then
                        tooltip="$tooltip\nUbicación: $location"
                    fi
                fi
                
                # JSON para Waybar
                echo "{\"text\":\"🔒 VPN\",\"tooltip\":\"$tooltip\",\"class\":\"connected\",\"percentage\":100}"
            else
                echo "{\"text\":\"🔓\",\"tooltip\":\"VPN Desconectada\",\"class\":\"disconnected\",\"percentage\":0}"
            fi
            ;;
        "simple")
            if [ "$status" = "connected" ]; then
                echo "🔒 $type"
            else
                echo "🔓 No VPN"
            fi
            ;;
        "detailed")
            if [ "$status" = "connected" ]; then
                echo "🔒 VPN: $type ($name) - $ip"
            else
                echo "🔓 Sin conexión VPN"
            fi
            ;;
        *)
            echo "$vpn_status"
            ;;
    esac
}

# Ejecutar función principal
main "$@"
