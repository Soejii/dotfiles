#!/usr/bin/env bash
# Waybar custom/hypridle health indicator.
# Healthy is invisible. A dead service is shown in red and can be started by
# clicking it. Application inhibitors are normal state, not an error dashboard.

if ! systemctl --user is-active --quiet hypridle.service; then
  printf '{"text":"󰒲 !","tooltip":"hypridle is not running; click to start it","class":"dead"}\n'
  exit 0
fi

printf '{"text":"","tooltip":"idle timers active"}\n'
