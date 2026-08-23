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

# ---- Observation only: the Wayland idle-inhibit channel ----------------------
# A window can hold idle open through the Wayland zwp_idle_inhibit protocol
# instead of D-Bus. Hyprland enforces that itself and never tells hypridle, so
# the "Inhibit locks: 0" read above is perfectly true while the screen still
# never locks. That is the 2026-08-23 Vesktop incident: 4.5 hours unlocked with
# every guard on this machine reporting a good condition.
#
# The .inhibitingIdle test further down already reads this, but it sits AFTER the
# locks<=0 early return below, so for this failure mode it has never once been
# reached. Hence this block, deliberately placed before that return.
#
# This block only REPORTS. It must never restart hypridle: the inhibitor belongs
# to the client, so a restart cannot clear it and would only risk orphaning
# hyprlock. Enforcement is hypridle.conf's 1200s ignore_inhibit listener.
WLSTATE="/run/user/$(id -u)/hypridle-watchdog.wayland"
wl_holders="$(/usr/bin/hyprctl clients -j 2>/dev/null \
    | /usr/bin/jq -r '[.[] | select(.inhibitingIdle == true) | .class] | unique | join(", ")' 2>/dev/null)"
wl_holders="${wl_holders:-}"
if [ -n "$wl_holders" ]; then
    wl_now="$(/usr/bin/date +%s)"
    [ -f "$WLSTATE" ] || printf '%s\n' "$wl_now" > "$WLSTATE"
    wl_since="$(/usr/bin/cat "$WLSTATE" 2>/dev/null)"
    case "$wl_since" in ''|*[!0-9]*) wl_since="$wl_now" ;; esac
    wl_held=$(( wl_now - wl_since ))
    # Report once per episode, and only once the hold has outlived the 1200s
    # hard-lock listener, so a short legitimate call or video stays quiet.
    if [ "$wl_held" -ge 1200 ] && [ ! -f "$WLSTATE.reported" ]; then
        echo "wayland idle inhibit held ${wl_held}s by: $wl_holders (dbus locks: $locks)"
        /usr/bin/notify-send -u critical -a hypridle-watchdog \
            "Screen lock is blocked" \
            "$wl_holders holds a Wayland idle inhibitor (${wl_held}s). hypridle's D-Bus counter cannot see it and is not at fault. Restarting hypridle will NOT clear it. The 20-min hard listener still locks." 2>/dev/null || true
        : > "$WLSTATE.reported"
    fi
else
    /usr/bin/rm -f "$WLSTATE" "$WLSTATE.reported"
fi

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
