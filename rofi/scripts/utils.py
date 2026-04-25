import subprocess
import os
import json
from typing import Optional


def notify(
    title: str,
    message: str,
    replace_id: Optional[int] = None,
    app_name: Optional[str] = "",
    expire_time: int = 1_200,
    urgency: str = "normal",
):
    cmd = ["notify-send"]
    if replace_id:
        cmd.append(f"--replace-id={replace_id}")
    if app_name:
        cmd.append(f"--app-name={app_name}")
    cmd.append(f"--urgency={urgency}")
    cmd.append(f"--expire-time={expire_time}")
    subprocess.run(cmd + [title, message], check=False)


def get_wal_theme_str() -> str:
    """Return a rofi -theme-str string built from pywal colors, or empty string on failure."""
    wal_json = os.path.expanduser("~/.cache/wal/colors.json")
    try:
        with open(wal_json) as f:
            wal = json.load(f)
        bg     = wal["special"]["background"]
        fg     = wal["special"]["foreground"]
        active = wal["colors"]["color2"]
        bg_alt = wal["colors"]["color8"]
        return (
            f"* {{ bg: {bg}; bg-alt: {bg_alt}; fg: {fg}; "
            f"fg-alt: {fg}; active: {active}; "
            f"background-color: {bg}; text-color: {fg}; }}"
        )
    except Exception:
        return ""
