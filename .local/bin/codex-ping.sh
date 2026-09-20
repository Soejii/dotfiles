#!/usr/bin/env bash
# Run bounded, measurable Codex and OpenCode tasks, then verify a fresh window
# with the live ChatGPT subscription rate-limit state.
set -uo pipefail

LOG_DIR="${PING_LOG_DIR:-$HOME/.codex/window-pinger}"
LOG="$LOG_DIR/ping.log"
WORK_DIR="${PING_WORK_DIR:-/tmp/codex-window-ping}"
CODEX="${CODEX_BIN:-$(command -v codex 2>/dev/null || true)}"
MODEL="${PING_MODEL:-gpt-5.6-sol}"
PROMPT="${PING_PROMPT:-Write a 250 to 350 word incident postmortem about a failed scheduled Linux automation. Cover impact, timeline, root cause, corrective actions, and prevention. Use plain prose with short section headings. Ignore the synthetic padding supplied on stdin. Do not use tools or inspect the machine.}"
MIN_RESPONSE_WORDS="${PING_MIN_RESPONSE_WORDS:-200}"
# Calibrated 2026-09-03: 10,000 unique padding words produced 14,103
# uncached input tokens and moved the live five-hour meter by 2%.
PADDING_WORDS="${PING_PADDING_WORDS:-10000}"
MIN_UNCACHED_INPUT_TOKENS="${PING_MIN_UNCACHED_INPUT_TOKENS:-12000}"
ANCHOR_TOLERANCE="${PING_ANCHOR_TOLERANCE:-120}"
VERIFY_ATTEMPTS="${PING_VERIFY_ATTEMPTS:-8}"
VERIFY_DELAY="${PING_VERIFY_DELAY:-15}"
NETWORK_WAIT="${PING_NETWORK_WAIT:-60}"
PING_TIMEOUT="${PING_TIMEOUT:-180}"
OPENCODE="${OPENCODE_BIN:-$HOME/.opencode/bin/opencode}"
OPENCODE_MODEL="${OPENCODE_MODEL:-openai/$MODEL}"
OPENCODE_PROMPT="${OPENCODE_PROMPT:-Write a 250 to 350 word incident postmortem about a failed scheduled Linux automation. Cover impact, timeline, root cause, corrective actions, and prevention. Use plain prose with short section headings. Ignore the synthetic padding below. Do not use tools or inspect the machine.}"
OPENCODE_PADDING_WORDS="${OPENCODE_PADDING_WORDS:-10000}"
OPENCODE_MIN_RESPONSE_WORDS="${OPENCODE_MIN_RESPONSE_WORDS:-200}"
OPENCODE_MIN_INPUT_TOKENS="${OPENCODE_MIN_INPUT_TOKENS:-10000}"
OPENCODE_TIMEOUT="${OPENCODE_TIMEOUT:-180}"
OPENCODE_CONFIG_CONTENT='{"agent":{"pinger":{"description":"Bounded subscription-window pinger","mode":"primary","variant":"low","prompt":"Complete only the requested writing task. Do not use tools or inspect files.","tools":{"*":false},"permission":{"*":"deny"}}}}'

