#!/bin/bash

# Script para limpiar archivos temporales y proyectos de prueba
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Función para confirmar acción
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi
    
    read -p "$message $prompt: " -n 1 -r
    echo
    
    if [[ "$default" == "y" ]]; then
        [[ $REPLY =~ ^[Nn]$ ]] && return 1 || return 0
    else
        [[ $REPLY =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# Limpiar archivos Python
cleanup_python() {
    log "Limpiando archivos Python..."
    
    local count=0
    
    # __pycache__ directories
    while IFS= read -r -d '' dir; do
        rm -rf "$dir"
        ((count++))
    done < <(find "$PROJECT_ROOT" -name "__pycache__" -type d -print0 2>/dev/null)
    
    # .pyc files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find "$PROJECT_ROOT" -name "*.pyc" -type f -print0 2>/dev/null)
    
    # .pyo files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find "$PROJECT_ROOT" -name "*.pyo" -type f -print0 2>/dev/null)
    
    # .pyd files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find "$PROJECT_ROOT" -name "*.pyd" -type f -print0 2>/dev/null)
    
    # Virtual environments
    for venv_name in venv .venv env .env; do
        while IFS= read -r -d '' dir; do
            if confirm "¿Eliminar entorno virtual $dir?"; then
                rm -rf "$dir"
                ((count++))
            fi
        done < <(find "$PROJECT_ROOT" -name "$venv_name" -type d -print0 2>/dev/null)
    done
    
    log "Archivos Python limpiados: $count elementos"
}

# Limpiar archivos Node.js
cleanup_nodejs() {
    log "Limpiando archivos Node.js..."
    
    local count=0
    
    # node_modules directories
    while IFS= read -r -d '' dir; do
        if confirm "¿Eliminar $dir? ($(du -sh "$dir" 2>/dev/null | cut -f1))"; then
            rm -rf "$dir"
            ((count++))
        fi
    done < <(find "$PROJECT_ROOT" -name "node_modules" -type d -print0 2>/dev/null)
    
    # package-lock.json files (opcional)
    if confirm "¿Eliminar archivos package-lock.json?"; then
        while IFS= read -r -d '' file; do
            rm -f "$file"
            ((count++))
        done < <(find "$PROJECT_ROOT" -name "package-lock.json" -type f -print0 2>/dev/null)
    fi
    
    # yarn.lock files (opcional)
    if confirm "¿Eliminar archivos yarn.lock?"; then
        while IFS= read -r -d '' file; do
            rm -f "$file"
            ((count++))
        done < <(find "$PROJECT_ROOT" -name "yarn.lock" -type f -print0 2>/dev/null)
    fi
    
    # .npm cache
    if [ -d "$HOME/.npm" ] && confirm "¿Limpiar caché de npm?"; then
        npm cache clean --force 2>/dev/null || true
        ((count++))
    fi
    
    log "Archivos Node.js limpiados: $count elementos"
}

# Limpiar archivos de sistema
cleanup_system() {
    log "Limpiando archivos de sistema..."
    
    local count=0
    
    # .DS_Store files (macOS)
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find "$PROJECT_ROOT" -name ".DS_Store" -type f -print0 2>/dev/null)
    
    # Thumbs.db files (Windows)
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find "$PROJECT_ROOT" -name "Thumbs.db" -type f -print0 2>/dev/null)
    
    # .tmp files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((count++))
    done < <(find "$PROJECT_ROOT" -name "*.tmp" -type f -print0 2>/dev/null)
    
    # .log files
    if confirm "¿Eliminar archivos .log?"; then
        while IFS= read -r -d '' file; do
            rm -f "$file"
            ((count++))
        done < <(find "$PROJECT_ROOT" -name "*.log" -type f -print0 2>/dev/null)
    fi
    
    # .bak files
    if confirm "¿Eliminar archivos .bak?"; then
        while IFS= read -r -d '' file; do
            rm -f "$file"
            ((count++))
        done < <(find "$PROJECT_ROOT" -name "*.bak" -type f -print0 2>/dev/null)
    fi
    
    log "Archivos de sistema limpiados: $count elementos"
}

# Limpiar proyectos de prueba
cleanup_test_projects() {
    log "Limpiando proyectos de prueba..."
    
    local count=0
    
    # Buscar directorios que empiecen con "test-"
    while IFS= read -r -d '' dir; do
        if confirm "¿Eliminar proyecto de prueba $(basename "$dir")?"; then
            rm -rf "$dir"
            ((count++))
        fi
    done < <(find "$PROJECT_ROOT" -maxdepth 1 -name "test-*" -type d -print0 2>/dev/null)
    
    # Buscar directorios que empiecen con "temp-"
    while IFS= read -r -d '' dir; do
        if confirm "¿Eliminar directorio temporal $(basename "$dir")?"; then
            rm -rf "$dir"
            ((count++))
        fi
    done < <(find "$PROJECT_ROOT" -maxdepth 1 -name "temp-*" -type d -print0 2>/dev/null)
    
    log "Proyectos de prueba limpiados: $count elementos"
}

