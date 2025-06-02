#!/bin/bash

# System Monitor
# Comprehensive system monitoring and alerting

CONFIG_FILE="$HOME/.config/system-monitor.conf"
LOG_FILE="$HOME/.local/share/system-monitor.log"
ALERT_FILE="$HOME/.local/share/system-alerts.log"

# Default thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
TEMP_THRESHOLD=75
LOAD_THRESHOLD=4.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        create_default_config
    fi
}

# Create default configuration
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
# System Monitor Configuration

# Thresholds (percentage)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
TEMP_THRESHOLD=75

# Load average threshold
LOAD_THRESHOLD=4.0

# Monitoring intervals (seconds)
CHECK_INTERVAL=30
ALERT_COOLDOWN=300

# Notification settings
ENABLE_NOTIFICATIONS=true
ENABLE_LOGGING=true
ENABLE_SOUND_ALERTS=false

# Monitored disks (space-separated)
MONITORED_DISKS="/ /home"

# Network interfaces to monitor
MONITORED_INTERFACES="wlan0 eth0"

# Services to monitor
MONITORED_SERVICES="NetworkManager bluetooth"
EOF
}

# Logging functions
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$ENABLE_LOGGING" = "true" ]; then
        echo "[$timestamp] INFO: $message" >> "$LOG_FILE"
    fi
    
    echo -e "${GREEN}[INFO]${NC} $message"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$ENABLE_LOGGING" = "true" ]; then
        echo "[$timestamp] WARNING: $message" >> "$LOG_FILE"
        echo "[$timestamp] WARNING: $message" >> "$ALERT_FILE"
    fi
    
    echo -e "${YELLOW}[WARNING]${NC} $message"
    
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        notify-send "System Warning" "$message" -u normal -t 5000
    fi
}

log_critical() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$ENABLE_LOGGING" = "true" ]; then
        echo "[$timestamp] CRITICAL: $message" >> "$LOG_FILE"
        echo "[$timestamp] CRITICAL: $message" >> "$ALERT_FILE"
    fi
    
    echo -e "${RED}[CRITICAL]${NC} $message"
    
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        notify-send "System Critical" "$message" -u critical -t 10000
    fi
    
    if [ "$ENABLE_SOUND_ALERTS" = "true" ]; then
        paplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null &
    fi
}

# Get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
}

# Get memory usage
get_memory_usage() {
    free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100.0}'
}

# Get disk usage
get_disk_usage() {
    local mount_point="$1"
    df -h "$mount_point" 2>/dev/null | awk 'NR==2{print $5}' | cut -d'%' -f1
}

# Get CPU temperature
get_cpu_temp() {
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo $((temp / 1000))
    elif command -v sensors &> /dev/null; then
        sensors | grep -E "Core 0|Package id 0" | head -1 | awk '{print $3}' | cut -d'+' -f2 | cut -d'°' -f1
    else
        echo "0"
    fi
}

# Get load average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1
}

# Get network usage
get_network_usage() {
    local interface="$1"
    
    if [ ! -d "/sys/class/net/$interface" ]; then
        echo "0 0"
        return
    fi
    
    local rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
    local tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
    
    echo "$rx_bytes $tx_bytes"
}

# Check service status
check_service() {
    local service="$1"
    systemctl is-active "$service" &>/dev/null
}

# Get GPU usage (NVIDIA)
get_gpu_usage() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1
    else
        echo "0"
    fi
}

# Get GPU temperature (NVIDIA)
get_gpu_temp() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1
    else
        echo "0"
    fi
}

# Monitor CPU
monitor_cpu() {
    local cpu_usage=$(get_cpu_usage)
    
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        log_warning "High CPU usage: ${cpu_usage}%"
        return 1
    fi
    
    return 0
}

# Monitor memory
monitor_memory() {
    local memory_usage=$(get_memory_usage)
    
    if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) )); then
        log_warning "High memory usage: ${memory_usage}%"
        return 1
    fi
    
    return 0
}

