#!/usr/bin/env bash
# Battery alert daemon — plays sound + sends dunst notification at low levels.
# Launched once by startup.sh; tracks thresholds so each level only alerts once per discharge cycle.

SOUND="$HOME/.config/hypr/sounds/snorcon-low-battery-charge-421814.mp3"
BAT="/sys/class/power_supply/BAT0"

# Alert thresholds (descending). Each fires once per discharge cycle.
THRESHOLDS=(20 10 5)

# Tracks which thresholds have already fired this discharge cycle.
declare -A alerted

play_sound() {
    mpv --no-terminal --volume=80 "$SOUND" &>/dev/null &
}

notify_low() {
    local level="$1"
    local urgency="normal"
    local icon="󰁻"

    if   (( level <= 5  )); then urgency="critical"; icon="󰂎";
    elif (( level <= 10 )); then urgency="critical"; icon="󰁺";
    fi

    notify-send \
        --urgency="$urgency" \
        --expire-time=8000 \
        --app-name="Battery" \
        "$icon  Battery Low" \
        "${level}% remaining — plug in your charger"
}

prev_status=""

while true; do
    capacity=$(cat "$BAT/capacity" 2>/dev/null) || { sleep 60; continue; }
    status=$(cat "$BAT/status" 2>/dev/null)

    if [[ "$status" != "Discharging" ]]; then
        # Notify once when charger is plugged in
        if [[ "$prev_status" == "Discharging" ]]; then
            notify-send \
                --urgency="low" \
                --expire-time=4000 \
                --app-name="Battery" \
                "󰂄  Charger Connected" \
                "${capacity}% — charging"
        fi
        # Reset all alerts when charging or full
        alerted=()
        prev_status="$status"
        sleep 60
        continue
    fi

    prev_status="$status"

    for threshold in "${THRESHOLDS[@]}"; do
        if (( capacity <= threshold )) && [[ -z "${alerted[$threshold]}" ]]; then
            alerted[$threshold]=1
            play_sound
            notify_low "$capacity"
            break  # only fire the highest applicable threshold per cycle
        fi
    done

    sleep 60
done
