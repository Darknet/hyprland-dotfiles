#!/bin/bash

# Waydroid Setup Script - Instalación y configuración de Waydroid
# Para ejecutar aplicaciones Android en Hyprland

set -euo pipefail

readonly LOG_FILE="/tmp/waydroid-setup-$(date +%Y%m%d-%H%M%S).log"

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac
}

check_requirements() {
    log "INFO" "Verificando requisitos del sistema..."
    
    # Verificar kernel
    if ! modinfo binder_linux >/dev/null 2>&1; then
        log "WARN" "Módulo binder_linux no encontrado. Instalando..."
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm linux-zen linux-zen-headers
        else
            log "ERROR" "Se requiere un kernel con soporte para binder (linux-zen recomendado)"
            return 1
        fi
    fi
    
    # Verificar Wayland
    if [ -z "${WAYLAND_DISPLAY:-}" ]; then
        log "WARN" "No se detectó sesión Wayland. Waydroid funciona mejor en Wayland"
    fi
    
    return 0
}

install_waydroid() {
    log "INFO" "Instalando Waydroid..."
    
    # Instalar desde AUR
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm waydroid python-pyclip
    elif command -v paru >/dev/null 2>&1; then
        paru -S --needed --noconfirm waydroid python-pyclip
    else
        log "ERROR" "Se requiere un helper de AUR (yay o paru)"
        return 1
    fi
    
    # Habilitar servicios
    sudo systemctl enable --now waydroid-container
    
    log "INFO" "Waydroid instalado correctamente"
}

configure_waydroid() {
    log "INFO" "Configurando Waydroid..."
    
    # Inicializar Waydroid
    log "INFO" "Inicializando Waydroid (esto puede tomar varios minutos)..."
    waydroid init
    
    # Configurar propiedades
    log "INFO" "Configurando propiedades del sistema..."
    waydroid prop set persist.waydroid.multi_windows true
    waydroid prop set persist.waydroid.cursor_on_subsurface true
    
    # Configurar red
    sudo waydroid shell "settings put global http_proxy :0"
    
    log "INFO" "Configuración básica completada"
}

install_gapps() {
    read -p "¿Deseas instalar Google Apps (Play Store, etc.)? [y/N]: " install_gapps
    
    case "$install_gapps" in
        [Yy]|[Yy][Ee][Ss])
            log "INFO" "Instalando Google Apps..."
            
            # Descargar script de instalación de GApps
            curl -L https://raw.githubusercontent.com/casualsnek/waydroid_script/main/waydroid_extras.py -o /tmp/waydroid_extras.py
            
            # Instalar GApps
            python3 /tmp/waydroid_extras.py -g
            
            log "INFO" "Google Apps instalado. Reinicia Waydroid para aplicar cambios"
            ;;
        *)
            log "INFO" "Saltando instalación de Google Apps"
            ;;
    esac
}

