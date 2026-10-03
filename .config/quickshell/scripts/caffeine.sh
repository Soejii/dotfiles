#!/usr/bin/env bash
# Caffeine mode for the Quickshell System pane.
#
#   caffeine.sh cycle         off -> 10 min -> 30 min -> always -> off
#   caffeine.sh on [10|30|always]   (default always)
#   caffeine.sh off
#   caffeine.sh status        "off", or "on <10|30|always> <seconds left|->"
#   caffeine.sh idle-allowed  hypridle condition_cmd: exit 0 lets a listener fire,
#                             exit 1 defers it while caffeine is on
#
# The inhibitor is a detached systemd-inhibit, so it survives Quickshell reloads
# and restarts. Its mode and end time live in its own --why text, so the state is
# read back from the live process and there is no state file to go stale. A timed
# mode is a `sleep <seconds>` child: when it ends, the inhibitor exits and caffeine
# is off on its own. Everything is matched on --who=Caffeine so other inhibitors
# (Claude Code, wake-cockpit, ...) are never touched.
#
# While on it blocks logind idle and sleep (the 30 min suspend), and hypridle's
# dim, 5 min lock, screen-off and 45 min safety lock check `idle-allowed`.
set -uo pipefail

PATTERN='systemd-inhibit .*--who=Caffeine'

pids() { pgrep -f -- "$PATTERN" || true; }

# The --why text of the live inhibitor, e.g. "caffeine mode=10 until=1791050000".
why() { pgrep -af -- "$PATTERN" | head -1 | sed -n 's/.*--why=\(caffeine mode=[^ ]* until=[^ ]*\).*/\1/p'; }

mode() { why | sed -n 's/.*mode=\([^ ]*\).*/\1/p'; }

stop() {
    for p in $(pids); do
        pkill -P "$p" 2>/dev/null   # the sleep child
        kill "$p" 2>/dev/null
    done
}

start() {
    local m="$1" secs until
    case "$m" in
        10) secs=600 ;;
        30) secs=1800 ;;
        always) secs=infinity ;;
        *) echo "unknown mode: $m" >&2; exit 2 ;;
    esac
    if [ "$secs" = infinity ]; then until=-; else until=$(( $(date +%s) + secs )); fi
    stop
    setsid -f systemd-inhibit --what=idle:sleep --who=Caffeine \
        --why="caffeine mode=$m until=$until" --mode=block \
        sleep "$secs" </dev/null >/dev/null 2>&1
    sleep 0.2   # let the inhibitor register before reporting status
}

status() {
    if [ -z "$(pids)" ]; then echo off; return; fi
    local m until left
    m=$(mode); until=$(why | sed -n 's/.*until=\([^ ]*\).*/\1/p')
    # An inhibitor started by the old script has no mode: treat it as always.
    [ -n "$m" ] || m=always
    if [ -n "$until" ] && [ "$until" != - ]; then
        left=$(( until - $(date +%s) )); [ "$left" -lt 0 ] && left=0
    else
        left=-
    fi
    echo "on $m $left"
}

case "${1:-status}" in
    cycle)
        if [ -z "$(pids)" ]; then start 10
        else
            case "$(mode)" in
                10) start 30 ;;
                30) start always ;;
                *) stop ;;
            esac
        fi
        ;;
    on) start "${2:-always}" ;;
    off) stop ;;
    status) ;;
    idle-allowed)
        [ -n "$(pids)" ] && exit 1 || exit 0
        ;;
    *) echo "usage: $0 cycle|on [10|30|always]|off|status|idle-allowed" >&2; exit 2 ;;
esac

status
