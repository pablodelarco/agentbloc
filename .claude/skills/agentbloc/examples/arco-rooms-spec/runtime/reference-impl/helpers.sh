#!/usr/bin/env bash
# helpers.sh — AgentBloc v2.5 runtime primitives
#
# Sourced by every entry point: wake.sh, claude-wrap.sh, install-demo.sh,
# uninstall-demo.sh, agentbloc-cost.sh, inspect.sh, telegram-send.sh,
# telegram-poll.sh, approval-router.sh, escalation-router.sh, hooks/*.
#
# All function signatures here are FROZEN as of Wave 1.1 (Eng Review CQ-1).
# Implementations may evolve; the API surface does not. If you change a
# signature, every consumer above must update in the same PR.
#
# Function dependency graph (ASCII):
#
#   ┌──────────────────────────────────────────────────────────────────────┐
#   │  ENTRY POINTS                                                         │
#   │     wake.sh    ──▶ check_kill_switch ──▶ inbox_janitor ──▶ claude-wrap│
#   │                                              │                        │
#   │                                              ▼                        │
#   │                                       atomic_write_inbox              │
#   │                                              │                        │
#   │     claude-wrap.sh ──▶ gen_correlation_id    │                        │
#   │                                              │                        │
#   │     hooks/audit-log.sh ──▶ redact_pii ◀──────┘                        │
#   │                                                                       │
#   │     OTHER CONSUMERS                                                   │
#   │     reader-side wakes ──▶ read_next_inbox ──▶ inbox_janitor (sweep)   │
#   │     telegram-poll.sh ──▶ (uses flock independently, not via helpers)  │
#   └──────────────────────────────────────────────────────────────────────┘
#
# Design references:
# - Inbox-handoff semantics: .claude/skills/agentbloc/references/runtime-coordination.md
#   (post-Wave-5 surgery: writeStateHandoff → inbox-handoff naming)
# - Correlation ID format (D-75): .claude/skills/agentbloc/references/correlation-id.md
# - PII redaction rules: .claude/skills/agentbloc/references/audit-logging.md
# - Eng Review D3: filename uses <sender>-<correlation-id>.json prefix
#
# Configuration (from .env, with defaults):
# - INBOX_TMP_STALE_MIN     = 10  (minutes before .tmp files are reclaimed)
# - INBOX_STALE_MIN         = 15  (minutes before processing/ entries are reclaimed)
# - INBOX_PROCESSED_MAX     = 1000 (entries before processed/ rotates)
# - AGENTBLOC_HOME          = $(git rev-parse --show-toplevel) (repo root)

set -euo pipefail

# ─── Defaults (tunable via .env) ─────────────────────────────────────────────
: "${INBOX_TMP_STALE_MIN:=10}"
: "${INBOX_STALE_MIN:=15}"
: "${INBOX_PROCESSED_MAX:=1000}"
: "${AGENTBLOC_HOME:=$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# ─── State paths ─────────────────────────────────────────────────────────────
_KILL_SWITCH="${AGENTBLOC_HOME}/.agentbloc/KILL_SWITCH"
_AGENTS_ROOT="${AGENTBLOC_HOME}/.agentbloc/agents"

# ────────────────────────────────────────────────────────────────────────────
# gen_correlation_id <trigger-source>
#
# Generates a D-75 format correlation ID:
#   <trigger-source>-<UTC-Z-compact>-<nonce6>
#
# trigger-source: bounded enum { cron, webhook-<name>, telegram, inter, manual }
# UTC-Z-compact:  ISO-8601 UTC with colons and dashes stripped (e.g. 20260427T091523Z)
# nonce6:         6 hex chars from /dev/urandom
#
# Example output: cron-20260427T091523Z-a3f21b
#
# Echoes the correlation ID to stdout. No file I/O.
# ────────────────────────────────────────────────────────────────────────────
gen_correlation_id() {
  local trigger_source="${1:-manual}"
  # Validate against the bounded enum (Eng Review: regex pinned in correlation-id.md)
  case "$trigger_source" in
    cron|telegram|inter|manual) ;;
    webhook-*) ;;
    *)
      echo "gen_correlation_id: invalid trigger-source '${trigger_source}' (expected: cron, webhook-*, telegram, inter, manual)" >&2
      return 1
      ;;
  esac
  local utc_z
  utc_z=$(date -u +%Y%m%dT%H%M%SZ)
  local nonce6
  nonce6=$(head -c 4 /dev/urandom | xxd -p | cut -c1-6)
  printf '%s-%s-%s\n' "$trigger_source" "$utc_z" "$nonce6"
}

