#!/bin/bash

# Script para validar proyectos generados
set -e

PROJECT_PATH=${1:-.}
PROJECT_TYPE=""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Detectar tipo de proyecto
detect_project_type() {
    if [ -f "$PROJECT_PATH/package.json" ]; then
        if grep -q "react" "$PROJECT_PATH/package.json"; then
            PROJECT_TYPE="react"
        elif grep -q "vue" "$PROJECT_PATH/package.json"; then
            PROJECT_TYPE="vue"
        elif grep -q "next" "$PROJECT_PATH/package.json"; then
            PROJECT_TYPE="nextjs"
        elif grep -q "express" "$PROJECT_PATH/package.json"; then
            PROJECT_TYPE="express"
        else
            PROJECT_TYPE="nodejs"
        fi
    elif [ -f "$PROJECT_PATH/requirements.txt" ]; then
        if [ -f "$PROJECT_PATH/manage.py" ]; then
            PROJECT_TYPE="django"
        elif grep -q "Flask" "$PROJECT_PATH/requirements.txt"; then
            PROJECT_TYPE="flask"
        else
            PROJECT_TYPE="python"
        fi
    elif [ -f "$PROJECT_PATH/build.gradle" ] || [ -f "$PROJECT_PATH/build.gradle.kts" ]; then
        if find "$PROJECT_PATH" -name "*.kt" | head -1 | grep -q "kt"; then
            PROJECT_TYPE="kotlin"
        else
            PROJECT_TYPE="java"
        fi
    elif [ -f "$PROJECT_PATH/Dockerfile" ]; then
        PROJECT_TYPE="docker"
    elif find "$PROJECT_PATH" -name "*.yaml" -o -name "*.yml" | grep -q "apiVersion"; then
        PROJECT_TYPE="kubernetes"
    else
        PROJECT_TYPE="unknown"
    fi
}

# Validar estructura básica
validate_basic_structure() {
    info "Validando estructura básica del proyecto..."
    
    local errors=0
    
    # README
    if [ -f "$PROJECT_PATH/README.md" ]; then
        log "README.md encontrado"
    else
        error "README.md no encontrado"
        ((errors++))
    fi
    
    # .gitignore
    if [ -f "$PROJECT_PATH/.gitignore" ]; then
        log ".gitignore encontrado"
    else
        warning ".gitignore no encontrado"
    fi
    
    return $errors
}

# Validar proyecto Python
validate_python() {
    info "Validando proyecto Python..."
    
    local errors=0
    
    # requirements.txt
    if [ -f "$PROJECT_PATH/requirements.txt" ]; then
        log "requirements.txt encontrado"
    else
        error "requirements.txt no encontrado"
        ((errors++))
    fi
    
    # Archivo principal
    if [ -f "$PROJECT_PATH/main.py" ] || [ -f "$PROJECT_PATH/app.py" ]; then
        log "Archivo principal Python encontrado"
    else
        error "Archivo principal Python no encontrado"
        ((errors++))
    fi
    
    # Sintaxis Python
    find "$PROJECT_PATH" -name "*.py" | while read -r file; do
        if python3 -m py_compile "$file" 2>/dev/null; then
            log "Sintaxis válida: $(basename "$file")"
        else
            error "Error de sintaxis: $file"
            ((errors++))
        fi
    done
    
    return $errors
}

# Validar proyecto Node.js
validate_nodejs() {
    info "Validando proyecto Node.js..."
    
    local errors=0
    
    # package.json
    if [ -f "$PROJECT_PATH/package.json" ]; then
        log "package.json encontrado"
        
        # Validar JSON
        if node -e "JSON.parse(require('fs').readFileSync('$PROJECT_PATH/package.json'))" 2>/dev/null; then
            log "package.json tiene formato JSON válido"
        else
            error "package.json tiene formato JSON inválido"
            ((errors++))
        fi
    else
        error "package.json no encontrado"
        ((errors++))
    fi
    
    # Scripts npm
    if grep -q '"scripts"' "$PROJECT_PATH/package.json" 2>/dev/null; then
        log "Scripts npm encontrados"
    else
        warning "No se encontraron scripts npm"
    fi
    
    return $errors
}

