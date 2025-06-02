#!/bin/bash
# Bluetooth menu usando Rofi

# Verificar si bluetoothctl está disponible
if ! command -v bluetoothctl >/dev/null 2>&1; then
    notify-send "Error" "bluetoothctl no está instalado"
    exit 1
fi

# Función para obtener estado del bluetooth
get_bluetooth_status() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

# Función para obtener dispositivos emparejados
get_paired_devices() {
    bluetoothctl devices | while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)
        
        # Verificar si está conectado
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            echo "🔗 $name (Conectado)"
        else
            echo "📱 $name"
        fi
    done
}

# Función para escanear dispositivos
scan_devices() {
    notify-send "Bluetooth" "Escaneando dispositivos..."
    
    # Iniciar escaneo
    bluetoothctl scan on &
    scan_pid=$!
    
    sleep 5
    
    # Obtener dispositivos descubiertos
    devices=$(bluetoothctl devices | while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)
        echo "🔍 $name"
    done)
    
    # Detener escaneo
    kill $scan_pid 2>/dev/null
    bluetoothctl scan off
    
    echo "$devices"
}

# Función para conectar dispositivo
connect_device() {
    local device_line="$1"
    local name=$(echo "$device_line" | sed 's/^[🔗📱🔍] //' | sed 's/ (Conectado)$//')
    
    # Buscar MAC del dispositivo
    local mac=$(bluetoothctl devices | grep "$name" | awk '{print $2}')
    
    if [ -n "$mac" ]; then
        if echo "$device_line" | grep -q "Conectado"; then
            # Desconectar
            bluetoothctl disconnect "$mac"
            notify-send "Bluetooth" "Desconectado de $name"
        else
            # Conectar (emparejar si es necesario)
            if ! bluetoothctl info "$mac" | grep -q "Paired: yes"; then
                bluetoothctl pair "$mac"
            fi
            bluetoothctl connect "$mac"
            notify-send "Bluetooth" "Conectado a $name"
        fi
    fi
}

# Menú principal
main_menu() {
    local bt_status=$(get_bluetooth_status)
    local options=""
    
    if [ "$bt_status" = "enabled" ]; then
        options="📱 Dispositivos Emparejados\n🔍 Escanear Dispositivos\n📴 Desactivar Bluetooth\n"
    else
        options="📶 Activar Bluetooth\n"
    fi
    
    options="$options⚙️ Configuración Bluetooth"
    
    echo -e "$options"
}

# Ejecutar menú principal
choice=$(main_menu | rofi -dmenu -i -p "Bluetooth" -theme-str 'window {width: 400px;}')

case "$choice" in
    "📱 Dispositivos Emparejados")
        devices=$(get_paired_devices)
        if [ -n "$devices" ]; then
            device_choice=$(echo "$devices" | rofi -dmenu -i -p "Dispositivos" -theme-str 'window {width: 450px;}')
            if [ -n "$device_choice" ]; then
                connect_device "$device_choice"
            fi
        else
            notify-send "Bluetooth" "No hay dispositivos emparejados"
        fi
        ;;
    "🔍 Escanear Dispositivos")
        devices=$(scan_devices)
        if [ -n "$devices" ]; then
            device_choice=$(echo "$devices" | rofi -dmenu -i -p "Dispositivos Encontrados" -theme-str 'window {width: 450px;}')
            if [ -n "$device_choice" ]; then
                connect_device "$device_choice"
            fi
        else
            notify-send "Bluetooth" "No se encontraron dispositivos"
        fi
        ;;
    "📴 Desactivar Bluetooth")
        bluetoothctl power off
        notify-send "Bluetooth" "Bluetooth desactivado"
        ;;
    "📶 Activar Bluetooth")
        bluetoothctl power on
        notify-send "Bluetooth" "Bluetooth activado"
        ;;
    "⚙️ Configuración Bluetooth")
        blueman-manager
        ;;
esac
