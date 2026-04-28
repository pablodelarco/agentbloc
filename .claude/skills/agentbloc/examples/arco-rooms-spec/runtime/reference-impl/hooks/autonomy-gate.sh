#!/usr/bin/env bash
# hooks/autonomy-gate.sh — PreToolUse blast-radius blocker
#
# Registered into <repo>/.claude/settings.local.json by install-demo.sh
# under hooks.PreToolUse with key 'agentbloc-autonomy-gate'. Wave 4.3's
# settings-merge.sh handles the deep-merge.
#
# Contract (Claude Code hooks v2.1+):
#   stdin  = JSON envelope:
#            {
#              "session_id": "...",
#              "transcript_path": "...",
#              "cwd": "...",
#              "tool_name": "Bash" | "Write" | "Edit" | "mcp__*",
#              "tool_input": { ... }
#            }
#   stdout = ignored on exit 0
#   stderr = shown to Claude when exit 2 (block with reason)
#   exit   = 0 allow / 2 block / other = non-blocking error
#
# v2.0 → v2.5 architectural shift:
#   v2.0 had the hook dispatch to an in-process approval-router that
#   long-polled Telegram. v2.5 inverts: the hook checks approvals.jsonl
#   for an existing /approve record matching $CLAUDE_CORRELATION_ID.
#   The agent's wake.md prose is responsible for sending the approval
#   request via telegram-send.sh BEFORE invoking the gated tool, and
#   waiting one cron tick for the /approve to land in approvals.jsonl.
#
# Per-Autonomy Behavior Matrix (v2.5 simplified, sync'd with v2.0
# autonomy-controller.md in Wave 5):
#
#   Tool blast level → Allowed for autonomy
#     L1 read-only            → all (full / semi / supervised)
#     L2 write-scoped         → all
#     L3 write-unrestricted   → full; semi (with approval); supervised (with approval)
#     L4 send-external        → full; semi (with approval); supervised (with approval)
#
# Fail-safe BLOCK posture (Eng Review):
#   - Missing $CLAUDE_AGENT_ID env → BLOCK (refuse to assume).
#   - Unknown tool with side-effect-shaped name → BLOCK (deny by default).
#   - jq missing or stdin malformed → BLOCK.

set -euo pipefail

# ─── Resolve repo root ───────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export AGENTBLOC_HOME="${AGENTBLOC_HOME:-$REPO_ROOT}"

# ─── Fail-safe: $CLAUDE_AGENT_ID required ────────────────────────────────────
AGENT_ID="${CLAUDE_AGENT_ID:-}"
if [ -z "$AGENT_ID" ]; then
  echo "[BLOCK] autonomy-gate: \$CLAUDE_AGENT_ID unset; refusing tool call" >&2
  echo "  Hint: tools must be invoked from within wake.sh, which exports CLAUDE_AGENT_ID." >&2
  exit 2
fi
CORRELATION_ID="${CLAUDE_CORRELATION_ID:-}"

# ─── Load .env (for AGENTBLOC_HOME consistency) ──────────────────────────────
ENV_FILE="${AGENTBLOC_HOME}/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

# ─── jq required ─────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo "[BLOCK] autonomy-gate: jq not in PATH; cannot parse hook stdin" >&2
  exit 2
fi

# ─── Read + parse stdin ──────────────────────────────────────────────────────
INPUT=$(cat || true)
if [ -z "$INPUT" ] || ! printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1; then
  echo "[BLOCK] autonomy-gate: invalid stdin JSON" >&2
  exit 2
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT_JSON=$(printf '%s' "$INPUT" | jq -c '.tool_input // {}')

if [ -z "$TOOL_NAME" ]; then
  echo "[BLOCK] autonomy-gate: tool_name missing from hook input" >&2
  exit 2
fi

