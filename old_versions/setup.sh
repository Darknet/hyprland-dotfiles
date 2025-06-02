#!/bin/bash

# Mejoras basadas en tu ejemplo
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.config"
readonly LOG_FILE="$HOME/.cache/hyprland-setup.log"

# Colores (usando readonly como en tu ejemplo)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Función de logging mejorada (basada en tu estilo)
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    case "$level" in
        "INFO")    echo -e "${BLUE}[INFO]${NC} $message" ;;
        "WARN")    echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR")   echo -e "${RED}[ERROR]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
    esac
    
    echo "$timestamp - [$level] $message" >> "$LOG_FILE"
}

# Función de error mejorada
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Header mejorado (estilo similar al tuyo)
print_header() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    HYPRLAND DOTFILES SETUP                  ║
║              Instalador y Configurador Completo             ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Verificar si ya se ejecutó (como en tu script)
check_previous_installation() {
    if [[ -f "$HOME/.hyprland_setup_completed" ]]; then
        log "WARN" "El setup ya se ejecutó anteriormente"
        read -p "¿Ejecutar de nuevo? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# Crear directorio de logs
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Success message
success() {
    log "${GREEN}✓ $1${NC}"
}

# Warning message
warning() {
    log "${YELLOW}⚠ $1${NC}"
}

# Info message
info() {
    log "${BLUE}ℹ $1${NC}"
}

# Header function
print_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    HYPRLAND DOTFILES SETUP                  ║"
    echo "║                Enhanced Configuration Manager                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root!"
    fi
}

# Check distribution
check_distro() {
    if [[ ! -f /etc/arch-release ]]; then
        error_exit "This script is designed for Arch Linux and its derivatives only!"
    fi
}

# Check internet connection
check_internet() {
    info "Checking internet connection..."
    if ! ping -c 1 google.com &> /dev/null; then
        error_exit "No internet connection detected!"
    fi
    success "Internet connection verified"
}

# Detect GPU type
detect_gpu() {
    info "Detecting GPU configuration..."
    
    # Check for NVIDIA GPU
    if lspci | grep -i nvidia &> /dev/null; then
        if lspci | grep -i intel &> /dev/null || lspci | grep -i amd &> /dev/null; then
            GPU_TYPE="hybrid"
            info "Hybrid GPU detected (NVIDIA + Intel/AMD)"
        else
            GPU_TYPE="nvidia"
            info "NVIDIA GPU detected"
        fi
    elif lspci | grep -i amd &> /dev/null; then
        GPU_TYPE="amd"
        info "AMD GPU detected"
    elif lspci | grep -i intel &> /dev/null; then
        GPU_TYPE="intel"
        info "Intel GPU detected"
    else
        GPU_TYPE="unknown"
        warning "Unknown GPU type detected"
    fi
}

# Check if laptop
detect_laptop() {
    if [[ -d /proc/acpi/battery ]] || [[ -d /sys/class/power_supply/BAT* ]]; then
        IS_LAPTOP=true
        info "Laptop detected"
    else
        IS_LAPTOP=false
        info "Desktop system detected"
    fi
}

