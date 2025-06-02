#!/bin/bash

# Dotfiles Manager
# Manages configuration files, themes, and system settings

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backups"
THEMES_DIR="$CONFIG_DIR/themes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration files to manage
MANAGED_CONFIGS=(
    "hypr"
    "waybar"
    "rofi"
    "kitty"
    "fish"
    "starship"
    "dunst"
    "gtk-3.0"
    "gtk-4.0"
    "fontconfig"
)

# Initialize dotfiles repository
init_dotfiles() {
    if [ -d "$DOTFILES_DIR" ]; then
        warn "Dotfiles directory already exists"
        return 1
    fi
    
    log "Initializing dotfiles repository..."
    mkdir -p "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
    
    git init
    
    # Create directory structure
    for config in "${MANAGED_CONFIGS[@]}"; do
        mkdir -p "$config"
    done
    
    # Create README
    cat > README.md << EOF
# My Dotfiles

Personal configuration files for Hyprland and associated applications.

## Installation

\`\`\`bash
./install.sh
\`\`\`

## Configurations Included

$(printf "- %s\n" "${MANAGED_CONFIGS[@]}")

## Last Updated

$(date)
EOF
    
    # Create install script
    create_install_script
    
    git add .
    git commit -m "Initial dotfiles setup"
    
    log "Dotfiles repository initialized at $DOTFILES_DIR"
}

# Create install script for dotfiles
create_install_script() {
    cat > "$DOTFILES_DIR/install.sh" << 'EOF'
#!/bin/bash

# Dotfiles installation script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# Create backup
if [ -d "$CONFIG_DIR" ]; then
    log "Creating backup at $BACKUP_DIR"
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
fi

# Install configurations
for config_dir in "$DOTFILES_DIR"/*; do
    if [ -d "$config_dir" ] && [ "$(basename "$config_dir")" != ".git" ]; then
        config_name=$(basename "$config_dir")
        target_dir="$CONFIG_DIR/$config_name"
        
        log "Installing $config_name configuration"
        
        # Remove existing config
        [ -d "$target_dir" ] && rm -rf "$target_dir"
        
        # Create symlink
        ln -sf "$config_dir" "$target_dir"
    fi
done

log "Dotfiles installation completed"
log "Backup created at: $BACKUP_DIR"
EOF
    
    chmod +x "$DOTFILES_DIR/install.sh"
}

# Backup current configurations
backup_configs() {
    local backup_name="backup-$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "Creating backup: $backup_name"
    mkdir -p "$backup_path"
    
    for config in "${MANAGED_CONFIGS[@]}"; do
        local config_path="$CONFIG_DIR/$config"
        if [ -d "$config_path" ]; then
            cp -r "$config_path" "$backup_path/"
            log "Backed up $config"
        fi
    done
    
    # Create backup info
    cat > "$backup_path/backup-info.txt" << EOF
Backup created: $(date)
Hostname: $(hostname)
User: $(whoami)
Configurations backed up:
$(ls -la "$backup_path" | grep -v "backup-info.txt")
EOF
    
    log "Backup completed: $backup_path"
    echo "$backup_path"
}

# Sync configurations to dotfiles repository
sync_to_dotfiles() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        error "Dotfiles repository not initialized. Run 'init' first."
        return 1
    fi
    
    log "Syncing configurations to dotfiles repository..."
    
    for config in "${MANAGED_CONFIGS[@]}"; do
        local config_path="$CONFIG_DIR/$config"
        local dotfiles_path="$DOTFILES_DIR/$config"
        
        if [ -d "$config_path" ]; then
            # Remove old version
            rm -rf "$dotfiles_path"
            
            # Copy current config
            cp -r "$config_path" "$dotfiles_path"
            
            # Remove sensitive files
            find "$dotfiles_path" -name "*.log" -delete
            find "$dotfiles_path" -name "*.cache" -delete
            find "$dotfiles_path" -name "*history*" -delete
            
            log "Synced $config"
        else
            warn "Configuration $config not found"
        fi
    done
    
    # Update README with current date
    sed -i "s/## Last Updated.*/## Last Updated\n\n$(date)/" "$DOTFILES_DIR/README.md"
    
    cd "$DOTFILES_DIR"
    git add .
    
    if ! git diff --cached --quiet; then
        local commit_msg="Update configurations - $(date '+%Y-%m-%d %H:%M')"
        git commit -m "$commit_msg"
        log "Changes committed to dotfiles repository"
    else
        log "No changes to commit"
    fi
}

# Restore configurations from dotfiles
restore_from_dotfiles() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        error "Dotfiles repository not found"
        return 1
    fi
    
    # Create backup first
    local backup_path=$(backup_configs)
    
    log "Restoring configurations from dotfiles..."
    
    for config in "${MANAGED_CONFIGS[@]}"; do
        local dotfiles_path="$DOTFILES_DIR/$config"
        local config_path="$CONFIG_DIR/$config"
        
        if [ -d "$dotfiles_path" ]; then
            # Remove existing config
            [ -d "$config_path" ] && rm -rf "$config_path"
            
            # Copy from dotfiles
            cp -r "$dotfiles_path" "$config_path"
            
            # Fix permissions
            find "$config_path" -name "*.sh" -exec chmod +x {} \;
            
            log "Restored $config"
        else
            warn "Configuration $config not found in dotfiles"
        fi
    done
    
    log "Configurations restored from dotfiles"
    log "Previous configuration backed up to: $backup_path"
}

# List available themes
list_themes() {
    log "Available themes:"
    
    if [ -d "$THEMES_DIR" ]; then
        find "$THEMES_DIR" -name "*.conf" -o -name "*.css" -o -name "*.json" | while read -r theme_file; do
            local theme_name=$(basename "$theme_file" | sed 's/\.[^.]*$//')
            local theme_type=$(basename "$(dirname "$theme_file")")
            echo "  $theme_type: $theme_name"
        done
    else
        warn "No themes directory found"
    fi
}

# Apply theme
apply_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        # Show theme selection menu
        local themes=$(find "$THEMES_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort)
        theme_name=$(echo "$themes" | rofi -dmenu -p "Select theme")
        [ -z "$theme_name" ] && return 1
    fi
    
    log "Applying theme: $theme_name"
    
    # Apply Hyprland theme
    local hypr_theme="$THEMES_DIR/hyprland/$theme_name.conf"
    if [ -f "$hypr_theme" ]; then
        # Update theme source in hyprland.conf
        sed -i "s|source = .*themes.*|source = $hypr_theme|" "$CONFIG_DIR/hypr/hyprland.conf"
        log "Applied Hyprland theme"
    fi
    
    # Apply Waybar theme
    local waybar_theme="$THEMES_DIR/waybar/$theme_name.css"
    if [ -f "$waybar_theme" ]; then
        cp "$waybar_theme" "$CONFIG_DIR/waybar/style.css"
        log "Applied Waybar theme"
    fi
    
    # Apply Rofi theme
    local rofi_theme="$THEMES_DIR/rofi/$theme_name.rasi"
    if [ -f "$rofi_theme" ]; then
        # Update rofi config
        sed -i "s|@theme \".*\"|@theme \"$rofi_theme\"|" "$CONFIG_DIR/rofi/config.rasi"
        log "Applied Rofi theme"
    fi
    
    # Apply GTK theme
    local gtk_theme="$THEMES_DIR/gtk/$theme_name"
    if [ -d "$gtk_theme" ]; then
        cp -r "$gtk_theme"/* "$CONFIG_DIR/gtk-3.0/" 2>/dev/null
        cp -r "$gtk_theme"/* "$CONFIG_DIR/gtk-4.0/" 2>/dev/null
        log "Applied GTK theme"
    fi
    
    # Reload configurations
    reload_configs
    
    log "Theme '$theme_name' applied successfully"
}

# Create new theme
create_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        theme_name=$(rofi -dmenu -p "Theme name")
        [ -z "$theme_name" ] && return 1
    fi
    
    log "Creating theme: $theme_name"
    
    # Create theme directories
    mkdir -p "$THEMES_DIR"/{hyprland,waybar,rofi,gtk}
    
    # Copy current configurations as base
    cp "$CONFIG_DIR/hypr/themes/current.conf" "$THEMES_DIR/hyprland/$theme_name.conf" 2>/dev/null
    cp "$CONFIG_DIR/waybar/style.css" "$THEMES_DIR/waybar/$theme_name.css" 2>/dev/null
    cp "$CONFIG_DIR/rofi/themes/current.rasi" "$THEMES_DIR/rofi/$theme_name.rasi" 2>/dev/null
    
    log "Theme '$theme_name' created. Edit files in $THEMES_DIR"
}

# Reload configurations
reload_configs() {
    log "Reloading configurations..."
    
    # Reload Hyprland
    hyprctl reload 2>/dev/null && log "Hyprland reloaded"
    
    # Restart Waybar
    pkill waybar
    waybar &
    log "Waybar restarted"
    
    # Restart Dunst
    pkill dunst
    dunst &
    log "Dunst restarted"
}

# Show configuration status
show_status() {
    echo -e "${BLUE}=== Dotfiles Manager Status ===${NC}"
    echo
    
    # Dotfiles repository status
    if [ -d "$DOTFILES_DIR" ]; then
        echo -e "Dotfiles repository: ${GREEN}Initialized${NC}"
        cd "$DOTFILES_DIR"
        local last_commit=$(git log -1 --format="%cr" 2>/dev/null || echo "No commits")
        echo "Last sync: $last_commit"
        
        local changes=$(git status --porcelain 2>/dev/null | wc -l)
        if [ "$changes" -gt 0 ]; then
            echo -e "Uncommitted changes: ${YELLOW}$changes files${NC}"
        else
            echo -e "Repository status: ${GREEN}Clean${NC}"
        fi
    else
        echo -e "Dotfiles repository: ${RED}Not initialized${NC}"
    fi
    
    echo
    
    # Configuration status
    echo "Managed configurations:"
    for config in "${MANAGED_CONFIGS[@]}"; do
        if [ -d "$CONFIG_DIR/$config" ]; then
            echo -e "  $config: ${GREEN}Present${NC}"
        else
            echo -e "  $config: ${RED}Missing${NC}"
        fi
    done
    
    echo
    
    # Backup status
    if [ -d "$BACKUP_DIR" ]; then
        local backup_count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
        echo "Available backups: $backup_count"
        if [ "$backup_count" -gt 0 ]; then
            local latest_backup=$(ls -1t "$BACKUP_DIR" | head -1)
            echo "Latest backup: $latest_backup"
        fi
    else
        echo -e "Backups: ${YELLOW}No backups found${NC}"
    fi
    
    echo
    
    # Theme status
    if [ -d "$THEMES_DIR" ]; then
        local theme_count=$(find "$THEMES_DIR" -name "*.conf" -o -name "*.css" -o -name "*.rasi" | wc -l)
        echo "Available themes: $theme_count"
    else
        echo -e "Themes: ${YELLOW}No themes directory${NC}"
    fi
}

# Clean old backups
clean_backups() {
    local days="${1:-30}"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        warn "No backup directory found"
        return 1
    fi
    
    log "Cleaning backups older than $days days..."
    
    find "$BACKUP_DIR" -type d -name "backup-*" -mtime +$days -exec rm -rf {} \; 2>/dev/null
    
    local remaining=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    log "Cleanup completed. $remaining backups remaining."
}

# Export configurations
export_configs() {
    local export_file="$HOME/dotfiles-export-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    log "Exporting configurations to $export_file"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local export_dir="$temp_dir/dotfiles-export"
    mkdir -p "$export_dir"
    
    # Copy configurations
    for config in "${MANAGED_CONFIGS[@]}"; do
        if [ -d "$CONFIG_DIR/$config" ]; then
            cp -r "$CONFIG_DIR/$config" "$export_dir/"
        fi
    done
    
    # Add system info
    cat > "$export_dir/system-info.txt" << EOF
Export created: $(date)
Hostname: $(hostname)
User: $(whoami)
OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)
Kernel: $(uname -r)
Desktop: Hyprland $(hyprctl version 2>/dev/null | head -1 || echo "Unknown")

Configurations included:
$(ls -la "$export_dir" | grep -v "system-info.txt")
EOF
    
    # Create archive
    tar -czf "$export_file" -C "$temp_dir" "dotfiles-export"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log "Export completed: $export_file"
}

# Import configurations
import_configs() {
    local import_file="$1"
    
    if [ -z "$import_file" ]; then
        import_file=$(rofi -dmenu -p "Path to import file")
        [ -z "$import_file" ] && return 1
    fi
    
    if [ ! -f "$import_file" ]; then
        error "Import file not found: $import_file"
        return 1
    fi
    
    # Create backup first
    local backup_path=$(backup_configs)
    
    log "Importing configurations from $import_file"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    
    # Extract archive
    tar -xzf "$import_file" -C "$temp_dir"
    
    # Find extracted directory
    local extracted_dir=$(find "$temp_dir" -type d -name "*dotfiles*" | head -1)
    
    if [ -z "$extracted_dir" ]; then
        error "Invalid import file format"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Import configurations
    for config_dir in "$extracted_dir"/*; do
        if [ -d "$config_dir" ]; then
            local config_name=$(basename "$config_dir")
            
            # Skip system info file
            [ "$config_name" = "system-info.txt" ] && continue
            
            local target_dir="$CONFIG_DIR/$config_name"
            
            # Remove existing config
            [ -d "$target_dir" ] && rm -rf "$target_dir"
            
            # Copy imported config
            cp -r "$config_dir" "$target_dir"
            
            log "Imported $config_name"
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log "Import completed. Previous configuration backed up to: $backup_path"
    
    # Reload configurations
    reload_configs
}

# Show interactive menu
show_menu() {
    local menu_options="🏠 Status\n📦 Backup Configs\n🔄 Sync to Dotfiles\n📥 Restore from Dotfiles\n🎨 Manage Themes\n📤 Export Configs\n📥 Import Configs\n🧹 Clean Backups\n⚙️ Settings"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "Dotfiles Manager")
    
    case "$selection" in
        "🏠 Status")
            show_status | rofi -dmenu -p "Status"
            ;;
        "📦 Backup Configs")
            backup_configs
            ;;
        "🔄 Sync to Dotfiles")
            sync_to_dotfiles
            ;;
        "📥 Restore from Dotfiles")
            restore_from_dotfiles
            ;;
        "🎨 Manage Themes")
            show_theme_menu
            ;;
        "📤 Export Configs")
            export_configs
            ;;
        "📥 Import Configs")
            import_configs
            ;;
        "🧹 Clean Backups")
            clean_backups
            ;;
        "⚙️ Settings")
            show_settings_menu
            ;;
    esac
}

# Theme management menu
show_theme_menu() {
    local theme_options="📋 List Themes\n🎨 Apply Theme\n🆕 Create Theme\n📝 Edit Theme\n🗑️ Delete Theme"
    
    local selection=$(echo -e "$theme_options" | rofi -dmenu -p "Theme Manager")
    
    case "$selection" in
        "📋 List Themes")
            list_themes | rofi -dmenu -p "Available Themes"
            ;;
        "🎨 Apply Theme")
            apply_theme
            ;;
        "🆕 Create Theme")
            create_theme
            ;;
        "📝 Edit Theme")
            edit_theme
            ;;
        "🗑️ Delete Theme")
            delete_theme
            ;;
    esac
}

# Edit theme
edit_theme() {
    local themes=$(find "$THEMES_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort)
    local theme_name=$(echo "$themes" | rofi -dmenu -p "Select theme to edit")
    
    [ -z "$theme_name" ] && return 1
    
    # Show component selection
    local components="Hyprland\nWaybar\nRofi\nGTK"
    local component=$(echo -e "$components" | rofi -dmenu -p "Edit component")
    
    case "$component" in
        "Hyprland")
            code "$THEMES_DIR/hyprland/$theme_name.conf"
            ;;
        "Waybar")
            code "$THEMES_DIR/waybar/$theme_name.css"
            ;;
        "Rofi")
            code "$THEMES_DIR/rofi/$theme_name.rasi"
            ;;
        "GTK")
            code "$THEMES_DIR/gtk/$theme_name/"
            ;;
    esac
}

# Delete theme
delete_theme() {
    local themes=$(find "$THEMES_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort)
    local theme_name=$(echo "$themes" | rofi -dmenu -p "Select theme to delete")
    
    [ -z "$theme_name" ] && return 1
    
    # Confirmation
    local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Delete theme '$theme_name'?")
    
    if [ "$confirm" = "Yes" ]; then
        rm -f "$THEMES_DIR/hyprland/$theme_name.conf"
        rm -f "$THEMES_DIR/waybar/$theme_name.css"
        rm -f "$THEMES_DIR/rofi/$theme_name.rasi"
        rm -rf "$THEMES_DIR/gtk/$theme_name"
        
        log "Theme '$theme_name' deleted"
    fi
}

# Settings menu
show_settings_menu() {
    local settings_options="📁 Set Dotfiles Directory\n🔧 Edit Managed Configs\n🔄 Reset to Defaults\n📊 Show Disk Usage"
    
    local selection=$(echo -e "$settings_options" | rofi -dmenu -p "Settings")
    
    case "$selection" in
        "📁 Set Dotfiles Directory")
            set_dotfiles_directory
            ;;
        "🔧 Edit Managed Configs")
            edit_managed_configs
            ;;
        "🔄 Reset to Defaults")
            reset_to_defaults
            ;;
        "📊 Show Disk Usage")
            show_disk_usage
            ;;
    esac
}

# Set dotfiles directory
set_dotfiles_directory() {
    local new_dir=$(rofi -dmenu -p "Dotfiles directory" -filter "$DOTFILES_DIR")
    
    if [ -n "$new_dir" ] && [ "$new_dir" != "$DOTFILES_DIR" ]; then
        # Update script configuration
        sed -i "s|DOTFILES_DIR=.*|DOTFILES_DIR=\"$new_dir\"|" "$0"
        log "Dotfiles directory changed to $new_dir"
    fi
}

# Show disk usage
show_disk_usage() {
    local usage_info="📊 Disk Usage Information\n\n"
    
    if [ -d "$CONFIG_DIR" ]; then
        local config_size=$(du -sh "$CONFIG_DIR" 2>/dev/null | cut -f1)
        usage_info+="Config directory: $config_size\n"
    fi
    
    if [ -d "$DOTFILES_DIR" ]; then
        local dotfiles_size=$(du -sh "$DOTFILES_DIR" 2>/dev/null | cut -f1)
        usage_info+="Dotfiles repository: $dotfiles_size\n"
    fi
    
    if [ -d "$BACKUP_DIR" ]; then
        local backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        local backup_count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
        usage_info+="Backups ($backup_count): $backup_size\n"
    fi
    
    if [ -d "$THEMES_DIR" ]; then
        local themes_size=$(du -sh "$THEMES_DIR" 2>/dev/null | cut -f1)
        usage_info+="Themes: $themes_size\n"
    fi
    
    echo -e "$usage_info" | rofi -dmenu -p "Disk Usage"
}

# Reset to defaults
reset_to_defaults() {
    local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Reset all configurations to defaults? This cannot be undone!")
    
    if [ "$confirm" = "Yes" ]; then
        # Create backup first
        local backup_path=$(backup_configs)
        
        log "Resetting configurations to defaults..."
        
        # Remove current configurations
        for config in "${MANAGED_CONFIGS[@]}"; do
            [ -d "$CONFIG_DIR/$config" ] && rm -rf "$CONFIG_DIR/$config"
        done
        
        # Restore from system defaults or dotfiles
        if [ -d "$DOTFILES_DIR" ]; then
            restore_from_dotfiles
        else
            warn "No dotfiles repository found. Manual configuration required."
        fi
        
        log "Reset completed. Previous configuration backed up to: $backup_path"
    fi
}

# Main function
main() {
    # Ensure directories exist
    mkdir -p "$BACKUP_DIR" "$THEMES_DIR"
    
    case "${1:-menu}" in
        "menu") show_menu ;;
        "init") init_dotfiles ;;
        "backup") backup_configs ;;
        "sync") sync_to_dotfiles ;;
        "restore") restore_from_dotfiles ;;
        "status") show_status ;;
        "theme") apply_theme "$2" ;;
        "create-theme") create_theme "$2" ;;
        "list-themes") list_themes ;;
        "export") export_configs ;;
        "import") import_configs "$2" ;;
        "clean") clean_backups "$2" ;;
        "reload") reload_configs ;;
        *)
            echo "Usage: $0 {menu|init|backup|sync|restore|status|theme|create-theme|list-themes|export|import|clean|reload}"
            echo ""
            echo "Commands:"
            echo "  menu         - Show interactive menu"
            echo "  init         - Initialize dotfiles repository"
            echo "  backup       - Backup current configurations"
            echo "  sync         - Sync configurations to dotfiles"
            echo "  restore      - Restore from dotfiles"
            echo "  status       - Show status information"
            echo "  theme [name] - Apply theme"
            echo "  create-theme - Create new theme"
            echo "  list-themes  - List available themes"
            echo "  export       - Export configurations"
            echo "  import [file]- Import configurations"
            echo "  clean [days] - Clean old backups"
            echo "  reload       - Reload configurations"
            exit 1
            ;;
    esac
}

main "$@"
