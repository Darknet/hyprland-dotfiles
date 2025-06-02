#!/bin/bash

# Advanced Application Manager
# Provides application launching, management, and system monitoring

# Configuration
CONFIG_DIR="$HOME/.config/app-manager"
FAVORITES_FILE="$CONFIG_DIR/favorites.json"
HISTORY_FILE="$CONFIG_DIR/history.json"
LOGS_DIR="$CONFIG_DIR/logs"

# Create directories
mkdir -p "$CONFIG_DIR" "$LOGS_DIR"

# Initialize files
[ ! -f "$FAVORITES_FILE" ] && echo "[]" > "$FAVORITES_FILE"
[ ! -f "$HISTORY_FILE" ] && echo "[]" > "$HISTORY_FILE"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons
ICON_APP="📱"
ICON_FAVORITE="⭐"
ICON_RECENT="🕒"
ICON_RUNNING="🟢"
ICON_SYSTEM="⚙️"
ICON_TERMINAL="💻"

# Logging
log() { echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOGS_DIR/app.log"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOGS_DIR/app.log"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOGS_DIR/app.log"; }

# Get all desktop applications
get_applications() {
    local app_dirs="/usr/share/applications:$HOME/.local/share/applications:/var/lib/flatpak/exports/share/applications:$HOME/.local/share/flatpak/exports/share/applications"
    
    IFS=':' read -ra DIRS <<< "$app_dirs"
    for dir in "${DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -name "*.desktop" -type f
        fi
    done | sort | uniq
}

# Parse desktop file
parse_desktop_file() {
    local desktop_file="$1"
    local name=""
    local exec=""
    local icon=""
    local comment=""
    local categories=""
    local terminal="false"
    local nodisplay="false"
    
    while IFS='=' read -r key value; do
        case "$key" in
            "Name") name="$value" ;;
            "Exec") exec="$value" ;;
            "Icon") icon="$value" ;;
            "Comment") comment="$value" ;;
            "Categories") categories="$value" ;;
            "Terminal") terminal="$value" ;;
            "NoDisplay") nodisplay="$value" ;;
        esac
    done < "$desktop_file"
    
    # Skip if NoDisplay is true
    if [ "$nodisplay" = "true" ]; then
        return 1
    fi
    
    # Clean exec command (remove field codes)
    exec=$(echo "$exec" | sed 's/%[fFuU]//g' | sed 's/%[icdnNvmk]//g' | xargs)
    
    echo "$name|$exec|$icon|$comment|$categories|$terminal|$desktop_file"
}

# List all applications
list_applications() {
    local filter="$1"
    
    get_applications | while read -r desktop_file; do
        local app_info=$(parse_desktop_file "$desktop_file")
        
        if [ $? -eq 0 ] && [ -n "$app_info" ]; then
            local name=$(echo "$app_info" | cut -d'|' -f1)
            local categories=$(echo "$app_info" | cut -d'|' -f5)
            
            # Apply filter if specified
            if [ -n "$filter" ]; then
                if ! echo "$categories" | grep -qi "$filter" && ! echo "$name" | grep -qi "$filter"; then
                    continue
                fi
            fi
            
            echo "$app_info"
        fi
    done | sort
}

# Launch application
launch_app() {
    local app_name="$1"
    local exec_command="$2"
    local terminal="$3"
    local desktop_file="$4"
    
    if [ -z "$exec_command" ]; then
        error "No exec command provided"
        return 1
    fi
    
    log "Launching application: $app_name"
    
    # Add to history
    add_to_history "$app_name" "$exec_command" "$desktop_file"
    
    # Launch application
    if [ "$terminal" = "true" ]; then
        x-terminal-emulator -e bash -c "$exec_command; read -p 'Press Enter to close...'"
    else
        nohup bash -c "$exec_command" > /dev/null 2>&1 &
    fi
    
    notify-send "App Manager" "Launched $app_name" -i "$ICON_APP" -t 2000
}

