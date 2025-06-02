#!/bin/bash

# Advanced Power Manager
# Provides battery monitoring, power profiles, and system power control

# Configuration
CONFIG_DIR="$HOME/.config/power-manager"
PROFILES_DIR="$CONFIG_DIR/profiles"
LOGS_DIR="$CONFIG_DIR/logs"

# Create directories
mkdir -p "$PROFILES_DIR" "$LOGS_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons
ICON_BATTERY_FULL="🔋"
ICON_BATTERY_GOOD="🔋"
ICON_BATTERY_LOW="🪫"
ICON_BATTERY_CRITICAL="⚠️"
ICON_CHARGING="⚡"
ICON_AC_POWER="🔌"
ICON_SLEEP="😴"
ICON_HIBERNATE="💤"

# Battery thresholds
BATTERY_LOW_THRESHOLD=20
BATTERY_CRITICAL_THRESHOLD=10

# Logging
log() { echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOGS_DIR/power.log"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOGS_DIR/power.log"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOGS_DIR/power.log"; }

# Get battery information
get_battery_info() {
    local battery_path="/sys/class/power_supply/BAT0"
    
    if [ ! -d "$battery_path" ]; then
        battery_path="/sys/class/power_supply/BAT1"
    fi
    
    if [ ! -d "$battery_path" ]; then
        echo "No battery found"
        return 1
    fi
    
    local capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "0")
    local status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
    local energy_now=$(cat "$battery_path/energy_now" 2>/dev/null || echo "0")
    local energy_full=$(cat "$battery_path/energy_full" 2>/dev/null || echo "1")
    local power_now=$(cat "$battery_path/power_now" 2>/dev/null || echo "0")
    
    echo "capacity:$capacity"
    echo "status:$status"
    echo "energy_now:$energy_now"
    echo "energy_full:$energy_full"
    echo "power_now:$power_now"
}

# Get battery percentage
get_battery_percentage() {
    local battery_info=$(get_battery_info)
    echo "$battery_info" | grep "capacity:" | cut -d':' -f2
}

# Get battery status
get_battery_status() {
    local battery_info=$(get_battery_info)
    echo "$battery_info" | grep "status:" | cut -d':' -f2
}

# Calculate time remaining
get_time_remaining() {
    local battery_info=$(get_battery_info)
    local energy_now=$(echo "$battery_info" | grep "energy_now:" | cut -d':' -f2)
    local power_now=$(echo "$battery_info" | grep "power_now:" | cut -d':' -f2)
    local status=$(echo "$battery_info" | grep "status:" | cut -d':' -f2)
    
    if [ "$power_now" -eq 0 ]; then
        echo "Unknown"
        return
    fi
    
    local hours_remaining=$((energy_now / power_now))
    local minutes_remaining=$(((energy_now * 60 / power_now) % 60))
    
    if [ "$status" = "Charging" ]; then
        local energy_full=$(echo "$battery_info" | grep "energy_full:" | cut -d':' -f2)
        local energy_to_full=$((energy_full - energy_now))
        hours_remaining=$((energy_to_full / power_now))
        minutes_remaining=$(((energy_to_full * 60 / power_now) % 60))
    fi
    
    printf "%02d:%02d" "$hours_remaining" "$minutes_remaining"
}

# Get power status for status bar
get_power_status() {
    local percentage=$(get_battery_percentage)
    local status=$(get_battery_status)
    local icon="$ICON_BATTERY_FULL"
    
    if [ "$status" = "Charging" ]; then
        icon="$ICON_CHARGING"
    elif [ "$percentage" -le "$BATTERY_CRITICAL_THRESHOLD" ]; then
        icon="$ICON_BATTERY_CRITICAL"
    elif [ "$percentage" -le "$BATTERY_LOW_THRESHOLD" ]; then
        icon="$ICON_BATTERY_LOW"
    elif [ "$percentage" -le 50 ]; then
        icon="$ICON_BATTERY_GOOD"
    fi
    
    echo "$icon ${percentage}%"
}

# Check AC adapter status
is_ac_connected() {
    local ac_path="/sys/class/power_supply/ADP1"
    
    if [ ! -d "$ac_path" ]; then
        ac_path="/sys/class/power_supply/AC"
    fi
    
    if [ ! -d "$ac_path" ]; then
        ac_path="/sys/class/power_supply/ACAD"
    fi
    
    if [ -d "$ac_path" ]; then
        local online=$(cat "$ac_path/online" 2>/dev/null || echo "0")
        [ "$online" = "1" ]
    else
        return 1
    fi
}

