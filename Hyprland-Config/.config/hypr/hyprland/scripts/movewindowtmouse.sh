#!/usr/bin/env bash

# 1. Get current workspace
current_ws=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .activeWorkspace.id')

# 2. Get a UNIQUE list of window classes (no duplicates, no addresses)
# This is what you will see in wofi
choice=$(hyprctl clients -j | jq -r '.[].class' | sort -u | wofi --dmenu)

if [ -n "$choice" ]; then
    # 3. Find the address of the first window that matches that class
    window_address=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$choice\") | .address" | head -n 1)

    # 4. Summon it to your workspace and move it to the cursor
    hyprctl dispatch movetoworkspace "$current_ws",address:"$window_address"
    hyprctl dispatch focuswindow address:"$window_address"
    hyprctl dispatch movewindow org
fi