#!/bin/bash

# Waydroid Setup and Management Script
# Location: ~/.local/bin/waydroid-setup.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Waydroid is installed
check_waydroid() {
    if ! command -v waydroid &> /dev/null; then
        error "Waydroid is not installed. Please install it first."
    fi
}

# Initialize Waydroid
init_waydroid() {
    log "Initializing Waydroid..."
    
    if [ ! -d "/var/lib/waydroid" ]; then
        sudo waydroid init
    else
        log "Waydroid already initialized"
    fi
}

# Start Waydroid session
start_waydroid() {
    log "Starting Waydroid session..."
    
    # Start container
    sudo systemctl start waydroid-container.service
    
    # Start session
    waydroid session start &
    
    sleep 5
    
    # Show first time setup
    waydroid show-full-ui
}

# Install Google Apps
install_gapps() {
    log "Installing Google Apps..."
    
    # Download and install GApps
    cd /tmp
    
    # Download script for GApps installation
    if ! [ -f "waydroid_script.py" ]; then
        wget https://raw.githubusercontent.com/casualsnek/waydroid_script/main/waydroid_extras.py -O waydroid_script.py
    fi
    
    python3 waydroid_script.py -g
    
    log "Google Apps installation completed. Restart Waydroid to take effect."
}

# Install additional apps
install_apps() {
    log "Installing additional Android apps..."
    
    # F-Droid
    waydroid app install https://f-droid.org/F-Droid.apk
    
    log "F-Droid installed. You can install more apps from there."
}

# Configure Waydroid
configure_waydroid() {
    log "Configuring Waydroid..."
    
    # Set properties
    waydroid prop set persist.waydroid.multi_windows true
    waydroid prop set persist.waydroid.cursor_on_subsurface true
    
    # Enable hardware acceleration if possible
    if lspci | grep -i nvidia > /dev/null; then
        warning "NVIDIA GPU detected. Hardware acceleration may not work properly."
    else
        waydroid prop set persist.waydroid.hardware_acceleration true
    fi
    
    log "Waydroid configuration completed"
}

# Show Waydroid status
show_status() {
    echo -e "${BLUE}=== Waydroid Status ===${NC}"
    
    # Check container status
    if systemctl is-active --quiet waydroid-container.service; then
        echo -e "Container: ${GREEN}Running${NC}"
    else
        echo -e "Container: ${RED}Stopped${NC}"
    fi
    
    # Check session status
    if pgrep -f "waydroid session" > /dev/null; then
        echo -e "Session: ${GREEN}Active${NC}"
    else
        echo -e "Session: ${RED}Inactive${NC}"
    fi
    
    # Show properties
    echo -e "\n${BLUE}Properties:${NC}"
    waydroid prop get persist.waydroid.multi_windows 2>/dev/null || echo "Multi-windows: Not set"
    waydroid prop get persist.waydroid.hardware_acceleration 2>/dev/null || echo "Hardware acceleration: Not set"
}

# Stop Waydroid
stop_waydroid() {
    log "Stopping Waydroid..."
    
    # Stop session
    waydroid session stop 2>/dev/null || true
    
    # Stop container
    sudo systemctl stop waydroid-container.service
    
    log "Waydroid stopped"
}

# Restart Waydroid
restart_waydroid() {
    log "Restarting Waydroid..."
    stop_waydroid
    sleep 2
    start_waydroid
}

# Uninstall Waydroid
uninstall_waydroid() {
    warning "This will completely remove Waydroid and all data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Uninstalling Waydroid..."
        
        # Stop services
        stop_waydroid
        
        # Remove data
        sudo rm -rf /var/lib/waydroid
        sudo rm -rf ~/.local/share/waydroid
        
        log "Waydroid data removed. Uninstall the package manually if needed."
    fi
}

# Show menu
show_menu() {
    echo -e "${BLUE}=== Waydroid Setup & Management ===${NC}"
    echo "1. Initialize Waydroid"
    echo "2. Start Waydroid"
    echo "3. Stop Waydroid"
    echo "4. Restart Waydroid"
    echo "5. Install Google Apps"
    echo "6. Install Additional Apps"
    echo "7. Configure Waydroid"
    echo "8. Show Status"
    echo "9. Uninstall Waydroid"
    echo "0. Exit"
    echo
    read -p "Select option: " choice
    
    case $choice in
        1) init_waydroid ;;
        2) start_waydroid ;;
        3) stop_waydroid ;;
        4) restart_waydroid ;;
        5) install_gapps ;;
        6) install_apps ;;
        7) configure_waydroid ;;
        8) show_status ;;
        9) uninstall_waydroid ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
}

# Main function
main() {
    check_waydroid
    
    if [ $# -eq 0 ]; then
        while true; do
            show_menu
            echo
        done
    else
        case "$1" in
            "init") init_waydroid ;;
            "start") start_waydroid ;;
            "stop") stop_waydroid ;;
            "restart") restart_waydroid ;;
            "gapps") install_gapps ;;
            "apps") install_apps ;;
            "config") configure_waydroid ;;
            "status") show_status ;;
            "uninstall") uninstall_waydroid ;;
            *) 
                echo "Usage: $0 {init|start|stop|restart|gapps|apps|config|status|uninstall}"
                exit 1
                ;;
        esac
    fi
}

main "$@"

