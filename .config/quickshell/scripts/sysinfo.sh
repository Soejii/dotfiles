#!/usr/bin/env bash
# Emits one key=value block per run for the Quickshell System pane.
# hwmon indices are NOT stable across boots, so sensors are resolved by the
# driver name in hwmonN/name rather than by a hardcoded path.
set -uo pipefail

# --- cpu jiffies; the pane computes the delta between ticks ---
read -r _ a b c idle rest < /proc/stat
total=0; for v in $a $b $c $idle $rest; do total=$((total + v)); done
echo "cpu=$total $idle"

# --- memory ---
awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2}
     END{print "mem=" t " " a}' /proc/meminfo

# --- temperatures, resolved by driver name ---
temp_of() {   # $1 = driver name, $2 = temp index
    for h in /sys/class/hwmon/hwmon*; do
        [ "$(cat "$h/name" 2>/dev/null)" = "$1" ] || continue
        f="$h/temp$2_input"
        [ -r "$f" ] && { echo $(( $(cat "$f") / 1000 )); return; }
    done
    echo ""
}
echo "tcpu=$(temp_of k10temp 1)"    # Tctl
echo "tgpu=$(temp_of amdgpu 1)"     # edge
echo "tnvme=$(temp_of nvme 1)"      # composite of the first nvme found

# --- root filesystem ---
df -h --output=used,size,pcent / | tail -1 | awk '{gsub(/%/,"",$3); print "disk=" $1 " " $2 " " $3}'

# --- heaviest processes by resident memory ---
ps -eo comm=,rss= --sort=-rss | head -3 | awk '{m=$NF; $NF=""; sub(/[ \t]+$/,""); printf "proc=%s %d\n", $0, m/1024}'
