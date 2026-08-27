#!/usr/bin/env bash
# codex-ping.sh -- Codex counterpart to claude-ping.sh.
# Sends a minimal Luna/low message through the Codex ChatGPT subscription
# to anchor the rolling 5-hour usage window. Logs each run to ping.log.
#
# Subscription-only: do NOT set OPENAI_API_KEY here. Codex must remain logged
# in with ChatGPT so the call uses the subscription rather than API billing.
set -uo pipefail

LOG_DIR="$HOME/.codex/window-pinger"
LOG="$LOG_DIR/ping.log"
mkdir -p "$LOG_DIR"
ts="$(date '+%Y-%m-%d %H:%M:%S')"

# codex is the native installer binary in ~/.local/bin.
CODEX="$(command -v codex || echo "$HOME/.local/bin/codex")"
if [[ ! -x "$CODEX" ]]; then
    echo "[$ts] ERROR codex not found at $CODEX" >> "$LOG"
    exit 0
fi

response_file="$(mktemp "$LOG_DIR/.response.XXXXXX")"
trap 'rm -f -- "$response_file"' EXIT

raw="$("$CODEX" exec "Reply with exactly: ok" \
        --model gpt-5.6-luna \
        -c 'model_reasoning_effort="low"' \
        --ignore-user-config --ignore-rules --ephemeral \
        --skip-git-repo-check --sandbox read-only --color never \
        --output-last-message "$response_file" </dev/null 2>&1)"
code=$?
if [[ -s "$response_file" ]]; then
    out="$(<"$response_file")"
else
    out="$raw"
fi
clean="$(printf '%s' "$out" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
clean="${clean:0:300}"

if printf '%s' "$clean" | grep -qiE 'hit your .*limit|session limit|usage limit|rate limit|resets [0-9]'; then
    echo "[$ts] LIMIT (rate-limited, expected) $clean" >> "$LOG"
elif [[ $code -eq 0 ]]; then
    echo "[$ts] OK    exit=$code  resp='$clean'" >> "$LOG"
else
    echo "[$ts] FAIL  exit=$code  resp='$clean'" >> "$LOG"
    # Non-zero so systemd marks the unit failed and the miss is visible in
    # `systemctl --user --failed` instead of only inside ping.log.
    exit 1
fi
