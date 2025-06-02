#!/bin/bash

# Advanced Audio Manager for PipeWire/PulseAudio
# Provides audio device management, volume control, and audio routing

# Configuration
CONFIG_DIR="$HOME/.config/audio-manager"
PROFILES_DIR="$CONFIG_DIR/profiles"
PRESETS_DIR="$CONFIG_DIR/presets"

# Create directories
mkdir -p "$PROFILES_DIR" "$PRESETS_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons for notifications
ICON_VOLUME_HIGH="🔊"
ICON_VOLUME_MID="🔉"
ICON_VOLUME_LOW="🔈"
ICON_VOLUME_MUTE="🔇"
ICON_MIC_ON="🎤"
ICON_MIC_MUTE="🎤"

# Logging
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect audio system
detect_audio_system() {
    if command -v wpctl &> /dev/null; then
        echo "pipewire"
    elif command -v pactl &> /dev/null; then
        echo "pulseaudio"
    else
        echo "none"
    fi
}

AUDIO_SYSTEM=$(detect_audio_system)

# Get volume level
get_volume() {
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'
            ;;
        "pulseaudio")
            pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%'
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Set volume level
set_volume() {
    local volume="$1"
    
    # Clamp volume between 0 and 100
    if [ "$volume" -gt 100 ]; then
        volume=100
    elif [ "$volume" -lt 0 ]; then
        volume=0
    fi
    
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "${volume}%"
            ;;
        "pulseaudio")
            pactl set-sink-volume @DEFAULT_SINK@ "${volume}%"
            ;;
    esac
    
    show_volume_notification "$volume"
}

# Increase volume
volume_up() {
    local step="${1:-5}"
    local current_volume=$(get_volume)
    local new_volume=$((current_volume + step))
    
    set_volume "$new_volume"
}

# Decrease volume
volume_down() {
    local step="${1:-5}"
    local current_volume=$(get_volume)
    local new_volume=$((current_volume - step))
    
    set_volume "$new_volume"
}

# Toggle mute
toggle_mute() {
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            ;;
        "pulseaudio")
            pactl set-sink-mute @DEFAULT_SINK@ toggle
            ;;
    esac
    
    show_mute_notification
}

# Check if muted
is_muted() {
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"
            ;;
        "pulseaudio")
            pactl get-sink-mute @DEFAULT_SINK@ | grep -q "yes"
            ;;
        *)
            return 1
            ;;
    esac
}

# Get microphone volume
get_mic_volume() {
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print int($2 * 100)}'
            ;;
        "pulseaudio")
            pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '\d+%' | head -1 | tr -d '%'
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Set microphone volume
set_mic_volume() {
    local volume="$1"
    
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${volume}%"
            ;;
        "pulseaudio")
            pactl set-source-volume @DEFAULT_SOURCE@ "${volume}%"
            ;;
    esac
    
    show_mic_notification "$volume"
}

# Toggle microphone mute
toggle_mic_mute() {
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            ;;
        "pulseaudio")
            pactl set-source-mute @DEFAULT_SOURCE@ toggle
            ;;
    esac
    
    show_mic_mute_notification
}

# Check if microphone is muted
is_mic_muted() {
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q "MUTED"
            ;;
        "pulseaudio")
            pactl get-source-mute @DEFAULT_SOURCE@ | grep -q "yes"
            ;;
        *)
            return 1
            ;;
    esac
}

# Show volume notification
show_volume_notification() {
    local volume="$1"
    local icon="$ICON_VOLUME_HIGH"
    
    if is_muted; then
        icon="$ICON_VOLUME_MUTE"
        notify-send "Volume" "Muted" -i audio-volume-muted -t 2000 -h int:value:0
    else
        if [ "$volume" -eq 0 ]; then
            icon="$ICON_VOLUME_MUTE"
        elif [ "$volume" -lt 30 ]; then
            icon="$ICON_VOLUME_LOW"
        elif [ "$volume" -lt 70 ]; then
            icon="$ICON_VOLUME_MID"
        fi
        
        notify-send "Volume" "${volume}%" -i audio-volume-high -t 2000 -h int:value:"$volume"
    fi
}

