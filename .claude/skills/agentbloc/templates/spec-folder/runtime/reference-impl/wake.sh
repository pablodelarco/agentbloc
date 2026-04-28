#!/usr/bin/env bash
# wake.sh — AgentBloc v2.5 cron entry point
#
# Invoked once per agent per cron tick:
#
#   $ ./scripts/wake.sh <agent-id> [trigger-source]
#
# Mounted into crontab via cron-generator.sh (Wave 3.1). Also invoked
# in-process by loop.sh (Wave 3.2) when AGENTBLOC_NO_CRON=1.
#
# Lifecycle (ASCII):
#
#   ┌────────────────────────────────────────────────────────────────┐
#   │  cron / loop.sh                                                 │
#   │     │                                                           │
#   │     ▼                                                           │
#   │  wake.sh <agent-id>                                             │
#   │     │                                                           │
#   │     ├─▶ source helpers.sh           (frozen API surface)        │
#   │     ├─▶ source .env (if present)    (TELEGRAM_BOT_TOKEN etc.)   │
#   │     ├─▶ check_kill_switch <id>      ──▶ exit 0 if halt active   │
#   │     │       (team-wide KILL_SWITCH +                            │
#   │     │        per-agent pause file)                              │
#   │     ├─▶ inbox_janitor <id>          (sweep stale .tmp +         │
#   │     │                                processing/ + processed/)  │
#   │     ├─▶ gen_correlation_id <src>    ──▶ CLAUDE_CORRELATION_ID   │
#   │     ├─▶ export CLAUDE_AGENT_ID      (autonomy hook reads this)  │
#   │     └─▶ claude-wrap.sh <id> <cid>   (claude -p < wake.md,       │
#   │                                      cost capture, log to       │
#   │                                      claude-runs/<cid>.log)     │
#   │                                                                 │
#   │  Exit 0 — wake completed (claude-wrap may have errored;          │
#   │            that's logged but doesn't fail the cron line).       │
#   │  Exit 1 — kill switch active OR fatal precondition failed.      │
#   └────────────────────────────────────────────────────────────────┘
#
# Halt is "soft": kill_switch causes exit 0, not exit 1, so cron's
# MAILTO doesn't spam on every tick while the team is paused. The
# audit log line at the top of the wake records the halt for forensics.
#
# Design references:
# - Three-point kill switch: D-86 + .claude/skills/agentbloc/references/security-patterns.md
# - Inbox-handoff lifecycle: .claude/skills/agentbloc/references/runtime-coordination.md
# - Correlation ID format (D-75): .claude/skills/agentbloc/references/correlation-id.md

set -euo pipefail

# ─── Resolve repo root + helpers ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export AGENTBLOC_HOME="${AGENTBLOC_HOME:-$REPO_ROOT}"

# shellcheck source=helpers.sh
. "${SCRIPT_DIR}/helpers.sh"

# ─── Argument parsing ────────────────────────────────────────────────────────
AGENT_ID="${1:-}"
TRIGGER_SOURCE="${2:-cron}"

if [ -z "$AGENT_ID" ]; then
  echo "wake.sh: agent-id required" >&2
  echo "usage: wake.sh <agent-id> [trigger-source]" >&2
  echo "       trigger-source ∈ { cron | telegram | inter | manual | webhook-* }" >&2
  exit 2
fi

# ─── Load .env (best-effort) ─────────────────────────────────────────────────
# Cron jobs have a minimal env. We rely on .env for TELEGRAM_BOT_TOKEN,
# ANTHROPIC_API_KEY, AGENTBLOC_DEMO, AGENTBLOC_NO_CRON, INBOX_* tunables.
# .env is gitignored (see .env.example). Missing .env is fine — the demo
# defaults already let the runtime smoke-test pass in MOCK mode.
ENV_FILE="${AGENTBLOC_HOME}/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

# ─── Kill switch (team-wide + per-agent) ─────────────────────────────────────
if ! check_kill_switch "$AGENT_ID"; then
  # Halt logged to stderr by check_kill_switch. Exit 0 so cron doesn't
  # mail-spam during a planned pause.
  exit 0
fi

# ─── Janitor sweep (non-fatal; never blocks the wake) ────────────────────────
inbox_janitor "$AGENT_ID" || true

# ─── Correlation ID + export to claude-wrap + hooks ──────────────────────────
CLAUDE_CORRELATION_ID="$(gen_correlation_id "$TRIGGER_SOURCE")"
export CLAUDE_CORRELATION_ID
export CLAUDE_AGENT_ID="$AGENT_ID"
export CLAUDE_TRIGGER_SOURCE="$TRIGGER_SOURCE"

# ─── Resolve agent wake.md prompt ────────────────────────────────────────────
WAKE_MD="${AGENTBLOC_HOME}/.agentbloc/agents/${AGENT_ID}/wake.md"
if [ ! -f "$WAKE_MD" ]; then
  echo "wake.sh: missing wake.md for agent '${AGENT_ID}' at ${WAKE_MD}" >&2
  exit 1
fi

# ─── Hand off to claude-wrap ─────────────────────────────────────────────────
# claude-wrap.sh owns: timeout, output capture, cost.jsonl append, audit
# stamp. wake.sh's job ends after the handoff. Any error from claude-wrap
# is logged there (not propagated as cron failure) so a bad model run
# doesn't blackhole the schedule.
exec "${SCRIPT_DIR}/claude-wrap.sh" "$AGENT_ID" "$CLAUDE_CORRELATION_ID" "$WAKE_MD"
