#!/usr/bin/env bash
# Waybar custom/volume module.
# Reads the CURRENT default sink every run, so the bar can never go stale.
# Output: one line of JSON {text,tooltip,class,percentage}.

raw="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"

# Nerd-font speaker glyphs (same family as the old config: f026/f027/f028).
i_low=$''
i_med=$''
i_high=$''
i_mute=$''

esc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }

if [[ -z "$raw" ]]; then
  printf '{"text":"%s no sink","tooltip":"No default audio sink","class":"muted","percentage":0}\n' "$i_mute"
  exit 0
fi

muted=0
[[ "$raw" == *"[MUTED]"* ]] && muted=1
vol="${raw#Volume: }"
vol="${vol%% *}"                       # e.g. 0.42
pct="$(awk -v v="$vol" 'BEGIN{printf "%d", v*100 + 0.5}')"

desc="$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null \
        | sed -nE 's/.*node\.description = "(.*)"/\1/p' | head -n1)"
[[ -z "$desc" ]] && desc="Audio"

if (( muted )); then
  text="$i_mute Muted"
  class="muted"
else
  if   (( pct <= 33 )); then ic="$i_low"
  elif (( pct <= 66 )); then ic="$i_med"
  else                       ic="$i_high"
  fi
  text="$ic ${pct}%"
  class="normal"
fi

tooltip="$desc  ·  ${pct}%"

printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%d}\n' \
  "$(esc "$text")" "$(esc "$tooltip")" "$class" "$pct"
