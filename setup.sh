
## Script de configuración principal mejorado

#!/bin/bash

# Hyprland Dotfiles Setup Script
# Script principal que orquesta toda la instalación

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
LOG_FILE="${SCRIPT_DIR}/logs/setup_$(date +%Y%m%d_%H%M%S).log"

# Crear directorio de logs
mkdir -p "${SCRIPT_DIR}/logs"

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

show_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗  ║
║    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗ ║
║    ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║ ║
║    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║ ║
║    ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝ ║
║    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝  ║
║                                                                        ║
║                    DOTFILES SETUP v2.0                                 ║
║          Combinando lo mejor de JaKooLit y mylinuxforwork              ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_menu() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                      MENÚ DE INSTALACIÓN                    ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  1. Instalación completa (Recomendado)                      ║"
    echo "║  2. Instalación personalizada                               ║"
    echo "║  3. Solo configurar GPU NVIDIA                              ║"
    echo "║  4. Solo configurar GPU híbrida                             ║"
    echo "║  5. Solo instalar Waydroid                                  ║"
    echo "║  6. Actualizar dotfiles existentes                          ║"
    echo "║  7. Restaurar backup                                        ║"
    echo "║  8. Salir                                                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
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

# Detectar sistema y hardware
detect_system() {
    log "Detectando configuración del sistema..."
    
    # Detectar distribución
    if [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
        log "✓ Arch Linux detectado"
    else
        error "Esta configuración está optimizada para Arch Linux"
    fi
    
    # Detectar GPU
    if lspci | grep -i nvidia &>/dev/null; then
        if lspci | grep -i "intel.*graphics\|amd.*graphics" &>/dev/null; then
            GPU_TYPE="hybrid"
            log "✓ Configuración GPU híbrida detectada"
        else
            GPU_TYPE="nvidia"
            log "✓ GPU NVIDIA dedicada detectada"
        fi
    elif lspci | grep -i "intel.*graphics\|amd.*graphics" &>/dev/null; then
        GPU_TYPE="integrated"
        log "✓ GPU integrada detectada"
    else
        GPU_TYPE="unknown"
        warning "No se pudo detectar la GPU"
    fi
    
    # Detectar tipo de sistema
    if [[ -d /proc/acpi/battery ]] || [[ -n $(ls /sys/class/power_supply/BAT* 2>/dev/null) ]]; then
        SYSTEM_TYPE="laptop"
        log "✓ Laptop detectado"
    else
        SYSTEM_TYPE="desktop"
        log "✓ Desktop detectado"
    fi
    
    # Detectar memoria RAM
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    log "✓ RAM detectada: ${RAM_GB}GB"
    
    # Detectar CPU
    CPU_INFO=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    log "✓ CPU: $CPU_INFO"
}

# Configuración personalizada
custom_setup() {
    echo -e "${YELLOW}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  CONFIGURACIÓN PERSONALIZADA                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Configuraciones base
    INSTALL_BASE=true
    INSTALL_HYPRLAND=true
    
    # Configuraciones opcionales
    if ask_question "¿Instalar paquetes de gaming?"; then
        INSTALL_GAMING=true
    else
        INSTALL_GAMING=false
    fi
    
    if ask_question "¿Instalar herramientas de desarrollo?"; then
        INSTALL_DEVELOPMENT=true
    else
        INSTALL_DEVELOPMENT=false
    fi
    
    if ask_question "¿Instalar herramientas multimedia?"; then
        INSTALL_MULTIMEDIA=true
    else
        INSTALL_MULTIMEDIA=false
    fi
    
    if ask_question "¿Instalar Waydroid (Android)?"; then
        INSTALL_WAYDROID=true
    else
        INSTALL_WAYDROID=false
    fi
    
    # Configuración de GPU
    case "$GPU_TYPE" in
        "nvidia")
            if ask_question "¿Configurar GPU NVIDIA?"; then
                SETUP_NVIDIA=true
            else
                SETUP_NVIDIA=false
            fi
            SETUP_HYBRID=false
            ;;
        "hybrid")
            if ask_question "¿Configurar GPU híbrida?"; then
                SETUP_HYBRID=true
                SETUP_NVIDIA=true
            else
                SETUP_HYBRID=false
                SETUP_NVIDIA=false
            fi
            ;;
        *)
            SETUP_NVIDIA=false
            SETUP_HYBRID=false
            ;;
    esac
    
    # Configuraciones adicionales
    if ask_question "¿Instalar temas adicionales?"; then
        INSTALL_THEMES=true
    else
        INSTALL_THEMES=false
    fi
    
    if ask_question "¿Configurar servicios automáticos?"; then
        SETUP_SERVICES=true
    else
        SETUP_SERVICES=false
    fi
}

