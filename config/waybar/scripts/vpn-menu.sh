#!/bin/bash
# VPN Menu usando Rofi

# Función para obtener conexiones VPN disponibles
get_vpn_connections() {
    local connections=""
    
    # NetworkManager VPN connections
    local nm_vpns=$(nmcli connection show | grep vpn | awk '{print $1}')
    if [ -n "$nm_vpns" ]; then
        while read -r vpn; do
            if nmcli connection show --active | grep -q "$vpn"; then
                connections="$connections🔗 $vpn (NetworkManager - Conectado)\n"
            else
                connections="$connections📡 $vpn (NetworkManager)\n"
            fi
        done <<< "$nm_vpns"
    fi
    
    # OpenVPN configs
    local ovpn_dir="$HOME/.config/openvpn"
    if [ -d "$ovpn_dir" ]; then
        for config in "$ovpn_dir"/*.ovpn; do
            if [ -f "$config" ]; then
                local name=$(basename "$config" .ovpn)
                connections="$connections🔐 $name (OpenVPN)\n"
            fi
        done
    fi
    
    # WireGuard configs
    local wg_dir="/etc/wireguard"
    if [ -d "$wg_dir" ]; then
        for config in "$wg_dir"/*.conf; do
            if [ -f "$config" ]; then
                local name=$(basename "$config" .conf)
                if wg show "$name" >/dev/null 2>&1; then
                    connections="$connections🔗 $name (WireGuard - Conectado)\n"
                else
                    connections="$connections⚡ $name (WireGuard)\n"
                fi
            fi
        done
    fi
    
    # Servicios VPN comerciales
    if command -v nordvpn >/dev/null 2>&1; then
        if nordvpn status | grep -q "Connected"; then
            connections="$connections🔗 NordVPN (Conectado)\n"
        else
            connections="$connections🛡️ NordVPN\n"
        fi
    fi
    
    if command -v protonvpn >/dev/null 2>&1; then
        if protonvpn status | grep -q "Connected"; then
            connections="$connections🔗 ProtonVPN (Conectado)\n"
        else
            connections="$connections🛡️ ProtonVPN\n"
        fi
    fi
    
    echo -e "$connections"
}

# Función para conectar/desconectar VPN
manage_vpn() {
    local selection="$1"
    local name=$(echo "$selection" | sed 's/^[🔗📡🔐⚡🛡️] //' | sed 's/ (.*)$//')
    local type=$(echo "$selection" | grep -o '([^)]*)')
    
    if echo "$selection" | grep -q "Conectado"; then
        # Desconectar
        case "$type" in
            *"NetworkManager"*)
                nmcli connection down "$name"
                ;;
            *"WireGuard"*)
                sudo wg-quick down "$name"
                ;;
            *"NordVPN"*)
                nordvpn disconnect
                ;;
            *"ProtonVPN"*)
                protonvpn disconnect
                ;;
        esac
        notify-send "VPN" "Desconectado de $name"
    else
        # Conectar
        case "$type" in
            *"NetworkManager"*)
                nmcli connection up "$name"
                ;;
            *"OpenVPN"*)
                sudo openvpn --config "$HOME/.config/openvpn/$name.ovpn" --daemon
                ;;
            *"WireGuard"*)
                sudo wg-quick up "$name"
                ;;
            *"NordVPN"*)
                # Menú de países para NordVPN
                country=$(echo -e "United States\nUnited Kingdom\nGermany\nJapan\nCanada\nAustralia" | rofi -dmenu -p "Seleccionar país")
                if [ -n "$country" ]; then
                    nordvpn connect "$country"
                fi
                ;;
            *"ProtonVPN"*)
                # Menú básico para ProtonVPN
                server=$(echo -e "Fastest\nSecure Core\nP2P\nTor" | rofi -dmenu -p "Tipo de servidor")
                case "$server" in
                    "Fastest") protonvpn connect --fastest ;;
                    "Secure Core") protonvpn connect --sc ;;
                    "P2P") protonvpn connect --p2p ;;
                    "Tor") protonvpn connect --tor ;;
                esac
                ;;
        esac
        notify-send "VPN" "Conectando a $name..."
    fi
}

# Menú principal
main_menu() {
    local options="🔍 Ver Estado Actual\n"
    options="$options🔄 Actualizar Lista\n"
    options="$options➕ Agregar Configuración\n"
    options="$options⚙️ Configuración VPN\n"
    options="$options📊 Estadísticas de Conexión\n"
    options="$options🚫 Desconectar Todo\n"
    options="$options$(get_vpn_connections)"
    
    echo -e