# Monitor disk space
monitor_disk() {
    local issues=0
    
    for disk in $MONITORED_DISKS; do
        local usage=$(get_disk_usage "$disk")
        
        if [ -n "$usage" ] && [ "$usage" -gt "$DISK_THRESHOLD" ]; then
            log_warning "High disk usage on $disk: ${usage}%"
            ((issues++))
        fi
    done
    
    return $issues
}

# Monitor temperature
monitor_temperature() {
    local cpu_temp=$(get_cpu_temp)
    local gpu_temp=$(get_gpu_temp)
    
    local issues=0
    
    if [ "$cpu_temp" -gt "$TEMP_THRESHOLD" ]; then
        log_warning "High CPU temperature: ${cpu_temp}°C"
        ((issues++))
    fi
    
    if [ "$gpu_temp" -gt 0 ] && [ "$gpu_temp" -gt "$TEMP_THRESHOLD" ]; then
        log_warning "High GPU temperature: ${gpu_temp}°C"
        ((issues++))
    fi
    
    return $issues
}

# Monitor load average
monitor_load() {
    local load=$(get_load_average)
    
    if (( $(echo "$load > $LOAD_THRESHOLD" | bc -l) )); then
        log_warning "High system load: $load"
        return 1
    fi
    
    return 0
}

# Monitor services
monitor_services() {
    local issues=0
    
    for service in $MONITORED_SERVICES; do
        if ! check_service "$service"; then
            log_critical "Service '$service' is not running"
            ((issues++))
        fi
    done
    
    return $issues
}

# Monitor network interfaces
monitor_network() {
    local issues=0
    
    for interface in $MONITORED_INTERFACES; do
        if [ ! -d "/sys/class/net/$interface" ]; then
            log_warning "Network interface '$interface' not found"
            ((issues++))
        elif ! ip link show "$interface" | grep -q "state UP"; then
            log_warning "Network interface '$interface' is down"
            ((issues++))
        fi
    done
    
    return $issues
}

# Get system overview
get_system_overview() {
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local cpu_temp=$(get_cpu_temp)
    local load=$(get_load_average)
    local uptime=$(uptime -p)
    
    echo "=== System Overview ==="
    echo "Uptime: $uptime"
    echo "CPU Usage: ${cpu_usage}%"
    echo "Memory Usage: ${memory_usage}%"
    echo "CPU Temperature: ${cpu_temp}°C"
    echo "Load Average: $load"
    echo
    
    # Disk usage
    echo "=== Disk Usage ==="
    for disk in $MONITORED_DISKS; do
        local usage=$(get_disk_usage "$disk")
        if [ -n "$usage" ]; then
            echo "$disk: ${usage}%"
        fi
    done
    echo
    
    # GPU info
    local gpu_usage=$(get_gpu_usage)
    local gpu_temp=$(get_gpu_temp)
    if [ "$gpu_usage" != "0" ]; then
        echo "=== GPU Status ==="
        echo "GPU Usage: ${gpu_usage}%"
        echo "GPU Temperature: ${gpu_temp}°C"
        echo
    fi
    
    # Network interfaces
    echo "=== Network Interfaces ==="
    for interface in $MONITORED_INTERFACES; do
        if [ -d "/sys/class/net/$interface" ]; then
            local status=$(ip link show "$interface" | grep -o "state [A-Z]*" | cut -d' ' -f2)
            echo "$interface: $status"
        fi
    done
    echo
    
    # Services
    echo "=== Services Status ==="
    for service in $MONITORED_SERVICES; do
        if check_service "$service"; then
            echo "$service: Running"
        else
            echo "$service: Stopped"
        fi
    done
}

# Run full system check
run_system_check() {
    local total_issues=0
    
    log_info "Starting system check..."
    
    monitor_cpu || ((total_issues++))
    monitor_memory || ((total_issues++))
    monitor_disk; total_issues=$((total_issues + $?))
    monitor_temperature; total_issues=$((total_issues + $?))
    monitor_load || ((total_issues++))
    monitor_services; total_issues=$((total_issues + $?))
    monitor_network; total_issues=$((total_issues + $?))
    
    if [ $total_issues -eq 0 ]; then
        log_info "System check completed - no issues found"
    else
        log_warning "System check completed - $total_issues issues found"
    fi
    
    return $total_issues
}

