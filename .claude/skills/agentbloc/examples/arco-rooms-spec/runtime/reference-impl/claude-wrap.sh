#!/usr/bin/env bash
# claude-wrap.sh — cost-capturing `claude -p` invoker
#
# Invoked once per wake by wake.sh:
#
#   $ ./scripts/claude-wrap.sh <agent-id> <correlation-id> <wake-md-path>
#
# Owns all `claude -p` invocations in v2.5. Centralizing here gives us
# one place to enforce timeout, capture cost JSON, redact PII, and
# emit the per-run audit envelope.
#
# Wraps the spike-locked invocation (docs/notes/claude-wrap-spike.md):
#   claude -p --output-format json --max-budget-usd "$MAX_BUDGET" < wake.md
#
# Spike confirmed `claude -p --output-format json` emits a single-line
# JSON result containing `total_cost_usd`, `usage.{input_tokens,
# cache_read_input_tokens, output_tokens}`, `duration_ms`, `is_error`,
# and `result`. We extract those via jq and append to cost.jsonl.
#
# Output disposition:
#   - Raw single-line JSON (stdout of claude -p) → claude-runs/<cid>.log
#   - One cost.jsonl line per run                  → cost.jsonl
#   - Model's result text                          → stdout (cron MAILTO
#                                                    or /dev/null per
#                                                    crontab line)
#   - Errors                                       → stderr
#
# Exit codes:
#   0  — claude -p completed (model may have errored; that's logged not propagated)
#   1  — fatal precondition (missing claude, missing wake.md, missing jq)
#   124 — timeout (`timeout` exit code)
#
# A model-side error (is_error:true in JSON) is recorded in cost.jsonl
# with is_error:true but does NOT fail the wrapper, so the next cron
# tick can retry without operator intervention.
#
# Refs:
# - docs/notes/claude-wrap-spike.md (Eng Review D5 path A)
# - .claude/skills/agentbloc/references/audit-logging.md (cost.jsonl is
#   separate from audit.jsonl per Eng Review D1)

set -euo pipefail

# ─── Resolve repo root + helpers ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export AGENTBLOC_HOME="${AGENTBLOC_HOME:-$REPO_ROOT}"

# shellcheck source=helpers.sh
. "${SCRIPT_DIR}/helpers.sh"

# ─── Argument parsing ────────────────────────────────────────────────────────
AGENT_ID="${1:-}"
CORRELATION_ID="${2:-}"
WAKE_MD="${3:-}"

if [ -z "$AGENT_ID" ] || [ -z "$CORRELATION_ID" ] || [ -z "$WAKE_MD" ]; then
  echo "claude-wrap.sh: agent-id, correlation-id, and wake-md path are required" >&2
  echo "usage: claude-wrap.sh <agent-id> <correlation-id> <wake-md-path>" >&2
  exit 2
fi

if [ ! -f "$WAKE_MD" ]; then
  echo "claude-wrap.sh: wake-md not found: ${WAKE_MD}" >&2
  exit 1
fi

# ─── Tunables (from .env, with conservative defaults) ────────────────────────
: "${CLAUDE_WRAP_TIMEOUT_SEC:=120}"      # per-invocation hard timeout
: "${CLAUDE_WRAP_MAX_BUDGET_USD:=0.50}"  # second-line cost ceiling
: "${CLAUDE_WRAP_BARE:=0}"               # 1 = pass --bare (skips hooks/LSP/auto-memory)

# ─── Dependency checks (fail-fast, mapped to AB-NNN codes) ───────────────────
# AB-001: claude missing — install-demo.sh enforces this at install time
#         too. Wake-time check exists for users who uninstalled claude after
#         install or whose PATH was truncated under cron.
if ! command -v claude >/dev/null 2>&1; then
  echo "[AB-001] claude CLI not found in PATH" >&2
  echo "  Why: cron's PATH may differ from your shell PATH" >&2
  echo "  Fix: ensure claude is at /opt/homebrew/bin/claude or set PATH in crontab" >&2
  exit 1
fi

# AB-003: jq missing — required for parsing the result JSON.
if ! command -v jq >/dev/null 2>&1; then
  echo "[AB-003] jq not found in PATH" >&2
  echo "  Why: claude-wrap.sh parses --output-format json with jq" >&2
  echo "  Fix: brew install jq  (macOS)  |  apt-get install jq  (Linux)" >&2
  exit 1
fi

# `timeout` is GNU coreutils on Linux; on macOS it's `gtimeout` from
# coreutils-via-brew. install-demo.sh checks this; we fall back to
# `gtimeout` if `timeout` is missing so the wrapper still works on
# stock macOS with brew-installed coreutils.
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
else
  echo "claude-wrap.sh: neither 'timeout' nor 'gtimeout' found; cannot enforce CLAUDE_WRAP_TIMEOUT_SEC" >&2
  echo "  Fix: brew install coreutils  (macOS)  |  already present on Linux" >&2
  exit 1
fi

# ─── Output paths ────────────────────────────────────────────────────────────
LOGS_ROOT="${AGENTBLOC_HOME}/.agentbloc/logs"
RUNS_DIR="${LOGS_ROOT}/claude-runs"
COST_LOG="${LOGS_ROOT}/cost.jsonl"
RUN_LOG="${RUNS_DIR}/${CORRELATION_ID}.log"

mkdir -p "$RUNS_DIR"

