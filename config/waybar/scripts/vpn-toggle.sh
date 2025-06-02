#!/bin/bash
# Toggle rápido de VPN

# Detectar si hay VPN activa
vpn_status=$(~/.config/waybar/scripts/vpn-status.sh)
IFS='|' read -r status type name ip <<< "$vpn_status"

if [ "$status" = "connected" ]; then
    # Desconectar VPN activa
    case "$type" in
        "NetworkManager")
            nmcli connection down "$name"
            ;;
        "WireGuard")
            sudo wg-quick down "$name"
            ;;
        "OpenVPN")
            sudo pkill openvpn
            ;;
        "NordVPN")
            nordvpn disconnect
            ;;
        "ProtonVPN")
            protonvpn disconnect
            ;;
        *)
            # Intentar desconectar por interfaz
            if [ -n "$name" ]; then
                sudo ip link set "$name" down 2>/dev/null
            fi
            ;;
    esac
    notify-send "VPN" "VPN desconectada"
else
    # Conectar a VPN por defecto o mostrar menú rápido
    default_vpn=$(cat "$HOME/.config/vpn-default" 2>/dev/null)
    
    if [ -n "$default_vpn" ]; then
        # Conectar a VPN por defecto
        IFS='|' read -r def_type def_name <<< "$default_vpn"
        case "$def_type" in
            "nm")
                nmcli connection up "$def_name"
                ;;
            "wg")
                sudo wg-quick up "$def_name"
                ;;
            "ovpn")
                sudo openvpn --config "$HOME/.config/openvpn/$def_name.ovpn" --daemon
                ;;
        esac
        notify-send "VPN" "Conectando a $def_name..."
    else
        # Mostrar menú rápido de VPNs favoritas
        quick_options=""
        
        # Agregar VPNs de NetworkManager
        nm_vpns=$(nmcli connection show | grep vpn | head -3 | awk '{print "nm|" $1}')
        if [ -n "$nm_vpns" ]; then
            while read -r vpn; do
                name=$(echo "$vpn" | cut -d'|' -f2)
                quick_options="$quick_options📡 $name\n"
            done <<< "$nm_vpns"
        fi
        
        # Agregar opción para abrir menú completo
        quick_options="$quick_options⚙️ Más opciones..."
        
        choice=$(echo -e "$quick_options" | rofi -dmenu -i -p "Conectar VPN" -theme-str 'window {width: 300px;}')
        
        if [ "$choice" = "⚙️ Más opciones..." ]; then
            ~/.local/bin/vpn-menu.sh
        elif [ -n "$choice" ]; then
            vpn_name=$(echo "$choice" | sed 's/^📡 //')
            nmcli connection up "$vpn_name"
            notify-send "VPN" "Conectando a $vpn_name..."
        fi
    fi
fi

# Actualizar waybar
pkill -RTMIN+8 waybar
