#!/bin/bash
# WiFi menu usando Rofi y NetworkManager

# Verificar si NetworkManager está corriendo
if ! systemctl is-active --quiet NetworkManager; then
    notify-send "Error" "NetworkManager no está corriendo"
    exit 1
fi

# Función para mostrar redes WiFi
show_networks() {
    # Escanear redes
    nmcli device wifi rescan 2>/dev/null
    sleep 2
    
    # Obtener lista de redes
    networks=$(nmcli -t -f SSID,SECURITY,SIGNAL device wifi list | sort -t: -k3 -nr)
    
    if [ -z "$networks" ]; then
        notify-send "WiFi" "No se encontraron redes"
        exit 1
    fi
    
    # Formatear para Rofi
    formatted=""
    while IFS=: read -r ssid security signal; do
        if [ -n "$ssid" ]; then
            # Icono según seguridad
            if [ "$security" = "--" ]; then
                icon="🔓"
            else
                icon="🔒"
            fi
            
            # Barra de señal
            if [ "$signal" -gt 75 ]; then
                signal_icon="📶"
            elif [ "$signal" -gt 50 ]; then
                signal_icon="📶"
            elif [ "$signal" -gt 25 ]; then
                signal_icon="📶"
            else
                signal_icon="📶"
            fi
            
            formatted="$formatted$icon $ssid $signal_icon ($signal%)\n"
        fi
    done <<< "$networks"
    
    echo -e "$formatted"
}

# Función para conectar a red
connect_network() {
    local ssid="$1"
    local security="$2"
    
    if [ "$security" = "--" ]; then
        # Red abierta
        nmcli device wifi connect "$ssid"
    else
        # Red con contraseña
        password=$(rofi -dmenu -password -p "Contraseña para $ssid")
        if [ -n "$password" ]; then
            nmcli device wifi connect "$ssid" password "$password"
        fi
    fi
}

# Menú principal
main_menu() {
    local current_connection=$(nmcli -t -f NAME connection show --active | head -1)
    local wifi_status=$(nmcli radio wifi)
    
    local options=""
    
    if [ "$wifi_status" = "enabled" ]; then
        options="📡 Escanear Redes\n"
        if [ -n "$current_connection" ]; then
            options="$options🔌 Desconectar ($current_connection)\n"
        fi
        options="$options📴 Desactivar WiFi\n"
    else
        options="📶 Activar WiFi\n"
    fi
    
    options="$options⚙️ Configuración de Red"
    
    echo -e "$options"
}

# Menú principal
choice=$(main_menu | rofi -dmenu -i -p "WiFi" -theme-str 'window {width: 400px;}')

case "$choice" in
    "📡 Escanear Redes")
        network_choice=$(show_networks | rofi -dmenu -i -p "Seleccionar Red" -theme-str 'window {width: 500px; height: 400px;}')
        if [ -n "$network_choice" ]; then
            # Extraer SSID
            ssid=$(echo "$network_choice" | sed 's/^[🔒🔓] //' | sed 's/ 📶.*$//')
            
            # Obtener información de seguridad
            security=$(nmcli -t -f SSID,SECURITY device wifi list | grep "^$ssid:" | cut -d: -f2)
            
            connect_network "$ssid" "$security"
            
            if [ $? -eq 0 ]; then
                notify-send "WiFi" "Conectado a $ssid"
            else
                notify-send "WiFi" "Error al conectar a $ssid"
            fi
        fi
        ;;
    "🔌 Desconectar"*)
        nmcli connection down id "$(nmcli -t -f NAME connection show --active | head -1)"
        notify-send "WiFi" "Desconectado"
        ;;
    "📴 Desactivar WiFi")
        nmcli radio wifi off
        notify-send "WiFi" "WiFi desactivado"
        ;;
    "📶 Activar WiFi")
        nmcli radio wifi on
        notify-send "WiFi" "WiFi activado"
        ;;
    "⚙️ Configuración de Red")
        nm-connection-editor
        ;;
esac