# Add application to favorites
add_to_favorites() {
    local app_name="$1"
    local exec_command="$2"
    local icon="$3"
    local desktop_file="$4"
    
    local favorites=$(cat "$FAVORITES_FILE")
    local new_favorite=$(jq -n \
        --arg name "$app_name" \
        --arg exec "$exec_command" \
        --arg icon "$icon" \
        --arg desktop_file "$desktop_file" \
        --arg added "$(date -Iseconds)" \
        '{
            name: $name,
            exec: $exec,
            icon: $icon,
            desktop_file: $desktop_file,
            added: $added
        }')
    
    # Check if already in favorites
    local exists=$(echo "$favorites" | jq --arg name "$app_name" 'any(.name == $name)')
    
    if [ "$exists" = "true" ]; then
        warn "Application already in favorites: $app_name"
        return 1
    fi
    
    # Add to favorites
    echo "$favorites" | jq ". += [$new_favorite]" > "$FAVORITES_FILE"
    log "Added to favorites: $app_name"
    notify-send "App Manager" "Added $app_name to favorites" -i "$ICON_FAVORITE" -t 2000
}

# Remove from favorites
remove_from_favorites() {
    local app_name="$1"
    
    local favorites=$(cat "$FAVORITES_FILE")
    local updated_favorites=$(echo "$favorites" | jq --arg name "$app_name" 'map(select(.name != $name))')
    
    echo "$updated_favorites" > "$FAVORITES_FILE"
    log "Removed from favorites: $app_name"
    notify-send "App Manager" "Removed $app_name from favorites" -i "$ICON_FAVORITE" -t 2000
}

# List favorite applications
list_favorites() {
    local favorites=$(cat "$FAVORITES_FILE")
    echo "$favorites" | jq -r '.[] | "\(.name)|\(.exec)|\(.icon)|\(.desktop_file)"'
}

# Add to history
add_to_history() {
    local app_name="$1"
    local exec_command="$2"
    local desktop_file="$3"
    
    local history=$(cat "$HISTORY_FILE")
    local new_entry=$(jq -n \
        --arg name "$app_name" \
        --arg exec "$exec_command" \
        --arg desktop_file "$desktop_file" \
        --arg launched "$(date -Iseconds)" \
        '{
            name: $name,
            exec: $exec,
            desktop_file: $desktop_file,
            launched: $launched
        }')
    
    # Remove existing entry if present and add new one at the beginning
    local updated_history=$(echo "$history" | jq --arg name "$app_name" 'map(select(.name != $name))')
    updated_history=$(echo "$updated_history" | jq ". = [$new_entry] + .")
    
    # Keep only last 50 entries
    updated_history=$(echo "$updated_history" | jq '.[0:50]')
    
    echo "$updated_history" > "$HISTORY_FILE"
}

# List recent applications
list_recent() {
    local limit="${1:-10}"
    local history=$(cat "$HISTORY_FILE")
    echo "$history" | jq -r --arg limit "$limit" '.[:($limit | tonumber)] | .[] | "\(.name)|\(.exec)||\(.desktop_file)"'
}

# Get running applications
get_running_apps() {
    ps aux --no-headers | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | \
    grep -v "^\[" | grep -v "^$" | sort | uniq | head -20
}

# Kill application
kill_app() {
    local app_pattern="$1"
    
    if [ -z "$app_pattern" ]; then
        local running_apps=$(get_running_apps | nl -w2 -s'. ')
        local selection=$(echo "$running_apps" | rofi -dmenu -p "Select process to kill")
        
        if [ -n "$selection" ]; then
            app_pattern=$(echo "$selection" | sed 's/^[0-9]*\. //')
        else
            return 1
        fi
    fi
    
    local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Kill process: $app_pattern?")
    
    if [ "$confirm" = "Yes" ]; then
        pkill -f "$app_pattern"
        log "Killed process: $app_pattern"
        notify-send "App Manager" "Killed $app_pattern" -i process-stop -t 2000
    fi
}