# Start monitoring daemon
start_daemon() {
    local pid_file="/tmp/system-monitor.pid"
    
    if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        echo "System monitor is already running (PID: $(cat "$pid_file"))"
        return 1
    fi
    
    echo $$ > "$pid_file"
    
    log_info "Starting system monitor daemon..."
    
    while true; do
        run_system_check
        sleep "$CHECK_INTERVAL"
    done
}

# Stop monitoring daemon
stop_daemon() {
    local pid_file="/tmp/system-monitor.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$pid_file"
            log_info "System monitor daemon stopped"
        else
            rm -f "$pid_file"
            echo "System monitor daemon was not running"
        fi
    else
        echo "System monitor daemon is not running"
    fi
}

# Show system status in Waybar format
waybar_status() {
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local cpu_temp=$(get_cpu_temp)
    
    # Create status object for Waybar
    local status="{\"text\": \"CPU: ${cpu_usage}% | RAM: ${memory_usage}% | ${cpu_temp}°C\""
    
    # Add class based on highest usage
    local max_usage=$(echo "$cpu_usage $memory_usage" | tr ' ' '\n' | sort -nr | head -1)
    
    if (( $(echo "$max_usage > 80" | bc -l) )); then
        status+=", \"class\": \"critical\""
    elif (( $(echo "$max_usage > 60" | bc -l) )); then
        status+=", \"class\": \"warning\""
    else
        status+=", \"class\": \"normal\""
    fi
    
    status+="}"
    echo "$status"
}

# Show interactive menu
show_menu() {
    local menu_options="📊 System Overview\n🔍 Run System Check\n📈 Show Graphs\n📋 View Logs\n⚠️ View Alerts\n🔧 Settings\n▶️ Start Daemon\n⏹️ Stop Daemon"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "System Monitor")
    
    case "$selection" in
        "📊 System Overview")
            get_system_overview | rofi -dmenu -p "System Overview"
            ;;
        "🔍 Run System Check")
            run_system_check
            ;;
        "📈 Show Graphs")
            show_graphs_menu
            ;;
        "📋 View Logs")
            view_logs
            ;;
        "⚠️ View Alerts")
            view_alerts
            ;;
        "🔧 Settings")
            show_settings_menu
            ;;
        "▶️ Start Daemon")
            start_daemon &
            ;;
        "⏹️ Stop Daemon")
            stop_daemon
            ;;
    esac
}

# Show graphs menu
show_graphs_menu() {
    local graph_options="📊 CPU Usage\n💾 Memory Usage\n💿 Disk Usage\n🌡️ Temperature\n🌐 Network Usage"
    
    local selection=$(echo -e "$graph_options" | rofi -dmenu -p "Select Graph")
    
    case "$selection" in
        "📊 CPU Usage")
            show_cpu_graph
            ;;
        "💾 Memory Usage")
            show_memory_graph
            ;;
        "💿 Disk Usage")
            show_disk_graph
            ;;
        "🌡️ Temperature")
            show_temperature_graph
            ;;
        "🌐 Network Usage")
            show_network_graph
            ;;
    esac
}

#!/bin/bash

# Advanced Window Manager for Hyprland
# Provides window management, workspace organization, and layout automation

# Configuration
CONFIG_DIR="$HOME/.config/hypr"
LAYOUTS_DIR="$CONFIG_DIR/layouts"
SESSIONS_DIR="$CONFIG_DIR/sessions"

# Create directories
mkdir -p "$LAYOUTS_DIR" "$SESSIONS_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get active window info
get_active_window() {
    hyprctl activewindow -j 2>/dev/null
}

# Get all windows
get_all_windows() {
    hyprctl clients -j 2>/dev/null
}

