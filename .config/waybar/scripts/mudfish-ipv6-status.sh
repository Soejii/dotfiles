#!/usr/bin/env bash
# Waybar status for the IPv6 guard used with Mudfish Full VPN.

set -u

readonly device="enp6s0"
readonly runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
readonly switching_file="${runtime_dir}/mudfish-ipv6-switching"

escape_json() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

emit() {
  local text="$1"
  local tooltip="$2"
  local class="$3"
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(escape_json "$text")" "$(escape_json "$tooltip")" "$class"
}

if [[ -e "$switching_file" ]]; then
  emit "󰔟 IPv4" "Changing IPv6 state on ${device}..." "switching"
  exit 0
fi

connection_uuid="$(nmcli -g GENERAL.CON-UUID device show "$device" 2>/dev/null)"
if [[ -z "$connection_uuid" || "$connection_uuid" == "--" ]]; then
  emit "󰅛 IPv4" "IPv4 guard: Ethernet profile unavailable" "error"
  exit 0
fi

connection_name="$(nmcli -g connection.id connection show "$connection_uuid" 2>/dev/null)"
ipv6_method="$(nmcli -g ipv6.method connection show "$connection_uuid" 2>/dev/null)"

if [[ "$ipv6_method" == "disabled" ]]; then
  emit "󰈀 IPv4" \
    "Mudfish IPv4 guard: ON\nIPv6 disabled on ${connection_name}\nGGST is forced onto Mudfish IPv4\nClick to restore IPv6" \
    "on"
else
  emit "󰈀 IPv6" \
    "Mudfish IPv4 guard: OFF\nIPv6 mode: ${ipv6_method}\nGGST can bypass Mudfish over IPv6\nClick to disable IPv6" \
    "off"
fi
