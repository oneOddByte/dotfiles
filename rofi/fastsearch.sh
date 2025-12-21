#!/usr/bin/env bash

PRIORITY_DIRS=(
    "$HOME/Downloads"
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Dev"
)

CACHE_FILE="/tmp/rofi_unified_cache_$USER"
CACHE_AGE=300  # 5 minutes

# Rebuild cache if old or missing
if [[ ! -f "$CACHE_FILE" ]] || [[ $(find "$CACHE_FILE" -mmin +5 2>/dev/null) ]]; then
    > "$CACHE_FILE"
    
    # Add all apps
    for dir in "/usr/share/applications" "$HOME/.local/share/applications"; do
        [[ -d "$dir" ]] || continue
        find "$dir" -name "*.desktop" 2>/dev/null | while read -r file; do
            name=$(grep -m1 "^Name=" "$file" 2>/dev/null | cut -d= -f2)
            [[ -n "$name" ]] && echo "[APP] $name|$file" >> "$CACHE_FILE"
        done
    done
    
    # Add all recent files from priority dirs
    for dir in "${PRIORITY_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        fd -H -t f -d 4 . "$dir" 2>/dev/null | while read -r f; do
            echo "[FILE] $f|$f" >> "$CACHE_FILE"
        done
    done
fi

# Show everything and let rofi filter live
SELECTION=$(cat "$CACHE_FILE" | cut -d'|' -f1 | \
    rofi -dmenu -i -p "Search" -matching fuzzy)

[[ -z "$SELECTION" ]] && exit 0

# Get the path
PATH=$(grep -F "$SELECTION|" "$CACHE_FILE" | head -1 | cut -d'|' -f2)

# Open it
if [[ "$PATH" == *.desktop ]]; then
    gtk-launch "$(basename "$PATH" .desktop)" 2>/dev/null &
else
    xdg-open "$PATH" 2>/dev/null &
fi
