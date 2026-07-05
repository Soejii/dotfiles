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

# Headless `claude -p` cannot refresh an expired OAuth access token (8h TTL),
# so any run >8h after the last interactive session 401s (claude-code#53063).
# A long-lived subscription token from `claude setup-token`, stored in
# $LOG_DIR/oauth-token (chmod 600), bypasses refresh entirely and still
# draws from the subscription window.
TOKEN_FILE="$LOG_DIR/oauth-token"
if [[ -s "$TOKEN_FILE" ]]; then
    CLAUDE_CODE_OAUTH_TOKEN="$(tr -d '[:space:]' < "$TOKEN_FILE")"
    export CLAUDE_CODE_OAUTH_TOKEN
fi

# claude is the native installer binary (~/.local/bin, symlink into ~/.local/share/claude)
CLAUDE="$(command -v claude || echo "$HOME/.local/bin/claude")"
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
    # Non-zero so systemd marks the unit failed and the miss is visible in
    # `systemctl --user --failed` instead of only inside ping.log.
    exit 1
fi