# User prompts
ask_user_preferences() {
    echo -e "\n${CYAN}=== INSTALLATION PREFERENCES ===${NC}\n"
    
    # GPU Configuration
    echo -e "${WHITE}GPU Configuration:${NC}"
    case $GPU_TYPE in
        "nvidia")
            read -p "Configure NVIDIA drivers for Wayland/Hyprland? (y/N): " -n 1 -r
            echo
            INSTALL_NVIDIA=${REPLY,,}
            [[ $INSTALL_NVIDIA =~ ^[yY]$ ]] && INSTALL_NVIDIA=true || INSTALL_NVIDIA=false
            ;;
        "hybrid")
            read -p "Configure hybrid GPU setup (NVIDIA + Intel/AMD)? (y/N): " -n 1 -r
            echo
            INSTALL_HYBRID=${REPLY,,}
            [[ $INSTALL_HYBRID =~ ^[yY]$ ]] && INSTALL_HYBRID=true || INSTALL_HYBRID=false
            ;;
    esac
    
    # Waydroid
    echo -e "\n${WHITE}Android Emulation:${NC}"
    read -p "Install Waydroid (Android container)? (y/N): " -n 1 -r
    echo
    INSTALL_WAYDROID=${REPLY,,}
    [[ $INSTALL_WAYDROID =~ ^[yY]$ ]] && INSTALL_WAYDROID=true || INSTALL_WAYDROID=false
    
    # Gaming tools
    echo -e "\n${WHITE}Gaming:${NC}"
    read -p "Install gaming tools (Steam, Lutris, GameMode)? (y/N): " -n 1 -r
    echo
    INSTALL_GAMING=${REPLY,,}
    [[ $INSTALL_GAMING =~ ^[yY]$ ]] && INSTALL_GAMING=true || INSTALL_GAMING=false
    
    # Development tools
    echo -e "\n${WHITE}Development:${NC}"
    read -p "Install development tools (VS Code, Git tools, etc.)? (y/N): " -n 1 -r
    echo
    INSTALL_DEV=${REPLY,,}
    [[ $INSTALL_DEV =~ ^[yY]$ ]] && INSTALL_DEV=true || INSTALL_DEV=false
    
    # Multimedia tools
    echo -e "\n${WHITE}Multimedia:${NC}"
    read -p "Install multimedia tools (OBS, GIMP, etc.)? (y/N): " -n 1 -r
    echo
    INSTALL_MULTIMEDIA=${REPLY,,}
    [[ $INSTALL_MULTIMEDIA =~ ^[yY]$ ]] && INSTALL_MULTIMEDIA=true || INSTALL_MULTIMEDIA=false
    
    # Backup existing configs
    echo -e "\n${WHITE}Configuration:${NC}"
    read -p "Backup existing configurations? (Y/n): " -n 1 -r
    echo
    BACKUP_CONFIGS=${REPLY,,}
    [[ $BACKUP_CONFIGS =~ ^[nN]$ ]] && BACKUP_CONFIGS=false || BACKUP_CONFIGS=true
}

# Install AUR helper (yay)
install_yay() {
    if ! command -v yay &> /dev/null; then
        info "Installing yay AUR helper..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        success "yay installed successfully"
    else
        success "yay already installed"
    fi
}

# Update system
update_system() {
    info "Updating system packages..."
    sudo pacman -Syu --noconfirm
    success "System updated"
}

# Install base packages
install_base_packages() {
    info "Installing base Hyprland packages..."
    
    local base_packages=(
        # Hyprland and Wayland
        "hyprland"
        "xdg-desktop-portal-hyprland"
        "xdg-desktop-portal-gtk"
        "waybar"
        "rofi-wayland"
        "dunst"
        "swww"
        "grim"
        "slurp"
        "wl-clipboard"
        "cliphist"
        "swaylock-effects"
        "swayidle"
        
        # Terminal and shell
        "kitty"
        "fish"
        "starship"
        
        # File management
        "thunar"
        "thunar-archive-plugin"
        "file-roller"
        
        # Audio
        "pipewire"
        "pipewire-alsa"
        "pipewire-pulse"
        "pipewire-jack"
        "wireplumber"
        "pavucontrol"
        
        # Network
        "networkmanager"
        "network-manager-applet"
        
        # Fonts
        "ttf-font-awesome"
        "ttf-jetbrains-mono-nerd"
        "noto-fonts"
        "noto-fonts-emoji"
        
        # System tools
        "htop"
        "neofetch"
        "tree"
        "unzip"
        "wget"
        "curl"
        "git"
    )
    
    for package in "${base_packages[@]}"; do
        if ! pacman -Qi "$package" &> /dev/null; then
            sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
        fi
    done
    
    success "Base packages installed"
}

# Install AUR packages
install_aur_packages() {
    info "Installing AUR packages..."
    
    local aur_packages=(
        "hyprpicker"
        "wlogout"
        "swww"
        "nwg-look"
        "catppuccin-gtk-theme-mocha"
        "papirus-icon-theme"
    )
    
    for package in "${aur_packages[@]}"; do
        if ! pacman -Qi "$package" &> /dev/null; then
            yay -S --noconfirm "$package" || warning "Failed to install $package"
        fi
    done
    
    success "AUR packages installed"
}

# Configure NVIDIA
configure_nvidia() {
    if [[ $INSTALL_NVIDIA == true ]]; then
        info "Configuring NVIDIA for Wayland..."
        "$SCRIPT_DIR/scripts/install/nvidia-setup.sh"
        success "NVIDIA configuration completed"
    fi
}

# Configure hybrid GPU
configure_hybrid_gpu() {
    if [[ $INSTALL_HYBRID == true ]]; then
        info "Configuring hybrid GPU setup..."
        "$SCRIPT_DIR/scripts/install/hybrid-gpu-setup.sh"
        success "Hybrid GPU configuration completed"
    fi
}

