#!/bin/bash

# Project Manager for Development Workflow
# Manages development projects, sessions, and environments

CONFIG_DIR="$HOME/.config"
PROJECTS_DIR="$HOME/Projects"
SESSIONS_FILE="$CONFIG_DIR/.project_sessions"

# Colors
RED="#ff5555"
GREEN="#50fa7b"
YELLOW="#f1fa8c"
BLUE="#8be9fd"
PURPLE="#bd93f9"

# Ensure directories exist
mkdir -p "$PROJECTS_DIR"
touch "$SESSIONS_FILE"

# Get list of projects
get_projects() {
    find "$PROJECTS_DIR" -maxdepth 2 -name ".git" -type d | while read -r git_dir; do
        project_dir=$(dirname "$git_dir")
        basename "$project_dir"
    done | sort
}

# Get recent projects from sessions file
get_recent_projects() {
    if [ -f "$SESSIONS_FILE" ]; then
        tail -10 "$SESSIONS_FILE" | cut -d'|' -f1 | tac
    fi
}

# Add project to recent sessions
add_to_sessions() {
    local project="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${project}|${timestamp}" >> "$SESSIONS_FILE"
}

# Create new project
create_project() {
    local project_name="$1"
    local template="$2"
    
    if [ -z "$project_name" ]; then
        project_name=$(rofi -dmenu -p "Project name")
        [ -z "$project_name" ] && return 1
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ -d "$project_path" ]; then
        notify-send "Project Manager" "Project '$project_name' already exists" -u normal
        return 1
    fi
    
    mkdir -p "$project_path"
    cd "$project_path"
    
    case "$template" in
        "react")
            npx create-react-app . --template typescript
            ;;
        "vue")
            npm create vue@latest .
            ;;
        "node")
            npm init -y
            mkdir -p src tests docs
            echo "node_modules/\n.env\n*.log" > .gitignore
            ;;
        "python")
            python -m venv venv
            echo "venv/\n__pycache__/\n*.pyc\n.env" > .gitignore
            echo "# $project_name\n\n## Installation\n\n## Usage" > README.md
            ;;
        "rust")
            cargo init .
            ;;
        "go")
            go mod init "$project_name"
            mkdir -p cmd pkg internal
            ;;
        "empty"|*)
            echo "# $project_name\n\n## Description\n\n## Installation\n\n## Usage" > README.md
            ;;
    esac
    
    # Initialize git
    git init
    git add .
    git commit -m "Initial commit"
    
    notify-send "Project Manager" "Project '$project_name' created successfully" -u normal
    open_project "$project_name"
}

# Open project in development environment
open_project() {
    local project="$1"
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        notify-send "Project Manager" "Project '$project' not found" -u critical
        return 1
    fi
    
    # Add to recent sessions
    add_to_sessions "$project"
    
    # Open in VS Code
    if command -v code &> /dev/null; then
        code "$project_path"
    fi
    
    # Open terminal in project directory
    kitty --working-directory="$project_path" &
    
    # Start development servers if package.json exists
    if [ -f "$project_path/package.json" ]; then
        # Check for common dev scripts
        if grep -q '"dev"' "$project_path/package.json"; then
            kitty --working-directory="$project_path" -e fish -c "npm run dev; fish" &
        elif grep -q '"start"' "$project_path/package.json"; then
            kitty --working-directory="$project_path" -e fish -c "npm start; fish" &
        fi
    fi
    
    # Start Python virtual environment
    if [ -f "$project_path/venv/bin/activate" ]; then
        kitty --working-directory="$project_path" -e fish -c "source venv/bin/activate.fish; fish" &
    fi
    
    notify-send "Project Manager" "Opened project '$project'" -u normal
}

# Delete project
delete_project() {
    local project="$1"
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        notify-send "Project Manager" "Project '$project' not found" -u critical
        return 1
    fi
    
    # Confirmation dialog
    local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Delete project '$project'? This cannot be undone!")
    
    if [ "$confirm" = "Yes" ]; then
        rm -rf "$project_path"
        # Remove from sessions
        grep -v "^$project|" "$SESSIONS_FILE" > "${SESSIONS_FILE}.tmp" && mv "${SESSIONS_FILE}.tmp" "$SESSIONS_FILE"
        notify-send "Project Manager" "Project '$project' deleted" -u normal
    fi
}

