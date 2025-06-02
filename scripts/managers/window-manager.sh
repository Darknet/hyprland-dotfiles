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

# Resize window
resize_window() {
    local direction="$1"
    local amount="${2:-50}"
    
    case "$direction" in
        "left"|"l") hyprctl dispatch resizeactive -"$amount" 0 ;;
        "right"|"r") hyprctl dispatch resizeactive "$amount" 0 ;;
        "up"|"u") hyprctl dispatch resizeactive 0 -"$amount" ;;
        "down"|"d") hyprctl dispatch resizeactive 0 "$amount" ;;
        "grow") hyprctl dispatch resizeactive "$amount" "$amount" ;;
        "shrink") hyprctl dispatch resizeactive -"$amount" -"$amount" ;;
        *) error "Invalid resize direction: $direction" ;;
    esac
}

# Toggle window floating
toggle_floating() {
    hyprctl dispatch togglefloating
}

# Toggle window fullscreen
toggle_fullscreen() {
    local mode="${1:-0}"
    hyprctl dispatch fullscreen "$mode"
}

# Close active window
close_window() {
    hyprctl dispatch killactive
}

# Cycle through windows
cycle_windows() {
    local direction="${1:-next}"
    
    case "$direction" in
        "next"|"n") hyprctl dispatch cyclenext ;;
        "prev"|"p") hyprctl dispatch cyclenext prev ;;
        *) error "Invalid cycle direction: $direction" ;;
    esac
}

# Move window to workspace
move_to_workspace() {
    local workspace="$1"
    
    if [ -z "$workspace" ]; then
        workspace=$(seq 1 10 | rofi -dmenu -p "Move to workspace")
        [ -z "$workspace" ] && return 1
    fi
    
    hyprctl dispatch movetoworkspace "$workspace"
}

# Switch to workspace
switch_workspace() {
    local workspace="$1"
    
    if [ -z "$workspace" ]; then
        workspace=$(seq 1 10 | rofi -dmenu -p "Switch to workspace")
        [ -z "$workspace" ] && return 1
    fi
    
    hyprctl dispatch workspace "$workspace"
}

# Create new workspace
create_workspace() {
    local workspace_name="$1"
    
    if [ -z "$workspace_name" ]; then
        workspace_name=$(rofi -dmenu -p "Workspace name")
        [ -z "$workspace_name" ] && return 1
    fi
    
    # Find next available workspace number
    local next_ws=$(hyprctl workspaces -j | jq -r '.[].id' | sort -n | tail -1)
    next_ws=$((next_ws + 1))
    
    hyprctl dispatch workspace "$next_ws"
    hyprctl dispatch renameworkspace "$next_ws" "$workspace_name"
    
    log "Created workspace: $workspace_name ($next_ws)"
}

# Window layouts
apply_layout() {
    local layout="$1"
    
    case "$layout" in
        "tiled")
            hyprctl dispatch workspaceopt allfloat false
            log "Applied tiled layout"
            ;;
        "floating")
            hyprctl dispatch workspaceopt allfloat true
            log "Applied floating layout"
            ;;
        "master")
            # Set master layout
            hyprctl keyword general:layout master
            log "Applied master layout"
            ;;
        "dwindle")
            # Set dwindle layout
            hyprctl keyword general:layout dwindle
            log "Applied dwindle layout"
            ;;
        *)
            error "Unknown layout: $layout"
            ;;
    esac
}

# Save current layout
save_layout() {
    local layout_name="$1"
    
    if [ -z "$layout_name" ]; then
        layout_name=$(rofi -dmenu -p "Layout name")
        [ -z "$layout_name" ] && return 1
    fi
    
    local layout_file="$LAYOUTS_DIR/$layout_name.json"
    
    # Get current window positions and sizes
    local windows=$(get_all_windows)
    local workspaces=$(get_workspaces)
    
    # Create layout data
    local layout_data=$(jq -n \
        --argjson windows "$windows" \
        --argjson workspaces "$workspaces" \
        '{
            name: $layout_name,
            created: now,
            windows: $windows,
            workspaces: $workspaces
        }' --arg layout_name "$layout_name")
    
    echo "$layout_data" > "$layout_file"
    
    log "Layout saved: $layout_name"
}

