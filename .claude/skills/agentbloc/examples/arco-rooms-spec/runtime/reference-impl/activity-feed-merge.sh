#!/usr/bin/env bash
# activity-feed-merge.sh — daily unified activity feed (v2.0 D-90 contract)
#
# Invoked once per day by cron (00:05 UTC):
#
#   $ ./scripts/activity-feed-merge.sh           # merge yesterday
#   $ ./scripts/activity-feed-merge.sh 2026-04-26  # merge specific UTC date
#
# Reads the per-domain JSONL logs that accumulated during the day and
# emits a unified activity-feed.jsonl that inspector.html (Wave 7) and
# agentbloc-cost.sh aggregate against.
#
# Sources merged:
#   audit.jsonl          (PostToolUse hook tool calls)
#   cost.jsonl           (claude-wrap.sh runs)
#   approvals.jsonl      (approval-router decisions)
#   escalated.jsonl      (escalation-router watchdog fires)
#   telegram-sent.jsonl  (outbound notifications)
#
# Output entries (one event per line):
#   {timestamp, type, agent, correlation_id, summary, details}
#   where type ∈ {tool_call, cost_run, approval, escalation, telegram}
#
# Idempotency:
#   activity-feed-pointer.json tracks last_merged_utc_date. We never
#   re-merge an already-merged day. Today is skipped (still in flight).
#
# Refs: design doc Wave 3.3 (D-90 contract), inspector.html (Wave 7.7).

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

# ─── Paths ───────────────────────────────────────────────────────────────────
LOGS_DIR="${AGENTBLOC_HOME}/.agentbloc/logs"
STATE_DIR="${AGENTBLOC_HOME}/.agentbloc/state"
FEED="${LOGS_DIR}/activity-feed.jsonl"
POINTER="${LOGS_DIR}/activity-feed-pointer.json"

mkdir -p "$LOGS_DIR" "$STATE_DIR"

# ─── Dep check ───────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo "[AB-003] jq not found in PATH (activity-feed-merge.sh requires jq)" >&2
  exit 1
fi

