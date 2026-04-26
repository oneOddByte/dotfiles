#!/usr/bin/env bash
# Battery alert daemon — plays sound + sends dunst notification at low levels.
# Launched once by startup.sh; tracks thresholds so each level only alerts once per discharge cycle.

set -u

SOUND="$HOME/.config/hypr/sounds/snorcon-low-battery-charge-421814.mp3"
BAT="${BAT_PATH:-/sys/class/power_supply/BAT0}"
AC="${AC_PATH:-}"
REPEAT_LOW_SECS="${REPEAT_LOW_SECS:-900}"
POLL_SECS="${POLL_SECS:-15}"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/battery_alert.lock"
LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/battery_alert.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$1" >> "$LOG_FILE"
}

# Ensure only one watcher runs per session.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    log "another battery_alert instance is already running; exiting"
    exit 0
fi

if [[ ! -d "$BAT" ]]; then
    BAT="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)"
fi

if [[ -z "${BAT:-}" || ! -d "$BAT" ]]; then
    log "no battery path found, exiting"
    exit 1
fi

if [[ -z "$AC" ]]; then
    AC="$(ls -d /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/ACAD* 2>/dev/null | head -n 1)"
fi

get_ac_online() {
    if [[ -n "$AC" && -r "$AC/online" ]]; then
        cat "$AC/online" 2>/dev/null || echo "0"
    else
        # Fall back to status if no AC supply is exposed.
        local s="$1"
        if [[ "$s" == "Charging" || "$s" == "Full" ]]; then
            echo "1"
        else
            echo "0"
        fi
    fi
}

is_on_battery() {
    local status="$1"
    local ac_online="$2"
    if [[ "$ac_online" == "0" ]]; then
        return 0
    fi
    if [[ "$status" == "Discharging" ]]; then
        return 0
    fi
    if [[ "$status" == "Not charging" && "$ac_online" == "0" ]]; then
        return 0
    fi
    return 1
}

# Alert thresholds (descending). Each fires once per discharge cycle.
THRESHOLDS=(20 10 5)

# Tracks which thresholds have already fired this discharge cycle.
declare -A alerted
last_repeat_low_ts=0

play_sound() {
    mpv --no-terminal --volume=80 "$SOUND" &>/dev/null &
}

send_notification() {
    notify-send "$@" 2>>"$LOG_FILE" || log "notify-send failed"
}

notify_low() {
    local level="$1"
    local urgency="normal"
    local icon="󰁻"

    if   (( level <= 5  )); then urgency="critical"; icon="󰂎";
    elif (( level <= 10 )); then urgency="critical"; icon="󰁺";
    fi

    send_notification \
        --urgency="$urgency" \
        --expire-time=8000 \
        --app-name="Battery" \
        "$icon  Battery Low" \
        "${level}% remaining — plug in your charger"
}

notify_repeat_low() {
    local level="$1"
    send_notification \
        --urgency="normal" \
        --expire-time=6000 \
        --app-name="Battery" \
        "󰁻  Battery Still Low" \
        "${level}% remaining — still discharging"
}

notify_charger_connected() {
    local level="$1"
    send_notification \
        --urgency="low" \
        --expire-time=4000 \
        --app-name="Battery" \
        "󰂄  Charger Connected" \
        "${level}% — charging"
}

prev_status="$(cat "$BAT/status" 2>/dev/null || echo "Unknown")"
prev_ac_online="$(get_ac_online "$prev_status")"
log "started pid=$$ battery_path=$BAT ac_path=${AC:-none} repeat_low_secs=$REPEAT_LOW_SECS poll_secs=$POLL_SECS status=$prev_status ac_online=$prev_ac_online"

while true; do
    capacity=$(cat "$BAT/capacity" 2>/dev/null) || { sleep "$POLL_SECS"; continue; }
    status=$(cat "$BAT/status" 2>/dev/null || echo "Unknown")
    ac_online="$(get_ac_online "$status")"

    # Detect cable insertion directly from AC state transition.
    if [[ "$prev_ac_online" == "0" && "$ac_online" == "1" ]]; then
        notify_charger_connected "$capacity"
        log "charger connected at ${capacity}% (status=$status)"
        # Reset all alerts after plugging in.
        alerted=()
        last_repeat_low_ts=0
    fi

    if ! is_on_battery "$status" "$ac_online"; then
        prev_status="$status"
        prev_ac_online="$ac_online"
        sleep "$POLL_SECS"
        continue
    fi

    prev_status="$status"
    prev_ac_online="$ac_online"

    for threshold in "${THRESHOLDS[@]}"; do
        if (( capacity <= threshold )) && [[ -z "${alerted[$threshold]:-}" ]]; then
            alerted[$threshold]=1
            play_sound
            notify_low "$capacity"
            log "low battery alert fired at ${capacity}% (threshold=${threshold})"
            break  # only fire the highest applicable threshold per cycle
        fi
    done

    # Optional reminder below 20% while still discharging (not for 10/5 critical range).
    now=$(date +%s)
    if (( capacity <= 20 && capacity > 10 )) && (( last_repeat_low_ts == 0 || now - last_repeat_low_ts >= REPEAT_LOW_SECS )); then
        if [[ -n "${alerted[20]:-}" ]]; then
            notify_repeat_low "$capacity"
            log "repeat low battery reminder at ${capacity}%"
            last_repeat_low_ts=$now
        fi
    fi

    sleep "$POLL_SECS"
done
