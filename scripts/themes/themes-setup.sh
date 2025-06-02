#!/bin/bash

# Themes Setup Script
# Configuración de temas y personalización visual

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../../logs/themes_setup_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

ask_question() {
    local question="$1"
    local default="${2:-n}"
    local response
    
    echo -e "${CYAN}$question [y/N]: ${NC}"
    read -r response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Mostrar temas disponibles
show_theme_menu() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                     SELECCIÓN DE TEMAS                      ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  1. Catppuccin Mocha (Recomendado)                          ║"
    echo "║  2. Tokyo Night                                              ║"
    echo "║  3. Dracula                                                  ║"
    echo "║  4. Nord                                                     ║"
    echo "║  5. Gruvbox Dark                                             ║"
    echo "║  6. Rose Pine                                                ║"
    echo "║  7. Everforest                                               ║"
    echo "║  8. Kanagawa                                                 ║"
    echo "║  9. Configuración personalizada                             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Instalar iconos y cursores
install_icons_cursors() {
    log "Instalando iconos y cursores..."
    
    # Determinar helper AUR
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        error "No se encontró helper de AUR (yay o paru)"
    fi
    
    # Iconos
    $AUR_HELPER -S --needed --noconfirm \
        papirus-icon-theme \
        tela-icon-theme \
        beautyline \
        candy-icons-git \
        la-capitaine-icon-theme
    
    # Cursores
    $AUR_HELPER -S --needed --noconfirm \
        bibata-cursor-theme \
        capitaine-cursors \
        xcursor-breeze \
        phinger-cursors
    
    # Fuentes
    sudo pacman -S --needed --noconfirm \
        ttf-jetbrains-mono \
        ttf-jetbrains-mono-nerd \
        ttf-fira-code \
        ttf-fira-sans \
        ttf-roboto \
        ttf-roboto-mono \
        noto-fonts \
        noto-fonts-emoji \
        ttf-liberation \
        ttf-opensans
    
    # Fuentes adicionales desde AUR
    $AUR_HELPER -S --needed --noconfirm \
        ttf-meslo-nerd-font-powerlevel10k \
        ttf-sf-pro \
        ttf-ms-fonts \
        inter-font
}

# Configurar tema Catppuccin
setup_catppuccin() {
    log "Configurando tema Catppuccin Mocha..."
    
    # Colores Catppuccin Mocha
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/catppuccin.conf" << 'EOF'
# Catppuccin Mocha Theme

# Variables de color
$rosewater = rgb(f5e0dc)
$flamingo = rgb(f2cdcd)
$pink = rgb(f5c2e7)
$mauve = rgb(cba6f7)
$red = rgb(f38ba8)
$maroon = rgb(eba0ac)
$peach = rgb(fab387)
$yellow = rgb(f9e2af)
$green = rgb(a6e3a1)
$teal = rgb(94e2d5)
$sky = rgb(89dceb)
$sapphire = rgb(74c7ec)
$blue = rgb(89b4fa)
$lavender = rgb(b4befe)
$text = rgb(cdd6f4)
$subtext1 = rgb(bac2de)
$subtext0 = rgb(a6adc8)
$overlay2 = rgb(9399b2)
$overlay1 = rgb(7f849c)
$overlay0 = rgb(6c7086)
$surface2 = rgb(585b70)
$surface1 = rgb(45475a)
$surface0 = rgb(313244)
$base = rgb(1e1e2e)
$mantle = rgb(181825)
$crust = rgb(11111b)

# Configuración de colores para Hyprland
general {
    col.active_border = $mauve $pink 45deg
    col.inactive_border = $surface0
}

decoration {
    col.shadow = $crust
    col.shadow_inactive = $crust
}

# Variables para otros componentes
env = THEME_PRIMARY,$mauve
env = THEME_SECONDARY,$pink
env = THEME_ACCENT,$blue
env = THEME_BACKGROUND,$base
env = THEME_SURFACE,$surface0
env = THEME_TEXT,$text
EOF

    # Waybar theme
    cat > "${SCRIPT_DIR}/../../config/waybar/themes/catppuccin.css" << 'EOF'
/* Catppuccin Mocha Theme for Waybar */

@define-color rosewater #f5e0dc;
@define-color flamingo #f2cdcd;
@define-color pink #f5c2e7;
@define-color mauve #cba6f7;
@define-color red #f38ba8;
@define-color maroon #eba0ac;
@define-color peach #fab387;
@define-color yellow #f9e2af;
@define-color green #a6e3a1;
@define-color teal #94e2d5;
@define-color sky #89dceb;
@define-color sapphire #74c7ec;
@define-color blue #89b4fa;
@define-color lavender #b4befe;
@define-color text #cdd6f4;
@define-color subtext1 #bac2de;
@define-color subtext0 #a6adc8;
@define-color overlay2 #9399b2;
@define-color overlay1 #7f849c;
@define-color overlay0 #6c7086;
@define-color surface2 #585b70;
@define-color surface1 #45475a;
@define-color surface0 #313244;
@define-color base #1e1e2e;
@define-color mantle #181825;
@define-color crust #11111b;

* {
    font-family: "JetBrains Mono Nerd Font";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: alpha(@base, 0.9);
    color: @text;
    border-radius: 10px;
    margin: 5px;
}

.modules-left,
.modules-center,
.modules-right {
    background: transparent;
}

#workspaces button {
    background: @surface0;
    color: @subtext0;
    border-radius: 5px;
    margin: 2px;
    padding: 0 10px;
    transition: all 0.3s ease;
}

#workspaces button.active {
    background: @mauve;
    color: @base;
}