# Get workspaces
get_workspaces() {
    hyprctl workspaces -j 2>/dev/null
}

# Focus window by direction
focus_window() {
    local direction="$1"
    
    case "$direction" in
        "left"|"l") hyprctl dispatch movefocus l ;;
        "right"|"r") hyprctl dispatch movefocus r ;;
        "up"|"u") hyprctl dispatch movefocus u ;;
        "down"|"d") hyprctl dispatch movefocus d ;;
        *) error "Invalid direction: $direction" ;;
    esac
}

# Move window by direction
move_window() {
    local direction="$1"
    
    case "$direction" in
        "left"|"l") hyprctl dispatch movewindow l ;;
        "right"|"r") hyprctl dispatch movewindow r ;;
        "up"|"u") hyprctl dispatch movewindow u ;;
        "down"|"d") hyprctl dispatch movewindow d ;;
        *) error "Invalid direction: $direction" ;;
    esac
}

# Show CPU usage graph (simple text-based)
show_cpu_graph() {
    local graph_data=""
    
    for i in {1..20}; do
        local cpu_usage=$(get_cpu_usage)
        local bar_length=$((cpu_usage / 5))
        local bar=$(printf "%*s" "$bar_length" | tr ' ' '█')
        
        graph_data+="$(date '+%H:%M:%S') [$bar] ${cpu_usage}%\n"
        sleep 1
    done
    
    echo -e "$graph_data" | rofi -dmenu -p "CPU Usage Graph"
}

# View logs
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -50 "$LOG_FILE" | rofi -dmenu -p "System Logs"
    else
        echo "No logs found" | rofi -dmenu -p "System Logs"
    fi
}

# View alerts
view_alerts() {
    if [ -f "$ALERT_FILE" ]; then
        tail -20 "$ALERT_FILE" | rofi -dmenu -p "System Alerts"
    else
        echo "No alerts found" | rofi -dmenu -p "System Alerts"
    fi
}

# Settings menu
show_settings_menu() {
    local settings_options="🎚️ Adjust Thresholds\n⏱️ Set Intervals\n🔔 Notification Settings\n📁 Manage Logs\n🔄 Reset Configuration"
    
    local selection=$(echo -e "$settings_options" | rofi -dmenu -p "Settings")
    
    case "$selection" in
        "🎚️ Adjust Thresholds")
            adjust_thresholds
            ;;
        "⏱️ Set Intervals")
            set_intervals
            ;;
        "🔔 Notification Settings")
            notification_settings
            ;;
        "📁 Manage Logs")
            manage_logs
            ;;
        "🔄 Reset Configuration")
            reset_configuration
            ;;
    esac
}

# Adjust thresholds
adjust_thresholds() {
    local new_cpu=$(rofi -dmenu -p "CPU threshold (%)" -filter "$CPU_THRESHOLD")
    local new_memory=$(rofi -dmenu -p "Memory threshold (%)" -filter "$MEMORY_THRESHOLD")
    local new_disk=$(rofi -dmenu -p "Disk threshold (%)" -filter "$DISK_THRESHOLD")
    local new_temp=$(rofi -dmenu -p "Temperature threshold (°C)" -filter "$TEMP_THRESHOLD")
    
    # Update configuration file
    if [ -n "$new_cpu" ]; then
        sed -i "s/CPU_THRESHOLD=.*/CPU_THRESHOLD=$new_cpu/" "$CONFIG_FILE"
    fi
    if [ -n "$new_memory" ]; then
        sed -i "s/MEMORY_THRESHOLD=.*/MEMORY_THRESHOLD=$new_memory/" "$CONFIG_FILE"
    fi
    if [ -n "$new_disk" ]; then
        sed -i "s/DISK_THRESHOLD=.*/DISK_THRESHOLD=$new_disk/" "$CONFIG_FILE"
    fi
    if [ -n "$new_temp" ]; then
        sed -i "s/TEMP_THRESHOLD=.*/TEMP_THRESHOLD=$new_temp/" "$CONFIG_FILE"
    fi
    
    log_info "Thresholds updated"
}

