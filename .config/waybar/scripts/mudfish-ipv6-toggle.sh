#!/usr/bin/env bash
# Toggle IPv6 for the active wired profile, refreshing Waybar immediately.

set -u

readonly device="enp6s0"
readonly runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
readonly switching_file="${runtime_dir}/mudfish-ipv6-switching"
readonly lock_file="${runtime_dir}/mudfish-ipv6-toggle.lock"

refresh_waybar() {
  pkill -RTMIN+11 waybar 2>/dev/null || true
}

finish() {
  rm -f "$switching_file"
  refresh_waybar
}

fail() {
  notify-send --urgency=critical "IPv4 guard failed" "$1"
  exit 1
}

exec 9>"$lock_file"
flock -n 9 || exit 0
trap finish EXIT

connection_uuid="$(nmcli -g GENERAL.CON-UUID device show "$device" 2>/dev/null)"
[[ -n "$connection_uuid" && "$connection_uuid" != "--" ]] || \
  fail "No active Ethernet profile found on ${device}."

connection_name="$(nmcli -g connection.id connection show "$connection_uuid" 2>/dev/null)"
current_method="$(nmcli -g ipv6.method connection show "$connection_uuid" 2>/dev/null)"

if [[ "$current_method" == "disabled" ]]; then
  target_method="auto"
  success_title="IPv4 guard off"
  success_body="IPv6 restored on ${connection_name}."
else
  target_method="disabled"
  success_title="IPv4 guard on"
  success_body="IPv6 disabled on ${connection_name}; GGST will use Mudfish IPv4."
fi

touch "$switching_file"
refresh_waybar

nmcli connection modify "$connection_uuid" ipv6.method "$target_method" || \
  fail "Could not update ${connection_name}."

# Most NetworkManager versions can apply this without dropping IPv4. Fall back
# to a short profile reconnect when the active settings cannot be reapplied.
if ! nmcli device reapply "$device" >/dev/null 2>&1; then
  nmcli connection down "$connection_uuid" >/dev/null 2>&1 || true
  nmcli connection up "$connection_uuid" >/dev/null 2>&1 || \
    fail "Could not reconnect ${connection_name}. Open nmtui to recover it."
fi

notify-send "$success_title" "$success_body"
