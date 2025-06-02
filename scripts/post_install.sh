#!/bin/bash

# Post Install Script - Configuración post-instalación mejorada
# Basado en: https://github.com/Darknet/Test/blob/main/Option/post_install.sh

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.config"

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "SUCCESS") echo -e "${CYAN}[SUCCESS]${NC} $message" ;;
    esac
}

show_welcome() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════╗
    ║                 HYPRLAND POST-INSTALL                   ║
    ║              Configuración Final del Sistema            ║
    ╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

setup_environment() {
    log "INFO" "Configurando variables de entorno..."
    
    # Crear archivo de entorno para Hyprland
    cat > "$HOME/.hyprland_env" << 'EOF'
# Hyprland Environment Variables
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland

# Wayland specific
export WAYLAND_DISPLAY=wayland-1
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1

# NVIDIA specific (if applicable)
export LIBVA_DRIVER_NAME=nvidia
export XDG_SESSION_TYPE=wayland
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1

# Gaming
export WINE_FULLSCREEN_INTEGER_SCALING=1
export DXVK_ASYNC=1
export __GL_SHADER_DISK_CACHE=1
export __GL_THREADED_OPTIMIZATIONS=1

# Qt scaling
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Java applications
export _JAVA_AWT_WM_NONREPARENTING=1
EOF

    # Agregar source al .profile si no existe
    if ! grep -q ".hyprland_env" "$HOME/.profile" 2>/dev/null; then
        echo "source ~/.hyprland_env" >> "$HOME/.profile"
    fi
    
    log "SUCCESS" "Variables de entorno configuradas"
}

setup_audio() {
    log "INFO" "Configurando sistema de audio..."
    
    # Detener pulseaudio si está corriendo
    pulseaudio --kill 2>/dev/null || true
    
    # Habilitar servicios de PipeWire
    systemctl --user enable pipewire pipewire-pulse wireplumber
    systemctl --user start pipewire pipewire-pulse wireplumber
    
    # Configurar ALSA para usar PipeWire
    if [ ! -f "$HOME/.asoundrc" ]; then
        cat > "$HOME/.asoundrc" << 'EOF'
pcm.!default {
    type pulse
}
ctl.!default {
    type pulse
}
EOF
    fi
    
    log "SUCCESS" "Audio configurado"
}

setup_fonts() {
    log "INFO" "Configurando fuentes..."
    
    # Crear directorio de fuentes del usuario
    mkdir -p "$HOME/.local/share/fonts"
    
    # Configurar fontconfig
    mkdir -p "$CONFIG_DIR/fontconfig"
    cat > "$CONFIG_DIR/fontconfig/fonts.conf" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <alias>
        <family>sans-serif</family>
        <prefer>
            <family>Inter</family>
            <family>Noto Sans</family>
            <family>DejaVu Sans</family>
        </prefer>
    </alias>
    <alias>
        <family>serif</family>
        <prefer>
            <family>Noto Serif</family>
            <family>DejaVu Serif</family>
        </prefer>
    </alias>
    <alias>
        <family>monospace</family>
        <prefer>
            <family>JetBrainsMono Nerd Font</family>
            <family>Fira Code</family>
            <family>DejaVu Sans Mono</family>
        </prefer>
    </alias>
</fontconfig>
EOF
    
    # Actualizar cache de fuentes
    fc-cache -fv
    
    log "SUCCESS" "Fuentes configuradas"
}

setup_gtk_theme() {
    log "INFO" "Configurando tema GTK..."
    
    # Configurar GTK3
    mkdir -p "$CONFIG_DIR/gtk-3.0"
    cat > "$CONFIG_DIR/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 11
gtk-cursor-theme-name=Adwaita
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
gtk-decoration-layout=close,minimize,maximize:menu
gtk-enable-primary-paste=0
EOF

    # Configurar GTK4
    mkdir -p "$CONFIG_DIR/gtk-4.0"
    cat > "$CONFIG_DIR/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
gtk-decoration-layout=close,minimize,maximize:menu
EOF
    
    log "SUCCESS" "Tema GTK configurado"
}

# Agregar en setup_services()

