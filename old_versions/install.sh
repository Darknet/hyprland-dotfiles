#!/bin/bash

# Enhanced Hyprland Dotfiles Installation Script
# Combining best features from JaKooLit and mylinuxforwork

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/hyprland-install.log"
CONFIG_DIR="$HOME/.config"
GPU_TYPE=""
LAPTOP_MODE=false
INSTALL_WAYDROID=false
INSTALL_NVIDIA=false
HYBRID_GRAPHICS=false
INSTALL_GAMING=false
INSTALL_VPN=false

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗       ║
║    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗      ║
║    ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║      ║
║    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║      ║
║    ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝      ║
║    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝       ║
║                                                                              ║
║                        DOTFILES INSTALLER v2.0                              ║
║                                                                              ║
║    🚀 Instalación completa de Hyprland con todas las funcionalidades        ║
║    📦 Waybar + Rofi + Dunst + Fish + VPN + Gaming + Temas                   ║
║    🎨 Configuración optimizada para productividad y gaming                  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo
}

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running on Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux only!"
    fi
    log "Arch Linux detected"
}

# System detection
detect_system() {
    log "Detecting system configuration..."
    
    # Check if laptop
    if [ -d "/sys/class/power_supply" ] && ls /sys/class/power_supply/ | grep -q "BAT"; then
        LAPTOP_MODE=true
        info "Laptop detected"
    fi
    
    # Detect GPU
    if lspci | grep -i nvidia > /dev/null; then
        if lspci | grep -i intel > /dev/null || lspci | grep -i amd > /dev/null; then
            GPU_TYPE="hybrid"
            info "Hybrid GPU setup detected (NVIDIA + integrated)"
        else
            GPU_TYPE="nvidia"
            info "NVIDIA GPU detected"
        fi
    elif lspci | grep -i amd > /dev/null; then
        GPU_TYPE="amd"
        info "AMD GPU detected"
    else
        GPU_TYPE="intel"
        info "Intel GPU detected"
    fi
}

# User preferences
ask_user_preferences() {
    echo -e "${PURPLE}=== Installation Configuration ===${NC}"
    echo
    
    # GPU configuration
    if [[ "$GPU_TYPE" == "nvidia" || "$GPU_TYPE" == "hybrid" ]]; then
        echo -e "${YELLOW}NVIDIA GPU detected.${NC}"
        read -p "Install NVIDIA drivers optimized for Wayland/Hyprland? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_NVIDIA=true
        fi
        
        if [[ "$GPU_TYPE" == "hybrid" ]]; then
            echo -e "${YELLOW}Hybrid GPU setup detected.${NC}"
            read -p "Configure for laptop hybrid graphics (Optimus)? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                HYBRID_GRAPHICS=true
            fi
        fi
    fi
    
    # Waydroid
    echo -e "${CYAN}Waydroid allows running Android apps on Linux.${NC}"
    read -p "Install Waydroid (Android emulation)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_WAYDROID=true
    fi
    
    # Gaming setup
    echo -e "${CYAN}Gaming mode includes Steam, Lutris, GameMode, and optimizations.${NC}"
    read -p "Install gaming tools and optimizations? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_GAMING=true
    fi
    
    # VPN setup
    echo -e "${CYAN}VPN manager includes OpenVPN and WireGuard support.${NC}"
    read -p "Install VPN management tools? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_VPN=true
    fi
    
    echo
    log "Configuration completed"
}

# Install AUR helper
install_yay() {
    if ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        success "yay installed successfully"
    else
        info "yay already installed"
    fi
}

# Package installation
install_base_packages() {
    log "Installing base packages..."
    
    local packages=(
        # Hyprland and Wayland essentials
        "hyprland" "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk"
        "waybar" "rofi-wayland" "dunst" "swww" "grim" "slurp" "wl-clipboard"
        "wlogout" "swaylock-effects" "swayidle"
        
        # Audio system
        "pipewire" "pipewire-alsa" "pipewire-pulse" "pipewire-jack" "wireplumber"
        "pavucontrol" "pamixer" "playerctl"
        
        # System utilities
        "kitty" "thunar" "thunar-volman" "thunar-archive-plugin"
        "firefox" "neofetch" "fastfetch" "htop" "btop" "eza" "bat" "fd" "ripgrep"
        "network-manager-applet" "blueman" "brightnessctl" "gammastep"
        
        # Development tools
        "git" "vim" "neovim" "code" "base-devel" "cmake" "ninja"
        
        # Shell and terminal
        "fish" "starship" "zoxide" "fzf"
        
        # Fonts and themes
        "ttf-font-awesome" "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd"
        "noto-fonts" "noto-fonts-emoji" "noto-fonts-cjk"
        "papirus-icon-theme" "arc-gtk-theme" "catppuccin-gtk-theme-mocha"
        
        # Media and graphics
        "mpv" "imv" "gimp" "obs-studio"
        
        # Archive support
        "unzip" "unrar" "p7zip" "zip"
        
        # System monitoring
        "lm_sensors" "acpi" "upower"
    )
    
    sudo pacman -S --needed --noconfirm "${packages[@]}" || error "Failed to install base packages"
    success "Base packages installed"
}

