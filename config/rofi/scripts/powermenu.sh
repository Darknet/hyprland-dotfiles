#!/bin/bash
# Power menu usando Rofi

options="⏻ Apagar\n🔄 Reiniciar\n🔒 Bloquear\n🚪 Cerrar Sesión\n💤 Suspender\n🔋 Hibernar"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Energía" -theme-str 'window {width: 300px; height: 250px;}')

case $chosen in
    "⏻ Apagar")
        systemctl poweroff
        ;;
    "🔄 Reiniciar")
        systemctl reboot
        ;;
    "🔒 Bloquear")
        swaylock -f -c 000000
        ;;
    "🚪 Cerrar Sesión")
        hyprctl dispatch exit
        ;;
    "💤 Suspender")
        systemctl suspend
        ;;
    "🔋 Hibernar")
        systemctl hibernate
        ;;
esac