# Load layout
load_layout() {
    local layout_name="$1"
    
    if [ -z "$layout_name" ]; then
        local layouts=$(ls "$LAYOUTS_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
        layout_name=$(echo "$layouts" | rofi -dmenu -p "Select layout")
        [ -z "$layout_name" ] && return 1
    fi
    
    local layout_file="$LAYOUTS_DIR/$layout_name.json"
    
    if [ ! -f "$layout_file" ]; then
        error "Layout not found: $layout_name"
        return 1
    fi
    
    log "Loading layout: $layout_name"
    
    # This is a simplified version - full implementation would restore window positions
    local layout_data=$(cat "$layout_file")
    
    # Apply basic layout settings
    local general_layout=$(echo "$layout_data" | jq -r '.general_layout // "dwindle"')
    hyprctl keyword general:layout "$general_layout"
    
    log "Layout loaded: $layout_name"
}

# List available layouts
list_layouts() {
    if [ -d "$LAYOUTS_DIR" ]; then
        echo "Available layouts:"
        ls "$LAYOUTS_DIR"/*.json 2>/dev/null | while read -r layout_file; do
            local layout_name=$(basename "$layout_file" .json)
            local created=$(jq -r '.created' "$layout_file" 2>/dev/null)
            local date_str=$(date -d "@$created" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "Unknown")
            echo "  $layout_name (created: $date_str)"
        done
    else
        echo "No layouts found"
    fi
}

# Save window session
save_session() {
    local session_name="$1"
    
    if [ -z "$session_name" ]; then
        session_name=$(rofi -dmenu -p "Session name")
        [ -z "$session_name" ] && return 1
    fi
    
    local session_file="$SESSIONS_DIR/$session_name.json"
    
    # Get all windows with their applications
    local windows=$(get_all_windows)
    local workspaces=$(get_workspaces)
    
    # Create session data
    local session_data=$(jq -n \
        --argjson windows "$windows" \
        --argjson workspaces "$workspaces" \
        '{
            name: $session_name,
            created: now,
            windows: $windows,
            workspaces: $workspaces
        }' --arg session_name "$session_name")
    
    echo "$session_data" > "$session_file"
    
    log "Session saved: $session_name"
}

# Load window session
load_session() {
    local session_name="$1"
    
    if [ -z "$session_name" ]; then
        local sessions=$(ls "$SESSIONS_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
        session_name=$(echo "$sessions" | rofi -dmenu -p "Select session")
        [ -z "$session_name" ] && return 1
    fi
    
    local session_file="$SESSIONS_DIR/$session_name.json"
    
    if [ ! -f "$session_file" ]; then
        error "Session not found: $session_name"
        return 1
    fi
    
    log "Loading session: $session_name"
    
    # Extract application list from session
    local apps=$(jq -r '.windows[].class' "$session_file" | sort | uniq)
    
    # Launch applications
    echo "$apps" | while read -r app; do
        if [ -n "$app" ] && [ "$app" != "null" ]; then
            log "Launching: $app"
            hyprctl dispatch exec "$app" &
            sleep 1
        fi
    done
    
    log "Session loaded: $session_name"
}

# Window rules management
add_window_rule() {
    local rule="$1"
    local class="$2"
    
    if [ -z "$rule" ] || [ -z "$class" ]; then
        echo "Usage: add_window_rule <rule> <class>"
        echo "Example: add_window_rule 'float,size 800 600' firefox"
        return 1
    fi
    
    hyprctl keyword windowrule "$rule,$class"
    
    # Save to config file
    echo "windowrule = $rule,$class" >> "$CONFIG_DIR/windowrules.conf"
    
    log "Added window rule: $rule for $class"
}

# Show window information
show_window_info() {
    local window_info=$(get_active_window)
    
    if [ "$window_info" = "null" ] || [ -z "$window_info" ]; then
        error "No active window"
        return 1
    fi
    
    local title=$(echo "$window_info" | jq -r '.title')
    local class=$(echo "$window_info" | jq -r '.class')
    local workspace=$(echo "$window_info" | jq -r '.workspace.name')
    local floating=$(echo "$window_info" | jq -r '.floating')
    local fullscreen=$(echo "$window_info" | jq -r '.fullscreen')
    local at=$(echo "$window_info" | jq -r '.at | "\(.[0]),\(.[1])"')
    local size=$(echo "$window_info" | jq -r '.size | "\(.[0])x\(.[1])"')
    
    local info="Window Information:
Title: $title
Class: $class
Workspace: $workspace
Position: $at
Size: $size
Floating: $floating
Fullscreen: $fullscreen"
    
    echo "$info" | rofi -dmenu -p "Window Info"
}

# Workspace management
organize_workspaces() {
    local organization="$1"
    
    case "$organization" in
        "by-app")
            organize_by_application
            ;;
        "by-project")
            organize_by_project
            ;;
        "clean")
            clean_empty_workspaces
            ;;
        *)
            error "Unknown organization method: $organization"
            ;;
    esac
}

# Organize windows by application
organize_by_application() {
    log "Organizing windows by application..."
    
    local windows=$(get_all_windows)
    local apps=$(echo "$windows" | jq -r '.[].class' | sort | uniq)
    
    local workspace=1
    echo "$apps" | while read -r app; do
        if [ -n "$app" ] && [ "$app" != "null" ]; then
            # Move all windows of this app to workspace
            echo "$windows" | jq -r ".[] | select(.class == \"$app\") | .address" | while read -r address; do
                hyprctl dispatch movetoworkspacesilent "$workspace,address:$address"
            done
            
            # Rename workspace
            hyprctl dispatch renameworkspace "$workspace" "$app"
            
            workspace=$((workspace + 1))
        fi
    done
    
    log "Windows organized by application"
}

# Clean empty workspaces
clean_empty_workspaces() {
    log "Cleaning empty workspaces..."
    
    local workspaces=$(get_workspaces)
    
    echo "$workspaces" | jq -r '.[] | select(.windows == 0) | .id' | while read -r ws_id; do
        if [ "$ws_id" -gt 1 ]; then  # Don't remove workspace 1
            hyprctl dispatch removeworkspace "$ws_id"
            log "Removed empty workspace: $ws_id"
        fi
    done
}

# Smart window placement
smart_placement() {
    local placement_type="$1"
    
    case "$placement_type" in
        "center")
            hyprctl dispatch centerwindow
            ;;
        "maximize")
            hyprctl dispatch fullscreen 1
            ;;
        "tile-left")
            hyprctl dispatch movewindow l
            hyprctl dispatch resizeactive 50% 100%
            ;;
        "tile-right")
            hyprctl dispatch movewindow r
            hyprctl dispatch resizeactive 50% 100%
            ;;
        "quarter-tl")
            hyprctl dispatch movewindow l
            hyprctl dispatch movewindow u
            hyprctl dispatch resizeactive 50% 50%
            ;;
        "quarter-tr")
            hyprctl dispatch movewindow r
            hyprctl dispatch movewindow u
            hyprctl dispatch resizeactive 50% 50%
            ;;
        "quarter-bl")
            hyprctl dispatch movewindow l
            hyprctl dispatch movewindow d
            hyprctl dispatch resizeactive 50% 50%
            ;;
        "quarter-br")
            hyprctl dispatch movewindow r
            hyprctl dispatch movewindow d
            hyprctl dispatch resizeactive 50% 50%
            ;;
        *)
            error "Unknown placement type: $placement_type"
            ;;
    esac
}

# Window search and focus
search_and_focus() {
    local windows=$(get_all_windows)
    
    # Create searchable list
    local window_list=$(echo "$windows" | jq -r '.[] | "\(.title) [\(.class)] - WS:\(.workspace.name)"')
    
    local selection=$(echo "$window_list" | rofi -dmenu -p "Search window")
    
    if [ -n "$selection" ]; then
        # Extract window class and title to find the window
        local title=$(echo "$selection" | cut -d'[' -f1 | xargs)
        local class=$(echo "$selection" | sed 's/.*\[\(.*\)\].*/\1/')
        
        # Find window address
        local address=$(echo "$windows" | jq -r ".[] | select(.title == \"$title\" and .class == \"$class\") | .address")
        
        if [ -n "$address" ]; then
            hyprctl dispatch focuswindow "address:$address"
            log "Focused window: $title"
        fi
    fi
}

# Show interactive menu
show_menu() {
    local menu_options="🔍 Search & Focus\n📐 Window Layouts\n💾 Save Layout\n📂 Load Layout\n💼 Sessions\n📊 Window Info\n🎯 Smart Placement\n🗂️ Organize Workspaces\n⚙️ Window Rules"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "Window Manager")
    
    case "$selection" in
        "🔍 Search & Focus")
            search_and_focus
            ;;
        "📐 Window Layouts")
            show_layout_menu
            ;;
        "💾 Save Layout")
            save_layout
            ;;
        "📂 Load Layout")
            load_layout
            ;;
        "💼 Sessions")
            show_session_menu
            ;;
        "📊 Window Info")
            show_window_info
            ;;
        "🎯 Smart Placement")
            show_placement_menu
            ;;
        "🗂️ Organize Workspaces")
            show_organize_menu
            ;;
        "⚙️ Window Rules")
            show_rules_menu
            ;;
    esac
}

