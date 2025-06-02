#!/bin/bash

# Gaming Mode Script for Hyprland
# Optimizes system for gaming performance

CONFIG_DIR="$HOME/.config"
GAMING_STATE_FILE="$CONFIG_DIR/.gaming_mode"

# Colors
RED="#ff5555"
GREEN="#50fa7b"
YELLOW="#f1fa8c"
BLUE="#8be9fd"

# Check if gaming mode is active
is_gaming_mode_active() {
    [ -f "$GAMING_STATE_FILE" ]
}

# Enable gaming mode
enable_gaming_mode() {
    echo "Enabling gaming mode..."
    
    # Save current state
    echo "$(date)" > "$GAMING_STATE_FILE"
    
    # Disable compositor effects for better performance
    hyprctl keyword decoration:blur:enabled false
    hyprctl keyword decoration:drop_shadow false
    hyprctl keyword animations:enabled false
    
    # Set performance governor
    if command -v cpupower &> /dev/null; then
        sudo cpupower frequency-set -g performance 2>/dev/null || true
    fi
    
    # Disable gaps for maximum screen space
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    
    # Kill unnecessary processes
    pkill -f "system-monitor.sh" 2>/dev/null || true
    
    # Set high priority for gaming processes
    echo 'kernel.sched_rt_runtime_us = -1' | sudo tee /proc/sys/kernel/sched_rt_runtime_us >/dev/null 2>&1 || true
    
    # Disable swap for better performance (if enough RAM)
    local total_ram=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_ram" -gt 8192 ]; then
        sudo swapoff -a 2>/dev/null || true
    fi
    
    # Start GameMode if available
    if command -v gamemoded &> /dev/null; then
        systemctl --user start gamemoded 2>/dev/null || true
    fi
    
    # Update waybar to show gaming mode
    pkill -SIGUSR1 waybar 2>/dev/null || true
    
    notify-send "Gaming Mode" "Gaming optimizations enabled" -t 3000 -u normal
    echo "Gaming mode enabled"
}

# Disable gaming mode
disable_gaming_mode() {
    echo "Disabling gaming mode..."
    
    # Remove state file
    rm -f "$GAMING_STATE_FILE"
    
    # Restore visual effects
    hyprctl keyword decoration:blur:enabled true
    hyprctl keyword decoration:drop_shadow true
    hyprctl keyword animations:enabled true
    
    # Restore gaps
    hyprctl keyword general:gaps_in 5
    hyprctl keyword general:gaps_out 10
    
    # Restore CPU governor
    if command -v cpupower &> /dev/null; then
        sudo cpupower frequency-set -g schedutil 2>/dev/null || true
    fi
    
    # Re-enable swap
    sudo swapon -a 2>/dev/null || true
    
    # Restart system monitor
    "$CONFIG_DIR/scripts/system-monitor.sh" monitor &
    
    # Stop GameMode
    if command -v gamemoded &> /dev/null; then
        systemctl --user stop gamemoded 2>/dev/null || true
    fi
    
    # Update waybar
    pkill -SIGUSR1 waybar 2>/dev/null || true
    
    notify-send "Gaming Mode" "Gaming optimizations disabled" -t 3000 -u normal
    echo "Gaming mode disabled"
}

# Toggle gaming mode
toggle_gaming_mode() {
    if is_gaming_mode_active; then
        disable_gaming_mode
    else
        enable_gaming_mode
    fi
}

# Show gaming status
show_gaming_status() {
    if is_gaming_mode_active; then
        local enabled_time=$(cat "$GAMING_STATE_FILE")
        echo "Gaming mode: ACTIVE (since $enabled_time)"
        
        # Show current optimizations
        echo ""
        echo "Active optimizations:"
        echo "  ✓ Visual effects disabled"
        echo "  ✓ Gaps disabled"
        echo "  ✓ Performance CPU governor"
        
        if command -v gamemoded &> /dev/null; then
            if systemctl --user is-active gamemoded >/dev/null 2>&1; then
                echo "  ✓ GameMode daemon active"
            fi
        fi
        
        # Check if swap is disabled
        if [ "$(swapon --show | wc -l)" -eq 0 ]; then
            echo "  ✓ Swap disabled"
        fi
    else
        echo "Gaming mode: INACTIVE"
    fi
}

# Launch game with optimizations
launch_game() {
    local game_command="$1"
    
    if [ -z "$game_command" ]; then
        echo "Error: Game command required"
        return 1
    fi
    
    echo "Launching game with optimizations: $game_command"
    
    # Enable gaming mode if not active
    if ! is_gaming_mode_active; then
        enable_gaming_mode
    fi
    
    # Launch game with GameMode if available
    if command -v gamemoderun &> /dev/null; then
        gamemoderun $game_command
    else
        $game_command
    fi
}

# Show gaming menu
show_gaming_menu() {
    local menu_options=""
    
    if is_gaming_mode_active; then
        menu_options="🔴 Disable Gaming Mode\n📊 Show Status\n🎮 Launch Steam\n🎯 Launch Lutris"
    else
        menu_options="🟢 Enable Gaming Mode\n📊 Show Status\n🎮 Launch Steam\n🎯 Launch Lutris"
    fi
    
    menu_options="${menu_options}\n⚙️ Gaming Settings\n📈 Performance Monitor"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "Gaming Mode")
    
    case "$selection" in
        "🟢 Enable Gaming Mode")
            enable_gaming_mode
            ;;
        "🔴 Disable Gaming Mode")
            disable_gaming_mode
            ;;
        "📊 Show Status")
            show_gaming_status | rofi -dmenu -p "Gaming Status"
            ;;
        "🎮 Launch Steam")
            launch_game "steam"
            ;;
        "🎯 Launch Lutris")
            launch_game "lutris"
            ;;
        "⚙️ Gaming Settings")
            show_gaming_settings
            ;;
        "📈 Performance Monitor")
            kitty -e htop &
            ;;
    esac
}

