#!/bin/bash

option=$(printf "Shutdown\nReboot\nSuspend\nLogout" | wofi --dmenu --prompt "Power" -i)

case "$option" in
  Shutdown) systemctl poweroff ;;
  Reboot) systemctl reboot ;;
  Suspend) systemctl suspend ;;
  Logout) hyprctl dispatch exit ;;
  *) ;;  # Do nothing if user hits Esc
esac