# Install Waydroid
install_waydroid() {
    if [[ $INSTALL_WAYDROID == true ]]; then
        info "Installing Waydroid..."
        "$SCRIPT_DIR/scripts/install/waydroid-setup.sh"
        success "Waydroid installation completed"
    fi
}

# Install gaming tools
install_gaming_tools() {
    if [[ $INSTALL_GAMING == true ]]; then
        info "Installing gaming tools..."
        
        local gaming_packages=(
            "steam"
            "lutris"
            "gamemode"
            "lib32-gamemode"
            "mangohud"
            "lib32-mangohud"
        )
        
        for package in "${gaming_packages[@]}"; do
            sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
        done
        
        success "Gaming tools installed"
    fi
}

# Install development tools
install_dev_tools() {
    if [[ $INSTALL_DEV == true ]]; then
        info "Installing development tools..."
        
        local dev_packages=(
            "code"
            "git"
            "github-cli"
            "docker"
            "docker-compose"
            "nodejs"
            "npm"
            "python"
            "python-pip"
        )
        
        for package in "${dev_packages[@]}"; do
            if [[ $package == "code" ]]; then
                yay -S --noconfirm visual-studio-code-bin || warning "Failed to install VS Code"
            else
                sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
            fi
        done
        
        success "Development tools installed"
    fi
}

# Install multimedia tools
install_multimedia_tools() {
    if [[ $INSTALL_MULTIMEDIA == true ]]; then
        info "Installing multimedia tools..."
        
        local multimedia_packages=(
            "obs-studio"
            "gimp"
            "vlc"
            "firefox"
            "discord"
            "spotify-launcher"
        )
        
        for package in "${multimedia_packages[@]}"; do
            if [[ $package == "discord" || $package == "spotify-launcher" ]]; then
                yay -S --noconfirm "$package" || warning "Failed to install $package"
            else
                sudo pacman -S --noconfirm "$package" || warning "Failed to install $package"
            fi
        done
        
        success "Multimedia tools installed"
    fi
}

# Backup existing configurations
backup_existing_configs() {
    if [[ $BACKUP_CONFIGS == true ]]; then
        info "Backing up existing configurations..."
        "$SCRIPT_DIR/scripts/system/backup-configs.sh"
        success "Configurations backed up"
    fi
}

# Install dotfiles
install_dotfiles() {
    info "Installing dotfiles..."
    
    # Create necessary directories
    mkdir -p "$HOME/.config"
    
    # Copy configurations
    local config_dirs=("hypr" "waybar" "rofi" "dunst" "kitty" "fish")
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$SCRIPT_DIR/$dir" ]]; then
            cp -r "$SCRIPT_DIR/$dir" "$HOME/.config/"
            success "Installed $dir configuration"
        fi
    done
    
    # Copy starship config
    if [[ -f "$SCRIPT_DIR/starship.toml" ]]; then
        cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/"
        success "Installed starship configuration"
    fi
    
    # Make scripts executable
    find "$SCRIPT_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
    find "$HOME/.config" -name "*.sh" -exec chmod +x {} \;
    
    success "Dotfiles installed"
}

# Configure services
configure_services() {
    info "Configuring system services..."
    
    # Enable NetworkManager
    sudo systemctl enable NetworkManager
    
    # Enable bluetooth if available
    if systemctl list-unit-files | grep -q bluetooth; then
        sudo systemctl enable bluetooth
    fi
    
    # Configure fish as default shell
    if command -v fish &> /dev/null; then
        if [[ $SHELL != *"fish"* ]]; then
            chsh -s "$(which fish)"
            success "Fish shell set as default"
        fi
    fi
    
    success "Services configured"
}

# Final setup
final_setup() {
    info "Performing final setup..."
    
    # Update font cache
    fc-cache -fv
    
    # Update desktop database
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    
    # Set up wallpaper
    if [[ -f "$HOME/.config/hypr/wallpapers/default.jpg" ]]; then
        swww init &
        sleep 2
        swww img "$HOME/.config/hypr/wallpapers/default.jpg" &
    fi
    
    success "Final setup completed"
}

