#!/usr/bin/env sh


#// Check if wlogout is already running

if pgrep -x "wlogout" > /dev/null
then
    pkill -x "wlogout"
    exit 0
fi


hypr_border=2

#// set file variables

#scrDir=`dirname "$(realpath "$0")"`
#source $scrDir/globalcontrol.sh
#[ -z "${1}" ] || wlogoutStyle="${1}"
wLayout="/home/andrew/.config/wlogout/layout_1"
wlTmplt="/home/andrew/.config/wlogout/style_1.css"

#// detect monitor res

x_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
y_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .height')
hypr_scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')


#// scale config layout and style

wlColms=6
export mgn=$(( y_mon * 28 / hypr_scale ))
export hvr=$(( y_mon * 23 / hypr_scale ))

#// scale font size

export fntSize=$(( y_mon * 2 / 100 ))


export BtnCol="white"


#// eval hypr border radius

export active_rad=$(( hypr_border * 5 ))
export button_rad=$(( hypr_border * 8 ))


#// eval config files

wlStyle="$(envsubst < $wlTmplt)"


#// launch wlogout

wlogout -b "${wlColms}" -c 0 -r 0 -m 0 --layout "${wLayout}" --css <(echo "${wlStyle}") --protocol layer-shell

