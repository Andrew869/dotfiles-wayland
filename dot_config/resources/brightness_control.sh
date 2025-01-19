#!/bin/bash

send_notification() {
	local brightness=$(brightnessctl get)   # Obtiene el valor actual del brillo
    local max_brightness=$(brightnessctl max)   # Obtiene el valor máximo del brillo
    local percentage=$(( brightness * 100 / max_brightness ))  # Calcula el porcentaje de brillo
    local icon=""

    # Determine icon based on brightness percentage
    if [ "$percentage" -ge 75 ]; then
        icon="brightness-high"
    elif [ "$percentage" -ge 50 ]; then
        icon="brightness-medium"
    elif [ "$percentage" -ge 25 ]; then
        icon="brightness-low"
    else
        icon="brightness-off"
    fi

	notify-send -u low -h string:x-canonical-private-synchronous:brightness "Brightness" "${percentage}%" -h int:value:"$percentage" -i "$icon" -a brightness_control -t 1500
	canberra-gtk-play -i audio-volume-change -d "changevolume"
}

down() {
	brightnessctl -q set +5%
	send_notification
}

up() {
	brightnessctl -q set 5%-
	send_notification
}

case "$1" in
	up) up;;
	down) down;;
esac
