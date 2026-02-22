#!/bin/bash
prev=""
while true; do
    online=$(cat /sys/class/power_supply/ADP0/online)
    if [ "$online" != "$prev" ]; then
        if [ "$online" = "0" ]; then
            powerprofilesctl set balanced
        else
            powerprofilesctl set performance
        fi
        prev="$online"
    fi
    sleep 3
done
