#!/bin/bash

# 1. Create the headless monitor if it doesn't exist
if ! hyprctl monitors | grep -q "HEADLESS-2"; then
    hyprctl output create headless
    sleep 2
fi

# 2. Identify the passthrough devices (Mice, Keyboards, Tablets)
# We find everything with "-passthrough" and move it to "seat1"
# seat1 is a totally separate cursor logic from your main seat0
DEVICES=$(hyprctl devices -j | jq -r '.[][] | .name? // empty' | grep "passthrough")

if [ -z "$DEVICES" ]; then
    echo "No passthrough devices found. Start your Moonlight stream first!"
    exit 1
fi

echo "Isolating devices to seat1 on HEADLESS-2..."

for DEV in $DEVICES; do
    # This is the magic command: move the device to a new seat
    hyprctl keyword "device[$DEV]:set_seat" "seat1"
    
    # Map that seat to the headless monitor
    hyprctl keyword "device[$DEV]:output" "HEADLESS-2"
    echo "  -> $DEV moved to seat1"
done

# 3. Final polish
# Stop the mouse from warping between seats/monitors
hyprctl keyword cursor:no_warps true
# Stop the second mouse from stealing your window focus
hyprctl keyword misc:mouse_move_focuses_monitor false

echo "Done. Your physical mouse is seat0. Sunshine is seat1."
