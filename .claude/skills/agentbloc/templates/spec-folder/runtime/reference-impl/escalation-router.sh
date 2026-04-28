#!/usr/bin/env bash
# escalation-router.sh — approval-timeout escalation (Wave 2.4 / D-86)
#
# Invoked once per cron tick (1-min interval per Eng Review F5):
#
#   $ ./scripts/escalation-router.sh
#
# Detects approval requests that have been sent but not resolved within
# their timeout window, and re-pings the operator on the escalations
# channel (or the same chat with stronger framing if no separate
# escalations chat is configured).
#
# This is NOT the v2.0 4-part escalation-on-agent-failure mechanism
# (that lives in agent prose, calling telegram-send.sh directly).
# This is the timeout watchdog for unresponded approvals — D-86 in
# v2.0 spec, Premise 4 in the v2.5 design doc.
#
# Pending detection (per-tick):
#   pending = telegram-sent.jsonl minus approvals.jsonl minus escalated.jsonl
#   For each pending entry, if (now - sent_at) > ESCALATION_TIMEOUT_SEC,
#   escalate and append to escalated.jsonl.
#
# Dedup gotcha:
#   telegram-send.sh dedups by correlation_id. If we re-sent under the
#   original cid, it would be skipped. Instead we derive a child cid:
#     <original-cid>-esc<tier>
#   tier starts at 1; subsequent ticks while still pending → esc2, esc3...
#   Tier ceiling = ESCALATION_MAX_TIER (default 3). After ceiling,
#   silent-skip rather than spam the operator.
#
# Tunables (.env):
#   ESCALATION_TIMEOUT_SEC=3600              (default 1 hour)
#   ESCALATION_MAX_TIER=3
#   ESCALATION_CHAT_ID                       (falls back to TELEGRAM_CHAT_ID)
#   ESCALATION_THREAD_ID                     (forum-topic supergroups)
#
# Modes:
#   TELEGRAM_MOCK=1 / AGENTBLOC_DEMO=mock
#     → still runs. telegram-send.sh handles MOCK routing internally,
#       so escalations land in telegram-out.jsonl during CI/demo.
#
# Exit codes:
#   0  — processed (or nothing pending)
#   1  — fatal: missing jq
#
# Refs: design doc Premise 4; v2.0 spec D-86; Wave 5 reconciles
#       references/escalation-protocol.md (currently describes the
#       v2.0 agent-failure path, not the timeout watchdog).

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
SENT_LOG="${STATE_DIR}/telegram-sent.jsonl"
APPROVALS_LOG="${STATE_DIR}/approvals.jsonl"
ESCALATED_LOG="${STATE_DIR}/escalated.jsonl"
LOCK_DIR="${STATE_DIR}/.escalation-router.lock.d"
mkdir -p "$STATE_DIR"

# ─── Tunables ────────────────────────────────────────────────────────────────
: "${ESCALATION_TIMEOUT_SEC:=3600}"   # 1 hour default
: "${ESCALATION_MAX_TIER:=3}"
: "${ESCALATION_STALE_MIN:=5}"        # lock TTL

# ─── Dep check ───────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo "[AB-003] jq not found in PATH (escalation-router.sh requires jq)" >&2
  exit 1
fi

# ─── Acquire lock ────────────────────────────────────────────────────────────
acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    return 0
  fi
  if [ -d "$LOCK_DIR" ] \
     && find "$LOCK_DIR" -maxdepth 0 -mmin "+${ESCALATION_STALE_MIN}" 2>/dev/null \
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

# ─── No sent-log → nothing to watch ──────────────────────────────────────────
if [ ! -f "$SENT_LOG" ] || [ ! -s "$SENT_LOG" ]; then
  exit 0
fi

# ─── Build resolved + already-escalated cid sets ─────────────────────────────
# Read approvals.jsonl correlation-ids into a sorted file we can grep -F.
RESOLVED_TMP="${STATE_DIR}/.escalation-resolved.$$"
ESCALATED_TMP="${STATE_DIR}/.escalation-escalated.$$"
trap "rm -f '$RESOLVED_TMP' '$ESCALATED_TMP'; rmdir '$LOCK_DIR' 2>/dev/null || true" EXIT INT TERM

if [ -f "$APPROVALS_LOG" ]; then
  jq -r '.correlation_id // empty' "$APPROVALS_LOG" 2>/dev/null | sort -u > "$RESOLVED_TMP" || : > "$RESOLVED_TMP"
else
  : > "$RESOLVED_TMP"
fi

