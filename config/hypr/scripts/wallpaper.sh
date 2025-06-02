#!/bin/bash
# Script de gestión de wallpapers

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
CURRENT_WALLPAPER="$HOME/.config/hypr/current-wallpaper"

set_wallpaper() {
    local wallpaper="$1"
    if [ -f "$wallpaper" ]; then
        swww img "$wallpaper" --transition-fps 60 --transition-type wipe --transition-duration 2
        echo "$wallpaper" > "$CURRENT_WALLPAPER"
        notify-send "Wallpaper" "Cambiado a $(basename "$wallpaper")" -i image-x-generic
    fi
}

case "$1" in
    "set")
        set_wallpaper "$2"
        ;;
    "random")
        if [ -d "$WALLPAPER_DIR" ]; then
            wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
            set_wallpaper "$wallpaper"
        fi
        ;;
    "next")
        if [ -f "$CURRENT_WALLPAPER" ]; then
            current=$(cat "$CURRENT_WALLPAPER")
            wallpapers=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | sort))
            for i in "${!wallpapers[@]}"; do
                if [[ "${wallpapers[$i]}" = "$current" ]]; then
                    next_index=$(( (i + 1) % ${#wallpapers[@]} ))
                    set_wallpaper "${wallpapers[$next_index]}"
                    break
                fi
            done
        fi
        ;;
    "menu")
        wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) -exec basename {} \; | rofi -dmenu -i -p "Seleccionar wallpaper")
        if [ -n "$wallpaper" ]; then
            set_wallpaper "$WALLPAPER_DIR/$wallpaper"
        fi
        ;;
    *)
        echo "Uso: $0 {set|random|next|menu} [archivo]"
        ;;
esac
