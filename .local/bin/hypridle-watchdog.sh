#!/usr/bin/env bash
# Restart hypridle when its D-Bus idle-inhibit lock counter is stuck:
# locks > 0 while no media is playing, no window holds a Wayland idle
# inhibit, and OBS is not running. Requires two consecutive detections
# (runs are 5 min apart) before restarting, to avoid racing a just-paused
# player. Runs from hypridle-watchdog.timer.

set -u
STRIKE="/run/user/$(id -u)/hypridle-watchdog.strike"

clear_strike() { /usr/bin/rm -f "$STRIKE"; }

/usr/bin/systemctl --user is-active --quiet hypridle.service || exit 0

inv="$(/usr/bin/systemctl --user show -p InvocationID --value hypridle.service)"
[ -n "$inv" ] || exit 0
locks="$(/usr/bin/journalctl --user -u hypridle.service "_SYSTEMD_INVOCATION_ID=$inv" \
    -n 2000 --no-pager -o cat 2>/dev/null \
    | /usr/bin/grep -oP 'Inhibit locks: \K-?[0-9]+' | /usr/bin/tail -n1)"
locks="${locks:-0}"

if [ "$locks" -le 0 ]; then clear_strike; exit 0; fi

# Legit inhibit: something is actually playing (covers Firefox and
# video-idle-inhibit, both of which key off real playback).
if /usr/bin/playerctl -a status 2>/dev/null | /usr/bin/grep -q Playing; then
    clear_strike; exit 0
fi
# Legit inhibit: a window holds a Wayland-protocol idle inhibit.
if /usr/bin/hyprctl clients -j 2>/dev/null \
    | /usr/bin/jq -e 'any(.[]; .inhibitingIdle == true)' >/dev/null 2>&1; then
    clear_strike; exit 0
fi
# Never touch hypridle while OBS might be streaming or recording.
if /usr/bin/pgrep -x obs >/dev/null 2>&1 || /usr/bin/pgrep -f com.obsproject.Studio >/dev/null 2>&1; then
    clear_strike; exit 0
fi

now="$(/usr/bin/date +%s)"
if [ -f "$STRIKE" ] && [ $((now - $(cat "$STRIKE"))) -le 720 ]; then
    echo "inhibit locks stuck at $locks with nothing playing; restarting hypridle"
    /usr/bin/systemctl --user restart hypridle.service
    clear_strike
    /usr/bin/pkill -RTMIN+10 waybar 2>/dev/null || true
    exit 0
fi
echo "$now" > "$STRIKE"
