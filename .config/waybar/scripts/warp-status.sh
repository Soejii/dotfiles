#!/usr/bin/env bash
# Waybar custom/warp module.
# Read the kernel-visible WARP interface instead of querying warp-svc every five
# seconds. `warp-cli status` makes this client version log registration details
# on every call; CloudflareWARP exists only while the tunnel is active.

esc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
connecting_marker="$runtime_dir/waybar-warp-connecting"
warp_interface="/sys/class/net/CloudflareWARP"

if [[ -d "$warp_interface" ]]; then
  text=" WARP"
  class="on"
  tooltip="Cloudflare WARP: Connected"
elif [[ -e "$connecting_marker" ]]; then
  text=" WARP"
  class="connecting"
  tooltip="Cloudflare WARP: Connecting..."
else
  text=" WARP"
  class="off"
  tooltip="Cloudflare WARP: Disconnected"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$(esc "$text")" "$(esc "$tooltip")" "$class"
