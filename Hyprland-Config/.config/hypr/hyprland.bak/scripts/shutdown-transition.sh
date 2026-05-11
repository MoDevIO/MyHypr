#!/usr/bin/env bash
set -euo pipefail

TRANSITION_DIR="$HOME/.config/hypr/hyprland/scripts/theme-transition"
OVERLAY_BIN="$TRANSITION_DIR/theme_overlay"
SHADER_FILE="$TRANSITION_DIR/circle_blackout.frag"
DURATION="${1:-1.25}"
BLACK_HOLD="${2:-0}"

TMP_PREFIX="/tmp/shutdown_transition_$$"
MONITOR_LIST="$TMP_PREFIX.monitors"

declare -a SCREENSHOTS=()
declare -a OVERLAY_PIDS=()

cleanup() {
    rm -f "$MONITOR_LIST"
    if ((${#SCREENSHOTS[@]} > 0)); then
        rm -f "${SCREENSHOTS[@]}"
    fi
}
trap cleanup EXIT INT TERM

if [[ ! -x "$OVERLAY_BIN" ]]; then
    notify-send "Shutdown transition" "Missing $OVERLAY_BIN (run build.sh first)" -t 3000
    exit 1
fi

if [[ ! -f "$SHADER_FILE" ]]; then
    notify-send "Shutdown transition" "Missing shader $SHADER_FILE" -t 3000
    exit 1
fi

# Capture every connected monitor so the blackout animation runs on all displays.
hyprctl monitors -j | jq -r '.[].name' > "$MONITOR_LIST" 2>/dev/null || true

monitor_index=0
while IFS= read -r monitor; do
    [[ -n "$monitor" ]] || continue

    screenshot="$TMP_PREFIX.$monitor_index.ppm"
    if grim -t ppm -o "$monitor" "$screenshot"; then
        SCREENSHOTS+=("$screenshot")
    fi

    monitor_index=$((monitor_index + 1))
done < "$MONITOR_LIST"

if ((${#SCREENSHOTS[@]} == 0)); then
    screenshot="$TMP_PREFIX.fallback.ppm"
    grim -t ppm "$screenshot"
    SCREENSHOTS+=("$screenshot")
fi

for idx in "${!SCREENSHOTS[@]}"; do
    "$OVERLAY_BIN" "${SCREENSHOTS[$idx]}" "$SHADER_FILE" "$DURATION" "$idx" &
    OVERLAY_PIDS+=("$!")
done

# Trigger DPMS while overlay is in its shader black-tail phase (CLOSE_PHASE=0.8).
DPMS_TRIGGER_AT=$(awk -v d="$DURATION" 'BEGIN { printf "%.3f", d * 0.8 }')
sleep "$DPMS_TRIGGER_AT"

# hyprctl dispatch dpms off || true
sleep 1
shutdown now