#workspaces button:hover {
    background: @surface1;
    color: @text;
}

#clock {
    background: @blue;
    color: @base;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
    font-weight: bold;
}

#battery {
    background: @green;
    color: @base;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
}

#battery.warning {
    background: @yellow;
    color: @base;
}

#battery.critical {
    background: @red;
    color: @base;
}

#network {
    background: @teal;
    color: @base;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
}

#pulseaudio {
    background: @pink;
    color: @base;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
}

#custom-gpu {
    background: @peach;
    color: @base;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
}

#tray {
    background: @surface0;
    border-radius: 5px;
    padding: 0 10px;
    margin: 2px;
}
EOF

    # Rofi theme
    mkdir -p "${SCRIPT_DIR}/../../config/rofi/themes"
    cat > "${SCRIPT_DIR}/../../config/rofi/themes/catppuccin.rasi" << 'EOF'
/* Catppuccin Mocha Theme for Rofi */

* {
    bg: #1e1e2e;
    bg-alt: #313244;
    fg: #cdd6f4;
    fg-alt: #bac2de;
    
    primary: #cba6f7;
    secondary: #f5c2e7;
    accent: #89b4fa;
    urgent: #f38ba8;
    
    background-color: transparent;
    text-color: @fg;
    font: "JetBrains Mono Nerd Font 12";
}

window {
    background-color: @bg;
    border: 2px;
    border-color: @primary;
    border-radius: 10px;
    width: 600px;
    location: center;
    anchor: center;
}

mainbox {
    children: [inputbar, listview];
    spacing: 10px;
    padding: 20px;
}

inputbar {
    children: [prompt, entry];
    background-color: @bg-alt;
    border-radius: 5px;
    padding: 10px;
}

prompt {
    background-color: @primary;
    text-color: @bg;
    border-radius: 3px;
    padding: 5px 10px;
    margin: 0 10px 0 0;
}

entry {
    placeholder: "Buscar...";
    placeholder-color: @fg-alt;
    background-color: transparent;
    padding: 5px;
}

listview {
    lines: 8;
    columns: 1;
    fixed-height: false;
    scrollbar: false;
    spacing: 5px;
}

element {
    background-color: transparent;
    text-color: @fg;
    border-radius: 5px;
    padding: 8px;
}

element selected {
    background-color: @primary;
    text-color: @bg;
}

element-text {
    background-color: transparent;
    text-color: inherit;
}

element-icon {
    background-color: transparent;
    size: 24px;
    margin: 0 10px 0 0;
}
EOF

    # Dunst theme
    cat > "${SCRIPT_DIR}/../../config/dunst/themes/catppuccin.conf" << 'EOF'
# Catppuccin Mocha Theme for Dunst

[global]
    frame_color = "#cba6f7"
    separator_color = "#313244"

[base16_low]
    msg_urgency = low
    background = "#1e1e2e"
    foreground = "#cdd6f4"

[base16_normal]
    msg_urgency = normal
    background = "#1e1e2e"
    foreground = "#cdd6f4"

[base16_critical]
    msg_urgency = critical
    background = "#1e1e2e"
    foreground = "#f38ba8"
    frame_color = "#f38ba8"
EOF

    # Kitty theme
    cat > "${SCRIPT_DIR}/../../config/kitty/themes/catppuccin.conf" << 'EOF'
# Catppuccin Mocha Theme for Kitty

# The basic colors
foreground              #cdd6f4
background              #1e1e2e
selection_foreground    #1e1e2e
selection_background    #f5e0dc

# Cursor colors
cursor                  #f5e0dc
cursor_text_color       #1e1e2e

# URL underline color when hovering with mouse
url_color               #f5e0dc

# Kitty window border colors
active_border_color     #b4befe
inactive_border_color   #6c7086
bell_border_color       #f9e2af

# OS Window titlebar colors
wayland_titlebar_color system
macos_titlebar_color system

# Tab bar colors
active_tab_foreground   #11111b
active_tab_background   #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b

# Colors for marks (marked text in the terminal)
mark1_foreground #1e1e2e
mark1_background #b4befe
mark2_foreground #1e1e2e
mark2_background #cba6f7
mark3_foreground #1e1e2e
mark3_background #74c7ec

# The 16 terminal colors

# black
color0 #45475a
color8 #585b70

# red
color1 #f38ba8
color9 #f38ba8

# green
color2  #a6e3a1
color10 #a6e3a1

# yellow
color3  #f9e2af
color11 #f9e2af

# blue
color4  #89b4fa
color12 #89b4fa

# magenta
color5  #f5c2e7
color13 #f5c2e7

# cyan
color6  #94e2d5
color14 #94e2d5

# white
color7  #bac2de
color15 #a6adc8
EOF

    # GTK theme
    setup_gtk_theme "catppuccin"
}

