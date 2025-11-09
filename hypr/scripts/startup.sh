#!/usr/bin/env bash
# startup.sh — run once when Hyprland starts

# give Wayland environment time to initialize
sleep 1

# --------------WALLPAPER----------------------------
# Detect Wayland socket dynamically
WAYLAND_NS="${WAYLAND_DISPLAY:-wayland-0}"

# Kill any old swww-daemon
pkill -x swww-daemon 2>/dev/null

# Start swww-daemon for this namespace
swww-daemon & disown

# Wait for the daemon socket to appear (max 3 seconds)
for i in {1..30}; do
    if [ -S "/run/user/$(id -u)/${WAYLAND_NS}-swww-daemon.sock" ]; then
        break
    fi
    sleep 0.1
done

# Set wallpaper
swww img "$(find ~/Pictures -type f | shuf -n 1)" &


# waybar + autohide script
waybar &
~/.config/waybar/scripts/autohide.sh &

# apps
# open on specific workspaces
hyprctl dispatch workspace 1
brave &

sleep 0.5
hyprctl dispatch workspace 2
ghostty &
