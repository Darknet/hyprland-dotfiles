#!/bin/bash
# Script de información del sistema para Waybar

get_cpu_usage() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "${cpu_usage}%"
}

get_memory_usage() {
    mem_info=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
    mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    echo "${mem_info} (${mem_percent}%)"
}

get_disk_usage() {
    disk_info=$(df -h / | awk 'NR==2 {print $3 "/" $2}')
    disk_percent=$(df / | awk 'NR==2 {print $5}')
    echo "${disk_info} (${disk_percent})"
}

get_temperature() {
    if command -v sensors >/dev/null 2>&1; then
        temp=$(sensors | grep 'Core 0' | awk '{print $3}' | cut -d'+' -f2 | cut -d'.' -f1)
        echo "${temp}°C"
    else
        echo "N/A"
    fi
}

case "$1" in
    "cpu")
        echo "{\"text\":\"󰻠 $(get_cpu_usage)\",\"tooltip\":\"CPU Usage: $(get_cpu_usage)\"}"
        ;;
    "memory")
        mem=$(get_memory_usage)
        echo "{\"text\":\"󰍛 ${mem%% *}\",\"tooltip\":\"Memory: ${mem}\"}"
        ;;
    "disk")
        disk=$(get_disk_usage)
        echo "{\"text\":\"󰋊 ${disk%% *}\",\"tooltip\":\"Disk: ${disk}\"}"
        ;;
    "temp")
        temp=$(get_temperature)
        echo "{\"text\":\"󰔏 ${temp}\",\"tooltip\":\"CPU Temperature: ${temp}\"}"
        ;;
    *)
        echo "Uso: $0 {cpu|memory|disk|temp}"
        ;;
esac