# Show gaming settings
show_gaming_settings() {
    local settings_options="CPU Governor Settings\nGPU Performance Mode\nGameMode Configuration\nSystem Tweaks"
    
    local selection=$(echo -e "$settings_options" | rofi -dmenu -p "Gaming Settings")
    
    case "$selection" in
        "CPU Governor Settings")
            show_cpu_governor_menu
            ;;
        "GPU Performance Mode")
            configure_gpu_performance
            ;;
        "GameMode Configuration")
            edit_gamemode_config
            ;;
        "System Tweaks")
            show_system_tweaks
            ;;
    esac
}

# CPU Governor menu
show_cpu_governor_menu() {
    local governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "performance schedutil powersave")
    local current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    
    local selection=$(echo "$governors" | tr ' ' '\n' | rofi -dmenu -p "Select CPU Governor (current: $current_governor)")
    
    if [ -n "$selection" ] && command -v cpupower &> /dev/null; then
        sudo cpupower frequency-set -g "$selection"
        notify-send "CPU Governor" "Set to $selection" -t 3000
    fi
}

# Configure GPU performance
configure_gpu_performance() {
    # NVIDIA GPU settings
    if command -v nvidia-settings &> /dev/null; then
        local nvidia_options="Max Performance Mode\nAdaptive Mode\nOptimal Power Mode"
        local selection=$(echo -e "$nvidia_options" | rofi -dmenu -p "NVIDIA Performance Mode")
        
        case "$selection" in
            "Max Performance Mode")
                nvidia-settings -a '[gpu:0]/GPUPowerMizerMode=1' >/dev/null 2>&1
                notify-send "GPU Performance" "NVIDIA set to max performance" -t 3000
                ;;
            "Adaptive Mode")
                nvidia-settings -a '[gpu:0]/GPUPowerMizerMode=0' >/dev/null 2>&1
                notify-send "GPU Performance" "NVIDIA set to adaptive mode" -t 3000
                ;;
            "Optimal Power Mode")
                nvidia-settings -a '[gpu:0]/GPUPowerMizerMode=2' >/dev/null 2>&1
                notify-send "GPU Performance" "NVIDIA set to optimal power" -t 3000
                ;;
        esac
    else
        notify-send "GPU Performance" "No supported GPU configuration found" -t 3000
    fi
}

# Edit GameMode configuration
edit_gamemode_config() {
    local gamemode_config="$HOME/.config/gamemode.ini"
    
    if [ ! -f "$gamemode_config" ]; then
        # Create default GameMode config
        mkdir -p "$(dirname "$gamemode_config")"
        cat > "$gamemode_config" << 'EOF'
[general]
renice=10
ioprio=1
inhibit_screensaver=1

[filter]
whitelist=
blacklist=

[gpu]
apply_gpu_optimisations=accept-responsibility
nv_powermizer_mode=1
amd_performance_level=high

[custom]
start=notify-send "GameMode" "Optimizations activated"
end=notify-send "GameMode" "Optimizations deactivated"
EOF
    fi
    
    if command -v code &> /dev/null; then
        code "$gamemode_config"
    elif command -v nvim &> /dev/null; then
        kitty -e nvim "$gamemode_config" &
    else
        kitty -e vim "$gamemode_config" &
    fi
}

# Show system tweaks
show_system_tweaks() {
    local tweaks_info="System Tweaks for Gaming:\n\n"
    tweaks_info+="• Kernel parameters for low latency\n"
    tweaks_info+="• I/O scheduler optimization\n"
    tweaks_info+="• Memory management tweaks\n"
    tweaks_info+="• Network optimization\n\n"
    tweaks_info+="These tweaks require system restart to take effect."
    
    echo -e "$tweaks_info" | rofi -dmenu -p "System Tweaks Info"
}

# Get gaming status for waybar
get_gaming_status_json() {
    if is_gaming_mode_active; then
        echo "{\"text\": \"🎮\", \"class\": \"gaming-active\", \"tooltip\": \"Gaming mode active\"}"
    else
        echo "{\"text\": \"\", \"class\": \"gaming-inactive\", \"tooltip\": \"Gaming mode inactive\"}"
    fi
}

# Main function
case "${1:-toggle}" in
    "toggle")
        toggle_gaming_mode
        ;;
    "enable"|"on")
        enable_gaming_mode
        ;;
    "disable"|"off")
        disable_gaming_mode
        ;;
    "status")
        show_gaming_status
        ;;
    "status-json")
        get_gaming_status_json
        ;;
    "menu")
        show_gaming_menu
        ;;
    "launch")
        launch_game "$2"
        ;;
    *)
        echo "Usage: $0 {toggle|enable|disable|status|status-json|menu|launch}"
        echo ""
        echo "Commands:"
        echo "  toggle       - Toggle gaming mode on/off"
        echo "  enable       - Enable gaming optimizations"
        echo "  disable      - Disable gaming optimizations"
        echo "  status       - Show current gaming mode status"
        echo "  status-json  - Get status in JSON format (for waybar)"
        echo "  menu         - Show interactive gaming menu"
        echo "  launch CMD   - Launch game with optimizations"
        exit 1
        ;;
esac
