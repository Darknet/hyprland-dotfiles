#!/bin/bash
# ================================
# SCRIPT DE ACTUALIZACIÓN DEL SISTEMA
# ================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para enviar notificación
notify() {
    if command -v dunstify &> /dev/null; then
        dunstify -u normal -t 5000 "Sistema" "$1"
    fi
}

# Verificar conexión a internet
check_internet() {
    print_status "Verificando conexión a internet..."
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No hay conexión a internet"
        notify "❌ Error: No hay conexión a internet"
        exit 1
    fi
    print_success "Conexión a internet verificada"
}

# Actualizar mirrors
update_mirrors() {
    print_status "Actualizando mirrors..."
    if command -v reflector &> /dev/null; then
        sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        print_success "Mirrors actualizados"
        notify "🔄 Mirrors actualizados"
    else
        print_warning "Reflector no está instalado, saltando actualización de mirrors"
    fi
}

# Actualizar sistema base
update_pacman() {
    print_status "Actualizando paquetes del sistema..."
    sudo pacman -Syu --noconfirm
    print_success "Sistema base actualizado"
    notify "📦 Sistema base actualizado"
}

# Actualizar AUR
update_aur() {
    if command -v yay &> /dev/null; then
        print_status "Actualizando paquetes AUR..."
        yay -Syu --noconfirm
        print_success "Paquetes AUR actualizados"
        notify "📦 Paquetes AUR actualizados"
    else
        print_warning "yay no está instalado, saltando actualización AUR"
    fi
}

# Actualizar Flatpak
update_flatpak() {
    if command -v flatpak &> /dev/null; then
        print_status "Actualizando aplicaciones Flatpak..."
        flatpak update -y
        print_success "Aplicaciones Flatpak actualizadas"
        notify "📦 Flatpak actualizado"
    else
        print_warning "Flatpak no está instalado"
    fi
}

# Actualizar firmware
update_firmware() {
    if command -v fwupdmgr &> /dev/null; then
        print_status "Verificando actualizaciones de firmware..."
        fwupdmgr refresh
        if fwupdmgr get-updates &> /dev/null; then
            print_status "Actualizando firmware..."
            fwupdmgr update -y
            print_success "Firmware actualizado"
            notify "🔧 Firmware actualizado"
        else
            print_status "No hay actualizaciones de firmware disponibles"
        fi
    fi
}

# Limpiar caché
clean_cache() {
    print_status "Limpiando caché del sistema..."
    
    # Limpiar caché de pacman
    sudo pacman -Sc --noconfirm
    
    # Limpiar caché de yay
    if command -v yay &> /dev/null; then
        yay -Sc --noconfirm
    fi
    
    # Limpiar caché de usuario
    rm -rf ~/.cache/*
    
    print_success "Caché limpiado"
    notify "🧹 Caché del sistema limpiado"
}

# Verificar huérfanos
check_orphans() {
    print_status "Verificando paquetes huérfanos..."
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    if [[ -n "$orphans" ]]; then
        print_warning "Se encontraron paquetes huérfanos:"
        echo "$orphans"
        read -p "¿Desea eliminarlos? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -Rns $orphans --noconfirm
            print_success "Paquetes huérfanos eliminados"
            notify "🗑️ Paquetes huérfanos eliminados"
        fi
    else
        print_success "No se encontraron paquetes huérfanos"
    fi
}

# Función principal
main() {
    print_status "🚀 Iniciando actualización del sistema..."
    notify "🚀 Iniciando actualización del sistema"
    
    check_internet
    
    # Mostrar menú de opciones
    echo
    echo "Seleccione las opciones de actualización:"
    echo "1) Actualización completa (recomendado)"
    echo "2) Solo sistema base"
    echo "3) Solo AUR"
    echo "4) Solo Flatpak"
    echo "5) Personalizada"
    echo
    read -p "Opción [1-5]: " choice
    
    case $choice in
        1)
            update_mirrors
            update_pacman
            update_aur
            update_flatpak
            update_firmware
            clean_cache
            check_orphans
            ;;
        2)
            update_pacman
            ;;
        3)
            update_aur
            ;;
        4)
            update_flatpak
            ;;
        5)
            echo "Opciones personalizadas:"
            read -p "¿Actualizar mirrors? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && update_mirrors
            
            read -p "¿Actualizar sistema base? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && update_pacman
            
            read -p "¿Actualizar AUR? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && update_aur
            
            read -p "¿Actualizar Flatpak? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && update_flatpak
            
            read -p "¿Actualizar firmware? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && update_firmware
            
            read -p "¿Limpiar caché? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && clean_cache
            
            read -p "¿Verificar huérfanos? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && check_orphans
            ;;
        *)
            print_error "Opción inválida"
            exit 1
            ;;
    esac
    
    print_success "✅ Actualización completada"
    notify "✅ Sistema actualizado correctamente"
    
    # Verificar si se necesita reinicio
    if [[ -f /var/run/reboot-required ]]; then
        print_warning "⚠️ Se requiere reinicio del sistema"
        notify "⚠️ Se requiere reinicio del sistema"
        read -p "¿Desea reiniciar ahora? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo reboot
        fi
    fi
}

# Verificar si se ejecuta como root
if [[ $EUID -eq 0 ]]; then
    print_error "No ejecute este script como root"
    exit 1
fi

main "$@"
