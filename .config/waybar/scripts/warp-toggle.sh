#!/usr/bin/env bash
# Toggle Cloudflare WARP on/off, then force the waybar module to refresh immediately.

set -u
umask 077

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
connecting_marker="$runtime_dir/waybar-warp-connecting"
toggle_lock="$runtime_dir/waybar-warp-toggle.lock"
warp_interface="/sys/class/net/CloudflareWARP"

refresh_waybar() {
  pkill -x -RTMIN+9 waybar 2>/dev/null || true
}

notify_failure() {
  command -v notify-send >/dev/null 2>&1 \
    && notify-send -u critical "Cloudflare WARP" "$1"
}

# Ignore a second click while the first connect/disconnect is still settling.
exec 9>"$toggle_lock"
flock -n 9 || exit 0

if [[ -d "$warp_interface" ]]; then
  rm -f -- "$connecting_marker"
  if ! warp-cli disconnect >/dev/null 2>&1; then
    notify_failure "Could not disconnect the tunnel."
    exit 1
  fi
  refresh_waybar
  exit 0
fi

# Preserve the yellow Waybar state without repeatedly asking warp-svc for its
# full status. The real network interface remains the source of truth.
: >"$connecting_marker"
refresh_waybar

cleanup() {
  rm -f -- "$connecting_marker"
  refresh_waybar
}
trap cleanup EXIT

if ! warp-cli connect >/dev/null 2>&1; then
  notify_failure "Could not request a tunnel connection."
  exit 1
fi

# Cloudflare creates this interface during a successful connection. Polling
# sysfs is local and does not make warp-svc emit registration-bearing logs.
for _ in {1..60}; do
  [[ -d "$warp_interface" ]] && exit 0
  sleep 0.25
done

notify_failure "The tunnel did not become ready within 15 seconds."
exit 1