# Generate system report
generate_report() {
    local report_file="$HOME/system-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== System Monitor Report ==="
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo ""
        
        get_system_overview
        
        echo "=== Recent Alerts ==="
        if [ -f "$ALERT_FILE" ]; then
            tail -20 "$ALERT_FILE"
        else
            echo "No alerts found"
        fi
        
        echo ""
        echo "=== System Information ==="
        echo "Kernel: $(uname -r)"
        echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "Architecture: $(uname -m)"
        echo "Processor: $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)"
        echo "Total Memory: $(free -h | grep Mem | awk '{print $2}')"
        
        echo ""
        echo "=== Disk Information ==="
        df -h
        
        echo ""
        echo "=== Process Information ==="
        echo "Top 10 CPU processes:"
        ps aux --sort=-%cpu | head -11
        
        echo ""
        echo "Top 10 Memory processes:"
        ps aux --sort=-%mem | head -11
        
    } > "$report_file"
    
    log_info "System report generated: $report_file"
    echo "$report_file"
}

# Performance benchmark
run_benchmark() {
    log_info "Starting performance benchmark..."
    
    local start_time=$(date +%s)
    
    # CPU benchmark
    log_info "Running CPU benchmark..."
    local cpu_start=$(date +%s.%N)
    echo "scale=5000; 4*a(1)" | bc -l > /dev/null
    local cpu_end=$(date +%s.%N)
    local cpu_time=$(echo "$cpu_end - $cpu_start" | bc)
    
    # Memory benchmark
    log_info "Running memory benchmark..."
    local mem_start=$(date +%s.%N)
    dd if=/dev/zero of=/tmp/benchmark bs=1M count=100 2>/dev/null
    local mem_end=$(date +%s.%N)
    local mem_time=$(echo "$mem_end - $mem_start" | bc)
    rm -f /tmp/benchmark
    
    # Disk benchmark
    log_info "Running disk benchmark..."
    local disk_start=$(date +%s.%N)
    dd if=/dev/zero of=/tmp/diskbench bs=1M count=100 2>/dev/null
    sync
    local disk_end=$(date +%s.%N)
    local disk_time=$(echo "$disk_end - $disk_start" | bc)
    rm -f /tmp/diskbench
    
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    local results="=== Performance Benchmark Results ===\n"
    results+="Total time: ${total_time}s\n"
    results+="CPU calculation time: ${cpu_time}s\n"
    results+="Memory write time: ${mem_time}s\n"
    results+="Disk write time: ${disk_time}s\n"
    results+="\nBenchmark completed at: $(date)"
    
    echo -e "$results" | rofi -dmenu -p "Benchmark Results"
    
    log_info "Performance benchmark completed"
}

