#!/bin/bash

option=$(printf "Shutdown\nReboot\nSuspend\nLogout" | wofi --dmenu --prompt "Power" -i)

case "$option" in
  Shutdown) systemctl poweroff ;;
  Reboot) systemctl reboot ;;
  Suspend) systemctl suspend ;;
  # lua dispatcher form: `hyprctl dispatch exit` is a silent no-op under the
  # 0.55 lua config (see ~/.local/bin/hypr-dispatch).
  Logout) hyprctl dispatch 'hl.dsp.exit()' ;;
  *) ;;  # Do nothing if user hits Esc
esac
