#!/usr/bin/env bash
pkill -x rofi && exit 0
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

rofi_style="${ROFI_BTCONNECT_STYLE:-clipboard}"

setup_rofi_config() {
    local font_scale="$ROFI_BTCONNECT_SCALE"
    [[ $font_scale =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}
    local font_name=${ROFI_BTCONNECT_FONT:-$ROFI_FONT}
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
        -theme "$rofi_style" \
        "$@"
}

list_paired_devices() {
    bluetoothctl devices Paired | while IFS= read -r line; do
        local mac name connected
        mac=$(awk '{print $2}' <<< "$line")
        name=$(awk '{$1=""; $2=""; print}' <<< "$line" | sed 's/^ *//')
        connected=$(bluetoothctl info "$mac" | grep -q "Connected: yes" && echo "connected" || echo "disconnected")
        if [[ "$connected" == "connected" ]]; then
            echo "󰂱  $name|$mac"
        else
            echo "󰂯  $name|$mac"
        fi
    done
}

setup_rofi_config

selected=$(list_paired_devices | sort | run_rofi " 󰂯 Bluetooth" -i -display-column-separator "\\|" -display-columns 1)

[ -n "$selected" ] || exit 0

mac=$(list_paired_devices | grep -F "$selected" | head -1 | awk -F'|' '{print $2}')
name="${selected#*  }"

if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
    bluetoothctl disconnect "$mac"
    notify-send -a "HyDE Notify" -r 8 -t 2000 "Bluetooth" "Disconnected: $name"
else
    notify-send -a "HyDE Notify" -r 8 -t 2000 "Bluetooth" "Connecting: $name..."
    if bluetoothctl connect "$mac"; then
        notify-send -a "HyDE Notify" -r 8 -t 2000 "Bluetooth" "Connected: $name"
    else
        notify-send -a "HyDE Notify" -r 8 -t 2000 -u critical "Bluetooth" "Failed to connect: $name"
    fi
fi