# Limpiar archivos Docker
cleanup_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        warning "Docker no está instalado, saltando limpieza Docker"
        return
    fi
    
    log "Limpiando recursos Docker..."
    
    if confirm "¿Limpiar imágenes Docker no utilizadas?"; then
        docker image prune -f || warning "Error limpiando imágenes Docker"
    fi
    
    if confirm "¿Limpiar contenedores Docker detenidos?"; then
        docker container prune -f || warning "Error limpiando contenedores Docker"
    fi
    
    if confirm "¿Limpiar volúmenes Docker no utilizados?"; then
        docker volume prune -f || warning "Error limpiando volúmenes Docker"
    fi
    
    if confirm "¿Limpiar redes Docker no utilizadas?"; then
        docker network prune -f || warning "Error limpiando redes Docker"
    fi
    
    log "Limpieza Docker completada"
}

# Limpiar caché de herramientas
cleanup_caches() {
    log "Limpiando cachés de herramientas..."
    
    # Pip cache
    if command -v pip3 >/dev/null 2>&1 && confirm "¿Limpiar caché de pip?"; then
        pip3 cache purge 2>/dev/null || warning "Error limpiando caché de pip"
    fi
    
    # Homebrew cache (macOS)
    if command -v brew >/dev/null 2>&1 && confirm "¿Limpiar caché de Homebrew?"; then
        brew cleanup || warning "Error limpiando caché de Homebrew"
    fi
    
    # APT cache (Debian/Ubuntu)
    if command -v apt-get >/dev/null 2>&1 && confirm "¿Limpiar caché de APT?"; then
        sudo apt-get clean || warning "Error limpiando caché de APT"
        sudo apt-get autoclean || warning "Error en autoclean de APT"
    fi
    
    log "Cachés limpiados"
}

# Mostrar estadísticas de espacio
show_space_stats() {
    log "Estadísticas de espacio en disco:"
    
    if command -v du >/dev/null 2>&1; then
        echo "Tamaño total del proyecto:"
        du -sh "$PROJECT_ROOT" 2>/dev/null || echo "No se pudo calcular"
        
        echo
        echo "Directorios más grandes:"
        du -sh "$PROJECT_ROOT"/*/ 2>/dev/null | sort -hr | head -10 || echo "No se pudieron listar"
    fi
    
    if command -v df >/dev/null 2>&1; then
        echo
        echo "Espacio disponible en disco:"
        df -h "$PROJECT_ROOT" 2>/dev/null || echo "No se pudo obtener información del disco"
    fi
}

# Función principal
main() {
    echo "🧹 Herramienta de limpieza del proyecto"
    echo "======================================"
    echo
    
    cd "$PROJECT_ROOT"
    
    case "${1:-all}" in
        "python")
            cleanup_python
            ;;
        "nodejs")
            cleanup_nodejs
            ;;
        "system")
            cleanup_system
            ;;
        "test")
            cleanup_test_projects
            ;;
        "docker")
            cleanup_docker
            ;;
        "cache")
            cleanup_caches
            ;;
        "stats")
            show_space_stats
            ;;
        "all")
            cleanup_python
            cleanup_nodejs
            cleanup_system
            cleanup_test_projects
            cleanup_docker
            cleanup_caches
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
    
    echo
    log "🎉 Limpieza completada"
    
    if [[ "${1:-all}" == "all" ]] || [[ "${1:-}" == "stats" ]]; then
        echo
        show_space_stats
    fi
}

# Mostrar ayuda
show_help() {
    echo "🧹 Script de limpieza del proyecto"
    echo
    echo "Uso: $0 [tipo]"
    echo
    echo "Tipos de limpieza:"
    echo "  all      Limpieza completa (por defecto)"
    echo "  python   Limpiar archivos Python (__pycache__, .pyc, venv)"
    echo "  nodejs   Limpiar archivos Node.js (node_modules, package-lock.json)"
    echo "  system   Limpiar archivos de sistema (.DS_Store, .tmp, .log)"
    echo "  test     Limpiar proyectos de prueba (test-*, temp-*)"
    echo "  docker   Limpiar recursos Docker no utilizados"
    echo "  cache    Limpiar cachés de herramientas (pip, npm, brew)"
    echo "  stats    Mostrar estadísticas de espacio en disco"
    echo
    echo "Ejemplos:"
    echo "  $0           # Limpieza completa"
    echo "  $0 python    # Solo archivos Python"
    echo "  $0 nodejs    # Solo archivos Node.js"
    echo "  $0 stats     # Solo mostrar estadísticas"
}

# Verificar argumentos
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Ejecutar función principal
main "$@"
