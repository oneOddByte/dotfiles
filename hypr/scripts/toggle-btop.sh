#!/usr/bin/env bash
# Floating btop toggle — open if not running, close if already open.

TITLE="btop-popup"

ADDRESS=$(hyprctl clients -j | jq -r --arg t "$TITLE" \
    '.[] | select(.title == $t) | .address' | head -1)

if [ -z "$ADDRESS" ]; then
    ghostty --title="$TITLE" -e btop &
else
    hyprctl dispatch closewindow "address:$ADDRESS"
fi