# Install AUR packages
install_aur_packages() {
    log "Installing AUR packages..."
    
    local aur_packages=(
        "hyprpicker" "hyprshot" "wlr-randr"
        "catppuccin-cursors-mocha" "bibata-cursor-theme"
        "visual-studio-code-bin"
    )
    
    yay -S --noconfirm "${aur_packages[@]}" || warning "Some AUR packages failed to install"
    success "AUR packages installed"
}

# NVIDIA configuration
install_nvidia_packages() {
    if [[ "$INSTALL_NVIDIA" == true ]]; then
        log "Installing NVIDIA packages for Wayland..."
        
        local nvidia_packages=(
            "nvidia" "nvidia-utils" "nvidia-settings"
            "libva-nvidia-driver" "egl-wayland"
        )
        
        if [[ "$HYBRID_GRAPHICS" == true ]]; then
            nvidia_packages+=("optimus-manager" "optimus-manager-qt")
        fi
        
        sudo pacman -S --needed --noconfirm "${nvidia_packages[@]}" || error "Failed to install NVIDIA packages"
        
        configure_nvidia_wayland
        success "NVIDIA packages installed and configured"
    fi
}

configure_nvidia_wayland() {
    log "Configuring NVIDIA for Wayland..."
    
    # Add kernel parameters
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    
    # Create NVIDIA environment config
    mkdir -p "$CONFIG_DIR/hypr"
    cat > "$CONFIG_DIR/hypr/nvidia.conf" << 'EOF'
# NVIDIA specific configuration
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = NVIDIA_WAYLAND,1

# Cursor fix for NVIDIA
cursor {
    no_hardware_cursors = true
}
EOF
}

# Gaming packages
install_gaming_packages() {
    if [[ "$INSTALL_GAMING" == true ]]; then
        log "Installing gaming packages..."
        
        local gaming_packages=(
            "steam" "lutris" "gamemode" "lib32-gamemode"
            "wine" "winetricks" "lib32-vulkan-icd-loader"
            "mangohud" "lib32-mangohud" "goverlay"
        )
        
        # Add GPU-specific packages
        case "$GPU_TYPE" in
            "nvidia")
                gaming_packages+=("lib32-nvidia-utils" "nvidia-prime")
                ;;
            "amd")
                gaming_packages+=("lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon")
                ;;
            "intel")
                gaming_packages+=("lib32-mesa" "vulkan-intel" "lib32-vulkan-intel")
                ;;
        esac
        
        sudo pacman -S --needed --noconfirm "${gaming_packages[@]}" || warning "Some gaming packages failed to install"
        
        # Enable gamemode service
        sudo systemctl enable --now gamemode
        
        success "Gaming packages installed"
    fi
}

# VPN packages
install_vpn_packages() {
    if [[ "$INSTALL_VPN" == true ]]; then
        log "Installing VPN packages..."
        
        local vpn_packages=(
            "openvpn" "wireguard-tools" "networkmanager-openvpn"
            "networkmanager-wireguard" "openresolv"
        )
        
        sudo pacman -S --needed --noconfirm "${vpn_packages[@]}" || error "Failed to install VPN packages"
        success "VPN packages installed"
    fi
}

# Waydroid installation
install_waydroid() {
    if [[ "$INSTALL_WAYDROID" == true ]]; then
        log "Installing Waydroid..."
        
        yay -S --noconfirm waydroid python-pyclip || error "Failed to install Waydroid"
        
        # Enable services
        sudo systemctl enable --now waydroid-container.service
        
        success "Waydroid installed. Run the waydroid-setup.sh script to complete setup."
    fi
}

