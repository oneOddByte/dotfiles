#!/bin/bash

# 1. Configuration
WALL_DIR="$HOME/Pictures"
CACHE_DIR="$HOME/.cache/wall_engine"
QUEUE_FILE="$CACHE_DIR/queue"
CURRENT_WALL="$CACHE_DIR/current"

mkdir -p "$CACHE_DIR"

# 2. Manage the "Deck" (Queue)
# If queue is empty, find all images and shuffle them into the file
if [ ! -s "$QUEUE_FILE" ]; then
    find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.jpeg" \) | shuf > "$QUEUE_FILE"
fi

# 3. Get the next wallpaper & remove from queue
WP=$(head -n 1 "$QUEUE_FILE")
sed -i '1d' "$QUEUE_FILE"
echo "$WP" > "$CURRENT_WALL"

# 4. Apply Wallpaper (using your awww command)
awww img "$WP" --transition-type random --transition-fps 60 &

# 5. Generate Theme (pywal)
# -n skips setting wall (awww does that), -q is quiet
wal -i "$WP" -n -q -s

# 6. Hooks (Add future features here)
# Example: restart waybar to apply new colors
# ~/.config/waybar/scripts/launch.sh &
