#!/usr/bin/env bash
# Waybar custom/hypridle module.
# Shows hypridle's D-Bus idle-inhibit lock count (parsed from its journal).
# Invisible when locks == 0; coffee icon while idle is inhibited; red if dead.

if ! systemctl --user is-active --quiet hypridle.service; then
  printf '{"text":"󰒲 !","tooltip":"hypridle is NOT running — click to (re)start it","class":"dead"}\n'
  exit 0
fi

inv="$(systemctl --user show -p InvocationID --value hypridle.service)"
locks="$(journalctl --user -u hypridle.service "_SYSTEMD_INVOCATION_ID=$inv" \
  -n 2000 --no-pager -o cat 2>/dev/null \
  | grep -oP 'Inhibit locks: \K-?[0-9]+' | tail -n1)"
locks="${locks:-0}"

if [ "$locks" -gt 0 ]; then
  printf '{"text":"󰅶 %s","tooltip":"idle inhibited (%s locks) — no dim/lock/suspend.\\nNormal while a video plays; click to restart hypridle if stuck.","class":"inhibited"}\n' "$locks" "$locks"
else
  printf '{"text":"","tooltip":"idle timers active"}\n'
fi