# Show project info
show_project_info() {
    local project="$1"
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        echo "Project not found"
        return 1
    fi
    
    local info="Project: $project\n"
    info+="Path: $project_path\n"
    info+="Size: $(du -sh "$project_path" | cut -f1)\n"
    
    # Git info
    if [ -d "$project_path/.git" ]; then
        cd "$project_path"
        local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        local commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        local last_commit=$(git log -1 --format="%cr" 2>/dev/null || echo "never")
        
        info+="Git branch: $branch\n"
        info+="Commits: $commits\n"
        info+="Last commit: $last_commit\n"
    fi
    
    # Language detection
    if [ -f "$project_path/package.json" ]; then
        info+="Type: Node.js/JavaScript\n"
    elif [ -f "$project_path/Cargo.toml" ]; then
        info+="Type: Rust\n"
    elif [ -f "$project_path/go.mod" ]; then
        info+="Type: Go\n"
    elif [ -f "$project_path/requirements.txt" ] || [ -f "$project_path/pyproject.toml" ]; then
        info+="Type: Python\n"
    fi
    
    echo -e "$info"
}

# Clone repository
clone_repository() {
    local repo_url=$(rofi -dmenu -p "Repository URL")
    [ -z "$repo_url" ] && return 1
    
    local project_name=$(basename "$repo_url" .git)
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ -d "$project_path" ]; then
        notify-send "Project Manager" "Project '$project_name' already exists" -u normal
        return 1
    fi
    
    # Clone repository
    git clone "$repo_url" "$project_path"
    
    if [ $? -eq 0 ]; then
        notify-send "Project Manager" "Repository cloned successfully" -u normal
        open_project "$project_name"
    else
        notify-send "Project Manager" "Failed to clone repository" -u critical
    fi
}

# Search projects
search_projects() {
    local query=$(rofi -dmenu -p "Search projects")
    [ -z "$query" ] && return 1
    
    local results=$(get_projects | grep -i "$query")
    
    if [ -z "$results" ]; then
        notify-send "Project Manager" "No projects found matching '$query'" -u normal
        return 1
    fi
    
    local selected=$(echo "$results" | rofi -dmenu -p "Select project")
    [ -n "$selected" ] && open_project "$selected"
}

# Backup projects
backup_projects() {
    local backup_dir="$HOME/project-backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    notify-send "Project Manager" "Starting backup..." -u normal
    
    # Create archive of all projects
    tar -czf "$backup_dir/projects.tar.gz" -C "$HOME" "Projects" 2>/dev/null
    
    # Copy sessions file
    cp "$SESSIONS_FILE" "$backup_dir/sessions.txt"
    
    # Create backup info
    echo "Backup created: $(date)" > "$backup_dir/info.txt"
    echo "Projects backed up: $(get_projects | wc -l)" >> "$backup_dir/info.txt"
    
    notify-send "Project Manager" "Backup completed: $backup_dir" -u normal
}

# Show project menu
show_project_menu() {
    local menu_options="🆕 New Project\n📂 Open Project\n📋 Recent Projects\n🔍 Search Projects\n📥 Clone Repository\n📊 Project Stats\n💾 Backup Projects\n⚙️ Settings"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "Project Manager")
    
    case "$selection" in
        "🆕 New Project")
            show_new_project_menu
            ;;
        "📂 Open Project")
            show_open_project_menu
            ;;
        "📋 Recent Projects")
            show_recent_projects_menu
            ;;
        "🔍 Search Projects")
            search_projects
            ;;
        "📥 Clone Repository")
            clone_repository
            ;;
        "📊 Project Stats")
            show_project_stats
            ;;
        "💾 Backup Projects")
            backup_projects
            ;;
        "⚙️ Settings")
            show_settings_menu
            ;;
    esac
}

# New project menu
show_new_project_menu() {
    local templates="📄 Empty Project\n⚛️ React (TypeScript)\n🟢 Vue.js\n📦 Node.js\n🐍 Python\n🦀 Rust\n🐹 Go"
    
    local selection=$(echo -e "$templates" | rofi -dmenu -p "Select template")
    
    case "$selection" in
        "📄 Empty Project") create_project "" "empty" ;;
        "⚛️ React (TypeScript)") create_project "" "react" ;;
        "🟢 Vue.js") create_project "" "vue" ;;
        "📦 Node.js") create_project "" "node" ;;
        "🐍 Python") create_project "" "python" ;;
        "🦀 Rust") create_project "" "rust" ;;
        "🐹 Go") create_project "" "go" ;;
    esac
}

# Open project menu
show_open_project_menu() {
    local projects=$(get_projects)
    
    if [ -z "$projects" ]; then
        notify-send "Project Manager" "No projects found" -u normal
        return 1
    fi
    
    local selected=$(echo "$projects" | rofi -dmenu -p "Select project to open")
    
    if [ -n "$selected" ]; then
        # Show project actions
        local actions="📂 Open\nℹ️ Info\n🗑️ Delete"
        local action=$(echo -e "$actions" | rofi -dmenu -p "Action for '$selected'")
        
        case "$action" in
            "📂 Open") open_project "$selected" ;;
            "ℹ️ Info") show_project_info "$selected" | rofi -dmenu -p "Project Info" ;;
            "🗑️ Delete") delete_project "$selected" ;;
        esac
    fi
}

