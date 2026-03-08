#!/usr/bin/env bash

# =====================
# USER CONFIGURABLE BINDINGS
# =====================
#
# Format: BINDINGS[<APP_CLASS>]="<dotoolc command> # description"
# or   BINDINGS[<APP_CLASS>_shift] for when the script is invoked with
# the "shift" argument. Example:
#   BINDINGS[zen]="key ctrl+t # new tab"
#   BINDINGS[zen_shift]="key ctrl+shift+t # reopen last closed tab"
#
# Script usage: capslock.sh [shift]
#   no argument -> use normal mapping
#   "shift"     -> use alternate mapping
#
declare -A BINDINGS

# --- VS Code (code) ---
BINDINGS[code]=""
BINDINGS[code_shift]=""

# --- Terminal (kitty) ---
BINDINGS[kitty]="key alt+right # Accept one word autocomplete"
BINDINGS[kitty_shift]="key right # Accept all autocomplete"


# =====================
# END USER CONFIGURABLE SECTION
# =====================

ACTIVE_CLASS=$(hyprctl activewindow -j | grep -oP '"class":\s*"\K[^"]*')

# determine whether the user supplied the optional "shift" argument
USE_SHIFT=false
if [[ "$1" == "shift" ]]; then
    USE_SHIFT=true
fi

# choose the appropriate binding key (with or without _shift suffix)
if $USE_SHIFT; then
    key="${ACTIVE_CLASS}_shift"
else
    key="$ACTIVE_CLASS"
fi

# look up binding for the active application, fall back to generic entry
cmd_and_comment="${BINDINGS[$key]}"
if [[ -z "$cmd_and_comment" ]]; then
    # try generic fallback for shifted or non-shifted case
    if $USE_SHIFT; then
        cmd_and_comment="${BINDINGS[_shift]}"
    else
        cmd_and_comment="${BINDINGS[_]}"
    fi
fi

if [[ -n "$cmd_and_comment" ]]; then
    # extract command before any `#` comment and trim surrounding whitespace
    cmd="$(echo "${cmd_and_comment%%#*}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    echo "$cmd" | dotoolc
fi
