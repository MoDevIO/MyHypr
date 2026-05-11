#!/bin/bash

# Define the action and capture the output
# The 'action' string is what the script will see when clicked
ACTION=$(notify-send "Welcome!" "Wanna change the light?" \
    --action="turn_on=Turn On" \
    --action="turn_off=Turn Off")

case "$ACTION" in
    "turn_on")
        # Put your light-on command here (e.g., a curl request or local script)
        #!/bin/bash
        curl -X POST \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJjOGYyMDdhYTA1NzY0ZWVkOTFlMDNjNjc3YjQzYzU2NSIsImlhdCI6MTc3MTA2NTI4MywiZXhwIjoyMDg2NDI1MjgzfQ.YdPW9xUoOYQ12ECp1bL6tolcbaBdNkNTDNfP7LjiGeg" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "light.mo"}' \
  http://192.168.178.143:8123/api/services/light/turn_on
        ;;
    "turn_off")
        # Put your light-off command here (e.g., a curl request or local script)
        curl -X POST \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJjOGYyMDdhYTA1NzY0ZWVkOTFlMDNjNjc3YjQzYzU2NSIsImlhdCI6MTc3MTA2NTI4MywiZXhwIjoyMDg2NDI1MjgzfQ.YdPW9xUoOYQ12ECp1bL6tolcbaBdNkNTDNfP7LjiGeg" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "light.mo"}' \
  http://192.168.178.143:8123/api/services/light/turn_off
        ;;
esac