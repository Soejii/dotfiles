#!/bin/bash
blocked=$(rfkill list bluetooth | grep -A2 "hci0" | grep "Soft blocked: yes")
if [ -z "$blocked" ]; then
    echo '{"text": "󰂯", "class": "on"}'
else
    echo '{"text": "󰂲", "class": "off"}'
fi
