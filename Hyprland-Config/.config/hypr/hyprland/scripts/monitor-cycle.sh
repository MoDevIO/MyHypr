#!/bin/bash
# Cycle focus between monitors without wrapping
# Usage: monitor-cycle.sh <direction>
#   direction: next | prev

DIRECTION="$1"

# Collect monitor names in the order reported by hyprctl
MON_LIST=($(hyprctl monitors | awk '/^Monitor/{print $2}'))

# Detect which monitor is currently focused
FOCUSED_MON=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

if [ -z "$FOCUSED_MON" ]; then
    exit 1
fi

# find the index of the focused monitor
idx=-1
for i in "${!MON_LIST[@]}"; do
    if [ "${MON_LIST[$i]}" = "$FOCUSED_MON" ]; then
        idx=$i
        break
    fi
done

if [ "$idx" -eq -1 ]; then
    exit 1
fi

case "$DIRECTION" in
    next)
        if [ "$idx" -lt $(( ${#MON_LIST[@]} - 1 )) ]; then
            newidx=$((idx + 1))
        else
            # already at last monitor; do nothing
            exit 0
        fi
        ;;
    prev)
        if [ "$idx" -gt 0 ]; then
            newidx=$((idx - 1))
        else
            # already at first monitor; do nothing
            exit 0
        fi
        ;;
    *)
        exit 1
        ;;
esac

hyprctl dispatch focusmonitor "${MON_LIST[$newidx]}"