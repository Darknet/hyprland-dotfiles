#!/bin/bash

# Hybrid GPU Setup Script
# Configuración para laptops con GPU híbrida (Intel/AMD + NVIDIA)

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
LOG_FILE="${SCRIPT_DIR}/../../logs/hybrid_gpu_setup_$(date +%Y%m%d_%H%M%S).log"

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

# Detectar configuración de GPU híbrida
detect_hybrid_setup() {
    log "Detectando configuración de GPU híbrida..."
    
    # Detectar GPU integrada
    if lspci | grep -i "intel.*graphics" &>/dev/null; then
        IGPU_TYPE="intel"
        IGPU_INFO=$(lspci | grep -i "intel.*graphics" | head -1)
    elif lspci | grep -i "amd.*graphics\|radeon" &>/dev/null; then
        IGPU_TYPE="amd"
        IGPU_INFO=$(lspci | grep -i "amd.*graphics\|radeon" | head -1)
    else
        error "No se detectó GPU integrada compatible"
    fi
    
    # Detectar GPU NVIDIA
    if lspci | grep -i nvidia &>/dev/null; then
        DGPU_INFO=$(lspci | grep -i nvidia | head -1)
        log "GPU Integrada: $IGPU_INFO"
        log "GPU Dedicada: $DGPU_INFO"
    else
        error "No se detectó GPU NVIDIA"
    fi
    
    # Detectar tecnología híbrida
    if lspci | grep -i "3d controller.*nvidia" &>/dev/null; then
        HYBRID_TYPE="optimus"
        log "Tecnología detectada: NVIDIA Optimus"
    elif [[ -d /sys/class/drm/card1 ]]; then
        HYBRID_TYPE="prime"
        log "Tecnología detectada: NVIDIA PRIME"
    else
        HYBRID_TYPE="manual"
        log "Configuración manual requerida"
    fi
}

# Instalar herramientas de gestión híbrida
install_hybrid_tools() {
    log "Instalando herramientas de gestión híbrida..."
    
    # Determinar helper AUR
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        error "No se encontró helper de AUR (yay o paru)"
    fi
    
    # Instalar paquetes base
    sudo pacman -S --needed --noconfirm \
        mesa lib32-mesa \
        vulkan-intel lib32-vulkan-intel \
        intel-media-driver \
        switcheroo-control
    
    # Herramientas específicas según el tipo
    case "$HYBRID_TYPE" in
        "optimus"|"prime")
            # EnvyControl - Herramienta moderna para gestión híbrida
            $AUR_HELPER -S --needed --noconfirm envycontrol
            
            # Optimus Manager como alternativa
            if ask_question "¿Instalar también Optimus Manager como alternativa?"; then
                $AUR_HELPER -S --needed --noconfirm optimus-manager optimus-manager-qt
            fi
            ;;
        "manual")
            # Solo EnvyControl para configuración manual
            $AUR_HELPER -S --needed --noconfirm envycontrol
            ;;
    esac
    
    # Herramientas adicionales
    $AUR_HELPER -S --needed --noconfirm \
        gpu-switch \
        nvidia-prime \
        glxinfo \
        vulkan-tools
}

# Configurar EnvyControl
configure_envycontrol() {
    log "Configurando EnvyControl..."
    
    # Configurar modo híbrido por defecto
    echo -e "${CYAN}Selecciona el modo de GPU por defecto:${NC}"
    echo "1) Híbrido (Recomendado - Mejor batería)"
    echo "2) NVIDIA (Máximo rendimiento)"
    echo "3) Integrada (Máximo ahorro de batería)"
    read -p "Opción [1]: " GPU_MODE
    GPU_MODE=${GPU_MODE:-1}
    
    case $GPU_MODE in
        1)
            sudo envycontrol -s hybrid --dm gdm --force
            DEFAULT_MODE="hybrid"
            ;;
        2)
            sudo envycontrol -s nvidia --dm gdm --force
            DEFAULT_MODE="nvidia"
            ;;
        3)
            sudo envycontrol -s integrated --dm gdm --force
            DEFAULT_MODE="integrated"
            ;;
        *)
            sudo envycontrol -s hybrid --dm gdm --force
            DEFAULT_MODE="hybrid"
            ;;
    esac
    
    log "Modo GPU configurado: $DEFAULT_MODE"
}