# Configurar tema Tokyo Night
setup_tokyo_night() {
    log "Configurando tema Tokyo Night..."
    
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/tokyo-night.conf" << 'EOF'
# Tokyo Night Theme

# Variables de color
$bg = rgb(1a1b26)
$bg_dark = rgb(16161e)
$bg_highlight = rgb(292e42)
$terminal_black = rgb(414868)
$fg = rgb(c0caf5)
$fg_dark = rgb(a9b1d6)
$fg_gutter = rgb(3b4261)
$dark3 = rgb(545c7e)
$comment = rgb(565f89)
$dark5 = rgb(737aa2)
$blue0 = rgb(3d59a1)
$blue = rgb(7aa2f7)
$cyan = rgb(7dcfff)
$blue1 = rgb(2ac3de)
$blue2 = rgb(0db9d7)
$blue5 = rgb(89ddff)
$blue6 = rgb(b4f9f8)
$blue7 = rgb(394b70)
$magenta = rgb(bb9af7)
$magenta2 = rgb(ff007c)
$purple = rgb(9d7cd8)
$orange = rgb(ff9e64)
$yellow = rgb(e0af68)
$green = rgb(9ece6a)
$green1 = rgb(73daca)
$green2 = rgb(41a6b5)
$teal = rgb(1abc9c)
$red = rgb(f7768e)
$red1 = rgb(db4b4b)

# Configuración de colores para Hyprland
general {
    col.active_border = $blue $cyan 45deg
    col.inactive_border = $bg_highlight
}

decoration {
    col.shadow = $bg_dark
    col.shadow_inactive = $bg_dark
}

# Variables para otros componentes
env = THEME_PRIMARY,$blue
env = THEME_SECONDARY,$cyan
env = THEME_ACCENT,$magenta
env = THEME_BACKGROUND,$bg
env = THEME_SURFACE,$bg_highlight
env = THEME_TEXT,$fg
EOF

    # Waybar theme para Tokyo Night
    cat > "${SCRIPT_DIR}/../../config/waybar/themes/tokyo-night.css" << 'EOF'
/* Tokyo Night Theme for Waybar */

@define-color bg #1a1b26;
@define-color bg-alt #292e42;
@define-color fg #c0caf5;
@define-color blue #7aa2f7;
@define-color cyan #7dcfff;
@define-color green #9ece6a;
@define-color yellow #e0af68;
@define-color orange #ff9e64;
@define-color red #f7768e;
@define-color magenta #bb9af7;
@define-color purple #9d7cd8;

* {
    font-family: "JetBrains Mono Nerd Font";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: alpha(@bg, 0.9);
    color: @fg;
    border-radius: 10px;
    margin: 5px;
}

#workspaces button {
    background: @bg-alt;
    color: @fg;
    border-radius: 5px;
    margin: 2px;
    padding: 0 10px;
    transition: all 0.3s ease;
}

#workspaces button.active {
    background: @blue;
    color: @bg;
}

#clock {
    background: @cyan;
    color: @bg;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
    font-weight: bold;
}

#battery {
    background: @green;
    color: @bg;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
}

#network {
    background: @purple;
    color: @bg;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
}

#pulseaudio {
    background: @magenta;
    color: @bg;
    border-radius: 5px;
    padding: 0 15px;
    margin: 2px;
}
EOF
}

# Configurar GTK theme
setup_gtk_theme() {
    local theme_name="$1"
    
    log "Configurando tema GTK: $theme_name"
    
    # Instalar temas GTK
    case "$theme_name" in
        "catppuccin")
            if command -v yay &>/dev/null; then
                yay -S --needed --noconfirm catppuccin-gtk-theme-mocha
            fi
            GTK_THEME="Catppuccin-Mocha-Standard-Mauve-Dark"
            ICON_THEME="Papirus-Dark"
            CURSOR_THEME="Bibata-Modern-Classic"
            ;;
        "tokyo-night")
            GTK_THEME="Adwaita-dark"
            ICON_THEME="Tela-dark"
            CURSOR_THEME="Bibata-Modern-Classic"
            ;;
        *)
            GTK_THEME="Adwaita-dark"
            ICON_THEME="Papirus-Dark"
            CURSOR_THEME="Bibata-Modern-Classic"
            ;;
    esac
    
    # Configurar GTK-3
    mkdir -p "${HOME}/.config/gtk-3.0"
    cat > "${HOME}/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Inter 11
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF

    # Configurar GTK-4
    mkdir -p "${HOME}/.config/gtk-4.0"
    cat > "${HOME}/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Inter 11
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

    # Configurar Qt
    setup_qt_theme "$theme_name"
}

# Configurar Qt theme
setup_qt_theme() {
    local theme_name="$1"
    
    log "Configurando tema Qt..."
    
    # Instalar qt5ct y qt6ct si no están instalados
    sudo pacman -S --needed --noconfirm qt5ct qt6ct
    
    # Variables de entorno para Qt
    cat > "${HOME}/.config/environment.d/qt-theme.conf" << 'EOF'
QT_QPA_PLATFORMTHEME=qt5ct
QT_AUTO_SCREEN_SCALE_FACTOR=0
QT_SCALE_FACTOR=1
QT_FONT_DPI=96
EOF

    # Configurar qt5ct
    mkdir -p "${HOME}/.config/qt5ct"
    cat > "${HOME}/.config/qt5ct/qt5ct.conf" << EOF
[Appearance]
color_scheme_path=${HOME}/.config/qt5ct/colors/${theme_name}.conf
custom_palette=false
icon_theme=$ICON_THEME
standard_dialogs=default
style=Fusion

[Fonts]
fixed=@Variant(\\0\\0\\0@\\0\\0\\0\\x12\\0J\\0e\\0t\\0B\\0r\\0a\\0i\\0n\\0s\\0 \\0M\\0o\\0n\\0o@$\\0\\0\\0\\0\\0\\0\\xff\\xff\\xff\\xff\\x5\\x1\\0\\x32\\x10)
general=@Variant(\\0\\0\\0@\\0\\0\\0\\n\\0I\\0n\\0t\\0e\\0r@$\\0\\0\\0\\0\\0\\0\\xff\\xff\\xff\\xff\\x5\\x1\\0\\x32\\x10)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[SettingsWindow]
geometry=@ByteArray(\\x1\\xd9\\xd0\\xcb\\0\\x3\\0\\0\\0\\0\\x2\\x80\\0\\0\\x1\\x90\\0\\0\\x5\\x7f\\0\\0\\x4\\x37\\0\\0\\x2\\x80\\0\\0\\x1\\x90\\0\\0\\x5\\x7f\\0\\0\\x4\\x37\\0\\0\\0\\0\\0\\0\\a\\x80\\0\\0\\x2\\x80\\0\\0\\x1\\x90\\0\\0\\x5\\x7f\\0\\0\\x4\\x37)
EOF

    # Configurar qt6ct
    mkdir -p "${HOME}/.config/qt6ct"
    cp "${HOME}/.config/qt5ct/qt5ct.conf" "${HOME}/.config/qt6ct/qt6ct.conf"
}