setup_vpn_services() {
    log "INFO" "Configurando servicios VPN..."
    
    # Habilitar NetworkManager
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
    
    # Configurar vnstat para estadísticas
    if command -v vnstat >/dev/null 2>&1; then
        sudo systemctl enable vnstat
        sudo systemctl start vnstat
    fi
    
    # Crear directorio para configuraciones OpenVPN
    mkdir -p "$HOME/.config/openvpn"
    
    # Configurar permisos para WireGuard
    sudo usermod -a -G wheel "$USER"
    
    log "SUCCESS" "Servicios VPN configurados"
}

setup_mime_types() {
    log "INFO" "Configurando tipos MIME..."
    
    # Configurar aplicaciones por defecto
    cat > "$CONFIG_DIR/mimeapps.list" << 'EOF'
[Default Applications]
text/html=firefox.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
x-scheme-handler/about=firefox.desktop
x-scheme-handler/unknown=firefox.desktop
application/pdf=org.gnome.Evince.desktop
image/jpeg=imv.desktop
image/png=imv.desktop
image/gif=imv.desktop
image/webp=imv.desktop
video/mp4=mpv.desktop
video/x-matroska=mpv.desktop
video/webm=mpv.desktop
audio/mpeg=mpv.desktop
audio/flac=mpv.desktop
audio/x-wav=mpv.desktop
text/plain=code.desktop
application/json=code.desktop
application/javascript=code.desktop
inode/directory=thunar.desktop

[Added Associations]
text/html=firefox.desktop;
x-scheme-handler/http=firefox.desktop;
x-scheme-handler/https=firefox.desktop;
application/pdf=org.gnome.Evince.desktop;
image/jpeg=imv.desktop;
image/png=imv.desktop;
video/mp4=mpv.desktop;
audio/mpeg=mpv.desktop;
text/plain=code.desktop;
inode/directory=thunar.desktop;
EOF
    
    log "SUCCESS" "Tipos MIME configurados"
}

setup_xdg_portals() {
    log "INFO" "Configurando XDG Portals..."
    
    mkdir -p "$CONFIG_DIR/xdg-desktop-portal"
    cat > "$CONFIG_DIR/xdg-desktop-portal/portals.conf" << 'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.FileChooser=gtk
EOF
    
    # Habilitar servicios
    systemctl --user enable xdg-desktop-portal-hyprland
    systemctl --user enable xdg-desktop-portal-gtk
    
    log "SUCCESS" "XDG Portals configurados"
}

setup_security() {
    log "INFO" "Configurando seguridad..."
    
    # Configurar polkit
    if [ ! -f /etc/polkit-1/rules.d/50-default.rules ]; then
        sudo tee /etc/polkit-1/rules.d/50-default.rules > /dev/null << 'EOF'
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
    fi
    
    # Configurar gnome-keyring
    if ! grep -q "gnome-keyring-daemon" "$HOME/.profile" 2>/dev/null; then
        echo 'eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)' >> "$HOME/.profile"
        echo 'export SSH_AUTH_SOCK' >> "$HOME/.profile"
    fi
    
    log "SUCCESS" "Seguridad configurada"
}

setup_gaming() {
    log "INFO" "Configurando optimizaciones para gaming..."
    
    # Configurar límites del sistema para gaming
    if [ ! -f /etc/security/limits.d/99-gaming.conf ]; then
        sudo tee /etc/security/limits.d/99-gaming.conf > /dev/null << 'EOF'
# Gaming optimizations
@games soft nofile 1048576
@games hard nofile 1048576
@games soft nproc unlimited
@games hard nproc unlimited
EOF
    fi
    
    # Configurar sysctl para gaming
    if [ ! -f /etc/sysctl.d/99-gaming.conf ]; then
        sudo tee /etc/sysctl.d/99-gaming.conf > /dev/null << 'EOF'
# Gaming optimizations
vm.max_map_count = 2147483642
fs.file-max = 2097152
kernel.sched_child_runs_first = 0
kernel.sched_autogroup_enabled = 1
kernel.sched_cfs_bandwidth_slice_us = 3000
net.core.default_qdisc = cake
EOF
    fi
    
    log "SUCCESS" "Gaming configurado"
}

