#!/usr/bin/env python3
"""Combined CPU + RAM waybar module. Outputs JSON for return-type: json."""

import time
import json


def cpu_pct() -> int:
    def read():
        with open("/proc/stat") as f:
            vals = list(map(int, f.readline().split()[1:]))
        idle = vals[3] + vals[4]
        return sum(vals), idle

    t1, i1 = read()
    time.sleep(0.5)
    t2, i2 = read()
    dt, di = t2 - t1, i2 - i1
    return int((dt - di) * 100 / dt) if dt else 0


def mem_info() -> tuple[int, float, float]:
    data = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, v = line.split(":")
            data[k.strip()] = int(v.split()[0])
    total = data["MemTotal"]
    used  = total - data["MemAvailable"]
    pct   = used * 100 // total
    return pct, used / 1024 / 1024, total / 1024 / 1024


cpu  = cpu_pct()
mpct, mused, mtotal = mem_info()

css_class = "normal"
if cpu > 90 or mpct > 90:
    css_class = "critical"
elif cpu > 70 or mpct > 70:
    css_class = "warning"

print(json.dumps({
    "text":    f"<span size='x-large'>󰘚</span> {cpu}%  <span size='x-large'>󰍛</span> {mpct}%",
    "tooltip": f"CPU: {cpu}%\nRAM: {mused:.1f} G / {mtotal:.1f} G",
    "class":   css_class,
}))
