#!/usr/bin/env bash
# approval-router.sh — parse telegram-seen.jsonl → approvals.jsonl
#
# Invoked once per cron tick (1-min interval per Eng Review F5):
#
#   $ ./scripts/approval-router.sh
#
# Reads telegram-seen.jsonl (populated by telegram-poll.sh), filters for
# slash-command messages matching /approve|/reject <correlation-id>,
# and appends structured decision records to approvals.jsonl.
#
# Agents that requested approval grep approvals.jsonl for their
# correlation-id at wake time and proceed (approve) or skip (reject).
# Wake.md authoring pattern is documented in
# templates/wake-job-inter.md.tmpl after Wave 5 surgery.
#
# Pointer mechanism:
#   approval-router-pointer.json tracks last_update_id processed. On
#   each tick, only update_ids > last_update_id are considered. This
#   keeps the parser O(new-messages-per-tick) instead of O(seen-log-size).
#
# Slash-command grammar:
#   /approve <correlation-id> [optional reasoning text]
#   /reject  <correlation-id> [optional reasoning text]
#   /deny    <correlation-id> [optional reasoning text]   (alias for v2.0)
#
# Decisions outside the bot's chat_id (if TELEGRAM_CHAT_ID is set) are
# IGNORED — security gate so a stranger DM-ing the bot can't approve.
#
# approvals.jsonl entry schema (single line per decision):
#   timestamp           ISO-8601 UTC
#   correlation_id      from the slash-command
#   decision            "approve" | "reject"
#   reasoning           text after correlation-id, trimmed (may be empty)
#   decider             { id, username, first_name }
#   telegram_update_id  from the source update
#   chat_id             of the message
#
# Modes:
#   TELEGRAM_MOCK=1 / AGENTBLOC_DEMO=mock
#     → still runs (parses an empty / synthetic seen.jsonl). Allows
#       record-demo.sh to inject /approve via telegram-seen.jsonl
#       directly when scripting a mock pipeline.
#
# Exit codes:
#   0  — processed (or nothing-to-do)
#   1  — fatal: missing jq, malformed pointer file
#   2  — bad invocation
#
# Refs: design doc Premise 4 (split from v2.0 monolith); Wave 5 will
#       reconcile references/approval-router.md.

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
SEEN_LOG="${STATE_DIR}/telegram-seen.jsonl"
APPROVALS_LOG="${STATE_DIR}/approvals.jsonl"
POINTER_FILE="${STATE_DIR}/approval-router-pointer.json"
LOCK_DIR="${STATE_DIR}/.approval-router.lock.d"
mkdir -p "$STATE_DIR"

# ─── Tunables ────────────────────────────────────────────────────────────────
: "${APPROVAL_ROUTER_STALE_MIN:=5}"  # stale lock TTL
: "${APPROVAL_ROUTER_CHAT_GUARD:=1}" # 1 = require chat_id == TELEGRAM_CHAT_ID

# ─── Dep check ───────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo "[AB-003] jq not found in PATH (approval-router.sh requires jq)" >&2
  exit 1
fi

# ─── Acquire lock (mkdir-atomic, with stale TTL) ─────────────────────────────
# Same pattern as telegram-poll.sh — overlapping ticks exit fast.
acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    return 0
  fi
  if [ -d "$LOCK_DIR" ] \
     && find "$LOCK_DIR" -maxdepth 0 -mmin "+${APPROVAL_ROUTER_STALE_MIN}" 2>/dev/null \
        | grep -q .; then
    rmdir "$LOCK_DIR" 2>/dev/null || true
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

if ! acquire_lock; then
  exit 0
fi
# shellcheck disable=SC2064
trap "rmdir '$LOCK_DIR' 2>/dev/null || true" EXIT INT TERM

# ─── No seen-log → nothing to do ─────────────────────────────────────────────
if [ ! -f "$SEEN_LOG" ] || [ ! -s "$SEEN_LOG" ]; then
  exit 0
fi

# ─── Load pointer ────────────────────────────────────────────────────────────
LAST_UID=0
if [ -f "$POINTER_FILE" ] && jq -e . "$POINTER_FILE" >/dev/null 2>&1; then
  LAST_UID=$(jq -r '.last_update_id // 0' "$POINTER_FILE")