# Aplicar tema seleccionado
apply_theme() {
    local theme_choice="$1"
    
    case $theme_choice in
        1)
            setup_catppuccin
            SELECTED_THEME="catppuccin"
            ;;
        2)
            setup_tokyo_night
            SELECTED_THEME="tokyo-night"
            ;;
        3)
            setup_dracula
            SELECTED_THEME="dracula"
            ;;
        4)
            setup_nord
            SELECTED_THEME="nord"
            ;;
        5)
            setup_gruvbox
            SELECTED_THEME="gruvbox"
            ;;
        6)
            setup_rose_pine
            SELECTED_THEME="rose-pine"
            ;;
        7)
            setup_everforest
            SELECTED_THEME="everforest"
            ;;
        8)
            setup_kanagawa
            SELECTED_THEME="kanagawa"
            ;;
        9)
            custom_theme_setup
            SELECTED_THEME="custom"
            ;;
        *)
            warning "Opción no válida, usando Catppuccin por defecto"
            setup_catppuccin
            SELECTED_THEME="catppuccin"
            ;;
    esac
    
    # Actualizar configuración principal de Hyprland
    update_hyprland_theme
    
    # Actualizar configuraciones de aplicaciones
    update_app_configs
    
    log "✓ Tema $SELECTED_THEME aplicado exitosamente"
}

# Configuración personalizada de tema
custom_theme_setup() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  CONFIGURACIÓN PERSONALIZADA                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Solicitar colores personalizados
    echo "Introduce los colores en formato hexadecimal (sin #):"
    
    echo -n "Color primario [cba6f7]: "
    read -r primary_color
    primary_color=${primary_color:-cba6f7}
    
    echo -n "Color secundario [f5c2e7]: "
    read -r secondary_color
    secondary_color=${secondary_color:-f5c2e7}
    
    echo -n "Color de fondo [1e1e2e]: "
    read -r bg_color
    bg_color=${bg_color:-1e1e2e}
    
    echo -n "Color de texto [cdd6f4]: "
    read -r text_color
    text_color=${text_color:-cdd6f4}
    
    echo -n "Color de superficie [313244]: "
    read -r surface_color
    surface_color=${surface_color:-313244}
    
    # Crear tema personalizado
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/custom.conf" << EOF
# Custom Theme

# Variables de color personalizadas
\$primary = rgb($primary_color)
\$secondary = rgb($secondary_color)
\$background = rgb($bg_color)
\$text = rgb($text_color)
\$surface = rgb($surface_color)

# Configuración de colores para Hyprland
general {
    col.active_border = \$primary \$secondary 45deg
    col.inactive_border = \$surface
}

decoration {
    col.shadow = \$background
    col.shadow_inactive = \$background
}

# Variables para otros componentes
env = THEME_PRIMARY,\$primary
env = THEME_SECONDARY,\$secondary
env = THEME_ACCENT,\$primary
env = THEME_BACKGROUND,\$background
env = THEME_SURFACE,\$surface
env = THEME_TEXT,\$text
EOF

    log "✓ Tema personalizado creado"
}

# Actualizar configuración de Hyprland
update_hyprland_theme() {
    log "Actualizando configuración de Hyprland..."
    
    # Actualizar hyprland.conf para incluir el tema
    local hyprland_conf="${SCRIPT_DIR}/../../config/hypr/hyprland.conf"
    
    if [[ -f "$hyprland_conf" ]]; then
        # Remover línea de tema anterior si existe
        sed -i '/^source.*themes.*\.conf$/d' "$hyprland_conf"
        
        # Añadir nueva línea de tema
        echo "source = ~/.config/hypr/themes/${SELECTED_THEME}.conf" >> "$hyprland_conf"
        
        log "✓ Configuración de Hyprland actualizada"
    else
        warning "No se encontró hyprland.conf"
    fi
}

