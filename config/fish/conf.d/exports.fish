# ================================
# VARIABLES DE ENTORNO
# ================================

# Editor por defecto
set -gx EDITOR nvim
set -gx VISUAL code

# Navegador por defecto
set -gx BROWSER firefox

# Terminal por defecto
set -gx TERMINAL kitty

# Pager
set -gx PAGER less
set -gx MANPAGER 'nvim +Man!'

# Configuración de Less
set -gx LESS '-R -i -w -M -z-4'
set -gx LESSHISTFILE '-'

# Configuración de FZF
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border --margin=1 --padding=1'
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

# Configuración de Ripgrep
set -gx RIPGREP_CONFIG_PATH ~/.config/ripgrep/config

# Configuración de Bat
set -gx BAT_THEME 'Catppuccin-mocha'

# Configuración de Node.js
set -gx NPM_CONFIG_PREFIX ~/.npm-global

# Configuración de Go
set -gx GOPATH ~/go
set -gx GOPROXY https://proxy.golang.org

# Configuración de Rust
set -gx CARGO_HOME ~/.cargo

# Configuración de Python
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx PYTHONUNBUFFERED 1

# Configuración de Java
set -gx JAVA_HOME /usr/lib/jvm/default

# Configuración de Android (si está instalado)
set -gx ANDROID_HOME ~/Android/Sdk
set -gx ANDROID_SDK_ROOT $ANDROID_HOME

# Configuración de Docker
set -gx DOCKER_BUILDKIT 1
set -gx COMPOSE_DOCKER_CLI_BUILD 1

# Configuración de SSH
set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket

# Configuración de GPG
set -gx GPG_TTY (tty)

# Configuración de XDG
set -gx XDG_CONFIG_HOME ~/.config
set -gx XDG_DATA_HOME ~/.local/share
set -gx XDG_CACHE_HOME ~/.cache
set -gx XDG_STATE_HOME ~/.local/state

# Configuración de Qt
set -gx QT_QPA_PLATFORMTHEME qt5ct
set -gx QT_AUTO_SCREEN_SCALE_FACTOR 1

# Configuración de GTK
set -gx GTK_THEME Catppuccin-Mocha-Standard-Blue-Dark

# Configuración de Gaming
set -gx STEAM_COMPAT_DATA_PATH ~/.steam/steam/steamapps/compatdata
set -gx MANGOHUD 1
set -gx DXVK_HUD compiler

# Configuración de desarrollo
set -gx MAKEFLAGS "-j"(nproc)
set -gx CFLAGS '-march=native -O2 -pipe'
set -gx CXXFLAGS $CFLAGS

# Configuración de colores para man pages
set -gx LESS_TERMCAP_mb \e'[1;32m'     # begin blinking
set -gx LESS_TERMCAP_md \e'[1;32m'     # begin bold
set -gx LESS_TERMCAP_me \e'[0m'        # end mode
set -gx LESS_TERMCAP_se \e'[0m'        # end standout-mode
set -gx LESS_TERMCAP_so \e'[01;33m'    # begin standout-mode - info box
set -gx LESS_TERMCAP_ue \e'[0m'        # end underline
set -gx LESS_TERMCAP_us \e'[1;4;31m'   # begin underline

# Configuración de tiempo
set -gx TZ 'Europe/Madrid'

# Configuración de idioma
set -gx LANG es_ES.UTF-8
set -gx LC_ALL es_ES.UTF-8

# Configuración de historial
set -gx HISTSIZE 10000
set -gx HISTFILESIZE 20000
