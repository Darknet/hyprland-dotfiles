#!/bin/bash

# Applications Setup Script
# Instalación y configuración de aplicaciones esenciales

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
LOG_FILE="${SCRIPT_DIR}/../../logs/apps_setup_$(date +%Y%m%d_%H%M%S).log"

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

# Detectar helper de AUR
detect_aur_helper() {
    if command -v yay &>/dev/null; then
        echo "yay"
    elif command -v paru &>/dev/null; then
        echo "paru"
    else
        echo ""
    fi
}

# Instalar helper de AUR si no existe
install_aur_helper() {
    local aur_helper=$(detect_aur_helper)
    
    if [[ -z "$aur_helper" ]]; then
        log "Instalando helper de AUR (yay)..."
        
        # Instalar dependencias
        sudo pacman -S --needed --noconfirm git base-devel
        
        # Clonar y compilar yay
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd "$HOME"
        rm -rf "$temp_dir"
        
        log "✓ Yay instalado exitosamente"
    else
        log "✓ Helper de AUR detectado: $aur_helper"
    fi
}

# Mostrar menú de categorías de aplicaciones
show_apps_menu() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  INSTALACIÓN DE APLICACIONES                ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  1. Aplicaciones esenciales (Recomendado)                   ║"
    echo "║  2. Desarrollo y programación                                ║"
    echo "║  3. Multimedia y entretenimiento                             ║"
    echo "║  4. Productividad y oficina                                  ║"
    echo "║  5. Juegos y gaming                                          ║"
    echo "║  6. Herramientas de sistema                                  ║"
    echo "║  7. Navegadores web                                          ║"
    echo "║  8. Comunicación                                             ║"
    echo "║  9. Instalación personalizada                                ║"
    echo "║  10. Instalar todo                                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Aplicaciones esenciales
install_essential_apps() {
    log "Instalando aplicaciones esenciales..."
    
    local aur_helper=$(detect_aur_helper)
    
    # Aplicaciones del repositorio oficial
    sudo pacman -S --needed --noconfirm \
        firefox \
        kitty \
        thunar \
        thunar-volman \
        thunar-archive-plugin \
        file-roller \
        gvfs \
        gvfs-mtp \
        gvfs-gphoto2 \
        tumbler \
        ffmpegthumbnailer \
        poppler-glib \
        libgsf \
        raw-thumbnailer \
        totem \
        vlc \
        mpv \
        imv \
        gimp \
        libreoffice-fresh \
        libreoffice-fresh-es \
        thunderbird \
        neofetch \
        htop \
        btop \
        tree \
        wget \
        curl \
        git \
        vim \
        nano \
        unzip \
        zip \
        p7zip \
        unrar \
        rsync \
        openssh \
        networkmanager \
        network-manager-applet \
        bluez \
        bluez-utils \
        blueman \
        pavucontrol \
        alsa-utils \
        pipewire \
        pipewire-alsa \
        pipewire-pulse \
        pipewire-jack \
        wireplumber
    
    # Aplicaciones de AUR
    if [[ -n "$aur_helper" ]]; then
        $aur_helper -S --needed --noconfirm \
            visual-studio-code-bin \
            google-chrome \
            discord \
            spotify \
            telegram-desktop \
            whatsapp-for-linux \
            zoom \
            obs-studio \
            steam \
            lutris \
            heroic-games-launcher-bin \
            bottles \
            timeshift \
            timeshift-autosnap \
            balena-etcher \
            ventoy-bin \
            anydesk-bin \
            teamviewer \
            dropbox \
            onlyoffice-bin \
            wps-office \
            masterpdfeditor \
            figma-linux \
            postman-bin \
            insomnia \
            dbeaver \
            android-studio \
            flutter \
            nodejs \
            npm \
            yarn \
            docker \
            docker-compose \
            virtualbox \
            virtualbox-host-modules-arch \
            vmware-workstation \
            qemu \
            virt-manager \
            wireshark-qt \
            nmap \
            metasploit \
            burpsuite \
            john \
            hashcat \
            aircrack-ng \
            ettercap \
            sqlmap \
            nikto \
            dirb \
            gobuster \
            ffuf \
            nuclei \
            subfinder \
            httpx \
            katana \
            gau \
            waybackurls \
            anew \
            notify \
            dalfox \
            gf \
            qsreplace \
            freq \
            dnsx \
            shuffledns \
            puredns \
            massdns \
            amass \
            assetfinder \
            findomain \
            chaos-client \
            shodan \
            censys \
            bbot \
            reconftw \
            osmedeus \
            axiom \
            projectdiscovery-toolkit
    fi
    
    log "✓ Aplicaciones esenciales instaladas"
}

# Aplicaciones de desarrollo
install_development_apps() {
    log "Instalando aplicaciones de desarrollo..."
    
    local aur_helper=$(detect_aur_helper)
    
    # Repositorio oficial
    sudo pacman -S --needed --noconfirm \
        code \
        git \
        github-cli \
        nodejs \
        npm \
        python \
        python-pip \
        python-virtualenv \
        python-pipenv \
        go \
        rust \
        cargo \
        java-runtime-common \
        jdk-openjdk \
        maven \
        gradle \
        docker \
        docker-compose \
        kubectl \
        helm \
        terraform \
        ansible \
        vagrant \
        virtualbox \
        qemu \
        libvirt \
        virt-manager \
        wireshark-qt \
        nmap \
        tcpdump \
        strace \
        gdb \
        valgrind \
        perf \
        htop \
        iotop \
        nethogs \
        bandwhich \
        fd \
        ripgrep \
        bat \
        exa \
        zoxide \
        fzf \
        tmux \
        screen \
        neovim \
        emacs \
        vim
    
    # AUR
    if [[ -n "$aur_helper" ]]; then
        $aur_helper -S --needed --noconfirm \
            visual-studio-code-bin \
            jetbrains-toolbox \
            android-studio \
            flutter \
            dart \
            postman-bin \
            insomnia \
            dbeaver \
            mongodb-compass \
            robo3t-bin \
            redis-desktop-manager \
            pgadmin4 \
            mysql-workbench \
            sequel-pro \
            tableplus \
            datagrip \
            webstorm \
            phpstorm \
            pycharm-professional \
            intellij-idea-ultimate-edition \
            clion \
            rider \
            goland \
            rubymine \
            appcode \
            datagrip \
            slack-desktop \
            discord \
            telegram-desktop \
            zoom \
            teams \
            skype \
            notion-app \
            obsidian \
            logseq \
            typora \
            mark-text \
            zettlr \
            vnote \
            ghostwriter \
            remarkable \
            xournalpp \
            drawio-desktop \
            lucidchart \
            miro \
            figma-linux \
            sketch \
            invision \
            principle \
            framer \
            protopie \
            marvel \
            balsamiq-mockups \
            axure-rp \
            justinmind \
            mockplus \
            proto-io \
            fluid-ui \
            origami-studio \
            flinto \
            atomic \
            uxpin \
            avocode \
            zeplin \
            sympli \
            marvel-app
    fi
    
    # Configurar entornos de desarrollo
    setup_development_environment
    
    log "✓ Aplicaciones de desarrollo instaladas"
}