# Show completion message
show_completion() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    INSTALLATION COMPLETE!                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${WHITE}Installation Summary:${NC}"
    echo -e "${GREEN}✓${NC} Hyprland and base packages installed"
    echo -e "${GREEN}✓${NC} Dotfiles configured"
    echo -e "${GREEN}✓${NC} Services enabled"
    
    [[ $INSTALL_NVIDIA == true ]] && echo -e "${GREEN}✓${NC} NVIDIA drivers configured"
    [[ $INSTALL_HYBRID == true ]] && echo -e "${GREEN}✓${NC} Hybrid GPU setup configured"
    [[ $INSTALL_WAYDROID == true ]] && echo -e "${GREEN}✓${NC} Waydroid installed"
    [[ $INSTALL_GAMING == true ]] && echo -e "${GREEN}✓${NC} Gaming tools installed"
    [[ $INSTALL_DEV == true ]] && echo -e "${GREEN}✓${NC} Development tools installed"
    [[ $INSTALL_MULTIMEDIA == true ]] && echo -e "${GREEN}✓${NC} Multimedia tools installed"
    
    echo -e "\n${YELLOW}Important Notes:${NC}"
    echo -e "• Log out and log back in to start using Hyprland"
    echo -e "• Check the keybindings in ~/.config/hypr/keybinds.conf"
    echo -e "• Customize your setup using the provided scripts in ~/scripts/"
    echo -e "• Read the documentation in the docs/ folder"
    
    if [[ $INSTALL_NVIDIA == true ]] || [[ $INSTALL_HYBRID == true ]]; then
        echo -e "• ${RED}REBOOT REQUIRED${NC} for GPU drivers to take effect"
    fi
    
    echo -e "\n${CYAN}Useful Commands:${NC}"
    echo -e "• Super + Return: Open terminal"
    echo -e "• Super + D: Application launcher"
    echo -e "• Super + Q: Close window"
    echo -e "• Super + M: Exit Hyprland"
    echo -e "• Super + L: Lock screen"
    
    echo -e "\n${WHITE}Support:${NC}"
    echo -e "• Check logs: ${CYAN}$LOG_FILE${NC}"
    echo -e "• Documentation: ${CYAN}./docs/${NC}"
    echo -e "• Troubleshooting: ${CYAN}./docs/TROUBLESHOOTING.md${NC}"
    
    echo -e "\n${PURPLE}Enjoy your new Hyprland setup! 🚀${NC}\n"
}

# Cleanup function
cleanup() {
    info "Cleaning up temporary files..."
    # Clean package cache
    sudo pacman -Sc --noconfirm
    # Clean yay cache
    yay -Sc --noconfirm 2>/dev/null || true
    success "Cleanup completed"
}

# Error handling for interruption
trap 'error_exit "Installation interrupted by user"' INT TERM

# Main installation function
main() {
    print_header
    
    # Pre-installation checks
    check_previous_installation
    check_root
    check_distro
    check_internet
    
    log "INFO" "Iniciando instalación de Hyprland dotfiles..."
    
    # System detection
    detect_gpu
    detect_laptop
    
    # User preferences
    ask_user_preferences
    
    # Confirm installation
    echo -e "\n${YELLOW}Ready to begin installation with the following settings:${NC}"
    echo -e "GPU Type: ${WHITE}$GPU_TYPE${NC}"
    echo -e "Laptop: ${WHITE}$IS_LAPTOP${NC}"
    [[ $INSTALL_NVIDIA == true ]] && echo -e "NVIDIA Setup: ${GREEN}Yes${NC}"
    [[ $INSTALL_HYBRID == true ]] && echo -e "Hybrid GPU: ${GREEN}Yes${NC}"
    [[ $INSTALL_WAYDROID == true ]] && echo -e "Waydroid: ${GREEN}Yes${NC}"
    [[ $INSTALL_GAMING == true ]] && echo -e "Gaming Tools: ${GREEN}Yes${NC}"
    [[ $INSTALL_DEV == true ]] && echo -e "Dev Tools: ${GREEN}Yes${NC}"
    [[ $INSTALL_MULTIMEDIA == true ]] && echo -e "Multimedia: ${GREEN}Yes${NC}"
    [[ $BACKUP_CONFIGS == true ]] && echo -e "Backup Configs: ${GREEN}Yes${NC}"
    
    echo -e "\n${WHITE}Press Enter to continue or Ctrl+C to cancel...${NC}"
    read -r
    
    # Installation steps
    info "Starting Hyprland dotfiles installation..."
    
    # Core installation
    update_system
    install_yay
    install_base_packages
    install_aur_packages
    
    # Hardware-specific configuration
    configure_nvidia
    configure_hybrid_gpu
    
    # Optional components
    install_waydroid
    install_gaming_tools
    install_dev_tools
    install_multimedia_tools
    
    # Configuration
    backup_existing_configs
    install_dotfiles
    configure_services
    final_setup
	
    # Marcar como completado
    touch "$HOME/.hyprland_setup_completed"
    
    # Cleanup and completion
    cleanup
    show_completion
    
    # Log completion
    log "Installation completed successfully at $(date)"
    
	# Sugerir ejecutar post-instalación
    echo -e "\n${CYAN}💡 Sugerencia:${NC}"
    echo -e "Ejecuta el script de post-instalación para configuraciones avanzadas:"
    echo -e "${WHITE}./scripts/post-install.sh${NC}"
	
    # Ask for reboot if needed
    if [[ $INSTALL_NVIDIA == true ]] || [[ $INSTALL_HYBRID == true ]]; then
        echo -e "\n${RED}A reboot is required for GPU drivers to work properly.${NC}"
        read -p "Reboot now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo reboot
        fi
    fi
}