# Crear scripts de gestión
create_gpu_scripts() {
    log "Creando scripts de gestión de GPU..."
    
    mkdir -p "${HOME}/.local/bin"
    
    # Script principal de cambio de GPU
    cat > "${HOME}/.local/bin/gpu-switch" << 'EOF'
#!/bin/bash

# GPU Switch Script - Gestión de GPU híbrida

SCRIPT_NAME="GPU Switch"
NOTIFY_TIMEOUT=5000

notify() {
    if command -v notify-send &>/dev/null; then
        notify-send "$SCRIPT_NAME" "$1" -t $NOTIFY_TIMEOUT
    fi
    echo "$1"
}

show_current() {
    echo "=== Estado Actual de GPU ==="
    
    # EnvyControl status
    if command -v envycontrol &>/dev/null; then
        echo "Modo EnvyControl: $(envycontrol --query 2>/dev/null || echo 'No disponible')"
    fi
    
    # GPU activa
    if command -v glxinfo &>/dev/null; then
        echo "Renderer activo: $(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs)"
    fi
    
    # Procesos usando GPU NVIDIA
    if command -v nvidia-smi &>/dev/null; then
        echo ""
        echo "=== Procesos usando NVIDIA ==="
        nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader,nounits 2>/dev/null || echo "Ninguno"
    fi
}

switch_to_nvidia() {
    notify "Cambiando a GPU NVIDIA..."
    if sudo envycontrol -s nvidia --dm gdm; then
        notify "GPU NVIDIA activada. Reinicia para aplicar cambios."
    else
        notify "Error al cambiar a GPU NVIDIA"
        exit 1
    fi
}

switch_to_hybrid() {
    notify "Cambiando a modo híbrido..."
    if sudo envycontrol -s hybrid --dm gdm; then
        notify "Modo híbrido activado. Reinicia para aplicar cambios."
    else
        notify "Error al cambiar a modo híbrido"
        exit 1
    fi
}

switch_to_integrated() {
    notify "Cambiando a GPU integrada..."
    if sudo envycontrol -s integrated --dm gdm; then
        notify "GPU integrada activada. Reinicia para aplicar cambios."
    else
        notify "Error al cambiar a GPU integrada"
        exit 1
    fi
}

run_with_nvidia() {
    if [[ $# -eq 0 ]]; then
        echo "Uso: gpu-switch run <comando>"
        exit 1
    fi
    
    notify "Ejecutando $1 con GPU NVIDIA..."
    __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia "$@"
}

show_help() {
    echo "GPU Switch - Gestión de GPU híbrida"
    echo ""
    echo "Uso: gpu-switch [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  status      Mostrar estado actual"
    echo "  nvidia      Cambiar a GPU NVIDIA"
    echo "  hybrid      Cambiar a modo híbrido"
    echo "  integrated  Cambiar a GPU integrada"
    echo "  run <cmd>   Ejecutar comando con GPU NVIDIA"
    echo "  help        Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  gpu-switch status"
    echo "  gpu-switch nvidia"
    echo "  gpu-switch run steam"
    echo "  gpu-switch run blender"
}

case "${1:-}" in
    "status"|"")
        show_current
        ;;
    "nvidia")
        switch_to_nvidia
        ;;
    "hybrid")
        switch_to_hybrid
        ;;
    "integrated")
        switch_to_integrated
        ;;
    "run")
        shift
        run_with_nvidia "$@"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Opción no válida: $1"
        echo "Usa 'gpu-switch help' para ver las opciones disponibles"
        exit 1
        ;;
esac
EOF
    chmod +x "${HOME}/.local/bin/gpu-switch"
    
    # Script de monitoreo de GPU
    cat > "${HOME}/.local/bin/gpu-monitor" << 'EOF'
#!/bin/bash

# GPU Monitor - Monitoreo en tiempo real de GPU híbrida

watch -n 1 '
echo "=== GPU Híbrida - Monitor en Tiempo Real ==="
echo ""

# Estado EnvyControl
if command -v envycontrol &>/dev/null; then
    echo "Modo actual: $(envycontrol --query 2>/dev/null || echo "No disponible")"
    echo ""
