#!/bin/bash

# NVIDIA Setup Script para Hyprland
# Configuración optimizada para Wayland

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../../logs/nvidia_setup_$(date +%Y%m%d_%H%M%S).log"

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

# Detectar GPU NVIDIA
detect_nvidia() {
    if ! lspci | grep -i nvidia &>/dev/null; then
        error "No se detectó GPU NVIDIA en el sistema"
    fi
    
    # Obtener información de la GPU
    GPU_INFO=$(lspci | grep -i nvidia | head -1)
    log "GPU detectada: $GPU_INFO"
    
    # Detectar generación de GPU
    if echo "$GPU_INFO" | grep -E "(RTX 40|RTX 30|GTX 16)" &>/dev/null; then
        GPU_GENERATION="modern"
    elif echo "$GPU_INFO" | grep -E "(RTX 20|GTX 10)" &>/dev/null; then
        GPU_GENERATION="recent"
    else
        GPU_GENERATION="legacy"
        warning "GPU antigua detectada. Algunos features pueden no estar disponibles."
    fi
}

# Instalar drivers NVIDIA
install_nvidia_drivers() {
    log "Instalando drivers NVIDIA..."
    
    # Remover drivers nouveau si están presentes
    if lsmod | grep nouveau &>/dev/null; then
        warning "Removiendo drivers nouveau..."
        echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
        echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
        sudo mkinitcpio -P
    fi
    
    # Instalar paquetes NVIDIA
    local nvidia_packages=(
        "nvidia"
        "nvidia-utils" 
        "nvidia-settings"
        "lib32-nvidia-utils"
        "opencl-nvidia"
        "cuda"
    )
    
    # Para GPUs modernas, instalar driver beta si está disponible
    if [[ "$GPU_GENERATION" == "modern" ]]; then
        if pacman -Ss nvidia-beta &>/dev/null; then
            nvidia_packages[0]="nvidia-beta"
            info "Instalando driver NVIDIA beta para GPU moderna"
        fi
    fi
    
    sudo pacman -S --needed --noconfirm "${nvidia_packages[@]}"
    
    # Instalar paquetes AUR adicionales
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        error "No se encontró helper de AUR (yay o paru)"
    fi
    
    $AUR_HELPER -S --needed --noconfirm nvidia-tweaks
}

# Configurar kernel parameters
configure_kernel_params() {
    log "Configurando parámetros del kernel..."
    
    # Backup del grub config
    sudo cp /etc/default/grub /etc/default/grub.backup
    
    # Parámetros NVIDIA para Wayland
    local nvidia_params="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"
    
    # Añadir parámetros si no existen
    if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$nvidia_params /" /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        log "Parámetros del kernel actualizados"
    fi
}

# Configurar variables de entorno
configure_environment() {
    log "Configurando variables de entorno para Wayland..."
    
    # Crear archivo de configuración NVIDIA para Hyprland
    mkdir -p "${SCRIPT_DIR}/../../config/hypr/conf"
    
    cat > "${SCRIPT_DIR}/../../config/hypr/conf/nvidia.conf" << 'EOF'
# NVIDIA Configuration for Hyprland
# Variables de entorno específicas para NVIDIA + Wayland

env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER_ALLOW_SOFTWARE,1

# NVIDIA DRM
env = NVIDIA_MODESET,1
env = NVIDIA_DRM_MODESET,1

# Electron apps
env = ELECTRON_OZONE_PLATFORM_HINT,wayland

# Qt
env = QT_QPA_PLATFORM,wayland
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1

# Firefox
env = MOZ_ENABLE_WAYLAND,1

# CUDA
env = CUDA_CACHE_PATH,$HOME/.cache/nv

# Vulkan
env = VK_DRIVER_FILES,/usr/share/vulkan/icd.d/nvidia_icd.json
EOF

    # Configurar variables globales del sistema
    cat > /tmp/nvidia-wayland.conf << 'EOF'
# NVIDIA Wayland Environment Variables
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
NVIDIA_MODESET=1
NVIDIA_DRM_MODESET=1
EOF
    
    sudo mv /tmp/nvidia-wayland.conf /etc/environment.d/
    
    log "Variables de entorno configuradas"
}

# Configurar Hyprland específicamente para NVIDIA
configure_hyprland_nvidia() {
    log "Configurando Hyprland para NVIDIA..."
    
    # Crear configuración específica de renderizado
    cat > "${SCRIPT_DIR}/../../config/hypr/conf/nvidia-render.conf" << 'EOF'
# NVIDIA Rendering Configuration

# Renderer settings
render {
    explicit_sync = 2
    explicit_sync_kms = 2
    direct_scanout = true
}

# OpenGL settings
opengl {
    nvidia_anti_flicker = true
    force_introspection = 2
}

# Cursor settings
cursor {
    no_hardware_cursors = true
    allow_dumb_copy = true
}

# Performance optimizations
misc {
    vrr = 1
    vfr = true
    no_direct_scanout = false
}
EOF

    # Añadir source a hyprland.conf si no existe
    local hypr_config="${SCRIPT_DIR}/../../config/hypr/hyprland.conf"
    if [[ -f "$hypr_config" ]] && ! grep -q "nvidia.conf" "$hypr_config"; then
        echo "" >> "$hypr_config"
        echo "# NVIDIA Configuration" >> "$hypr_config"
        echo "source = ~/.config/hypr/conf/nvidia.conf" >> "$hypr_config"
        echo "source = ~/.config/hypr/conf/nvidia-render.conf" >> "$hypr_config"
    fi
}