# Configurar entorno de desarrollo
setup_development_environment() {
    log "Configurando entorno de desarrollo..."
    
    # Configurar Git si no está configurado
    if ! git config --global user.name &>/dev/null; then
        echo -n "Introduce tu nombre para Git: "
        read -r git_name
        git config --global user.name "$git_name"
    fi
    
    if ! git config --global user.email &>/dev/null; then
        echo -n "Introduce tu email para Git: "
        read -r git_email
        git config --global user.email "$git_email"
    fi
    
    # Configuraciones adicionales de Git
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    git config --global core.editor "code --wait"
    git config --global merge.tool vscode
    git config --global mergetool.vscode.cmd 'code --wait $MERGED'
    git config --global diff.tool vscode
    git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
    
    # Configurar SSH para Git
    if [[ ! -f "${HOME}/.ssh/id_rsa" ]] && [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then
        if ask_question "¿Generar clave SSH para Git?"; then
            ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "${HOME}/.ssh/id_ed25519" -N ""
            eval "$(ssh-agent -s)"
            ssh-add "${HOME}/.ssh/id_ed25519"
            
            echo -e "${CYAN}Clave SSH generada. Añade esta clave a tu cuenta de GitHub/GitLab:${NC}"
            cat "${HOME}/.ssh/id_ed25519.pub"
            
            # Configurar SSH config
            mkdir -p "${HOME}/.ssh"
            cat >> "${HOME}/.ssh/config" << EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
EOF
            chmod 600 "${HOME}/.ssh/config"
        fi
    fi
    
    # Instalar extensiones de VSCode
    if command -v code &>/dev/null; then
        log "Instalando extensiones de VSCode..."
        
        local vscode_extensions=(
            # Lenguajes de programación
            "ms-python.python"
            "ms-python.pylint"
            "ms-python.black-formatter"
            "ms-python.isort"
            "ms-vscode.cpptools"
            "ms-vscode.cpptools-extension-pack"
            "rust-lang.rust-analyzer"
            "golang.go"
            "ms-vscode.vscode-typescript-next"
            "ms-dotnettools.csharp"
            "ms-dotnettools.vscode-dotnet-runtime"
            "oracle.oracle-java"
            "redhat.java"
            "vscjava.vscode-java-pack"
            "ms-vscode.powershell"
            "ms-vscode.cmake-tools"
            "twxs.cmake"
            "ms-vscode.makefile-tools"
            
            # Web Development
            "bradlc.vscode-tailwindcss"
            "esbenp.prettier-vscode"
            "ms-vscode.vscode-eslint"
            "formulahendry.auto-rename-tag"
            "christian-kohler.path-intellisense"
            "ms-vscode.vscode-json"
            "redhat.vscode-yaml"
            "ms-vscode.vscode-css-peek"
            "zignd.html-css-class-completion"
            "pranaygp.vscode-css-peek"
            "bradlc.vscode-tailwindcss"
            "ms-vscode.vscode-html-languageservice"
            
            # Frameworks y librerías
            "ms-vscode.vscode-react-native"
            "ms-vscode.vscode-node-azure-pack"
            "ms-python.flake8"
            "ms-python.mypy-type-checker"
            "ms-toolsai.jupyter"
            "ms-toolsai.jupyter-keymap"
            "ms-toolsai.jupyter-renderers"
            "dart-code.dart-code"
            "dart-code.flutter"
            "pivotal.vscode-spring-boot"
            "vmware.vscode-spring-boot-dashboard"
            "gabrielbb.vscode-lombok"
            
            # DevOps y Cloud
            "ms-kubernetes-tools.vscode-kubernetes-tools"
            "ms-azuretools.vscode-docker"
            "hashicorp.terraform"
            "ms-vscode-remote.remote-ssh"
            "ms-vscode-remote.remote-containers"
            "ms-vscode-remote.remote-wsl"
            "ms-azuretools.vscode-azureresourcegroups"
            "amazonwebservices.aws-toolkit-vscode"
            "googlecloudtools.cloudcode"
            
            # Git y control de versiones
            "github.copilot"
            "github.copilot-chat"
            "github.vscode-pull-request-github"
            "eamodio.gitlens"
            "mhutchie.git-graph"
            "donjayamanne.githistory"
            "codezombiech.gitignore"
            "github.vscode-github-actions"
            
            # Bases de datos
            "ms-mssql.mssql"
            "oracle.oracledevtools"
            "mtxr.sqltools"
            "mtxr.sqltools-driver-mysql"
            "mtxr.sqltools-driver-pg"
            "mtxr.sqltools-driver-sqlite"
            "mongodb.mongodb-vscode"
            
            # Herramientas de desarrollo
            "ms-vscode.hexeditor"
            "ms-vscode.vscode-serial-monitor"
            "platformio.platformio-ide"
            "vadimcn.vscode-lldb"
            "sonarsource.sonarlint-vscode"
            "shengchen.vscode-checkstyle"
            "redhat.vscode-xml"
            "dotjoshjohnson.xml"
            "ms-vscode.test-adapter-converter"
            "hbenl.vscode-test-explorer"
            
            # Productividad
            "ms-vscode.vscode-todo-highlight"
            "gruntfuggly.todo-tree"
            "streetsidesoftware.code-spell-checker"
            "streetsidesoftware.code-spell-checker-spanish"
            "ms-vscode.wordcount"
            "alefragnani.bookmarks"
            "formulahendry.code-runner"
            "ms-vscode.vscode-speech"
            
            # Temas y apariencia
            "pkief.material-icon-theme"
            "ms-vscode.theme-monokai-dimmed"
            "github.github-vscode-theme"
            "dracula-theme.theme-dracula"
            "monokai.theme-monokai-pro-vscode"
            
            # Documentación
            "yzhang.markdown-all-in-one"
            "shd101wyy.markdown-preview-enhanced"
            "davidanson.vscode-markdownlint"
            "ms-vscode.vscode-markdown"
            "bierner.markdown-mermaid"
            
            # API Development
            "humao.rest-client"
            "rangav.vscode-thunder-client"
            "ms-vscode.vscode-httpyac"
        )
        
        # Instalar extensiones con manejo de errores
        local installed_count=0
        local failed_extensions=()
        
        for extension in "${vscode_extensions[@]}"; do
            if code --install-extension "$extension" --force &>/dev/null; then
                ((installed_count++))
            else
                failed_extensions+=("$extension")
                warning "Falló la instalación de la extensión: $extension"
            fi
        done
        
        log "✓ Extensiones de VSCode instaladas: $installed_count/${#vscode_extensions[@]}"
        
        if [[ ${#failed_extensions[@]} -gt 0 ]]; then
            warning "Extensiones que fallaron: ${failed_extensions[*]}"
        fi
    fi
    
    # Configurar Node.js y npm
    if command -v npm &>/dev/null; then
        log "Configurando Node.js y npm..."
        
        # Configurar npm para usar directorio global sin sudo
        mkdir -p "${HOME}/.npm-global"
        npm config set prefix "${HOME}/.npm-global"
        
        # Añadir al PATH si no está
        if ! grep -q "/.npm-global/bin" "${HOME}/.bashrc"; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "${HOME}/.bashrc"
        fi
        
        # Instalar paquetes globales útiles
        local npm_packages=(
            "typescript"
            "ts-node"
            "@types/node"
            "nodemon"
            "pm2"
            "http-server"
            "live-server"
            "json-server"
            "create-react-app"
            "create-next-app"
            "@vue/cli"
            "@angular/cli"
            "express-generator"
            "nest"
            "prisma"
            "typeorm"
            "sequelize-cli"
            "knex"
            "eslint"
            "prettier"
            "stylelint"
            "sass"
            "less"
            "postcss-cli"
            "autoprefixer"
            "webpack"
            "webpack-cli"
            "vite"
            "rollup"
            "parcel"
            "gulp-cli"
            "grunt-cli"
            "yarn"
            "pnpm"
            "npm-check-updates"
            "depcheck"
            "license-checker"
            "semantic-release"
            "commitizen"
            "husky"
            "lint-staged"
        )
        
        for package in "${npm_packages[@]}"; do
            if npm install -g "$package" &>/dev/null; then
                info "✓ Instalado: $package"
            else
                warning "✗ Falló: $package"
            fi
        done
        
        log "✓ Configuración de Node.js completada"
    fi
    
    # Configurar Python
    if command -v python &>/dev/null; then
        log "Configurando Python..."
        
        # Instalar paquetes Python útiles
        local python_packages=(
            "pip"
            "setuptools"
            "wheel"
            "virtualenv"
            "pipenv"
            "poetry"
            "black"
            "flake8"
            "pylint"
            "mypy"
            "pytest"
            "pytest-cov"
            "jupyter"
            "jupyterlab"
            "notebook"
            "ipython"
            "requests"
            "flask"
            "django"
            "fastapi"
            "uvicorn"
            "gunicorn"
            "celery"
            "redis"
            "sqlalchemy"
            "alembic"
            "psycopg2-binary"
            "pymongo"
            "pandas"
            "numpy"
            "matplotlib"
            "seaborn"
            "scikit-learn"
            "tensorflow"
            "torch"
            "opencv-python"
            "pillow"
            "beautifulsoup4"
            "scrapy"
            "selenium"
            "pydantic"
            "typer"
            "rich"
            "click"
            "python-dotenv"
            "pre-commit"
        )
        
        for package in "${python_packages[@]}"; do
            if pip install --user "$package" &>/dev/null; then
                info "✓ Instalado: $package"
            else
                warning "✗ Falló: $package"
            fi
        done
        
        log "✓ Configuración de Python completada"
    fi
    
    # Configurar Docker
    if command -v docker &>/dev/null; then
        log "Configurando Docker..."
        
        # Añadir usuario al grupo docker
        sudo usermod -aG docker "$USER"
        
        # Habilitar y iniciar servicios
        sudo systemctl enable docker
        sudo systemctl start docker
        
        # Configurar Docker Compose
        if command -v docker-compose &>/dev/null; then
            log "✓ Docker Compose disponible"
        fi
        
        log "✓ Configuración de Docker completada"
        warning "Necesitarás reiniciar la sesión para usar Docker sin sudo"
    fi
    
    # Configurar Rust
    if command -v rustc &>/dev/null; then
        log "Configurando Rust..."
        
        # Instalar componentes adicionales
        rustup component add clippy
        rustup component add rustfmt
        rustup component add rust-analyzer
        
        # Instalar herramientas útiles
        local rust_tools=(
            "cargo-edit"
            "cargo-watch"
            "cargo-expand"
            "cargo-outdated"
            "cargo-audit"
            "cargo-tree"
            "cargo-bloat"
            "cargo-deps"
            "cargo-make"
            "cargo-generate"
            "serde"
            "tokio"
            "clap"
            "reqwest"
        )
        
        for tool in "${rust_tools[@]}"; do
            if cargo install "$tool" &>/dev/null; then
                info "✓ Instalado: $tool"
            else
                warning "✗ Falló: $tool"
            fi
        done
        
        log "✓ Configuración de Rust completada"
    fi
    
    # Configurar Go
    if command -v go &>/dev/null; then
        log "Configurando Go..."
        
        # Configurar GOPATH si no está configurado
        if [[ -z "$GOPATH" ]]; then
            echo 'export GOPATH="$HOME/go"' >> "${HOME}/.bashrc"
            echo 'export PATH="$GOPATH/bin:$PATH"' >> "${HOME}/.bashrc"
            export GOPATH="$HOME/go"
            export PATH="$GOPATH/bin:$PATH"
        fi
        
        mkdir -p "$GOPATH/src" "$GOPATH/bin" "$GOPATH/pkg"
        
        # Instalar herramientas útiles
        local go_tools=(
            "golang.org/x/tools/gopls@latest"
            "github.com/go-delve/delve/cmd/dlv@latest"
            "golang.org/x/tools/cmd/goimports@latest"
            "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
            "github.com/cosmtrek/air@latest"
            "github.com/swaggo/swag/cmd/swag@latest"
            "github.com/golang-migrate/migrate/v4/cmd/migrate@latest"
            "github.com/pressly/goose/v3/cmd/goose@latest"
            "github.com/goreleaser/goreleaser@latest"
            "github.com/securecodewarrior/sast-scan@latest"
            "github.com/mgechev/revive@latest"
            "honnef.co/go/tools/cmd/staticcheck@latest"
            "github.com/kisielk/errcheck@latest"
            "golang.org/x/vuln/cmd/govulncheck@latest"
        )
        
        for tool in "${go_tools[@]}"; do
            if go install "$tool" &>/dev/null; then
                info "✓ Instalado: $tool"
            else
                warning "✗ Falló: $tool"
            fi
        done
        
        log "✓ Configuración de Go completada"
    fi
    
    # Configurar Java
    if command -v java &>/dev/null; then
        log "Configurando Java..."
        
        # Configurar JAVA_HOME si no está configurado
        local java_home=$(readlink -f /usr/bin/java | sed "s:bin/java::")
        if [[ -z "$JAVA_HOME" ]]; then
            echo "export JAVA_HOME=\"$java_home\"" >> "${HOME}/.bashrc"
            export JAVA_HOME="$java_home"
        fi
        
        # Configurar Maven si está instalado
        if command -v mvn &>/dev/null; then
            mkdir -p "${HOME}/.m2"
            
            # Crear settings.xml básico si no existe
            if [[ ! -f "${HOME}/.m2/settings.xml" ]]; then
                cat > "${HOME}/.m2/settings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
  
  <localRepository>${user.home}/.m2/repository</localRepository>
  
  <profiles>
    <profile>
      <id>default</id>
      <repositories>
        <repository>
          <id>central</id>
          <url>https://repo1.maven.org/maven2</url>
          <releases>
            <enabled>true</enabled>
          </releases>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>
  
  <activeProfiles>
    <activeProfile>default</activeProfile>
  </activeProfiles>
  
</settings>
EOF
            fi
        fi
        
        log "✓ Configuración de Java completada"
    fi
    
    # Configurar bases de datos de desarrollo
    setup_development_databases
    
    # Configurar herramientas de contenedores
    setup_container_tools
    
    # Configurar herramientas de monitoreo
    setup_monitoring_tools
    
    # Crear estructura de directorios de desarrollo
    create_development_directories
    
    # Configurar aliases útiles
    setup_development_aliases
    
    # Configurar variables de entorno
    setup_environment_variables
    
    log "✓ Configuración del entorno de desarrollo completada"
}

# Configurar bases de datos de desarrollo
setup_development_databases() {
    log "Configurando bases de datos de desarrollo..."
    
    # PostgreSQL
    if command -v psql &>/dev/null; then
        log "Configurando PostgreSQL..."
        
        # Inicializar base de datos si es necesario
        if [[ ! -d /var/lib/postgres/data ]]; then
            sudo -u postgres initdb -D /var/lib/postgres/data
        fi
        
        # Habilitar y iniciar servicio
        sudo systemctl enable postgresql
        sudo systemctl start postgresql
        
        # Crear usuario de desarrollo
        if ask_question "¿Crear usuario de desarrollo para PostgreSQL?"; then
            echo -n "Nombre de usuario: "
            read -r pg_user
            sudo -u postgres createuser --interactive "$pg_user"
            sudo -u postgres createdb "$pg_user"
        fi
    fi
    
    # MySQL/MariaDB
    if command -v mysql &>/dev/null; then
        log "Configurando MySQL/MariaDB..."
        
        sudo systemctl enable mariadb
        sudo systemctl start mariadb
        
        if ask_question "¿Ejecutar mysql_secure_installation?"; then
            sudo mysql_secure_installation
        fi
    fi
    
    # MongoDB
    if command -v mongod &>/dev/null; then
        log "Configurando MongoDB..."
        
        sudo systemctl enable mongodb
        sudo systemctl start mongodb
    fi
    
    # Redis
    if command -v redis-server &>/dev/null; then
        log "Configurando Redis..."
        
        sudo systemctl enable redis
        sudo systemctl start redis
    fi
    
    log "✓ Configuración de bases de datos completada"
}

# Configurar herramientas de contenedores
setup_container_tools() {
    log "Configurando herramientas de contenedores..."
    
    # Kubernetes
    if command -v kubectl &>/dev/null; then
        # Configurar autocompletado
        echo 'source <(kubectl completion bash)' >> "${HOME}/.bashrc"
        echo 'alias k=kubectl' >> "${HOME}/.bashrc"
        echo 'complete -F __start_kubectl k' >> "${HOME}/.bashrc"
        
        # Crear directorio de configuración
        mkdir -p "${HOME}/.kube"
    fi
    
    # Helm
    if command -v helm &>/dev/null; then
        echo 'source <(helm completion bash)' >> "${HOME}/.bashrc"
        
        # Añadir repositorios útiles
        helm repo add stable https://charts.helm.sh/stable
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo update
    fi
    
    # Terraform
    if command -v terraform &>/dev/null; then
        echo 'complete -C /usr/bin/terraform terraform' >> "${HOME}/.bashrc"
        
        # Crear directorio de configuración
        mkdir -p "${HOME}/.terraform.d"
    fi
    
    log "✓ Configuración de herramientas de contenedores completada"
}

# Configurar herramientas de monitoreo
setup_monitoring_tools() {
    log "Configurando herramientas de monitoreo..."
    
    # Configurar htop
    if command -v htop &>/dev/null; then
        mkdir -p "${HOME}/.config/htop"
        cat > "${HOME}/.config/htop/htoprc" << 'EOF'
fields=0 48 17 18 38 39 40 2 46 47 49 1
sort_key=46
sort_direction=1
hide_threads=0
hide_kernel_threads=1
hide_userland_threads=0
shadow_other_users=0
show_thread_names=0
show_program_path=1
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
tree_view=0
header_margin=1
detailed_cpu_time=0
cpu_count_from_zero=0
update_process_names=0
account_guest_in_cpu_meter=0
color_scheme=0
delay=15
left_meters=LeftCPUs Memory Swap
left_meter_modes=1 1 1
right_meters=RightCPUs Tasks LoadAverage Uptime
right_meter_modes=1 2 2 2
EOF
    fi
    
    log "✓ Configuración de herramientas de monitoreo completada"
}

# Crear estructura de directorios de desarrollo
create_development_directories() {
    log "Creando estructura de directorios de desarrollo..."
    
    local dev_dirs=(
        "${HOME}/Development"
        "${HOME}/Development/projects"
        "${HOME}/Development/playground"
        "${HOME}/Development/learning"
        "${HOME}/Development/tools"
        "${HOME}/Development/scripts"
        "${HOME}/Development/templates"
        "${HOME}/Development/docker"
        "${HOME}/Development/kubernetes"
        "${HOME}/Development/terraform"
        "${HOME}/Development/ansible"
        "${HOME}/Development/databases"
        "${HOME}/Development/apis"
        "${HOME}/Development/mobile"
        "${HOME}/Development/web"
        "${HOME}/Development/desktop"
        "${HOME}/Development/cli"
        "${HOME}/Development/libraries"
        "${HOME}/Development/frameworks"
        "${HOME}/Development/microservices"
        "${HOME}/Development/serverless"
        "${HOME}/Development/blockchain"
        "${HOME}/Development/ai-ml"
        "${HOME}/Development/iot"
        "${HOME}/Development/game-dev"
        "${HOME}/Development/devops"
        "${HOME}/Development/security"
        "${HOME}/Development/testing"
        "${HOME}/Development/documentation"
        "${HOME}/Development/resources"
        "${HOME}/Development/backups"
    )
    
    for dir in "${dev_dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    # Crear archivos README en directorios principales
    cat > "${HOME}/Development/README.md" << 'EOF'
# Development Directory Structure

## Directories

- **projects/**: Main development projects
- **playground/**: Experimental code and quick tests
- **learning/**: Learning materials and tutorials
- **tools/**: Development tools and utilities
- **scripts/**: Automation and helper scripts
- **templates/**: Project templates and boilerplates
- **docker/**: Docker configurations and Dockerfiles
- **kubernetes/**: Kubernetes manifests and configurations
- **terraform/**: Infrastructure as Code
- **ansible/**: Configuration management
- **databases/**: Database schemas and migrations
- **apis/**: API development and documentation
- **mobile/**: Mobile application development
- **web/**: Web development projects
- **desktop/**: Desktop application development
- **cli/**: Command-line tools and applications
- **libraries/**: Reusable libraries and components
- **frameworks/**: Custom frameworks and extensions
- **microservices/**: Microservices architecture projects
- **serverless/**: Serverless functions and applications
- **blockchain/**: Blockchain and cryptocurrency projects
- **ai-ml/**: Artificial Intelligence and Machine Learning
- **iot/**: Internet of Things projects
- **game-dev/**: Game development projects
- **devops/**: DevOps tools and configurations
- **security/**: Security tools and penetration testing
- **testing/**: Testing frameworks and test suites
- **documentation/**: Project documentation and wikis
- **resources/**: Development resources and references
- **backups/**: Project backups and archives

## Usage

Each directory contains projects organized by technology, purpose, or client.
Use consistent naming conventions and maintain proper documentation.
EOF
    
    log "✓ Estructura de directorios de desarrollo creada"
}

# Configurar aliases útiles para desarrollo
setup_development_aliases() {
    log "Configurando aliases de desarrollo..."
    
    # Crear archivo de aliases si no existe
    if [[ ! -f "${HOME}/.bash_aliases" ]]; then
        touch "${HOME}/.bash_aliases"
        echo 'source ~/.bash_aliases' >> "${HOME}/.bashrc"
    fi
    
    # Añadir aliases de desarrollo
    cat >> "${HOME}/.bash_aliases" << 'EOF'

# Development Aliases
alias dev='cd ~/Development'
alias projects='cd ~/Development/projects'
alias playground='cd ~/Development/playground'
alias scripts='cd ~/Development/scripts'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git rebase'
alias glog='git log --oneline --graph --decorate'
alias gstash='git stash'
alias gpop='git stash pop'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias drmi='docker rmi'
alias drm='docker rm'
alias dexec='docker exec -it'
alias dlogs='docker logs'
alias dstop='docker stop $(docker ps -q)'
alias dclean='docker system prune -f'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
alias kapply='kubectl apply -f'
alias kdelete='kubectl delete -f'

# Python aliases
alias py='python'
alias py3='python3'
alias pip='pip3'
alias venv='python -m venv'
alias activate='source venv/bin/activate'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze > requirements.txt'

# Node.js aliases
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nw='npm run watch'
alias nc='npm run clean'

# Yarn aliases
alias y='yarn'
alias ya='yarn add'
alias yad='yarn add --dev'
alias yr='yarn run'
alias ys='yarn start'
alias yt='yarn test'
alias yb='yarn build'
alias yw='yarn watch'

# System monitoring
alias cpu='htop'
alias mem='free -h'
alias disk='df -h'
alias ports='netstat -tuln'
alias processes='ps aux'

# File operations
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Network
alias ping='ping -c 5'
alias wget='wget -c'
alias myip='curl ifconfig.me'
alias localip='hostname -I'

# Development servers
alias serve='python -m http.server 8000'
alias phpserve='php -S localhost:8000'
alias nodeserve='npx http-server'

# Database aliases
alias pgstart='sudo systemctl start postgresql'
alias pgstop='sudo systemctl stop postgresql'
alias pgstatus='sudo systemctl status postgresql'
alias mysqlstart='sudo systemctl start mariadb'
alias mysqlstop='sudo systemctl stop mariadb'
alias mysqlstatus='sudo systemctl status mariadb'
alias mongostart='sudo systemctl start mongodb'
alias mongostop='sudo systemctl stop mongodb'
alias mongostatus='sudo systemctl status mongodb'
alias redisstart='sudo systemctl start redis'
alias redisstop='sudo systemctl stop redis'
alias redisstatus='sudo systemctl status redis'

# Code editors
alias code='code .'
alias vim='nvim'
alias vi='nvim'

# Quick edits
alias bashrc='nvim ~/.bashrc'
alias vimrc='nvim ~/.vimrc'
alias aliases='nvim ~/.bash_aliases'
alias hosts='sudo nvim /etc/hosts'

# Quick navigation
alias home='cd ~'
alias root='cd /'
alias downloads='cd ~/Downloads'
alias documents='cd ~/Documents'
alias desktop='cd ~/Desktop'

# Archive operations
alias tarx='tar -xvf'
alias tarc='tar -cvf'
alias tarz='tar -czvf'
alias untar='tar -xvf'

# System updates
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias remove='sudo pacman -R'
alias autoremove='sudo pacman -Rns $(pacman -Qtdq)'

# Development tools shortcuts
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias ans='ansible'
alias ansp='ansible-playbook'
alias vag='vagrant'
alias vagu='vagrant up'
alias vagd='vagrant destroy'
alias vags='vagrant ssh'

EOF

    log "✓ Aliases de desarrollo configurados"
}


# Mas codigo
# Configurar entorno de desarrollo
setup_development_environment() {
    log "Configurando entorno de desarrollo..."
    
    # Configurar Git si no está configurado
    if ! git config --global user.name &>/dev/null; then
        echo -n "Introduce tu nombre para Git: "
        read -r git_name
        git config --global user.name "$git_name"
    fi
    
    if ! git config --global user.email &>/dev/null; then
        echo -n "Introduce tu email para Git: "
        read -r git_email
        git config --global user.email "$git_email"
    fi
    
    # Configuraciones adicionales de Git
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    git config --global core.editor "code --wait"
    git config --global merge.tool vscode
    git config --global mergetool.vscode.cmd 'code --wait $MERGED'
    git config --global diff.tool vscode
    git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
    
    # Configurar SSH para Git
    if [[ ! -f "${HOME}/.ssh/id_rsa" ]] && [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then
        if ask_question "¿Generar clave SSH para Git?"; then
            ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "${HOME}/.ssh/id_ed25519" -N ""
            eval "$(ssh-agent -s)"
            ssh-add "${HOME}/.ssh/id_ed25519"
            
            echo -e "${CYAN}Clave SSH generada. Añade esta clave a tu cuenta de GitHub/GitLab:${NC}"
            cat "${HOME}/.ssh/id_ed25519.pub"
            
            # Configurar SSH config
            mkdir -p "${HOME}/.ssh"
            cat >> "${HOME}/.ssh/config" << EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
EOF
            chmod 600 "${HOME}/.ssh/config"
        fi
    fi
    
    # Instalar extensiones de VSCode
    if command -v code &>/dev/null; then
        log "Instalando extensiones de VSCode..."
        
        local vscode_extensions=(
            # Lenguajes de programación
            "ms-python.python"
            "ms-python.pylint"
            "ms-python.black-formatter"
            "ms-python.isort"
            "ms-vscode.cpptools"
            "ms-vscode.cpptools-extension-pack"
            "rust-lang.rust-analyzer"
            "golang.go"
            "ms-vscode.vscode-typescript-next"
            "ms-dotnettools.csharp"
            "ms-dotnettools.vscode-dotnet-runtime"
            "oracle.oracle-java"
            "redhat.java"
            "vscjava.vscode-java-pack"
            "ms-vscode.powershell"
            "ms-vscode.cmake-tools"
            "twxs.cmake"
            "ms-vscode.makefile-tools"
            
            # Web Development
            "bradlc.vscode-tailwindcss"
            "esbenp.prettier-vscode"
            "ms-vscode.vscode-eslint"
            "formulahendry.auto-rename-tag"
            "christian-kohler.path-intellisense"
            "ms-vscode.vscode-json"
            "redhat.vscode-yaml"
            "ms-vscode.vscode-css-peek"
            "zignd.html-css-class-completion"
            "pranaygp.vscode-css-peek"
            "bradlc.vscode-tailwindcss"
            "ms-vscode.vscode-html-languageservice"
            
            # Frameworks y librerías
            "ms-vscode.vscode-react-native"
            "ms-vscode.vscode-node-azure-pack"
            "ms-python.flake8"
            "ms-python.mypy-type-checker"
            "ms-toolsai.jupyter"
            "ms-toolsai.jupyter-keymap"
            "ms-toolsai.jupyter-renderers"
            "dart-code.dart-code"
            "dart-code.flutter"
            "pivotal.vscode-spring-boot"
            "vmware.vscode-spring-boot-dashboard"
            "gabrielbb.vscode-lombok"
            
            # DevOps y Cloud
            "ms-kubernetes-tools.vscode-kubernetes-tools"
            "ms-azuretools.vscode-docker"
            "hashicorp.terraform"
            "ms-vscode-remote.remote-ssh"
            "ms-vscode-remote.remote-containers"
            "ms-vscode-remote.remote-wsl"
            "ms-azuretools.vscode-azureresourcegroups"
            "amazonwebservices.aws-toolkit-vscode"
            "googlecloudtools.cloudcode"
            
            # Git y control de versiones
            "github.copilot"
            "github.copilot-chat"
            "github.vscode-pull-request-github"
            "eamodio.gitlens"
            "mhutchie.git-graph"
            "donjayamanne.githistory"
            "codezombiech.gitignore"
            "github.vscode-github-actions"
            
            # Bases de datos
            "ms-mssql.mssql"
            "oracle.oracledevtools"
            "mtxr.sqltools"
            "mtxr.sqltools-driver-mysql"
            "mtxr.sqltools-driver-pg"
            "mtxr.sqltools-driver-sqlite"
            "mongodb.mongodb-vscode"
            
            # Herramientas de desarrollo
            "ms-vscode.hexeditor"
            "ms-vscode.vscode-serial-monitor"
            "platformio.platformio-ide"
            "vadimcn.vscode-lldb"
            "sonarsource.sonarlint-vscode"
            "shengchen.vscode-checkstyle"
            "redhat.vscode-xml"
            "dotjoshjohnson.xml"
            "ms-vscode.test-adapter-converter"
            "hbenl.vscode-test-explorer"
            
            # Productividad
            "ms-vscode.vscode-todo-highlight"
            "gruntfuggly.todo-tree"
            "streetsidesoftware.code-spell-checker"
            "streetsidesoftware.code-spell-checker-spanish"
            "ms-vscode.wordcount"
            "alefragnani.bookmarks"
            "formulahendry.code-runner"
            "ms-vscode.vscode-speech"
            
            # Temas y apariencia
            "pkief.material-icon-theme"
            "ms-vscode.theme-monokai-dimmed"
            "github.github-vscode-theme"
            "dracula-theme.theme-dracula"
            "monokai.theme-monokai-pro-vscode"
            
            # Documentación
            "yzhang.markdown-all-in-one"
            "shd101wyy.markdown-preview-enhanced"
            "davidanson.vscode-markdownlint"
            "ms-vscode.vscode-markdown"
            "bierner.markdown-mermaid"
            
            # API Development
            "humao.rest-client"
            "rangav.vscode-thunder-client"
            "ms-vscode.vscode-httpyac"
        )
        
        # Instalar extensiones con manejo de errores
        local installed_count=0
        local failed_extensions=()
        
        for extension in "${vscode_extensions[@]}"; do
            if code --install-extension "$extension" --force &>/dev/null; then
                ((installed_count++))
            else
                failed_extensions+=("$extension")
                warning "Falló la instalación de la extensión: $extension"
            fi
        done
        
        log "✓ Extensiones de VSCode instaladas: $installed_count/${#vscode_extensions[@]}"
        
        if [[ ${#failed_extensions[@]} -gt 0 ]]; then
            warning "Extensiones que fallaron: ${failed_extensions[*]}"
        fi
    fi
    
    # Configurar Node.js y npm
    if command -v npm &>/dev/null; then
        log "Configurando Node.js y npm..."
        
        # Configurar npm para usar directorio global sin sudo
        mkdir -p "${HOME}/.npm-global"
        npm config set prefix "${HOME}/.npm-global"
        
        # Añadir al PATH si no está
        if ! grep -q "/.npm-global/bin" "${HOME}/.bashrc"; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "${HOME}/.bashrc"
        fi
        
        # Instalar paquetes globales útiles
        local npm_packages=(
            "typescript"
            "ts-node"
            "@types/node"
            "nodemon"
            "pm2"
            "http-server"
            "live-server"
            "json-server"
            "create-react-app"
            "create-next-app"
            "@vue/cli"
            "@angular/cli"
            "express-generator"
            "nest"
            "prisma"
            "typeorm"
            "sequelize-cli"
            "knex"
            "eslint"
            "prettier"
            "stylelint"
            "sass"
            "less"
            "postcss-cli"
            "autoprefixer"
            "webpack"
            "webpack-cli"
            "vite"
            "rollup"
            "parcel"
            "gulp-cli"
            "grunt-cli"
            "yarn"
            "pnpm"
            "npm-check-updates"
            "depcheck"
            "license-checker"
            "semantic-release"
            "commitizen"
            "husky"
            "lint-staged"
        )
        
        for package in "${npm_packages[@]}"; do
            if npm install -g "$package" &>/dev/null; then
                info "✓ Instalado: $package"
            else
                warning "✗ Falló: $package"
            fi
        done
        
        log "✓ Configuración de Node.js completada"
    fi
    
    # Configurar Python
    if command -v python &>/dev/null; then
        log "Configurando Python..."
        
        # Instalar paquetes Python útiles
        local python_packages=(
            "pip"
            "setuptools"
            "wheel"
            "virtualenv"
            "pipenv"
            "poetry"
            "black"
            "flake8"
            "pylint"
            "mypy"
            "pytest"
            "pytest-cov"
            "jupyter"
            "jupyterlab"
            "notebook"
            "ipython"
            "requests"
            "flask"
            "django"
            "fastapi"
            "uvicorn"
            "gunicorn"
            "celery"
            "redis"
            "sqlalchemy"
            "alembic"
            "psycopg2-binary"
            "pymongo"
            "pandas"
            "numpy"
            "matplotlib"
            "seaborn"
            "scikit-learn"
            "tensorflow"
            "torch"
            "opencv-python"
            "pillow"
            "beautifulsoup4"
            "scrapy"
            "selenium"
            "pydantic"
            "typer"
            "rich"
            "click"
            "python-dotenv"
            "pre-commit"
        )
        
        for package in "${python_packages[@]}"; do
            if pip install --user "$package" &>/dev/null; then
                info "✓ Instalado: $package"
            else
                warning "✗ Falló: $package"
            fi
        done
        
        log "✓ Configuración de Python completada"
    fi
    
    # Configurar Docker
    if command -v docker &>/dev/null; then
        log "Configurando Docker..."
        
        # Añadir usuario al grupo docker
        sudo usermod -aG docker "$USER"
        
        # Habilitar y iniciar servicios
        sudo systemctl enable docker
        sudo systemctl start docker
        
        # Configurar Docker Compose
        if command -v docker-compose &>/dev/null; then
            log "✓ Docker Compose disponible"
        fi
        
        log "✓ Configuración de Docker completada"
        warning "Necesitarás reiniciar la sesión para usar Docker sin sudo"
    fi
    
    # Configurar Rust
    if command -v rustc &>/dev/null; then
        log "Configurando Rust..."
        
        # Instalar componentes adicionales
        rustup component add clippy
        rustup component add rustfmt
        rustup component add rust-analyzer
        
        # Instalar herramientas útiles
        local rust_tools=(
            "cargo-edit"
            "cargo-watch"
            "cargo-expand"
            "cargo-outdated"
            "cargo-audit"
            "cargo-tree"
            "cargo-bloat"
            "cargo-deps"
            "cargo-make"
            "cargo-generate"
            "serde"
            "tokio"
            "clap"
            "reqwest"
        )
        
        for tool in "${rust_tools[@]}"; do
            if cargo install "$tool" &>/dev/null; then
                info "✓ Instalado: $tool"
            else
                warning "✗ Falló: $tool"
            fi
        done
        
        log "✓ Configuración de Rust completada"
    fi
    
    # Configurar Go
    if command -v go &>/dev/null; then
        log "Configurando Go..."
        
        # Configurar GOPATH si no está configurado
        if [[ -z "$GOPATH" ]]; then
            echo 'export GOPATH="$HOME/go"' >> "${HOME}/.bashrc"
            echo 'export PATH="$GOPATH/bin:$PATH"' >> "${HOME}/.bashrc"
            export GOPATH="$HOME/go"
            export PATH="$GOPATH/bin:$PATH"
        fi
        
        mkdir -p "$GOPATH/src" "$GOPATH/bin" "$GOPATH/pkg"
        
        # Instalar herramientas útiles
        local go_tools=(
            "golang.org/x/tools/gopls@latest"
            "github.com/go-delve/delve/cmd/dlv@latest"
            "golang.org/x/tools/cmd/goimports@latest"
            "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
            "github.com/cosmtrek/air@latest"
            "github.com/swaggo/swag/cmd/swag@latest"
            "github.com/golang-migrate/migrate/v4/cmd/migrate@latest"
            "github.com/pressly/goose/v3/cmd/goose@latest"
            "github.com/goreleaser/goreleaser@latest"
            "github.com/securecodewarrior/sast-scan@latest"
            "github.com/mgechev/revive@latest"
            "honnef.co/go/tools/cmd/staticcheck@latest"
            "github.com/kisielk/errcheck@latest"
            "golang.org/x/vuln/cmd/govulncheck@latest"
        )
        
        for tool in "${go_tools[@]}"; do
            if go install "$tool" &>/dev/null; then
                info "✓ Instalado: $tool"
            else
                warning "✗ Falló: $tool"
            fi
        done
        
        log "✓ Configuración de Go completada"
    fi
    
    # Configurar Java
    if command -v java &>/dev/null; then
        log "Configurando Java..."
        
        # Configurar JAVA_HOME si no está configurado
        local java_home=$(readlink -f /usr/bin/java | sed "s:bin/java::")
        if [[ -z "$JAVA_HOME" ]]; then
            echo "export JAVA_HOME=\"$java_home\"" >> "${HOME}/.bashrc"
            export JAVA_HOME="$java_home"
        fi
        
        # Configurar Maven si está instalado
        if command -v mvn &>/dev/null; then
            mkdir -p "${HOME}/.m2"
            
            # Crear settings.xml básico si no existe
            if [[ ! -f "${HOME}/.m2/settings.xml" ]]; then
                cat > "${HOME}/.m2/settings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
  
  <localRepository>${user.home}/.m2/repository</localRepository>
  
  <profiles>
    <profile>
      <id>default</id>
      <repositories>
        <repository>
          <id>central</id>
          <url>https://repo1.maven.org/maven2</url>
          <releases>
            <enabled>true</enabled>
          </releases>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>
  
  <activeProfiles>
    <activeProfile>default</activeProfile>
  </activeProfiles>
  
</settings>
EOF
            fi
        fi
        
        log "✓ Configuración de Java completada"
    fi
    
    # Configurar bases de datos de desarrollo
    setup_development_databases
    
    # Configurar herramientas de contenedores
    setup_container_tools
    
    # Configurar herramientas de monitoreo
    setup_monitoring_tools
    
    # Crear estructura de directorios de desarrollo
    create_development_directories
    
    # Configurar aliases útiles
    setup_development_aliases
    
    # Configurar variables de entorno
    setup_environment_variables
    
    log "✓ Configuración del entorno de desarrollo completada"
}

# Configurar bases de datos de desarrollo
setup_development_databases() {
    log "Configurando bases de datos de desarrollo..."
    
    # PostgreSQL
    if command -v psql &>/dev/null; then
        log "Configurando PostgreSQL..."
        
        # Inicializar base de datos si es necesario
        if [[ ! -d /var/lib/postgres/data ]]; then
            sudo -u postgres initdb -D /var/lib/postgres/data
        fi
        
        # Habilitar y iniciar servicio
        sudo systemctl enable postgresql
        sudo systemctl start postgresql
        
        # Crear usuario de desarrollo
        if ask_question "¿Crear usuario de desarrollo para PostgreSQL?"; then
            echo -n "Nombre de usuario: "
            read -r pg_user
            sudo -u postgres createuser --interactive "$pg_user"
            sudo -u postgres createdb "$pg_user"
        fi
    fi
    
    # MySQL/MariaDB
    if command -v mysql &>/dev/null; then
        log "Configurando MySQL/MariaDB..."
        
        sudo systemctl enable mariadb
        sudo systemctl start mariadb
        
        if ask_question "¿Ejecutar mysql_secure_installation?"; then
            sudo mysql_secure_installation
        fi
    fi
    
    # MongoDB
    if command -v mongod &>/dev/null; then
        log "Configurando MongoDB..."
        
        sudo systemctl enable mongodb
        sudo systemctl start mongodb
    fi
    
    # Redis
    if command -v redis-server &>/dev/null; then
        log "Configurando Redis..."
        
        sudo systemctl enable redis
        sudo systemctl start redis
    fi
    
    log "✓ Configuración de bases de datos completada"
}

# Configurar herramientas de contenedores
setup_container_tools() {
    log "Configurando herramientas de contenedores..."
    
    # Kubernetes
    if command -v kubectl &>/dev/null; then
        # Configurar autocompletado
        echo 'source <(kubectl completion bash)' >> "${HOME}/.bashrc"
        echo 'alias k=kubectl' >> "${HOME}/.bashrc"
        echo 'complete -F __start_kubectl k' >> "${HOME}/.bashrc"
        
        # Crear directorio de configuración
        mkdir -p "${HOME}/.kube"
    fi
    
    # Helm
    if command -v helm &>/dev/null; then
        echo 'source <(helm completion bash)' >> "${HOME}/.bashrc"
        
        # Añadir repositorios útiles
        helm repo add stable https://charts.helm.sh/stable
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo update
    fi
    
    # Terraform
    if command -v terraform &>/dev/null; then
        echo 'complete -C /usr/bin/terraform terraform' >> "${HOME}/.bashrc"
        
        # Crear directorio de configuración
        mkdir -p "${HOME}/.terraform.d"
    fi
    
    log "✓ Configuración de herramientas de contenedores completada"
}

# Configurar herramientas de monitoreo
setup_monitoring_tools() {
    log "Configurando herramientas de monitoreo..."
    
    # Configurar htop
    if command -v htop &>/dev/null; then
        mkdir -p "${HOME}/.config/htop"
        cat > "${HOME}/.config/htop/htoprc" << 'EOF'
fields=0 48 17 18 38 39 40 2 46 47 49 1
sort_key=46
sort_direction=1
hide_threads=0
hide_kernel_threads=1
hide_userland_threads=0
shadow_other_users=0
show_thread_names=0
show_program_path=1
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
tree_view=0
header_margin=1
detailed_cpu_time=0
cpu_count_from_zero=0
update_process_names=0
account_guest_in_cpu_meter=0
color_scheme=0
delay=15
left_meters=LeftCPUs Memory Swap
left_meter_modes=1 1 1
right_meters=RightCPUs Tasks LoadAverage Uptime
right_meter_modes=1 2 2 2
EOF
    fi
    
    log "✓ Configuración de herramientas de monitoreo completada"
}

# Crear estructura de directorios de desarrollo
create_development_directories() {
    log "Creando estructura de directorios de desarrollo..."
    
    local dev_dirs=(
        "${HOME}/Development"
        "${HOME}/Development/projects"
        "${HOME}/Development/playground"
        "${HOME}/Development/learning"
        "${HOME}/Development/tools"
        "${HOME}/Development/scripts"
        "${HOME}/Development/templates"
        "${HOME}/Development/docker"
        "${HOME}/Development/kubernetes"
        "${HOME}/Development/terraform"
        "${HOME}/Development/ansible"
        "${HOME}/Development/databases"
        "${HOME}/Development/apis"
        "${HOME}/Development/mobile"
        "${HOME}/Development/web"
        "${HOME}/Development/desktop"
        "${HOME}/Development/cli"
        "${HOME}/Development/libraries"
        "${HOME}/Development/frameworks"
        "${HOME}/Development/microservices"
        "${HOME}/Development/serverless"
        "${HOME}/Development/blockchain"
        "${HOME}/Development/ai-ml"
        "${HOME}/Development/iot"
        "${HOME}/Development/game-dev"
        "${HOME}/Development/devops"
        "${HOME}/Development/security"
        "${HOME}/Development/testing"
        "${HOME}/Development/documentation"
        "${HOME}/Development/resources"
        "${HOME}/Development/backups"
    )
    
    for dir in "${dev_dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    # Crear archivos README en directorios principales
    cat > "${HOME}/Development/README.md" << 'EOF'
# Development Directory Structure

## Directories

- **projects/**: Main development projects
- **playground/**: Experimental code and quick tests
- **learning/**: Learning materials and tutorials
- **tools/**: Development tools and utilities
- **scripts/**: Automation and helper scripts
- **templates/**: Project templates and boilerplates
- **docker/**: Docker configurations and Dockerfiles
- **kubernetes/**: Kubernetes manifests and configurations
- **terraform/**: Infrastructure as Code
- **ansible/**: Configuration management
- **databases/**: Database schemas and migrations
- **apis/**: API development and documentation
- **mobile/**: Mobile application development
- **web/**: Web development projects
- **desktop/**: Desktop application development
- **cli/**: Command-line tools and applications
- **libraries/**: Reusable libraries and components
- **frameworks/**: Custom frameworks and extensions
- **microservices/**: Microservices architecture projects
- **serverless/**: Serverless functions and applications
- **blockchain/**: Blockchain and cryptocurrency projects
- **ai-ml/**: Artificial Intelligence and Machine Learning
- **iot/**: Internet of Things projects
- **game-dev/**: Game development projects
- **devops/**: DevOps tools and configurations
- **security/**: Security tools and penetration testing
- **testing/**: Testing frameworks and test suites
- **documentation/**: Project documentation and wikis
- **resources/**: Development resources and references
- **backups/**: Project backups and archives

## Usage

Each directory contains projects organized by technology, purpose, or client.
Use consistent naming conventions and maintain proper documentation.
EOF
    
    log "✓ Estructura de directorios de desarrollo creada"
}

# Configurar aliases útiles para desarrollo
setup_development_aliases() {
    log "Configurando aliases de desarrollo..."
    
    # Crear archivo de aliases si no existe
    if [[ ! -f "${HOME}/.bash_aliases" ]]; then
        touch "${HOME}/.bash_aliases"
        echo 'source ~/.bash_aliases' >> "${HOME}/.bashrc"
    fi
    
    # Añadir aliases de desarrollo
    cat >> "${HOME}/.bash_aliases" << 'EOF'

# Development Aliases
alias dev='cd ~/Development'
alias projects='cd ~/Development/projects'
alias playground='cd ~/Development/playground'
alias scripts='cd ~/Development/scripts'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git rebase'
alias glog='git log --oneline --graph --decorate'
alias gstash='git stash'
alias gpop='git stash pop'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias drmi='docker rmi'
alias drm='docker rm'
alias dexec='docker exec -it'
alias dlogs='docker logs'
alias dstop='docker stop $(docker ps -q)'
alias dclean='docker system prune -f'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
alias kapply='kubectl apply -f'
alias kdelete='kubectl delete -f'

# Python aliases
alias py='python'
alias py3='python3'
alias pip='pip3'
alias venv='python -m venv'
alias activate='source venv/bin/activate'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze > requirements.txt'

# Node.js aliases
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nw='npm run watch'
alias nc='npm run clean'

# Yarn aliases
alias y='yarn'
alias ya='yarn add'
alias yad='yarn add --dev'
alias yr='yarn run'
alias ys='yarn start'
alias yt='yarn test'
alias yb='yarn build'
alias yw='yarn watch'

# System monitoring
alias cpu='htop'
alias mem='free -h'
alias disk='df -h'
alias ports='netstat -tuln'
alias processes='ps aux'

# File operations
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Network
alias ping='ping -c 5'
alias wget='wget -c'
alias myip='curl ifconfig.me'
alias localip='hostname -I'

# Development servers
alias serve='python -m http.server 8000'
alias phpserve='php -S localhost:8000'
alias nodeserve='npx http-server'

# Database aliases
alias pgstart='sudo systemctl start postgresql'
alias pgstop='sudo systemctl stop postgresql'
alias pgstatus='sudo systemctl status postgresql'
alias mysqlstart='sudo systemctl start mariadb'
alias mysqlstop='sudo systemctl stop mariadb'
alias mysqlstatus='sudo systemctl status mariadb'
alias mongostart='sudo systemctl start mongodb'
alias mongostop='sudo systemctl stop mongodb'
alias mongostatus='sudo systemctl status mongodb'
alias redisstart='sudo systemctl start redis'
alias redisstop='sudo systemctl stop redis'
alias redisstatus='sudo systemctl status redis'

# Code editors
alias code='code .'
alias vim='nvim'
alias vi='nvim'

# Quick edits
alias bashrc='nvim ~/.bashrc'
alias vimrc='nvim ~/.vimrc'
alias aliases='nvim ~/.bash_aliases'
alias hosts='sudo nvim /etc/hosts'

# Quick navigation
alias home='cd ~'
alias root='cd /'
alias downloads='cd ~/Downloads'
alias documents='cd ~/Documents'
alias desktop='cd ~/Desktop'

# Archive operations
alias tarx='tar -xvf'
alias tarc='tar -cvf'
alias tarz='tar -czvf'
alias untar='tar -xvf'

# System updates
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias remove='sudo pacman -R'
alias autoremove='sudo pacman -Rns $(pacman -Qtdq)'

# Development tools shortcuts
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias ans='ansible'
alias ansp='ansible-playbook'
alias vag='vagrant'
alias vagu='vagrant up'
alias vagd='vagrant destroy'
alias vags='vagrant ssh'

EOF

    log "✓ Aliases de desarrollo configurados"
}

# Configurar variables de entorno
setup_environment_variables() {
    log "Configurando variables de entorno..."
    
    # Crear archivo de variables de entorno
    cat >> "${HOME}/.bashrc" << 'EOF'

# Development Environment Variables
export EDITOR='code --wait'
export VISUAL='code --wait'
export BROWSER='firefox'
export TERM='xterm-256color'

# Development paths
export DEV_HOME="$HOME/Development"
export PROJECTS_HOME="$DEV_HOME/projects"
export SCRIPTS_HOME="$DEV_HOME/scripts"
export TOOLS_HOME="$DEV_HOME/tools"

# Language specific
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
export PIP_REQUIRE_VIRTUALENV=true
export NODE_ENV=development
export NPM_CONFIG_PREFIX="$HOME/.npm-global"

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Kubernetes
export KUBECONFIG="$HOME/.kube/config"
export KUBE_EDITOR="code --wait"

# History
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# Colors
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export GREP_OPTIONS='--color=auto'

# Less
export LESS='-R'
export LESSOPEN='|~/.lessfilter %s'

# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

EOF

    # Crear configuración de ripgrep
    cat > "${HOME}/.ripgreprc" << 'EOF'
--max-columns=150
--max-columns-preview
--smart-case
--hidden
--glob=!.git/*
--glob=!node_modules/*
--glob=!vendor/*
--glob=!dist/*
--glob=!build/*
--glob=!target/*
--glob=!*.min.js
--glob=!*.min.css
--colors=line:none
--colors=line:style:bold
EOF

    log "✓ Variables de entorno configuradas"
}

# Configurar herramientas de línea de comandos mejoradas
setup_enhanced_cli_tools() {
    log "Configurando herramientas CLI mejoradas..."
    
    # Configurar Zoxide (mejor cd)
    if command -v zoxide &>/dev/null; then
        echo 'eval "$(zoxide init bash)"' >> "${HOME}/.bashrc"
    fi
    
    # Configurar FZF
    if command -v fzf &>/dev/null; then
        echo 'source /usr/share/fzf/key-bindings.bash' >> "${HOME}/.bashrc"
        echo 'source /usr/share/fzf/completion.bash' >> "${HOME}/.bashrc"
    fi
    
    # Configurar Starship prompt (si está instalado)
    if command -v starship &>/dev/null; then
        echo 'eval "$(starship init bash)"' >> "${HOME}/.bashrc"
        
        # Crear configuración básica de Starship
        mkdir -p "${HOME}/.config"
        cat > "${HOME}/.config/starship.toml" << 'EOF'
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$cmd_duration\
$line_break\
$python\
$character"""

[directory]
style = "blue"

[character]
success_symbol = "[❯](purple)"
error_symbol = "[❯](red)"
vicmd_symbol = "[❮](green)"

[git_branch]
format = "[$branch]($style)"
style = "bright-black"

[git_status]
format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)"
style = "cyan"

[git_state]
format = '\([$state( $progress_current/$progress_total)]($style)\) '
style = "bright-black"

[cmd_duration]
format = "[$duration]($style) "
style = "yellow"

[python]
format = "[$virtualenv]($style) "
style = "bright-black"
EOF
    fi
    
    log "✓ Herramientas CLI mejoradas configuradas"
}

# Aplicaciones multimedia y entretenimiento
install_multimedia_apps() {
    log "Instalando aplicaciones multimedia y entretenimiento..."
    
    local aur_helper=$(detect_aur_helper)
    
    # Repositorio oficial
    sudo pacman -S --needed --noconfirm \
        vlc \
        mpv \
        obs-studio \
        audacity \
        kdenlive \
        openshot \
        blender \
        krita \
        inkscape \
        gimp \
        darktable \
        rawtherapee \
        shotcut \
        handbrake \
        makemkv \
        dvdbackup \
        brasero \
        k3b \
        rhythmbox \
        clementine \
        amarok \
        strawberry \
        lollypop \
        parole \
        totem \
        dragon \
        haruna \
        celluloid \
        smplayer \
        qmmp \
        audacious \
        deadbeef \
        easytag \
        kid3 \
        puddletag \
        soundconverter \
        winff \
        transmageddon \
        pitivi \
        flowblade \
        lives \
        cinelerra-gg \
        natron \
        synfigstudio \
        pencil2d \
        opentoonz \
        tahoma2d
    
    # AUR
    if [[ -n "$aur_helper" ]]; then
        $aur_helper -S --needed --noconfirm \
            spotify \
            youtube-dl-gui \
            freetube-bin \
            stremio \
            popcorntime-bin \
            plex-media-player \
            jellyfin-media-player \
            kodi-bin \
            emby-theater \
            netflix-1080p \
            prime-video-desktop \
            disney-plus-desktop \
            hbo-max-desktop \
            twitch-desktop \
            streamlink-twitch-gui-bin \
            obs-studio-browser \
            obs-backgroundremoval \
            reaper \
            bitwig-studio \
            renoise \
            mixxx \
            virtual-dj \
            serato-dj \
            traktor \
            rekordbox \
            djay-pro \
            cross-dj \
            mixx \
            lmms \
            ardour \
            rosegarden \
            musescore \
            tuxguitar \
            hydrogen \
            qtractor \
            seq24 \
            non-sequencer \
            carla \
            cadence \
            qjackctl \
            pavucontrol-qt \
            pulseeffects \
            easyeffects \
            calf \
            lsp-plugins \
            x42-plugins \
            zam-plugins
    fi
    
    log "✓ Aplicaciones multimedia instaladas"
}

# Aplicaciones de productividad y oficina
install_productivity_apps() {
    log "Instalando aplicaciones de productividad y oficina..."
    
    local aur_helper=$(detect_aur_helper)
    
    # Repositorio oficial
    sudo pacman -S --needed --noconfirm \
        libreoffice-fresh \
        libreoffice-fresh-es \
        calligra \
        abiword \
        gnumeric \
        scribus \
        texlive-most \
        texmaker \
        texstudio \
        lyx \
        pandoc \
        ghostscript \
        poppler-utils \
        pdftk \
        qpdf \
        mupdf \
        zathura \
        zathura-pdf-mupdf \
        evince \
        okular \
        atril \
        xreader \
        calibre \
        fbreader \
        foliate \
        bookworm \
        sigil \
        focuswriter \
        ghostwriter \
        remarkable \
        xournalpp \
        rnote \
        kolourpaint \
        pinta \
        drawing \
        simple-scan \
        skanlite \
        gscan2pdf \
        tesseract \
        tesseract-data-spa \
        gocr \
        ocrmypdf \
        pdfarranger \
        pdfmod \
        masterpdfeditor-free
    
    # AUR
    if [[ -n "$aur_helper" ]]; then
        $aur_helper -S --needed --noconfirm \
            onlyoffice-bin \
            wps-office \
            freeoffice \
            softmaker-office \
            masterpdfeditor \
            pdf-studio \
            foxit-reader \
            adobe-acrobat-reader \
            mendeley-reference-manager \
            zotero \
            jabref \
            notion-app \
            obsidian \
            logseq \
            joplin-appimage \
            standard-notes-bin \
            simplenote-electron-bin \
            boostnote \
            vnote \
            cherrytree \
            zim \
            tiddlydesktop \
            typora \
            mark-text \
            zettlr \
            manuskript \
            bibisco \
            artisan \
            scrivener \
            ywriter \
            planner \
            ganttproject \
            projectlibre \
            openproject \
            taskwarrior-tui \
            timewarrior \
            toggl-track \
            rescuetime \
            activitywatch-bin \
            rocketbook \
            xmind \
            freemind \
            freeplane \
            vym \
            drawio-desktop \
            lucidchart \
            miro \
            conceptboard \
            mural \
            figma-linux
    fi
    
    log "✓ Aplicaciones de productividad instaladas"
}

# Aplicaciones de juegos y gaming
install_gaming_apps() {
    log "Instalando aplicaciones de juegos y gaming..."
    
    local aur_helper=$(detect_aur_helper)
    
    # Repositorio oficial
    sudo pacman -S --needed --noconfirm \
        steam \
        lutris \
        wine \
        wine-gecko \
        wine-mono \
        winetricks \
        playonlinux \
        bottles \
        gamemode \
        lib32-gamemode \
        mangohud \
        lib32-mangohud \
        goverlay \
        gamescope \
        retroarch \
        retroarch-assets-xmb \
        retroarch-assets-ozone \
        libretro-core-info \
        libretro-beetle-pce-fast \
        libretro-beetle-psx \
        libretro-beetle-psx-hw \
        libretro-blastem \
        libretro-bsnes \
        libretro-desmume \
        libretro-dolphin \
        libretro-flycast \
        libretro-gambatte \
        libretro-genesis-plus-gx \
        libretro-mame \
        libretro-melonds \
        libretro-mgba \
        libretro-mupen64plus-next \
        libretro-nestopia \
        libretro-parallel-n64 \
        libretro-pcsx2 \
        libretro-picodrive \
        libretro-ppsspp \
        libretro-sameboy \
        libretro-scummvm \
        libretro-snes9x \
        libretro-stella \
        mame \
        dosbox \
        scummvm \
         \
        supertux \
        supertuxkart \
        0ad \
        wesnoth \
        freeciv \
        openttd \
        simutrans \
        flightgear \
        torcs \
        extreme-tuxracer
    
    # AUR
    if [[ -n "$aur_helper" ]]; then
        $aur_helper -S --needed --noconfirm \
            heroic-games-launcher-bin \
            legendary \
            rare \
            minigalaxy \
            itch \
            gog-galaxy-wine \
            origin-wine \
            uplay-wine \
            battle-net-wine \
            minecraft-launcher \
            multimc-bin \
            polymc-bin \
            prismlauncher-bin \
            atlauncher \
            technic-launcher \
            ftb-app \
            curseforge \
            modrinth-app \
            steam-native-runtime \
            proton-ge-custom-bin \
            dxvk-bin \
            vkd3d-proton-bin \
            lib32-vkd3d \
            discord-rich-presence \
            gamehub \
            cartridges \
            pegasus-frontend \
            emulationstation-de \
            attract-mode \
            launchbox-wine \
            bigpicture-wine \
            antimicrox \
            qjoypad \
            jstest-gtk \
            joystickwake \
            oversteer \
            piper \
            solaar \
            openrgb-bin \
            ckb-next \
            rivalcfg \
            roccat-tools \
            steelseries-engine-wine \
            logitech-gaming-software-wine \
            corsair-icue-wine \
            razer-synapse-wine
    fi
    
    # Configurar gamemode
    sudo usermod -aG gamemode "$USER"
    
    log "✓ Aplicaciones de gaming instaladas"
}

# Herramientas de sistema
install_system_tools() {
    log "Instalando herramientas de sistema..."
    
    local aur_helper=$(detect_aur_helper)
    
    # Repositorio oficial
    sudo pacman -S --needed --noconfirm \
        htop \
        btop \
        gtop \
        bashtop \
        iotop \
        iftop \
        nethogs \
        bandwhich \
        nload \
        vnstat \
        speedtest-cli \
        fast-cli \
        neofetch \
        screenfetch \
        inxi \
        hwinfo \
        lshw \
        dmidecode \
        lscpu \
        lsusb \
        lspci \
        usbutils \
        pciutils \
        smartmontools \
        hdparm \
        sdparm \
        nvme-cli \
        fwupd \
        thermald \
        tlp \
        powertop \
        acpi \
        lm_sensors \
        hddtemp \
        fancontrol \
        stress \
        stress-ng \
        memtest86+ \
        gparted \
        parted \
        fdisk \
        gdisk \
        testdisk \
        ddrescue \
        safecopy \
        rsync \
        rclone \
        duplicity \
        borgbackup \
        restic \
        timeshift \
        snapper \
        btrfs-progs \
        compsize \
        duperemove \
        bleachbit \
        stacer \
        sweeper \
        rmlint \
        ncdu \
        dust \
        duf \
        tree \
        fd \
        ripgrep \
        bat \
        exa \
        lsd \
        zoxide \
        fzf \
        ranger \
        nnn \
        mc \
        vifm \
        thunar \
        pcmanfm \
        dolphin \
        nautilus \
        nemo \
        caja
    
    # AUR
    if [[ -n "$aur_helper" ]]; then
        $aur_helper -S --needed --noconfirm \
            timeshift-autosnap \
            auto-cpufreq \
            cpupower-gui \
            corectrl \
            gwe \
            radeon-profile-git \
            amdgpu-fan \
            nvidia-system-monitor-qt \
            gpu-viewer \
            mission-center \
            resources \
            usage \
            stacer \
            bleachbit \
            czkawka-gui-bin \
            dupeguru \
            fslint \
            rmlint-shredder \
            balena-etcher \
            ventoy-bin \
            woeusb-ng \
            multibootusb \
            unetbootin \
            rufus-wine \
            gparted \
            kde-partition-manager \
            gnome-disk-utility \
            baobab \
            filelight \
            qdirstat \
            gdmap \
            k4dirstat \
            duc \
            ncdu \
            gt5 \
            nnn-nerd \
            lf \
            broot \
            xplr \
            felix-rs \
            joshuto \
            hunter \
            clifm \
            nnn-git \
            fff \
            superfile-bin \
            yazi \
            walk \
            diskonaut \
            erdtree \
            tre-command \
            broot \
            xh \
            httpie \
            curlie \
            dog \
            bandwhich \
            procs \
            tokei \
            hyperfine \
            tealdeer \
            bottom \
            zenith \
            ytop \
            gotop-bin
    fi
    
    log "✓ Herramientas de sistema instaladas"
}

# Navegadores web
install_web_browsers() {
    log "Instalando navegadores web..."
    
    local aur_helper=$(detect_aur_helper)
    
    # Repositorio oficial
    sudo pacman -S --needed --noconfirm \
        firefox \
        brave \
        chromium \
        opera \
        vivaldi \
        falkon \
        qutebrowser \
        midori \
        epiphany \
        konqueror \
        seamonkey \
        palemoon-bin \
        waterfox-g-bin \
        librewolf-bin \
        tor-browser \
        torbrowser-launcher
    
    # AUR
    if [[ -n "$aur_helper" ]]; then
        $aur_helper -S --needed --noconfirm \
            google-chrome \
            microsoft-edge-stable-bin \
            brave-bin \
            ungoogled-chromium-bin \
            thorium-browser-bin \
            vivaldi-ffmpeg-codecs \
            opera-ffmpeg-codecs \
            chromium-widevine \
            firefox-esr-bin \
            firefox-developer-edition \
            firefox-nightly \
            waterfox-current-bin \
            waterfox-classic-bin \
            librewolf-bin \
            icecat-bin \
            basilisk-bin \
            pale-moon-bin \
            seamonkey-bin \
            k-meleon-wine \
            maxthon-wine \
            yandex-browser \
            min \
            beaker-browser \
            nyxt \
            luakit \
            surf \
            uzbl-browser \
            vimb \
            lariza \
            badwolf \
            ephemeral \
            eolie \
            gnome-web-git \
            angelfish \
            plasma-browser-integration \
            chrome-gnome-shell \
            firefox-gnome-theme-git \
            firefox-kde-opensuse \
            firefox-extension-arch-search \
            firefox-ublock-origin \
            firefox-extension-https-everywhere
    fi
    
    log "✓ Navegadores web instalados"
}

# Aplicaciones de comunicación
install_communication_apps() {
    log "Instalando aplicaciones de comunicación..."
    
    local aur_helper=$(detect_aur_helper)
    
    # Repositorio oficial
    sudo pacman -S --needed --noconfirm \
        thunderbird \
        thunderbird-i18n-es-es \
        evolution \
        kmail \
        claws-mail \
        sylpheed \
        mutt \
        neomutt \
        alpine \
        aerc \
        hexchat \
        irssi \
        weechat \
        konversation \
        quassel-core \
        quassel-client \
        pidgin \
        kopete \
        empathy \
        telepathy-gabble \
        telepathy-salut \
        telepathy-idle \
        jami-daemon \
        jami-gnome \
        linphone \
        ekiga \
        mumble \
        teamspeak3 \
        element-desktop \
        nheko \
        quaternion \
        spectral \
        fractal \
        dino \
        gajim \
        psi \
        swift-im \
        profanity \
        mcabber \
        poezio \
        vacuum-im
    
    # AUR
    if [[ -n "$aur_helper" ]]; then
        $aur_helper -S --needed --noconfirm \
            discord \
            discord-canary \
            discord-ptb \
            betterdiscordctl \
            webcord \
            gtkcord4 \
            telegram-desktop \
            telegram-desktop-bin \
            64gram-desktop \
            kotatogram-desktop \
            unigram \
            whatsapp-for-linux \
            whatsapp-nativefier \
            whatsdesk \
            signal-desktop \
            signal-desktop-beta \
            session-desktop-bin \
            element-desktop-nightly \
            cinny-desktop \
            fluffychat \
            schildichat-desktop \
            slack-desktop \
            slack-electron \
            mattermost-desktop \
            rocketchat-desktop \
            zulip-desktop \
            ferdium-bin \
            ferdi-bin \
            rambox-bin \
            franz-bin \
            station \
            wavebox \
            shift \
            mailspring \
            thunderbird-beta-bin \
            betterbird-bin \
            geary-git \
            trojita \
            kube \
            nylas-mail-bin \
            mailnag \
            birdtray \
            zoom \
            teams \
            skype \
            jitsi-meet-desktop \
            jami-qt \
            wire-desktop \
            viber \
            wickr-me \
            keybase-gui \
            briar-desktop \
            ricochet-refresh \
            tox-qt-gui \
            qtox \
            toxic \
            utox \
            teamspeak3-server \
            mumble-server \
            prosody \
            ejabberd \
            openfire \
            coturn \
            janus-gateway \
            jitsi-videobridge \
            jitsi-jicofo \
            matrix-synapse \
            dendrite \
            conduit-bin \
            mautrix-telegram \
            mautrix-whatsapp \
            mautrix-signal \
            mx-puppet-discord \
            heisenbridge
    fi
    
    log "✓ Aplicaciones de comunicación instaladas"
}

# Instalación personalizada
install_custom_apps() {
    log "Iniciando instalación personalizada..."
    
    local aur_helper=$(detect_aur_helper)
    
    echo -e "${CYAN}Selecciona las categorías que deseas instalar:${NC}"
    echo ""
    
    local categories=()
    
    if ask_question "¿Instalar aplicaciones esenciales?"; then
        categories+=("essential")
    fi
    
    if ask_question "¿Instalar herramientas de desarrollo?"; then
        categories+=("development")
    fi
    
    if ask_question "¿Instalar aplicaciones multimedia?"; then
        categories+=("multimedia")
    fi
    
    if ask_question "¿Instalar aplicaciones de productividad?"; then
        categories+=("productivity")
    fi
    
    if ask_question "¿Instalar juegos y gaming?"; then
        categories+=("gaming")
    fi
    
    if ask_question "¿Instalar herramientas de sistema?"; then
        categories+=("system")
    fi
    
    if ask_question "¿Instalar navegadores web?"; then
        categories+=("browsers")
    fi
    
    if ask_question "¿Instalar aplicaciones de comunicación?"; then
        categories+=("communication")
    fi
    
    if [[ ${#categories[@]} -eq 0 ]]; then
        warning "No se seleccionaron categorías para instalar"
        return
    fi
    
    # Mostrar resumen de selección
    echo -e "${YELLOW}Categorías seleccionadas para instalación:${NC}"
    for category in "${categories[@]}"; do
        case "$category" in
            "essential") echo "  ✓ Aplicaciones esenciales" ;;
            "development") echo "  ✓ Desarrollo y programación" ;;
            "multimedia") echo "  ✓ Multimedia y entretenimiento" ;;
            "productivity") echo "  ✓ Productividad y oficina" ;;
            "gaming") echo "  ✓ Juegos y gaming" ;;
            "system") echo "  ✓ Herramientas de sistema" ;;
            "browsers") echo "  ✓ Navegadores web" ;;
            "communication") echo "  ✓ Comunicación" ;;
        esac
    done
    
    echo ""
    if ! ask_question "¿Continuar con la instalación?"; then
        info "Instalación cancelada por el usuario"
        return
    fi
    
    # Instalar categorías seleccionadas
    local total=${#categories[@]}
    local current=0
    
    for category in "${categories[@]}"; do
        ((current++))
        show_progress "$current" "$total" "Instalando $category"
        
        case "$category" in
            "essential") install_essential_apps ;;
            "development") install_development_apps ;;
            "multimedia") install_multimedia_apps ;;
            "productivity") install_productivity_apps ;;
            "gaming") install_gaming_apps ;;
            "system") install_system_tools ;;
            "browsers") install_web_browsers ;;
            "communication") install_communication_apps ;;
        esac
    done
    
    log "✓ Instalación personalizada completada"
}

# Instalar todo
install_all_apps() {
    log "Iniciando instalación completa de todas las aplicaciones..."
    
    echo -e "${YELLOW}⚠️  ADVERTENCIA: Esta opción instalará TODAS las aplicaciones disponibles.${NC}"
    echo -e "${YELLOW}   Esto puede tomar mucho tiempo y espacio en disco.${NC}"
    echo ""
    
    # Estimar tiempo y espacio
    local estimated_time=$(estimate_installation_time "all")
    local estimated_size="15-25 GB"
    
    echo -e "${CYAN}Estimaciones:${NC}"
    echo "  • Tiempo aproximado: $((estimated_time / 60)) minutos"
    echo "  • Espacio en disco: ~$estimated_size"
    echo "  • Paquetes a instalar: ~500-800"
    echo ""
    
    if ! ask_question "¿Estás seguro de que quieres continuar?"; then
        info "Instalación completa cancelada por el usuario"
        return
    fi
    
    # Verificar espacio en disco
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=$((25 * 1024 * 1024)) # 25GB en KB
    
    if [[ $available_space -lt $required_space ]]; then
        error "Espacio insuficiente en disco. Se requieren al menos 25GB libres."
    fi
    
    local categories=("essential" "development" "multimedia" "productivity" "gaming" "system" "browsers" "communication")
    local total=${#categories[@]}
    local current=0
    
    log "Iniciando instalación de todas las categorías..."
    
    for category in "${categories[@]}"; do
        ((current++))
        show_progress "$current" "$total" "Instalando categoría: $category"
        
        case "$category" in
            "essential") install_essential_apps ;;
            "development") install_development_apps ;;
            "multimedia") install_multimedia_apps ;;
            "productivity") install_productivity_apps ;;
            "gaming") install_gaming_apps ;;
            "system") install_system_tools ;;
            "browsers") install_web_browsers ;;
            "communication") install_communication_apps ;;
        esac
        
        # Pequeña pausa entre categorías
        sleep 2
    done
    
    log "✓ Instalación completa de todas las aplicaciones finalizada"
}

# Función principal del menú
main_menu() {
    while true; do
        clear
        show_apps_menu
        
        echo -e "${CYAN}Selecciona una opción [1-10]: ${NC}"
        read -r choice
        
        case "$choice" in
            1)
                install_essential_apps
                ;;
            2)
                install_development_apps
                ;;
            3)
                install_multimedia_apps
                ;;
            4)
                install_productivity_apps
                ;;
            5)
                install_gaming_apps
                ;;
            6)
                install_system_tools
                ;;
            7)
                install_web_browsers
                ;;
            8)
                install_communication_apps
                ;;
            9)
                install_custom_apps
                ;;
            10)
                install_all_apps
                ;;
            q|Q|quit|exit)
                log "Saliendo del instalador de aplicaciones..."
                break
                ;;
            *)
                error "Opción inválida. Por favor selecciona un número del 1 al 10."
                sleep 2
                ;;
        esac
        
        echo ""
        echo -e "${GREEN}Instalación completada. Presiona Enter para continuar...${NC}"
        read -r
    done
}

# Función de ayuda para mostrar progreso
show_progress() {
    local current="$1"
    local total="$2"
    local task="$3"
    local percentage=$((current * 100 / total))
    
    printf "\r${BLUE}[%3d%%] (%d/%d) %s${NC}" "$percentage" "$current" "$total" "$task"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# Función para estimar tiempo de instalación
estimate_installation_time() {
    local category="$1"
    local base_time=300  # 5 minutos base
    
    case "$category" in
        "essential") echo $((base_time + 600)) ;;      # +10 min
        "development") echo $((base_time + 1200)) ;;   # +20 min
        "multimedia") echo $((base_time + 900)) ;;     # +15 min
        "productivity") echo $((base_time + 600)) ;;   # +10 min
        "gaming") echo $((base_time + 1800)) ;;        # +30 min
        "system") echo $((base_time + 300)) ;;         # +5 min
        "browsers") echo $((base_time + 600)) ;;       # +10 min
        "communication") echo $((base_time + 900)) ;;  # +15 min
        "all") echo $((base_time + 5400)) ;;           # +90 min total
        *) echo $base_time ;;
    esac
}

# Verificar dependencias antes de iniciar
check_dependencies() {
    log "Verificando dependencias del sistema..."
    
    # Verificar que pacman esté disponible
    if ! command -v pacman &>/dev/null; then
        error "Este script requiere pacman (Arch Linux)"
    fi
    
    # Verificar conexión a internet
    if ! ping -c 1 archlinux.org &>/dev/null; then
        error "No hay conexión a internet. Verifica tu conexión de red."
    fi
    
    # Actualizar base de datos de paquetes
    log "Actualizando base de datos de paquetes..."
    sudo pacman -Sy
    
    # Instalar helper de AUR si es necesario
    install_aur_helper
    
    log "✓ Verificación de dependencias completada"
}

# Función principal
main() {
    # Crear directorio de logs si no existe
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log "=== INICIANDO INSTALADOR DE APLICACIONES ==="
    log "Fecha: $(date)"
    log "Usuario: $USER"
    log "Sistema: $(uname -a)"
    
    # Verificar dependencias
    check_dependencies
    
    # Mostrar menú principal
    main_menu
    
    # Limpieza final
    cleanup_installation
    
    log "=== INSTALADOR DE APLICACIONES FINALIZADO ==="
}

# Ejecutar función principal si el script se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi


