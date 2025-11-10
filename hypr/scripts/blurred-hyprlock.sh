#!/bin/bash

# Get the current wallpaper path
CURRENT_WALL=$(cat ~/.cache/current_wallpaper 2>/dev/null)

# Fallback if missing
if [[ ! -f "$CURRENT_WALL" ]]; then
    CURRENT_WALL="$HOME/Pictures/default.jpg"
fi

# Run hyprlock with blur
hyprlock --override "background,path=$CURRENT_WALL" \
         --override "background,blur_passes=4" \
         --override "background,brightness=0.7"