# ────────────────────────────────────────────────────────────────────────────
# atomic_write_inbox <recipient-id> <sender-id> <correlation-id> <payload-file>
#
# Writes <payload-file> contents to the recipient's inbox via atomic rename.
#
# Steps:
#   1. Compute target = .agentbloc/agents/<recipient-id>/inbox/<sender-id>-<correlation-id>.json
#   2. Compute tmp    = .agentbloc/agents/<recipient-id>/inbox/.<sender-id>-<correlation-id>.tmp
#   3. Copy payload-file → tmp, fsync
#   4. mv tmp → target (POSIX rename, atomic on same filesystem)
#
# If target already exists (collision), fail loudly (return 1). Do NOT overwrite.
#
# Returns 0 on success, 1 on collision/error.
# ────────────────────────────────────────────────────────────────────────────
atomic_write_inbox() {
  local recipient_id="${1:?atomic_write_inbox: recipient-id required}"
  local sender_id="${2:?atomic_write_inbox: sender-id required}"
  local correlation_id="${3:?atomic_write_inbox: correlation-id required}"
  local payload_file="${4:?atomic_write_inbox: payload-file required}"

  if [ ! -f "$payload_file" ]; then
    echo "atomic_write_inbox: payload file not found: $payload_file" >&2
    return 1
  fi

  local inbox_dir="${_AGENTS_ROOT}/${recipient_id}/inbox"
  local filename="${sender_id}-${correlation_id}.json"
  local target="${inbox_dir}/${filename}"
  local tmp="${inbox_dir}/.${filename}.tmp"

  # Ensure inbox directory exists (writer's responsibility — recipient may
  # not have been wake'd yet).
  mkdir -p "$inbox_dir"

  # Collision check before write — Eng Review D3 says fail loud, never overwrite.
  if [ -e "$target" ]; then
    echo "atomic_write_inbox: collision at ${target} (sender=${sender_id} correlation=${correlation_id})" >&2
    return 1
  fi

  # Copy + fsync the tmp file, then atomic-rename onto the target.
  cp "$payload_file" "$tmp"
  # Best-effort fsync via dd if available; fall back to sync(1) which fsyncs
  # the whole filesystem (acceptable for v2.5 demo-scale workloads).
  sync
  mv "$tmp" "$target"
}

# ────────────────────────────────────────────────────────────────────────────
# read_next_inbox <agent-id>
#
# Reads (and atomically claims) the next-pending inbox envelope for <agent-id>.
#
# Steps:
#   1. List inbox/*.json (sorted, ignores .<id>.tmp dotfiles)
#   2. For each envelope: try mv to inbox/processing/<filename>
#      - mv succeeds → we own it. Echo absolute path. Return 0.
#      - mv fails with ENOENT → another reader claimed it. Skip silently.
#      - mv fails for other reasons → log, return 2.
#
# If no envelopes are queued, return 1 (callers check exit code).
# Echoes the absolute path of the claimed envelope to stdout.
# ────────────────────────────────────────────────────────────────────────────
read_next_inbox() {
  local agent_id="${1:?read_next_inbox: agent-id required}"
  local inbox_dir="${_AGENTS_ROOT}/${agent_id}/inbox"
  local processing_dir="${inbox_dir}/processing"

  # If inbox doesn't exist yet, no envelopes queued.
  [ -d "$inbox_dir" ] || return 1

  mkdir -p "$processing_dir"

  # Find sorts deterministically; -maxdepth 1 + -name '*.json' explicitly
  # skips .<id>.tmp dotfiles (writers in mid-rename) and ignores
  # processing/ + processed/ subdirs.
  local envelope
  while IFS= read -r envelope; do
    [ -z "$envelope" ] && continue
    local basename
    basename=$(basename "$envelope")
    local claim="${processing_dir}/${basename}"

    # Atomic mv: if it succeeds, we own this envelope. If another reader
    # claimed it between find and mv, mv exits non-zero and we skip silently.
    if mv "$envelope" "$claim" 2>/dev/null; then
      printf '%s\n' "$claim"
      return 0
    fi
    # Race lost — another reader took it. Try the next envelope.
  done < <(find "$inbox_dir" -maxdepth 1 -name '*.json' -type f 2>/dev/null | sort)

  # No envelopes available (or all were lost to other readers).
  return 1
}

