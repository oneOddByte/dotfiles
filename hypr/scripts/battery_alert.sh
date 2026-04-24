#!/bin/bash

THRESHOLD=20
ALERT_PLAYED=false

while true; do
    BATTERY=$(cat /sys/class/power_supply/BAT0/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT0/status)

    if [ "$BATTERY" -le "$THRESHOLD" ] && [ "$STATUS" = "Discharging" ]; then
        if [ "$ALERT_PLAYED" = false ]; then
            pw-play ./../sounds/snorcon-low-battery-charge-421814.mp3  # or mpv, paplay, aplay
            ALERT_PLAYED=true
        fi
    else
        ALERT_PLAYED=false  # reset so it alerts again next discharge cycle
    fi

    sleep 120
done