# Instalación completa
full_setup() {
    log "Configurando instalación completa..."
    
    INSTALL_BASE=true
    INSTALL_HYPRLAND=true
    INSTALL_GAMING=true
    INSTALL_DEVELOPMENT=true
    INSTALL_MULTIMEDIA=true
    INSTALL_WAYDROID=true
    INSTALL_THEMES=true
    SETUP_SERVICES=true
    
    case "$GPU_TYPE" in
        "nvidia")
            SETUP_NVIDIA=true
            SETUP_HYBRID=false
            ;;
        "hybrid")
            SETUP_NVIDIA=true
            SETUP_HYBRID=true
            ;;
        *)
            SETUP_NVIDIA=false
            SETUP_HYBRID=false
            ;;
    esac
}

# Crear backup
create_backup() {
    log "Creando backup de configuraciones existentes..."
    
    local backup_dir="${HOME}/.config/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Directorios a respaldar
    local config_dirs=(
        ".config/hypr"
        ".config/waybar"
        ".config/rofi"
        ".config/kitty"
        ".config/dunst"
        ".config/gtk-3.0"
        ".config/gtk-4.0"
        ".config/qt5ct"
        ".config/qt6ct"
        ".local/share/applications"
        ".local/bin"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "${HOME}/$dir" ]]; then
            cp -r "${HOME}/$dir" "$backup_dir/" 2>/dev/null || true
            log "✓ Backup creado: $dir"
        fi
    done
    
    # Archivos específicos
    local config_files=(
        ".bashrc"
        ".zshrc"
        ".xinitrc"
        ".Xresources"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "${HOME}/$file" ]]; then
            cp "${HOME}/$file" "$backup_dir/" 2>/dev/null || true
            log "✓ Backup creado: $file"
        fi
    done
    
    log "Backup completado en: $backup_dir"
    echo "$backup_dir" > "${SCRIPT_DIR}/.last_backup"
}