# Show mute notification
show_mute_notification() {
    if is_muted; then
        notify-send "Audio" "Muted $ICON_VOLUME_MUTE" -i audio-volume-muted -t 2000
    else
        local volume=$(get_volume)
        notify-send "Audio" "Unmuted ${volume}%" -i audio-volume-high -t 2000
    fi
}

# Show microphone notification
show_mic_notification() {
    local volume="$1"
    notify-send "Microphone" "Volume: ${volume}%" -i audio-input-microphone -t 2000 -h int:value:"$volume"
}

# Show microphone mute notification
show_mic_mute_notification() {
    if is_mic_muted; then
        notify-send "Microphone" "Muted $ICON_MIC_MUTE" -i microphone-sensitivity-muted -t 2000
    else
        local volume=$(get_mic_volume)
        notify-send "Microphone" "Unmuted ${volume}%" -i audio-input-microphone -t 2000
    fi
}

# List audio devices
list_devices() {
    local device_type="${1:-all}"
    
    case "$AUDIO_SYSTEM" in
        "pipewire")
            case "$device_type" in
                "sinks"|"output")
                    wpctl status | sed -n '/Audio/,/Video/p' | grep -E "^\s*[0-9]+\.\s" | grep -v "input"
                    ;;
                "sources"|"input")
                    wpctl status | sed -n '/Audio/,/Video/p' | grep -E "^\s*[0-9]+\.\s" | grep "input"
                    ;;
                "all")
                    wpctl status | sed -n '/Audio/,/Video/p' | grep -E "^\s*[0-9]+\.\s"
                    ;;
            esac
            ;;
        "pulseaudio")
            case "$device_type" in
                "sinks"|"output")
                    pactl list short sinks
                    ;;
                "sources"|"input")
                    pactl list short sources
                    ;;
                "all")
                    echo "=== Output Devices ==="
                    pactl list short sinks
                    echo "=== Input Devices ==="
                    pactl list short sources
                    ;;
            esac
            ;;
    esac
}

# Set default device
set_default_device() {
    local device_id="$1"
    local device_type="$2"
    
    if [ -z "$device_id" ]; then
        error "Device ID required"
        return 1
    fi
    
    case "$AUDIO_SYSTEM" in
        "pipewire")
            wpctl set-default "$device_id"
            ;;
        "pulseaudio")
            case "$device_type" in
                "sink"|"output")
                    pactl set-default-sink "$device_id"
                    ;;
                "source"|"input")
                    pactl set-default-source "$device_id"
                    ;;
            esac
            ;;
    esac
    
    log "Set default device: $device_id"
}

# Interactive device selector
select_device() {
    local device_type="${1:-output}"
    local devices
    
    case "$device_type" in
        "output"|"sink")
            devices=$(list_devices "sinks")
            ;;
        "input"|"source")
            devices=$(list_devices "sources")
            ;;
    esac
    
    local selection=$(echo "$devices" | rofi -dmenu -p "Select $device_type device")
    
    if [ -n "$selection" ]; then
        local device_id=$(echo "$selection" | awk '{print $1}' | tr -d '.')
        set_default_device "$device_id" "$device_type"
    fi
}

# Save audio profile
save_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        profile_name=$(rofi -dmenu -p "Profile name")
        [ -z "$profile_name" ] && return 1
    fi
    
    local profile_file="$PROFILES_DIR/$profile_name.json"
    
    # Get current audio state
    local volume=$(get_volume)
    local mic_volume=$(get_mic_volume)
    local muted=$(is_muted && echo "true" || echo "false")
    local mic_muted=$(is_mic_muted && echo "true" || echo "false")
    
    # Get current devices
    local default_sink default_source
    
    case "$AUDIO_SYSTEM" in
        "pipewire")
            default_sink=$(wpctl status | grep -A1 "Audio" | grep "sink" | head -1 | awk '{print $2}')
            default_source=$(wpctl status | grep -A1 "Audio" | grep "source" | head -1 | awk '{print $2}')
            ;;
        "pulseaudio")
            default_sink=$(pactl get-default-sink)
            default_source=$(pactl get-default-source)
            ;;
    esac
    
    # Create profile
    local profile_data=$(jq -n \
        --arg name "$profile_name" \
        --arg volume "$volume" \
        --arg mic_volume "$mic_volume" \
        --arg muted "$muted" \
        --arg mic_muted "$mic_muted" \
        --arg default_sink "$default_sink" \
        --arg default_source "$default_source" \
        --arg created "$(date -Iseconds)" \
        '{
            name: $name,
            created: $created,
            volume: ($volume | tonumber),
            mic_volume: ($mic_volume | tonumber),
            muted: ($muted == "true"),
            mic_muted: ($mic_muted == "true"),
            default_sink: $default_sink,
            default_source: $default_source
        }')
    
    echo "$profile_data" > "$profile_file"
    log "Audio profile saved: $profile_name"
}