fi

# GPU Integrada
echo "=== GPU Integrada ==="
if command -v intel_gpu_top &>/dev/null; then
    timeout 1 intel_gpu_top -s 100 -c 1 2>/dev/null | grep -E "(RC6|GPU|IMC)" || echo "Intel GPU: Activa"
elif [[ -f /sys/class/drm/card0/device/gpu_busy_percent ]]; then
    echo "Uso: $(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo "N/A")%"
else
    echo "Información no disponible"
fi
echo ""

# GPU NVIDIA
echo "=== GPU NVIDIA ==="
if command -v nvidia-smi &>/dev/null; then
    nvidia-smi --query-gpu=utilization.gpu,utilization.memory,temperature.gpu,power.draw --format=csv,noheader,nounits 2>/dev/null | while read line; do
        IFS="," read -r gpu_util mem_util temp power <<< "$line"
        echo "GPU: ${gpu_util}% | Memoria: ${mem_util}% | Temp: ${temp}°C | Potencia: ${power}W"
    done
else
    echo "NVIDIA no disponible o inactiva"
fi
echo ""

# Procesos gráficos
echo "=== Procesos Gráficos Activos ==="
ps aux | grep -E "(Xorg|Wayland|hyprland|steam|game)" | grep -v grep | head -5 || echo "Ninguno detectado"
'
EOF
    chmod +x "${HOME}/.local/bin/gpu-monitor"
    
    # Script de optimización automática
    cat > "${HOME}/.local/bin/gpu-auto-optimize" << 'EOF'
#!/bin/bash

# GPU Auto Optimize - Optimización automática según el uso

BATTERY_THRESHOLD=30
HIGH_PERFORMANCE_APPS=("steam" "blender" "davinci-resolve" "obs" "games")

get_battery_level() {
    if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
        cat /sys/class/power_supply/BAT0/capacity
    elif [[ -f /sys/class/power_supply/BAT1/capacity ]]; then
        cat /sys/class/power_supply/BAT1/capacity
    else
        echo "100"  # Asumir desktop si no hay batería
    fi
}

is_on_ac_power() {
    if [[ -f /sys/class/power_supply/ADP1/online ]]; then
        [[ "$(cat /sys/class/power_supply/ADP1/online)" == "1" ]]
    elif [[ -f /sys/class/power_supply/AC/online ]]; then
        [[ "$(cat /sys/class/power_supply/AC/online)" == "1" ]]
    else
        return 0  # Asumir AC si no se puede detectar
    fi
}

check_high_performance_apps() {
    for app in "${HIGH_PERFORMANCE_APPS[@]}"; do
        if pgrep -f "$app" &>/dev/null; then
            return 0
        fi
    done
    return 1
}

optimize_gpu() {
    local battery_level=$(get_battery_level)
    local current_mode=$(envycontrol --query 2>/dev/null || echo "unknown")
    
    echo "Batería: ${battery_level}% | Modo actual: ${current_mode}"
    
    # Lógica de optimización
    if is_on_ac_power; then
        if check_high_performance_apps; then
            if [[ "$current_mode" != "nvidia" ]]; then
                echo "Apps de alto rendimiento detectadas + AC - Cambiando a NVIDIA"
                notify-send "GPU Auto-Optimize" "Cambiando a modo NVIDIA para mejor rendimiento"
                sudo envycontrol -s nvidia --dm gdm
            fi
        else
            if [[ "$current_mode" != "hybrid" ]]; then
                echo "Uso normal + AC - Cambiando a híbrido"
                sudo envycontrol -s hybrid --dm gdm
            fi
        fi
    else
        # En batería
        if [[ $battery_level -lt $BATTERY_THRESHOLD ]]; then
            if [[ "$current_mode" != "integrated" ]]; then
                echo "Batería baja - Cambiando a GPU integrada"
                notify-send "GPU Auto-Optimize" "Batería baja: cambiando a GPU integrada"
                sudo envycontrol -s integrated --dm gdm
            fi
        elif check_high_performance_apps; then
            if [[ "$current_mode" != "hybrid" ]]; then
                echo "Apps de rendimiento en batería - Modo híbrido"
                sudo envycontrol -s hybrid --dm gdm
            fi
        else
            if [[ "$current_mode" != "integrated" ]]; then
                echo "Uso normal en batería - GPU integrada"
                sudo envycontrol -s integrated --dm gdm
            fi
        fi
    fi
}

