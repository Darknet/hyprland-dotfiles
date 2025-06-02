#!/bin/bash

# Script para inicializar nuevos proyectos
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Mostrar ayuda
show_help() {
    cat << EOF
🚀 Inicializador de Proyectos

Uso: $0 [OPCIONES] <tipo-proyecto> <nombre-proyecto>

Tipos de proyecto disponibles:
  python-basic    - Proyecto básico de Python
  nodejs-basic    - Proyecto básico de Node.js
  react-basic     - Aplicación React
  vue-basic       - Aplicación Vue.js
  django-basic    - Proyecto Django
  flask-basic     - Aplicación Flask
  express-basic   - API Express.js
  nextjs-basic    - Aplicación Next.js
  kotlin-basic    - Proyecto Kotlin
  gradle-basic    - Proyecto Java con Gradle
  docker          - Configuración Docker
  kubernetes      - Configuración Kubernetes

Opciones:
  -h, --help      Mostrar esta ayuda
  -d, --dir DIR   Directorio donde crear el proyecto (default: current)
  -g, --git       Inicializar repositorio Git
  -i, --install   Instalar dependencias automáticamente
  -v, --verbose   Modo verbose

Ejemplos:
  $0 python-basic mi-proyecto-python
  $0 nodejs-basic mi-api --git --install
  $0 react-basic mi-frontend -d ~/projects -g -i
EOF
}

# Parsear argumentos
INSTALL_DEPS=false
INIT_GIT=false
VERBOSE=false
TARGET_DIR="."

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -g|--git)
            INIT_GIT=true
            shift
            ;;
        -i|--install)
            INSTALL_DEPS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$PROJECT_TYPE" ]; then
                PROJECT_TYPE="$1"
            elif [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                error "Demasiados argumentos"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Verificar argumentos requeridos
if [ -z "$PROJECT_TYPE" ] || [ -z "$PROJECT_NAME" ]; then
    error "Se requieren tipo de proyecto y nombre"
    show_help
    exit 1
fi

# Verificar que el template existe
TEMPLATE_PATH="$TEMPLATES_DIR/$PROJECT_TYPE"
if [ ! -d "$TEMPLATE_PATH" ]; then
    error "Tipo de proyecto '$PROJECT_TYPE' no encontrado"
    echo "Templates disponibles:"
    ls -1 "$TEMPLATES_DIR" | grep -v scripts | sed 's/^/  - /'
    exit 1
fi

# Crear directorio del proyecto
PROJECT_PATH="$TARGET_DIR/$PROJECT_NAME"
if [ -d "$PROJECT_PATH" ]; then
    error "El directorio '$PROJECT_PATH' ya existe"
    exit 1
fi

log "Creando proyecto '$PROJECT_NAME' de tipo '$PROJECT_TYPE'"
mkdir -p "$PROJECT_PATH"

# Copiar template
log "Copiando archivos del template..."
cp -r "$TEMPLATE_PATH/"* "$PROJECT_PATH/" 2>/dev/null || true
cp -r "$TEMPLATE_PATH/".* "$PROJECT_PATH/" 2>/dev/null || true

# Personalizar archivos
log "Personalizando archivos..."
cd "$PROJECT_PATH"

# Reemplazar placeholders en archivos
find . -type f -name "*.md" -o -name "*.json" -o -name "*.py" -o -name "*.js" -o -name "*.kt" -o -name "*.gradle*" -o -name "*.yaml" -o -name "*.yml" | \
while read -r file; do
    if [ "$VERBOSE" = true ]; then
        log "Procesando: $file"
    fi
    
    # Reemplazos comunes
    sed -i.bak \
        -e "s/mi-proyecto-python/$PROJECT_NAME/g" \
        -e "s/proyecto-nodejs/$PROJECT_NAME/g" \
        -e "s/mi-app/$PROJECT_NAME/g" \
        -e "s/Mi Aplicación/$PROJECT_NAME/g" \
        -e "s/Tu Nombre/$(git config user.name 2>/dev/null || echo 'Tu Nombre')/g" \
        -e "s/tu.email@ejemplo.com/$(git config user.email 2>/dev/null || echo 'tu.email@ejemplo.com')/g" \
        -e "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" \
        "$file" && rm "${file}.bak"
done

# Hacer ejecutables los scripts
find . -name "*.sh" -exec chmod +x {} \;

# Inicializar Git si se solicita
if [ "$INIT_GIT" = true ]; then
    log "Inicializando repositorio Git..."
    git init
    git add .
    git commit -m "Initial commit: $PROJECT_TYPE project setup"
fi

# Instalar dependencias si se solicita
if [ "$INSTALL_DEPS" = true ]; then
    log "Instalando dependencias..."
    
    case $PROJECT_TYPE in
        python-*|django-*|flask-*)
            if command -v python3 &> /dev/null; then
                python3 -m venv venv
                source venv/bin/activate
                pip install -r requirements.txt 2>/dev/null || true
                pip install -r requirements-dev.txt 2>/dev/null || true
            fi
            ;;
        nodejs-*|react-*|vue-*|express-*|nextjs-*)
            if command -v npm &> /dev/null; then
                npm install
            elif command -v yarn &> /dev/null; then
                yarn install
            fi
            ;;
        kotlin-*|gradle-*)
            if command -v gradle &> /dev/null; then
                gradle build -x test
            elif [ -f "./gradlew" ]; then
                ./gradlew build -x test
            fi
            ;;
    esac
fi

# Mostrar información final
log "✅ Proyecto '$PROJECT_NAME' creado exitosamente en '$PROJECT_PATH'"
echo
echo -e "${BLUE}Próximos pasos:${NC}"
echo "  1. cd $PROJECT_PATH"

case $PROJECT_TYPE in
    python-*|django-*|flask-*)
        echo "  2. python3 -m venv venv && source venv/bin/activate"
        echo "  3. pip install -r requirements.txt"
        echo "  4. python main.py"
        ;;
    nodejs-*|express-*)
        echo "  2. npm install"
        echo "  3. npm run dev"
        ;;
    react-*|vue-*|nextjs-*)
        echo "  2. npm install"
        echo "  3. npm run dev"
        ;;
    kotlin-*|gradle-*)
        echo "  2. ./gradlew build"
        echo "  3. ./gradlew run"
        ;;
    docker)
        echo "  2. docker build -t $PROJECT_NAME ."
        echo "  3. docker run -p 3000:3000 $PROJECT_NAME"
        ;;
    kubernetes)
        echo "  2. kubectl apply -f ."
        echo "  3. kubectl get pods"
        ;;
esac

if [ "$INIT_GIT" = false ]; then
    echo "  💡 Considera inicializar Git: git init && git add . && git commit -m 'Initial commit'"
fi

echo
log "🎉 ¡Feliz codificación!"
