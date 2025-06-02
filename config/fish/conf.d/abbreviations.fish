# ================================
# ABREVIACIONES PARA FISH SHELL
# ================================

# Git abreviaciones
abbr -a gs git status
abbr -a ga git add
abbr -a gaa git add .
abbr -a gc git commit
abbr -a gcm git commit -m
abbr -a gp git push
abbr -a gpl git pull
abbr -a gd git diff
abbr -a gl git log --oneline
abbr -a gb git branch
abbr -a gco git checkout
abbr -a gcb git checkout -b
abbr -a gm git merge
abbr -a gr git rebase
abbr -a gst git stash
abbr -a gstp git stash pop
abbr -a gf git fetch
abbr -a grh git reset --hard
abbr -a grs git reset --soft

# Sistema
abbr -a ll exa -l --icons --git
abbr -a la exa -la --icons --git
abbr -a lt exa --tree --icons
abbr -a cat bat
abbr -a grep rg
abbr -a find fd
abbr -a ps procs
abbr -a top btop

# Pacman
abbr -a pac sudo pacman -S
abbr -a pacs pacman -Ss
abbr -a pacu sudo pacman -Syu
abbr -a pacr sudo pacman -Rns
abbr -a paci pacman -Si
abbr -a pacq pacman -Q
abbr -a pacl pacman -Ql

# Yay
abbr -a y yay -S
abbr -a ys yay -Ss
abbr -a yu yay -Syu
abbr -a yr yay -Rns

# Systemctl
abbr -a sc sudo systemctl
abbr -a scu systemctl --user
abbr -a scr sudo systemctl restart
abbr -a scs sudo systemctl start
abbr -a sct sudo systemctl stop
abbr -a sce sudo systemctl enable
abbr -a scd sudo systemctl disable
abbr -a scst systemctl status

# Docker
abbr -a d docker
abbr -a dc docker-compose
abbr -a dps docker ps
abbr -a di docker images
abbr -a drm docker rm
abbr -a drmi docker rmi
abbr -a dex docker exec -it
abbr -a dlog docker logs

# Navegación
abbr -a .. cd ..
abbr -a ... cd ../..
abbr -a .... cd ../../..
abbr -a ..... cd ../../../..

# Editores
abbr -a v nvim
abbr -a vim nvim
abbr -a nano nvim

# Red
abbr -a ping ping -c 5
abbr -a wget wget -c
abbr -a curl curl -L

# Multimedia
abbr -a yt yt-dlp
abbr -a ytmp3 yt-dlp -x --audio-format mp3
abbr -a ytmp4 yt-dlp -f "best[height<=720]"

# Desarrollo
abbr -a py python
abbr -a py3 python3
abbr -a pip pip3
abbr -a venv python -m venv
abbr -a serve python -m http.server
abbr -a json python -m json.tool

# Node.js
abbr -a ni npm install
abbr -a nr npm run
abbr -a ns npm start
abbr -a nt npm test
abbr -a nb npm run build

# Rust
abbr -a cb cargo build
abbr -a cr cargo run
abbr -a ct cargo test
abbr -a cc cargo check
abbr -a cu cargo update

# Hyprland específicos
abbr -a hypr-reload hyprctl reload
abbr -a waybar-reload pkill waybar; waybar &
abbr -a rofi-test rofi -show drun

# Utilidades rápidas
abbr -a weather curl wttr.in
abbr -a myip curl -s https://ipinfo.io/ip
abbr -a ports netstat -tulanp
abbr -a meminfo free -m -l -t
abbr -a diskinfo df -h

# Limpieza
abbr -a clean-cache rm -rf ~/.cache/*
abbr -a clean-trash rm -rf ~/.local/share/Trash/*
abbr -a clean-logs sudo journalctl --vacuum-time=3d

# Archivos de configuración
abbr -a fishconf nvim ~/.config/fish/config.fish
abbr -a hyprconf nvim ~/.config/hypr/hyprland.conf
abbr -a waybarconf nvim ~/.config/waybar/config.jsonc
abbr -a roficonf nvim ~/.config/rofi/config.rasi
abbr -a kittyconf nvim ~/.config/kitty/kitty.conf

# Backup rápido
abbr -a backup-dots tar -czf ~/dotfiles-backup-(date +%Y%m%d).tar.gz ~/.config/
