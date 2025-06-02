#!/bin/bash

# Gamemode Script - Optimizar sistema para gaming
# Activa/desactiva optimizaciones para juegos

set -euo pipefail

readonly GAMEMODE_FILE="/tmp/.hyprland_gamemode"

enable_gamemode() {
    echo "Activando Game Mode..."
    
    # Desactivar compositor effects
    hyprctl keyword decoration:blur:enabled false
    hyprctl keyword decoration:drop_shadow false
    hyprctl keyword animations:enabled false
    
    # Quitar gaps y bordes
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    hyprctl keyword decoration:rounding 0
    hyprctl keyword general:border_size 1
    
    # Configurar CPU governor a performance
    echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    
    # Configurar prioridades
    sudo sysctl vm.swappiness=10 >/dev/null 2>&1 || true
    sudo sysctl vm.vfs_cache_pressure=50 >/dev/null 2>&1 || true
    
    # Crear archivo de estado
    touch "$GAMEMODE_FILE"
    
    notify-send "Game Mode" "Activado - Sistema optimizado para gaming" -i applications-games
}

disable_gamemode() {
    echo "Desactivando Game Mode..."
    
    # Restaurar compositor effects
    hyprctl keyword decoration:blur:enabled true
    hyprctl keyword decoration:drop_shadow true
    hyprctl keyword animations:enabled true
    
    # Restaurar gaps y bordes
    hyprctl keyword general:gaps_in 5
    hyprctl keyword general:gaps_out 10
    hyprctl keyword decoration:rounding 10
    hyprctl keyword general:border_size 2
    
    # Restaurar CPU governor
    echo 'schedutil' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    
    # Restaurar configuraciones del sistema
    sudo sysctl vm.swappiness=60 >/dev/null 2>&1 || true
    sudo sysctl vm.vfs_cache_pressure=100 >/dev/null 2>&1 || true
    
    # Eliminar archivo de estado
    rm -f "$GAMEMODE_FILE"
    
    notify-send "Game Mode" "Desactivado - Sistema restaurado" -i preferences-desktop
}

# Verificar estado actual y toggle
if [ -f "$GAMEMODE_FILE" ]; then
    disable_gamemode
else
    enable_gamemode
fi
