#!/bin/bash

# Script para configurar entorno de desarrollo local
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

# Detectar sistema operativo
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get >/dev/null 2>&1; then
            DISTRO="debian"
        elif command -v yum >/dev/null 2>&1; then
            DISTRO="rhel"
        elif command -v pacman >/dev/null 2>&1; then
            DISTRO="arch"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
}

# Instalar dependencias según el SO
install_dependencies() {
    log "Instalando dependencias para $OS..."
    
    case $OS in
        "linux")
            case $DISTRO in
                "debian")
                    sudo apt-get update
                    sudo apt-get install -y \
                        curl wget git vim tree jq unzip \
                        build-essential python3 python3-pip python3-venv \
                        nodejs npm shellcheck
                    ;;
                "rhel")
                    sudo yum update -y
                    sudo yum install -y \
                        curl wget git vim tree jq unzip \
                        gcc gcc-c++ make python3 python3-pip \
                        nodejs npm ShellCheck
                    ;;
                "arch")
                    sudo pacman -Syu --noconfirm
                    sudo pacman -S --noconfirm \
                        curl wget git vim tree jq unzip \
                        base-devel python python-pip \
                        nodejs npm shellcheck
                    ;;
            esac
            ;;
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                log "Instalando Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            brew update
            brew install \
                curl wget git vim tree jq \
                python3 node shellcheck \
                docker kubectl helm
            ;;
        "windows")
            warning "Para Windows, se recomienda usar WSL2 o Docker Desktop"
            warning "Instala manualmente: Git, Node.js, Python, Docker Desktop"
            ;;
        *)
            error "Sistema operativo no soportado: $OS"
            exit 1
            ;;
    esac
}

# Instalar Docker
install_docker() {
    if command -v docker >/dev/null 2>&1; then
        log "Docker ya está instalado"
        return
    fi
    
    log "Instalando Docker..."
    
    case $OS in
        "linux")
            curl -fsSL https://get.docker.com | sh
            sudo usermod -aG docker $USER
            warning "Reinicia la sesión para usar Docker sin sudo"
            ;;
        "macos")
            warning "Instala Docker Desktop desde https://www.docker.com/products/docker-desktop"
            ;;
        "windows")
            warning "Instala Docker Desktop desde https://www.docker.com/products/docker-desktop"
            ;;
    esac
}

# Instalar kubectl
install_kubectl() {
    if command -v kubectl >/dev/null 2>&1; then
        log "kubectl ya está instalado"
        return
    fi
    
    log "Instalando kubectl..."
    
    case $OS in
        "linux")
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
        "macos")
            brew install kubectl
            ;;
        "windows")
            warning "Instala kubectl usando chocolatey: choco install kubernetes-cli"
            ;;
    esac
}

# Configurar herramientas de desarrollo
setup_dev_tools() {
    log "Configurando herramientas de desarrollo..."
    
    # Instalar herramientas Node.js globales
    if command -v npm >/dev/null 2>&1; then
        npm install -g \
            prettier \
            eslint \
            @vue/cli \
            create-react-app \
            express-generator \
            npm-check-updates
    fi
    
    # Instalar herramientas Python
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user \
            black \
            flake8 \
            pytest \
            django \
            flask \
            fastapi \
            requests \
            pyyaml
    fi
}

