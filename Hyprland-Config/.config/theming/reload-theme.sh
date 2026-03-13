#!/bin/sh
# source the palette

# --- Select Theme ---
THEME="grayscale"
# --- ---  --  --- ---

# If available load theme from argument
THEME="${1:-$THEME}"

update_vscode_colors() (
        set -eu

        SETTINGS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json"
        TEMPLATE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/theming/vscode-color-customizations.json.template"

        [ -f "$TEMPLATE_FILE" ] || exit 0

        VSCODE_THEME_VARS=$(env | grep -o '^THEME_COLOR_[A-Za-z0-9_]*' | sed 's/^/${/;s/$/}/' | tr '\n' ' ')
        rendered_file=$(mktemp)
        output_file=$(mktemp)

        cleanup() {
                rm -f "$rendered_file" "$output_file"
        }
        trap cleanup EXIT INT TERM

        envsubst "$VSCODE_THEME_VARS" < "$TEMPLATE_FILE" > "$rendered_file"
        mkdir -p "$(dirname "$SETTINGS_FILE")"

        if [ ! -f "$SETTINGS_FILE" ] || [ ! -s "$SETTINGS_FILE" ]; then
                {
                        echo "{"
                        cat "$rendered_file"
                        echo "}"
                } > "$SETTINGS_FILE"
                exit 0
        fi

        if awk -v replacement_file="$rendered_file" '
        function brace_delta(str,    i, ch, delta, in_string, escaped) {
                delta = 0
                in_string = 0
                escaped = 0
                for (i = 1; i <= length(str); i++) {
                        ch = substr(str, i, 1)
                        if (escaped) {
                                escaped = 0
                                continue
                        }
                        if (ch == "\\" && in_string) {
                                escaped = 1
                                continue
                        }
                        if (ch == "\"") {
                                in_string = !in_string
                                continue
                        }
                        if (!in_string) {
                                if (ch == "{") {
                                        delta++
                                } else if (ch == "}") {
                                        delta--
                                }
                        }
                }
                return delta
        }

        function print_replacement(with_comma,    i) {
                for (i = 1; i <= replacement_count; i++) {
                        if (with_comma && i == replacement_count) {
                                print replacement_lines[i] ","
                        } else {
                                print replacement_lines[i]
                        }
                }
        }

        BEGIN {
                replacement_count = 0
                while ((getline line < replacement_file) > 0) {
                        replacement_lines[++replacement_count] = line
                }
                close(replacement_file)
                in_block = 0
                depth = 0
                replaced = 0
        }

        in_block == 0 && /"workbench\.colorCustomizations"[[:space:]]*:/ {
                replaced = 1
                in_block = 1
                depth = brace_delta($0)
                next
        }

        in_block == 1 {
                depth += brace_delta($0)
                if (depth <= 0) {
                        if ($0 ~ /}[[:space:]]*,[[:space:]]*$/) {
                                print_replacement(1)
                        } else {
                                print_replacement(0)
                        }
                        in_block = 2
                }
                next
        }

        {
                print
        }

        END {
                if (!replaced) {
                        exit 2
                }
        }
        ' "$SETTINGS_FILE" > "$output_file"; then
                mv "$output_file" "$SETTINGS_FILE"
                exit 0
        fi

        status=$?
        if [ "$status" -ne 2 ]; then
                exit "$status"
        fi

        awk -v replacement_file="$rendered_file" '
        BEGIN {
                replacement_count = 0
                while ((getline line < replacement_file) > 0) {
                        replacement_lines[++replacement_count] = line
                }
                close(replacement_file)
                inserted = 0
        }

        NR == 1 && /^[[:space:]]*\{/ {
                print
                for (i = 1; i <= replacement_count; i++) {
                        if (i == replacement_count) {
                                print replacement_lines[i] ","
                        } else {
                                print replacement_lines[i]
                        }
                }
                inserted = 1
                next
        }

        {
                print
        }

        END {
                if (!inserted) {
                        exit 2
                }
        }
        ' "$SETTINGS_FILE" > "$output_file"

        mv "$output_file" "$SETTINGS_FILE"
)

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

# VS Code
update_vscode_colors 2>/dev/null

# Cava
envsubst < "$HOME/.config/cava/config.template" \
        > "$HOME/.config/cava/config"

# Wofi
envsubst "$THEME_VARS" < "$HOME/.config/wofi/style.css.template" \
        > "$HOME/.config/wofi/style.css"

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



