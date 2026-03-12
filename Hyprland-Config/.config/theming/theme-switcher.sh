#!/bin/sh
THEMES_DIR="$HOME/.config/theming/themes"
TRANSITION_DIR="$HOME/.config/hypr/hyprland/scripts/theme-transition"
ENABLE_TRANSITION=true  # set to false to skip the circle-reveal animation

apply_theme() {
    THEME="${1:-grayscale}"

    echo "$THEME" > "$HOME/.config/theming/current-theme"
    [ -f "$HOME/.config/theming/themes/${THEME}/theme.sh" ] && . "$HOME/.config/theming/themes/${THEME}/theme.sh"

    notify-send "Applying Theme..." "$THEME" -t 2000

    THEME_VARS=$(env | grep -o '^THEME_COLOR_[A-Za-z0-9_]*' | sed 's/^/$/g' | tr '\n' ' ')

    # Kitty
    envsubst < "$HOME/.config/kitty/kitty.conf.template" \
            > "$HOME/.config/kitty/kitty.conf"
    for s in /tmp/mykitty.socket-*; do kitty @ --to="unix:$s" load-config 2>/dev/null; done

    # AGS status bar
    envsubst "$THEME_VARS" < "$HOME/.config/ags/status-bar/style.scss.template" \
                           > "$HOME/.config/ags/status-bar/style.scss"
    sass --no-source-map "$HOME/.config/ags/status-bar/style.scss" \
                         "$HOME/.config/ags/status-bar/style.css"
    busctl --user call io.Astal.status-bar /io/Astal/Application io.Astal.Application Request as 1 reload-css

    # Vesktop
    envsubst < "$HOME/.config/vesktop/themes/vesktop.theme.css.template" \
            > "$HOME/.config/vesktop/themes/Vesktop.theme.css"

    # Swaync
    envsubst < "$HOME/.config/swaync/style.css.template" \
            > "$HOME/.config/swaync/style.css"
    swaync-client -rs 2>/dev/null

    # Cava
    envsubst < "$HOME/.config/cava/config.template" \
            > "$HOME/.config/cava/config"

    # Rofi
    envsubst < "$HOME/.config/rofi/colors.rasi.template" \
            > "$HOME/.config/rofi/colors.rasi"

    # Hyprland
    envsubst < "$HOME/.config/hypr/hyprland/design.conf.template" \
            > "$HOME/.config/hypr/hyprland/design.conf"
    hyprctl reload 2>/dev/null

    # Wallpaper (swww) — instant swap, overlay handles the visual transition
    THEME_DIR="$HOME/.config/theming/themes/${THEME}"
    WALLPAPER=$(find "$THEME_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | head -1)
    if [ -n "$WALLPAPER" ]; then
        swww img -o DP-1 "$WALLPAPER" --resize crop \
            --transition-type simple --transition-duration 0 --transition-fps 144
        swww img -o HDMI-A-1 "$WALLPAPER" --resize crop \
            --transition-type simple --transition-duration 0 --transition-fps 144
    fi
}

chosen=$(ls -1 "$THEMES_DIR" | rofi -dmenu -p "Theme" -theme "$HOME/.config/rofi/launcher.rasi")

if [ -n "$chosen" ]; then
    if [ "$ENABLE_TRANSITION" = true ] && [ -x "$TRANSITION_DIR/theme_overlay" ]; then
        # Wait for rofi to fully close before capturing
        sleep 0.2

        # Capture the current screen for the transition overlay (PPM = fast)
        SCREENSHOT="/tmp/theme_transition_$$.ppm"
        monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' 2>/dev/null)
        if [ -n "$monitor" ]; then
            grim -t ppm -o "$monitor" "$SCREENSHOT"
        else
            grim -t ppm "$SCREENSHOT"
        fi

        # Apply the theme immediately behind the frozen overlay
        (sleep 0.05 && apply_theme "$chosen") &

        # Overlay: 1.2s hold (theme applies) + 1.3s circle reveal = 2.5s total
        "$TRANSITION_DIR/theme_overlay" "$SCREENSHOT" "$TRANSITION_DIR/circle_reveal.frag" 2.5

        wait 2>/dev/null
        rm -f "$SCREENSHOT"
    else
        # No animation — apply theme directly
        apply_theme "$chosen"
    fi
fi
