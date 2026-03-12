#!/usr/bin/env bash
# build.sh — compile the theme-transition overlay (GTK4 + gtk4-layer-shell)
#
# Dependencies (Arch):   pacman -S gtk4 gtk4-layer-shell libepoxy grim jq
# Dependencies (Fedora): dnf install gtk4-devel gtk4-layer-shell-devel
#                         libepoxy-devel grim jq
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

BIN="theme_overlay"
SRC="theme_transition_overlay.c"

# ---- stb_image.h -----------------------------------------------------------
if [[ ! -f stb_image.h ]]; then
    echo "[build] Downloading stb_image.h ..."
    curl -sL "https://raw.githubusercontent.com/nothings/stb/master/stb_image.h" \
        -o stb_image.h
fi

# ---- Compile ----------------------------------------------------------------
echo "[build] Compiling $BIN ..."
gcc -O2 -Wall -Wextra -Wno-unused-parameter \
    -o "$BIN" "$SRC" \
    -I"$DIR" \
    $(pkg-config --cflags --libs gtk4 gtk4-layer-shell-0 epoxy) \
    -lm

echo "[build] Done → $DIR/$BIN"