# Copy dotfiles
setup_dotfiles() {
    log "Setting up dotfiles..."
    
    # Create directory structure
    mkdir -p "$CONFIG_DIR"/{hypr,waybar,rofi,dunst,kitty,fish,scripts}
    mkdir -p "$CONFIG_DIR/hypr"/{scripts,wallpapers}
    mkdir -p "$CONFIG_DIR/waybar/scripts"
    mkdir -p "$CONFIG_DIR/rofi"/{themes,scripts}
    mkdir -p "$CONFIG_DIR/kitty"/{themes,sessions}
    mkdir -p "$CONFIG_DIR/fish"/{functions,conf.d}
    mkdir -p "$HOME/Pictures/wallpapers"
    mkdir -p "$HOME/.local/share/applications"
    
    # Copy configuration files
    copy_hypr_configs
    copy_waybar_configs
    copy_rofi_configs
    copy_other_configs
    copy_scripts
    
    success "Dotfiles configured"
}

copy_hypr_configs() {
    log "Copying Hyprland configurations..."
    
    # Copy all hypr configs from the dotfiles
    cp -r "$SCRIPT_DIR/hypr/"* "$CONFIG_DIR/hypr/" 2>/dev/null || true
    
    # Ensure proper permissions
    chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null
}

copy_waybar_configs() {
    log "Copying Waybar configurations..."
    
    # Copy waybar configs
    cp -r "$SCRIPT_DIR/waybar/"* "$CONFIG_DIR/waybar/" 2>/dev/null || true
    
    # Make scripts executable
    chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh 2>/dev/null || true
}

copy_rofi_configs() {
    log "Copying Rofi configurations..."
    
    # Copy rofi configs
    cp -r "$SCRIPT_DIR/rofi/"* "$CONFIG_DIR/rofi/" 2>/dev/null || true
    
    # Make scripts executable
    chmod +x "$CONFIG_DIR/rofi/scripts/"*.sh 2>/dev/null || true
}

copy_other_configs() {
    log "Copying other configurations..."
    
    # Copy remaining configs
    cp -r "$SCRIPT_DIR/dunst/"* "$CONFIG_DIR/dunst/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/kitty/"* "$CONFIG_DIR/kitty/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/fish/"* "$CONFIG_DIR/fish/" 2>/dev/null || true
    
    # Copy starship config
    cp "$SCRIPT_DIR/starship.toml" "$CONFIG_DIR/" 2>/dev/null || true
}

copy_scripts() {
    log "Copying utility scripts..."
    
    # Copy main scripts
    cp -r "$SCRIPT_DIR/scripts/"* "$CONFIG_DIR/scripts/" 2>/dev/null || true
    
    # Make all scripts executable
    find "$CONFIG_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    # Copy install scripts to a separate location
    mkdir -p "$HOME/.local/bin"
    cp "$SCRIPT_DIR/scripts/install/"*.sh "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/"*.sh 2>/dev/null || true
}

# Configure services
configure_services() {
    log "Configuring system services..."
    
    # Enable essential services
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth
    
    # Configure fish as default shell
    if command -v fish &> /dev/null; then
        if [[ "$SHELL" != *"fish"* ]]; then
            read -p "Set fish as default shell? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                chsh -s $(which fish)
                success "Fish shell configured as default"
            fi
        fi
    fi
    
    success "Services configured"
}

# Set up themes and appearance
setup_themes() {
    log "Setting up themes and appearance..."
    
    # Set GTK theme
    mkdir -p "$CONFIG_DIR/gtk-3.0"
    cat > "$CONFIG_DIR/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrains Mono 11
gtk-cursor-theme-name=catppuccin-mocha-blue-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
EOF

    # Set cursor theme
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=catppuccin-mocha-blue-cursors
EOF

    success "Themes configured"
}

# Final setup and cleanup
final_setup() {
    log "Performing final setup..."
    
    # Add user to necessary groups
    sudo usermod -aG video,audio,input,wheel "$USER"
    
    # Update font cache
    fc-cache -fv
    
    # Update desktop database
    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    
    # Create desktop entries for custom scripts
    create_desktop_entries
    
    success "Final setup completed"
}

create_desktop_entries() {
    log "Creating desktop entries..."
    
    # Gaming mode desktop entry
    if [[ "$INSTALL_GAMING" == true ]]; then
        cat > "$HOME/.local/share/applications/gaming-mode.desktop" << 'EOF'
[Desktop Entry]
Name=Gaming Mode
Comment=Toggle gaming optimizations
Exec=/home/$USER/.config/scripts/gaming-mode.sh
Icon=applications-games
Terminal=false
Type=Application
Categories=Game;
EOF
    fi
    
    # VPN manager desktop entry
    if [[ "$INSTALL_VPN" == true ]]; then
        cat > "$HOME/.local/share/applications/vpn-manager.desktop" << 'EOF'
[Desktop Entry]
Name=VPN Manager
Comment=Manage VPN connections
Exec=/home/$USER/.config/scripts/vpn-manager.sh
Icon=network-vpn
Terminal=false
Type=Application
Categories=Network;
EOF
    fi
    
    # Waydroid setup desktop entry
    if [[ "$INSTALL_WAYDROID" == true ]]; then
        cat > "$HOME/.local/share/applications/waydroid-setup.desktop" << 'EOF'
[Desktop Entry]
Name=Waydroid Setup
Comment=Setup and manage Waydroid
Exec=kitty -e /home/$USER/.local/bin/waydroid-setup.sh
Icon=android
Terminal=true
Type=Application
Categories=System;
EOF
    fi
}

