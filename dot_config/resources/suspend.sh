swayidle -w \
timeout 600 'hyprctl dispatch dpms off' \
timeout 900 'waylock -fork-on-lock' \
timeout 1800 'loginctl suspend' \
resume 'hyprctl dispatch dpms on' \
before-sleep 'waylock -fork-on-lock'