# Layout menu
show_layout_menu() {
    local layout_options="📋 Tiled\n🎈 Floating\n👑 Master\n🌀 Dwindle\n📋 List Layouts"
    
    local selection=$(echo -e "$layout_options" | rofi -dmenu -p "Select Layout")
    
    case "$selection" in
        "📋 Tiled")
            apply_layout "tiled"
            ;;
        "🎈 Floating")
            apply_layout "floating"
            ;;
        "👑 Master")
            apply_layout "master"
            ;;
        "🌀 Dwindle")
            apply_layout "dwindle"
            ;;
        "📋 List Layouts")
            list_layouts | rofi -dmenu -p "Available Layouts"
            ;;
    esac
}

# Session menu
show_session_menu() {
    local session_options="💾 Save Session\n📂 Load Session\n📋 List Sessions\n🗑️ Delete Session"
    
    local selection=$(echo -e "$session_options" | rofi -dmenu -p "Session Manager")
    
    case "$selection" in
        "💾 Save Session")
            save_session
            ;;
        "📂 Load Session")
            load_session
            ;;
        "📋 List Sessions")
            list_sessions
            ;;
        "🗑️ Delete Session")
            delete_session
            ;;
    esac
}

# List sessions
list_sessions() {
    if [ -d "$SESSIONS_DIR" ]; then
        echo "Available sessions:"
        ls "$SESSIONS_DIR"/*.json 2>/dev/null | while read -r session_file; do
            local session_name=$(basename "$session_file" .json)
            local created=$(jq -r '.created' "$session_file" 2>/dev/null)
            local date_str=$(date -d "@$created" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "Unknown")
            local window_count=$(jq -r '.windows | length' "$session_file" 2>/dev/null)
            echo "  $session_name ($window_count windows, created: $date_str)"
        done | rofi -dmenu -p "Available Sessions"
    else
        echo "No sessions found" | rofi -dmenu -p "Sessions"
    fi
}

# Delete session
delete_session() {
    local sessions=$(ls "$SESSIONS_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
    local session_name=$(echo "$sessions" | rofi -dmenu -p "Delete session")
    
    if [ -n "$session_name" ]; then
        local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Delete session '$session_name'?")
        
        if [ "$confirm" = "Yes" ]; then
            rm -f "$SESSIONS_DIR/$session_name.json"
            log "Session deleted: $session_name"
        fi
    fi
}

# Smart placement menu
show_placement_menu() {
    local placement_options="🎯 Center\n📏 Maximize\n⬅️ Tile Left\n➡️ Tile Right\n↖️ Quarter Top-Left\n↗️ Quarter Top-Right\n↙️ Quarter Bottom-Left\n↘️ Quarter Bottom-Right"
    
    local selection=$(echo -e "$placement_options" | rofi -dmenu -p "Smart Placement")
    
    case "$selection" in
        "🎯 Center")
            smart_placement "center"
            ;;
        "📏 Maximize")
            smart_placement "maximize"
            ;;
        "⬅️ Tile Left")
            smart_placement "tile-left"
            ;;
        "➡️ Tile Right")
            smart_placement "tile-right"
            ;;
        "↖️ Quarter Top-Left")
            smart_placement "quarter-tl"
            ;;
        "↗️ Quarter Top-Right")
            smart_placement "quarter-tr"
            ;;
        "↙️ Quarter Bottom-Left")
            smart_placement "quarter-bl"
            ;;
        "↘️ Quarter Bottom-Right")
            smart_placement "quarter-br"
            ;;
    esac
}

# Organize menu
show_organize_menu() {
    local organize_options="📱 By Application\n📁 By Project\n🧹 Clean Empty Workspaces\n🔢 Renumber Workspaces"
    
    local selection=$(echo -e "$organize_options" | rofi -dmenu -p "Organize Workspaces")
    
    case "$selection" in
        "📱 By Application")
            organize_workspaces "by-app"
            ;;
        "📁 By Project")
            organize_workspaces "by-project"
            ;;
        "🧹 Clean Empty Workspaces")
            organize_workspaces "clean"
            ;;
        "🔢 Renumber Workspaces")
            renumber_workspaces
            ;;
    esac
}

# Renumber workspaces
renumber_workspaces() {
    log "Renumbering workspaces..."
    
    local workspaces=$(get_workspaces | jq -r 'sort_by(.id) | .[].id')
    local new_number=1
    
    echo "$workspaces" | while read -r ws_id; do
        if [ "$ws_id" != "$new_number" ]; then
            hyprctl dispatch renameworkspace "$ws_id" "$new_number"
            log "Renamed workspace $ws_id to $new_number"
        fi
        new_number=$((new_number + 1))
    done
}

# Window rules menu
show_rules_menu() {
    local rules_options="➕ Add Rule\n📋 List Rules\n🗑️ Remove Rule\n📝 Edit Rules File"
    
    local selection=$(echo -e "$rules_options" | rofi -dmenu -p "Window Rules")
    
    case "$selection" in
        "➕ Add Rule")
            add_rule_interactive
            ;;
        "📋 List Rules")
            list_window_rules
            ;;
        "🗑️ Remove Rule")
            remove_window_rule
            ;;
        "📝 Edit Rules File")
            edit_rules_file
            ;;
    esac
}

# Add rule interactively
add_rule_interactive() {
    local rule_types="float\nsize\nposition\nworkspace\nopacity\nfullscreen"
    local rule_type=$(echo -e "$rule_types" | rofi -dmenu -p "Rule type")
    
    if [ -z "$rule_type" ]; then
        return 1
    fi
    
    local class=$(rofi -dmenu -p "Window class")
    if [ -z "$class" ]; then
        return 1
    fi
    
    local rule=""
    case "$rule_type" in
        "float")
            rule="float"
            ;;
        "size")
            local width=$(rofi -dmenu -p "Width")
            local height=$(rofi -dmenu -p "Height")
            rule="size $width $height"
            ;;
        "position")
            local x=$(rofi -dmenu -p "X position")
            local y=$(rofi -dmenu -p "Y position")
            rule="move $x $y"
            ;;
        "workspace")
            local workspace=$(rofi -dmenu -p "Workspace")
            rule="workspace $workspace"
            ;;
        "opacity")
            local opacity=$(rofi -dmenu -p "Opacity (0.0-1.0)")
            rule="opacity $opacity"
            ;;
        "fullscreen")
            rule="fullscreen"
            ;;
    esac
    
    if [ -n "$rule" ]; then
        add_window_rule "$rule" "$class"
    fi
}

# List window rules
list_window_rules() {
    if [ -f "$CONFIG_DIR/windowrules.conf" ]; then
        cat "$CONFIG_DIR/windowrules.conf" | rofi -dmenu -p "Window Rules"
    else
        echo "No window rules found" | rofi -dmenu -p "Window Rules"
    fi
}

# Remove window rule
remove_window_rule() {
    if [ ! -f "$CONFIG_DIR/windowrules.conf" ]; then
        error "No window rules file found"
        return 1
    fi
    
    local rules=$(cat "$CONFIG_DIR/windowrules.conf")
    local rule_to_remove=$(echo "$rules" | rofi -dmenu -p "Select rule to remove")
    
    if [ -n "$rule_to_remove" ]; then
        grep -v "$rule_to_remove" "$CONFIG_DIR/windowrules.conf" > "$CONFIG_DIR/windowrules.conf.tmp"
        mv "$CONFIG_DIR/windowrules.conf.tmp" "$CONFIG_DIR/windowrules.conf"
        log "Removed window rule: $rule_to_remove"
    fi
}

# Edit rules file
edit_rules_file() {
    if [ ! -f "$CONFIG_DIR/windowrules.conf" ]; then
        touch "$CONFIG_DIR/windowrules.conf"
    fi
    
    ${EDITOR:-code} "$CONFIG_DIR/windowrules.conf"
}

# Workspace switcher with preview
workspace_switcher() {
    local workspaces=$(get_workspaces)
    
    # Create workspace list with window counts
    local ws_list=$(echo "$workspaces" | jq -r '.[] | "\(.id): \(.name) (\(.windows) windows)"')
    
    local selection=$(echo "$ws_list" | rofi -dmenu -p "Switch to workspace")
    
    if [ -n "$selection" ]; then
        local ws_id=$(echo "$selection" | cut -d':' -f1)
        switch_workspace "$ws_id"
    fi
}

# Window stack management
manage_stack() {
    local action="$1"
    
    case "$action" in
        "next")
            hyprctl dispatch layoutmsg cyclenext
            ;;
        "prev")
            hyprctl dispatch layoutmsg cycleprev
            ;;
        "swap")
            hyprctl dispatch layoutmsg swapwithmaster
            ;;
        "master")
            hyprctl dispatch layoutmsg focusmaster
            ;;
        *)
            error "Unknown stack action: $action"
            ;;
    esac
}

# Emergency window recovery
emergency_recovery() {
    log "Starting emergency window recovery..."
    
    # Reset all floating windows to tiled
    hyprctl dispatch workspaceopt allfloat false
    
    # Move all windows to visible area
    local windows=$(get_all_windows)
    echo "$windows" | jq -r '.[].address' | while read -r address; do
        hyprctl dispatch movewindowpixel exact 100 100 "address:$address"
        hyprctl dispatch resizewindowpixel exact 800 600 "address:$address"
    done
    
    # Reset layout
    hyprctl keyword general:layout dwindle
    
    log "Emergency recovery completed"
}

# Main function
main() {
    case "${1:-menu}" in
        "menu") show_menu ;;
        "focus") focus_window "$2" ;;
        "move") move_window "$2" ;;
        "resize") resize_window "$2" "$3" ;;
        "float") toggle_floating ;;
        "fullscreen") toggle_fullscreen "$2" ;;
        "close") close_window ;;
        "cycle") cycle_windows "$2" ;;
        "workspace") switch_workspace "$2" ;;
        "movetoworkspace") move_to_workspace "$2" ;;
        "layout") apply_layout "$2" ;;
        "save-layout") save_layout "$2" ;;
        "load-layout") load_layout "$2" ;;
        "list-layouts") list_layouts ;;
        "save-session") save_session "$2" ;;
        "load-session") load_session "$2" ;;
        "search") search_and_focus ;;
        "info") show_window_info ;;
        "organize") organize_workspaces "$2" ;;
        "placement") smart_placement "$2" ;;
        "rule") add_window_rule "$2" "$3" ;;
        "switcher") workspace_switcher ;;
        "stack") manage_stack "$2" ;;
        "recovery") emergency_recovery ;;
        *)
            echo "Usage: $0 {menu|focus|move|resize|float|fullscreen|close|cycle|workspace|movetoworkspace|layout|save-layout|load-layout|list-layouts|save-session|load-session|search|info|organize|placement|rule|switcher|stack|recovery}"
            echo ""
            echo "Window Management:"
            echo "  focus <direction>     - Focus window in direction"
            echo "  move <direction>      - Move window in direction"
            echo "  resize <direction>    - Resize window"
            echo "  float                 - Toggle floating"
            echo "  fullscreen [mode]     - Toggle fullscreen"
            echo "  close                 - Close active window"
            echo "  cycle [direction]     - Cycle through windows"
            echo ""
            echo "Workspace Management:"
            echo "  workspace <id>        - Switch to workspace"
            echo "  movetoworkspace <id>  - Move window to workspace"
            echo "  switcher              - Interactive workspace switcher"
            echo "  organize <method>     - Organize workspaces"
            echo ""
            echo "Layout Management:"
            echo "  layout <type>         - Apply layout"
            echo "  save-layout [name]    - Save current layout"
            echo "  load-layout [name]    - Load saved layout"
            echo "  list-layouts          - List available layouts"
            echo ""
            echo "Session Management:"
            echo "  save-session [name]   - Save window session"
            echo "  load-session [name]   - Load window session"
            echo ""
            echo "Utilities:"
            echo "  search                - Search and focus window"
            echo "  info                  - Show window information"
            echo "  placement <type>      - Smart window placement"
            echo "  rule <rule> <class>   - Add window rule"
            echo "  stack <action>        - Manage window stack"
            echo "  recovery              - Emergency window recovery"
            echo "  menu                  - Show interactive menu"
            exit 1
            ;;
    esac
}

main "$@"


