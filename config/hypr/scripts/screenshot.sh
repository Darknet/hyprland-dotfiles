#!/bin/bash
# Script de captura de pantalla

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

case "$1" in
    "area")
        grim -g "$(slurp)" "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d_%H%M%S).png"
        notify-send "Screenshot" "Área capturada" -i camera-photo
        ;;
    "screen")
        grim "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d_%H%M%S).png"
        notify-send "Screenshot" "Pantalla completa capturada" -i camera-photo
        ;;
    "window")
        hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d_%H%M%S).png"
        notify-send "Screenshot" "Ventana capturada" -i camera-photo
        ;;
    "edit")
        grim -g "$(slurp)" - | swappy -f -
        ;;
    *)
        echo "Uso: $0 {area|screen|window|edit}"
        ;;
esac
