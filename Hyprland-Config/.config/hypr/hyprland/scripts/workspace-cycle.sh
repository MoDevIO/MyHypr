#!/bin/bash
# Cycle workspaces on the currently focused monitor
# Usage: workspace-cycle.sh <direction>
#   direction: next | prev

DIRECTION="$1"

# Detect which monitor is focused
FOCUSED_MON=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

if [ "$FOCUSED_MON" = "DP-1" ]; then
    MIN=1
    MAX=5
elif [ "$FOCUSED_MON" = "HDMI-A-1" ]; then
    MIN=6
    MAX=10
else
    exit 1
fi

# Get current workspace on the focused monitor
CURRENT=$(hyprctl monitors | grep -A 8 "Monitor $FOCUSED_MON" | grep "active workspace:" | grep -oP 'active workspace: \K[0-9]+')

if [ -z "$CURRENT" ]; then
    CURRENT=$MIN
fi

if [ "$DIRECTION" = "next" ]; then
    NEXT=$((CURRENT + 1))
    [ "$NEXT" -gt "$MAX" ] && NEXT=$MIN
elif [ "$DIRECTION" = "prev" ]; then
    NEXT=$((CURRENT - 1))
    [ "$NEXT" -lt "$MIN" ] && NEXT=$MAX
else
    exit 1
fi

hyprctl dispatch workspace "$NEXT"
