#!/bin/bash
# Script de clipboard manager con Rofi

case "$1" in
    "show")
        cliphist list | rofi -dmenu -p "Clipboard" -theme ~/.config/rofi/themes/catppuccin-mocha.rasi | cliphist decode | wl-copy
        ;;
    "clear")
        cliphist wipe
        notify-send "Clipboard" "Historial limpiado" -i edit-clear
        ;;
    *)
        echo "Uso: $0 {show|clear}"
        ;;
esac