case "${1:-auto}" in
    "auto")
        optimize_gpu
        ;;
    "daemon")
        echo "Iniciando daemon de optimización automática..."
        while true; do
            optimize_gpu
            sleep 300  # Revisar cada 5 minutos
        done
        ;;
    *)
        echo "Uso: gpu-auto-optimize [auto|daemon]"
        ;;
esac
EOF
    chmod +x "${HOME}/.local/bin/gpu-auto-optimize"
}

# Configurar aplicaciones para GPU híbrida
configure_hybrid_applications() {
    log "Configurando aplicaciones para GPU híbrida..."
    
    # Crear directorio de aplicaciones personalizadas
    mkdir -p "${HOME}/.local/share/applications"
    
    # Steam con GPU NVIDIA
    cat > "${HOME}/.local/share/applications/steam-nvidia.desktop" << 'EOF'
[Desktop Entry]
Name=Steam (NVIDIA)
Comment=Application for managing and playing games on Steam with NVIDIA GPU
Exec=env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia steam %U
Icon=steam
Terminal=false
Type=Application
Categories=Network;FileTransfer;Game;
MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
EOF

    # Blender con GPU NVIDIA
    if command -v blender &>/dev/null; then
        cat > "${HOME}/.local/share/applications/blender-nvidia.desktop" << 'EOF'
[Desktop Entry]
Name=Blender (NVIDIA)
Comment=3D modeling, animation, rendering and post-production with NVIDIA GPU
Exec=env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia blender %f
Icon=blender
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;
MimeType=application/x-blender;
EOF
    fi
    
    # OBS Studio con GPU NVIDIA
    if command -v obs &>/dev/null; then
        cat > "${HOME}/.local/share/applications/obs-nvidia.desktop" << 'EOF'
[Desktop Entry]
Name=OBS Studio (NVIDIA)
Comment=Live streaming and recording software with NVIDIA encoding
Exec=env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia obs %U
Icon=com.obsproject.Studio
Terminal=false
Type=Application
Categories=AudioVideo;Recorder;
EOF
    fi
    
    # Configurar variables para aplicaciones específicas
    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/hybrid-gpu.conf" << 'EOF'
# Configuración para GPU híbrida
# Estas variables se aplicarán automáticamente

# Para aplicaciones que soporten PRIME
__NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
__GLX_VENDOR_LIBRARY_NAME=nvidia

# Vulkan
VK_DRIVER_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/intel_icd.x86_64.json

# Mesa
MESA_LOADER_DRIVER_OVERRIDE=iris
EOF
}

# Configurar servicios del sistema
configure_hybrid_services() {
    log "Configurando servicios para GPU híbrida..."
    
    # Servicio de optimización automática
    cat > /tmp/gpu-auto-optimize.service << 'EOF'
[Unit]
Description=GPU Auto Optimization Service
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/gpu-auto-optimize daemon
Restart=always
RestartSec=30
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF
    
    mkdir -p "${HOME}/.config/systemd/user"
    mv /tmp/gpu-auto-optimize.service "${HOME}/.config/systemd/user/"
    
    # Habilitar servicio si el usuario lo desea
    if ask_question "¿Habilitar optimización automática de GPU?"; then
        systemctl --user enable gpu-auto-optimize.service
        log "Servicio de optimización automática habilitado"
    fi
    
    # Configurar udev rules para detección de cambios de energía
    cat > /tmp/99-gpu-power-management.rules << 'EOF'
# GPU Power Management Rules
# Ejecutar optimización cuando cambie el estado de energía

SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/bin/systemctl --user start gpu-auto-optimize.service"
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/systemctl --user start gpu-auto-optimize.service"
EOF
    
    sudo mv /tmp/99-gpu-power-management.rules /etc/udev/rules.d/
    sudo udevadm control --reload-rules
}