# Actualizar configuraciones de aplicaciones
update_app_configs() {
    log "Actualizando configuraciones de aplicaciones..."
    
    # Actualizar Waybar
    if [[ -f "${SCRIPT_DIR}/../../config/waybar/style.css" ]]; then
        # Crear backup
        cp "${SCRIPT_DIR}/../../config/waybar/style.css" "${SCRIPT_DIR}/../../config/waybar/style.css.bak"
        
        # Aplicar nuevo tema
        if [[ -f "${SCRIPT_DIR}/../../config/waybar/themes/${SELECTED_THEME}.css" ]]; then
            cp "${SCRIPT_DIR}/../../config/waybar/themes/${SELECTED_THEME}.css" "${SCRIPT_DIR}/../../config/waybar/style.css"
            log "✓ Tema de Waybar actualizado"
        fi
    fi
    
    # Actualizar Rofi
    local rofi_config="${SCRIPT_DIR}/../../config/rofi/config.rasi"
    if [[ -f "$rofi_config" ]]; then
        sed -i "s|@theme.*|@theme \"~/.config/rofi/themes/${SELECTED_THEME}.rasi\"|" "$rofi_config"
        log "✓ Tema de Rofi actualizado"
    fi
    
    # Actualizar Dunst
    local dunst_config="${SCRIPT_DIR}/../../config/dunst/dunstrc"
    if [[ -f "$dunst_config" ]] && [[ -f "${SCRIPT_DIR}/../../config/dunst/themes/${SELECTED_THEME}.conf" ]]; then
        # Añadir include del tema
        if ! grep -q "include.*themes.*${SELECTED_THEME}" "$dunst_config"; then
            echo "" >> "$dunst_config"
            echo "# Theme" >> "$dunst_config"
            echo "include = ~/.config/dunst/themes/${SELECTED_THEME}.conf" >> "$dunst_config"
        fi
        log "✓ Tema de Dunst actualizado"
    fi
    
    # Actualizar Kitty
    local kitty_config="${SCRIPT_DIR}/../../config/kitty/kitty.conf"
    if [[ -f "$kitty_config" ]]; then
        # Remover línea de tema anterior
        sed -i '/^include.*themes.*\.conf$/d' "$kitty_config"
        
        # Añadir nuevo tema
        echo "include ~/.config/kitty/themes/${SELECTED_THEME}.conf" >> "$kitty_config"
        log "✓ Tema de Kitty actualizado"
    fi
}