# Set CPU governor
set_cpu_governor() {
    local governor="$1"
    
    if [ -z "$governor" ]; then
        local available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)
        governor=$(echo "$available_governors" | tr ' ' '\n' | rofi -dmenu -p "Select CPU governor")
        [ -z "$governor" ] && return 1
    fi
    
    log "Setting CPU governor to: $governor"
    
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -w "$cpu" ]; then
            echo "$governor" | sudo tee "$cpu" > /dev/null
        fi
    done
    
    notify-send "Power Manager" "CPU governor set to $governor" -i preferences-system -t 2000
}

# Get current CPU governor
get_cpu_governor() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Unknown"
}

# Set screen brightness
set_brightness() {
    local brightness="$1"
    
    if [ -z "$brightness" ]; then
        local current_brightness=$(get_brightness)
        brightness=$(seq 0 5 100 | rofi -dmenu -p "Set brightness %" -selected-row $((current_brightness / 5)))
        [ -z "$brightness" ] && return 1
    fi
    
    # Clamp brightness between 1 and 100
    if [ "$brightness" -gt 100 ]; then
        brightness=100
    elif [ "$brightness" -lt 1 ]; then
        brightness=1
    fi
    
    if command -v brightnessctl &> /dev/null; then
        brightnessctl set "${brightness}%"
    elif command -v xbacklight &> /dev/null; then
        xbacklight -set "$brightness"
    else
        # Direct control via sysfs
        local backlight_path="/sys/class/backlight"
        local backlight_device=$(ls "$backlight_path" 2>/dev/null | head -1)
        
        if [ -n "$backlight_device" ]; then
            local max_brightness=$(cat "$backlight_path/$backlight_device/max_brightness")
            local target_brightness=$((brightness * max_brightness / 100))
            echo "$target_brightness" | sudo tee "$backlight_path/$backlight_device/brightness" > /dev/null
        fi
    fi
    
    notify-send "Brightness" "${brightness}%" -i display-brightness -t 1500 -h int:value:"$brightness"
}

# Get current brightness
get_brightness() {
    if command -v brightnessctl &> /dev/null; then
        brightnessctl get | awk '{print int($1)}'
    elif command -v xbacklight &> /dev/null; then
        xbacklight -get | cut -d'.' -f1
    else
        local backlight_path="/sys/class/backlight"
        local backlight_device=$(ls "$backlight_path" 2>/dev/null | head -1)
        
        if [ -n "$backlight_device" ]; then
            local current=$(cat "$backlight_path/$backlight_device/brightness")
            local max=$(cat "$backlight_path/$backlight_device/max_brightness")
            echo $((current * 100 / max))
        else
            echo "50"
        fi
    fi
}

# Increase brightness
brightness_up() {
    local step="${1:-10}"
    local current=$(get_brightness)
    local new_brightness=$((current + step))
    set_brightness "$new_brightness"
}

# Decrease brightness
brightness_down() {
    local step="${1:-10}"
    local current=$(get_brightness)
    local new_brightness=$((current - step))
    set_brightness "$new_brightness"
}

# Power profiles
apply_power_profile() {
    local profile="$1"
    
    case "$profile" in
        "performance")
            log "Applying performance profile"
            set_cpu_governor "performance"
            # Disable USB autosuspend
            echo 'on' | sudo tee /sys/bus/usb/devices/*/power/control > /dev/null 2>&1
            # Set higher brightness
            set_brightness 80
            ;;
        "balanced")
            log "Applying balanced profile"
            set_cpu_governor "ondemand"
            # Default USB power settings
            echo 'auto' | sudo tee /sys/bus/usb/devices/*/power/control > /dev/null 2>&1
            # Medium brightness
            set_brightness 60
            ;;
        "powersave")
            log "Applying power save profile"
            set_cpu_governor "powersave"
            # Enable aggressive power saving
            echo 'auto' | sudo tee /sys/bus/usb/devices/*/power/control > /dev/null 2>&1
            echo 'auto' | sudo tee /sys/bus/pci/devices/*/power/control > /dev/null 2>&1
            # Lower brightness
            set_brightness 30
            ;;
        *)
            error "Unknown power profile: $profile"
            return 1
            ;;
    esac
    
    notify-send "Power Manager" "Applied $profile profile" -i preferences-system -t 2000
}

# Auto power profile based on AC status
auto_power_profile() {
    if is_ac_connected; then
        apply_power_profile "balanced"
    else
        apply_power_profile "powersave"
    fi
}

