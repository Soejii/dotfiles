#!/usr/bin/env bash
# Quick audio-output switcher for Waybar (right-click on the volume module).
# Shows a wofi menu of output sinks, sets the chosen one as default, and
# moves all currently-playing streams over to it.

set -uo pipefail

default_name="$(pactl get-default-sink 2>/dev/null)"

# Map sink name -> human description.
declare -A DESC
cur=""
while IFS= read -r line; do
  case "$line" in
    *"Name: "*)        cur="${line#*Name: }" ;;
    *"Description: "*)  DESC["$cur"]="${line#*Description: }" ;;
  esac
done < <(pactl list sinks)

# Build the menu from the live sink list.
menu=""
declare -A NAME_BY_LABEL
while IFS=$'\t' read -r _idx name _rest; do
  d="${DESC[$name]:-$name}"
  if [[ "$name" == "$default_name" ]]; then
    label="$d  ✓"
  else
    label="$d"
  fi
  menu+="$label"$'\n'
  NAME_BY_LABEL["$label"]="$name"
done < <(pactl list short sinks)

menu="${menu%$'\n'}"   # drop trailing blank line

choice="$(printf '%s' "$menu" | wofi --dmenu -i -p 'Audio output')"
[[ -z "$choice" ]] && exit 0

target="${NAME_BY_LABEL[$choice]:-}"
[[ -z "$target" ]] && exit 0

pactl set-default-sink "$target"

# Pull existing streams onto the new default.
while read -r sid _rest; do
  [[ -n "$sid" ]] && pactl move-sink-input "$sid" "$target" 2>/dev/null
done < <(pactl list short sink-inputs)

pkill -RTMIN+8 waybar   # refresh the bar immediately
exit 0