# Show application launcher
show_launcher() {
    local category="$1"
    local apps=""
    
    # Get applications based on category
    case "$category" in
        "favorites")
            apps=$(list_favorites | while IFS='|' read -r name exec icon desktop_file; do
                echo "$ICON_FAVORITE $name"
            done)
            ;;
        "recent")
            apps=$(list_recent | while IFS='|' read -r name exec icon desktop_file; do
                echo "$ICON_RECENT $name"
            done)
            ;;
        "running")
            apps=$(get_running_apps | while read -r app; do
                echo "$ICON_RUNNING $app"
            done)
            ;;
        *)
            apps=$(list_applications "$category" | while IFS='|' read -r name exec icon comment categories terminal desktop_file; do
                echo "$ICON_APP $name"
            done)
            ;;
    esac
    
    if [ -z "$apps" ]; then
        notify-send "App Manager" "No applications found" -i dialog-information -t 2000
        return 1
    fi
    
    local selection=$(echo "$apps" | rofi -dmenu -p "Launch Application")
    
    if [ -n "$selection" ]; then
        local app_name=$(echo "$selection" | sed 's/^[^ ]* //')
        
        case "$category" in
            "favorites")
                local app_info=$(list_favorites | grep "^$app_name|")
                if [ -n "$app_info" ]; then
                    local exec_command=$(echo "$app_info" | cut -d'|' -f2)
                    local desktop_file=$(echo "$app_info" | cut -d'|' -f4)
                    launch_app "$app_name" "$exec_command" "false" "$desktop_file"
                fi
                ;;
            "recent")
                local app_info=$(list_recent 50 | grep "^$app_name|")
                if [ -n "$app_info" ]; then
                    local exec_command=$(echo "$app_info" | cut -d'|' -f2)
                    local desktop_file=$(echo "$app_info" | cut -d'|' -f4)
                    launch_app "$app_name" "$exec_command" "false" "$desktop_file"
                fi
                ;;
            "running")
                kill_app "$app_name"
                ;;
            *)
                local app_info=$(list_applications "$category" | grep "^$app_name|")
                if [ -n "$app_info" ]; then
                    IFS='|' read -r name exec icon comment categories terminal desktop_file <<< "$app_info"
                    launch_app "$name" "$exec" "$terminal" "$desktop_file"
                fi
                ;;
        esac
    fi
}

# Show application details
show_app_details() {
    local apps=$(list_applications | while IFS='|' read -r name exec icon comment categories terminal desktop_file; do
        echo "$name"
    done)
    
    local selection=$(echo "$apps" | rofi -dmenu -p "Select application for details")
    
    if [ -n "$selection" ]; then
        local app_info=$(list_applications | grep "^$selection|")
        
        if [ -n "$app_info" ]; then
            IFS='|' read -r name exec icon comment categories terminal desktop_file <<< "$app_info"
            
            local details="=== Application Details ===\n"
            details+="Name: $name\n"
            details+="Command: $exec\n"
            details+="Icon: $icon\n"
            details+="Description: $comment\n"
            details+="Categories: $categories\n"
            details+="Terminal: $terminal\n"
            details+="Desktop File: $desktop_file\n\n"
            
            # Check if in favorites
            local in_favorites=$(cat "$FAVORITES_FILE" | jq --arg name "$name" 'any(.name == $name)')
            details+="In Favorites: $in_favorites\n"
            
            echo -e "$details" | rofi -dmenu -p "Application Details"
        fi
    fi
}

