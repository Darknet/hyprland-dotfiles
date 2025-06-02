#!/bin/bash
# Script de bloqueo de pantalla

# Crear imagen de bloqueo
LOCK_IMAGE="/tmp/lockscreen.png"
WALLPAPER=$(cat "$HOME/.config/hypr/current-wallpaper" 2>/dev/null || echo "$HOME/.config/hypr/wallpapers/default.jpg")

# Crear imagen borrosa para el bloqueo
if [ -f "$WALLPAPER" ]; then
    convert "$WALLPAPER" -blur 0x8 "$LOCK_IMAGE"
else
    # Captura de pantalla como fallback
    grim "$LOCK_IMAGE"
    convert "$LOCK_IMAGE" -blur 0x8 "$LOCK_IMAGE"
fi

# Pausar notificaciones
dunstctl set-paused true

# Bloquear pantalla
swaylock \
    --image "$LOCK_IMAGE" \
    --clock \
    --indicator \
    --indicator-radius 100 \
    --indicator-thickness 7 \
    --effect-blur 7x5 \
    --effect-vignette 0.5:0.5 \
    --ring-color bb00cc \
    --key-hl-color 880033 \
    --line-color 00000000 \
    --inside-color 00000088 \
    --separator-color 00000000 \
    --grace 2 \
    --fade-in 0.2

# Reanudar notificaciones
dunstctl set-paused false

# Limpiar imagen temporal
rm -f "$LOCK_IMAGE"
