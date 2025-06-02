#!/bin/bash
# ================================
# SCRIPT DE LIMPIEZA DEL SISTEMA
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

notify() {
    if command -v dunstify &> /dev/null; then
        dunstify -u normal -t 5000 "Limpieza" "$1"
    fi
}

# Mostrar espacio en disco antes
show_disk_usage() {
    print_status "Espacio en disco actual:"
    df -h / | tail -1 | awk '{print "Usado: " $3 " / " $2 " (" $5 ")"}'
    echo
}

# Limpiar caché de pacman
clean_pacman_cache() {
    print_status "Limpiando caché de pacman..."
    
    # Mostrar tamaño actual del caché
    cache_size=$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | cut -f1 || echo "0")
    print_status "Tamaño actual del caché: $cache_size"
    
    # Limpiar paquetes no instalados
    sudo pacman -Sc --noconfirm
    
    # Opción para limpiar todo el caché
    read -p "¿Limpiar TODO el caché de pacman? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo pacman -Scc --noconfirm
        print_success "Todo el caché de pacman limpiado"
    fi
    
    notify "🧹 Caché de pacman limpiado"
}

# Limpiar caché de AUR
clean_aur_cache() {
    if command -v yay &> /dev/null; then
        print_status "Limpiando caché de AUR..."
        yay -Sc --noconfirm
        
        # Limpiar directorio de construcción de yay
        if [[ -d ~/.cache/yay ]]; then
            rm -rf ~/.cache/yay/*
            print_success "Caché de construcción de yay limpiado"
        fi
        
        notify "🧹 Caché de AUR limpiado"
    fi
}

# Eliminar paquetes huérfanos
remove_orphans() {
    print_status "Buscando paquetes huérfanos..."
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    
    if [[ -n "$orphans" ]]; then
        print_warning "Paquetes huérfanos encontrados:"
        echo "$orphans"
        echo
        read -p "¿Eliminar paquetes huérfanos? (y/N): " -n 1 -r
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

# Limpiar logs del sistema
clean_system_logs() {
    print_status "Limpiando logs del sistema..."
    
    # Mostrar tamaño actual de logs
    log_size=$(sudo journalctl --disk-usage | grep -o '[0-9.]*[KMGT]B')
    print_status "Tamaño actual de logs: $log_size"
    
    # Limpiar logs antiguos (mantener últimos 3 días)
    sudo journalctl --vacuum-time=3d
    
    # Limpiar logs de Xorg antiguos
    if [[ -d /var/log ]]; then
        sudo find /var/log -name "*.old" -delete 2>/dev/null || true
        sudo find /var/log -name "*.log.*" -mtime +7 -delete 2>/dev/null || true
    fi
    
    print_success "Logs del sistema limpiados"
    notify "📋 Logs del sistema limpiados"
}

# Limpiar caché de usuario
clean_user_cache() {
    print_status "Limpiando caché de usuario..."
    
    # Mostrar tamaño del caché de usuario
    if [[ -d ~/.cache ]]; then
        cache_size=$(du -sh ~/.cache 2>/dev/null | cut -f1 || echo "0")
        print_status "Tamaño del caché de usuario: $cache_size"
        
        # Limpiar caché pero preservar algunos directorios importantes
        find ~/.cache -type f -mtime +7 -delete 2>/dev/null || true
        
        # Limpiar cachés específicos
        rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
        rm -rf ~/.cache/mozilla/* 2>/dev/null || true
        rm -rf ~/.cache/chromium/* 2>/dev/null || true
    fi
    
    # Limpiar papelera
    if [[ -d ~/.local/share/Trash ]]; then
        rm -rf ~/.local/share/Trash/* 2>/dev/null || true
        print_success "Papelera limpiada"
    fi
    
    # Limpiar archivos temporales
    rm -rf /tmp/* 2>/dev/null || true
    
    print_success "Caché de usuario limpiado"
    notify "🧹 Caché de usuario limpiado"
}

# Limpiar Flatpak
clean_flatpak() {
    if command -v flatpak &> /dev/null; then
        print_status "Limpiando Flatpak..."
        
        # Eliminar aplicaciones no utilizadas
        flatpak uninstall --unused -y 2>/dev/null || true
        
        # Limpiar caché de Flatpak
        rm -rf ~/.var/app/*/cache/* 2>/dev/null || true
        
        print_success "Flatpak limpiado"
        notify "📦 Flatpak limpiado"
    fi
}

# Limpiar Docker (si está instalado)
clean_docker() {
    if command -v docker &> /dev/null; then
        print_status "Limpiando Docker..."
        
        # Mostrar espacio usado por Docker
        docker_size=$(docker system df 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
        print_status "Espacio usado por Docker: $docker_size"
        
        read -p "¿Limpiar contenedores, imágenes y volúmenes no utilizados? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker system prune -af --volumes
            print_success "Docker limpiado"
            notify "🐳 Docker limpiado"
        fi
    fi
}

# Optimizar base de datos de pacman
optimize_pacman_db() {
    print_status "Optimizando base de datos de pacman..."
    sudo pacman-db-upgrade
    print_success "Base de datos de pacman optimizada"
}

# Limpiar archivos de configuración huérfanos
clean_config_orphans() {
    print_status "Buscando archivos de configuración huérfanos..."
    
    # Buscar directorios en .config que podrían ser de aplicaciones desinstaladas
    if [[ -d ~/.config ]]; then
        print_status "Directorios en ~/.config:"
        ls -la ~/.config | grep "^d" | awk '{print $9}' | grep -v "^\.$\|^\.\.$"
        echo
        print_warning "Revise manualmente los directorios que ya no necesite"
    fi
}

# Limpiar descargas antiguas
clean_old_downloads() {
    print_status "Limpiando descargas antiguas..."
    
    if [[ -d ~/Downloads ]]; then
        # Mostrar archivos antiguos (más de 30 días)
        old_files=$(find ~/Downloads -type f -mtime +30 2>/dev/null || true)
        
        if [[ -n "$old_files" ]]; then
            print_warning "Archivos en Downloads con más de 30 días:"
            echo "$old_files"
            echo
            read -p "¿Eliminar estos archivos? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                find ~/Downloads -type f -mtime +30 -delete 2>/dev/null || true
                print_success "Descargas antiguas eliminadas"
                notify "📥 Descargas antiguas eliminadas"
            fi
        else
            print_success "No hay descargas antiguas para limpiar"
        fi
    fi
}

# Función principal
main() {
    print_status "🧹 Iniciando limpieza del sistema..."
    notify "🧹 Iniciando limpieza del sistema"
    
    echo "Espacio en disco ANTES de la limpieza:"
    show_disk_usage
    
    echo "Seleccione el tipo de limpieza:"
    echo "1) Limpieza completa (recomendado)"
    echo "2) Limpieza básica"
    echo "3) Limpieza personalizada"
    echo "4) Solo mostrar información"
    echo
    read -p "Opción [1-4]: " choice
    
    case $choice in
        1)
            clean_pacman_cache
            clean_aur_cache
            remove_orphans
            clean_system_logs
            clean_user_cache
            clean_flatpak
            clean_docker
            optimize_pacman_db
            clean_old_downloads
            ;;
        2)
            clean_pacman_cache
            clean_user_cache
            clean_system_logs
            ;;
        3)
            echo "Opciones de limpieza personalizadas:"
            
            read -p "¿Limpiar caché de pacman? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && clean_pacman_cache
            
            read -p "¿Limpiar caché de AUR? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && clean_aur_cache
            
            read -p "¿Eliminar paquetes huérfanos? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && remove_orphans
            
            read -p "¿Limpiar logs del sistema? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && clean_system_logs
            
            read -p "¿Limpiar caché de usuario? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && clean_user_cache
            
            read -p "¿Limpiar Flatpak? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && clean_flatpak
            
            read -p "¿Limpiar Docker? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && clean_docker
            
            read -p "¿Limpiar descargas antiguas? (y/N): " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && clean_old_downloads
            ;;
        4)
            show_disk_usage
            clean_config_orphans
            exit 0
            ;;
        *)
            print_error "Opción inválida"
            exit 1
            ;;
    esac
    
    echo
    echo "Espacio en disco DESPUÉS de la limpieza:"
    show_disk_usage
    
    print_success "✅ Limpieza completada"
    notify "✅ Limpieza del sistema completada"
}

# Verificar que no se ejecute como root
if [[ $EUID -eq 0 ]]; then
    print_error "No ejecute este script como root"
    exit 1
fi

main "$@"
