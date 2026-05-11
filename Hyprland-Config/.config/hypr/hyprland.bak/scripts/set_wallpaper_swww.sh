#!/usr/bin/env bash

# 1. WAIT FOR HYPRLAND
# Ensures the script doesn't fire before the compositor is ready
while [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; do
    sleep 0.1
done

# 2. START AND WAIT FOR AWWW-DAEMON
# Checks if daemon is running; if not, starts it.
if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon &
fi

# CRITICAL: Wait until the awww socket is actually responding to commands.
# This fixes the "failed to find wayland buffer" error.
until awww query &>/dev/null; do
    sleep 0.1
done

# 3. CONFIGURATION
# Initial black screen (instant)
BLACK_ARGS=(
    --transition-type none
    --transition-duration 0
)

# Transition for DP-1 (Grow from center)
TRANSITION_ARGS_1=(
    --transition-type grow
    --transition-pos 0.5,0.5
    --transition-duration 1.2
    --transition-fps 144
)

# Transition for HDMI-A-1 (Simple fade)
TRANSITION_ARGS_2=(
    --transition-type simple
    --transition-fps 144
)

# Path to your images
BLACK_IMG="$HOME/.config/hypr/black-wallpaper.ppm"
CURRENT_THEME=$(cat "$HOME/.config/theming/current-theme" 2>/dev/null || echo "grayscale")
THEME_DIR="$HOME/.config/theming/themes/$CURRENT_THEME"
WALLPAPER=$(find "$THEME_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | head -1)
WALLPAPER="${WALLPAPER:-$HOME/.config/hypr/wallpapers/macos_minimal.jpg}"

# 4. EXECUTION

# Set monitors to black initially to clear any old framebuffers
awww img -o DP-1 "$BLACK_IMG" --resize crop "${BLACK_ARGS[@]}"
awww img -o HDMI-A-1 "$BLACK_IMG" --resize crop "${BLACK_ARGS[@]}"

# Small buffer to ensure the black screen is rendered
sleep 0.3

# Transition to the actual wallpaper
awww img -o DP-1 "$WALLPAPER" --resize crop "${TRANSITION_ARGS_1[@]}"
awww img -o HDMI-A-1 "$WALLPAPER" --resize crop "${TRANSITION_ARGS_2[@]}"