# Suspend system
suspend_system() {
    log "Suspending system"
    notify-send "Power Manager" "Suspending system..." -i system-suspend -t 2000
    sleep 2
    systemctl suspend
}

# Hibernate system
hibernate_system() {
    log "Hibernating system"
    notify-send "Power Manager" "Hibernating system..." -i system-hibernate -t 2000
    sleep 2
    systemctl hibernate
}

# Shutdown system
shutdown_system() {
    local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Shutdown system?")
    
    if [ "$confirm" = "Yes" ]; then
        log "Shutting down system"
        notify-send "Power Manager" "Shutting down..." -i system-shutdown -t 2000
        sleep 2
        systemctl poweroff
    fi
}

# Reboot system
reboot_system() {
    local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Reboot system?")
    
    if [ "$confirm" = "Yes" ]; then
        log "Rebooting system"
        notify-send "Power Manager" "Rebooting..." -i system-reboot -t 2000
        sleep 2
        systemctl reboot
    fi
}

# Battery monitoring daemon
battery_monitor() {
    local last_percentage=100
    local last_status="Unknown"
    local low_battery_warned=false
    local critical_battery_warned=false
    
    log "Starting battery monitor daemon"
    
    while true; do
        local current_percentage=$(get_battery_percentage)
        local current_status=$(get_battery_status)
        
        # Check for status changes
        if [ "$current_status" != "$last_status" ]; then
            case "$current_status" in
                "Charging")
                    notify-send "Power Manager" "Charging started" -i battery-charging -t 3000
                    low_battery_warned=false
                    critical_battery_warned=false
                    ;;
                "Discharging")
                    notify-send "Power Manager" "Running on battery" -i battery-discharging -t 3000
                    ;;
                "Full")
                    notify-send "Power Manager" "Battery fully charged" -i battery-full -t 3000
                    ;;
            esac
            last_status="$current_status"
        fi
        
        # Check battery levels
        if [ "$current_status" = "Discharging" ]; then
            if [ "$current_percentage" -le "$BATTERY_CRITICAL_THRESHOLD" ] && [ "$critical_battery_warned" = false ]; then
                notify-send "Critical Battery" "Battery at ${current_percentage}%! System will hibernate soon." -u critical -i battery-caution -t 10000
                critical_battery_warned=true
                
                # Auto-hibernate at 5%
                if [ "$current_percentage" -le 5 ]; then
                    log "Critical battery level reached, hibernating system"
                    hibernate_system
                fi
                
            elif [ "$current_percentage" -le "$BATTERY_LOW_THRESHOLD" ] && [ "$low_battery_warned" = false ]; then
                notify-send "Low Battery" "Battery at ${current_percentage}%" -u normal -i battery-low -t 5000
                low_battery_warned=true
            fi
        fi
        
        last_percentage="$current_percentage"
        sleep 30
    done
}

# Save power profile
save_power_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        profile_name=$(rofi -dmenu -p "Profile name")
        [ -z "$profile_name" ] && return 1
    fi
    
    local profile_file="$PROFILES_DIR/$profile_name.json"
    
    # Get current power state
    local cpu_governor=$(get_cpu_governor)
    local brightness=$(get_brightness)
    
    # Create profile
    local profile_data=$(jq -n \
        --arg name "$profile_name" \
        --arg cpu_governor "$cpu_governor" \
        --arg brightness "$brightness" \
        --arg created "$(date -Iseconds)" \
        '{
            name: $name,
            created: $created,
            cpu_governor: $cpu_governor,
            brightness: ($brightness | tonumber)
        }')
    
    echo "$profile_data" > "$profile_file"
    log "Power profile saved: $profile_name"
}

# Load power profile
load_power_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        local profiles=$(ls "$PROFILES_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
        profile_name=$(echo "$profiles" | rofi -dmenu -p "Select profile")
        [ -z "$profile_name" ] && return 1
    fi
    
    local profile_file="$PROFILES_DIR/$profile_name.json"
    
    if [ ! -f "$profile_file" ]; then
        error "Profile not found: $profile_name"
        return 1
    fi
    
    log "Loading power profile: $profile_name"
    
    # Read profile data
    local profile_data=$(cat "$profile_file")
    local cpu_governor=$(echo "$profile_data" | jq -r '.cpu_governor')
    local brightness=$(echo "$profile_data" | jq -r '.brightness')
    
    # Apply settings
    if [ "$cpu_governor" != "null" ]; then
        set_cpu_governor "$cpu_governor"
    fi
    
    if [ "$brightness" != "null" ]; then
        set_brightness "$brightness"
    fi
    
    log "Power profile loaded: $profile_name"
}

