#!/bin/bash

# Script para actualizar templates desde el repositorio
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")"
REPO_URL="https://github.com/tu-usuario/project-templates.git"
BACKUP_DIR="$HOME/.project-templates-backup"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Crear backup
create_backup() {
    log "Creando backup de templates actuales..."
    rm -rf "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$TEMPLATES_DIR" "$BACKUP_DIR/templates-$(date +%Y%m%d-%H%M%S)"
}

# Actualizar desde Git
update_from_git() {
    log "Actualizando templates desde repositorio..."
    
    if [ -d "$TEMPLATES_DIR/.git" ]; then
        cd "$TEMPLATES_DIR"
        git pull origin main
    else
        warning "No es un repositorio Git. Clonando desde $REPO_URL"
        cd "$(dirname "$TEMPLATES_DIR")"
        rm -rf "$(basename "$TEMPLATES_DIR")"
        git clone "$REPO_URL" "$(basename "$TEMPLATES_DIR")"
    fi
}

# Verificar integridad
verify_templates() {
    log "Verificando integridad de templates..."
    
    local errors=0
    
    # Verificar que existen los templates básicos
    local required_templates=("python-basic" "nodejs-basic" "docker" "kubernetes")
    
    for template in "${required_templates[@]}"; do
        if [ ! -d "$TEMPLATES_DIR/$template" ]; then
            error "Template requerido no encontrado: $template"
            ((errors++))
        fi
    done
    
    # Verificar scripts
    if [ ! -f "$TEMPLATES_DIR/scripts/init-project.sh" ]; then
        error "Script init-project.sh no encontrado"
        ((errors++))
    fi
    
    if [ $errors -gt 0 ]; then
        error "Se encontraron $errors errores. Restaurando backup..."
        restore_backup
        exit 1
    fi
    
    log "✅ Verificación completada sin errores"
}

# Restaurar backup
restore_backup() {
    warning "Restaurando desde backup..."
    local latest_backup=$(ls -1t "$BACKUP_DIR" | head -n 1)
    if [ -n "$latest_backup" ]; then
        rm -rf "$TEMPLATES_DIR"
        cp -r "$BACKUP_DIR/$latest_backup" "$TEMPLATES_DIR"
        log "Backup restaurado: $latest_backup"
    else
        error "No se encontró backup para restaurar"
    fi
}

# Main
main() {
    log "🔄 Iniciando actualización de templates..."
    
    create_backup
    update_from_git
    verify_templates
    
    log "🎉 Templates actualizados exitosamente!"
    log "💾 Backup disponible en: $BACKUP_DIR"
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
