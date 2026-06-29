#!/usr/bin/env bash
# claude-ping.sh -- Linux port of claude-ping.ps1.
# Sends a minimal Haiku message through the Claude Code SUBSCRIPTION (claude.ai auth)
# to anchor the rolling 5-hour usage window. Logs each run to ping.log.
#
# Subscription-only: do NOT set ANTHROPIC_API_KEY or use --bare here, or the call
# bills per-token via the API and does NOT touch the subscription window.
set -uo pipefail

LOG_DIR="$HOME/.claude/window-pinger"
LOG="$LOG_DIR/ping.log"
mkdir -p "$LOG_DIR"
ts="$(date '+%Y-%m-%d %H:%M:%S')"

# claude is installed via the npm global prefix in install.sh (~/.npm-global/bin)
CLAUDE="$(command -v claude || echo "$HOME/.npm-global/bin/claude")"
if [[ ! -x "$CLAUDE" ]]; then
    echo "[$ts] ERROR claude not found at $CLAUDE" >> "$LOG"
    exit 0
fi

out="$(printf '' | "$CLAUDE" -p "Reply with exactly: ok" \
        --model haiku --tools "" --no-session-persistence 2>&1)"
code=$?
clean="$(printf '%s' "$out" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
clean="${clean:0:300}"

if printf '%s' "$clean" | grep -qiE 'hit your .*limit|session limit|usage limit|rate limit|resets [0-9]'; then
    echo "[$ts] LIMIT (rate-limited, expected) $clean" >> "$LOG"
elif [[ $code -eq 0 ]]; then
    echo "[$ts] OK    exit=$code  resp='$clean'" >> "$LOG"
else
    echo "[$ts] FAIL  exit=$code  resp='$clean'" >> "$LOG"
fi
