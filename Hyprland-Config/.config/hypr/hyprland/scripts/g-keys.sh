#!/usr/bin/env bash

# =====================
# USER CONFIGURABLE BINDINGS
# =====================
#
# Format: BINDINGS[<APP_CLASS>_<GKEY>]="<dotoolc command> # description"
# Example: BINDINGS[zen_G1]="key ctrl+t # New tab"
#
declare -A BINDINGS

# --- Zen Browser ---
BINDINGS[zen_G1]="key ctrl+t # New tab"
BINDINGS[zen_G2]="key ctrl+w # Close tab"
BINDINGS[zen_G3]="key ctrl+shift+t # Reopen last closed tab"
BINDINGS[zen_G4]="key ctrl+shift+tab # Tab left"
BINDINGS[zen_G5]="key ctrl+tab # Tab right"
BINDINGS[zen_mouse-G3]="key alt+right # Forward"
BINDINGS[zen_mouse-G4]="key alt+left # Backward"

# --- VS Code (code) ---
BINDINGS[code_G1]="key ctrl+b # Toggle sidebar"
BINDINGS[code_G2]="key ctrl+j # Toggle panel"
BINDINGS[code_G5]="key ctrl+alt+shift+p # Collapse all folders in explorer"

# --- Terminal (kitty) ---
BINDINGS[kitty_G1]="key ctrl+l # Clear output"

# --- File Manager (nautilus) ---
BINDINGS[org.gnome.Nautilus_mouse-G3]="key alt+right # Forward"
BINDINGS[org.gnome.Nautilus_G1]="key alt+right # Forward"
BINDINGS[org.gnome.Nautilus_mouse-G4]="key alt+left # Backward"
BINDINGS[org.gnome.Nautilus_G2]="key alt+left # Backward"


# =====================
# END USER CONFIGURABLE SECTION
# =====================

ACTIVE_CLASS=$(hyprctl activewindow -j | grep -oP '"class":\s*"\K[^"]*')
KEY="$1"

# Try direct match, then fallback to wildcard (e.g. G3 for any app)
binding_key="${ACTIVE_CLASS}_${KEY}"
cmd_and_comment="${BINDINGS[$binding_key]}"

if [[ -n "$cmd_and_comment" ]]; then
    # Extract command before any # comment
    cmd="${cmd_and_comment%%#*}"
    echo $cmd | dotoolc
fi