create_desktop_entries() {
    log "INFO" "Creando entradas de escritorio..."
    
    # Crear directorio de aplicaciones
    mkdir -p "$HOME/.local/share/applications"
    
    # Entrada principal de Waydroid
    cat > "$HOME/.local/share/applications/waydroid.desktop" << 'EOF'
[Desktop Entry]
Name=Waydroid
Comment=Android Container
Exec=waydroid show-full-ui
Icon=waydroid
Type=Application
Categories=System;Emulator;
Keywords=android;container;
EOF
    
    # Script para lanzar aplicaciones Android
    cat > "$HOME/.local/bin/waydroid-app" << 'EOF'
#!/bin/bash
# Script para lanzar aplicaciones Android específicas

if [ $# -eq 0 ]; then
    echo "Uso: $0 <package_name>"
    echo "Ejemplo: $0 com.android.settings"
    exit 1
fi

waydroid app intent "$1"
EOF
    
    chmod +x "$HOME/.local/bin/waydroid-app"
    
    log "INFO" "Entradas de escritorio creadas"
}

configure_hyprland_integration() {
    log "INFO" "Configurando integración con Hyprland..."
    
    local hypr_config="$HOME/.config/hypr"
    
    # Crear reglas de ventana para Waydroid
    cat >> "$hypr_config/windowrules.conf" << 'EOF'

# Waydroid window rules
windowrulev2 = float, class:^(Waydroid)$
windowrulev2 = size 400 600, class:^(Waydroid)$
windowrulev2 = center, class:^(Waydroid)$
windowrulev2 = opacity 0.95, class:^(Waydroid)$

# Reglas específicas para aplicaciones Android
windowrulev2 = float, title:^(Android)(.*)$
windowrulev2 = size 350 550, title:^(Android)(.*)$
EOF
    
    # Agregar keybinds para Waydroid
    cat >> "$hypr_config/keybinds.conf" << 'EOF'

# Waydroid keybinds
bind = $mainMod SHIFT, A, exec, waydroid show-full-ui
bind = $mainMod SHIFT, W, exec, waydroid session stop
bind = $mainMod CTRL, A, exec, waydroid app launch com.android.settings
EOF
    
    log "INFO" "Integración con Hyprland configurada"
}

optimize_performance() {
    log "INFO" "Optimizando rendimiento de Waydroid..."
    
    # Configurar CPU governor
    echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    
    # Configurar propiedades de rendimiento
    waydroid prop set persist.waydroid.uevent true
    waydroid prop set persist.waydroid.udev true
    waydroid prop set persist.waydroid.fake_touch true
    
    # Configurar memoria
    waydroid prop set dalvik.vm.heapsize 512m
    waydroid prop set dalvik.vm.heapstartsize 8m
    waydroid prop set dalvik.vm.heapgrowthlimit 192m
    waydroid prop set dalvik.vm.heaptargetutilization 0.75
    waydroid prop set dalvik.vm.heapminfree 2m
    waydroid prop set dalvik.vm.heapmaxfree 8m
    
    log "INFO" "Optimizaciones aplicadas"
}

show_usage_info() {
    log "INFO" "Información de uso de Waydroid:"
    echo
    echo "Comandos básicos:"
    echo "  waydroid show-full-ui          - Mostrar interfaz completa"
    echo "  waydroid app list              - Listar aplicaciones instaladas"
    echo "  waydroid app install <apk>     - Instalar APK"
    echo "  waydroid app launch <package>  - Lanzar aplicación"
    echo "  waydroid session stop          - Detener sesión"
    echo
    echo "Atajos de teclado en Hyprland:"
    echo "  Super + Shift + A              - Abrir Waydroid"
    echo "  Super + Shift + W              - Cerrar Waydroid"
    echo "  Super + Ctrl + A               - Abrir configuración Android"
    echo
    echo "Para instalar aplicaciones:"
    echo "  1. Descarga el APK"
    echo "  2. Ejecuta: waydroid app install /ruta/al/archivo.apk"
    echo "  3. Lanza con: waydroid app launch com.package.name"
    echo
}

main() {
    log "INFO" "Iniciando instalación de Waydroid..."
    
    # Verificar requisitos
    if ! check_requirements; then
        log "ERROR" "Los requisitos del sistema no se cumplen"
        exit 1
    fi
    
    # Instalar Waydroid
    install_waydroid
    
    # Configurar Waydroid
    configure_waydroid
    
    # Instalar Google Apps (opcional)
    install_gapps
    
    # Crear entradas de escritorio
    create_desktop_entries
    
    # Configurar integración con Hyprland
    configure_hyprland_integration
    
    # Optimizar rendimiento
    optimize_performance
    
    # Mostrar información de uso
    show_usage_info
    
    log "INFO" "Instalación de Waydroid completada!"
    log "INFO" "Ejecuta 'waydroid show-full-ui' para comenzar"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
