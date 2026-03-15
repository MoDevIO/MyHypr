#!/bin/sh
THEMES_DIR="$HOME/.config/theming/themes"
TRANSITION_DIR="$HOME/.config/hypr/hyprland/scripts/theme-transition"
ENABLE_TRANSITION=true  # set to false to skip the circle-reveal animation

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

    # VS Code
    update_vscode_colors 2>/dev/null

    # Cava
    envsubst < "$HOME/.config/cava/config.template" \
            > "$HOME/.config/cava/config"

        # Wofi
        envsubst "$THEME_VARS" < "$HOME/.config/wofi/style.css.template" \
            > "$HOME/.config/wofi/style.css"

    # Spicetify
    envsubst < "$HOME/.config/spicetify/Themes/marketplace/color.ini.template" \
            | sed -E 's/^([[:space:]]*[A-Za-z0-9-]+[[:space:]]*=[[:space:]]*)#/\1/' \
            > "$HOME/.config/spicetify/Themes/marketplace/color.ini"

        # Fastfetch
        envsubst "$THEME_VARS" < "$HOME/.config/fastfetch/config.jsonc.template" \
            > "$HOME/.config/fastfetch/config.jsonc"


    # GTK Theme (MyTheme)
    if [ -f "$HOME/.themes/MyTheme/index.theme.template" ]; then
        envsubst "$THEME_VARS" < "$HOME/.themes/MyTheme/index.theme.template" \
                > "$HOME/.themes/MyTheme/index.theme"
    fi
    if [ -f "$HOME/.themes/MyTheme/gtk-3.0/gtk.css.template" ]; then
        envsubst "$THEME_VARS" < "$HOME/.themes/MyTheme/gtk-3.0/gtk.css.template" \
                > "$HOME/.themes/MyTheme/gtk-3.0/gtk.css"
    fi
    if [ -f "$HOME/.themes/MyTheme/gtk-3.0/gtk-dark.css.template" ]; then
        envsubst "$THEME_VARS" < "$HOME/.themes/MyTheme/gtk-3.0/gtk-dark.css.template" \
                > "$HOME/.themes/MyTheme/gtk-3.0/gtk-dark.css"
    fi
    if [ -f "$HOME/.themes/MyTheme/gtk-4.0/gtk.css.template" ]; then
        envsubst "$THEME_VARS" < "$HOME/.themes/MyTheme/gtk-4.0/gtk.css.template" \
                > "$HOME/.themes/MyTheme/gtk-4.0/gtk.css"
    fi
    if [ -f "$HOME/.themes/MyTheme/gtk-4.0/gtk-dark.css.template" ]; then
        envsubst "$THEME_VARS" < "$HOME/.themes/MyTheme/gtk-4.0/gtk-dark.css.template" \
                > "$HOME/.themes/MyTheme/gtk-4.0/gtk-dark.css"
    fi
    if [ -f "$HOME/.themes/MyTheme/gtk-4.0/libadwaita.css.template" ]; then
        envsubst "$THEME_VARS" < "$HOME/.themes/MyTheme/gtk-4.0/libadwaita.css.template" \
                > "$HOME/.themes/MyTheme/gtk-4.0/libadwaita.css"
    fi
    if [ -f "$HOME/.themes/MyTheme/gtk-4.0/libadwaita-tweaks.css.template" ]; then
        envsubst "$THEME_VARS" < "$HOME/.themes/MyTheme/gtk-4.0/libadwaita-tweaks.css.template" \
                > "$HOME/.themes/MyTheme/gtk-4.0/libadwaita-tweaks.css"
    fi

    # Ensure GTK apps use the generated MyTheme files.
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme "MyTheme" 2>/dev/null || true
    fi

    # Hyprland
    envsubst < "$HOME/.config/hypr/hyprland/design.conf.template" \
            > "$HOME/.config/hypr/hyprland/design.conf"
    hyprctl reload 2>/dev/null

    # Reload running GTK app instances (delayed so theme files and hypr reload settle).
    GTK_RELOAD_SCRIPT="$HOME/.config/hypr/hyprland/scripts/reload-gtk-theme.sh"
    if [ -f "$GTK_RELOAD_SCRIPT" ]; then
        (
            sleep 0.4
            if [ -x "$GTK_RELOAD_SCRIPT" ]; then
                "$GTK_RELOAD_SCRIPT"
            else
                sh "$GTK_RELOAD_SCRIPT"
            fi
        ) >/dev/null 2>&1 &
    fi

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

chosen=$(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | wofi --show dmenu --prompt "Theme")

if [ -n "$chosen" ]; then
    if [ "$ENABLE_TRANSITION" = true ] && [ -x "$TRANSITION_DIR/theme_overlay" ]; then
        # Wait for wofi to fully close before capturing
        sleep 0.2

        MONITOR_LIST="/tmp/theme_transition_monitors_$$.txt"
        SCREENSHOTS=""
        OVERLAY_PIDS=""
        monitor_index=0

        hyprctl monitors -j | jq -r '.[].name' > "$MONITOR_LIST" 2>/dev/null

        while IFS= read -r monitor; do
            [ -n "$monitor" ] || continue

            SCREENSHOT="/tmp/theme_transition_${$}_${monitor_index}.ppm"
            if grim -t ppm -o "$monitor" "$SCREENSHOT"; then
                SCREENSHOTS="$SCREENSHOTS $SCREENSHOT"
            fi

            monitor_index=$((monitor_index + 1))
        done < "$MONITOR_LIST"

        # Apply the theme immediately behind the frozen overlay
        (sleep 0.05 && apply_theme "$chosen") &
        APPLY_PID=$!

        monitor_index=0
        while IFS= read -r monitor; do
            [ -n "$monitor" ] || continue

            SCREENSHOT="/tmp/theme_transition_${$}_${monitor_index}.ppm"
            if [ -f "$SCREENSHOT" ]; then
                # One overlay per monitor keeps the reveal synced on multi-head setups.
                "$TRANSITION_DIR/theme_overlay" "$SCREENSHOT" "$TRANSITION_DIR/circle_reveal.frag" 2.5 "$monitor_index" &
                OVERLAY_PIDS="$OVERLAY_PIDS $!"
            fi

            monitor_index=$((monitor_index + 1))
        done < "$MONITOR_LIST"

        if [ -z "$OVERLAY_PIDS" ]; then
            SCREENSHOT="/tmp/theme_transition_$$.ppm"
            grim -t ppm "$SCREENSHOT"
            SCREENSHOTS="$SCREENSHOTS $SCREENSHOT"
            "$TRANSITION_DIR/theme_overlay" "$SCREENSHOT" "$TRANSITION_DIR/circle_reveal.frag" 2.5
        fi

        for pid in $OVERLAY_PIDS; do
            wait "$pid" 2>/dev/null
        done

        wait "$APPLY_PID" 2>/dev/null

        rm -f "$MONITOR_LIST"
        rm -f $SCREENSHOTS
    else
        # No animation — apply theme directly
        apply_theme "$chosen"
    fi
fi
