#!/usr/bin/env bash
# loop.sh — AGENTBLOC_NO_CRON=1 foreground substitute for system cron
#
# Use cases:
#   - macOS Sonoma+ without Full Disk Access (AB-008)
#   - NixOS / immutable distros without crond
#   - Corporate machines that block 'crontab -'
#   - Local development where seeing the loop output live is useful
#   - CI runners (ubuntu-latest with mock mode)
#
# Run in a foreground terminal:
#   $ ./scripts/loop.sh
#
# Ctrl-C exits cleanly (releases the lockfile, kills in-flight wakes).
#
# Limitation vs system cron:
#   loop.sh is a 1-min-tick simulator, not a full cron parser. It
#   honors `* * * * *` and simple `*/N * * * *` minute fields. For
#   complex schedules (specific hours, weekdays, etc.) install real
#   cron via cron-generator.sh apply. v2.5 demo uses 1-min cadence
#   across the board (Eng Review F5), so this limitation doesn't
#   bite on the demo path.
#
# Lifecycle:
#
#   1. Source helpers + .env. Acquire .agentbloc/runtime/.loop.lock
#      (only one loop.sh per repo).
#   2. Read agent-profiles.yaml (if present) → list of (agent-id,
#      minute-stride). Stride 1 = every tick; stride N = every N ticks.
#   3. Trap INT/TERM → cleanup (kill wakes, rmdir lock).
#   4. Tick loop:
#      a. For each agent whose minute-stride divides this tick: launch
#         wake.sh in background.
#      b. Launch telegram-poll, approval-router, escalation-router.
#      c. If new UTC day: launch activity-feed-merge.
#      d. wait (collects all backgrounds; bounded by per-script timeouts).
#      e. sleep until top of next minute.
#
# Exit codes:
#   0   — clean exit via Ctrl-C
#   1   — fatal: lock held by another instance, missing python3 for
#         agent-profiles parsing
#   2   — bad invocation
#
# Refs: design doc Wave 3.2; Eng Review F5 (1-min cadence).

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

# ─── Paths + tunables ────────────────────────────────────────────────────────
PROFILES_YAML="${AGENTBLOC_HOME}/.agentbloc/team/agent-profiles.yaml"
RUNTIME_DIR="${AGENTBLOC_HOME}/.agentbloc/runtime"
LOCK_DIR="${RUNTIME_DIR}/.loop.lock.d"
LOGS_DIR="${AGENTBLOC_HOME}/.agentbloc/logs"
DAY_MARKER="${RUNTIME_DIR}/.loop.last-day"

mkdir -p "$RUNTIME_DIR" "$LOGS_DIR"

: "${LOOP_TICK_SEC:=60}"

# ─── Acquire foreground lock (single instance per repo) ──────────────────────
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "loop.sh: another instance is already running (lock held at ${LOCK_DIR})" >&2
  echo "  if you're sure not, remove the directory and retry" >&2
  exit 1
fi

# Track child PIDs for clean shutdown.
CHILDREN=()
cleanup() {
  echo ""
  echo "loop.sh: shutting down (received signal or exit)..."
  for pid in "${CHILDREN[@]:-}"; do
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
  done
  rmdir "$LOCK_DIR" 2>/dev/null || true
  echo "loop.sh: done."
}
trap cleanup EXIT INT TERM

# ─── Parse agents from agent-profiles.yaml ───────────────────────────────────
# Output one line per (agent-id, stride-minutes) tuple, tab-separated.
# stride is derived from the cron minute field: "*" → 1, "*/N" → N,
# specific minute "M" → 60 (run once per hour at minute M, but for v2.5
# demo we approximate as every minute since the loop.sh doc disclaims
# complex schedules).
load_agents() {
  if [ ! -f "$PROFILES_YAML" ]; then
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "[AB-009] python3 required to parse agent-profiles.yaml" >&2
    return 1
  fi
  python3 - <<'PY' "$PROFILES_YAML"
import sys, yaml
try:
    with open(sys.argv[1]) as f:
        data = yaml.safe_load(f) or {}
except Exception:
    sys.exit(0)
for agent in (data.get("agents") or []):
    aid = agent.get("id")
    if not aid:
        continue
    for trig in (agent.get("triggers") or []):
        if (trig or {}).get("type") != "cron":
            continue
        sched = trig.get("schedule") or ""
        # Parse minute field (first space-separated token).
        parts = sched.split()
        if not parts:
            continue
        m = parts[0]
        if m == "*":
            stride = 1
        elif m.startswith("*/"):
            try:
                stride = int(m[2:])
            except Exception:
                stride = 1
        else:
            stride = 1  # v2.5 simplification
        print(f"{aid}\t{stride}")
PY
}

