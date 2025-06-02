#!/bin/bash
# Script de actualizaciones para Waybar

CACHE_FILE="/tmp/updates_cache"
CACHE_TIME=3600  # 1 hora

get_updates() {
    if [ -f "$CACHE_FILE" ]; then
        cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
        if [ $cache_age -lt $CACHE_TIME ]; then
            cat "$CACHE_FILE"
            return
        fi
    fi
    
    # Verificar actualizaciones de pacman
    pacman_updates=$(checkupdates 2>/dev/null | wc -l)
    
    # Verificar actualizaciones de AUR
    aur_updates=0
    if command -v yay >/dev/null 2>&1; then
        aur_updates=$(yay -Qua 2>/dev/null | wc -l)
    fi
    
    total_updates=$((pacman_updates + aur_updates))
    
    if [ $total_updates -gt 0 ]; then
        if [ $total_updates -gt 50 ]; then
            icon="🔴"
        elif [ $total_updates -gt 20 ]; then
            icon="🟡"
        else
            icon="📦"
        fi
        
        result="{\"text\":\"${icon} ${total_updates}\",\"tooltip\":\"Actualizaciones disponibles:\\nPacman: ${pacman_updates}\\nAUR: ${aur_updates}\\n\\nClick para actualizar\"}"
    else
        result="{\"text\":\"✅\",\"tooltip\":\"Sistema actualizado\"}"
    fi
    
    echo "$result" > "$CACHE_FILE"
    echo "$result"
}

case "$1" in
    "update")
        # Actualizar sistema
        kitty -e bash -c "sudo pacman -Syu && yay -Syu; read -p 'Presiona Enter para continuar...'"
        rm -f "$CACHE_FILE"
        ;;
    *)
        get_updates
        ;;
esac
