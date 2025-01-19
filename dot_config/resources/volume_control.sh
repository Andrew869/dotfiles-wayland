#!/bin/bash

send_notification() {
	local volume=$(pamixer --get-volume)

 	local icon=""

	if [ "$volume" -ge 75 ]; then
        icon="audio-volume-high"
    elif [ "$volume" -ge 50 ]; then
        icon="audio-volume-medium"
    elif [ "$volume" -ge 25 ]; then
        icon="audio-volume-low"
    else
        icon="audio-volume-muted"
    fi

	notify-send -u low -h string:x-canonical-private-synchronous:volume "Volume" "${volume}%" -h int:value:"$volume" -i "$icon" -a volume_control -t 1500 
	canberra-gtk-play -i audio-volume-change -d "changevolume"
}

down() {
	pamixer -d 5
	send_notification
}

up() {
	pamixer -i 5
	send_notification
}

mute() {
	muted="$(pamixer --get-mute)"
	if $muted; then
		pamixer -u
		send_notification
	else 
		pamixer -m
		notify-send -u low -h string:x-canonical-private-synchronous:volume "Volume" ""Muted"" -i audio-volume-muted -a volume_control -t 1500
	fi
}

case "$1" in
	up) up;;
	down) down;;
	mute) mute;;
esac

