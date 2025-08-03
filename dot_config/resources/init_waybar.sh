#!/bin/bash

while true; do
    waybar &
    WAYBAR_PID=$!
    
    sleep 2
    
    if ps -p $WAYBAR_PID > /dev/null; then
        echo "Waybar inició correctamente."
        break
    else
        echo "Waybar falló al iniciar. Reintentando..."
    fi
done

udiskie -s &
# onedrive_tray &
