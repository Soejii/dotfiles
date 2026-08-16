#!/usr/bin/env bash
# Waybar custom/volume module.
# Reports the default PipeWire sink's volume and mute state as JSON.
#
#   audio-status.sh            print one line and exit
#   audio-status.sh --watch    print immediately, then on every audio change
#
# --watch is how waybar runs it: `pactl subscribe` pushes an event the instant
# anything touches audio, so the bar reacts to the XF86Audio keys, pavucontrol
# and apps alike with no polling. The module previously used "interval": 1,
# which lagged the media keys by up to a second and woke the CPU every second
# on battery.
#
# Rewritten 2026-08-16: the original was never tracked in the dotfiles repo, so
# the desktop->laptop config sync (3be91a2) brought over the module definition
# but not the script it execs, leaving the module rendering empty.

set -uo pipefail

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

render() {
  local raw vol desc icon class hint
  raw="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"

  if [ -z "$raw" ]; then
    printf '{"text":"󰝟 !","tooltip":"no default audio sink — is pipewire running?","class":"muted"}\n'
    return
  fi

  # "Volume: 1.55 [MUTED]" -> 155, muted
  vol="$(awk '{printf "%d", $2 * 100 + 0.5}' <<<"$raw")"

  desc="$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null \
    | sed -n 's/^[ *]*node\.description = "\(.*\)"$/\1/p' | head -n1)"
  desc="$(esc "${desc:-unknown device}")"

  hint='scroll: adjust · middle-click: mute · right-click: switch device'

  # Muted still shows the percentage, so volume keys visibly do something
  # while muted instead of looking like a frozen bar.
  if [[ "$raw" == *"[MUTED]"* ]]; then
    printf '{"text":"󰝟 %s%%","tooltip":"%s\\nvolume %s%% (muted)\\n%s","class":"muted"}\n' \
      "$vol" "$desc" "$vol" "$hint"
    return
  fi

  if   [ "$vol" -eq 0 ];  then icon="󰝟"
  elif [ "$vol" -lt 34 ]; then icon="󰕿"
  elif [ "$vol" -lt 67 ]; then icon="󰖀"
  else                         icon="󰕾"
  fi

  class="active"
  [ "$vol" -gt 100 ] && class="overamplified"

  printf '{"text":"%s %s%%","tooltip":"%s\\nvolume %s%%\\n%s","class":"%s"}\n' \
    "$icon" "$vol" "$desc" "$vol" "$hint" "$class"
}

if [ "${1:-}" != "--watch" ]; then
  render
  exit 0
fi

render

# Read via process substitution rather than `pactl subscribe | while`, so the
# loop runs in this shell and pactl's pid stays reachable for cleanup. With a
# pipeline, killing this script orphaned `pactl subscribe` onto init: it does
# not die of SIGPIPE when its reader goes away, so every waybar restart of this
# module stranded one forever (two were found alive at ppid=1 on 2026-08-16).
exec 3< <(pactl subscribe 2>/dev/null)
sub_pid=$!
trap 'kill "$sub_pid" 2>/dev/null' EXIT INT TERM HUP

# Sink events cover volume/mute; server events cover default-sink changes.
# sink-input is deliberately ignored: per-app streams fire constantly and do
# not affect what this module shows.
while IFS= read -r ev <&3; do
  case "$ev" in
    *"on sink #"*|*"on server"*) render ;;
  esac
done
