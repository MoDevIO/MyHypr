#!/bin/bash

curl -X POST \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJjOGYyMDdhYTA1NzY0ZWVkOTFlMDNjNjc3YjQzYzU2NSIsImlhdCI6MTc3MTA2NTI4MywiZXhwIjoyMDg2NDI1MjgzfQ.YdPW9xUoOYQ12ECp1bL6tolcbaBdNkNTDNfP7LjiGeg" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "media_player.mo"}' \
  http://192.168.178.143:8123/api/services/media_player/turn_on