# ─── Tool classification (blast level) ───────────────────────────────────────
# v2.5 baseline mapping. Wave 5 surgery formalizes this in
# references/blast-radius.md and adds an MCP tool prefix table.
classify_tool() {
  local tool="$1" input_json="$2"
  case "$tool" in
    Read|Grep|Glob|NotebookRead|BashOutput|TodoWrite|TaskList|TaskGet|TaskOutput)
      echo 1
      return
      ;;
    WebFetch|WebSearch)
      # Read-shaped but reaches the public internet — treat as L4.
      echo 4
      return
      ;;
    Write|Edit|NotebookEdit)
      # Write target inside .agentbloc/agents/<self>/ → L2.
      # Anything else writable → L3.
      local target
      target=$(printf '%s' "$input_json" | jq -r '.file_path // .path // empty')
      if [ -z "$target" ]; then
        echo 3; return
      fi
      case "$target" in
        "${AGENTBLOC_HOME}/.agentbloc/agents/${AGENT_ID}/"*) echo 2 ;;
        *)                                                  echo 3 ;;
      esac
      return
      ;;
    Bash)
      # Bash is hard to classify statically. Conservative default = L3.
      # Sub-classify by command prefix: read-only commands stay at L1.
      local cmd
      cmd=$(printf '%s' "$input_json" | jq -r '.command // empty' | head -c 200)
      case "$cmd" in
        ls\ *|cat\ *|head\ *|tail\ *|grep\ *|find\ *|wc\ *|stat\ *|file\ *|pwd*|echo\ *)
          echo 1 ;;
        # Invoking our own helper scripts is L4 (telegram-send) or L2/3 (write helpers).
        # Match by basename to avoid false positives.
        *telegram-send.sh*|*telegram-poll.sh*) echo 4 ;;
        *) echo 3 ;;
      esac
      return
      ;;
    mcp__*)
      # MCP tools: classify by verb in tool name (post/send/create/etc → L4).
      case "$tool" in
        *send*|*post*|*create*|*update*|*delete*|*transfer*|*pay*|*deploy*|*publish*)
          echo 4 ;;
        *get*|*list*|*search*|*read*|*fetch*|*query*)
          echo 1 ;;
        *) echo 4 ;;  # unknown MCP verb → fail-safe L4
      esac
      return
      ;;
    Task|ExitPlanMode|EnterPlanMode|EnterWorktree|ExitWorktree)
      # Meta tools: agent-internal, no external side effects.
      echo 1
      return
      ;;
    *)
      # Unknown tool: fail-safe L4 BLOCK posture.
      echo 4
      ;;
  esac
}

# ─── Resolve agent autonomy ──────────────────────────────────────────────────
# Reads team/agent-profiles.yaml. Falls back to 'supervised' (most
# restrictive) on any parse failure — fail-safe.
resolve_autonomy() {
  local aid="$1"
  local profile_yaml="${AGENTBLOC_HOME}/.agentbloc/team/agent-profiles.yaml"
  if [ ! -f "$profile_yaml" ] || ! command -v python3 >/dev/null 2>&1; then
    echo "supervised"
    return
  fi
  python3 - <<'PY' "$profile_yaml" "$aid"
import sys, yaml
try:
    with open(sys.argv[1]) as f:
        data = yaml.safe_load(f) or {}
    target = sys.argv[2]
    for agent in (data.get("agents") or []):
        if agent.get("id") == target:
            print(agent.get("autonomy") or "supervised")
            sys.exit(0)
    print("supervised")
except Exception:
    print("supervised")
PY
}

AUTONOMY=$(resolve_autonomy "$AGENT_ID")
BLAST=$(classify_tool "$TOOL_NAME" "$TOOL_INPUT_JSON")

# ─── Approval check (only consulted when needed) ─────────────────────────────
has_approval() {
  local cid="$1"
  local approvals_log="${AGENTBLOC_HOME}/.agentbloc/state/approvals.jsonl"
  [ -z "$cid" ] && return 1
  [ -f "$approvals_log" ] || return 1
  jq -e --arg cid "$cid" \
    'select(.correlation_id == $cid and .decision == "approve")' \
    "$approvals_log" >/dev/null 2>&1
}

# ─── Decision matrix ─────────────────────────────────────────────────────────
case "$AUTONOMY" in
  full)
    # full autonomy proceeds for everything.
    exit 0
    ;;
  semi|supervised)
    if [ "$BLAST" -le 2 ]; then
      # L1-2 always proceed, even for supervised.
      exit 0
    fi
    if has_approval "$CORRELATION_ID"; then
      exit 0
    fi
    cat >&2 <<EOF
[BLOCK] autonomy-gate: tool '${TOOL_NAME}' (L${BLAST}) requires approval
  agent      = ${AGENT_ID}
  autonomy   = ${AUTONOMY}
  correlation= ${CORRELATION_ID:-<unset>}

To unblock:
  1. Send approval request via scripts/telegram-send.sh with this
     correlation-id.
  2. Wait for the operator to reply '/approve ${CORRELATION_ID}' in
     Telegram (or add a record manually to .agentbloc/state/approvals.jsonl
     for testing).
  3. Re-invoke on the next wake tick.
EOF
    exit 2
    ;;
  *)
    echo "[BLOCK] autonomy-gate: unknown autonomy '${AUTONOMY}' for ${AGENT_ID}; failing safe" >&2
    exit 2
    ;;
esac
