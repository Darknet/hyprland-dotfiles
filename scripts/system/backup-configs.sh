#!/bin/bash
# ================================
# SCRIPT DE BACKUP DE CONFIGURACIONES
# ================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

notify() {
    if command -v dunstify &> /dev/null; then
        dunstify -u normal -t 5000 "Backup" "$1"
    fi
}

# Variables
BACKUP_DIR="$HOME/Backups"
DATE_STR=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)

# Crear directorio de backup
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"/{configs,packages,system,full}
    print_success "Directorio de backup creado: $BACKUP_DIR"
}

# Backup de configuraciones de dotfiles
backup_dotfiles() {
    print_status "Respaldando configuraciones de dotfiles..."
    
    local backup_file="$BACKUP_DIR/configs/dotfiles_${HOSTNAME}_${DATE_STR}.tar.gz"
    
    # Configuraciones a respaldar
    local configs=(
        ".config/hypr"
        ".config/waybar"
        ".config/rofi"
        ".config/kitty"
        ".config/fish"
        ".config/dunst"
        ".config/starship.toml"
        ".config/git"
        ".config/nvim"
        ".bashrc"
        ".zshrc"
        ".profile"
        ".xinitrc"
        ".Xresources"
    )
    
    # Crear archivo tar con las configuraciones existentes
    local existing_configs=()
    for config in "${configs[@]}"; do
        if [[ -e "$HOME/$config" ]]; then
            existing_configs+=("$config")
        fi
    done
    
    if [[ ${#existing_configs[@]} -gt 0 ]]; then
        tar -czf "$backup_file" -C "$HOME" "${existing_configs[@]}" 2>/dev/null || true
        print_success "Dotfiles respaldados en: $backup_file"
        notify "💾 Dotfiles respaldados"
    else
        print_warning "No se encontraron configuraciones para respaldar"
    fi
}

# Backup de lista de paquetes
backup_packages() {
    print_status "Respaldando lista de paquetes..."
    
    local package_dir="$BACKUP_DIR/packages"
    local package_file="$package_dir/packages_${HOSTNAME}_${DATE_STR}"
    
    # Paquetes de pacman
    pacman -Qqe > "${package_file}_pacman.txt"
    pacman -Qqem > "${package_file}_aur.txt" 2>/dev/null || touch "${package_file}_aur.txt"
    
    # Paquetes de Flatpak
    if command -v flatpak &> /dev/null; then
        flatpak list --app --columns=application > "${package_file}_flatpak.txt" 2>/dev/null || touch "${package_file}_flatpak.txt"
    fi
    
    # Paquetes de npm globales
    if command -v npm &> /dev/null; then
        npm list -g --depth=0 > "${package_file}_npm.txt" 2>/dev/null || touch "${package_file}_npm.txt"
    fi
    
    # Paquetes de pip
    if command -v pip &> /dev/null; then
        pip list > "${package_file}_pip.txt" 2>/dev/null || touch "${package_file}_pip.txt"
    fi
    
    # Crear script de restauración
    cat > "$package_dir/restore_packages_${DATE_STR}.sh" << 'EOF'
#!/bin/bash
# Script de restauración de paquetes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE_STR=$(basename "$0" | sed 's/restore_packages_\(.*\)\.sh/\1/')

echo "Restaurando paquetes del backup: $DATE_STR"

# Instalar paquetes de pacman
if [[ -f "${SCRIPT_DIR}/packages_$(hostname)_${DATE_STR}_pacman.txt" ]]; then
    echo "Instalando paquetes de pacman..."
    sudo pacman -S --needed - < "${SCRIPT_DIR}/packages_$(hostname)_${DATE_STR}_pacman.txt"
fi

# Instalar paquetes AUR
if [[ -f "${SCRIPT_DIR}/packages_$(hostname)_${DATE_STR}_aur.txt" ]] && command -v yay &> /dev/null; then
    echo "Instalando paquetes AUR..."
    yay -S --needed - < "${SCRIPT_DIR}/packages_$(hostname)_${DATE_STR}_aur.txt"
fi

# Instalar paquetes Flatpak
if [[ -f "${SCRIPT_DIR}/packages_$(hostname)_${DATE_STR}_flatpak.txt" ]] && command -v flatpak &> /dev/null; then
    echo "Instalando paquetes Flatpak..."
    while read -r app; do
        flatpak install -y "$app" 2>/dev/null || true
    done < "${SCRIPT_DIR}/packages_$(hostname)_${DATE_STR}_flatpak.txt"
fi

echo "Restauración completada"
EOF
    
    chmod +x "$package_dir/restore_packages_${DATE_STR}.sh"
    
    print_success "Lista de paquetes respaldada en: $package_dir"
    notify "📦 Lista de paquetes respaldada"
}

# Backup de configuración del sistema
backup_system_config() {
    print_status "Respaldando configuración del sistema..."
    
    local system_file="$BACKUP_DIR/system/system_config_${HOSTNAME}_${DATE_STR}.tar.gz"
    
    # Configuraciones del sistema a respaldar
    local system_configs=(
        "/etc/fstab"
        "/etc/hosts"
        "/etc/hostname"
        "/etc/locale.conf"
        "/etc/vconsole.conf"
        "/etc/mkinitcpio.conf"
        "/etc/pacman.conf"
        "/etc/makepkg.conf"
        "/etc/systemd/system"
        "/etc/NetworkManager"
        "/etc/bluetooth"
    )
    
    # Crear archivo tar con las configuraciones del sistema existentes
    local existing_system_configs=()
    for config in "${system_configs[@]}"; do
        if [[ -e "$config" ]]; then
            existing_system_configs+=("$config")
        fi
    done
    
    if [[ ${#existing_system_configs[@]} -gt 0 ]]; then
        sudo tar -czf "$system_file" "${existing_system_configs[@]}" 2>/dev/null || true
        sudo chown "$USER:$USER" "$system_file"
        print_success "Configuración del sistema respaldada en: $system_file"
        notify "⚙️ Configuración del sistema respaldada"
    fi
}

# Backup completo del home
backup_full_home() {
    print_status "Respaldando directorio home completo..."
    print_warning "Esto puede tomar mucho tiempo y espacio..."
    
    read -p "¿Continuar con el backup completo? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    local home_backup="$BACKUP_DIR/full/home_${HOSTNAME}_${DATE_STR}"
    
    # Directorios a excluir
    local exclude_dirs=(
        "--exclude=.cache"
        "--exclude=.local/share/Trash"
        "--exclude=.local/share/Steam"
        "--exclude=.wine"
        "--exclude=Downloads"
        "--exclude=.npm"
        "--exclude=.cargo/registry"
        "--exclude=node_modules"
        "--exclude=.git"
        "--exclude=.mozilla/firefox/*/Cache"
        "--exclude=.var/app/*/cache"
    )
    
    rsync -av "${exclude_dirs[@]}" "$HOME/" "$home_backup/" --progress
    
    print_success "Backup completo del home en: $home_backup"
    notify "🏠 Backup completo del home completado"
}

# Backup de SSH y GPG
backup_security() {
    print_status "Respaldando claves SSH y GPG..."
    
    local security_backup="$BACKUP_DIR/configs/security_${HOSTNAME}_${DATE_STR}.tar.gz.gpg"
    
    # Crear backup temporal
    local temp_backup="/tmp/security_backup_${DATE_STR}.tar.gz"
    
    # Archivos de seguridad a respaldar
    local security_files=()
    
    # SSH
    if [[ -d ~/.ssh ]]; then
        security_files+=(".ssh")
    fi
    
    # GPG
    if [[ -d ~/.gnupg ]]; then
        security_files+=(".gnupg")
    fi
    
    if [[ ${#security_files[@]} -gt 0 ]]; then
        tar -czf "$temp_backup" -C "$HOME" "${security_files[@]}"
        
        # Encriptar el backup
        read -s -p "Ingrese contraseña para encriptar el backup de seguridad: " password
        echo
        echo "$password" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "$security_backup" "$temp_backup"
        
        # Limpiar archivo temporal
        rm -f "$temp_backup"
        
        print_success "Backup de seguridad encriptado en: $security_backup"
        notify "🔐 Backup de seguridad completado"
    else
        print_warning "No se encontraron archivos de seguridad para respaldar"
    fi
}

# Listar backups existentes
list_backups() {
    print_status "Backups existentes:"
    echo
    
    if [[ -d "$BACKUP_DIR" ]]; then
        echo "📁 Configuraciones:"
        ls -la "$BACKUP_DIR/configs/" 2>/dev/null | tail -n +2 || echo "  Ninguno"
        echo
        
        echo "📦 Paquetes:"
        ls -la "$BACKUP_DIR/packages/" 2>/dev/null | tail -n +2 || echo "  Ninguno"
        echo
        
        echo "⚙️ Sistema:"
        ls -la "$BACKUP_DIR/system/" 2>/dev/null | tail -n +2 || echo "  Ninguno"
        echo
        
        echo "🏠 Completos:"
        ls -la "$BACKUP_DIR/full/" 2>/dev/null | tail -n +2 || echo "  Ninguno"
    else
        print_warning "No existe el directorio de backups"
    fi
}

# Restaurar desde backup
restore_backup() {
    print_status "Función de restauración..."
    
    if [[ ! -d "$BACKUP_DIR/configs" ]]; then
        print_error "No se encontraron backups de configuración"
        return 1
    fi
    
    echo "Backups de configuración disponibles:"
    ls -1 "$BACKUP_DIR/configs/"*.tar.gz 2>/dev/null | nl -w2 -s') '
    echo
    
    read -p "Seleccione el número del backup a restaurar (0 para cancelar): " choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    fi
    
    local backup_file=$(ls -1 "$BACKUP_DIR/configs/"*.tar.gz 2>/dev/null | sed -n "${choice}p")
    
    if [[ -z "$backup_file" ]]; then
        print_error "Selección inválida"
        return 1
    fi
    
    print_warning "Esto sobrescribirá las configuraciones actuales"
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tar -xzf "$backup_file" -C "$HOME"
        print_success "Backup restaurado desde: $backup_file"
        notify "🔄 Configuraciones restauradas"
    fi
}

# Limpiar backups antiguos
clean_old_backups() {
    print_status "Limpiando backups antiguos..."
    
    read -p "¿Eliminar backups con más de 30 días? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        find "$BACKUP_DIR" -type f -mtime +30 -delete 2>/dev/null || true
        print_success "Backups antiguos eliminados"
        notify "🧹 Backups antiguos eliminados"
    fi
}

# Función principal
main() {
    print_status "💾 Sistema de Backup de Configuraciones"
    notify "💾 Iniciando sistema de backup"
    
    create_backup_dir
    
    echo
    echo "Seleccione una opción:"
    echo "1) Backup completo (dotfiles + paquetes + sistema)"
    echo "2) Solo dotfiles"
    echo "3) Solo lista de paquetes"
    echo "4) Solo configuración del sistema"
    echo "5) Backup completo del home"
    echo "6) Backup de seguridad (SSH/GPG)"
    echo "7) Listar backups existentes"
    echo "8) Restaurar desde backup"
    echo "9) Limpiar backups antiguos"
    echo
    read -p "Opción [1-9]: " choice
    
    case $choice in
        1)
            backup_dotfiles
            backup_packages
            backup_system_config
            ;;
        2)
            backup_dotfiles
            ;;
        3)
            backup_packages
            ;;
        4)
            backup_system_config
            ;;
        5)
            backup_full_home
            ;;
        6)
            backup_security
            ;;
        7)
            list_backups
            ;;
        8)
            restore_backup
            ;;
        9)
            clean_old_backups
            ;;
        *)
            print_error "Opción inválida"
            exit 1
            ;;
    esac
    
    print_success "✅ Operación de backup completada"
    notify "✅ Backup completado exitosamente"
}

# Verificar dependencias
check_dependencies() {
    local deps=("tar" "rsync")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "Dependencia faltante: $dep"
            exit 1
        fi
    done
}

# Verificar que no se ejecute como root
if [[ $EUID -eq 0 ]]; then
    print_error "No ejecute este script como root"
    exit 1
fi

check_dependencies
main "$@"