# Load audio profile
load_profile() {
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
    
    log "Loading audio profile: $profile_name"
    
    # Read profile data
    local profile_data=$(cat "$profile_file")
    local volume=$(echo "$profile_data" | jq -r '.volume')
    local mic_volume=$(echo "$profile_data" | jq -r '.mic_volume')
    local muted=$(echo "$profile_data" | jq -r '.muted')
    local mic_muted=$(echo "$profile_data" | jq -r '.mic_muted')
    local default_sink=$(echo "$profile_data" | jq -r '.default_sink')
    local default_source=$(echo "$profile_data" | jq -r '.default_source')
    
    # Apply profile settings
    if [ "$default_sink" != "null" ]; then
        set_default_device "$default_sink" "sink"
    fi
    
    if [ "$default_source" != "null" ]; then
        set_default_device "$default_source" "source"
    fi
    
    set_volume "$volume"
    set_mic_volume "$mic_volume"
    
    if [ "$muted" = "true" ] && ! is_muted; then
        toggle_mute
    elif [ "$muted" = "false" ] && is_muted; then
        toggle_mute
    fi
    
    if [ "$mic_muted" = "true" ] && ! is_mic_muted; then
        toggle_mic_mute
    elif [ "$mic_muted" = "false" ] && is_mic_muted; then
        toggle_mic_mute
    fi
    
    log "Audio profile loaded: $profile_name"
}

