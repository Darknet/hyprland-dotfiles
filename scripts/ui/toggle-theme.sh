#!/bin/bash

# Theme Toggle Script for Hyprland
# Switches between light and dark themes

CONFIG_DIR="$HOME/.config"
THEME_FILE="$CONFIG_DIR/.current_theme"
WALLPAPER_DIR="$CONFIG_DIR/hypr/wallpapers"

# Theme configurations
DARK_THEME="catppuccin-mocha"
LIGHT_THEME="catppuccin-latte"

# Get current theme
get_current_theme() {
    if [ -f "$THEME_FILE" ]; then
        cat "$THEME_FILE"
    else
        echo "$DARK_THEME"
    fi
}

#
# Set theme colors for Hyprland
set_hyprland_theme() {
    local theme="$1"
    
    if [ "$theme" = "$DARK_THEME" ]; then
        # Dark theme colors
        hyprctl keyword general:col.active_border "rgba(cba6f7ee) rgba(89b4faee) 45deg"
        hyprctl keyword general:col.inactive_border "rgba(6c7086aa)"
        hyprctl keyword decoration:col.shadow "rgba(1e1e2eee)"
        
        # Set dark wallpaper
        if [ -f "$WALLPAPER_DIR/dark.jpg" ]; then
            swww img "$WALLPAPER_DIR/dark.jpg" --transition-type wipe --transition-duration 1
        fi
    else
        # Light theme colors
        hyprctl keyword general:col.active_border "rgba(1e66f5ee) rgba(7287fdee) 45deg"
        hyprctl keyword general:col.inactive_border "rgba(9ca0b0aa)"
        hyprctl keyword decoration:col.shadow "rgba(4c4f69ee)"
        
        # Set light wallpaper
        if [ -f "$WALLPAPER_DIR/light.jpg" ]; then
            swww img "$WALLPAPER_DIR/light.jpg" --transition-type wipe --transition-duration 1
        fi
    fi
}

# Set GTK theme
set_gtk_theme() {
    local theme="$1"
    
    if [ "$theme" = "$DARK_THEME" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-mocha-blue-standard+default"
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
        gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-blue-cursors"
    else
        gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-latte-blue-standard+default"
        gsettings set org.gnome.desktop.interface icon-theme "Papirus"
        gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-latte-blue-cursors"
    fi
}

# Update waybar theme
update_waybar_theme() {
    local theme="$1"
    
    # Restart waybar to apply new theme
    pkill waybar
    sleep 1
    waybar &
}

# Update terminal theme
update_terminal_theme() {
    local theme="$1"
    
    if [ "$theme" = "$DARK_THEME" ]; then
        ln -sf "$CONFIG_DIR/kitty/themes/catppuccin-mocha.conf" "$CONFIG_DIR/kitty/current-theme.conf"
    else
        ln -sf "$CONFIG_DIR/kitty/themes/catppuccin-latte.conf" "$CONFIG_DIR/kitty/current-theme.conf"
    fi
}

# Toggle theme
toggle_theme() {
    local current_theme=$(get_current_theme)
    local new_theme
    
    if [ "$current_theme" = "$DARK_THEME" ]; then
        new_theme="$LIGHT_THEME"
    else
        new_theme="$DARK_THEME"
    fi
    
    echo "Switching to $new_theme theme..."
    
    # Apply theme changes
    set_hyprland_theme "$new_theme"
    set_gtk_theme "$new_theme"
    update_waybar_theme "$new_theme"
    update_terminal_theme "$new_theme"
    
    # Save current theme
    echo "$new_theme" > "$THEME_FILE"
    
    # Send notification
    notify-send "Theme Changed" "Switched to $new_theme theme" -t 3000
    
    echo "Theme changed to: $new_theme"
}

# Main execution
case "${1:-toggle}" in
    "toggle")
        toggle_theme
        ;;
    "dark")
        echo "$DARK_THEME" > "$THEME_FILE"
        set_hyprland_theme "$DARK_THEME"
        set_gtk_theme "$DARK_THEME"
        update_waybar_theme "$DARK_THEME"
        update_terminal_theme "$DARK_THEME"
        notify-send "Theme Changed" "Switched to dark theme" -t 3000
        ;;
    "light")
        echo "$LIGHT_THEME" > "$THEME_FILE"
        set_hyprland_theme "$LIGHT_THEME"
        set_gtk_theme "$LIGHT_THEME"
        update_waybar_theme "$LIGHT_THEME"
        update_terminal_theme "$LIGHT_THEME"
        notify-send "Theme Changed" "Switched to light theme" -t 3000
        ;;
    "status")
        echo "Current theme: $(get_current_theme)"
        ;;
    *)
        echo "Usage: $0 {toggle|dark|light|status}"
        exit 1
        ;;
esac
