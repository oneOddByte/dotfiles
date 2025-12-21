#!/usr/bin/env bash

WAYBAR_CMD="waybar"
HIDDEN=0
SUPER_HELD=0
FLAG="$HOME/.cache/waybar_toggle.lock"

start_waybar() {
    if ! pgrep -x waybar >/dev/null; then
        $WAYBAR_CMD &
        sleep 0.2
    fi
    HIDDEN=0
}

stop_waybar() {
    if pgrep -x waybar >/dev/null; then
        pkill -x waybar
    fi
    HIDDEN=1
}

while true; do
    # Check if toggled-on mode is active
    if [ -f "$FLAG" ]; then
        if [ "$HIDDEN" -eq 1 ]; then
            start_waybar
        fi
        sleep 0.1
        continue
    fi

    # Auto mode behavior
    read X Y <<< $(hyprctl cursorpos | awk '{print $1, $2}')
    if (( Y <= 2 )) && [ "$HIDDEN" -eq 1 ]; then
        start_waybar
    elif (( Y > 200 )) && [ "$HIDDEN" -eq 0 ]; then
        stop_waybar
    fi

    sleep 0.05
done

