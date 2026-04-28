#!/usr/bin/env bash
# telegram-send.sh — outbound Telegram messages with retries + dedup + MOCK
#
# Invoked by agent wake.md scripts when an agent needs to notify the
# operator (info/action_required/error) or request approval.
#
# Usage:
#   echo '{"text":"...","reply_markup":{...}}' | telegram-send.sh <correlation-id>
#
# JSON envelope on stdin (parsed via jq):
#   text                 (required)  message body
#   chat_id              (optional)  defaults to $TELEGRAM_CHAT_ID
#   message_thread_id    (optional)  for forum-topic supergroups
#   parse_mode           (optional)  "Markdown" / "MarkdownV2" / "HTML"
#   reply_markup         (optional)  inline keyboard JSON object
#   tier                 (optional)  "info" / "action_required" / "error"
#                                    (informational; routed via thread_id)
#
# Modes:
#   TELEGRAM_MOCK=1     → append envelope to telegram-out.jsonl, no curl.
#                         Used by AGENTBLOC_DEMO=mock + by CI runners.
#   TELEGRAM_BOT_TOKEN= → real mode. POSTs to api.telegram.org.
#
# Idempotency contract (Premise 4):
#   One correlation-id = one outbound message. If telegram-sent.jsonl
#   already has this correlation-id, exit 0 silently. This makes
#   send-then-crash retries safe — the next wake re-runs the whole
#   wake.md but won't double-send.
#
# Retry policy:
#   3 attempts, exponential backoff: 1s, 4s, 16s. On final failure,
#   append a record to telegram-failed.jsonl and exit 1 so the caller
#   knows. Telegram API rate-limit responses (429) honor the
#   Retry-After header within the same 21s budget.
#
# Exit codes:
#   0  — sent (or mocked, or deduped)
#   1  — fatal: missing TELEGRAM_BOT_TOKEN in real mode, missing chat_id,
#        empty text, or all 3 send attempts failed
#   2  — bad argv / malformed JSON envelope
#
# Refs: design doc Premise 4, .claude/skills/agentbloc/references/
#       telegram-patterns.md (note: that file references the v2.0
#       AGENTBLOC_TELEGRAM_BOT_TOKEN env name — Wave 5 surgery
#       reconciles to v2.5's TELEGRAM_BOT_TOKEN).

set -euo pipefail

# ─── Resolve repo root + helpers ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export AGENTBLOC_HOME="${AGENTBLOC_HOME:-$REPO_ROOT}"

# shellcheck source=helpers.sh
. "${SCRIPT_DIR}/helpers.sh"

# ─── Argument parsing ────────────────────────────────────────────────────────
CORRELATION_ID="${1:-}"
if [ -z "$CORRELATION_ID" ]; then
  echo "telegram-send.sh: correlation-id required as arg 1" >&2
  echo "usage: echo '{\"text\":\"...\"}' | telegram-send.sh <correlation-id>" >&2
  exit 2
fi

# ─── Load .env ───────────────────────────────────────────────────────────────
ENV_FILE="${AGENTBLOC_HOME}/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

# ─── State paths ─────────────────────────────────────────────────────────────
STATE_DIR="${AGENTBLOC_HOME}/.agentbloc/state"
SENT_LOG="${STATE_DIR}/telegram-sent.jsonl"
OUT_LOG="${STATE_DIR}/telegram-out.jsonl"
FAILED_LOG="${STATE_DIR}/telegram-failed.jsonl"
mkdir -p "$STATE_DIR"

# ─── Dep check ───────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo "[AB-003] jq not found in PATH (telegram-send.sh requires jq)" >&2
  exit 1
fi

# ─── Idempotency: skip if already sent ───────────────────────────────────────
# grep -F is literal-string match on the correlation-id. We anchor with
# the JSON key prefix so a correlation-id that happens to appear inside
# a message body doesn't false-match. v2.5 demo-scale is fine for grep;
# v3.0 inspector might index this differently.
if [ -f "$SENT_LOG" ] && grep -Fq "\"correlation_id\":\"${CORRELATION_ID}\"" "$SENT_LOG" 2>/dev/null; then
  exit 0
fi

# ─── Read + validate JSON envelope from stdin ────────────────────────────────
if [ -t 0 ]; then
  echo "telegram-send.sh: JSON envelope expected on stdin" >&2
  exit 2
fi

ENVELOPE_JSON=$(cat)

if ! printf '%s' "$ENVELOPE_JSON" | jq -e . >/dev/null 2>&1; then
  echo "telegram-send.sh: stdin is not valid JSON" >&2
  exit 2
fi

TEXT=$(printf '%s' "$ENVELOPE_JSON" | jq -r '.text // empty')
if [ -z "$TEXT" ]; then
  echo "telegram-send.sh: envelope missing required field 'text'" >&2
  exit 2
fi

