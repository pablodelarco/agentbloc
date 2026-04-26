# JSONL Log Schema (Phase 14)

> Phase 14 reference. Canonical 12-field schema for every deployed agent's structured log entries. Loaded by briefing-agent at wake; consumed by activity-feed merger; aligned with v1.0 audit-logging.md correlation-ID format per D-97. Per-day per-agent files at `.claude/agents/logs/<YYYY-MM-DD>/<agent-id>.jsonl` with sibling files for approvals + escalations.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Schema (12 Fields)](#schema-12-fields)
- [Path Convention](#path-convention)
- [Append-Only Discipline](#append-only-discipline)
- [JCS Canonicalization (D-60)](#jcs-canonicalization-d-60)
- [Sibling Files: approvals.jsonl + escalations.jsonl](#sibling-files-approvalsjsonl--escalationsjsonl)
- [Briefing Input Pattern](#briefing-input-pattern)
- [Cross-References](#cross-references)

## When This Applies

Phase 14 emits this schema as the single source of truth for every deployed agent's log entries. The schema is loaded UNCONDITIONALLY at Phase 5 entry per D-58 context-budget discipline. Every wake of every deployed agent results in one or more JSONL log lines conforming to this schema. The briefing-agent (`templates/briefing-agent.md.tmpl`, Plan 14-02) reads the day's per-agent log files at briefing time. The `activity-feed-merge.sh` script (Plan 14-01 Task 7 + Plan 14-03 runtime-engine emission) consumes the same files to produce a merged daily activity feed.

The schema deliberately separates required fields (8) from optional fields (7) so older v1.0 deployments and minimal log emissions remain valid while richer deployments carry more context per entry.

## Schema (12 Fields)

Each JSONL line is one self-contained JSON object. Example:

```json
{
  "schema_version": 1,
  "timestamp": "2026-04-26T08:00:00.123Z",
  "correlation_id": "cron-20260426T080000Z-a3f21b",
  "agent_id": "gestor-cobros",
  "team": "arco-rooms",
  "action": "tool_call",
  "tool": "mcp__plaid__list_transactions",
  "result": "success",
  "details": {"account_id": "es76-1234", "transaction_count": 14, "errors": []},
  "duration_ms": 2340,
  "token_count": {"input": 1245, "output": 312, "cached_input": 0},
  "cost_usd": 0.0231,
  "requires_human": false,
  "priority": "info",
  "locked_by": null
}
```

Field definitions:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | integer | mandatory | `1` for v2.0 ship date; consumers refuse on unknown major version per D-22 three-tier obligation discipline |
| `timestamp` | string (ISO 8601) | mandatory | When the action occurred, ms-precision UTC with Z suffix |
| `correlation_id` | string | mandatory | Per D-75 format `<source>-<UTC-Z-compact>-<nonce6>`; child rule `-sub-NNN` for spawned sub-sessions |
| `agent_id` | string | mandatory | Agent identifier as declared in `registry.yaml` |
| `team` | string | mandatory | Team name as declared in `registry.yaml` |
| `action` | string ENUM | mandatory | `tool_call \| decision \| error \| state_change \| escalation \| approval_request \| approval_response` |
| `result` | string ENUM | mandatory | `success \| failure \| skipped \| blocked` |
| `priority` | string ENUM | mandatory | `info \| warn \| critical`; critical priority bypasses briefing batching per AUTON-04 |
| `tool` | string | optional | MCP tool or Bash command invoked when `action: tool_call` (e.g., `mcp__plaid__list_transactions`) |
| `details` | object | optional | Structured JSON with action-specific payload; PII redacted per `audit-logging.md` rules |
| `duration_ms` | number | optional | Execution time in milliseconds for this action |
| `token_count` | object | optional | `{input: number, output: number, cached_input: number}` for Claude API calls per CTRL-02 |
| `cost_usd` | number | optional | USD cost computed by `claude-wrap.sh` from `token_count` + `references/billing-rates.md` rate table |
| `requires_human` | boolean | optional | True when action expects approval queue surfacing per AUTON-02 / CTRL-01 |
| `locked_by` | string | optional | Resource-slug if this entry pertains to a locked resource per CTRL-03 / `task-locking.md` |

The 8 required fields support core observability (when, who, what, result). The 7 optional fields support rich enrichment (cost, latency, locking, approval routing) without burdening minimal emissions.

## Path Convention

Per REQUIREMENTS.md MONITOR-02 literal:

```
.claude/agents/logs/<YYYY-MM-DD>/<agent-id>.jsonl
```

Examples for the Arco Rooms team on 2026-05-01:
- `.claude/agents/logs/2026-05-01/gestor-cobros.jsonl`
- `.claude/agents/logs/2026-05-01/recepcionista.jsonl`
- `.claude/agents/logs/2026-05-01/gestor-documental.jsonl`

The path is REQUIREMENTS-canonical per D-59 triple-override precedent (Phase 12 D-59a/b/c established the `.claude/skills/<agent-id>/SKILL.md` and `.agentbloc/agents/<agent-id>/...` paths; logs follow REQUIREMENTS verbatim because logs are git-versionable trails not mutable runtime state).

**Day boundary:** UTC midnight. An action that fires at 23:59:59.500Z on 2026-04-30 lands in `2026-04-30/`; an action firing at 00:00:00.000Z on 2026-05-01 lands in `2026-05-01/`.

**Per-agent per-day file rationale:**

| Layout | Pro | Con | Selected |
|---|---|---|---|
| Single team file per day | Unified grep target | Concurrent writers from cron + webhook agents interleave at line boundary risk | |
| Per-agent per WEEK | Smaller file count | File size grows; weekly boundary mismatches briefing cadence | |
| SQLite single DB per team | Indexed queries | Adds dependency contrary to v1.0 file-based decision; v2.5 web dashboard scope | |
| Per-agent per-day at REQUIREMENTS path | Append-safe via O_APPEND; daily boundary matches briefing cadence; one rg target for one day's run per agent | None at v2.0 scale | ✓ |

## Append-Only Discipline

Writes use `>>` redirect (or O_APPEND in Python/JS). No line edits, ever. Compaction is a future-phase concern (v2.5 per `.agentbloc/runtime/log-rotate.sh`); v2.0 ships uncompacted with the assumption that 30-agent teams generate <50MB of log per month per agent at typical activity rates.

Concurrent writes from multiple `claude -p` processes are safe because:
1. POSIX `O_APPEND` semantics guarantee atomic line appends up to PIPE_BUF (4096 bytes on Linux/macOS).
2. Each JSONL line is one self-contained JSON object on one physical line; even maximum-detail entries fit under 4096 bytes when canonicalized per D-60.
3. Per-agent file isolation removes the most common multi-writer contention pattern (the team-shared file alternative would require flock(1)).

## JCS Canonicalization (D-60)

Each JSONL line is RFC 8785 JCS-canonicalized before write. This ensures SHA256 fingerprints are stable across runs (enables idempotent re-emission of `activity-feed.jsonl` per CTRL-05; enables cross-deployment comparison in Phase 16 golden-file tests).

Canonicalization rules:
1. Object keys sorted alphabetically.
2. Numbers in shortest decimal form per ECMAScript 6 + `JSON.stringify` algorithm.
3. Strings escaped per RFC 8259.
4. No insignificant whitespace inside the line; the only whitespace is the trailing `\n` newline.

Example: `{"agent_id":"gestor-cobros","schema_version":1,"timestamp":"2026-04-26T08:00:00.123Z","..."}` (keys sorted; no padding spaces).

The `claude-wrap.sh` wrapper script (Plan 14-03 runtime-engine emission per D-91) is responsible for JCS canonicalization at write time when augmenting log lines with `cost_usd` + `token_count`. Agents that write directly should use a JCS-canonicalizing JSON serializer.

## Sibling Files: approvals.jsonl + escalations.jsonl

Two dedicated sibling files at the same per-day directory:

```
.claude/agents/logs/<YYYY-MM-DD>/approvals.jsonl
.claude/agents/logs/<YYYY-MM-DD>/escalations.jsonl
```

Both use the same 12-field schema with these conventions:
- `agent_id` is the originating agent (the agent that requested approval or that escalated).
- `action` ENUM extension: `approval_request` (when an approval was dispatched), `approval_response` (when the human replied), `escalation` (when an agent escalated).
- `details` field carries action-specific payload: for `approval_request`, `{tool, args_summary, reversibility, $TOOL_REASONING}`; for `approval_response`, `{outcome: approved | denied | timeout, decider_telegram_user_id, reasoning_supplied}`; for `escalation`, `{what_tried, why_failed, options, recommended_next_action}` per AUTON-05 4-part template.

Append-only + JCS-canonicalized + path-conventional same as per-agent files.

## Briefing Input Pattern

The briefing-agent (`templates/briefing-agent.md.tmpl`) reads the day's logs via this pattern at wake-time:

```bash
TODAY=$(date -u +%Y-%m-%d)
LOGS_DIR=".claude/agents/logs/${TODAY}"

# Per-agent summarization
for AGENT in $(ls "${LOGS_DIR}/" | grep -v -E '^(approvals|escalations|activity-feed)\.jsonl$'); do
  AGENT_ID="${AGENT%.jsonl}"
  ACTION_COUNTS=$(jq -r '.action' "${LOGS_DIR}/${AGENT}" | sort | uniq -c)
  TOTAL_COST=$(jq -r '.cost_usd // 0' "${LOGS_DIR}/${AGENT}" | awk '{s+=$1} END {print s}')
  TOTAL_INPUT_TOKENS=$(jq -r '.token_count.input // 0' "${LOGS_DIR}/${AGENT}" | awk '{s+=$1} END {print s}')
  STATUS=$(jq -r '.status' ".agentbloc/agents/${AGENT_ID}/last-run.json")
  # ... etc per briefing template
done

# Pending approvals + escalations
PENDING_APPROVALS=$(jq -s 'group_by(.correlation_id) | map(select(length == 1 and .[0].action == "approval_request"))' "${LOGS_DIR}/approvals.jsonl" | jq length)
TODAY_ESCALATIONS=$(jq 'select(.action == "escalation")' "${LOGS_DIR}/escalations.jsonl" | jq -s length)
```

The briefing then dispatches a Telegram message via `briefing-renderer.sh format-telegram <summary-json>` per MONITOR-06 pluggable presentation contract (D-88).

## Action ENUM Semantics

The `action` field disambiguates what kind of work the log line records. Each ENUM value carries specific contract obligations:

- **`tool_call`** , agent invoked an MCP tool or Bash command. `tool` field MUST be set; `details` carries action-specific params; `duration_ms` SHOULD be set; `result` is `success | failure | skipped | blocked`.
- **`decision`** , agent made a non-trivial routing or business decision (e.g., `which-tenant-to-bill-this-month`). `tool` is null; `details` carries decision payload (`{decision: <kebab-case-id>, options_considered: [...], chosen: <option>, rationale: <prose>}`).
- **`error`** , agent caught a recoverable error (uncaught errors trigger `escalation` instead). `details` carries `{error_code, error_message, recovery_action}`.
- **`state_change`** , agent wrote to its own state.json or memory.md. `details` carries `{file: state.json | memory.md, fields_changed: [...]}`.
- **`escalation`** , agent escalated per AUTON-04. `details` carries the 4-part template fields (`{what_tried, why_failed, options, recommended_next_action}`).
- **`approval_request`** , agent dispatched approval per AUTON-02 (only appears in `approvals.jsonl` sibling). `details` carries `{tool, args_summary, reversibility, $TOOL_REASONING}`.
- **`approval_response`** , human replied to approval per AUTON-03 (only appears in `approvals.jsonl` sibling). `details` carries `{outcome: approved | denied | timeout, decider_telegram_user_id, reasoning_supplied}`.

## Result ENUM Semantics

- **`success`** , action completed as intended.
- **`failure`** , action attempted but failed; agent will retry or escalate.
- **`skipped`** , action precondition unmet (e.g., resource locked, idempotency hit, kill-switch fired); not an error.
- **`blocked`** , action denied by autonomy gate or hook (semi/supervised approval denied; PreToolUse kill-switch fired); the action did NOT execute.

## Priority ENUM Semantics

- **`info`** , routine operational entry; briefing summarizes counts only.
- **`warn`** , notable but non-blocking (e.g., approval timeout, rate-limit warning); briefing surfaces with caution emoji.
- **`critical`** , triggers immediate escalation channel routing per AUTON-04 + bypasses briefing batching; surfaces directly to escalations Telegram thread without waiting for daily briefing.

## Cross-References

- [correlation-id.md](correlation-id.md) , D-75 format spec for the `correlation_id` field; child propagation `-sub-NNN`
- [agent-memory-schema.md](agent-memory-schema.md) , `last-run.json` `status` field used as the source of truth for CTRL-04 status badges; cost_usd + token_count rolling totals per D-98
- [audit-logging.md](audit-logging.md) , v1.0 audit schema legacy; aligned per D-97 (correlation-ID format unified with D-75)
- [autonomy-controller.md](autonomy-controller.md) , `requires_human` field semantics per AUTON-02
- [approval-router.md](approval-router.md) , approvals.jsonl append discipline per AUTON-03
- [escalation-protocol.md](escalation-protocol.md) , escalations.jsonl append discipline per AUTON-04 + AUTON-05
- [task-locking.md](task-locking.md) , `locked_by` field semantics per CTRL-03
- [activity-feed.md](activity-feed.md) , daily merge consumer of these per-agent files per CTRL-05
- [billing-rates.md](billing-rates.md) , rate table for `cost_usd` computation per CTRL-02
