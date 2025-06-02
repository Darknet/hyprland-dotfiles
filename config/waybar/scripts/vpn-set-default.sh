#!/bin/bash
# Configurar VPN por defecto para toggle rápido

echo "🔧 Configurar VPN por defecto"
echo "=============================="

# Mostrar VPNs disponibles
echo "VPNs disponibles:"
echo

# NetworkManager
echo "📡 NetworkManager:"
nmcli connection show | grep vpn | while read -r line; do
    name=$(echo "$line" | awk '{print $1}')
    echo "  - $name"
done

# WireGuard
echo
echo "⚡ WireGuard:"
if [ -d "/etc/wireguard" ]; then
    for config in /etc/wireguard/*.conf; do
        if [ -f "$config" ]; then
            name=$(basename "$config" .conf)
            echo "  - $name"
        fi
    done
fi

# OpenVPN
echo
echo "🔐 OpenVPN:"
if [ -d "$HOME/.config/openvpn" ]; then
    for config in "$HOME/.config/openvpn"/*.ovpn; do
        if [ -f "$config" ]; then
            name=$(basename "$config" .ovpn)
            echo "  - $name"
        fi
    done
fi

echo
read -p "Tipo de VPN (nm/wg/ovpn): " vpn_type
read -p "Nombre de la configuración: " vpn_name

# Guardar configuración por defecto
echo "$vpn_type|$vpn_name" > "$HOME/.config/vpn-default"

echo "✅ VPN por defecto configurada: $vpn_name ($vpn_type)"
echo "Ahora puedes usar Super+Shift+V para conectar/desconectar rápidamente"
