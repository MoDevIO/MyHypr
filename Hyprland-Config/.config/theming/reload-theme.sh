#!/bin/sh
# source the palette

# --- Select Theme ---
THEME="grayscale"
# --- ---  --  --- ---

# If available load theme from argument
THEME="${1:-$THEME}"

# Persist current theme name for other scripts (wallpaper, etc.)
echo "$THEME" > "$HOME/.config/theming/current-theme"

[ -f "$HOME/.config/theming/themes/${THEME}/theme.sh" ] && . "$HOME/.config/theming/themes/${THEME}/theme.sh"

notify-send "Applying Theme..." "$THEME" -t 2000

# Build list of THEME_COLOR_* vars for selective envsubst (avoids clobbering SCSS $vars)
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

# Wallpaper (swww)
THEME_DIR="$HOME/.config/theming/themes/${THEME}"
WALLPAPER=$(find "$THEME_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | head -1)
if [ -n "$WALLPAPER" ]; then
    swww img -o DP-1 "$WALLPAPER" --resize crop \
        --transition-type simple --transition-duration 0 --transition-fps 144
    swww img -o HDMI-A-1 "$WALLPAPER" --resize crop \
        --transition-type simple --transition-duration 0 --transition-fps 144
fi