# ─── Run a single tick ───────────────────────────────────────────────────────
run_tick() {
  local tick_n="$1"

  # System scripts: every tick.
  bash "${SCRIPT_DIR}/telegram-poll.sh" >>"${LOGS_DIR}/loop.log" 2>&1 &
  CHILDREN+=("$!")
  bash "${SCRIPT_DIR}/approval-router.sh" >>"${LOGS_DIR}/loop.log" 2>&1 &
  CHILDREN+=("$!")
  bash "${SCRIPT_DIR}/escalation-router.sh" >>"${LOGS_DIR}/loop.log" 2>&1 &
  CHILDREN+=("$!")

  # Per-agent wakes: only when stride divides tick_n.
  while IFS=$'\t' read -r aid stride; do
    [ -z "$aid" ] && continue
    if [ $(( tick_n % stride )) -eq 0 ]; then
      bash "${SCRIPT_DIR}/wake.sh" "$aid" cron >>"${LOGS_DIR}/loop.log" 2>&1 &
      CHILDREN+=("$!")
    fi
  done < <(load_agents)

  # Daily: activity-feed-merge fires once per UTC day on first tick of
  # the day. Tracked via DAY_MARKER file.
  TODAY_UTC=$(date -u +%Y-%m-%d)
  LAST_DAY=$(cat "$DAY_MARKER" 2>/dev/null || echo "")
  if [ "$TODAY_UTC" != "$LAST_DAY" ]; then
    bash "${SCRIPT_DIR}/activity-feed-merge.sh" >>"${LOGS_DIR}/loop.log" 2>&1 &
    CHILDREN+=("$!")
    printf '%s\n' "$TODAY_UTC" > "$DAY_MARKER"
  fi

  # Wait for all backgrounds. Each script has its own internal timeout
  # (claude-wrap kills after CLAUDE_WRAP_TIMEOUT_SEC; telegram-poll
  # has --max-time on curl), so 'wait' is bounded.
  wait
  CHILDREN=()
}

# ─── Sleep until top of next minute ──────────────────────────────────────────
sleep_to_next_tick() {
  # Compute seconds until top of next minute. Useful so wake events
  # align with crontab semantics (cron fires at minute boundaries).
  local now_sec
  now_sec=$(date +%S)
  local sleep_sec=$(( LOOP_TICK_SEC - 10#${now_sec} ))
  if [ "$sleep_sec" -le 0 ]; then sleep_sec=$LOOP_TICK_SEC; fi
  sleep "$sleep_sec"
}

# ─── Main loop ───────────────────────────────────────────────────────────────
echo "loop.sh: starting (TICK=${LOOP_TICK_SEC}s, AGENTBLOC_HOME=${AGENTBLOC_HOME})"
echo "  Ctrl-C to stop. Tail logs: tail -F ${LOGS_DIR}/loop.log"
echo ""

# Tick counter — used for stride math. Aligned to UTC minute-of-hour
# so behavior matches what crontab would do at the same wall clock.
TICK=$(( $(date -u +%M) ))

while true; do
  TS=$(date -u +%H:%M:%SZ)
  echo "[$TS] tick=${TICK}" >> "${LOGS_DIR}/loop.log"
  run_tick "$TICK" || true
  TICK=$(( (TICK + 1) % 1440 ))  # wrap at minutes-per-day
  sleep_to_next_tick
done
