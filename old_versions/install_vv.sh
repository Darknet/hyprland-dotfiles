#!/bin/bash

# Hyprland Dotfiles Installer - Combinando lo mejor de JaKooLit y mylinuxforwork
# Version: 2.0

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/logs/install_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="${SCRIPT_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
CONFIG_DIR="${HOME}/.config"

# Crear directorios necesarios
mkdir -p "${SCRIPT_DIR}/logs" "${BACKUP_DIR}"

# Funciones de utilidad
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

# Detectar sistema
detect_system() {
    if [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
        PKG_MANAGER="pacman"
        AUR_HELPER=""
    else
        error "Sistema no soportado. Solo Arch Linux es compatible."
    fi
    
    # Detectar GPU
    if lspci | grep -i nvidia &>/dev/null; then
        GPU_TYPE="nvidia"
    elif lspci | grep -i amd &>/dev/null; then
        GPU_TYPE="amd"
    else
        GPU_TYPE="intel"
    fi
    
    # Detectar si es laptop
    if [[ -d /proc/acpi/battery ]] || [[ -n $(ls /sys/class/power_supply/BAT* 2>/dev/null) ]]; then
        IS_LAPTOP=true
    else
        IS_LAPTOP=false
    fi
    
    log "Sistema detectado: $DISTRO, GPU: $GPU_TYPE, Laptop: $IS_LAPTOP"
}

# Instalar AUR helper
install_aur_helper() {
    if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
        info "Instalando AUR helper..."
        
        # Instalar dependencias para compilar
        sudo pacman -S --needed --noconfirm base-devel git
        
        # Instalar yay
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        
        AUR_HELPER="yay"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    else
        AUR_HELPER="paru"
    fi
    
    log "AUR helper configurado: $AUR_HELPER"
}

# Función para preguntas interactivas
ask_question() {
    local question="$1"
    local default="${2:-n}"
    local response
    
    echo -e "${CYAN}$question [y/N]: ${NC}"
    read -r response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Configuración interactiva
interactive_setup() {
    echo -e "${PURPLE}=== Configuración de Instalación ===${NC}"
    
    # Preguntar por componentes
    INSTALL_GAMING=$(ask_question "¿Instalar paquetes para gaming?")
    INSTALL_DEVELOPMENT=$(ask_question "¿Instalar herramientas de desarrollo?")
    INSTALL_MULTIMEDIA=$(ask_question "¿Instalar herramientas multimedia?")
    INSTALL_WAYDROID=$(ask_question "¿Instalar Waydroid (Android en Linux)?")
    
    # Configuración específica de GPU
    if [[ "$GPU_TYPE" == "nvidia" ]]; then
        INSTALL_NVIDIA=$(ask_question "¿Instalar drivers NVIDIA para Wayland/Hyprland?")
        if [[ "$IS_LAPTOP" == true ]]; then
            HYBRID_GPU=$(ask_question "¿Configurar GPU híbrida (NVIDIA Optimus)?")
        fi
    fi
    
    # Tema por defecto
    echo -e "${CYAN}Selecciona tema por defecto:${NC}"
    echo "1) Catppuccin Mocha (Oscuro)"
    echo "2) Catppuccin Latte (Claro)"
    echo "3) Tokyo Night"
    echo "4) Gruvbox"
    read -p "Opción [1]: " THEME_CHOICE
    THEME_CHOICE=${THEME_CHOICE:-1}
    
    case $THEME_CHOICE in
        1) DEFAULT_THEME="catppuccin-mocha" ;;
        2) DEFAULT_THEME="catppuccin-latte" ;;
        3) DEFAULT_THEME="tokyo-night" ;;
        4) DEFAULT_THEME="gruvbox" ;;
        *) DEFAULT_THEME="catppuccin-mocha" ;;
    esac
}

# Instalar paquetes base
install_base_packages() {
    log "Instalando paquetes base..."
    
    local base_packages=(
        # Hyprland y componentes base
        "hyprland" "hyprpaper" "hyprlock" "hypridle" "hyprpicker"
        "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk"
        
        # Wayland essentials
        "wayland" "wayland-protocols" "wlroots"
        
        # Audio
        "pipewire" "pipewire-alsa" "pipewire-pulse" "pipewire-jack"
        "wireplumber" "pavucontrol" "pamixer"
        
        # Aplicaciones esenciales
        "waybar" "rofi-wayland" "dunst" "swww" "swaylock-effects"
        "wlogout" "grim" "slurp" "wl-clipboard" "cliphist"
        
        # Terminal y shell
        "kitty" "fish" "starship" "eza" "bat" "fd" "ripgrep"
        
        # Archivos y sistema
        "thunar" "thunar-archive-plugin" "file-roller"
        "polkit-gnome" "gnome-keyring"
        
        # Fuentes
        "ttf-fira-code" "ttf-jetbrains-mono" "noto-fonts" "noto-fonts-emoji"
        
        # Herramientas de sistema
        "btop" "neofetch" "tree" "wget" "curl" "git" "vim" "nano"
    )
    
    # Instalar paquetes oficiales
    sudo pacman -S --needed --noconfirm "${base_packages[@]}"
    
    # Paquetes AUR
    local aur_packages=(
        "swww" "hyprpicker" "wlogout" "cliphist"
        "ttf-meslo-nerd-font-powerlevel10k"
        "visual-studio-code-bin"
    )
    
    $AUR_HELPER -S --needed --noconfirm "${aur_packages[@]}"
}

