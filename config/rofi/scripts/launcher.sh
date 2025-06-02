#!/bin/bash
# Script launcher personalizado para Rofi

# Configuración
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
THEME="$HOME/.config/rofi/themes/catppuccin-mocha.rasi"

# Opciones de rofi
rofi_command="rofi -show drun -theme $THEME"

# Ejecutar rofi
$rofi_command
