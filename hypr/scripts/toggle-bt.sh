#!/bin/bash
# Floating bluetui toggle — open if not running, close if already open.
# Can be bound to a Hyprland key or called from Waybar.

TITLE="bluetui"

ADDRESS=$(hyprctl clients -j | jq -r --arg t "$TITLE" \
    '.[] | select(.title == $t) | .address' | head -1)

if [ -z "$ADDRESS" ]; then
    ghostty --title="$TITLE" -e bluetui &
else
    hyprctl dispatch closewindow "address:$ADDRESS"
fi
