#!/usr/bin/env bash
# Waybar custom/hypridle click action: restart hypridle.
#
# Replaces the old `systemctl --user restart hypridle.service` binding, which on
# this laptop started a SECOND hypridle alongside the one Hyprland spawns. That
# collision is the "Another service is already providing the
# org.freedesktop.ScreenSaver interface" error in the journal from 2026-08-14.
#
# Respawns with setsid rather than `hyprctl dispatch exec`. Under Hyprland 0.55
# with a lua config, hyprctl parses dispatch arguments as lua, so the plain
# `exec hypridle` form is a syntax error and every variant tried (exec("..."),
# "exec","...", hl.dsp.exec("...")) failed too. hyprctl also exits 0 on those
# errors, so the failure is silent. setsid needs none of that API: it inherits
# WAYLAND_DISPLAY and HYPRLAND_INSTANCE_SIGNATURE from waybar and detaches so
# hypridle outlives the click.

set -uo pipefail

pkill -x hypridle 2>/dev/null

# Wait for the old instance to release the ScreenSaver D-Bus name.
for _ in $(seq 1 20); do
  pgrep -x hypridle >/dev/null 2>&1 || break
  sleep 0.1
done
pkill -9 -x hypridle 2>/dev/null

setsid -f hypridle >/dev/null 2>&1

sleep 1
if pgrep -x hypridle >/dev/null 2>&1; then
  command -v notify-send >/dev/null 2>&1 && notify-send -a "hypridle" -t 2500 "hypridle restarted"
else
  command -v notify-send >/dev/null 2>&1 && notify-send -a "hypridle" -u critical "hypridle failed to restart"
fi

pkill -RTMIN+10 waybar
