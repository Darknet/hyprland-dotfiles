# ================================
# ALIASES PARA FISH SHELL
# ================================

# Navegación
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ~ 'cd ~'
alias -- - 'cd -'

# Listado de archivos
alias ls 'exa --icons'
alias ll 'exa -l --icons --git'
alias la 'exa -la --icons --git'
alias lt 'exa --tree --icons'
alias l 'exa --icons'

# Comandos básicos mejorados
alias cat 'bat'
alias grep 'rg'
alias find 'fd'
alias du 'dust'
alias df 'duf'
alias ps 'procs'
alias top 'btop'
alias htop 'btop'

# Git
alias g 'git'
alias ga 'git add'
alias gaa 'git add .'
alias gc 'git commit'
alias gcm 'git commit -m'
alias gp 'git push'
alias gpl 'git pull'
alias gs 'git status'
alias gd 'git diff'
alias gl 'git log --oneline'
alias gb 'git branch'
alias gco 'git checkout'
alias gcb 'git checkout -b'

# Sistema
alias update 'sudo pacman -Syu'
alias install 'sudo pacman -S'
alias search 'pacman -Ss'
alias remove 'sudo pacman -Rns'
alias clean 'sudo pacman -Sc'
alias orphans 'sudo pacman -Rns (pacman -Qtdq)'

# Yay (AUR)
alias yinstall 'yay -S'
alias ysearch 'yay -Ss'
alias yupdate 'yay -Syu'
alias yremove 'yay -Rns'

# Systemctl
alias sc 'sudo systemctl'
alias scu 'systemctl --user'
alias scr 'sudo systemctl restart'
alias scs 'sudo systemctl start'
alias sct 'sudo systemctl stop'
alias sce 'sudo systemctl enable'
alias scd 'sudo systemctl disable'
alias scst 'systemctl status'

# Red
alias ping 'ping -c 5'
alias ports 'netstat -tulanp'
alias myip 'curl -s https://ipinfo.io/ip'
alias speedtest 'curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'

# Archivos y directorios
alias mkdir 'mkdir -pv'
alias cp 'cp -i'
alias mv 'mv -i'
alias rm 'rm -i'
alias ln 'ln -i'
alias chmod 'chmod --preserve-root'
alias chown 'chown --preserve-root'

# Editores
alias v 'nvim'
alias vim 'nvim'
alias nano 'nvim'
alias code 'code'

# Hyprland específicos
alias hypr-reload 'hyprctl reload'
alias hypr-restart 'pkill Hyprland'
alias waybar-reload 'pkill waybar; waybar &'
alias rofi-test 'rofi -show drun'

# Utilidades
alias weather 'curl wttr.in'
alias clock 'tty-clock -c'
alias matrix 'cmatrix'
alias pipes 'pipes.sh'
alias fetch 'neofetch'
alias fastfetch 'fastfetch'

# Docker (si está instalado)
alias d 'docker'
alias dc 'docker-compose'
alias dps 'docker ps'
alias di 'docker images'
alias drm 'docker rm'
alias drmi 'docker rmi'

# Desarrollo
alias py 'python'
alias py3 'python3'
alias pip 'pip3'
alias node 'node'
alias npm 'npm'
alias yarn 'yarn'

# Multimedia
alias yt 'yt-dlp'
alias ytmp3 'yt-dlp -x --audio-format mp3'
alias ytmp4 'yt-dlp -f "best[height<=720]"'

# Limpieza rápida
alias clean-downloads 'find ~/Downloads -type f -mtime +30 -delete'
alias clean-trash 'rm -rf ~/.local/share/Trash/*'
alias clean-cache 'rm -rf ~/.cache/*'
alias clean-logs 'sudo journalctl --vacuum-time=3d'

# Información del sistema
alias meminfo 'free -m -l -t'
alias cpuinfo 'lscpu'
alias diskinfo 'df -h'
alias gpuinfo 'lspci | grep -E "VGA|3D"'
alias usbinfo 'lsusb'

# Procesos
alias psg 'ps aux | grep -v grep | grep -i -E'
alias killall 'killall'
alias jobs 'jobs -l'

# Archivos de configuración rápidos
alias fishconfig 'nvim ~/.config/fish/config.fish'
alias hyprconfig 'nvim ~/.config/hypr/hyprland.conf'
alias waybarconfig 'nvim ~/.config/waybar/config.jsonc'
alias roficonfig 'nvim ~/.config/rofi/config.rasi'
alias kittyconfig 'nvim ~/.config/kitty/kitty.conf'
