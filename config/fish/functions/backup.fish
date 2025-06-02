function backup
    set -l backup_dir "$HOME/Backups"
    set -l date_str (date +%Y%m%d_%H%M%S)
    
    switch $argv[1]
        case "configs"
            echo "💾 Respaldando configuraciones..."
            mkdir -p "$backup_dir/configs"
            tar -czf "$backup_dir/configs/dotfiles_$date_str.tar.gz" \
                -C "$HOME" \
                .config/hypr \
                .config/waybar \
                .config/rofi \
                .config/kitty \
                .config/fish \
                .config/dunst
            echo "✅ Configuraciones respaldadas en $backup_dir/configs/dotfiles_$date_str.tar.gz"
        case "home"
            echo "💾 Respaldando directorio home..."
            mkdir -p "$backup_dir/home"
            rsync -av --exclude='.cache' --exclude='.local/share/Trash' \
                "$HOME/" "$backup_dir/home/home_$date_str/"
            echo "✅ Home respaldado en $backup_dir/home/home_$date_str/"
        case "packages"
            echo "💾 Respaldando lista de paquetes..."
            mkdir -p "$backup_dir/packages"
            pacman -Qqe > "$backup_dir/packages/pacman_$date_str.txt"
            if command -v yay >/dev/null
                yay -Qqe > "$backup_dir/packages/yay_$date_str.txt"
            end
            echo "✅ Lista de paquetes respaldada"
        case "*"
            echo "Backup Manager"
            echo "=============="
            echo "backup configs   - Respaldar configuraciones"
            echo "backup home      - Respaldar directorio home"
            echo "backup packages  - Respaldar lista de paquetes"
    end
end