# System cleanup
system_cleanup() {
    log_info "Starting system cleanup..."
    
    local cleaned_space=0
    
    # Clean package cache
    if command -v pacman &> /dev/null; then
        local cache_size=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
        sudo pacman -Sc --noconfirm
        log_info "Cleaned package cache: $cache_size"
    fi
    
    # Clean journal logs
    local journal_size=$(journalctl --disk-usage 2>/dev/null | grep -o '[0-9.]*[KMGT]B')
    sudo journalctl --vacuum-time=7d
    log_info "Cleaned journal logs: $journal_size"
    
    # Clean temporary files
    local temp_size=$(du -sh /tmp 2>/dev/null | cut -f1)
    find /tmp -type f -atime +7 -delete 2>/dev/null
    log_info "Cleaned temporary files: $temp_size"
    
    # Clean user cache
    if [ -d "$HOME/.cache" ]; then
        local cache_size=$(du -sh "$HOME/.cache" 2>/dev/null | cut -f1)
        find "$HOME/.cache" -type f -atime +30 -delete 2>/dev/null
        log_info "Cleaned user cache: $cache_size"
    fi
    
    # Clean thumbnails
    if [ -d "$HOME/.thumbnails" ]; then
        local thumb_size=$(du -sh "$HOME/.thumbnails" 2>/dev/null | cut -f1)
        rm -rf "$HOME/.thumbnails"/*
        log_info "Cleaned thumbnails: $thumb_size"
    fi
    
    log_info "System cleanup completed"
}

# Monitor specific process
monitor_process() {
    local process_name="$1"
    
    if [ -z "$process_name" ]; then
        process_name=$(ps aux | awk '{print $11}' | sort | uniq | rofi -dmenu -p "Select process to monitor")
        [ -z "$process_name" ] && return 1
    fi
    
    local pid=$(pgrep "$process_name" | head -1)
    
    if [ -z "$pid" ]; then
        log_warning "Process '$process_name' not found"
        return 1
    fi
    
    log_info "Monitoring process: $process_name (PID: $pid)"
    
    while kill -0 "$pid" 2>/dev/null; do
        local cpu_usage=$(ps -p "$pid" -o %cpu --no-headers 2>/dev/null | xargs)
        local mem_usage=$(ps -p "$pid" -o %mem --no-headers 2>/dev/null | xargs)
        local rss=$(ps -p "$pid" -o rss --no-headers 2>/dev/null | xargs)
        
        echo "$(date '+%H:%M:%S') - CPU: ${cpu_usage}% | Memory: ${mem_usage}% | RSS: ${rss}KB"
        
        sleep 2
    done
    
    log_info "Process '$process_name' has terminated"
}

# Check for system updates
check_updates() {
    log_info "Checking for system updates..."
    
    local updates=""
    
    if command -v pacman &> /dev/null; then
        updates=$(checkupdates 2>/dev/null | wc -l)
        if [ "$updates" -gt 0 ]; then
            log_info "$updates package updates available"
        else
            log_info "System is up to date"
        fi
    elif command -v apt &> /dev/null; then
        apt list --upgradable 2>/dev/null | grep -c upgradable
        updates=$?
        if [ "$updates" -gt 0 ]; then
            log_info "$updates package updates available"
        else
            log_info "System is up to date"
        fi
    fi
    
    return "$updates"
}

# Main function
main() {
    # Ensure directories exist
    mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$ALERT_FILE")"
    
    # Load configuration
    load_config
    
    case "${1:-menu}" in
        "menu") show_menu ;;
        "check") run_system_check ;;
        "overview") get_system_overview ;;
        "daemon") start_daemon ;;
        "stop") stop_daemon ;;
        "waybar") waybar_status ;;
        "report") generate_report ;;
        "benchmark") run_benchmark ;;
        "cleanup") system_cleanup ;;
        "monitor") monitor_process "$2" ;;
        "updates") check_updates ;;
        "cpu") echo "CPU: $(get_cpu_usage)%" ;;
        "memory") echo "Memory: $(get_memory_usage)%" ;;
        "temp") echo "Temperature: $(get_cpu_temp)°C" ;;
        "disk") 
            for disk in $MONITORED_DISKS; do
                echo "$disk: $(get_disk_usage "$disk")%"
            done
            ;;
        *)
            echo "Usage: $0 {menu|check|overview|daemon|stop|waybar|report|benchmark|cleanup|monitor|updates|cpu|memory|temp|disk}"
            echo ""
            echo "Commands:"
            echo "  menu      - Show interactive menu"
            echo "  check     - Run system check"
            echo "  overview  - Show system overview"
            echo "  daemon    - Start monitoring daemon"
            echo "  stop      - Stop monitoring daemon"
            echo "  waybar    - Output for Waybar"
            echo "  report    - Generate system report"
            echo "  benchmark - Run performance benchmark"
            echo "  cleanup   - Clean system files"
            echo "  monitor   - Monitor specific process"
            echo "  updates   - Check for updates"
            echo "  cpu       - Show CPU usage"
            echo "  memory    - Show memory usage"
            echo "  temp      - Show temperature"
            echo "  disk      - Show disk usage"
            exit 1
            ;;
    esac
}

main "$@"