fi

# ─── Process each new update_id ──────────────────────────────────────────────
# JSONL is one update per line. Filter to update_id > LAST_UID, then
# match the slash-command grammar against message.text. We iterate in
# bash so we can cleanly reject foreign chat_ids.
TS_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NEW_MAX_UID=$LAST_UID
PROCESSED=0

# Use jq to pre-filter and emit one line per candidate. Avoids re-parsing
# every line in bash. Fields we need are projected to a flat shape.
while IFS= read -r line; do
  [ -z "$line" ] && continue

  uid=$(printf '%s' "$line" | jq -r '.update_id // .update.update_id // 0')
  text=$(printf '%s' "$line" | jq -r '.update.message.text // .update.edited_message.text // empty')
  chat_id=$(printf '%s' "$line" | jq -r '.update.message.chat.id // .update.edited_message.chat.id // empty')
  user_id=$(printf '%s' "$line" | jq -r '.update.message.from.id // .update.edited_message.from.id // empty')
  username=$(printf '%s' "$line" | jq -r '.update.message.from.username // .update.edited_message.from.username // empty')
  first_name=$(printf '%s' "$line" | jq -r '.update.message.from.first_name // .update.edited_message.from.first_name // empty')

  if [ "$uid" -gt "$NEW_MAX_UID" ]; then NEW_MAX_UID=$uid; fi
  [ -z "$text" ] && continue

  # Chat-id guard: ignore messages from chats other than the configured
  # TELEGRAM_CHAT_ID. Stops a stranger DM-ing the bot from approving.
  if [ "$APPROVAL_ROUTER_CHAT_GUARD" = "1" ] \
     && [ -n "${TELEGRAM_CHAT_ID:-}" ] \
     && [ -n "$chat_id" ] \
     && [ "$chat_id" != "${TELEGRAM_CHAT_ID}" ]; then
    continue
  fi

  # Match /approve|/reject|/deny <cid> [reasoning]
  # Bash regex: [[ =~ ]]. The ERE captures: 1=cmd, 2=cid, 3=reasoning.
  if [[ "$text" =~ ^/(approve|reject|deny)[[:space:]]+([A-Za-z0-9-]+)[[:space:]]*(.*)$ ]]; then
    cmd=${BASH_REMATCH[1]}
    cid=${BASH_REMATCH[2]}
    reasoning=${BASH_REMATCH[3]}
    # Normalize /deny → reject
    case "$cmd" in
      approve) decision=approve ;;
      reject|deny) decision=reject ;;
      *) continue ;;  # defensive; regex guarantees one of the above
    esac

    # Build approvals.jsonl record. jq -n -c gives valid single-line JSON.
    jq -n -c \
      --arg ts "$TS_ISO" \
      --arg cid "$cid" \
      --arg dec "$decision" \
      --arg reasoning "$reasoning" \
      --arg uid "$uid" \
      --arg chat "$chat_id" \
      --arg uid2 "$user_id" \
      --arg uname "$username" \
      --arg fname "$first_name" \
      '{
        timestamp: $ts,
        correlation_id: $cid,
        decision: $dec,
        reasoning: $reasoning,
        decider: { id: $uid2, username: $uname, first_name: $fname },
        telegram_update_id: ($uid | tonumber? // 0),
        chat_id: $chat
      }' >> "$APPROVALS_LOG"
    PROCESSED=$(( PROCESSED + 1 ))
  fi
done < <(jq -c "select((.update_id // .update.update_id // 0) > ${LAST_UID})" "$SEEN_LOG" 2>/dev/null)

# ─── Persist pointer (atomic tmp + mv) ───────────────────────────────────────
TMP_PTR="${POINTER_FILE}.tmp.$$"
jq -n -c \
  --arg ts "$TS_ISO" \
  --argjson uid "$NEW_MAX_UID" \
  --argjson processed "$PROCESSED" \
  '{last_update_id:$uid, updated_at:$ts, processed_this_tick:$processed}' > "$TMP_PTR"
mv "$TMP_PTR" "$POINTER_FILE"

exit 0