# Post-installation information
show_post_install_info() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Installation Complete!                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. ${YELLOW}Reboot your system${NC} to ensure all changes take effect"
    echo -e "  2. Log into Hyprland from your display manager"
    echo -e "  3. Check the ${BLUE}docs/${NC} folder for detailed documentation:"
    echo -e "     • ${CYAN}KEYBINDINGS.md${NC} - All keyboard shortcuts"
    echo -e "     • ${CYAN}CUSTOMIZATION.md${NC} - How to customize your setup"
    echo -e "     • ${CYAN}TROUBLESHOOTING.md${NC} - Common issues and solutions"
    
    if [[ "$INSTALL_VPN" == true ]]; then
        echo -e "     • ${CYAN}VPN-SETUP.md${NC} - VPN configuration guide"
    fi
    
    echo
    echo -e "${CYAN}Key bindings:${NC}"
    echo -e "  • ${YELLOW}Super + Q${NC} - Terminal (Kitty)"
    echo -e "  • ${YELLOW}Super + R${NC} - Application launcher (Rofi)"
    echo -e "  • ${YELLOW}Super + E${NC} - File manager (Thunar)"
    echo -e "  • ${YELLOW}Super + G${NC} - Toggle gaps"
    echo -e "  • ${YELLOW}Super + L${NC} - Toggle layout"
    echo -e "  • ${YELLOW}Super + T${NC} - Toggle theme"
    echo -e "  • ${YELLOW}Print${NC} - Screenshot"
    
    if [[ "$INSTALL_GAMING" == true ]]; then
        echo -e "  • ${YELLOW}Super + Shift + G${NC} - Gaming mode"
    fi
    
    echo
    echo -e "${CYAN}Useful scripts:${NC}"
    echo -e "  • ${GREEN}~/.config/scripts/system-monitor.sh${NC} - System monitoring"
    echo -e "  • ${GREEN}~/.config/scripts/toggle-theme.sh${NC} - Theme switcher"
    
    if [[ "$INSTALL_VPN" == true ]]; then
        echo -e "  • ${GREEN}~/.config/scripts/vpn-manager.sh${NC} - VPN management"
    fi
    
    if [[ "$INSTALL_GAMING" == true ]]; then
        echo -e "  • ${GREEN}~/.config/scripts/gaming-mode.sh${NC} - Gaming optimizations"
    fi
    
    if [[ "$INSTALL_WAYDROID" == true ]]; then
        echo -e "  • ${GREEN}~/.local/bin/waydroid-setup.sh${NC} - Waydroid setup"
        echo
        echo -e "${YELLOW}Note:${NC} Run 'waydroid-setup.sh' to complete Waydroid installation"
    fi
    
    if [[ "$INSTALL_NVIDIA" == true ]]; then
        echo
        echo -e "${YELLOW}NVIDIA users:${NC} A reboot is required for driver changes to take effect"
    fi
    
    echo
    echo -e "${GREEN}Enjoy your new Hyprland setup! 🚀${NC}"
    echo
}

# Main installation function
main() {
    # Clear screen and show banner
    clear
    show_banner
    
    # Check prerequisites
    check_arch
    
    # System detection
    detect_system
    
    # Get user preferences
    ask_user_preferences
    
    # Start installation
    log "Starting Hyprland dotfiles installation..."
    
    # Install packages
    install_yay
    install_base_packages
    install_aur_packages
    
    # GPU-specific installations
    install_nvidia_packages
    
    # Optional installations
    install_gaming_packages
    install_vpn_packages
    install_waydroid
    
    # Setup configurations
    setup_dotfiles
    configure_services
    setup_themes
    final_setup
    
    # Show completion info
    show_post_install_info
    
    success "Installation completed successfully!"
    
    # Ask for reboot
    echo
    read -p "Reboot now to complete the installation? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Rebooting system..."
        sudo reboot
    else
        warning "Please reboot manually to complete the installation"
    fi
}

# Error handling
trap 'error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"