# Restaurar backup
restore_backup() {
    echo -e "${YELLOW}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    RESTAURAR BACKUP                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Buscar backups disponibles
    local backup_dirs=($(find "${HOME}" -maxdepth 1 -name ".config" -type d -name "*dotfiles-backup*" 2>/dev/null | sort -r))
    
    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        error "No se encontraron backups disponibles"
    fi
    
    echo "Backups disponibles:"
    for i in "${!backup_dirs[@]}"; do
        echo "$((i+1)). ${backup_dirs[i]}"
    done
    
    echo -n "Selecciona backup a restaurar [1]: "
    read -r backup_choice
    backup_choice=${backup_choice:-1}
    
    local selected_backup="${backup_dirs[$((backup_choice-1))]}"
    
    if [[ ! -d "$selected_backup" ]]; then
        error "Backup seleccionado no válido"
    fi
    
    if ask_question "¿Restaurar backup desde $selected_backup?"; then
        log "Restaurando backup..."
        cp -r "$selected_backup"/* "${HOME}/" 2>/dev/null || true
        log "Backup restaurado exitosamente"
    fi
}

# Ejecutar instalación
run_installation() {
    log "Iniciando proceso de instalación..."
    
    # Crear backup si existen configuraciones
    if [[ -d "${HOME}/.config/hypr" ]]; then
        if ask_question "¿Crear backup de configuraciones existentes?"; then
            create_backup
        fi
    fi
    
    # Ejecutar scripts según configuración
    if [[ "$INSTALL_BASE" == true ]]; then
        log "Ejecutando instalación base..."
        "${SCRIPT_DIR}/install.sh" \
            --gaming="$INSTALL_GAMING" \
            --development="$INSTALL_DEVELOPMENT" \
            --multimedia="$INSTALL_MULTIMEDIA" \
            --waydroid="$INSTALL_WAYDROID" \
            --nvidia="$SETUP_NVIDIA" \
            --hybrid="$SETUP_HYBRID" \
            --themes="$INSTALL_THEMES" \
            --services="$SETUP_SERVICES"
    fi
    
    # Configuraciones específicas de GPU
    if [[ "$SETUP_NVIDIA" == true ]] && [[ "$SETUP_HYBRID" == false ]]; then
        log "Configurando GPU NVIDIA..."
        "${SCRIPT_DIR}/scripts/install/nvidia-setup.sh"
    fi
    
    if [[ "$SETUP_HYBRID" == true ]]; then
        log "Configurando GPU híbrida..."
        "${SCRIPT_DIR}/scripts/install/hybrid-gpu-setup.sh"
    fi
    
    # Waydroid independiente
    if [[ "$INSTALL_WAYDROID" == true ]]; then
        log "Configurando Waydroid..."
        "${SCRIPT_DIR}/scripts/install/waydroid-setup.sh"
    fi
}

# Actualizar dotfiles
update_dotfiles() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   ACTUALIZAR DOTFILES                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Actualizando dotfiles..."
    
    # Actualizar repositorio
    if [[ -d "${SCRIPT_DIR}/.git" ]]; then
        cd "$SCRIPT_DIR"
        git pull origin main || git pull origin master
        log "✓ Repositorio actualizado"
    else
        warning "No es un repositorio git, descargando manualmente..."
        # Aquí podrías añadir lógica para descargar updates
    fi
    
    # Aplicar nuevas configuraciones
    if ask_question "¿Aplicar nuevas configuraciones?"; then
        "${SCRIPT_DIR}/scripts/install/configs-setup.sh"
        log "✓ Configuraciones actualizadas"
    fi
    
    # Actualizar scripts
    if ask_question "¿Actualizar scripts personalizados?"; then
        cp -r "${SCRIPT_DIR}/scripts/user/"* "${HOME}/.local/bin/" 2>/dev/null || true
        chmod +x "${HOME}/.local/bin/"* 2>/dev/null || true
        log "✓ Scripts actualizados"
    fi
}

# Mostrar resumen post-instalación
show_summary() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  INSTALACIÓN COMPLETADA                     ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║  🎉 ¡Hyprland dotfiles instalados exitosamente!             ║"
    echo "║                                                              ║"
    echo "║  📋 Resumen de instalación:                                  ║"
    echo "║  • Sistema: $SYSTEM_TYPE ($DISTRO)                                    ║"
    echo "║  • GPU: $GPU_TYPE                                              ║"
    echo "║  • RAM: ${RAM_GB}GB                                               ║"
    echo "║                                                              ║"
    echo "║  🔧 Componentes instalados:                                  ║"
    [[ "$INSTALL_BASE" == true ]] && echo "║  ✓ Configuración base                                       ║"
    [[ "$INSTALL_GAMING" == true ]] && echo "║  ✓ Paquetes gaming                                          ║"
    [[ "$INSTALL_DEVELOPMENT" == true ]] && echo "║  ✓ Herramientas desarrollo                                  ║"
    [[ "$INSTALL_MULTIMEDIA" == true ]] && echo "║  ✓ Herramientas multimedia                                  ║"
    [[ "$INSTALL_WAYDROID" == true ]] && echo "║  ✓ Waydroid (Android)                                       ║"
    [[ "$SETUP_NVIDIA" == true ]] && echo "║  ✓ Configuración NVIDIA                                     ║"
    [[ "$SETUP_HYBRID" == true ]] && echo "║  ✓ Configuración GPU híbrida                                ║"
    echo "║                                                              ║"
    echo "║  📚 Próximos pasos:                                          ║"
    echo "║  1. Reinicia el sistema                                      ║"
    echo "║  2. Selecciona Hyprland en el login manager                 ║"
    echo "║  3. Presiona Super+? para ver atajos de teclado             ║"
    echo "║  4. Revisa la documentación en docs/                        ║"
    echo "║                                                              ║"
    echo "║  🆘 Soporte:                                                 ║"
    echo "║  • Logs: $LOG_FILE ║"
    echo "║  • Documentación: docs/README.md                            ║"
    echo "║  • Troubleshooting: docs/TROUBLESHOOTING.md                 ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función principal
main() {
    # Verificar que se ejecuta desde el directorio correcto
    if [[ ! -f "${SCRIPT_DIR}/install.sh" ]]; then
        error "Ejecuta este script desde el directorio de dotfiles"
    fi
    
    show_banner
    detect_system
    
    while true; do
        show_menu
        echo -n "Selecciona una opción [1]: "
        read -r choice
        choice=${choice:-1}
        
        case $choice in
            1)
                log "Instalación completa seleccionada"
                full_setup
                run_installation
                show_summary
                break
                ;;
            2)
                log "Instalación personalizada seleccionada"
                custom_setup
                run_installation
                show_summary
                break
                ;;
            3)
                if [[ "$GPU_TYPE" == "nvidia" ]] || [[ "$GPU_TYPE" == "hybrid" ]]; then
                    log "Configurando solo GPU NVIDIA"
                    "${SCRIPT_DIR}/scripts/install/nvidia-setup.sh"
                else
                    error "No se detectó GPU NVIDIA compatible"
                fi
                break
                ;;
            4)
                if [[ "$GPU_TYPE" == "hybrid" ]]; then
                    log "Configurando solo GPU híbrida"
                    "${SCRIPT_DIR}/scripts/install/hybrid-gpu-setup.sh"
                else
                    error "No se detectó configuración GPU híbrida"
                fi
                break
                ;;
            5)
                log "Instalando solo Waydroid"
                "${SCRIPT_DIR}/scripts/install/waydroid-setup.sh"
                break
                ;;
            6)
                update_dotfiles
                break
                ;;
            7)
                restore_backup
                break
                ;;
            8)
                log "Saliendo del instalador"
                exit 0
                ;;
            *)
                warning "Opción no válida. Intenta de nuevo."
                ;;
        esac
    done
}

# Manejo de errores y señales
trap 'error "Instalación interrumpida. Revisa los logs en: $LOG_FILE"' ERR INT TERM

# Verificar dependencias mínimas
check_dependencies() {
    local deps=("git" "curl" "wget" "base-devel")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null && ! pacman -Qi "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Dependencias faltantes: ${missing[*]}. Instálalas con: sudo pacman -S ${missing[*]}"
    fi
}

# Verificar permisos
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        error "No ejecutes este script como root"
    fi
    
    if ! sudo -n true 2>/dev/null; then
        info "Se requieren permisos de sudo para la instalación"
        sudo -v || error "Permisos de sudo requeridos"
    fi
}

# Verificar espacio en disco
check_disk_space() {
    local available_space=$(df "${HOME}" | awk 'NR==2 {print $4}')
    local required_space=5242880  # 5GB en KB
    
    if [[ $available_space -lt $required_space ]]; then
        warning "Espacio en disco bajo. Se requieren al menos 5GB libres"
        if ! ask_question "¿Continuar de todos modos?"; then
            exit 0
        fi
    fi
}

# Verificaciones previas
pre_checks() {
    log "Realizando verificaciones previas..."
    check_dependencies
    check_permissions
    check_disk_space
    log "✓ Verificaciones completadas"
}

# Ejecutar función principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pre_checks
    main "$@"
fi