# Configurar GPU NVIDIA
setup_nvidia() {
    if [[ "$GPU_TYPE" == "nvidia" && "$INSTALL_NVIDIA" == true ]]; then
        log "Configurando NVIDIA para Wayland..."
        
        # Instalar drivers NVIDIA
        sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
        
        # Configurar variables de entorno para Wayland
        cat > "${SCRIPT_DIR}/config/hypr/conf/nvidia.conf" << 'EOF'
# NVIDIA-specific configuration
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1

# NVIDIA Wayland fixes
env = NVIDIA_MODESET,1
env = NVIDIA_DRM_MODESET,1
EOF
        
        # Configurar GPU híbrida si es laptop
        if [[ "$IS_LAPTOP" == true && "$HYBRID_GPU" == true ]]; then
            log "Configurando GPU híbrida..."
            
            # Instalar optimus-manager o envycontrol
            $AUR_HELPER -S --needed --noconfirm envycontrol
            
            # Configurar scripts para cambio de GPU
            cp "${SCRIPT_DIR}/scripts/gpu-switch.sh" "${HOME}/.local/bin/"
            chmod +x "${HOME}/.local/bin/gpu-switch.sh"
        fi
    fi
}

# Instalar Waydroid
setup_waydroid() {
    if [[ "$INSTALL_WAYDROID" == true ]]; then
        log "Instalando Waydroid..."
        
        # Instalar Waydroid
        $AUR_HELPER -S --needed --noconfirm waydroid python-pyclip
        
        # Configurar Waydroid
        sudo systemctl enable --now waydroid-container
        
        # Ejecutar script de configuración
        "${SCRIPT_DIR}/scripts/install/waydroid-setup.sh"
    fi
}

# Hacer backup de configuraciones existentes
backup_configs() {
    log "Creando backup de configuraciones existentes..."
    
    local configs_to_backup=(
        ".config/hypr"
        ".config/waybar"
        ".config/rofi"
        ".config/kitty"
        ".config/dunst"
        ".config/fish"
    )
    
    for config in "${configs_to_backup[@]}"; do
        if [[ -d "${HOME}/${config}" ]]; then
            cp -r "${HOME}/${config}" "${BACKUP_DIR}/"
            log "Backup creado: ${config}"
        fi
    done
}

# Instalar configuraciones
install_configs() {
    log "Instalando configuraciones..."
    
    # Crear directorios necesarios
    mkdir -p "${HOME}/.config" "${HOME}/.local/bin" "${HOME}/.local/share"
    
    # Copiar configuraciones base
    cp -r "${SCRIPT_DIR}/config/"* "${HOME}/.config/"
    
    # Copiar scripts
    cp -r "${SCRIPT_DIR}/scripts/"* "${HOME}/.local/bin/"
    find "${HOME}/.local/bin" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Configurar tema por defecto
    "${SCRIPT_DIR}/scripts/themes/set-theme.sh" "$DEFAULT_THEME"
    
    # Configurar shell
    if ! grep -q "/usr/bin/fish" /etc/shells; then
        echo "/usr/bin/fish" | sudo tee -a /etc/shells
    fi
    chsh -s /usr/bin/fish
    
    log "Configuraciones instaladas correctamente"
}

# Configurar servicios del sistema
setup_services() {
    log "Configurando servicios del sistema..."
    
    # Habilitar servicios necesarios
    sudo systemctl enable --now bluetooth
    sudo systemctl --user enable --now pipewire pipewire-pulse wireplumber
    
    # Configurar autologin (opcional)
    if ask_question "¿Configurar autologin?"; then
        sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
        cat << EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $USER %I \$TERM
EOF
    fi
}

# Post-instalación
post_install() {
    log "Ejecutando tareas post-instalación..."
    
    # Actualizar base de datos de fuentes
    fc-cache -fv
    
    # Configurar mimeapps
    cp "${SCRIPT_DIR}/config/mimeapps/mimeapps.list" "${HOME}/.config/"
    
    # Ejecutar script post-instalación personalizado
    if [[ -f "${SCRIPT_DIR}/scripts/post_install.sh" ]]; then
        "${SCRIPT_DIR}/scripts/post_install.sh"
    fi
    
    log "Instalación completada exitosamente!"
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    INSTALACIÓN COMPLETADA                   ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  • Reinicia el sistema para aplicar todos los cambios       ║"
    echo "║  • Usa 'Super + Return' para abrir terminal                 ║"
    echo "║  • Usa 'Super + D' para el launcher de aplicaciones         ║"
    echo "║  • Revisa los logs en: logs/                                ║"
    echo "║  • Backups guardados en: backups/                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función principal
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              HYPRLAND DOTFILES INSTALLER v2.0               ║"
    echo "║          Combinando lo mejor de JaKooLit y mylinuxforwork    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Verificar que se ejecuta en Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "Este script solo funciona en Arch Linux"
    fi
    
    # Verificar que no se ejecuta como root
    if [[ $EUID -eq 0 ]]; then
        error "No ejecutes este script como root"
    fi
    
    log "Iniciando instalación de Hyprland Dotfiles..."
    
    detect_system
    interactive_setup
    install_aur_helper
    backup_configs
    install_base_packages
    
       # Instalar paquetes opcionales
    if [[ "$INSTALL_GAMING" == true ]]; then
        "${SCRIPT_DIR}/scripts/install/gaming-setup.sh"
    fi
    
    if [[ "$INSTALL_DEVELOPMENT" == true ]]; then
        "${SCRIPT_DIR}/scripts/install/development-setup.sh"
    fi
    
    if [[ "$INSTALL_MULTIMEDIA" == true ]]; then
        "${SCRIPT_DIR}/scripts/install/multimedia-setup.sh"
    fi
    
    setup_nvidia
    setup_waydroid
    install_configs
    setup_services
    post_install
}

# Manejo de errores
trap 'error "Script interrumpido. Revisa los logs en: $LOG_FILE"' ERR INT TERM

# Ejecutar función principal
main "$@"