# Configurar Hyprland para GPU híbrida
configure_hyprland_hybrid() {
    log "Configurando Hyprland para GPU híbrida..."
    
    # Crear configuración específica para híbrida
    mkdir -p "${SCRIPT_DIR}/../../config/hypr/conf"
    
    cat > "${SCRIPT_DIR}/../../config/hypr/conf/hybrid-gpu.conf" << 'EOF'
# Hybrid GPU Configuration for Hyprland

# Variables de entorno para GPU híbrida
env = __NV_PRIME_RENDER_OFFLOAD,1
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0

# Configuración de renderizado
render {
    explicit_sync = 1
    explicit_sync_kms = 1
}

# Configuración de monitores para GPU híbrida
# El monitor principal usará la GPU integrada por defecto
# Los monitores externos pueden usar NVIDIA si están conectados

# Reglas de ventana para aplicaciones de alto rendimiento
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,class:^(steam)$
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,class:^(lutris)$
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,class:^(heroic)$
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,class:^(blender)$
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,class:^(obs)$
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,class:^(davinci-resolve)$

# Configuración específica para juegos
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,class:^(steam_app_.*)$
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,title:^(.*[Gg]ame.*)$
windowrulev2 = env __NV_PRIME_RENDER_OFFLOAD 1,title:^(.*[Gg]aming.*)$

# Optimizaciones de rendimiento
misc {
    vrr = 1
    vfr = true
    no_direct_scanout = false
}
EOF

    # Añadir source a hyprland.conf si no existe
    local hypr_config="${SCRIPT_DIR}/../../config/hypr/hyprland.conf"
    if [[ -f "$hypr_config" ]] && ! grep -q "hybrid-gpu.conf" "$hypr_config"; then
        echo "" >> "$hypr_config"
        echo "# Hybrid GPU Configuration" >> "$hypr_config"
        echo "source = ~/.config/hypr/conf/hybrid-gpu.conf" >> "$hypr_config"
    fi
}

# Crear widget para Waybar
create_waybar_widget() {
    log "Creando widget de GPU para Waybar..."
    
    # Script para el widget
    cat > "${HOME}/.local/bin/waybar-gpu-status" << 'EOF'
#!/bin/bash

# Waybar GPU Status Widget

get_gpu_mode() {
    if command -v envycontrol &>/dev/null; then
        envycontrol --query 2>/dev/null || echo "unknown"
    else
        echo "manual"
    fi
}

get_gpu_usage() {
    local nvidia_usage="0"
    local intel_usage="0"
    
    # NVIDIA usage
    if command -v nvidia-smi &>/dev/null; then
        nvidia_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "0")
    fi
    
    # Intel usage (aproximado)
    if [[ -f /sys/class/drm/card0/device/gpu_busy_percent ]]; then
        intel_usage=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo "0")
    fi
    
    echo "${intel_usage}:${nvidia_usage}"
}

get_battery_status() {
    if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
        local battery=$(cat /sys/class/power_supply/BAT0/capacity)
        local status=$(cat /sys/class/power_supply/BAT0/status)
        echo "${battery}%:${status}"
    else
        echo "AC:Charging"
    fi
}

main() {
    local mode=$(get_gpu_mode)
    local usage=$(get_gpu_usage)
    local battery=$(get_battery_status)
    
    IFS=':' read -r intel_usage nvidia_usage <<< "$usage"
    IFS=':' read -r battery_level battery_status <<< "$battery"
    
    # Determinar icono según el modo
    case "$mode" in
        "nvidia")
            icon="󰢮"
            class="nvidia"
            ;;
        "hybrid")
            icon="󰦀"
            class="hybrid"
            ;;
        "integrated")
            icon="󰇄"
            class="integrated"
            ;;
        *)
            icon="󰟀"
            class="unknown"
            ;;
    esac
    
    # Crear tooltip
    local tooltip="Modo: $mode\\nIntel: ${intel_usage}%\\nNVIDIA: ${nvidia_usage}%\\nBatería: $battery"
    
    # Output para Waybar
    printf '{"text": "%s %s", "class": "%s", "tooltip": "%s"}\n' \
        "$icon" "$mode" "$class" "$tooltip"
}