setup_autostart() {
    log "INFO" "Configurando aplicaciones de inicio automático..."
    
    # Crear script de autostart para Hyprland
    cat > "$CONFIG_DIR/hypr/autostart.conf" << 'EOF'
# Autostart applications

# Essential services
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = gnome-keyring-daemon --start --components=secrets

# Audio
exec-once = pipewire & pipewire-pulse & wireplumber

# UI Components
exec-once = waybar
exec-once = dunst
exec-once = swww init

# System tray applications
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = [workspace special:scratchpad silent] kitty --class scratchpad

# Set wallpaper
exec-once = swww img ~/Pictures/Wallpapers/tropic_island_day.png --transition-type wipe

# Idle management
exec-once = swayidle -w timeout 300 'swaylock -f -c 000000' timeout 600 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' before-sleep 'swaylock -f -c 000000'
EOF
    
    log "SUCCESS" "Autostart configurado"
}

create_user_dirs() {
    log "INFO" "Creando directorios de usuario..."
    
    # Crear directorios estándar
    mkdir -p "$HOME"/{Desktop,Documents,Downloads,Music,Pictures,Videos,Public,Templates}
    mkdir -p "$HOME/Pictures/Wallpapers"
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share/applications"
    
    # Configurar xdg-user-dirs
    cat > "$CONFIG_DIR/user-dirs.dirs" << 'EOF'
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
EOF
    
    log "SUCCESS" "Directorios creados"
}
setup_fish_config() {
    log "INFO" "Configurando Fish shell avanzado..."
    
    # Configuración avanzada de Fish
    mkdir -p "$CONFIG_DIR/fish/functions"
    
    # Función para actualizar sistema
    cat > "$CONFIG_DIR/fish/functions/update.fish" << 'EOF'
function update --description "Update system packages"
    echo "🔄 Actualizando sistema..."
    sudo pacman -Syu
    
    if command -v yay >/dev/null 2>&1
        echo "🔄 Actualizando AUR..."
        yay -Sua
    end
    
    if command -v flatpak >/dev/null 2>&1
        echo "🔄 Actualizando Flatpak..."
        flatpak update
    end
    
    echo "✅ Sistema actualizado"
end
EOF

    # Función para limpiar sistema
    cat > "$CONFIG_DIR/fish/functions/cleanup.fish" << 'EOF'
function cleanup --description "Clean system cache and orphaned packages"
    echo "🧹 Limpiando sistema..."
    
    # Limpiar cache de pacman
    sudo pacman -Sc --noconfirm
    
    # Remover paquetes huérfanos
    set orphans (pacman -Qtdq)
    if test -n "$orphans"
        sudo pacman -Rns $orphans --noconfirm
    end
    
    # Limpiar cache de usuario
    rm -rf ~/.cache/thumbnails/*
    rm -rf ~/.cache/mesa_shader_cache/*
    
    echo "✅ Sistema limpio"
end
EOF

    # Función para información del sistema
    cat > "$CONFIG_DIR/fish/functions/sysinfo.fish" << 'EOF'
function sysinfo --description "Show system information"
    echo "💻 Información del Sistema"
    echo "========================="
    echo "🖥️  Compositor: Hyprland"
    echo "🐚 Shell: Fish" (fish --version | cut -d' ' -f3)
    echo "🎨 Terminal: Kitty"
    echo "📦 Paquetes:" (pacman -Q | wc -l)
    echo "⚡ Uptime:" (uptime -p)
    echo "💾 Memoria:" (free -h | awk '/^Mem:/ {print $3 "/" $2}')
    echo "💽 Disco:" (df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
end
EOF

    # Configurar aliases útiles
    cat > "$CONFIG_DIR/fish/config.fish" << 'EOF'
# Fish configuration for Hyprland

# Starship prompt
starship init fish | source

# Aliases útiles
alias ll='exa -la --icons'
alias ls='exa --icons'
alias la='exa -a --icons'
alias lt='exa --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias ps='procs'
alias top='btop'
alias vim='nvim'
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'

# Hyprland specific
alias hypr-reload='hyprctl reload'
alias hypr-info='hyprctl info'
alias hypr-clients='hyprctl clients'

# System aliases
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias remove='sudo pacman -Rns'
alias orphans='pacman -Qtdq'

# Funciones útiles
function mkcd --description "Create directory and cd into it"
    mkdir -p $argv[1] && cd $argv[1]
end

function extract --description "Extract various archive formats"
    switch $argv[1]
        case "*.tar.bz2"
            tar xjf $argv[1]
        case "*.tar.gz"
            tar xzf $argv[1]
        case "*.bz2"
            bunzip2 $argv[1]
        case "*.rar"
            unrar x $argv[1]
        case "*.gz"
            gunzip $argv[1]
        case "*.tar"
            tar xf $argv[1]
        case "*.tbz2"
            tar xjf $argv[1]
        case "*.tgz"
            tar xzf $argv[1]
        case "*.zip"
            unzip $argv[1]
        case "*.Z"
            uncompress $argv[1]
        case "*.7z"
            7z x $argv[1]
        case "*"
            echo "No sé cómo extraer '$argv[1]'"
    end
end

# Variables de entorno
set -gx EDITOR nvim
set -gx BROWSER firefox
set -gx TERMINAL kitty

# Configurar PATH
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin

# Configurar zoxide si está instalado
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

# Configurar fzf si está instalado
if command -v fzf >/dev/null 2>&1
    set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
end

# Mensaje de bienvenida
if status is-interactive
    echo "🚀 Bienvenido a Hyprland!"
    echo "Usa 'sysinfo' para ver información del sistema"
    echo "Usa 'update' para actualizar el sistema"
    echo "Usa 'cleanup' para limpiar el sistema"
end
EOF
    
    log "SUCCESS" "Fish configurado"
}

setup_development() {
    log "INFO" "Configurando entorno de desarrollo..."
    
    # Configurar Git si no está configurado
    if ! git config --global user.name >/dev/null 2>&1; then
        echo -e "${YELLOW}Configurar Git:${NC}"
        read -p "Nombre: " git_name
        read -p "Email: " git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
    fi
    
    # Configurar VS Code para Wayland
    mkdir -p "$CONFIG_DIR/code-flags.conf"
    cat > "$CONFIG_DIR/code-flags.conf" << 'EOF'
--enable-features=UseOzonePlatform
--ozone-platform=wayland
--enable-wayland-ime
EOF
    
    log "SUCCESS" "Desarrollo configurado"
}

setup_performance() {
    log "INFO" "Aplicando optimizaciones de rendimiento..."
    
    # Configurar swappiness
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.d/99-swappiness.conf >/dev/null
    
    # Configurar I/O scheduler
    if [ ! -f /etc/udev/rules.d/60-ioschedulers.rules ]; then
        sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null << 'EOF'
# Set I/O scheduler
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
EOF
    fi
    
    log "SUCCESS" "Rendimiento optimizado"
}

setup_backup_system() {
    log "INFO" "Configurando sistema de respaldos..."
    
    # Crear script de backup
    cat > "$HOME/.local/bin/backup-config.sh" << 'EOF'
#!/bin/bash
# Backup configuration script

BACKUP_DIR="$HOME/Backups/config_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Creando respaldo en $BACKUP_DIR..."

# Respaldar configuraciones importantes
cp -r ~/.config/hypr "$BACKUP_DIR/"
cp -r ~/.config/waybar "$BACKUP_DIR/"
cp -r ~/.config/rofi "$BACKUP_DIR/"
cp -r ~/.config/dunst "$BACKUP_DIR/"
cp -r ~/.config/kitty "$BACKUP_DIR/"
cp -r ~/.config/fish "$BACKUP_DIR/"

# Respaldar scripts
cp -r ~/.local/bin "$BACKUP_DIR/"

# Crear archivo de información
cat > "$BACKUP_DIR/backup_info.txt" << EOL
Backup creado: $(date)
Sistema: $(uname -a)
Hyprland: $(hyprctl version | head -1)
Usuario: $USER
EOL

echo "✅ Respaldo completado: $BACKUP_DIR"
EOF
    
    chmod +x "$HOME/.local/bin/backup-config.sh"
    
    log "SUCCESS" "Sistema de respaldos configurado"
}

setup_monitoring() {
    log "INFO" "Configurando monitoreo del sistema..."
    
    # Script de monitoreo de recursos
    cat > "$HOME/.local/bin/system-monitor.sh" << 'EOF'
#!/bin/bash
# System monitoring script

while true; do
    clear
    echo "🖥️  Monitor del Sistema - $(date)"
    echo "=================================="
    
    # CPU
    echo "🔥 CPU:"
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print "   Uso: " usage "%"}'
    
    # Memoria
    echo "💾 Memoria:"
    free -h | awk 'NR==2{printf "   Uso: %s/%s (%.2f%%)\n", $3,$2,$3*100/$2 }'
    
    # Disco
    echo "💽 Disco:"
    df -h / | awk 'NR==2{printf "   Uso: %s/%s (%s)\n", $3,$2,$5}'
    
    # Temperatura (si está disponible)
    if command -v sensors >/dev/null 2>&1; then
        echo "🌡️  Temperatura:"
        sensors | grep "Core 0" | awk '{print "   CPU: " $3}'
    fi
    
    # Procesos top
    echo "📊 Top Procesos:"
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "   %s: %.1f%%\n", $11, $3}'
    
    sleep 2
done
EOF
    
    chmod +x "$HOME/.local/bin/system-monitor.sh"
    
    log "SUCCESS" "Monitoreo configurado"
}

finalize_setup() {
    log "INFO" "Finalizando configuración..."
    
    # Actualizar base de datos de aplicaciones
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    
    # Actualizar cache de iconos
    gtk-update-icon-cache -f -t ~/.local/share/icons 2>/dev/null || true
    
    # Aplicar configuración de sysctl
    sudo sysctl --system >/dev/null 2>&1 || true
    
    # Recargar servicios de usuario
    systemctl --user daemon-reload
    
    # Crear archivo de marca de configuración completada
    touch "$HOME/.hyprland_configured"
    
    log "SUCCESS" "Configuración finalizada"
}

show_completion() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════╗
    ║                 ✅ CONFIGURACIÓN COMPLETA                ║
    ╠══════════════════════════════════════════════════════════╣
    ║                                                          ║
    ║  🎉 ¡Tu sistema Hyprland está listo!                    ║
    ║                                                          ║
    ║  📋 Configuraciones aplicadas:                          ║
    ║     • Variables de entorno                               ║
    ║     • Sistema de audio (PipeWire)                       ║
    ║     • Fuentes y temas                                    ║
    ║     • Aplicaciones por defecto                           ║
    ║     • Optimizaciones de rendimiento                      ║
    ║     • Fish shell avanzado                                ║
    ║     • Sistema de respaldos                               ║
    ║                                                          ║
    ║  🚀 Próximos pasos:                                     ║
    ║     1. Reinicia tu sesión                                ║
    ║     2. Disfruta tu nuevo entorno                         ║
    ║                                                          ║
    ║  💡 Comandos útiles:                                    ║
    ║     • sysinfo - Información del sistema                 ║
    ║     • update - Actualizar sistema                       ║
    ║     • cleanup - Limpiar sistema                         ║
    ║     • backup-config.sh - Respaldar configuración        ║
    ║                                                          ║
    ╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

main() {
    show_welcome
    
    # Verificar si ya se ejecutó
    if [ -f "$HOME/.hyprland_configured" ]; then
        log "WARN" "La configuración post-instalación ya se ejecutó"
        read -p "¿Ejecutar de nuevo? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    log "INFO" "Iniciando configuración post-instalación..."
    
    # Ejecutar configuraciones
    setup_environment
    setup_audio
    setup_fonts
    setup_gtk_theme
    setup_mime_types
    setup_xdg_portals
    setup_security
    setup_gaming
	setup_vpn_services
    setup_autostart
    create_user_dirs
    setup_fish_config
    setup_development
    setup_performance
    setup_backup_system
    setup_monitoring
    finalize_setup
    
    show_completion
    
    log "SUCCESS" "Post-instalación completada. ¡Reinicia tu sesión!"
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

