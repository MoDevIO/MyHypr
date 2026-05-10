#!/usr/bin/env bash

# 1. Get current workspace
current_ws=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .activeWorkspace.id')

# 2. Build a list of windows with numbered duplicates by class
declare -A window_addresses
declare -A class_counts
choices=()
while IFS=$'\n' read -r line; do
    class=${line%%||*}
    rest=${line#*||}
    title=${rest%%//*}
    address=${rest#*//}

    class_counts["$class"]=$((class_counts["$class"] + 1))
    idx=${class_counts["$class"]}
    display="$class $idx"
    if [ -n "$title" ] && [ "$title" != "null" ]; then
        display="$display — $title"
    fi

    window_addresses["$display"]="$address"
    choices+=("$display")
done < <(hyprctl clients -j | jq -r '.[] | "\(.class)||\(.title)//\(.address)"')

# 3. Ask the user to pick one specific window
choice=$(printf '%s\n' "${choices[@]}" | wofi --dmenu)

if [ -n "$choice" ] && [ -n "${window_addresses[$choice]}" ]; then
    window_address=${window_addresses[$choice]}

    # 4. Summon it to your workspace and move it to the cursor
    hyprctl dispatch movetoworkspace "$current_ws",address:"$window_address"
    hyprctl dispatch focuswindow address:"$window_address"
    hyprctl dispatch movewindow org
fi