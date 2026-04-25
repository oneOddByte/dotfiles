#!/usr/bin/env bash

FLAG="$HOME/.cache/waybar_toggle.lock"

if [ -f "$FLAG" ]; then
    rm -f "$FLAG"
    pkill waybar
else
    touch "$FLAG"
    # regenerate colors.css from latest pywal palette before starting
    wal -R -s -o ~/.config/waybar/wal-reload.sh -o ~/.config/dunst/wal-reload.sh
fi