# List audio profiles
list_profiles() {
    if [ -d "$PROFILES_DIR" ]; then
        echo "Available audio profiles:"
        ls "$PROFILES_DIR"/*.json 2>/dev/null | while read -r profile_file; do
            local profile_name=$(basename "$profile_file" .json)
            local created=$(jq -r '.created' "$profile_file" 2>/dev/null)
            local date_str=$(date -d "$created" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "Unknown")
            echo "  $profile_name (created: $date_str)"
        done
    else
        echo "No audio profiles found"
    fi
}

# Delete audio profile
delete_profile() {
    local profiles=$(ls "$PROFILES_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//')
    local profile_name=$(echo "$profiles" | rofi -dmenu -p "Delete profile")
    
    if [ -n "$profile_name" ]; then
        local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Delete profile '$profile_name'?")
        
        if [ "$confirm" = "Yes" ]; then
            rm -f "$PROFILES_DIR/$profile_name.json"
            log "Audio profile deleted: $profile_name"
        fi
    fi
}

# Audio equalizer (if available)
show_equalizer() {
    if command -v easyeffects &> /dev/null; then
        easyeffects &
    elif command -v pulseeffects &> /dev/null; then
        pulseeffects &
    else
        warn "No equalizer application found. Install EasyEffects or PulseEffects."
    fi
}

# Audio routing
route_audio() {
    local source="$1"
    local sink="$2"
    
    if [ -z "$source" ] || [ -z "$sink" ]; then
        error "Usage: route_audio <source> <sink>"
        return 1
    fi
    
    case "$AUDIO_SYSTEM" in
        "pipewire")
            pw-link "$source" "$sink"
            ;;
        "pulseaudio")
            # PulseAudio doesn't have direct routing like PipeWire
            warn "Direct audio routing not supported with PulseAudio"
            ;;
    esac
}

# Show audio connections
show_connections() {
    case "$AUDIO_SYSTEM" in
        "pipewire")
            pw-link -l
            ;;
        "pulseaudio")
            pactl list sink-inputs
            echo "---"
            pactl list source-outputs
            ;;
    esac
}

# Audio test
test_audio() {
    local test_type="${1:-speaker}"
    
    case "$test_type" in
        "speaker"|"output")
            log "Testing speakers..."
            speaker-test -t sine -f 1000 -l 1 &
            local test_pid=$!
            sleep 2
            kill $test_pid 2>/dev/null
            ;;
        "microphone"|"input")
            log "Testing microphone (recording 5 seconds)..."
            local test_file="/tmp/mic_test_$(date +%s).wav"
            
            case "$AUDIO_SYSTEM" in
                "pipewire")
                    pw-record --target @DEFAULT_AUDIO_SOURCE@ "$test_file" &
                    ;;
                "pulseaudio")
                    parecord --device=@DEFAULT_SOURCE@ "$test_file" &
                    ;;
            esac
            
            local record_pid=$!
            sleep 5
            kill $record_pid 2>/dev/null
            
            log "Playing back recording..."
            case "$AUDIO_SYSTEM" in
                "pipewire")
                    pw-play "$test_file"
                    ;;
                "pulseaudio")
                    paplay "$test_file"
                    ;;
            esac
            
            rm -f "$test_file"
            ;;
        *)
            error "Unknown test type: $test_type"
            ;;
    esac
}

# Get audio status for status bar
get_status() {
    local volume=$(get_volume)
    local icon="$ICON_VOLUME_HIGH"
    
    if is_muted; then
        icon="$ICON_VOLUME_MUTE"
        echo "$icon Muted"
    else
        if [ "$volume" -eq 0 ]; then
            icon="$ICON_VOLUME_MUTE"
        elif [ "$volume" -lt 30 ]; then
            icon="$ICON_VOLUME_LOW"
        elif [ "$volume" -lt 70 ]; then
            icon="$ICON_VOLUME_MID"
        fi
        
        echo "$icon ${volume}%"
    fi
}

# Get microphone status
get_mic_status() {
    if is_mic_muted; then
        echo "$ICON_MIC_MUTE Muted"
    else
        local volume=$(get_mic_volume)
        echo "$ICON_MIC_ON ${volume}%"
    fi
}

# Show audio information
show_audio_info() {
    local info="=== Audio System Information ===\n"
    info+="Audio System: $AUDIO_SYSTEM\n"
    info+="Volume: $(get_volume)%\n"
    info+="Muted: $(is_muted && echo "Yes" || echo "No")\n"
    info+="Microphone: $(get_mic_volume)%\n"
    info+="Mic Muted: $(is_mic_muted && echo "Yes" || echo "No")\n\n"
    
    case "$AUDIO_SYSTEM" in
        "pipewire")
            info+="=== Default Devices ===\n"
            info+="$(wpctl status | grep -A5 "Audio")\n"
            ;;
        "pulseaudio")
            info+="Default Sink: $(pactl get-default-sink)\n"
            info+="Default Source: $(pactl get-default-source)\n"
            ;;
    esac
    
    echo -e "$info" | rofi -dmenu -p "Audio Information"
}

# Interactive volume control
interactive_volume() {
    local current_volume=$(get_volume)
    local new_volume=$(seq 0 5 100 | rofi -dmenu -p "Set volume" -selected-row $((current_volume / 5)))
    
    if [ -n "$new_volume" ]; then
        set_volume "$new_volume"
    fi
}

# Interactive microphone control
interactive_mic() {
    local current_volume=$(get_mic_volume)
    local new_volume=$(seq 0 5 100 | rofi -dmenu -p "Set microphone volume" -selected-row $((current_volume / 5)))
    
    if [ -n "$new_volume" ]; then
        set_mic_volume "$new_volume"
    fi
}

# Show main menu
show_menu() {
    local menu_options="🔊 Volume Control\n🎤 Microphone Control\n🎧 Audio Devices\n📊 Audio Information\n💾 Save Profile\n📂 Load Profile\n🎛️ Equalizer\n🔗 Audio Routing\n🧪 Test Audio\n⚙️ Settings"
    
    local selection=$(echo -e "$menu_options" | rofi -dmenu -p "Audio Manager")
    
    case "$selection" in
        "🔊 Volume Control")
            show_volume_menu
            ;;
        "🎤 Microphone Control")
            show_mic_menu
            ;;
        "🎧 Audio Devices")
            show_device_menu
            ;;
        "📊 Audio Information")
            show_audio_info
            ;;
        "💾 Save Profile")
            save_profile
            ;;
        "📂 Load Profile")
            load_profile
            ;;
        "🎛️ Equalizer")
            show_equalizer
            ;;
        "🔗 Audio Routing")
            show_routing_menu
            ;;
        "🧪 Test Audio")
            show_test_menu
            ;;
        "⚙️ Settings")
            show_settings_menu
            ;;
    esac
}

# Volume control menu
show_volume_menu() {
    local volume_options="🔊 Set Volume\n➕ Volume Up\n➖ Volume Down\n🔇 Toggle Mute\n📊 Current: $(get_volume)%"
    
    local selection=$(echo -e "$volume_options" | rofi -dmenu -p "Volume Control")
    
    case "$selection" in
        "🔊 Set Volume")
            interactive_volume
            ;;
        "➕ Volume Up")
            volume_up
            ;;
        "➖ Volume Down")
            volume_down
            ;;
        "🔇 Toggle Mute")
            toggle_mute
            ;;
    esac
}

# Microphone control menu
show_mic_menu() {
    local mic_options="🎤 Set Volume\n➕ Mic Up\n➖ Mic Down\n🔇 Toggle Mute\n📊 Current: $(get_mic_volume)%"
    
    local selection=$(echo -e "$mic_options" | rofi -dmenu -p "Microphone Control")
    
    case "$selection" in
        "🎤 Set Volume")
            interactive_mic
            ;;
        "➕ Mic Up")
            local current=$(get_mic_volume)
            set_mic_volume $((current + 5))
            ;;
        "➖ Mic Down")
            local current=$(get_mic_volume)
            set_mic_volume $((current - 5))
            ;;
        "🔇 Toggle Mute")
            toggle_mic_mute
            ;;
    esac
}

# Device selection menu
show_device_menu() {
    local device_options="🔊 Select Output Device\n🎤 Select Input Device\n📋 List All Devices\n🔄 Refresh Devices"
    
    local selection=$(echo -e "$device_options" | rofi -dmenu -p "Audio Devices")
    
    case "$selection" in
        "🔊 Select Output Device")
            select_device "output"
            ;;
        "🎤 Select Input Device")
            select_device "input"
            ;;
        "📋 List All Devices")
            list_devices "all" | rofi -dmenu -p "Available Devices"
            ;;
        "🔄 Refresh Devices")
            case "$AUDIO_SYSTEM" in
                "pipewire")
                    systemctl --user restart pipewire
                    ;;
                "pulseaudio")
                    pulseaudio -k && pulseaudio --start
                    ;;
            esac
            ;;
    esac
}

# Audio routing menu
show_routing_menu() {
    local routing_options="🔗 Show Connections\n📡 Route Audio\n🔄 Reset Routing"
    
    local selection=$(echo -e "$routing_options" | rofi -dmenu -p "Audio Routing")
    
    case "$selection" in
        "🔗 Show Connections")
            show_connections | rofi -dmenu -p "Audio Connections"
            ;;
        "📡 Route Audio")
            warn "Interactive routing not implemented yet"
            ;;
        "🔄 Reset Routing")
            case "$AUDIO_SYSTEM" in
                "pipewire")
                    systemctl --user restart pipewire
                    ;;
                "pulseaudio")
                    pulseaudio -k && pulseaudio --start
                    ;;
            esac
            ;;
    esac
}

# Test menu
show_test_menu() {
    local test_options="🔊 Test Speakers\n🎤 Test Microphone\n🎵 Play Test Sound"
    
    local selection=$(echo -e "$test_options" | rofi -dmenu -p "Audio Test")
    
    case "$selection" in
        "🔊 Test Speakers")
            test_audio "speaker"
            ;;
        "🎤 Test Microphone")
            test_audio "microphone"
            ;;
        "🎵 Play Test Sound")
            if [ -f "/usr/share/sounds/alsa/Front_Left.wav" ]; then
                case "$AUDIO_SYSTEM" in
                    "pipewire")
                        pw-play /usr/share/sounds/alsa/Front_Left.wav
                        ;;
                    "pulseaudio")
                        paplay /usr/share/sounds/alsa/Front_Left.wav
                        ;;
                esac
            else
                warn "No test sound file found"
            fi
            ;;
    esac
}

# Settings menu
show_settings_menu() {
    local settings_options="📋 List Profiles\n🗑️ Delete Profile\n🔧 Audio System Info\n📝 Edit Config"
    
    local selection=$(echo -e "$settings_options" | rofi -dmenu -p "Audio Settings")
    
    case "$selection" in
        "📋 List Profiles")
            list_profiles | rofi -dmenu -p "Audio Profiles"
            ;;
        "🗑️ Delete Profile")
            delete_profile
            ;;
        "🔧 Audio System Info")
            show_audio_info
            ;;
        "📝 Edit Config")
            case "$AUDIO_SYSTEM" in
                "pipewire")
                    ${EDITOR:-code} ~/.config/pipewire/
                    ;;
                "pulseaudio")
                    ${EDITOR:-code} ~/.config/pulse/
                    ;;
            esac
            ;;
    esac
}

# Main function
main() {
    case "${1:-menu}" in
        "menu") show_menu ;;
        "volume") 
            case "$2" in
                "up") volume_up "$3" ;;
                "down") volume_down "$3" ;;
                "set") set_volume "$3" ;;
                "toggle") toggle_mute ;;
                "get") get_volume ;;
                *) interactive_volume ;;
            esac
            ;;
        "mic")
            case "$2" in
                "up") 
                    local current=$(get_mic_volume)
                    set_mic_volume $((current + ${3:-5}))
                    ;;
                "down")
                    local current=$(get_mic_volume)
                    set_mic_volume $((current - ${3:-5}))
                    ;;
                "set") set_mic_volume "$3" ;;
                "toggle") toggle_mic_mute ;;
                "get") get_mic_volume ;;
                *) interactive_mic ;;
            esac
            ;;
        "device")
            case "$2" in
                "list") list_devices "$3" ;;
                "select") select_device "$3" ;;
                "set") set_default_device "$3" "$4" ;;
                *) show_device_menu ;;
            esac
            ;;
        "profile")
            case "$2" in
                "save") save_profile "$3" ;;
                "load") load_profile "$3" ;;
                "list") list_profiles ;;
                "delete") delete_profile ;;
                *) echo "Usage: $0 profile {save|load|list|delete} [name]" ;;
            esac
            ;;
        "test") test_audio "$2" ;;
        "status") get_status ;;
        "mic-status") get_mic_status ;;
        "info") show_audio_info ;;
        "equalizer") show_equalizer ;;
        "routing") show_routing_menu ;;
        *)
            echo "Usage: $0 {menu|volume|mic|device|profile|test|status|mic-status|info|equalizer|routing}"
            echo ""
            echo "Volume Control:"
            echo "  volume up [step]      - Increase volume"
            echo "  volume down [step]    - Decrease volume"
            echo "  volume set <level>    - Set volume level"
            echo "  volume toggle         - Toggle mute"
            echo "  volume get            - Get current volume"
            echo "  volume                - Interactive volume control"
            echo ""
            echo "Microphone Control:"
            echo "  mic up [step]         - Increase microphone volume"
            echo "  mic down [step]       - Decrease microphone volume"
            echo "  mic set <level>       - Set microphone level"
            echo "  mic toggle            - Toggle microphone mute"
            echo "  mic get               - Get current microphone volume"
            echo "  mic                   - Interactive microphone control"
            echo ""
            echo "Device Management:"
            echo "  device list [type]    - List audio devices"
            echo "  device select <type>  - Select audio device"
            echo "  device set <id> <type> - Set default device"
            echo "  device                - Device selection menu"
            echo ""
            echo "Profile Management:"
            echo "  profile save [name]   - Save audio profile"
            echo "  profile load [name]   - Load audio profile"
            echo "  profile list          - List available profiles"
            echo "  profile delete        - Delete audio profile"
            echo ""
            echo "Utilities:"
            echo "  test [type]           - Test audio (speaker/microphone)"
            echo "  status                - Get volume status for status bar"
            echo "  mic-status            - Get microphone status"
            echo "  info                  - Show audio system information"
            echo "  equalizer             - Open audio equalizer"
            echo "  routing               - Audio routing menu"
            echo "  menu                  - Show interactive menu"
            exit 1
            ;;
    esac
}

main "$@"