# Configurar Git hooks
setup_git_hooks() {
    log "Configurando Git hooks..."
    
    cd "$PROJECT_ROOT"
    
    if [ ! -d ".git" ]; then
        warning "No es un repositorio Git, inicializando..."
        git init
    fi
    
    # Pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "🔍 Ejecutando verificaciones pre-commit..."

# Lint shell scripts
find scripts -name "*.sh" -exec shellcheck {} \; || {
    echo "❌ Error en shellcheck"
    exit 1
}

# Verificar archivos JSON
find . -name "*.json" -not -path "./node_modules/*" | head -10 | while read -r file; do
    if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        echo "❌ JSON inválido: $file"
        exit 1
    fi
done

# Verificar archivos YAML
find . -name "*.yml" -o -name "*.yaml" | head -10 | while read -r file; do
    if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo "❌ YAML inválido: $file"
        exit 1
    fi
done

echo "✅ Verificaciones completadas"
EOF

    chmod +x .git/hooks/pre-commit
    
    # Pre-push hook
    cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
echo "🧪 Ejecutando tests antes del push..."

# Ejecutar tests básicos
if [ -f "scripts/validate-project.sh" ]; then
    chmod +x scripts/*.sh
    
    # Test rápido de templates principales
    for template in python-basic nodejs-basic; do
        echo "Probando template: $template"
        rm -rf "test-$template" 2>/dev/null || true
        ./scripts/init-project.sh "$template" "test-$template" || {
            echo "❌ Error creando template $template"
            exit 1
        }
        rm -rf "test-$template"
    done
fi

echo "✅ Tests completados"
EOF

    chmod +x .git/hooks/pre-push
    
    log "Git hooks configurados"
}

# Configurar VS Code
setup_vscode() {
    if ! command -v code >/dev/null 2>&1; then
        warning "VS Code no está instalado, saltando configuración"
        return
    fi
    
    log "Configurando VS Code..."
    
    # Instalar extensiones recomendadas
    local extensions=(
        "ms-python.python"
        "ms-python.black-formatter"
        "ms-python.flake8"
        "esbenp.prettier-vscode"
        "ms-vscode.vscode-json"
        "redhat.vscode-yaml"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "ms-azuretools.vscode-docker"
        "timonwong.shellcheck"
        "foxundermoon.shell-format"
        "ms-vscode.makefile-tools"
    )
    
    for ext in "${extensions[@]}"; do
        code --install-extension "$ext" --force
    done
    
    # Crear configuración de workspace
    mkdir -p .vscode
    cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.formatting.provider": "black",
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll": true
    },
    "files.associations": {
        "*.yml": "yaml",
        "*.yaml": "yaml",
        "Dockerfile*": "dockerfile",
        "*.sh": "shellscript"
    },
    "yaml.schemas": {
        "https://json.schemastore.org/github-workflow.json": ".github/workflows/*.yml",
        "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json": "docker-compose*.yml"
    },
    "shellcheck.enable": true,
    "terminal.integrated.defaultProfile.linux": "bash"
}
EOF

    cat > .vscode/extensions.json << 'EOF'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.black-formatter",
        "ms-python.flake8",
        "esbenp.prettier-vscode",
        "ms-vscode.vscode-json",
        "redhat.vscode-yaml",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "ms-azuretools.vscode-docker",
        "timonwong.shellcheck",
        "foxundermoon.shell-format",
        "ms-vscode.makefile-tools"
    ]
}
EOF

    log "VS Code configurado"
}

# Crear archivos de configuración
create_config_files() {
    log "Creando archivos de configuración..."
    
    cd "$PROJECT_ROOT"
    
    # .editorconfig
    if [ ! -f ".editorconfig" ]; then
        cat > .editorconfig << 'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[*.py]
indent_size = 4

[*.{sh,bash}]
indent_size = 4

[Makefile]
indent_style = tab
EOF
    fi
    
    # .prettierrc
    if [ ! -f ".prettierrc" ]; then
        cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false
}
EOF
    fi
    
    # .flake8
    if [ ! -f ".flake8" ]; then
        cat > .flake8 << 'EOF'
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = 
    .git,
    __pycache__,
    venv,
    .venv,
    node_modules
EOF
    fi
    
    log "Archivos de configuración creados"
}

# Verificar instalación
verify_installation() {
    log "Verificando instalación..."
    
    local errors=0
    
    # Verificar herramientas básicas
    local tools=("git" "node" "npm" "python3" "pip3")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log "✅ $tool: $(command -v "$tool")"
        else
            error "❌ $tool no encontrado"
            ((errors++))
        fi
    done
    
    # Verificar herramientas opcionales
    local optional_tools=("docker" "kubectl" "shellcheck" "black" "prettier")
    
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log "✅ $tool: $(command -v "$tool")"
        else
            warning "⚠️  $tool no encontrado (opcional)"
        fi
    done
    
    # Verificar scripts
    chmod +x "$SCRIPT_DIR"/*.sh
    
    if [ $errors -eq 0 ]; then
        log "🎉 Entorno configurado correctamente"
    else
        error "❌ Se encontraron $errors errores"
        exit 1
    fi
}

# Mostrar resumen
show_summary() {
    echo
    log "📋 Resumen de configuración:"
    echo "  • Sistema operativo: $OS"
    [ -n "$DISTRO" ] && echo "  • Distribución: $DISTRO"
    echo "  • Directorio del proyecto: $PROJECT_ROOT"
    echo "  • Scripts disponibles:"
    echo "    - make help (mostrar ayuda)"
    echo "    - make init PROJECT_NAME=mi-proyecto (crear proyecto)"
    echo "    - make validate PROJECT_NAME=mi-proyecto (validar proyecto)"
    echo "    - make test (ejecutar tests)"
    echo
    log "🚀 ¡Entorno listo para desarrollo!"
    echo
    warning "💡 Consejos:"
    echo "  • Reinicia tu terminal para aplicar todos los cambios"
    echo "  • Ejecuta 'make help' para ver comandos disponibles"
    echo "  • Usa 'make init' para crear tu primer proyecto"
}

# Función principal
main() {
    echo "🛠️  Configurando entorno de desarrollo..."
    echo
    
    detect_os
    info "Sistema detectado: $OS"
    
    # Verificar si es ejecución con --minimal
    if [[ "$1" == "--minimal" ]]; then
        log "Configuración mínima solicitada"
        setup_git_hooks
        create_config_files
        chmod +x "$SCRIPT_DIR"/*.sh
        verify_installation
        show_summary
        return
    fi
    
    # Configuración completa
    install_dependencies
    install_docker
    install_kubectl
    setup_dev_tools
    setup_git_hooks
    setup_vscode
    create_config_files
    verify_installation
    show_summary
}

# Mostrar ayuda
show_help() {
    echo "🛠️  Script de configuración del entorno de desarrollo"
    echo
    echo "Uso: $0 [opciones]"
    echo
    echo "Opciones:"
    echo "  --minimal     Configuración mínima (solo Git hooks y configs)"
    echo "  --help        Mostrar esta ayuda"
    echo
    echo "Este script configura automáticamente:"
    echo "  • Dependencias del sistema (Git, Node.js, Python, etc.)"
    echo "  • Docker y Kubernetes tools"
    echo "  • Herramientas de desarrollo (linters, formatters)"
    echo "  • Git hooks para pre-commit y pre-push"
    echo "  • Configuración de VS Code"
    echo "  • Archivos de configuración (.editorconfig, .prettierrc, etc.)"
    echo
    echo "Sistemas soportados:"
    echo "  • Linux (Ubuntu/Debian, RHEL/CentOS, Arch)"
    echo "  • macOS (con Homebrew)"
    echo "  • Windows (WSL recomendado)"
}

# Manejar argumentos
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --minimal)
        main --minimal
        ;;
    *)
        main
        ;;
esac
