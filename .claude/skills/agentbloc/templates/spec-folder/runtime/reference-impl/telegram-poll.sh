#!/usr/bin/env bash
# telegram-poll.sh — short-poll Telegram getUpdates with portable lock
#
# Invoked once per cron tick (1-min interval per Eng Review F5):
#
#   $ ./scripts/telegram-poll.sh
#
# Premise 4 (design doc) calls for `flock(1)` non-blocking, but flock
# isn't on macOS without `brew install util-linux`. We use POSIX
# `mkdir` instead — atomic across all supported targets, zero deps.
# Same fast-fail semantics: overlapping ticks exit immediately.
#
# Lifecycle (single tick):
#
#   1. Try mkdir .agentbloc/state/.telegram-poll.lock.d/
#      Success → we own the tick.
#      EEXIST  → another tick is mid-flight; check stale, exit 0 fast.
#   2. trap EXIT → rmdir lock (best-effort; survives kill -9 via stale TTL).
#   3. Load offset from telegram-offset.json (default 0).
#   4. curl getUpdates?timeout=5&offset=N+1   (--max-time 10 caps wall).
#   5. For each update:
#        - skip if update_id already in telegram-seen.jsonl
#        - append full update to telegram-seen.jsonl
#        - track max(update_id)
#   6. Persist offset atomically (tmp + mv).
#   7. Exit 0.
#
# Stale lock TTL: if the lock dir mtime is > 5 minutes old, we assume
# the prior holder crashed mid-poll and reclaim. Tunable via
# TELEGRAM_POLL_STALE_MIN.
#
# Modes:
#   TELEGRAM_MOCK=1 / AGENTBLOC_DEMO=mock
#     → exit 0 silently (no real API to poll). approval-router.sh
#       in mock mode synthesizes approvals from telegram-out.jsonl
#       echo-back.
#   TELEGRAM_BOT_TOKEN= unset
#     → exit 0 silently. Lets cron line stay installed even before the
#       user has run `cp .env.example .env && edit`.
#
# Exit codes:
#   0   — polled successfully, lock-skip, or nothing-to-do
#   1   — fatal: unrecoverable getUpdates error after retry
#   2   — bad invocation
#
# Refs: design doc Premise 4, scripts/helpers.sh (no helper used here —
#       lock mechanism is local).

set -euo pipefail

# ─── Resolve repo root + helpers ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export AGENTBLOC_HOME="${AGENTBLOC_HOME:-$REPO_ROOT}"

# shellcheck source=helpers.sh
. "${SCRIPT_DIR}/helpers.sh"

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
LOCK_DIR="${STATE_DIR}/.telegram-poll.lock.d"
OFFSET_FILE="${STATE_DIR}/telegram-offset.json"
SEEN_LOG="${STATE_DIR}/telegram-seen.jsonl"
mkdir -p "$STATE_DIR"

# ─── Tunables ────────────────────────────────────────────────────────────────
: "${TELEGRAM_POLL_STALE_MIN:=5}"   # reclaim lock dir if mtime > N min ago
: "${TELEGRAM_POLL_API_TIMEOUT:=5}" # getUpdates long-poll timeout (sec)
: "${TELEGRAM_POLL_MAX_TIME:=10}"   # curl --max-time (sec); must exceed long-poll

# ─── Mock / no-token short-circuit ───────────────────────────────────────────
if [ "${TELEGRAM_MOCK:-0}" = "1" ] || [ "${AGENTBLOC_DEMO:-real}" = "mock" ]; then
  exit 0
fi
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  exit 0
fi

# ─── Dep check ───────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo "[AB-003] jq not found in PATH (telegram-poll.sh requires jq)" >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "telegram-poll.sh: curl not found in PATH" >&2
  exit 1
fi

# ─── Acquire lock (mkdir-atomic, with stale TTL) ─────────────────────────────
acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    return 0
  fi
  # Lock held. Check staleness via mtime.
  if [ -d "$LOCK_DIR" ] \
     && find "$LOCK_DIR" -maxdepth 0 -mmin "+${TELEGRAM_POLL_STALE_MIN}" 2>/dev/null \
        | grep -q .; then
    # Stale. Reclaim and retry once.
    rmdir "$LOCK_DIR" 2>/dev/null || true
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

if ! acquire_lock; then
  # Overlapping tick. Exit fast — design intent.
  exit 0
fi
# shellcheck disable=SC2064  # we want $LOCK_DIR expanded NOW, not on trap
trap "rmdir '$LOCK_DIR' 2>/dev/null || true" EXIT INT TERM

# ─── Load offset ─────────────────────────────────────────────────────────────
OFFSET=0
if [ -f "$OFFSET_FILE" ] && jq -e . "$OFFSET_FILE" >/dev/null 2>&1; then
  OFFSET=$(jq -r '.offset // 0' "$OFFSET_FILE")
fi
NEXT_OFFSET=$(( OFFSET + 1 ))

# ─── getUpdates request ──────────────────────────────────────────────────────
API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates"
RESPONSE=$(curl --silent --show-error --max-time "$TELEGRAM_POLL_MAX_TIME" \
  --get \
  --data-urlencode "timeout=${TELEGRAM_POLL_API_TIMEOUT}" \
  --data-urlencode "offset=${NEXT_OFFSET}" \
  "$API_URL" 2>&1) || {
    echo "telegram-poll.sh: curl failed" >&2
    exit 1
  }

if ! printf '%s' "$RESPONSE" | jq -e '.ok == true' >/dev/null 2>&1; then
  # Telegram API error. Surface description but don't crash cron.
  ERR_DESC=$(printf '%s' "$RESPONSE" | jq -r '.description // "unknown error"' 2>/dev/null || echo "unparseable response")
  echo "telegram-poll.sh: getUpdates returned not-ok: ${ERR_DESC}" >&2
  exit 1
fi

UPDATE_COUNT=$(printf '%s' "$RESPONSE" | jq -r '.result | length')
if [ "$UPDATE_COUNT" = "0" ]; then
  exit 0
fi

# ─── Process each update ─────────────────────────────────────────────────────
# Stream updates one per line as compact JSON; jq -c emits valid JSONL.
MAX_UPDATE_ID=$OFFSET
TS_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

while IFS= read -r update; do
  [ -z "$update" ] && continue
  uid=$(printf '%s' "$update" | jq -r '.update_id')

  # Idempotency: skip if already seen. anchor-grep on update_id key.
  if [ -f "$SEEN_LOG" ] && grep -Fq "\"update_id\":${uid}" "$SEEN_LOG" 2>/dev/null; then
    if [ "$uid" -gt "$MAX_UPDATE_ID" ]; then MAX_UPDATE_ID=$uid; fi
    continue
  fi

  # Append a wrapped record with our receive timestamp + the raw update.
  jq -n -c \
    --arg ts "$TS_ISO" \
    --argjson upd "$update" \
    '{received_at:$ts, update_id:$upd.update_id, update:$upd}' >> "$SEEN_LOG"

  if [ "$uid" -gt "$MAX_UPDATE_ID" ]; then MAX_UPDATE_ID=$uid; fi
done < <(printf '%s' "$RESPONSE" | jq -c '.result[]')

# ─── Persist offset (atomic tmp + mv) ────────────────────────────────────────
TMP_OFFSET="${OFFSET_FILE}.tmp.$$"
jq -n -c \
  --arg ts "$TS_ISO" \
  --argjson off "$MAX_UPDATE_ID" \
  '{offset:$off, updated_at:$ts}' > "$TMP_OFFSET"
mv "$TMP_OFFSET" "$OFFSET_FILE"

exit 0