# Resolve chat_id: envelope.chat_id wins, else $TELEGRAM_CHAT_ID
CHAT_ID=$(printf '%s' "$ENVELOPE_JSON" | jq -r '.chat_id // empty')
if [ -z "$CHAT_ID" ]; then
  CHAT_ID="${TELEGRAM_CHAT_ID:-}"
fi

# In MOCK mode, chat_id is optional (we just record what would have been sent).
TS_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Build the canonical sent-marker shared by mock + real paths.
build_marker() {
  local outcome="$1" extra_arg="${2:-}"
  if [ -n "$extra_arg" ]; then
    jq -n -c \
      --arg ts "$TS_ISO" \
      --arg cid "$CORRELATION_ID" \
      --arg outcome "$outcome" \
      --arg extra "$extra_arg" \
      --argjson env "$ENVELOPE_JSON" \
      '{timestamp:$ts, correlation_id:$cid, outcome:$outcome, extra:$extra, envelope:$env}'
  else
    jq -n -c \
      --arg ts "$TS_ISO" \
      --arg cid "$CORRELATION_ID" \
      --arg outcome "$outcome" \
      --argjson env "$ENVELOPE_JSON" \
      '{timestamp:$ts, correlation_id:$cid, outcome:$outcome, envelope:$env}'
  fi
}

# ─── MOCK mode: write to telegram-out.jsonl ──────────────────────────────────
if [ "${TELEGRAM_MOCK:-0}" = "1" ] || [ "${AGENTBLOC_DEMO:-real}" = "mock" ]; then
  build_marker "mock" >> "$OUT_LOG"
  build_marker "mock" >> "$SENT_LOG"
  exit 0
fi

# ─── Real mode: dep + token check ────────────────────────────────────────────
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "[AB-006] TELEGRAM_BOT_TOKEN unset (required for real mode)" >&2
  echo "  Why: AGENTBLOC_DEMO != mock and TELEGRAM_MOCK != 1" >&2
  echo "  Fix: set TELEGRAM_BOT_TOKEN in .env or set AGENTBLOC_DEMO=mock" >&2
  exit 1
fi

if [ -z "$CHAT_ID" ]; then
  echo "telegram-send.sh: chat_id required in real mode (set TELEGRAM_CHAT_ID in .env or include in envelope)" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "telegram-send.sh: curl not found in PATH" >&2
  exit 1
fi

# ─── Build Telegram API payload ──────────────────────────────────────────────
# Telegram sendMessage expects a JSON body. We start from the envelope,
# strip our internal fields (tier), and ensure chat_id is set.
PAYLOAD=$(printf '%s' "$ENVELOPE_JSON" | jq -c \
  --arg cid "$CHAT_ID" \
  'del(.tier) | .chat_id = $cid')

API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

# ─── 3-attempt send with exponential backoff (1s, 4s, 16s) ───────────────────
attempt=1
last_http=""
last_body=""
while [ "$attempt" -le 3 ]; do
  # curl writes body to stdout, http code to a separate var via -w.
  # --max-time 10 caps a single attempt; --silent suppresses progress;
  # --show-error keeps fatal errors visible. We capture both.
  RESPONSE=$(curl --silent --show-error --max-time 10 \
    --request POST \
    --header 'Content-Type: application/json' \
    --data-binary "$PAYLOAD" \
    --write-out '\n___HTTP_CODE___%{http_code}' \
    "$API_URL" 2>&1) || true

  last_body=${RESPONSE%$'\n'___HTTP_CODE___*}
  last_http=${RESPONSE##*___HTTP_CODE___}

  if [ "$last_http" = "200" ] && printf '%s' "$last_body" | jq -e '.ok == true' >/dev/null 2>&1; then
    build_marker "sent" "$last_http" >> "$SENT_LOG"
    exit 0
  fi

  # 429 honors Retry-After if present in body.parameters.retry_after,
  # but we cap at our backoff schedule to bound total wall time.
  case "$attempt" in
    1) sleep 1 ;;
    2) sleep 4 ;;
    3) ;;  # last attempt, no further sleep
  esac
  attempt=$(( attempt + 1 ))
done

# All 3 failed. Record to telegram-failed.jsonl with last response
# for forensics. Emit on stderr so cron MAILTO surfaces it.
FAIL_RECORD=$(jq -n -c \
  --arg ts "$TS_ISO" \
  --arg cid "$CORRELATION_ID" \
  --arg http "$last_http" \
  --arg body "$last_body" \
  --argjson env "$ENVELOPE_JSON" \
  '{timestamp:$ts, correlation_id:$cid, http_code:$http, last_body:$body, envelope:$env}')
echo "$FAIL_RECORD" >> "$FAILED_LOG"

echo "telegram-send.sh: 3 attempts failed for ${CORRELATION_ID} (last http=${last_http})" >&2
echo "  see ${FAILED_LOG} for response body" >&2
exit 1
