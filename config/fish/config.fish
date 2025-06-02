# ================================
# CONFIGURACIÓN DE FISH SHELL
# ================================

# Suprimir mensaje de bienvenida
set fish_greeting

# Variables de entorno
set -gx EDITOR nvim
set -gx VISUAL code
set -gx BROWSER firefox
set -gx TERMINAL kitty

# Paths
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.npm-global/bin
fish_add_path ~/go/bin

# Configuración de colores
set -g fish_color_normal cdd6f4
set -g fish_color_command 89b4fa
set -g fish_color_keyword f38ba8
set -g fish_color_quote a6e3a1
set -g fish_color_redirection f9e2af
set -g fish_color_end fab387
set -g fish_color_error f38ba8
set -g fish_color_param f2cdcd
set -g fish_color_comment 6c7086
set -g fish_color_selection --background=313244
set -g fish_color_search_match --background=313244
set -g fish_color_operator f5c2e7
set -g fish_color_escape cba6f7
set -g fish_color_autosuggestion 6c7086

# Configuración de completado
set -g fish_color_valid_path --underline
set -g fish_color_cwd 89b4fa
set -g fish_color_cwd_root f38ba8
set -g fish_color_user a6e3a1
set -g fish_color_host f9e2af

# Inicializar Starship
if command -v starship >/dev/null
    starship init fish | source
end

# Inicializar zoxide si está disponible
if command -v zoxide >/dev/null
    zoxide init fish | source
end

# Configuración de direnv si está disponible
if command -v direnv >/dev/null
    direnv hook fish | source
end

# Función para actualizar el sistema
function update-all
    echo "🔄 Actualizando sistema..."
    sudo pacman -Syu
    if command -v yay >/dev/null
        echo "🔄 Actualizando AUR..."
        yay -Syu
    end
    if command -v flatpak >/dev/null
        echo "🔄 Actualizando Flatpak..."
        flatpak update
    end
    echo "✅ Sistema actualizado"
end

# Función para limpiar el sistema
function clean-system
    echo "🧹 Limpiando sistema..."
    sudo pacman -Rns (pacman -Qtdq) 2>/dev/null
    sudo pacman -Sc
    if command -v yay >/dev/null
        yay -Sc
    end
    if command -v flatpak >/dev/null
        flatpak uninstall --unused
    end
    echo "✅ Sistema limpio"
end

# Función para información del sistema
function sysinfo
    echo "💻 Información del Sistema"
    echo "=========================="
    echo "🖥️  Hostname: "(hostname)
    echo "👤 Usuario: "(whoami)
    echo "🐧 OS: "(uname -o)
    echo "🔧 Kernel: "(uname -r)
    echo "⏰ Uptime: "(uptime -p)
    echo "💾 Memoria: "(free -h | awk '/^Mem:/ {print $3 "/" $2}')
    echo "💿 Disco: "(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
    if command -v sensors >/dev/null
        echo "🌡️  CPU Temp: "(sensors | grep 'Core 0' | awk '{print $3}' | head -1)
    end
end

# Auto-completado mejorado
bind \t complete-and-search

# Configuración de historial
set -g fish_history_max 10000
set -g fish_history_ignore_space yes

# Configuración de Vi mode (opcional)
# fish_vi_key_bindings

# Función para crear directorio y entrar
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

# Función para extraer archivos
function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "No sé cómo extraer '$argv[1]'"
        end
    else
        echo "'$argv[1]' no es un archivo válido"
    end
end

# Cargar configuraciones adicionales
for file in ~/.config/fish/conf.d/*.fish
    source $file
end