[[ "$MIN_RESPONSE_WORDS" =~ ^[1-9][0-9]*$ ]] || MIN_RESPONSE_WORDS=200
[[ "$PADDING_WORDS" =~ ^[1-9][0-9]*$ ]] || PADDING_WORDS=10000
[[ "$MIN_UNCACHED_INPUT_TOKENS" =~ ^[1-9][0-9]*$ ]] || MIN_UNCACHED_INPUT_TOKENS=12000
[[ "$ANCHOR_TOLERANCE" =~ ^[1-9][0-9]*$ ]] || ANCHOR_TOLERANCE=120
[[ "$VERIFY_ATTEMPTS" =~ ^[1-9][0-9]*$ ]] || VERIFY_ATTEMPTS=8
[[ "$VERIFY_DELAY" =~ ^[0-9]+$ ]] || VERIFY_DELAY=15
[[ "$NETWORK_WAIT" =~ ^[0-9]+$ ]] || NETWORK_WAIT=60
[[ "$PING_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || PING_TIMEOUT=180
[[ "$OPENCODE_PADDING_WORDS" =~ ^[1-9][0-9]*$ ]] || OPENCODE_PADDING_WORDS=10000
[[ "$OPENCODE_MIN_RESPONSE_WORDS" =~ ^[1-9][0-9]*$ ]] || OPENCODE_MIN_RESPONSE_WORDS=200
[[ "$OPENCODE_MIN_INPUT_TOKENS" =~ ^[1-9][0-9]*$ ]] || OPENCODE_MIN_INPUT_TOKENS=10000
[[ "$OPENCODE_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || OPENCODE_TIMEOUT=180

mkdir -p "$LOG_DIR" "$WORK_DIR"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

clock_time() {
    date -d "@$1" '+%Y-%m-%d %H:%M:%S'
}

is_zero() {
    [[ "$1" =~ ^0+([.]0+)?$ ]]
}

# Never allow a scheduled retry and a calendar run to consume quota together.
exec 9>"$LOG_DIR/ping.lock"
if ! flock -n 9; then
    log "BUSY another codex-ping run is active"
    exit 0
fi

if [[ -z "$CODEX" || ! -x "$CODEX" ]]; then
    log "FAIL codex executable not found"
    exit 127
fi

# Prints: used_percent resets_at_epoch window_minutes
rate_state() {
    /usr/bin/python3 - "$CODEX" <<'PY'
import json
import selectors
import subprocess
import sys
import time

process = subprocess.Popen(
    [sys.argv[1], "app-server"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
    bufsize=1,
)
selector = selectors.DefaultSelector()
selector.register(process.stdout, selectors.EVENT_READ)

def send(message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()

def receive(response_id, timeout=20):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        events = selector.select(max(0, deadline - time.monotonic()))
        if not events:
            break
        line = process.stdout.readline()
        if not line:
            break
        try:
            message = json.loads(line)
        except ValueError:
            continue
        if message.get("id") == response_id:
            return message
    raise RuntimeError("rate-limit read timed out")

try:
    send({
        "jsonrpc": "2.0",
        "id": 0,
        "method": "initialize",
        "params": {
            "clientInfo": {"name": "codex-window-pinger", "version": "2"},
            "capabilities": {"experimentalApi": True},
        },
    })
    receive(0)
    send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
    send({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "account/rateLimits/read",
        "params": {},
    })
    response = receive(1)
    if response.get("error"):
        raise RuntimeError(response["error"])
    primary = response["result"]["rateLimits"]["primary"]
    if not primary:
        raise RuntimeError("primary rate-limit state is missing")
    print(
        primary.get("usedPercent", "?"),
        int(primary["resetsAt"]),
        int(primary.get("windowDurationMins", 300)),
    )
except Exception as error:
    print(f"{type(error).__name__}: {error}", file=sys.stderr)
    raise SystemExit(1)
finally:
    selector.close()
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
PY
}

state_error="$(mktemp "$LOG_DIR/.state-error.XXXXXX")" || exit 1
response_file="$(mktemp "$LOG_DIR/.response.XXXXXX")" || exit 1
command_output="$(mktemp "$LOG_DIR/.command-output.XXXXXX")" || exit 1
payload_file="$(mktemp "$LOG_DIR/.payload.XXXXXX")" || exit 1
opencode_events="$(mktemp "$LOG_DIR/.opencode-events.XXXXXX")" || exit 1
opencode_stderr="$(mktemp "$LOG_DIR/.opencode-stderr.XXXXXX")" || exit 1
opencode_payload_file="$(mktemp "$LOG_DIR/.opencode-payload.XXXXXX")" || exit 1
trap 'rm -f -- "$state_error" "$response_file" "$command_output" "$payload_file" "$opencode_events" "$opencode_stderr" "$opencode_payload_file"' EXIT

if (( NETWORK_WAIT > 0 )) && command -v nm-online >/dev/null 2>&1; then
    if ! nm-online -q --timeout="$NETWORK_WAIT"; then
        log "WARN network did not report online within ${NETWORK_WAIT}s; continuing"
    fi
fi

before_known=0
before_used="unknown"
before_reset=0
before_window=300
if state="$(rate_state 2>"$state_error")"; then
    read -r before_used before_reset before_window <<< "$state"
    before_known=1
else
    error="$(tr -s '[:space:]' ' ' < "$state_error" | head -c 240)"
    log "WARN precheck unavailable; sending scheduled ping anyway; error='$error'"
fi

now="$(date +%s)"
if (( before_known && before_reset > now )) && ! is_zero "$before_used"; then
    log "SKIP window already open used=${before_used}% reset=$(clock_time "$before_reset")"
    exit 0
fi

/usr/bin/python3 - "$PADDING_WORDS" > "$payload_file" <<'PY'
import secrets
import sys

word_count = int(sys.argv[1])
sys.stdout.write("unique-nonce " + secrets.token_hex(1024) + "\n")
sys.stdout.write("data " * word_count)
sys.stdout.write("\n")
PY

/usr/bin/python3 - "$OPENCODE_PADDING_WORDS" > "$opencode_payload_file" <<'PY'
import secrets
import sys

word_count = int(sys.argv[1])
sys.stdout.write("unique-nonce " + secrets.token_hex(1024) + "\n")
sys.stdout.write("data " * word_count)
sys.stdout.write("\n")
PY

sent="$(date +%s)"
log "SEND client=codex model=$MODEL padding_words=$PADDING_WORDS sent=$(clock_time "$sent")"
/usr/bin/timeout --kill-after=10s "${PING_TIMEOUT}s" \
    "$CODEX" exec \
    --json \
    --ephemeral \
    --ignore-user-config \
    --ignore-rules \
    --skip-git-repo-check \
    --disable plugins \
    --disable apps \
    --disable tool_suggest \
    --sandbox read-only \
    --color never \
    --model "$MODEL" \
    -c 'model_reasoning_effort="low"' \
    -c 'instructions="Complete only the requested writing task. Do not run commands, use tools, inspect files, or take any other action."' \
    -c include_permissions_instructions=false \
    -c include_apps_instructions=false \
    -c include_collaboration_mode_instructions=false \
    -c include_environment_context=false \
    -c 'skills.include_instructions=false' \
    -C "$WORK_DIR" \
    --output-last-message "$response_file" \
    "$PROMPT" \
    <"$payload_file" >"$command_output" 2>&1
codex_code=$?

response_words=0
response_bytes=0
if [[ -s "$response_file" ]]; then
    response_words="$(wc -w < "$response_file" | tr -d ' ')"
    response_bytes="$(wc -c < "$response_file" | tr -d ' ')"
fi

read -r input_tokens cached_input_tokens output_tokens reasoning_tokens < <(
    /usr/bin/python3 - "$command_output" <<'PY'
import json
import sys

usage = None
with open(sys.argv[1], errors="replace") as stream:
    for line in stream:
        try:
            event = json.loads(line)
        except ValueError:
            continue
        if event.get("type") == "turn.completed" and isinstance(event.get("usage"), dict):
            usage = event["usage"]

if usage is None:
    print("0 0 0 0")
else:
    print(
        int(usage.get("input_tokens", 0)),
        int(usage.get("cached_input_tokens", 0)),
        int(usage.get("output_tokens", 0)),
        int(usage.get("reasoning_output_tokens", 0)),
    )
PY
)
uncached_input_tokens=$(( input_tokens - cached_input_tokens ))

codex_status=ok
if (( codex_code != 0 )); then
    detail="$(tr -s '[:space:]' ' ' < "$command_output" | head -c 240)"
    log "FAIL client=codex model=$MODEL exit=$codex_code words=$response_words bytes=$response_bytes input=$input_tokens cached=$cached_input_tokens output=$output_tokens reasoning=$reasoning_tokens detail='$detail'"
    codex_status=fail
elif (( response_words < MIN_RESPONSE_WORDS )); then
    log "FAIL client=codex model=$MODEL exit=0 response too short words=$response_words minimum=$MIN_RESPONSE_WORDS bytes=$response_bytes"
    codex_status=fail
elif (( uncached_input_tokens < MIN_UNCACHED_INPUT_TOKENS )); then
    log "FAIL client=codex model=$MODEL workload too small uncached_input=$uncached_input_tokens minimum=$MIN_UNCACHED_INPUT_TOKENS input=$input_tokens cached=$cached_input_tokens output=$output_tokens"
    codex_status=fail
else
    log "CLIENT client=codex status=ok model=$MODEL exit=0 words=$response_words input=$input_tokens cached=$cached_input_tokens uncached=$uncached_input_tokens output=$output_tokens reasoning=$reasoning_tokens"
fi

opencode_status=fail
opencode_code=127
opencode_reason=missing
opencode_input_tokens=0
opencode_cached_tokens=0
opencode_output_tokens=0
opencode_reasoning_tokens=0
opencode_response_words=0
opencode_uncached_tokens=0

if [[ ! -x "$OPENCODE" ]]; then
    log "FAIL client=opencode executable not found path=$OPENCODE"
else
    mkdir -p "$WORK_DIR/opencode-config"
    opencode_message="$(printf '%s\n' "$OPENCODE_PROMPT"; /usr/bin/cat "$opencode_payload_file")"
    opencode_sent="$(date +%s)"
    log "SEND client=opencode model=$OPENCODE_MODEL padding_words=$OPENCODE_PADDING_WORDS sent=$(clock_time "$opencode_sent")"
    XDG_CONFIG_HOME="$WORK_DIR/opencode-config" \
    OPENCODE_CONFIG_CONTENT="$OPENCODE_CONFIG_CONTENT" \
    OPENCODE_DISABLE_PROJECT_CONFIG=1 \
    OPENCODE_DISABLE_CLAUDE_CODE=1 \
    OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1 \
    OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1 \
    OPENCODE_DISABLE_EXTERNAL_SKILLS=1 \
    /usr/bin/timeout --kill-after=10s "${OPENCODE_TIMEOUT}s" \
        "$OPENCODE" run \
        --pure \
        --format json \
        --model "$OPENCODE_MODEL" \
        --variant low \
        --agent pinger \
        --title 'Codex window pinger' \
        --dir "$WORK_DIR" \
        "$opencode_message" \
        >"$opencode_events" 2>"$opencode_stderr"
    opencode_code=$?

    read -r opencode_reason opencode_input_tokens opencode_cached_tokens opencode_output_tokens opencode_reasoning_tokens opencode_response_words < <(
        /usr/bin/python3 - "$opencode_events" <<'PY'
import json
import sys

finish = None
text_parts = []
with open(sys.argv[1], errors="replace") as stream:
    for line in stream:
        try:
            event = json.loads(line)
        except ValueError:
            continue
        part = event.get("part")
        if not isinstance(part, dict):
            continue
        if part.get("type") == "text" and isinstance(part.get("text"), str):
            text_parts.append(part["text"])
        elif part.get("type") == "step-finish":
            finish = part

if finish is None:
    print("missing 0 0 0 0", len(" ".join(text_parts).split()))
else:
    tokens = finish.get("tokens") or {}
    cache = tokens.get("cache") or {}
    print(
        str(finish.get("reason", "unknown")).replace(" ", "_"),
        int(tokens.get("input", 0)),
        int(cache.get("read", 0)),
        int(tokens.get("output", 0)),
        int(tokens.get("reasoning", 0)),
        len(" ".join(text_parts).split()),
    )
PY
    )
    opencode_uncached_tokens=$(( opencode_input_tokens - opencode_cached_tokens ))

    if (( opencode_code != 0 )); then
        detail="$(tr -s '[:space:]' ' ' < "$opencode_stderr" | head -c 120) $(tr -s '[:space:]' ' ' < "$opencode_events" | head -c 120)"
        log "FAIL client=opencode model=$OPENCODE_MODEL exit=$opencode_code reason=$opencode_reason words=$opencode_response_words input=$opencode_input_tokens cached=$opencode_cached_tokens output=$opencode_output_tokens reasoning=$opencode_reasoning_tokens detail='$detail'"
    elif [[ "$opencode_reason" != "stop" ]]; then
        log "FAIL client=opencode model=$OPENCODE_MODEL exit=0 completion reason=$opencode_reason"
    elif (( opencode_response_words < OPENCODE_MIN_RESPONSE_WORDS )); then
        log "FAIL client=opencode model=$OPENCODE_MODEL exit=0 response too short words=$opencode_response_words minimum=$OPENCODE_MIN_RESPONSE_WORDS"
    elif (( opencode_uncached_tokens < OPENCODE_MIN_INPUT_TOKENS )); then
        log "FAIL client=opencode model=$OPENCODE_MODEL workload too small uncached_input=$opencode_uncached_tokens minimum=$OPENCODE_MIN_INPUT_TOKENS input=$opencode_input_tokens cached=$opencode_cached_tokens output=$opencode_output_tokens"
    else
        opencode_status=ok
        log "CLIENT client=opencode status=ok model=$OPENCODE_MODEL exit=0 reason=$opencode_reason words=$opencode_response_words input=$opencode_input_tokens cached=$opencode_cached_tokens uncached=$opencode_uncached_tokens output=$opencode_output_tokens reasoning=$opencode_reasoning_tokens"
    fi
fi

if [[ "$codex_status" == "fail" && "$opencode_status" == "fail" ]]; then
    log "UNVERIFIED no qualified client workload completed codex_status=$codex_status opencode_status=$opencode_status"
    exit 1
elif [[ "$codex_status" == "ok" && "$opencode_status" == "ok" ]]; then
    verified_clients=codex,opencode
elif [[ "$codex_status" == "ok" ]]; then
    verified_clients=codex
else
    verified_clients=opencode
fi

# New usage can take several minutes to appear. Poll long enough to cover the
# delay observed on this machine. A reset timestamp with 0% usage is never
# accepted as an anchor.
valid_reads=0
last_used="unavailable"
last_reset=0
last_window=300
for (( attempt = 1; attempt <= VERIFY_ATTEMPTS; attempt++ )); do
    if (( VERIFY_DELAY > 0 )); then
        sleep "$VERIFY_DELAY"
    fi

    : > "$state_error"
    if state="$(rate_state 2>"$state_error")"; then
        read -r used reset window <<< "$state"
        valid_reads=$((valid_reads + 1))
        last_used="$used"
        last_reset="$reset"
        last_window="$window"
        if ! is_zero "$used"; then
            start=$(( reset - window * 60 ))
            offset=$(( start - sent ))
            now="$(date +%s)"
            if (( offset >= -ANCHOR_TOLERANCE && offset <= ANCHOR_TOLERANCE )); then
                log "VERIFIED clients=$verified_clients codex_status=$codex_status opencode_status=$opencode_status codex_model=$MODEL codex_words=$response_words codex_input=$input_tokens codex_cached=$cached_input_tokens codex_output=$output_tokens opencode_model=$OPENCODE_MODEL opencode_words=$opencode_response_words opencode_input=$opencode_input_tokens opencode_cached=$opencode_cached_tokens opencode_output=$opencode_output_tokens used=${used}% window_start=$(clock_time "$start") reset=$(clock_time "$reset") start_offset=${offset}s"
                exit 0
            fi
        fi
    else
        error="$(tr -s '[:space:]' ' ' < "$state_error" | head -c 240)"
        log "WARN verification read failed attempt=$attempt/$VERIFY_ATTEMPTS error='$error'"
    fi
done

if (( valid_reads > 0 )); then
    if is_zero "$last_used"; then
        log "UNVERIFIED usage remained 0% after $valid_reads live checks; scheduled task did not prove an anchor"
    else
        last_start=$(( last_reset - last_window * 60 ))
        last_offset=$(( last_start - sent ))
        log "UNVERIFIED usage=${last_used}% window_start=$(clock_time "$last_start") start_offset=${last_offset}s not attributable to this task within ${ANCHOR_TOLERANCE}s"
    fi
else
    log "UNVERIFIED no live verification succeeded after $VERIFY_ATTEMPTS attempts"
fi
exit 1
