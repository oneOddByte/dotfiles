#!/usr/bin/env bash
# autohide.sh manages the waybar process.
# This script only flips the FLAG that autohide reads.
exec 9>/tmp/waybar_toggle_flock
flock -n 9 || exit 0   # drop rapid re-presses

FLAG="$HOME/.cache/waybar_toggle.lock"

if [ -f "$FLAG" ]; then
    rm -f "$FLAG"
    pkill waybar          # hide immediately; autohide will re-show on hover
    sleep 0.5             # debounce so a quick re-press doesn't re-pin
else
    ~/.config/waybar/wal-reload.sh  # refresh colors.css from cached palette
    touch "$FLAG"                   # autohide.sh will start waybar with fresh colors
fi