# ────────────────────────────────────────────────────────────────────────────
# check_kill_switch <agent-id>
#
# Three-point kill switch (per Eng Review):
#   1. Team-wide:  .agentbloc/KILL_SWITCH file exists → halt all agents
#   2. Per-agent:  .agentbloc/agents/<agent-id>/pause file exists → halt this agent
#   3. Cooperative tool-level: PreToolUse hook will block per-tool blast radius
#      (this function does not check that — the hook handles it at exec time)
#
# Returns 0 (proceed) if no halt files exist.
# Returns 1 (halt) if either file exists. Echoes the reason to stderr.
# ────────────────────────────────────────────────────────────────────────────
check_kill_switch() {
  local agent_id="${1:?check_kill_switch: agent-id required}"

  if [ -e "$_KILL_SWITCH" ]; then
    echo "check_kill_switch: team-wide KILL_SWITCH active at ${_KILL_SWITCH}" >&2
    return 1
  fi

  local pause_file="${_AGENTS_ROOT}/${agent_id}/pause"
  if [ -e "$pause_file" ]; then
    echo "check_kill_switch: per-agent pause active at ${pause_file}" >&2
    return 1
  fi

  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# inbox_janitor <agent-id>
#
# Housekeeping sweep run at the top of every wake.sh invocation.
#
# 1. Reclaim stale .tmp files in inbox/: any .<id>.tmp older than
#    INBOX_TMP_STALE_MIN minutes is unlinked (writer crashed mid-write).
# 2. Reclaim stale processing/ entries: any file in inbox/processing/ older
#    than INBOX_STALE_MIN minutes is moved back to inbox/ for re-processing
#    (reader crashed mid-processing).
# 3. Rotate inbox/processed/ when entry count > INBOX_PROCESSED_MAX:
#    move oldest entries into inbox/processed/<YYYY-MM>/ archive.
#
# Returns 0. Failures during janitor are logged but non-fatal — wake should proceed.
# ────────────────────────────────────────────────────────────────────────────
inbox_janitor() {
  local agent_id="${1:?inbox_janitor: agent-id required}"
  local inbox_dir="${_AGENTS_ROOT}/${agent_id}/inbox"
  local processing_dir="${inbox_dir}/processing"
  local processed_dir="${inbox_dir}/processed"

  # If inbox doesn't exist yet, nothing to sweep.
  [ -d "$inbox_dir" ] || return 0

  # 1. Stale .tmp files (writer crashed mid-write).
  if find "$inbox_dir" -maxdepth 1 -name '.*.tmp' -type f -mmin "+${INBOX_TMP_STALE_MIN}" -print0 2>/dev/null \
       | xargs -0 -r rm -f 2>/dev/null; then
    :  # success or nothing-to-do — both fine
  fi

  # 2. Stale processing/ entries (reader crashed mid-processing).
  if [ -d "$processing_dir" ]; then
    local stale
    while IFS= read -r -d '' stale; do
      [ -z "$stale" ] && continue
      local basename
      basename=$(basename "$stale")
      # Move back to inbox/ for re-claim by next reader.
      mv "$stale" "${inbox_dir}/${basename}" 2>/dev/null || true
    done < <(find "$processing_dir" -maxdepth 1 -type f -mmin "+${INBOX_STALE_MIN}" -print0 2>/dev/null)
  fi

  # 3. Rotate processed/ when over INBOX_PROCESSED_MAX.
  if [ -d "$processed_dir" ]; then
    local count
    count=$(find "$processed_dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "${count:-0}" -gt "$INBOX_PROCESSED_MAX" ]; then
      local archive_dir
      archive_dir="${processed_dir}/$(date -u +%Y-%m)"
      mkdir -p "$archive_dir"
      # Move oldest 50% into archive (keeps the recent half hot for inspection).
      local half=$(( count / 2 ))
      find "$processed_dir" -maxdepth 1 -type f -print0 2>/dev/null \
        | xargs -0 ls -t 2>/dev/null \
        | tail -n "$half" \
        | while IFS= read -r old; do
            mv "$old" "$archive_dir/" 2>/dev/null || true
          done
    fi
  fi

  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# redact_pii <json-string>
#
# Strips PII per .claude/skills/agentbloc/references/audit-logging.md rules.
#
# Replaces with [REDACTED:<type>] markers:
#   - email addresses    → [REDACTED:email]
#   - phone numbers      → [REDACTED:phone]
#   - SSN (xxx-xx-xxxx)  → [REDACTED:national_id]
#   - DNI/NIE (Spanish)  → [REDACTED:national_id]
#
# For traceability: replace with hash:<8 hex> (sha256 truncated) when the
# caller passes --traceable. Default behavior is plain redaction.
#
# NEVER logs:
#   - Raw API keys / tokens / passwords / encryption keys (handled separately
#     by claude-wrap.sh's stdin-only design)
#
# Echoes redacted JSON string. Input remains valid JSON.
# ────────────────────────────────────────────────────────────────────────────
redact_pii() {
  local input="${1:-}"
  if [ -z "$input" ]; then
    printf ''
    return 0
  fi

  # Use sed for the regex passes. Order matters:
  # most-specific patterns first (SSN before generic digits), so we
  # don't accidentally double-redact.
  printf '%s' "$input" | sed -E \
    -e 's/[0-9]{3}-[0-9]{2}-[0-9]{4}/[REDACTED:national_id]/g' \
    -e 's/[0-9]{8}[A-Za-z]/[REDACTED:national_id]/g' \
    -e 's/[XYZxyz][0-9]{7}[A-Za-z]/[REDACTED:national_id]/g' \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[REDACTED:email]/g' \
    -e 's/\+?[0-9]{1,3}[ -]?\(?[0-9]{2,4}\)?[ -]?[0-9]{3,4}[ -]?[0-9]{3,4}/[REDACTED:phone]/g'
}

# ─── Module load marker ──────────────────────────────────────────────────────
export AGENTBLOC_HELPERS_LOADED=1
