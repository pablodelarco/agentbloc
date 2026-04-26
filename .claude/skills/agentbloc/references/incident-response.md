# Incident Response

> Security reference loaded by SKILL.md during Deployment (Phase 5) and Design (Phase 2).

## Table of Contents

- [When This Applies](#when-this-applies)
- [Kill Switch Specification](#kill-switch-specification)
- [Severity Classification](#severity-classification)
- [Incident Response Runbook Template](#incident-response-runbook-template)
- [Quick Reference](#quick-reference)

## When This Applies

Claude reads this file during Deployment (Phase 5) when generating the per-deployment incident response runbook and kill switch configuration. Also referenced during Design (Phase 2) when designing governance for high blast-radius agents (Level 3-4) that require immediate halt capability.

## Kill Switch Specification

The kill switch is dual-path: a file-based mechanism (zero-dependency, always available) and a Telegram command (remote-friendly). Both paths converge to the same enforcement point.

### Path 1: File-Based (Zero-Dependency)

- **File:** `.agentbloc/KILL_SWITCH`
- **Create to halt:** `touch .agentbloc/KILL_SWITCH`
- **Remove to resume:** `rm .agentbloc/KILL_SWITCH`
- **Content (optional):** Include reason, who triggered it, and timestamp for audit trail
  ```
  Halted by: Pablo
  Reason: Invoice agent sent duplicate emails
  Timestamp: 2026-04-14T10:23:00Z
  ```
- **Enforcement:** PreToolUse hook checks file existence before allowing Write, Edit, Bash, or any `mcp__*` tool call
- **Availability:** Works without network, Telegram, or any external service

### Path 2: Telegram /stop Command (Remote-Friendly)

- User sends `/stop` to the AgentBloc operations Telegram thread
- Telegram bot webhook receives the command and creates `.agentbloc/KILL_SWITCH` file
- This converges both paths to the same enforcement mechanism
- **Resume:** User sends `/resume` and bot removes the KILL_SWITCH file
- **Use case:** Operator is on mobile, away from SSH access

### PreToolUse Hook Template

Add this to `.claude/settings.json` or the hooks configuration for every deployed agent:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|Bash|mcp__*",
        "hooks": [
          {
            "type": "command",
            "command": "test ! -f .agentbloc/KILL_SWITCH || (echo 'KILLED: Agent halted by kill switch' >&2 && exit 2)"
          }
        ]
      }
    ]
  }
}
```

**Check frequency:** The kill switch is checked before EVERY side-effect tool call, not just at session start. This prevents long-running agents from continuing after a halt is triggered mid-run.

**Exit code 2:** Signals a hard block to Claude Code. The agent session will stop processing and report the halt.

## Severity Classification

| Severity | Description | Example | Response Time | Notification |
|----------|-------------|---------|---------------|--------------|
| **P1 Critical** | Agent sending incorrect data externally or data breach detected | Wrong invoices sent to clients, PII exposed in Telegram thread | Immediate | Kill switch + Telegram P1 alert + phone call to primary operator |
| **P2 High** | Agent malfunction with potential data impact | Agent writing to wrong state files, unexpected API errors on write operations | 1 hour | Telegram alert + pause agent |
| **P3 Medium** | Agent degraded but functional | Slow performance, partial data retrieval, rate limit warnings | 4 hours | Telegram notification |
| **P4 Low** | Cosmetic or minor issues | Report formatting issues, non-critical log warnings | Next business day | Logged in audit trail, no alert |

### Severity Decision Tree

1. Did the agent send data externally (email, API, Telegram to client)?
   - YES and data was incorrect or unauthorized: **P1**
   - YES and data was correct but unexpected: **P2**
   - NO: Continue to step 2
2. Did the agent modify state files or external data?
   - YES and modifications were incorrect: **P2**
   - YES and modifications were correct but unplanned: **P3**
   - NO: Continue to step 3
3. Is the agent still functional?
   - NO (crashed, stuck, unresponsive): **P3**
   - YES but degraded: **P4**

## Incident Response Runbook Template

Claude generates this template during Phase 5 and fills in deployment-specific details. The operator customizes escalation contacts and reviews before go-live.

### Overview

| Field | Value |
|-------|-------|
| Team name | `{team_name}` |
| Agents | `{agent_list}` |
| Deployment date | `{deploy_date}` |
| Last updated | `{last_update}` |
| Primary operator | `{name}` / `{telegram}` / `{phone}` |
| Backup operator | `{name}` / `{telegram}` / `{phone}` |
| Technical contact | `{name}` / `{telegram}` / `{phone}` |

### Immediate Actions (Any Severity)

1. **Activate kill switch:**
   ```bash
   touch .agentbloc/KILL_SWITCH
   ```
   Or send `/stop` in the Telegram operations thread.

2. **Check audit log:**
   ```bash
   tail -20 .agentbloc/logs/audit.jsonl | jq .
   ```

3. **Identify affected agent** from `correlation_id` in logs.

4. **Assess severity** using the decision tree above.

5. **Notify** per severity level notification requirements.

### Rollback Procedure

1. **Stop all agents** (kill switch should already be active from Immediate Actions).
2. **Identify last known good state** from state file timestamps:
   ```bash
   ls -lt .agentbloc/state/*.json
   ```
3. **Restore state files from backup:**
   ```bash
   cp .agentbloc/state/backup/*.json .agentbloc/state/
   ```
4. **Remove kill switch:**
   ```bash
   rm .agentbloc/KILL_SWITCH
   ```
5. **Restart agents and monitor first run.** Watch audit log for the first full cycle:
   ```bash
   tail -f .agentbloc/logs/audit.jsonl | jq .
   ```

### Common Failure Scenarios

| Scenario | Detection | Response | Severity |
|----------|-----------|----------|----------|
| MCP server unreachable | Connection timeout in audit log | Log error, skip provider, continue. If 3+ providers fail in one run, pause agent | P3 |
| Credential expired | 401/403 in audit log | Telegram alert: "Credential rotation needed for `{service}`". Agent pauses automatically | P2 |
| Rate limit exceeded | 429 in audit log or governance limit hit | Agent self-halts. Check governance.yaml limits. Adjust if traffic was legitimate | P3 |
| State file corrupted | JSON parse error in audit log | Restore from last backup. Re-run from last checkpoint | P2 |
| Agent sends wrong data externally | Recipient reports error or audit log shows unexpected target | Immediate kill switch. Contact affected recipients. Assess data impact | P1 |
| Telegram bot unresponsive | No notifications received for scheduled run | Check bot token validity. Restart bot. Agents continue without reporting | P3 |

### Post-Incident Review Template

Complete within 48 hours of P1/P2 resolution. Within 1 week for P3.

```markdown
## Post-Incident Review

**Incident ID:** {incident_id}
**Correlation ID:** {correlation_id from audit log}
**Severity:** {P1/P2/P3/P4}
**Date:** {date}

### Timeline

| Time | Event |
|------|-------|
| {time} | Detection: {how was the incident detected} |
| {time} | Triage: {initial assessment} |
| {time} | Mitigation: {immediate actions taken} |
| {time} | Resolution: {fix applied} |
| {time} | Verification: {confirmed fix works} |

### Root Cause

{What caused the incident. Be specific.}

### Impact

- Records affected: {count}
- External communications sent: {count and type}
- Data exposed: {description or "none"}

### Remediation

{What was done to fix the immediate issue.}

### Prevention

{What changes prevent this from happening again.
Examples: updated governance.yaml limits, added validation step,
modified agent skill file, added new test to dry run.}
```

## Quick Reference

| Severity | Response Time | First Action | Notification | Escalation |
|----------|---------------|--------------|--------------|------------|
| P1 | Immediate | Kill switch | Telegram + phone | Primary + backup operator |
| P2 | 1 hour | Pause agent | Telegram alert | Primary operator |
| P3 | 4 hours | Monitor | Telegram notification | Logged |
| P4 | Next business day | Log | Audit trail only | None |

**Kill switch paths:** `touch .agentbloc/KILL_SWITCH` (local) or `/stop` in Telegram (remote).

**Resume:** `rm .agentbloc/KILL_SWITCH` (local) or `/resume` in Telegram (remote).

## Runtime Kill-Switch Semantics

Phase 13 formalizes kill-switch behavior inside the runtime layer. Per D-77, the kill-switch is checked at 3 points per agent wake; coverage across these three enforcement points spans the full wake-to-completion latency window.

1. **Wake-time check (new in Phase 13 runtime layer):** Every materialized wake.md (produced by runtime-engine from `templates/wake-job-{cron,webhook,inter}.md.tmpl`) opens with Section 1 checking `.agentbloc/KILL_SWITCH`. If the file exists, the agent appends a `halted-kill-switch` entry to `.agentbloc/logs/audit.jsonl` with the correlation ID and EXITS IMMEDIATELY before reading state, loading the SKILL.md, or calling any tool. This prevents new damage from a wake that fires during an active halt window.

2. **Per-tool check (existing v1.0 SECR-05 + Phase 12 PreToolUse hook):** The hook at `.claude/hooks/kill-switch-check.sh` (generated by Phase 12 deploy-engine; documented earlier in this file) runs before every tool invocation. On KILL_SWITCH activation mid-run, the next tool call is blocked with `permissionDecision: deny`. This prevents in-flight damage from a long-running agent that passed the wake-time check but then encountered activation before completing.

3. **Team-transition check (new in Phase 13 runtime coordination layer):** Inside a TeamCreate session, every agent checks `.agentbloc/KILL_SWITCH` before SendMessage send AND before SendMessage consume. If active, the agent returns `{status: halted-kill-switch}` to the caller and the team lead dissolves the team via explicit TeamCreate teardown. Dissolution is logged to `.agentbloc/runtime/TEAM_SESSIONS.jsonl` with `team_dissolution_reason: kill-switch` alongside the shared correlation ID. Worst-case latency for a team-wide halt is one SendMessage round-trip (typically under 5 seconds). See [runtime-coordination.md](runtime-coordination.md) for the full TeamCreate plus dissolution semantics.

**Remote-trigger path (Telegram /stop):** Phase 13 runtime-engine emits an n8n route stub at `.agentbloc/runtime/n8n-routes/agentbloc-stop.json` that listens for `/stop` in the configured Telegram operations thread and runs `touch .agentbloc/KILL_SWITCH` via a shell node. A sibling route `agentbloc-resume.json` runs `rm .agentbloc/KILL_SWITCH` on `/resume`. Both are user-installable into the user's n8n instance. The v1.0 dual-path (file-based + Telegram /stop) remains operational; Phase 13 ships the route .json stubs so the user does not hand-author them.

**Correlation-ID-scoped forensics:** Every halt event logs the correlation ID. A single grep over `.agentbloc/logs/audit.jsonl` and `.agentbloc/runtime/TEAM_SESSIONS.jsonl` reconstructs the full chain from the triggering user event through every halted agent. See [correlation-id.md](correlation-id.md) for grep recipes.

## Escalation Protocol

Phase 14 introduces a third Telegram thread per team: `escalations`, distinct from `approvals` (CTRL-01) and `briefing` (MONITOR-04). Escalations route agent failures + critical errors with a structured 4-part message (what tried / why failed / options / recommended next action) per AUTON-04 + AUTON-05.

### Trigger

An agent escalates when one of:
1. An uncaught exception during wake.
2. A critical-action tool returning `result: failure` (where critical = the action was the agent's primary purpose for this wake, e.g., `mcp__plaid__list_transactions` for gestor-cobros).
3. An explicit `escalate(...)` call from agent prose when the agent assesses it cannot make progress.

### Persistent Halt + /resume

On escalation, the agent:
1. Appends a JSONL log entry with `priority: critical` and `action: escalation` per `references/jsonl-log-schema.md`.
2. Sets `last-run.json status: error` per `references/agent-memory-schema.md` (Phase 14 schema_version 2).
3. Invokes `escalation-router.sh telegram-escalate <agent-id> <correlation_id> ...` to dispatch the 4-part Telegram message to the escalations thread.
4. Exits the wake with `wake_outcome: escalated`.

Subsequent wakes (cron / webhook / inter) check `last-run.json status` first; if `error`, the wake template section 1 (after kill-switch check) detects it and short-circuits with `wake_outcome: skipped-prior-error` UNTIL a `/resume <correlation_id> [free-text instructions]` reply lands in the escalations thread. The `/resume` reply (handled by an inbound n8n route created by deploy-engine per `registry.yaml escalations` binding) updates `last-run.json status: idle` and appends free-text instructions to `memory.md` Open Items section (D-64 location). Next cron/webhook fires resumes work.

### Kill-Switch vs Escalation Sequencing

Kill-switch checks ALWAYS precede escalation router invocation: an agent halted by kill-switch does NOT escalate (the halt IS the alarm). Escalations explicitly bypass the kill-switch check ONLY when the escalation IS the kill-switch firing event itself (avoids self-suppression of the alarm).

### See

- [references/escalation-protocol.md](escalation-protocol.md) for the full 4-part template + 3 worked examples (gmail rate-limit, plaid auth-revoked, BBVA 2FA-expired).
- [references/approval-router.md](approval-router.md) for the shared Telegram-routing infrastructure (escalation-router.sh and approval-router.sh follow the same shell-script + long-poll pattern).