# Existing escalations: each line records {original_cid, tier, ts}. We
# track per-tier so the same cid can escalate up to ESCALATION_MAX_TIER.
if [ -f "$ESCALATED_LOG" ]; then
  jq -r '"\(.original_cid)|\(.tier)"' "$ESCALATED_LOG" 2>/dev/null | sort -u > "$ESCALATED_TMP" || : > "$ESCALATED_TMP"
else
  : > "$ESCALATED_TMP"
fi

# ─── Resolve escalation chat target ──────────────────────────────────────────
ESCALATION_TARGET_CHAT="${ESCALATION_CHAT_ID:-${TELEGRAM_CHAT_ID:-}}"

NOW_EPOCH=$(date +%s)
TS_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ESCALATED_COUNT=0

# ─── Iterate sent log for pending escalations ────────────────────────────────
# Only consider lines where correlation_id appears to be an approval
# request (envelope text starts with "**APPROVAL" or contains
# "/approve" — heuristic; v3.0 introduces an explicit envelope.kind
# field). For now, we escalate every unresolved sent message to
# preserve safety on the side of caution.
while IFS= read -r line; do
  [ -z "$line" ] && continue
  cid=$(printf '%s' "$line" | jq -r '.correlation_id // empty')
  sent_ts=$(printf '%s' "$line" | jq -r '.timestamp // empty')
  [ -z "$cid" ] && continue
  [ -z "$sent_ts" ] && continue

  # Skip resolved.
  if grep -Fxq "$cid" "$RESOLVED_TMP" 2>/dev/null; then
    continue
  fi

  # Compute age in seconds. date -d (GNU) vs -j (BSD/macOS) — try both.
  sent_epoch=$(date -u -d "$sent_ts" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$sent_ts" +%s 2>/dev/null || echo 0)
  if [ "$sent_epoch" = "0" ]; then
    continue  # unparseable timestamp; skip rather than mis-escalate
  fi
  age=$(( NOW_EPOCH - sent_epoch ))
  if [ "$age" -lt "$ESCALATION_TIMEOUT_SEC" ]; then
    continue  # still within timeout window
  fi

  # Determine next tier for this cid.
  tier=1
  while [ "$tier" -le "$ESCALATION_MAX_TIER" ]; do
    if ! grep -Fxq "${cid}|${tier}" "$ESCALATED_TMP" 2>/dev/null; then
      break
    fi
    tier=$(( tier + 1 ))
  done
  if [ "$tier" -gt "$ESCALATION_MAX_TIER" ]; then
    continue  # ceiling reached; silent
  fi

  # Build escalation message + child correlation-id.
  child_cid="${cid}-esc${tier}"
  age_min=$(( age / 60 ))

  # Build envelope JSON for telegram-send.sh.
  ENV_JSON=$(jq -n -c \
    --arg cid "$cid" \
    --arg child "$child_cid" \
    --arg tier "$tier" \
    --arg age "$age_min" \
    --arg chat "$ESCALATION_TARGET_CHAT" \
    --arg thread "${ESCALATION_THREAD_ID:-}" \
    '{
       text: ("ESCALATION (tier " + $tier + ") — approval pending " + $age + " min for " + $cid + "\nReply: /approve " + $cid + " | /reject " + $cid),
       chat_id: $chat,
       tier: "action_required"
     }
     | (if ($thread | length) > 0 then . + {message_thread_id: ($thread | tonumber? // 0)} else . end)')

  # Hand off to telegram-send.sh. We deliberately ignore its exit code
  # at the per-cid level — a single-cid send failure shouldn't block
  # other escalations on this tick. Real-mode failures land in
  # telegram-failed.jsonl; mock mode always succeeds.
  if printf '%s' "$ENV_JSON" | "${SCRIPT_DIR}/telegram-send.sh" "$child_cid" 2>>"${STATE_DIR}/escalation-router.stderr.log"; then
    jq -n -c \
      --arg ts "$TS_ISO" \
      --arg cid "$cid" \
      --arg child "$child_cid" \
      --argjson tier "$tier" \
      --argjson age "$age" \
      '{timestamp:$ts, original_cid:$cid, child_cid:$child, tier:$tier, age_sec:$age}' >> "$ESCALATED_LOG"
    ESCALATED_COUNT=$(( ESCALATED_COUNT + 1 ))
  fi
done < <(jq -c 'select(.correlation_id and .timestamp)' "$SENT_LOG" 2>/dev/null)

# ─── Cleanup is in the trap; just exit ───────────────────────────────────────
exit 0
