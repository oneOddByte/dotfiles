#!/bin/bash

WAYBAR_PID=$(pgrep -x waybar)
HIDDEN=1

while true; do
    read -r X Y < <(swaymsg -t get_cursor_position | jq -r '.x, .y')
    
    if (( Y < 5 )) && [ $HIDDEN -eq 1 ]; then
        # show Waybar
        hyprctl dispatch exec "kill -CONT $WAYBAR_PID"
        HIDDEN=0
    elif (( Y > 50 )) && [ $HIDDEN -eq 0 ]; then
        # hide Waybar
        hyprctl dispatch exec "kill -STOP $WAYBAR_PID"
        HIDDEN=1
    fi
    sleep 0.05
done