# Show power information
show_power_info() {
    local battery_info=$(get_battery_info)
    local percentage=$(echo "$battery_info" | grep "capacity:" | cut -d':' -f2)
    local status=$(echo "$battery_info" | grep "status:" | cut -d':' -f2)
    local time_remaining=$(get_time_remaining)
    local cpu_governor=$(get_cpu_governor)
    local brightness=$(get_brightness)
    local ac_status="Disconnected"
    
    if is_ac_connected; then
        ac_status="Connected"
    fi
    
    local info="=== Power Information ===\n"
    info+="Battery: ${percentage}% (${status})\n"
    info+="Time remaining: ${time_remaining}\n"
    info+="AC Adapter: ${ac_status}\n"
    info+="CPU Governor: ${cpu_governor}\n"
    info+="Brightness: ${brightness}%\n\n"
    
    info+="=== Battery Details ===\n"
    info+="$(echo "$battery_info" | sed 's/:/: /')\n"
    
    echo -e "$info" | rofi -dmenu -p "Power Information"
}

# Show brightness menu
show_brightness_menu() {
    local brightness_options="☀️ Set Brightness\n➕ Brightness Up\n➖ Brightness Down\n🌙 Night Mode\n📊 Current: $(get_brightness)%"
    
    local selection=$(echo -e "$brightness_options" | rofi -dmenu -p "Brightness Control")
    
    case "$selection" in
        "☀️ Set Brightness")
            set_brightness
            ;;
        "➕ Brightness Up")
            brightness_up
            ;;
        "➖ Brightness Down")
            brightness_down
            ;;
        "🌙 Night Mode")
            set_brightness 20
            ;;
    esac
}

# Show power profiles menu
show_profiles_menu() {
    local profile_options="⚡ Performance\n⚖️ Balanced\n🔋 Power Save\n🤖 Auto\n💾 Save Profile\n📂 Load Profile"
    
    local selection=$(echo -e "$profile_options" | rofi -dmenu -p "Power Profiles")
    
    case "$selection" in
        "⚡ Performance")
            apply_power_profile "performance"
            ;;
        "⚖️ Balanced")
            apply_power_profile "balanced"
            ;;
        "🔋 Power Save")
            apply_power_profile "powersave"
            ;;
        "🤖 Auto")
            auto_power_profile
            ;;
        "💾 Save Profile")
            save_power_profile
            ;;
        "📂 Load Profile")
            load_power_profile
            ;;
    esac
}

# Show system power menu
show_system_menu() {
    local system_options="😴 Suspend\n💤 Hibernate\n🔄 Reboot\n⚡ Shutdown\n🔒 Lock Screen"
    
    local selection=$(echo -e "$system_options" | rofi -dmenu -p "System Power")
    
    case "$selection" in
        "😴 Suspend")
            suspend_system
            ;;
        "💤 Hibernate")
            hibernate_system
            ;;
        "🔄 Reboot")
            reboot_system
            ;;
        "⚡ Shutdown")
            shutdown_system
            ;;
        "🔒 Lock Screen")
            if command -v i3lock &> /dev/null; then
                i3lock -c 000000
            elif command -v slock &> /dev/null; then
                slock
            else
                warn "No screen locker found"
            fi
            ;;
    esac
}

