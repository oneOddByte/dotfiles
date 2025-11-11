#!/bin/bash
# -------------------------------------------------
#  hyprlock with blurred current wallpaper
# -------------------------------------------------

CACHE_FILE="$HOME/.cache/current_wallpaper"
DEFAULT_WALL="$HOME/Pictures/default.jpg"
BLURRED_WALL="/tmp/hyprlock_blurred_$$.jpg"   # unique temp file

# ---- 1. Get current wallpaper (fallback to default) ----
if [[ -f "$CACHE_FILE" ]]; then
    CURRENT_WALL=$(<"$CACHE_FILE")
else
    CURRENT_WALL="$DEFAULT_WALL"
fi

# ---- 2. Ensure the source image exists ----
if [[ ! -f "$CURRENT_WALL" ]]; then
    echo "Error: Wallpaper not found → $CURRENT_WALL" >&2
    exit 1
fi

# ---- 3. Create blurred version (requires imagemagick) ----
# 4 blur passes + 70 % brightness = the same visual you asked for
if ! magick "$CURRENT_WALL" \
        -blur 0x8 -modulate 100,100,70 \
        -blur 0x8 -modulate 100,100,100 \
        -blur 0x8 -modulate 100,100,100 \
        -blur 0x8 "$BLURRED_WALL" 2>/dev/null; then
    echo "Error: Failed to blur image (imagemagick missing?)" >&2
    exit 1
fi

# ---- 4. Run hyprlock with the blurred image ----
hyprlock --override "background,path=$BLURRED_WALL" || {
    rm -f "$BLURRED_WALL"
    echo "Error: hyprlock failed" >&2
    exit 1
}

# ---- 5. Clean up temp file after unlock ----
rm -f "$BLURRED_WALL"