# Show categories menu
show_categories_menu() {
    local categories="📱 All Applications\n⭐ Favorites\n🕒 Recent\n🟢 Running\n📊 System Monitor\n🎮 Games\n🌐 Internet\n📝 Office\n🎨 Graphics\n🎵 Multimedia\n🛠️ Development\n⚙️ System\n📚 Education\n🔧 Utilities"
    
    local selection=$(echo -e "$categories" | rofi -dmenu -p "Application Categories")
    
    case "$selection" in
        "📱 All Applications") show_launcher ;;
        "⭐ Favorites") show_launcher "favorites" ;;
        "🕒 Recent") show_launcher "recent" ;;
        "🟢 Running") show_launcher "running" ;;
        "📊 System Monitor") 
            if command -v htop &> /dev/null; then
                x-terminal-emulator -e htop
            elif command -v top &> /dev/null; then
                x-terminal-emulator -e top
            else
                warn "No system monitor found"
            fi
            ;;
        "🎮 Games") show_launcher "game" ;;
        "🌐 Internet") show_launcher "network" ;;
        "📝 Office") show_launcher "office" ;;
        "🎨 Graphics") show_launcher "graphics" ;;
        "🎵 Multimedia") show_launcher "multimedia" ;;
        "🛠️ Development") show_launcher "development" ;;
        "⚙️ System") show_launcher "system" ;;
        "📚 Education") show_launcher "education" ;;
        "🔧 Utilities") show_launcher "utility" ;;
    esac
}

# Show favorites management menu
show_favorites_menu() {
    local fav_options="⭐ Launch Favorite\n➕ Add to Favorites\n➖ Remove from Favorites\n📋 List Favorites\n🗑️ Clear Favorites"
    
    local selection=$(echo -e "$fav_options" | rofi -dmenu -p "Favorites Manager")
    
    case "$selection" in
        "⭐ Launch Favorite")
            show_launcher "favorites"
            ;;
        "➕ Add to Favorites")
            local apps=$(list_applications | while IFS='|' read -r name exec icon comment categories terminal desktop_file; do
                echo "$name"
            done)
            
            local app_selection=$(echo "$apps" | rofi -dmenu -p "Add to favorites")
            
            if [ -n "$app_selection" ]; then
                local app_info=$(list_applications | grep "^$app_selection|")
                if [ -n "$app_info" ]; then
                    IFS='|' read -r name exec icon comment categories terminal desktop_file <<< "$app_info"
                    add_to_favorites "$name" "$exec" "$icon" "$desktop_file"
                fi
            fi
            ;;
        "➖ Remove from Favorites")
            local favorites=$(list_favorites | while IFS='|' read -r name exec icon desktop_file; do
                echo "$name"
            done)
            
            local fav_selection=$(echo "$favorites" | rofi -dmenu -p "Remove from favorites")
            
            if [ -n "$fav_selection" ]; then
                remove_from_favorites "$fav_selection"
            fi
            ;;
        "📋 List Favorites")
            local favorites_list=$(list_favorites | while IFS='|' read -r name exec icon desktop_file; do
                echo "⭐ $name"
            done)
            
            if [ -n "$favorites_list" ]; then
                echo "$favorites_list" | rofi -dmenu -p "Favorite Applications"
            else
                echo "No favorites found" | rofi -dmenu -p "Favorites"
            fi
            ;;
        "🗑️ Clear Favorites")
            local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Clear all favorites?")
            
            if [ "$confirm" = "Yes" ]; then
                echo "[]" > "$FAVORITES_FILE"
                log "Cleared all favorites"
                notify-send "App Manager" "Cleared all favorites" -i edit-clear -t 2000
            fi
            ;;
    esac
}