# Recent projects menu
show_recent_projects_menu() {
    local recent=$(get_recent_projects)
    
    if [ -z "$recent" ]; then
        notify-send "Project Manager" "No recent projects" -u normal
        return 1
    fi
    
    local selected=$(echo "$recent" | rofi -dmenu -p "Recent projects")
    [ -n "$selected" ] && open_project "$selected"
}

# Show project statistics
show_project_stats() {
    local total_projects=$(get_projects | wc -l)
    local total_size=$(du -sh "$PROJECTS_DIR" 2>/dev/null | cut -f1)
    
    # Count by language
    local js_projects=$(find "$PROJECTS_DIR" -name "package.json" | wc -l)
    local python_projects=$(find "$PROJECTS_DIR" -name "requirements.txt" -o -name "pyproject.toml" | wc -l)
    local rust_projects=$(find "$PROJECTS_DIR" -name "Cargo.toml" | wc -l)
    local go_projects=$(find "$PROJECTS_DIR" -name "go.mod" | wc -l)
    
    local stats="📊 Project Statistics\n\n"
    stats+="Total projects: $total_projects\n"
    stats+="Total size: $total_size\n\n"
    stats+="By language:\n"
    stats+="JavaScript/Node.js: $js_projects\n"
    stats+="Python: $python_projects\n"
    stats+="Rust: $rust_projects\n"
    stats+="Go: $go_projects\n"
    
    echo -e "$stats" | rofi -dmenu -p "Project Statistics"
}

# Settings menu
show_settings_menu() {
    local settings="📁 Change Projects Directory\n🔧 Edit Templates\n🧹 Clean Old Sessions\n📋 Export Project List"
    
    local selection=$(echo -e "$settings" | rofi -dmenu -p "Settings")
    
    case "$selection" in
        "📁 Change Projects Directory")
            change_projects_directory
            ;;
        "🔧 Edit Templates")
            edit_templates
            ;;
        "🧹 Clean Old Sessions")
            clean_old_sessions
            ;;
        "📋 Export Project List")
            export_project_list
            ;;
    esac
}

# Change projects directory
change_projects_directory() {
    local new_dir=$(rofi -dmenu -p "New projects directory" -filter "$PROJECTS_DIR")
    
    if [ -n "$new_dir" ] && [ "$new_dir" != "$PROJECTS_DIR" ]; then
        # Update script configuration
        sed -i "s|PROJECTS_DIR=.*|PROJECTS_DIR=\"$new_dir\"|" "$0"
        notify-send "Project Manager" "Projects directory changed to $new_dir" -u normal
    fi
}

# Clean old sessions
clean_old_sessions() {
    local days=$(rofi -dmenu -p "Remove sessions older than (days)" -filter "30")
    
    if [ -n "$days" ] && [ "$days" -gt 0 ]; then
        local cutoff_date=$(date -d "$days days ago" '+%Y-%m-%d')
        awk -F'|' -v cutoff="$cutoff_date" '$2 >= cutoff' "$SESSIONS_FILE" > "${SESSIONS_FILE}.tmp"
        mv "${SESSIONS_FILE}.tmp" "$SESSIONS_FILE"
        notify-send "Project Manager" "Cleaned sessions older than $days days" -u normal
    fi
}

# Export project list
export_project_list() {
    local export_file="$HOME/project-list-$(date +%Y%m%d).txt"
    
    echo "# Project List - $(date)" > "$export_file"
    echo "# Generated by Project Manager" >> "$export_file"
    echo "" >> "$export_file"
    
    get_projects | while read -r project; do
        echo "## $project" >> "$export_file"
        show_project_info "$project" >> "$export_file"
        echo "" >> "$export_file"
    done
    
    notify-send "Project Manager" "Project list exported to $export_file" -u normal
}

# Main function
main() {
    case "${1:-menu}" in
        "menu") show_project_menu ;;
        "new") create_project "$2" "$3" ;;
        "open") open_project "$2" ;;
        "delete") delete_project "$2" ;;
        "info") show_project_info "$2" ;;
        "clone") clone_repository ;;
        "search") search_projects ;;
        "backup") backup_projects ;;
        "stats") show_project_stats ;;
        "recent") show_recent_projects_menu ;;
        *) 
            echo "Usage: $0 {menu|new|open|delete|info|clone|search|backup|stats|recent}"
            exit 1
            ;;
    esac
}

main "$@"

