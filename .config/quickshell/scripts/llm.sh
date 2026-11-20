#!/usr/bin/env bash
# Backend for the drawer's LLM pane.
#   llm.sh status   -> key=value block: state, model, vram_used, vram_total (bytes)
#   llm.sh toggle   -> start/stop llama-server.service (blocks until loaded or stopped)
# state: off | loading | on | failed
set -u

case "${1:-status}" in
  toggle)
    exec /home/suji/.config/quickshell/scripts/llama-toggle.sh
    ;;
  status)
    svc=$(systemctl --user is-active llama-server.service 2>/dev/null)
    state=off; model=""
    if [[ "$svc" == "failed" ]]; then
      state=failed
    elif [[ "$svc" == "active" || "$svc" == "activating" ]]; then
      state=loading
      model=$(curl -s --max-time 1 http://127.0.0.1:8080/models 2>/dev/null | python3 -c 'import json,sys
try: d=json.load(sys.stdin)["data"]
except Exception: sys.exit()
print(" ".join(m["id"] for m in d if m.get("status",{}).get("value")=="loaded"))' 2>/dev/null)
      [[ -n "$model" ]] && state=on
    fi
    echo "state=$state"
    echo "model=$model"
    for d in /sys/class/drm/card*/device; do
      if [[ -r "$d/mem_info_vram_used" ]]; then
        echo "vram_used=$(<"$d/mem_info_vram_used")"
        echo "vram_total=$(<"$d/mem_info_vram_total")"
        # gpu-uv-moded: compute mode (-30 mV + cap) while ROCm runs, game mode (-70 mV) otherwise
        echo "gpu_mv=$(tr -d '\0' <"$d/pp_od_clk_voltage" 2>/dev/null | grep -A1 '^OD_VDDGFX_OFFSET' | tail -1 | tr -dc '0-9-')"
        h=$(ls -d "$d"/hwmon/hwmon* 2>/dev/null | head -1)
        [[ -n $h ]] && echo "gpu_cap=$(( $(<"$h/power1_cap") / 1000000 ))"
        if compgen -G "/sys/class/kfd/kfd/proc/*" >/dev/null; then echo "gpu_mode=compute"; else echo "gpu_mode=game"; fi
        break
      fi
    done
    ;;
esac
