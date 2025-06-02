function vpn
    switch $argv[1]
        case "status"
            ~/.config/waybar/scripts/vpn-status.sh
        case "list"
            nmcli connection show | grep vpn
        case "connect"
            if test (count $argv) -ge 2
                ~/.config/waybar/scripts/vpn-toggle.sh connect $argv[2]
            else
                echo "Uso: vpn connect <nombre_vpn>"
            end
        case "disconnect"
            ~/.config/waybar/scripts/vpn-toggle.sh disconnect
        case "toggle"
            ~/.config/waybar/scripts/vpn-toggle.sh toggle
        case "menu"
            ~/.config/waybar/scripts/vpn-menu.sh
        case "*"
            echo "VPN Manager"
            echo "==========="
            echo "vpn status     - Mostrar estado actual"
            echo "vpn list       - Listar conexiones VPN"
            echo "vpn connect    - Conectar a VPN específica"
            echo "vpn disconnect - Desconectar VPN"
            echo "vpn toggle     - Alternar conexión VPN"
            echo "vpn menu       - Mostrar menú VPN"
    end
end