# Validar proyecto Docker
validate_docker() {
    info "Validando configuración Docker..."
    
    local errors=0
    
    # Dockerfile
    if [ -f "$PROJECT_PATH/Dockerfile" ]; then
        log "Dockerfile encontrado"
        
        # Validar sintaxis básica
        if grep -q "FROM" "$PROJECT_PATH/Dockerfile"; then
            log "Dockerfile tiene instrucción FROM"
        else
            error "Dockerfile no tiene instrucción FROM"
            ((errors++))
        fi
    else
        error "Dockerfile no encontrado"
        ((errors++))
    fi
    
    # docker-compose.yml
    if [ -f "$PROJECT_PATH/docker-compose.yml" ]; then
        log "docker-compose.yml encontrado"
    else
        warning "docker-compose.yml no encontrado"
    fi
    
    # .dockerignore
    if [ -f "$PROJECT_PATH/.dockerignore" ]; then
        log ".dockerignore encontrado"
    else
        warning ".dockerignore no encontrado"
    fi
    
    return $errors
}

# Validar proyecto Kubernetes
validate_kubernetes() {
    info "Validando configuración Kubernetes..."
    
    local errors=0
    
    # Archivos YAML
    local yaml_files=$(find "$PROJECT_PATH" -name "*.yaml" -o -name "*.yml" | wc -l)
    if [ "$yaml_files" -gt 0 ]; then
        log "$yaml_files archivos YAML encontrados"
    else
        error "No se encontraron archivos YAML"
        ((errors++))
    fi
    
    # Deployment
    if find "$PROJECT_PATH" -name "*.yaml" -o -name "*.yml" | xargs grep -l "kind: Deployment" >/dev/null 2>&1; then
        log "Deployment encontrado"
    else
        error "Deployment no encontrado"
        ((errors++))
    fi
    
    # Service
    if find "$PROJECT_PATH" -name "*.yaml" -o -name "*.yml" | xargs grep -l "kind: Service" >/dev/null 2>&1; then
        log "Service encontrado"
    else
        warning "Service no encontrado"
    fi
    
    return $errors
}

# Validar proyecto Gradle
validate_gradle() {
    info "Validando proyecto Gradle..."
    
    local errors=0
    
    # build.gradle o build.gradle.kts
    if [ -f "$PROJECT_PATH/build.gradle" ] || [ -f "$PROJECT_PATH/build.gradle.kts" ]; then
        log "Archivo build.gradle encontrado"
    else
        error "Archivo build.gradle no encontrado"
        ((errors++))
    fi
    
    # gradle wrapper
    if [ -f "$PROJECT_PATH/gradlew" ]; then
        log "Gradle wrapper encontrado"
    else
        warning "Gradle wrapper no encontrado"
    fi
    
    # settings.gradle
    if [ -f "$PROJECT_PATH/settings.gradle" ] || [ -f "$PROJECT_PATH/settings.gradle.kts" ]; then
        log "settings.gradle encontrado"
    else
        warning "settings.gradle no encontrado"
    fi
    
    return $errors
}

# Función principal de validación
main() {
    echo "🔍 Validando proyecto en: $PROJECT_PATH"
    echo
    
    if [ ! -d "$PROJECT_PATH" ]; then
        error "Directorio no encontrado: $PROJECT_PATH"
        exit 1
    fi
    
    cd "$PROJECT_PATH"
    
    detect_project_type
    info "Tipo de proyecto detectado: $PROJECT_TYPE"
    echo
    
    local total_errors=0
    
    # Validación básica
    validate_basic_structure
    ((total_errors += $?))
    echo
    
    # Validación específica por tipo
    case $PROJECT_TYPE in
        python|django|flask)
            validate_python
            ((total_errors += $?))
            ;;
        nodejs|react|vue|nextjs|express)
            validate_nodejs
            ((total_errors += $?))
            ;;
        docker)
            validate_docker
            ((total_errors += $?))
            ;;
        kubernetes)
            validate_kubernetes
            ((total_errors += $?))
            ;;
        kotlin|java)
            validate_gradle
            ((total_errors += $?))
            ;;
        unknown)
            warning "Tipo de proyecto desconocido, solo validación básica"
            ;;
    esac
    
    echo
    if [ $total_errors -eq 0 ]; then
        log "🎉 Validación completada sin errores"
        exit 0
    else
        error "❌ Validación completada con $total_errors errores"
        exit 1
    fi
}

# Mostrar ayuda
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    cat << EOF
🔍 Validador de Proyectos

Uso: $0 [DIRECTORIO]

Valida la estructura y configuración de un proyecto generado.

Argumentos:
  DIRECTORIO    Directorio del proyecto a validar (default: directorio actual)

Opciones:
  -h, --help    Mostrar esta ayuda

Tipos de proyecto soportados:
  - Python (Django, Flask)
  - Node.js (React, Vue, Next.js, Express)
  - Java/Kotlin (Gradle)
  - Docker
  - Kubernetes

Ejemplo:
  $0 mi-proyecto
  $0 /path/to/mi-proyecto
EOF
    exit 0
fi

# Ejecutar validación
main "$@"
