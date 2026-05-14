#!/usr/bin/env bash

# Use a temporary file to keep track of the running process ID
PID_FILE="/tmp/qs_toggle.pid"

if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    # 1. If running: read the PID, kill it, restart the bar, and clean up
    PID=$(cat "$PID_FILE")
    kill "$PID"
    rm "$PID_FILE"
    
    systemctl --user start mybar.service
    echo "Quickshell stopped. Bar restarted."
else
    # 2. If not running: ensure a clean slate, stop the bar, and launch qs
    rm -f "$PID_FILE"
    systemctl --user stop mybar.service
    
    # Launch qs in the background and save its process ID
    qs --config "$1" && disown
    QS_PID=$!
    echo "$QS_PID" > "$PID_FILE"
    
    echo "Bar stopped. Quickshell started (PID: $QS_PID)."
fi