# ─── Build claude argv ───────────────────────────────────────────────────────
# Per spike: --output-format json gives us cost+token JSON; --max-budget-usd
# is the hard ceiling (cron interval is the soft ceiling). --bare is opt-in
# via env because it disables auto-memory and OAuth keychain auth.
CLAUDE_ARGV=(claude -p --output-format json --max-budget-usd "$CLAUDE_WRAP_MAX_BUDGET_USD")
if [ "$CLAUDE_WRAP_BARE" = "1" ]; then
  CLAUDE_ARGV+=(--bare)
fi

# ─── Invoke with timeout, capture stdout to RUN_LOG ──────────────────────────
# stdin = wake.md contents (the prompt)
# stdout = single-line JSON result → captured to RUN_LOG
# stderr = passes through to cron MAILTO / cron log
START_EPOCH_MS=$(date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))')
RUN_EXIT=0
"$TIMEOUT_BIN" --kill-after=5s "$CLAUDE_WRAP_TIMEOUT_SEC" "${CLAUDE_ARGV[@]}" \
  < "$WAKE_MD" > "$RUN_LOG" 2>>"${LOGS_ROOT}/claude-wrap.stderr.log" || RUN_EXIT=$?
END_EPOCH_MS=$(date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))')
WALL_MS=$(( END_EPOCH_MS - START_EPOCH_MS ))

# ─── Parse result JSON for cost.jsonl ────────────────────────────────────────
# If timeout fired (124) or claude itself crashed before writing JSON,
# RUN_LOG may be empty or invalid. We still emit a cost.jsonl line so
# operators see the failure in inspector + agentbloc-cost.sh.
TS_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [ -s "$RUN_LOG" ] && jq -e . "$RUN_LOG" >/dev/null 2>&1; then
  # Valid JSON. Extract canonical fields. jq -r prints "null" if the field
  # is missing — guard against that with // 0 / // false / // "unknown".
  TOTAL_COST_USD=$(jq -r '.total_cost_usd // 0' "$RUN_LOG")
  IN_TOKENS=$(jq -r '.usage.input_tokens // 0' "$RUN_LOG")
  CACHE_READ_TOKENS=$(jq -r '.usage.cache_read_input_tokens // 0' "$RUN_LOG")
  OUT_TOKENS=$(jq -r '.usage.output_tokens // 0' "$RUN_LOG")
  DURATION_MS=$(jq -r '.duration_ms // 0' "$RUN_LOG")
  IS_ERROR=$(jq -r '.is_error // false' "$RUN_LOG")
  MODEL_ID=$(jq -r '(.modelUsage // {}) | keys[0] // "unknown"' "$RUN_LOG")
  RESULT_TEXT=$(jq -r '.result // ""' "$RUN_LOG")
else
  # Either timeout, crash before write, or non-JSON output. Synthesize a
  # cost record so the failure is auditable.
  TOTAL_COST_USD=0
  IN_TOKENS=0
  CACHE_READ_TOKENS=0
  OUT_TOKENS=0
  DURATION_MS="$WALL_MS"
  IS_ERROR=true
  MODEL_ID="unknown"
  RESULT_TEXT=""
fi

# ─── Append cost.jsonl entry ─────────────────────────────────────────────────
# jq -n -c builds a valid single-line JSON object with proper quoting.
# Schema matches docs/notes/claude-wrap-spike.md "cost.jsonl entry shape".
jq -n -c \
  --arg ts "$TS_ISO" \
  --arg cid "$CORRELATION_ID" \
  --arg agent "$AGENT_ID" \
  --arg model "$MODEL_ID" \
  --argjson cost "$TOTAL_COST_USD" \
  --argjson in_tok "$IN_TOKENS" \
  --argjson cache_tok "$CACHE_READ_TOKENS" \
  --argjson out_tok "$OUT_TOKENS" \
  --argjson dur "$DURATION_MS" \
  --argjson wall "$WALL_MS" \
  --argjson err "$IS_ERROR" \
  --argjson exit "$RUN_EXIT" \
  '{
     timestamp: $ts,
     correlation_id: $cid,
     agent: $agent,
     model: $model,
     total_cost_usd: $cost,
     input_tokens: $in_tok,
     cache_read_input_tokens: $cache_tok,
     output_tokens: $out_tok,
     duration_ms: $dur,
     wall_ms: $wall,
     is_error: $err,
     exit_code: $exit
   }' >> "$COST_LOG"

# ─── Print model result to stdout ────────────────────────────────────────────
# wake.md prompts produce action descriptions. Whatever the model returned
# in `.result` flows to wake.sh's stdout (cron MAILTO or /dev/null). The
# raw JSON is in RUN_LOG for forensics.
if [ -n "$RESULT_TEXT" ]; then
  printf '%s\n' "$RESULT_TEXT"
fi

# Always exit 0 unless the runner itself failed for non-claude reasons
# (timeout's 124 stays as 124 so loop.sh / monitoring see it, but a
# model-side error logged in cost.jsonl with is_error:true exits 0
# so cron doesn't mail-spam on every retry).
if [ "$RUN_EXIT" = 124 ]; then
  echo "claude-wrap.sh: ${TIMEOUT_BIN} fired after ${CLAUDE_WRAP_TIMEOUT_SEC}s for ${AGENT_ID} ${CORRELATION_ID}" >&2
  exit 124
fi
exit 0
