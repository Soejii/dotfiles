#!/usr/bin/env bash
# Waybar custom/hypridle module.
# Shows BOTH idle-inhibit channels, because they are independent:
#   - D-Bus (org.freedesktop.ScreenSaver): hypridle counts these and logs
#     "Inhibit locks: N". This is all this module used to show.
#   - Wayland (zwp_idle_inhibit): Hyprland enforces these itself and never
#     reports them to hypridle, so the D-Bus count reads 0 while the screen
#     still never locks. That blind spot was the 2026-08-23 Vesktop incident
#     (4.5 hours unlocked, this lamp green the entire time).
# Invisible when nothing inhibits; coffee icon while inhibited; red if dead.

if ! systemctl --user is-active --quiet hypridle.service; then
  printf '{"text":"󰒲 !","tooltip":"hypridle is NOT running — click to (re)start it","class":"dead"}\n'
  exit 0
fi

inv="$(systemctl --user show -p InvocationID --value hypridle.service)"
locks="$(journalctl --user -u hypridle.service "_SYSTEMD_INVOCATION_ID=$inv" \
  -n 2000 --no-pager -o cat 2>/dev/null \
  | grep -oP 'Inhibit locks: \K-?[0-9]+' | tail -n1)"
locks="${locks:-0}"

wl="$(hyprctl clients -j 2>/dev/null \
  | jq -r '[.[] | select(.inhibitingIdle == true) | .class] | unique | join(", ")' 2>/dev/null)"
wl="${wl:-}"

# Wayland outranks D-Bus in the display: it is the channel nothing else surfaces,
# and unlike a stuck D-Bus lock the click action cannot clear it.
if [ -n "$wl" ]; then
  printf '{"text":"󰅶 W","tooltip":"WAYLAND idle inhibit held by: %s\\nThe screen will NOT lock at 5 min. hypridle reports %s D-Bus locks and is not at fault.\\nClicking (restart hypridle) will NOT clear this — quit or restart the offending app.\\nThe 20-min ignore_inhibit listener still locks regardless.","class":"waylandinhibit"}\n' "$wl" "$locks"
elif [ "$locks" -gt 0 ]; then
  printf '{"text":"󰅶 %s","tooltip":"idle inhibited (%s locks) — no dim/lock/suspend.\\nNormal while a video plays; click to restart hypridle if stuck.","class":"inhibited"}\n' "$locks" "$locks"
else
  printf '{"text":"","tooltip":"idle timers active"}\n'
fi