# Help function
show_help() {
    echo -e "${WHITE}Hyprland Dotfiles Setup Script${NC}"
    echo -e "Enhanced setup combining best features from JaKooLit and mylinuxforwork\n"
    echo -e "${WHITE}Usage:${NC}"
    echo -e "  $0 [OPTIONS]\n"
    echo -e "${WHITE}Options:${NC}"
    echo -e "  -h, --help     Show this help message"
    echo -e "  -v, --version  Show version information"
    echo -e "  --no-backup    Skip configuration backup"
    echo -e "  --minimal      Install only essential packages"
    echo -e "  --full         Install all optional components"
    echo -e "  --dry-run      Show what would be installed without installing\n"
    echo -e "${WHITE}Examples:${NC}"
    echo -e "  $0                    # Interactive installation"
    echo -e "  $0 --minimal          # Minimal installation"
    echo -e "  $0 --full             # Full installation with all components"
    echo -e "  $0 --no-backup        # Skip backing up existing configs\n"
}

# Version function
show_version() {
    echo -e "${WHITE}Hyprland Dotfiles Setup Script${NC}"
    echo -e "Version: 1.0"
    echo -e "Author: Enhanced Hyprland Setup"
    echo -e "Based on JaKooLit and mylinuxforwork dotfiles\n"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            --no-backup)
                BACKUP_CONFIGS=false
                shift
                ;;
            --minimal)
                INSTALL_GAMING=false
                INSTALL_DEV=false
                INSTALL_MULTIMEDIA=false
                INSTALL_WAYDROID=false
                shift
                ;;
            --full)
                INSTALL_GAMING=true
                INSTALL_DEV=true
                INSTALL_MULTIMEDIA=true
                INSTALL_WAYDROID=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
}

# Initialize variables
GPU_TYPE=""
IS_LAPTOP=false
INSTALL_NVIDIA=false
INSTALL_HYBRID=false
INSTALL_WAYDROID=false
INSTALL_GAMING=false
INSTALL_DEV=false
INSTALL_MULTIMEDIA=false
BACKUP_CONFIGS=true
DRY_RUN=false

# Parse arguments and run main function
parse_args "$@"

# Run dry-run if requested
if [[ $DRY_RUN == true ]]; then
    echo -e "${YELLOW}DRY RUN MODE - No packages will be installed${NC}\n"
    detect_gpu
    detect_laptop
    ask_user_preferences
    echo -e "\n${WHITE}Would install:${NC}"
    echo -e "• Base Hyprland packages"
    echo -e "• AUR packages"
    [[ $INSTALL_NVIDIA == true ]] && echo -e "• NVIDIA drivers and configuration"
    [[ $INSTALL_HYBRID == true ]] && echo -e "• Hybrid GPU configuration"
    [[ $INSTALL_WAYDROID == true ]] && echo -e "• Waydroid"
    [[ $INSTALL_GAMING == true ]] && echo -e "• Gaming tools"
    [[ $INSTALL_DEV == true ]] && echo -e "• Development tools"
    [[ $INSTALL_MULTIMEDIA == true ]] && echo -e "• Multimedia tools"
    echo -e "• Dotfiles and configurations"
    exit 0
fi

# Run main installation
# Ejecutar si es llamado directamente (como en tu ejemplo)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
# Exit successfully
exit 0

