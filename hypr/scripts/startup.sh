#!/usr/bin/env bash
# startup.sh — run once when Hyprland starts

# give Wayland environment time to initialize
sleep 1

# --------------WALLPAPER----------------------------
# Detect Wayland socket dynamically
WAYLAND_NS="${WAYLAND_DISPLAY:-wayland-0}"

# Kill any old awww-daemon
pkill -x awww-daemon 2>/dev/null

# Start awww-daemon for this namespace
awww-daemon & disown

# Wait for the daemon socket to appear (max 3 seconds)
for i in {1..30}; do
    if [ -S "/run/user/$(id -u)/${WAYLAND_NS}-awww-daemon.sock" ]; then
        break
    fi
    sleep 0.1
done

# Set wallpaper
WALLPAPER="$(find ~/Pictures -type f | shuf -n 1)"
# WALLPAPER="$(find ~/Pictures/mountain_landscape/ -type f | shuf -n 1)"
awww img "$WALLPAPER" --transition-type random --transition-fps 60 &
mkdir -p ~/.cache
echo "$WALLPAPER" > ~/.cache/current_wallpaper


# waybar + autohide script
waybar &
~/.config/waybar/scripts/autohide.sh &

# battery alert sound script
~/.config/hypr/scripts/battery_alert.sh &

# apps
# open on specific workspaces
hyprctl dispatch workspace 2
# brave &

sleep 0.5
hyprctl dispatch workspace 1
ghostty &


