#!/usr/bin/env bash

WAYBAR_CMD="waybar"
WAYBAR_PID=$(pgrep -x waybar)

# Start Waybar if not running
if [ -z "$WAYBAR_PID" ]; then
    $WAYBAR_CMD &
    sleep 0.3
    WAYBAR_PID=$(pgrep -x waybar)
fi

HIDDEN=0

while true; do
    # Get cursor position (x and y)
    read X Y <<< $(hyprctl cursorpos | awk '{print $1, $2}')
    
    if (( Y <= 2 )) && [ $HIDDEN -eq 1 ]; then
        $WAYBAR_CMD &
        HIDDEN=0
    elif (( Y > 30 )) && [ $HIDDEN -eq 0 ]; then
        pkill -x waybar
        HIDDEN=1
    fi
    
    sleep 0.05
done