main "$@"
EOF
    chmod +x "${HOME}/.local/bin/waybar-gpu-status"
    
    # Configuración para Waybar
    cat > "${SCRIPT_DIR}/../../config/waybar/modules/gpu-status.json" << 'EOF'
{
    "custom/gpu": {
        "exec": "waybar-gpu-status",
        "return-type": "json",
        "interval": 5,
        "format": "{}",
        "on-click": "gpu-switch status",
        "on-click-right": "gpu-monitor",
        "tooltip": true
    }
}
EOF
    
    # CSS para el widget
    cat >> "${SCRIPT_DIR}/../../config/waybar/styles/gpu-widget.css" << 'EOF'
/* GPU Status Widget Styles */

#custom-gpu {
    padding: 0 10px;
    margin: 0 5px;
    border-radius: 5px;
    font-weight: bold;
}

#custom-gpu.nvidia {
    background: linear-gradient(45deg, #76b900, #5a8f00);
    color: white;
}

#custom-gpu.hybrid {
    background: linear-gradient(45deg, #ff6b35, #f7931e);
    color: white;
}

#custom-gpu.integrated {
    background: linear-gradient(45deg, #0078d4, #106ebe);
    color: white;
}

#custom-gpu.unknown {
    background: #666666;
    color: white;
}

#custom-gpu:hover {
    opacity: 0.8;
}
EOF
}

# Verificar instalación híbrida
verify_hybrid_setup() {
    log "Verificando configuración híbrida..."
    
    # Verificar EnvyControl
    if command -v envycontrol &>/dev/null; then
        local current_mode=$(envycontrol --query 2>/dev/null || echo "error")
        if [[ "$current_mode" != "error" ]]; then
            log "✓ EnvyControl funcionando - Modo actual: $current_mode"
        else
            warning "✗ EnvyControl instalado pero no configurado correctamente"
        fi
    else
        error "✗ EnvyControl no está instalado"
    fi
    
    # Verificar GPUs disponibles
    local gpu_count=$(ls /dev/dri/card* 2>/dev/null | wc -l)
    if [[ $gpu_count -ge 2 ]]; then
        log "✓ Múltiples GPUs detectadas ($gpu_count)"
        ls /dev/dri/card* | while read -r card; do
            info "  - $card disponible"
        done
    else
        warning "✗ Solo se detectó una GPU"
    fi
    
    # Verificar drivers
    if lsmod | grep nvidia &>/dev/null; then
        log "✓ Driver NVIDIA cargado"
    else
        warning "✗ Driver NVIDIA no cargado"
    fi
    
    if lsmod | grep i915 &>/dev/null || lsmod | grep amdgpu &>/dev/null; then
        log "✓ Driver GPU integrada cargado"
    else
        warning "✗ Driver GPU integrada no detectado"
    fi
    
    # Verificar PRIME
    if command -v prime-run &>/dev/null; then
        log "✓ PRIME disponible"
    else
        info "ℹ PRIME no disponible (usando EnvyControl)"
    fi
    
    # Verificar scripts personalizados
    if [[ -x "${HOME}/.local/bin/gpu-switch" ]]; then
        log "✓ Script gpu-switch instalado"
    else
        warning "✗ Script gpu-switch no encontrado"
    fi
    
    # Test básico de funcionamiento
    info "Realizando test básico..."
    if glxinfo | grep -i "opengl renderer" &>/dev/null; then
        local renderer=$(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs)
        log "✓ OpenGL funcionando - Renderer: $renderer"
    else
        warning "✗ Problema con OpenGL"
    fi
}

# Crear documentación
create_documentation() {
    log "Creando documentación..."
    
    mkdir -p "${SCRIPT_DIR}/../../docs/gpu-hybrid"
    
    cat > "${SCRIPT_DIR}/../../docs/gpu-hybrid/README.md" << 'EOF'
# Configuración GPU Híbrida

Esta configuración permite gestionar laptops con GPU híbrida (Intel/AMD + NVIDIA) de manera eficiente.

## Comandos Principales

### gpu-switch
Gestión manual de GPU:
```bash
gpu-switch status          # Ver estado actual
gpu-switch nvidia          # Cambiar a NVIDIA (requiere reinicio)
gpu-switch hybrid          # Cambiar a modo híbrido (requiere reinicio)
gpu-switch integrated      # Cambiar a GPU integrada (requiere reinicio)
gpu-switch run <comando>   # Ejecutar comando con NVIDIA