# Configurar aplicaciones para NVIDIA
configure_applications() {
    log "Configurando aplicaciones para NVIDIA..."
    
    # Firefox
    mkdir -p "${HOME}/.mozilla/firefox"
    if [[ -d "${HOME}/.mozilla/firefox" ]]; then
        cat > "${HOME}/.mozilla/firefox/user.js" << 'EOF'
// NVIDIA + Wayland optimizations
user_pref("gfx.webrender.all", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.enabled", true);
user_pref("layers.acceleration.force-enabled", true);
user_pref("gfx.webrender.compositor.force-enabled", true);
EOF
    fi
    
    # VSCode
    mkdir -p "${HOME}/.config/Code/User"
    cat > "${HOME}/.config/Code/User/settings.json" << 'EOF'
{
    "window.titleBarStyle": "custom",
    "window.menuBarVisibility": "toggle",
    "editor.fontFamily": "'JetBrains Mono', 'Fira Code', monospace",
    "terminal.integrated.fontFamily": "'JetBrains Mono'",
    "workbench.colorTheme": "Catppuccin Mocha"
}
EOF

    # Crear script de lanzamiento optimizado para apps
    mkdir -p "${HOME}/.local/bin"
    cat > "${HOME}/.local/bin/nvidia-app-launcher" << 'EOF'
#!/bin/bash
# Launcher optimizado para aplicaciones con NVIDIA

export LIBVA_DRIVER_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Ejecutar aplicación con optimizaciones
exec "$@"
EOF
    chmod +x "${HOME}/.local/bin/nvidia-app-launcher"
}

# Crear scripts de utilidad
create_utility_scripts() {
    log "Creando scripts de utilidad NVIDIA..."
    
    # Script de información GPU
    cat > "${HOME}/.local/bin/nvidia-info" << 'EOF'
#!/bin/bash
# Información detallada de GPU NVIDIA

echo "=== NVIDIA GPU Information ==="
nvidia-smi
echo ""
echo "=== Driver Version ==="
cat /proc/driver/nvidia/version
echo ""
echo "=== GPU Usage ==="
nvidia-smi --query-gpu=utilization.gpu,utilization.memory,temperature.gpu --format=csv
echo ""
echo "=== Wayland Status ==="
echo "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
EOF
    chmod +x "${HOME}/.local/bin/nvidia-info"
    
    # Script de optimización de rendimiento
    cat > "${HOME}/.local/bin/nvidia-performance" << 'EOF'
#!/bin/bash
# Optimización de rendimiento NVIDIA

case "$1" in
    "max")
        sudo nvidia-smi -pm 1
        sudo nvidia-smi -pl 300
        echo "Modo rendimiento máximo activado"
        ;;
    "balanced")
        sudo nvidia-smi -pm 1
        sudo nvidia-smi -pl 250
        echo "Modo balanceado activado"
        ;;
    "power-save")
        sudo nvidia-smi -pm 0
        echo "Modo ahorro de energía activado"
        ;;
    *)
        echo "Uso: nvidia-performance [max|balanced|power-save]"
        ;;
esac
EOF
    chmod +x "${HOME}/.local/bin/nvidia-performance"
}

# Configurar servicios
configure_services() {
    log "Configurando servicios NVIDIA..."
    
    # Crear servicio para configuración automática
    cat > /tmp/nvidia-setup.service << 'EOF'
[Unit]
Description=NVIDIA Setup Service
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-smi -pm 1
ExecStart=/usr/bin/nvidia-modprobe -u -c=0
User=root

[Install]
WantedBy=graphical-session.target
EOF
    
    sudo mv /tmp/nvidia-setup.service /etc/systemd/system/
    sudo systemctl enable nvidia-setup.service
}

# Verificar instalación
verify_installation() {
    log "Verificando instalación NVIDIA..."
    
    # Verificar driver
    if nvidia-smi &>/dev/null; then
        log "✓ Driver NVIDIA funcionando correctamente"
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    else
        error "✗ Driver NVIDIA no está funcionando"
    fi
    
    # Verificar DRM
    if [[ -e /dev/dri/card0 ]]; then
        log "✓ DRM disponible"
    else
        warning "✗ DRM no disponible"
    fi
    
    # Verificar Wayland
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        log "✓ Sesión Wayland activa"
    else
        info "ℹ Sesión Wayland no activa (normal durante instalación)"
    fi
}

# Función principal
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    NVIDIA SETUP SCRIPT                      ║"
    echo "║              Configuración optimizada para Wayland          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    detect_nvidia
    install_nvidia_drivers
    configure_kernel_params
    configure_environment
    configure_hyprland_nvidia
    configure_applications
    create_utility_scripts
    configure_services
    verify_installation
    
    log "Configuración NVIDIA completada"
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 NVIDIA SETUP COMPLETADO                     ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  IMPORTANTE: Reinicia el sistema para aplicar los cambios   ║"
    echo "║                                                              ║"
    echo "║  Comandos útiles:                                            ║"
    echo "║  • nvidia-info          - Información de la GPU             ║"
    echo "║  • nvidia-performance   - Gestión de rendimiento            ║"
    echo "║  • nvidia-smi           - Monitor de GPU                    ║"
    echo "║                                                              ║"
    echo "║  Si tienes problemas:                                       ║"
    echo "║  • Verifica que Wayland esté activo: echo \$XDG_SESSION_TYPE ║"
    echo "║  • Revisa logs: journalctl -xe                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Manejo de errores
trap 'error "Script NVIDIA interrumpido. Revisa los logs en: $LOG_FILE"' ERR INT TERM

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
