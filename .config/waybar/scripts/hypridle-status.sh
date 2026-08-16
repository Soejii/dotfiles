#!/usr/bin/env bash
# Waybar custom/hypridle module.
# Invisible while hypridle is alive; red marker if it has died.
#
# Rewritten 2026-08-16. The previous version came from the desktop (3be91a2) and
# health-checked `systemctl --user is-active hypridle.service`. On this laptop
# hypridle is spawned directly by Hyprland (hyprland.lua: exec_cmd("hypridle"))
# and that unit is intentionally disabled, so the check was always false and the
# module sat permanently red while idle was in fact working. The old inhibit-lock
# counter is gone with it: it read the unit's journal, and a Hyprland-spawned
# process has none (its stdout is not captured in hyprland.log either).

set -uo pipefail

pid="$(pgrep -x hypridle | head -n1)"

if [ -z "$pid" ]; then
  printf '{"text":"󰒲 !","tooltip":"hypridle is NOT running — no dim, lock or suspend.\\nClick to restart it.","class":"dead"}\n'
  exit 0
fi

since="$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ')"
printf '{"text":"","tooltip":"hypridle running (pid %s, up %s)\\nidle timers active"}\n' \
  "$pid" "${since:-unknown}"
