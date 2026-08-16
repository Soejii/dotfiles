#!/usr/bin/env bash
# Waybar custom/volume right-click action: cycle the default audio sink.
#
# Rewritten 2026-08-16 alongside audio-status.sh; the original was never tracked
# in the dotfiles repo and was lost in the desktop->laptop config sync (3be91a2).

set -uo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "audio" -t 2500 "$1" "${2:-}"
}

# Sink IDs in wpctl's listing order, from the Audio section only (Video has its
# own Sinks: heading, which must not be picked up).
mapfile -t ids < <(
  wpctl status 2>/dev/null \
    | sed -n '/^Audio/,/^Video/p' \
    | sed -n '/Sinks:/,/Sources:/p' \
    | grep -oP '^[^0-9]*\K[0-9]+(?=\.)'
)

if [ "${#ids[@]}" -eq 0 ]; then
  notify "No audio sinks" "is pipewire running?"
  exit 1
fi

if [ "${#ids[@]}" -eq 1 ]; then
  notify "Only one audio output" "nothing to switch to"
  exit 0
fi

current="$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -oP '^id \K[0-9]+')"

# Find the current sink's position, then advance one with wraparound.
next="${ids[0]}"
for i in "${!ids[@]}"; do
  if [ "${ids[$i]}" = "$current" ]; then
    next="${ids[$(( (i + 1) % ${#ids[@]} ))]}"
    break
  fi
done

wpctl set-default "$next" 2>/dev/null || { notify "Failed to switch sink"; exit 1; }

name="$(wpctl inspect "$next" 2>/dev/null \
  | sed -n 's/^[ *]*node\.description = "\(.*\)"$/\1/p' | head -n1)"
notify "Audio output" "${name:-sink $next}"

# No waybar signal needed: the module watches `pactl subscribe`, and changing
# the default sink raises a server event it already renders on.
