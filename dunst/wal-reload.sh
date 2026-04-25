#!/usr/bin/env python3
"""
Reads pywal colors and rewrites the WAL_COLORS_START…WAL_COLORS_END block
in dunstrc, then restarts dunst.
"""

import json
import os
import re
import subprocess

DUNSTRC = os.path.expanduser("~/.config/dunst/dunstrc")
WAL_JSON = os.path.expanduser("~/.cache/wal/colors.json")


def load_colors():
    with open(WAL_JSON) as f:
        wal = json.load(f)
    bg      = wal["special"]["background"]
    fg      = wal["special"]["foreground"]
    dim     = wal["colors"]["color8"]   # muted mid-tone
    accent  = wal["colors"]["color2"]   # main accent (frame_color normal)
    accent2 = "#ff5555"                 # hardcoded red — always critical
    muted   = wal["colors"]["color3"]   # subdued (low urgency frame)
    return bg, fg, dim, accent, accent2, muted


def build_color_block(bg, fg, dim, accent, accent2, muted):
    return f"""\
# WAL_COLORS_START

[urgency_low]
    background = "{bg}"
    foreground = "{dim}"
    frame_color = "{muted}"
    highlight = "{muted}"
    timeout = 4

[urgency_normal]
    background = "{bg}"
    foreground = "{fg}"
    frame_color = "{accent}"
    highlight = "{accent}"
    timeout = 6

[urgency_critical]
    background = "{bg}"
    foreground = "{fg}"
    frame_color = "{accent2}"
    highlight = "{accent2}"
    timeout = 0

# WAL_COLORS_END"""


def update_dunstrc(new_block: str):
    with open(DUNSTRC) as f:
        content = f.read()
    updated = re.sub(
        r"# WAL_COLORS_START.*?# WAL_COLORS_END",
        new_block,
        content,
        flags=re.DOTALL,
    )
    with open(DUNSTRC, "w") as f:
        f.write(updated)


def restart_dunst():
    subprocess.run(["pkill", "-x", "dunst"], capture_output=True)
    subprocess.Popen(
        ["dunst"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


if __name__ == "__main__":
    try:
        colors = load_colors()
        block = build_color_block(*colors)
        update_dunstrc(block)
        restart_dunst()
        print("dunst reloaded with new pywal colors.")
    except Exception as e:
        print(f"wal-reload: {e}")