# ─── Determine target date ───────────────────────────────────────────────────
if [ "$#" -ge 1 ] && [ -n "${1:-}" ]; then
  TARGET="$1"
  # Validate YYYY-MM-DD shape.
  if ! [[ "$TARGET" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "activity-feed-merge.sh: bad date format '${TARGET}', expected YYYY-MM-DD" >&2
    exit 2
  fi
else
  # Default = yesterday in UTC (BSD vs GNU date).
  TARGET=$(date -u -v-1d +%Y-%m-%d 2>/dev/null || date -u -d 'yesterday' +%Y-%m-%d)
fi

TODAY_UTC=$(date -u +%Y-%m-%d)
if [ "$TARGET" = "$TODAY_UTC" ]; then
  echo "activity-feed-merge.sh: refusing to merge today (${TARGET}); pass yesterday or earlier"
  exit 0
fi

# ─── Idempotency pointer ─────────────────────────────────────────────────────
if [ -f "$POINTER" ] && jq -e . "$POINTER" >/dev/null 2>&1; then
  LAST_MERGED=$(jq -r '.last_merged_utc_date // ""' "$POINTER")
  if [ "$LAST_MERGED" = "$TARGET" ] || [ "$LAST_MERGED" \> "$TARGET" ]; then
    echo "activity-feed-merge.sh: ${TARGET} already merged (pointer: ${LAST_MERGED})"
    exit 0
  fi
fi

# ─── Filter helper: select JSONL lines whose .timestamp starts with date ─────
filter_date() {
  local file="$1"
  if [ ! -f "$file" ]; then return 0; fi
  jq -c --arg d "$TARGET" 'select((.timestamp // "") | startswith($d))' "$file" 2>/dev/null || true
}

# ─── Build the day's feed entries ────────────────────────────────────────────
TS_NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TMP_FEED=$(mktemp)
trap "rm -f '$TMP_FEED'" EXIT

EVENT_COUNT=0

# audit.jsonl → tool_call events (Wave 4.2 schema, Eng Review D1)
while IFS= read -r line; do
  [ -z "$line" ] && continue
  jq -n -c \
    --argjson src "$line" \
    '{
       timestamp: ($src.timestamp // ""),
       type: "tool_call",
       agent: ($src.agent // ""),
       correlation_id: ($src.correlation_id // ""),
       summary: (($src.tool // "tool") + " on " + ($src.target // "?") + " → " + ($src.result // "?")),
       details: $src
     }' >> "$TMP_FEED"
  EVENT_COUNT=$(( EVENT_COUNT + 1 ))
done < <(filter_date "${LOGS_DIR}/audit.jsonl")

# cost.jsonl → cost_run events (claude-wrap)
while IFS= read -r line; do
  [ -z "$line" ] && continue
  jq -n -c \
    --argjson src "$line" \
    '{
       timestamp: ($src.timestamp // ""),
       type: "cost_run",
       agent: ($src.agent // ""),
       correlation_id: ($src.correlation_id // ""),
       summary: ("claude-p run cost=$" + ($src.total_cost_usd // 0 | tostring) + " err=" + ($src.is_error // false | tostring)),
       details: $src
     }' >> "$TMP_FEED"
  EVENT_COUNT=$(( EVENT_COUNT + 1 ))
done < <(filter_date "${LOGS_DIR}/cost.jsonl")

# approvals.jsonl → approval events
while IFS= read -r line; do
  [ -z "$line" ] && continue
  jq -n -c \
    --argjson src "$line" \
    '{
       timestamp: ($src.timestamp // ""),
       type: "approval",
       agent: "",
       correlation_id: ($src.correlation_id // ""),
       summary: (($src.decision // "?") + " by " + ($src.decider.username // $src.decider.first_name // "operator")),
       details: $src
     }' >> "$TMP_FEED"
  EVENT_COUNT=$(( EVENT_COUNT + 1 ))
done < <(filter_date "${STATE_DIR}/approvals.jsonl")

# escalated.jsonl → escalation events
while IFS= read -r line; do
  [ -z "$line" ] && continue
  jq -n -c \
    --argjson src "$line" \
    '{
       timestamp: ($src.timestamp // ""),
       type: "escalation",
       agent: "",
       correlation_id: ($src.original_cid // ""),
       summary: ("escalation tier " + ($src.tier // 0 | tostring) + " for " + ($src.original_cid // "?")),
       details: $src
     }' >> "$TMP_FEED"
  EVENT_COUNT=$(( EVENT_COUNT + 1 ))
done < <(filter_date "${STATE_DIR}/escalated.jsonl")

# telegram-sent.jsonl → telegram events
while IFS= read -r line; do
  [ -z "$line" ] && continue
  jq -n -c \
    --argjson src "$line" \
    '{
       timestamp: ($src.timestamp // ""),
       type: "telegram",
       agent: "",
       correlation_id: ($src.correlation_id // ""),
       summary: ("telegram " + ($src.outcome // "?") + ": " + (($src.envelope.text // "") | tostring | .[:80])),
       details: $src
     }' >> "$TMP_FEED"
  EVENT_COUNT=$(( EVENT_COUNT + 1 ))
done < <(filter_date "${STATE_DIR}/telegram-sent.jsonl")

# ─── Sort by timestamp, append to activity-feed.jsonl ────────────────────────
if [ "$EVENT_COUNT" -gt 0 ]; then
  sort < "$TMP_FEED" >> "$FEED"
fi

# ─── Update pointer atomically ───────────────────────────────────────────────
TMP_PTR="${POINTER}.tmp.$$"
jq -n -c \
  --arg ts "$TS_NOW" \
  --arg date "$TARGET" \
  --argjson n "$EVENT_COUNT" \
  '{last_merged_utc_date:$date, last_merged_at:$ts, events_merged:$n}' > "$TMP_PTR"
mv "$TMP_PTR" "$POINTER"

echo "activity-feed-merge.sh: merged ${EVENT_COUNT} events for ${TARGET}"
echo "  feed:    ${FEED}"
echo "  pointer: ${POINTER}"