# Show main menu
show_menu() {
    local menu_options="🔋 Power Information\n☀️ Brightness Control\n⚡ Power Profiles\n😴 System Power\n📊 Battery Monitor\n⚙️ Settings"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "Power Manager")
    
    case "$selection" in
        "🔋 Power Information")
            show_power_info
            ;;
        "☀️ Brightness Control")
            show_brightness_menu
            ;;
        "⚡ Power Profiles")
            show_profiles_menu
            ;;
        "😴 System Power")
            show_system_menu
            ;;
        "📊 Battery Monitor")
            if pgrep -f "battery_monitor" > /dev/null; then
                local action=$(echo -e "Stop Monitor\nView Logs" | rofi -dmenu -p "Battery Monitor Running")
                case "$action" in
                    "Stop Monitor")
                        pkill -f "battery_monitor"
                        log "Battery monitor stopped"
                        ;;
                    "View Logs")
                        tail -50 "$LOGS_DIR/power.log" | rofi -dmenu -p "Power Logs"
                        ;;
                esac
            else
                local action=$(echo -e "Start Monitor\nView Logs" | rofi -dmenu -p "Battery Monitor")
                case "$action" in
                    "Start Monitor")
                        battery_monitor &
                        ;;
                    "View Logs")
                        tail -50 "$LOGS_DIR/power.log" | rofi -dmenu -p "Power Logs"
                        ;;
                esac
            fi
            ;;
        "⚙️ Settings")
            local settings_options="🔧 CPU Governor\n📋 List Profiles\n🗑️ Delete Profile\n📝 Edit Thresholds"
            local setting=$(echo -e "$settings_options" | rofi -dmenu -p "Power Settings")
            
            case "$setting" in
                "🔧 CPU Governor")
                    set_cpu_governor
                    ;;
                "📋 List Profiles")
                    if [ -d "$PROFILES_DIR" ]; then
                        ls "$PROFILES_DIR"/*.json 2>/dev/null | while read -r profile_file; do
                            local profile_name=$(basename "$profile_file" .json)
                            local created=$(jq -r '.created' "$profile_file" 2>/dev/null)
                            local date_str=$(date -d "$created" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "Unknown")
                            echo "$profile_name (created: $date_str)"
                        done | rofi -dmenu -p "Available Profiles"
                    fi
                    ;;
                "🗑️ Delete Profile")
                    local profiles=$(ls "$PROFILES_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
                    local profile_name=$(echo "$profiles" | rofi -dmenu -p "Delete profile")
                    
                    if [ -n "$profile_name" ]; then
                        local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Delete profile '$profile_name'?")
                        
                        if [ "$confirm" = "Yes" ]; then
                            rm -f "$PROFILES_DIR/$profile_name.json"
                            log "Profile deleted: $profile_name"
                        fi
                    fi
                    ;;
                "📝 Edit Thresholds")
                    warn "Edit thresholds in script configuration"
                    ;;
            esac
            ;;
    esac
}

# Main function
main() {
    case "${1:-menu}" in
        "menu") show_menu ;;
        "status") get_power_status ;;
        "info") show_power_info ;;
        "brightness")
            case "$2" in
                "up") brightness_up "$3" ;;
                "down") brightness_down "$3" ;;
                "set") set_brightness "$3" ;;
                "get") get_brightness ;;
                *) show_brightness_menu ;;
            esac
            ;;
        "profile")
            case "$2" in
                "performance"|"balanced"|"powersave") apply_power_profile "$2" ;;
                "auto") auto_power_profile ;;
                "save") save_power_profile "$3" ;;
                "load") load_power_profile "$3" ;;
                *) show_profiles_menu ;;
            esac
            ;;
        "suspend") suspend_system ;;
        "hibernate") hibernate_system ;;
        "shutdown") shutdown_system ;;
        "reboot") reboot_system ;;
        "monitor") battery_monitor ;;
        "governor") set_cpu_governor "$2" ;;
        "battery")
            case "$2" in
                "percentage") get_battery_percentage ;;
                "status") get_battery_status ;;
                "time") get_time_remaining ;;
                *) get_battery_info ;;
            esac
            ;;
        *)
            echo "Usage: $0 {menu|status|info|brightness|profile|suspend|hibernate|shutdown|reboot|monitor|governor|battery}"
            echo ""
            echo "Power Information:"
            echo "  status                - Get power status for status bar"
            echo "  info                  - Show detailed power information"
            echo "  battery percentage    - Get battery percentage"
            echo "  battery status        - Get battery status"
            echo "  battery time          - Get time remaining"
            echo ""
            echo "Brightness Control:"
            echo "  brightness up [step]  - Increase brightness"
            echo "  brightness down [step] - Decrease brightness"
            echo "  brightness set <level> - Set brightness level"
            echo "  brightness get        - Get current brightness"
            echo "  brightness            - Brightness control menu"
            echo ""
            echo "Power Profiles:"
            echo "  profile performance   - Apply performance profile"
            echo "  profile balanced      - Apply balanced profile"
            echo "  profile powersave     - Apply power save profile"
            echo "  profile auto          - Auto profile based on AC"
            echo "  profile save [name]   - Save current profile"
            echo "  profile load [name]   - Load saved profile"
            echo "  profile               - Power profiles menu"
            echo ""
            echo "System Power:"
            echo "  suspend               - Suspend system"
            echo "  hibernate             - Hibernate system"
            echo "  shutdown              - Shutdown system"
            echo "  reboot                - Reboot system"
            echo ""
            echo "Utilities:"
            echo "  monitor               - Start battery monitor daemon"
            echo "  governor [name]       - Set CPU governor"
            echo "  menu                  - Show interactive menu"
            exit 1
            ;;
    esac
}

main "$@"

