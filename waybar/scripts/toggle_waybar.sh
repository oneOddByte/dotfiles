#!/usr/bin/env bash

FLAG="$HOME/.cache/waybar_toggle.lock"

if [ -f "$FLAG" ]; then
    rm -f "$FLAG"
    pkill waybar
else
    touch "$FLAG"
    waybar &
fi

