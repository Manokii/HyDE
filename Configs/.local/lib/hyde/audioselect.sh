#!/usr/bin/env bash
pkill -x rofi && exit 0
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

cliphist_style="${ROFI_AUDIOSELECT_STYLE:-clipboard}"

setup_rofi_config() {
    local font_scale="$ROFI_AUDIOSELECT_SCALE"
    [[ $font_scale =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}
    local font_name=${ROFI_AUDIOSELECT_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} $font_scale\";}"
    local hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    rofi_position="window { location: center; anchor: center; }"
    local hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
}

run_rofi() {
    local placeholder="$1"
    shift
    rofi -dmenu \
        -theme-str "entry { placeholder: \"$placeholder\";}" \
        -theme-str "$font_override" \
        -theme-str "$r_override" \
        -theme-str "$rofi_position" \
        -theme "$cliphist_style" \
        "$@"
}

use_pipewire=false
if pactl info 2>/dev/null | grep -q "PipeWire"; then
    use_pipewire=true
fi

iconsDir="${iconsDir:-$XDG_DATA_HOME/icons}"
icodir="$iconsDir/Wallbash-Icon/media"

list_sinks() {
    if [[ $use_pipewire == true ]]; then
        pw-dump | jq -r '.[] | select(.info?.props?."media.class" == "Audio/Sink") | .info?.props?."node.description"' | sort
    else
        pactl list sinks | grep -ie "Description:" | awk -F ': ' '{print $2}' | sort
    fi
}

list_sources() {
    if [[ $use_pipewire == true ]]; then
        pw-dump | jq -r '.[] | select(.info?.props?."media.class" == "Audio/Source") | .info?.props?."node.description"' | sort
    else
        pactl list sources | grep -ie "Description:" | awk -F ': ' '{print $2}' | sort
    fi
}

get_default_sink() {
    if [[ $use_pipewire == true ]]; then
        wpctl inspect @DEFAULT_AUDIO_SINK@ | grep -oP 'node.description = "\K[^"]+' | head -1
    else
        pamixer --get-default-sink | awk -F '"' 'END{print $(NF - 1)}'
    fi
}

get_default_source() {
    if [[ $use_pipewire == true ]]; then
        wpctl inspect @DEFAULT_AUDIO_SOURCE@ | grep -oP 'node.description = "\K[^"]+' | head -1
    else
        pamixer --list-sources | awk -F '"' 'END {print $(NF - 1)}'
    fi
}

set_sink() {
    local selection="$1"
    if [[ $use_pipewire == true ]]; then
        local device
        device=$(pw-dump | sel="$selection" jq -r '.[] | select(.info?.props?."media.class" == "Audio/Sink" and .info?.props?."node.description" == env.sel) | .info?.props?."object.id"' | xargs)
        wpctl set-default "$device"
    else
        local device
        device=$(pactl list sinks | grep -C2 -F "Description: $selection" | grep Name | cut -d: -f2 | xargs)
        pactl set-default-sink "$device"
    fi
    notify-send -a "HyDE Notify" -r 8 -t 2000 -i "$icodir/unmuted-speaker.svg" "Audio Output" "$selection"
}

set_source() {
    local selection="$1"
    if [[ $use_pipewire == true ]]; then
        local device
        device=$(pw-dump | sel="$selection" jq -r '.[] | select(.info?.props?."media.class" == "Audio/Source" and .info?.props?."node.description" == env.sel) | .info?.props?."object.id"' | xargs)
        wpctl set-default "$device"
    else
        local device
        device=$(pactl list sources | grep -C2 -F "Description: $selection" | grep Name | cut -d: -f2 | xargs)
        pactl set-default-source "$device"
    fi
    notify-send -a "HyDE Notify" -r 8 -t 2000 -i "$icodir/unmuted-microphone.svg" "Audio Input" "$selection"
}

select_sink() {
    local default_sink
    default_sink=$(get_default_sink)
    local selected
    selected=$(list_sinks | while IFS= read -r sink; do
        if [[ "$sink" == "$default_sink" ]]; then
            echo "󰕾  $sink"
        else
            echo "󰖀  $sink"
        fi
    done | run_rofi " 󰕾 Audio Output" -i -selected-row "$(list_sinks | grep -n "$default_sink" | cut -d: -f1 | awk '{print $1 - 1}')")

    [ -n "$selected" ] || exit 0
    selected="${selected#*  }"
    set_sink "$selected"
}

select_source() {
    local default_source
    default_source=$(get_default_source)
    local selected
    selected=$(list_sources | while IFS= read -r source; do
        if [[ "$source" == "$default_source" ]]; then
            echo "󰍬  $source"
        else
            echo "󰍮  $source"
        fi
    done | run_rofi " 󰍬 Audio Input" -i -selected-row "$(list_sources | grep -n "$default_source" | cut -d: -f1 | awk '{print $1 - 1}')")

    [ -n "$selected" ] || exit 0
    selected="${selected#*  }"
    set_source "$selected"
}

setup_rofi_config

case "${1:-}" in
    sink|output|-o)   select_sink ;;
    source|input|-i)  select_source ;;
    *)
        echo "Usage: $(basename "$0") <sink|source>"
        echo "  sink/output/-o    Select audio output device"
        echo "  source/input/-i   Select audio input device"
        exit 1
        ;;
esac
