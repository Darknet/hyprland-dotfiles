#!/bin/bash

# Toggle Gaps Script - Activar/desactivar gaps
# Útil para maximizar espacio de pantalla

set -euo pipefail

# Obtener gaps actuales
current_gaps_in=$(hyprctl getoption general:gaps_in | grep -o 'int: [0-9]*' | cut -d' ' -f2)
current_gaps_out=$(hyprctl getoption general:gaps_out | grep -o 'int: [0-9]*' | cut -d' ' -f2)

# Toggle gaps
if [ "$current_gaps_in" -eq 0 ] && [ "$current_gaps_out" -eq 0 ]; then
    # Restaurar gaps
    hyprctl keyword general:gaps_in 5
    hyprctl keyword general:gaps_out 10
    hyprctl keyword decoration:rounding 10
    notify-send "Gaps" "Gaps activados" -i preferences-desktop
else
    # Quitar gaps
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    hyprctl keyword decoration:rounding 0
    notify-send "Gaps" "Gaps desactivados" -i preferences-desktop
fi