# Show main menu
show_menu() {
    local menu_options="🚀 Launch Application\n📂 Categories\n⭐ Favorites\n🕒 Recent Apps\n🟢 Running Apps\n📊 App Details\n🔧 System Tools\n⚙️ Settings"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "Application Manager")
    
    case "$selection" in
        "🚀 Launch Application")
            show_launcher
            ;;
        "📂 Categories")
            show_categories_menu
            ;;
        "⭐ Favorites")
            show_favorites_menu
            ;;
        "🕒 Recent Apps")
            show_launcher "recent"
            ;;
        "🟢 Running Apps")
            show_launcher "running"
            ;;
        "📊 App Details")
            show_app_details
            ;;
        "🔧 System Tools")
            local tools_options="💻 Terminal\n📁 File Manager\n🌐 Web Browser\n📝 Text Editor\n🎨 Image Viewer\n📊 System Monitor"
            local tool_selection=$(echo -e "$tools_options" | rofi -dmenu -p "System Tools")
            
            case "$tool_selection" in
                "💻 Terminal") x-terminal-emulator & ;;
                "📁 File Manager") 
                    if command -v nautilus &> /dev/null; then
                        nautilus &
                    elif command -v thunar &> /dev/null; then
                        thunar &
                    elif command -v pcmanfm &> /dev/null; then
                        pcmanfm &
                    else
                        warn "No file manager found"
                    fi
                    ;;
                "🌐 Web Browser")
                    if command -v firefox &> /dev/null; then
                        firefox &
                    elif command -v chromium &> /dev/null; then
                        chromium &
                    elif command -v google-chrome &> /dev/null; then
                        google-chrome &
                    else
                        warn "No web browser found"
                    fi
                    ;;
                "📝 Text Editor")
                    if command -v gedit &> /dev/null; then
                        gedit &
                    elif command -v mousepad &> /dev/null; then
                        mousepad &
                    elif command -v nano &> /dev/null; then
                        x-terminal-emulator -e nano
                    else
                        warn "No text editor found"
                    fi
                    ;;
                "🎨 Image Viewer")
                    if command -v eog &> /dev/null; then
                        eog &
                    elif command -v feh &> /dev/null; then
                        feh &
                    else
                        warn "No image viewer found"
                    fi
                    ;;
                "📊 System Monitor")
                    if command -v gnome-system-monitor &> /dev/null; then
                        gnome-system-monitor &
                    elif command -v htop &> /dev/null; then
                        x-terminal-emulator -e htop
                    else
                        x-terminal-emulator -e top
                    fi
                    ;;
            esac
            ;;
        "⚙️ Settings")
            local settings_options="📋 View History\n🗑️ Clear History\n📊 Statistics\n📝 View Logs\n🔧 Refresh Apps"
            local setting=$(echo -e "$settings_options" | rofi -dmenu -p "App Manager Settings")
            
            case "$setting" in
                "📋 View History")
                    local history_list=$(list_recent 20 | while IFS='|' read -r name exec icon desktop_file; do
                        echo "🕒 $name"
                    done)
                    
                    if [ -n "$history_list" ]; then
                        echo "$history_list" | rofi -dmenu -p "Application History"
                    else
                        echo "No history found" | rofi -dmenu -p "History"
                    fi
                    ;;
                "🗑️ Clear History")
                    local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Clear application history?")
                    
                    if [ "$confirm" = "Yes" ]; then
                        echo "[]" > "$HISTORY_FILE"
                        log "Cleared application history"
                        notify-send "App Manager" "Cleared application history" -i edit-clear -t 2000
                    fi
                    ;;
                "📊 Statistics")
                    local total_apps=$(list_applications | wc -l)
                    local favorites_count=$(cat "$FAVORITES_FILE" | jq 'length')
                    local history_count=$(cat "$HISTORY_FILE" | jq 'length')
                    local running_count=$(get_running_apps | wc -l)
                    
                    local stats="=== Application Statistics ===\n"
                    stats+="Total Applications: $total_apps\n"
                    stats+="Favorite Applications: $favorites_count\n"
                    stats+="History Entries: $history_count\n"
                    stats+="Running Processes: $running_count\n"
                    
                    echo -e "$stats" | rofi -dmenu -p "Statistics"
                    ;;
                "📝 View Logs")
                    if [ -f "$LOGS_DIR/app.log" ]; then
                        tail -50 "$LOGS_DIR/app.log" | rofi -dmenu -p "Application Logs"
                    else
                        echo "No logs found" | rofi -dmenu -p "Logs"
                    fi
                    ;;
                "🔧 Refresh Apps")
                    log "Refreshing application cache"
                    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
                    notify-send "App Manager" "Application cache refreshed" -i view-refresh -t 2000
                    ;;
            esac
            ;;
    esac
}

