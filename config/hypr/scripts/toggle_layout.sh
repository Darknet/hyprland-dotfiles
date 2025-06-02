#!/bin/bash

# Toggle Layout Script - Cambiar entre layouts de Hyprland
# Alterna entre dwindle y master layout

set -euo pipefail

# Obtener layout actual
current_layout=$(hyprctl getoption general:layout | grep -o '".*"' | sed 's/"//g')

# Cambiar layout
case "$current_layout" in
    "dwindle")
        hyprctl keyword general:layout master
        notify-send "Layout" "Cambiado a Master Layout" -i preferences-desktop
        ;;
    "master")
        hyprctl keyword general:layout dwindle
        notify-send "Layout" "Cambiado a Dwindle Layout" -i preferences-desktop
        ;;
    *)
        # Fallback a dwindle si el layout no es reconocido
        hyprctl keyword general:layout dwindle
        notify-send "Layout" "Cambiado a Dwindle Layout (default)" -i preferences-desktop
        ;;
esac
