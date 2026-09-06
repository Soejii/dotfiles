#!/usr/bin/env bash
# Opens the Quickshell drawer on whichever monitor currently has focus.
# Quickshell 0.3.1's Hyprland.monitors model comes back empty, so the
# monitor is resolved here and passed in over IPC.
set -uo pipefail

pane="${1:-power}"
mon="$(hyprctl monitors -j 2>/dev/null | jq -r 'map(select(.focused))[0].name // empty')"

exec qs ipc call drawer toggle "$pane" "$mon"