# Search applications
search_apps() {
    local query="$1"
    
    if [ -z "$query" ]; then
        query=$(rofi -dmenu -p "Search applications")
        [ -z "$query" ] && return 1
    fi
    
    local results=$(list_applications | grep -i "$query" | while IFS='|' read -r name exec icon comment categories terminal desktop_file; do
        echo "$ICON_APP $name - $comment"
    done)
    
    if [ -z "$results" ]; then
        notify-send "App Manager" "No applications found for: $query" -i dialog-information -t 3000
        return 1
    fi
    
    local selection=$(echo "$results" | rofi -dmenu -p "Search Results")
    
    if [ -n "$selection" ]; then
        local app_name=$(echo "$selection" | sed 's/^[^ ]* \([^-]*\) -.*/\1/' | xargs)
        local app_info=$(list_applications | grep "^$app_name|")
        
        if [ -n "$app_info" ]; then
            IFS='|' read -r name exec icon comment categories terminal desktop_file <<< "$app_info"
            launch_app "$name" "$exec" "$terminal" "$desktop_file"
        fi
    fi
}

# Quick launcher (dmenu style)
quick_launcher() {
    local apps=$(list_applications | while IFS='|' read -r name exec icon comment categories terminal desktop_file; do
        echo "$name"
    done)
    
    local selection=$(echo "$apps" | rofi -dmenu -p "Quick Launch")
    
    if [ -n "$selection" ]; then
        local app_info=$(list_applications | grep "^$selection|")
        
        if [ -n "$app_info" ]; then
            IFS='|' read -r name exec icon comment categories terminal desktop_file <<< "$app_info"
            launch_app "$name" "$exec" "$terminal" "$desktop_file"
        fi
    fi
}

# Main function
main() {
    case "${1:-menu}" in
        "menu") show_menu ;;
        "launch") quick_launcher ;;
        "search") search_apps "$2" ;;
        "favorites") show_favorites_menu ;;
        "recent") show_launcher "recent" ;;
        "running") show_launcher "running" ;;
        "categories") show_categories_menu ;;
        "details") show_app_details ;;
        "add-favorite")
            if [ -n "$2" ]; then
                local app_info=$(list_applications | grep "^$2|")
                if [ -n "$app_info" ]; then
                    IFS='|' read -r name exec icon comment categories terminal desktop_file <<< "$app_info"
                    add_to_favorites "$name" "$exec" "$icon" "$desktop_file"
                fi
            fi
            ;;
        "remove-favorite")
            if [ -n "$2" ]; then
                remove_from_favorites "$2"
            fi
            ;;
        "kill")
            kill_app "$2"
            ;;
        "list")
            case "$2" in
                "all") list_applications ;;
                "favorites") list_favorites ;;
                "recent") list_recent ;;
                "running") get_running_apps ;;
                *) list_applications "$2" ;;
            esac
            ;;
        *)
            echo "Usage: $0 {menu|launch|search|favorites|recent|running|categories|details|add-favorite|remove-favorite|kill|list}"
            echo ""
            echo "Application Management:"
            echo "  menu                  - Show main application menu"
            echo "  launch                - Quick application launcher"
            echo "  search [query]        - Search applications"
            echo "  categories            - Browse by categories"
            echo "  details               - Show application details"
            echo ""
            echo "Favorites Management:"
            echo "  favorites             - Favorites management menu"
            echo "  add-favorite <name>   - Add application to favorites"
            echo "  remove-favorite <name> - Remove from favorites"
            echo ""
            echo "Application Lists:"
            echo "  recent                - Show recent applications"
            echo "  running               - Show running applications"
            echo "  list all              - List all applications"
            echo "  list favorites        - List favorite applications"
            echo "  list recent           - List recent applications"
            echo "  list running          - List running processes"
            echo "  list [category]       - List applications by category"
            echo ""
            echo "Process Management:"
            echo "  kill [pattern]        - Kill application/process"
            exit 1
            ;;
    esac
}

main "$@"