# Crear script de cambio de tema
create_theme_switcher() {
    log "Creando script de cambio de tema..."
    
    mkdir -p "${HOME}/.local/bin"
    
    cat > "${HOME}/.local/bin/theme-switcher" << 'EOF'
#!/bin/bash

# Theme Switcher Script
# Permite cambiar temas dinámicamente

THEMES_DIR="${HOME}/.config/hypr/themes"
CURRENT_THEME_FILE="${HOME}/.config/current-theme"

show_themes() {
    echo "Temas disponibles:"
    local i=1
    for theme in "${THEMES_DIR}"/*.conf; do
        if [[ -f "$theme" ]]; then
            local theme_name=$(basename "$theme" .conf)
            echo "$i. $theme_name"
            ((i++))
        fi
    done
}

get_current_theme() {
    if [[ -f "$CURRENT_THEME_FILE" ]]; then
        cat "$CURRENT_THEME_FILE"
    else
        echo "No theme set"
    fi
}

apply_theme() {
    local theme_name="$1"
    local theme_file="${THEMES_DIR}/${theme_name}.conf"
    
    if [[ ! -f "$theme_file" ]]; then
        echo "Error: Theme '$theme_name' not found"
        exit 1
    fi
    
    # Actualizar Hyprland
    local hyprland_conf="${HOME}/.config/hypr/hyprland.conf"
    if [[ -f "$hyprland_conf" ]]; then
        sed -i '/^source.*themes.*\.conf$/d' "$hyprland_conf"
        echo "source = ~/.config/hypr/themes/${theme_name}.conf" >> "$hyprland_conf"
    fi
    
    # Actualizar otras aplicaciones
    update_waybar_theme "$theme_name"
    update_rofi_theme "$theme_name"
    update_kitty_theme "$theme_name"
    
    # Guardar tema actual
    echo "$theme_name" > "$CURRENT_THEME_FILE"
    
    # Recargar Hyprland
    hyprctl reload
    
    # Reiniciar Waybar
    pkill waybar
    waybar &
    
    echo "Theme '$theme_name' applied successfully"
}

update_waybar_theme() {
    local theme_name="$1"
    local waybar_theme="${HOME}/.config/waybar/themes/${theme_name}.css"
    
    if [[ -f "$waybar_theme" ]]; then
        cp "$waybar_theme" "${HOME}/.config/waybar/style.css"
    fi
}

update_rofi_theme() {
    local theme_name="$1"
    local rofi_config="${HOME}/.config/rofi/config.rasi"
    
    if [[ -f "$rofi_config" ]]; then
        sed -i "s|@theme.*|@theme \"~/.config/rofi/themes/${theme_name}.rasi\"|" "$rofi_config"
    fi
}

update_kitty_theme() {
    local theme_name="$1"
    local kitty_config="${HOME}/.config/kitty/kitty.conf"
    
    if [[ -f "$kitty_config" ]]; then
        sed -i '/^include.*themes.*\.conf$/d' "$kitty_config"
        echo "include ~/.config/kitty/themes/${theme_name}.conf" >> "$kitty_config"
    fi
}

case "$1" in
    "list")
        show_themes
        ;;
    "current")
        echo "Current theme: $(get_current_theme)"
        ;;
    "set")
        if [[ -z "$2" ]]; then
            echo "Usage: theme-switcher set <theme_name>"
            exit 1
        fi
        apply_theme "$2"
        ;;
    *)
        echo "Usage: theme-switcher {list|current|set <theme_name>}"
        echo ""
        echo "Commands:"
        echo "  list     - Show available themes"
        echo "  current  - Show current theme"
        echo "  set      - Apply a theme"
        echo ""
        echo "Examples:"
        echo "  theme-switcher list"
        echo "  theme-switcher set catppuccin"
        exit 1
        ;;
esac
EOF

    chmod +x "${HOME}/.local/bin/theme-switcher"
    log "✓ Script theme-switcher creado"
}

# Crear wallpaper manager
create_wallpaper_manager() {
    log "Creando gestor de wallpapers..."
    
    mkdir -p "${HOME}/.local/bin"
    mkdir -p "${HOME}/Pictures/Wallpapers"
    
    cat > "${HOME}/.local/bin/wallpaper-manager" << 'EOF'
#!/bin/bash

# Wallpaper Manager Script
# Gestión de wallpapers para Hyprland

WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
CURRENT_WALLPAPER_FILE="${HOME}/.config/current-wallpaper"

show_wallpapers() {
    echo "Wallpapers disponibles:"
    local i=1
    for wallpaper in "${WALLPAPER_DIR}"/*.{jpg,jpeg,png,webp} 2>/dev/null; do
        if [[ -f "$wallpaper" ]]; then
            local wallpaper_name=$(basename "$wallpaper")
            echo "$i. $wallpaper_name"
            ((i++))
        fi
    done
}

get_current_wallpaper() {
    if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
        cat "$CURRENT_WALLPAPER_FILE"
    else
        echo "No wallpaper set"
    fi
}

set_wallpaper() {
    local wallpaper_path="$1"
    
    if [[ ! -f "$wallpaper_path" ]]; then
        echo "Error: Wallpaper file not found: $wallpaper_path"
        exit 1
    fi
    
    # Usar swww si está disponible, sino hyprpaper
    if command -v swww &>/dev/null; then
        swww img "$wallpaper_path" --transition-type wipe --transition-duration 2
    elif command -v hyprpaper &>/dev/null; then
        # Actualizar configuración de hyprpaper
        local hyprpaper_conf="${HOME}/.config/hypr/hyprpaper.conf"
        cat > "$hyprpaper_conf" << EOF
preload = $wallpaper_path
wallpaper = ,$wallpaper_path
splash = false
EOF
        # Recargar hyprpaper
        pkill hyprpaper
        hyprpaper &
    else
        echo "Error: No wallpaper manager found (swww or hyprpaper)"
        exit 1
    fi
    
    # Guardar wallpaper actual
    echo "$wallpaper_path" > "$CURRENT_WALLPAPER_FILE"
    
    echo "Wallpaper set: $(basename "$wallpaper_path")"
}

random_wallpaper() {
    local wallpapers=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null))
    
    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    
    local random_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    set_wallpaper "$random_wallpaper"
}

download_wallpaper() {
    local url="$1"
    local filename="$2"
    
    if [[ -z "$url" ]]; then
        echo "Usage: wallpaper-manager download <url> [filename]"
        exit 1
    fi
    
    if [[ -z "$filename" ]]; then
        filename=$(basename "$url")
    fi
    
    local output_path="${WALLPAPER_DIR}/${filename}"
    
    if command -v wget &>/dev/null; then
        wget -O "$output_path" "$url"
    elif command -v curl &>/dev/null; then
        curl -o "$output_path" "$url"
    else
        echo "Error: wget or curl required for downloading"
        exit 1
    fi
    
    echo "Wallpaper downloaded: $output_path"
}

case "$1" in
    "list")
        show_wallpapers
        ;;
    "current")
        echo "Current wallpaper: $(get_current_wallpaper)"
        ;;
    "set")
        if [[ -z "$2" ]]; then
            echo "Usage: wallpaper-manager set <wallpaper_path>"
            exit 1
        fi
        set_wallpaper "$2"
        ;;
    "random")
        random_wallpaper
        ;;
    "download")
        download_wallpaper "$2" "$3"
        ;;
    *)
        echo "Usage: wallpaper-manager {list|current|set|random|download}"
        echo ""
        echo "Commands:"
        echo "  list                    - Show available wallpapers"
        echo "  current                 - Show current wallpaper"
        echo "  set <path>             - Set specific wallpaper"
        echo "  random                 - Set random wallpaper"
        echo "  download <url> [name]  - Download wallpaper from URL"
        echo ""
        echo "Examples:"
        echo "  wallpaper-manager list"
        echo "  wallpaper-manager set ~/Pictures/Wallpapers/image.jpg"
        echo "  wallpaper-manager random"
        echo "  wallpaper-manager download https://example.com/image.jpg"
        exit 1
        ;;
esac
EOF

    chmod +x "${HOME}/.local/bin/wallpaper-manager"
    log "✓ Script wallpaper-manager creado"
}

# Descargar wallpapers por defecto
download_default_wallpapers() {
    log "Descargando wallpapers por defecto..."
    
    local wallpaper_dir="${HOME}/Pictures/Wallpapers"
    mkdir -p "$wallpaper_dir"
    
    # URLs de wallpapers por tema
    declare -A wallpaper_urls=(
        ["catppuccin"]="https://raw.githubusercontent.com/catppuccin/wallpapers/main/landscapes/tropic_island_day.png"
        ["tokyo-night"]="https://raw.githubusercontent.com/tokyo-night/tokyo-night-vscode-theme/master/static/tokyo-night.png"
        ["nord"]="https://raw.githubusercontent.com/arcticicestudio/nord-docs/develop/assets/images/ports/vim/overview-go.png"
        ["dracula"]="https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/arch-dracula.png"
    )
    
    for theme in "${!wallpaper_urls[@]}"; do
        local url="${wallpaper_urls[$theme]}"
        local filename="${theme}-wallpaper.png"
        local output_path="${wallpaper_dir}/${filename}"
        
        if [[ ! -f "$output_path" ]]; then
            log "Descargando wallpaper para $theme..."
            if command -v wget &>/dev/null; then
                wget -q -O "$output_path" "$url" || warning "Error descargando wallpaper de $theme"
            elif command -v curl &>/dev/null; then
                curl -s -o "$output_path" "$url" || warning "Error descargando wallpaper de $theme"
            fi
        fi
    done
    
    log "✓ Wallpapers descargados"
}

# Configurar temas adicionales (implementaciones simplificadas)
setup_dracula() {
    log "Configurando tema Dracula..."
    
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/dracula.conf" << 'EOF'
# Dracula Theme
$background = rgb(282a36)
$current_line = rgb(44475a)
$foreground = rgb(f8f8f2)
$comment = rgb(6272a4)
$cyan = rgb(8be9fd)
$green = rgb(50fa7b)
$orange = rgb(ffb86c)
$pink = rgb(ff79c6)
$purple = rgb(bd93f9)
$red = rgb(ff5555)
$yellow = rgb(f1fa8c)

general {
    col.active_border = $purple $pink 45deg
    col.inactive_border = $current_line
}

decoration {
    col.shadow = $background
    col.shadow_inactive = $background
}

env = THEME_PRIMARY,$purple
env = THEME_SECONDARY,$pink
env = THEME_ACCENT,$cyan
env = THEME_BACKGROUND,$background
env = THEME_SURFACE,$current_line
env = THEME_TEXT,$foreground
EOF
}

setup_nord() {
    log "Configurando tema Nord..."
    
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/nord.conf" << 'EOF'
# Nord Theme
$nord0 = rgb(2e3440)
$nord1 = rgb(3b4252)
$nord2 = rgb(434c5e)
$nord3 = rgb(4c566a)
$nord4 = rgb(d8dee9)
$nord5 = rgb(e5e9f0)
$nord6 = rgb(eceff4)
$nord7 = rgb(8fbcbb)
$nord8 = rgb(88c0d0)
$nord9 = rgb(81a1c1)
$nord10 = rgb(5e81ac)
$nord11 = rgb(bf616a)
$nord12 = rgb(d08770)
$nord13 = rgb(ebcb8b)
$nord14 = rgb(a3be8c)
$nord15 = rgb(b48ead)

general {
    col.active_border = $nord8 $nord9 45deg
    col.inactive_border = $nord1
}

decoration {
    col.shadow = $nord0
    col.shadow_inactive = $nord0
}

env = THEME_PRIMARY,$nord8
env = THEME_SECONDARY,$nord9
env = THEME_ACCENT,$nord10
env = THEME_BACKGROUND,$nord0
env = THEME_SURFACE,$nord1
env = THEME_TEXT,$nord4
EOF
}

setup_gruvbox() {
    log "Configurando tema Gruvbox..."
    
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/gruvbox.conf" << 'EOF'
# Gruvbox Dark Theme
$bg = rgb(282828)
$bg1 = rgb(3c3836)
$bg2 = rgb(504945)
$bg3 = rgb(665c54)
$bg4 = rgb(7c6f64)
$fg = rgb(ebdbb2)
$fg1 = rgb(ebdbb2)
$fg2 = rgb(d5c4a1)
$fg3 = rgb(bdae93)
$fg4 = rgb(a89984)
$red = rgb(cc241d)
$green = rgb(98971a)
$yellow = rgb(d79921)
$blue = rgb(458588)
$purple = rgb(b16286)
$aqua = rgb(689d6a)
$orange = rgb(d65d0e)

general {
    col.active_border = $orange $yellow 45deg
    col.inactive_border = $bg1
}

decoration {
    col.shadow = $bg
    col.shadow_inactive = $bg
}

env = THEME_PRIMARY,$orange
env = THEME_SECONDARY,$yellow
env = THEME_ACCENT,$blue
env = THEME_BACKGROUND,$bg
env = THEME_SURFACE,$bg1
env = THEME_TEXT,$fg
EOF
}

setup_rose_pine() {
    log "Configurando tema Rose Pine..."
    
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/rose-pine.conf" << 'EOF'
# Rose Pine Theme
$base = rgb(191724)
$surface = rgb(1f1d2e)
$overlay = rgb(26233a)
$muted = rgb(6e6a86)
$subtle = rgb(908caa)
$text = rgb(e0def4)
$love = rgb(eb6f92)
$gold = rgb(f6c177)
$rose = rgb(ebbcba)
$pine = rgb(31748f)
$foam = rgb(9ccfd8)
$iris = rgb(c4a7e7)

general {
    col.active_border = $rose $iris 45deg
    col.inactive_border = $overlay
}

decoration {
    col.shadow = $base
    col.shadow_inactive = $base
}

env = THEME_PRIMARY,$rose
env = THEME_SECONDARY,$iris
env = THEME_ACCENT,$foam
env = THEME_BACKGROUND,$base
env = THEME_SURFACE,$surface
env = THEME_TEXT,$text
EOF
}

setup_everforest() {
    log "Configurando tema Everforest..."
    
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/everforest.conf" << 'EOF'
# Everforest Theme
$bg_dim = rgb(1e2326)
$bg0 = rgb(272e33)
$bg1 = rgb(2e383c)
$bg2 = rgb(374145)
$bg3 = rgb(414b50)
$bg4 = rgb(495156)
$bg5 = rgb(4f5b58)
$fg = rgb(d3c6aa)
$red = rgb(e67e80)
$orange = rgb(e69875)
$yellow = rgb(dbbc7f)
$green = rgb(a7c080)
$aqua = rgb(83c092)
$blue = rgb(7fbbb3)
$purple = rgb(d699b6)

general {
    col.active_border = $green $aqua 45deg
    col.inactive_border = $bg2
}

decoration {
    col.shadow = $bg_dim
    col.shadow_inactive = $bg_dim
}

env = THEME_PRIMARY,$green
env = THEME_SECONDARY,$aqua
env = THEME_ACCENT,$blue
env = THEME_BACKGROUND,$bg0
env = THEME_SURFACE,$bg1
env = THEME_TEXT,$fg
EOF
}

setup_kanagawa() {
    log "Configurando tema Kanagawa..."
    
    cat > "${SCRIPT_DIR}/../../config/hypr/themes/kanagawa.conf" << 'EOF'
# Kanagawa Theme
$fujiWhite = rgb(dcd7ba)
$oldWhite = rgb(c8c093)
$sumiInk0 = rgb(16161d)
$sumiInk1 = rgb(1f1f28)
$sumiInk2 = rgb(2a2a37)
$sumiInk3 = rgb(363646)
$sumiInk4 = rgb(54546d)
$waveBlue1 = rgb(223249)
$waveBlue2 = rgb(2d4f67)
$winterGreen = rgb(2b3328)
$winterYellow = rgb(49443c)
$winterRed = rgb(43242b)
$winterBlue = rgb(252535)
$autumnGreen = rgb(76946a)
$autumnRed = rgb(c73e1d)
$autumnYellow = rgb(dca561)
$samuraiRed = rgb(e82424)
$roninYellow = rgb(ff9e3b)
$waveAqua1 = rgb(6a9589)
$dragonBlue = rgb(658594)
$fujiGray = rgb(727169)
$springViolet1 = rgb(938aa9)
$oniViolet = rgb(957fb8)
$crystalBlue = rgb(7e9cd8)
$springViolet2 = rgb(9cabca)
$springBlue = rgb(7fb4ca)
$lightBlue = rgb(a3d4d5)
$waveAqua2 = rgb(7aa89f)
$springGreen = rgb(98bb6c)
$boatYellow1 = rgb(938056)
$boatYellow2 = rgb(c0a36e)
$carpYellow = rgb(e6c384)
$sakuraPink = rgb(d27e99)
$waveRed = rgb(e46876)
$peachRed = rgb(ff5d62)
$surimiOrange = rgb(ffa066)
$katanaGray = rgb(717c7c)

general {
    col.active_border = $waveAqua1 $springBlue 45deg
    col.inactive_border = $sumiInk3
}

decoration {
    col.shadow = $sumiInk0
    col.shadow_inactive = $sumiInk0
}

env = THEME_PRIMARY,$waveAqua1
env = THEME_SECONDARY,$springBlue
env = THEME_ACCENT,$crystalBlue
env = THEME_BACKGROUND,$sumiInk1
env = THEME_SURFACE,$sumiInk2
env = THEME_TEXT,$fujiWhite
EOF
}

# Función principal del script
main() {
    log "Iniciando configuración de temas..."
    
    # Crear directorios necesarios
    mkdir -p "${SCRIPT_DIR}/../../config/hypr/themes"
    mkdir -p "${SCRIPT_DIR}/../../config/waybar/themes"
    mkdir -p "${SCRIPT_DIR}/../../config/rofi/themes"
    mkdir -p "${SCRIPT_DIR}/../../config/dunst/themes"
    mkdir -p "${SCRIPT_DIR}/../../config/kitty/themes"
    
    # Instalar iconos y cursores
    install_icons_cursors
    
    # Mostrar menú de temas
    show_theme_menu
    
    echo -n "Selecciona un tema [1]: "
    read -r theme_choice
    theme_choice=${theme_choice:-1}
    
    # Aplicar tema seleccionado
    apply_theme "$theme_choice"
    
    # Crear herramientas adicionales
    create_theme_switcher
    create_wallpaper_manager
    
    # Descargar wallpapers por defecto
    if ask_question "¿Descargar wallpapers por defecto?"; then
        download_default_wallpapers
    fi
    
    # Configurar wallpaper inicial
    if ask_question "¿Configurar wallpaper inicial?"; then
        local wallpaper_dir="${HOME}/Pictures/Wallpapers"
        if [[ -d "$wallpaper_dir" ]] && [[ -n "$(ls -A "$wallpaper_dir" 2>/dev/null)" ]]; then
            "${HOME}/.local/bin/wallpaper-manager" random
        else
            info "No hay wallpapers disponibles. Descarga algunos en ~/Pictures/Wallpapers"
        fi
    fi
    
    log "✓ Configuración de temas completada"
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    TEMAS CONFIGURADOS                       ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║  🎨 Tema aplicado: $SELECTED_THEME                                    ║"
    echo "║                                                              ║"
    echo "║  📋 Herramientas disponibles:                                ║"
    echo "║  • theme-switcher - Cambiar temas dinámicamente             ║"
    echo "║  • wallpaper-manager - Gestionar wallpapers                 ║"
    echo "║                                                              ║"
    echo "║  🔧 Comandos útiles:                                         ║"
    echo "║  • theme-switcher list                                      ║"
    echo "║  • theme-switcher set <tema>                                ║"
    echo "║  • wallpaper-manager random                                 ║"
    echo "║  • wallpaper-manager set <ruta>                             ║"
    echo "║                                                              ║"
    echo "║  📁 Directorios importantes:                                 ║"
    echo "║  • ~/.config/hypr/themes/                                   ║"
    echo "║  • ~/Pictures/Wallpapers/                                   ║"
    echo "║                                                              ║"
    echo "║  💡 Reinicia Hyprland para aplicar todos los cambios        ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

 