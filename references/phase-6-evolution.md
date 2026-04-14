# Post-Deployment Evolution Protocol

> Loaded by SKILL.md at Phase 6 entry after deployment artifacts are generated and approved. Guides the user through setting up and running the scan-detect-propose-approve lifecycle loop that keeps deployed agent teams current and secure.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Evolution Opening](#evolution-opening)
- [Step 1: Scan Configuration (EVOL-01)](#step-1-scan-configuration-evol-01)
- [Step 2: Feature Detection (EVOL-02)](#step-2-feature-detection-evol-02)
- [Step 3: Vulnerability Detection (EVOL-03)](#step-3-vulnerability-detection-evol-03)
- [Step 4: Patch Proposal Format (EVOL-04)](#step-4-patch-proposal-format-evol-04)
- [Step 5: Human Approval Gate (EVOL-05)](#step-5-human-approval-gate-evol-05)
- [Evolution Lifecycle](#evolution-lifecycle)
- [Quick Reference](#quick-reference)

## When This Applies

Claude reads this file when the user completes Phase 5 (Deployment) and enters Phase 6 (Evolution). At this point, deployment artifacts are generated, approved, and running in production via system cron + `claude -p`. The input context for this phase is:

- The deployed `.agentbloc/` directory (team.yaml, governance.yaml, per-agent configs, job definitions)
- `governance.yaml` evolution config block (scan_frequency, scan_day, sources)
- `telegram.yaml` (approval thread configuration for delivering proposals)

Also load [references/incident-response.md](incident-response.md) for severity classification cross-references.

## Evolution Opening

Explain the evolution phase according to the user's technical level:

**Non-technical:** "Your agent team is deployed and running. This phase sets up a weekly health check that watches for two things: new capabilities that could make your agents better, and security issues that need fixing. Every suggested change comes to you on Telegram for approval before anything happens. You have full control."

**Basics:** "Your agents are live. Now we configure the evolution loop: a weekly scan that detects new MCP server versions, useful new integrations, and security vulnerabilities in your dependencies. It generates structured proposals and sends them to Telegram. Nothing changes without your explicit approval."

**Developer:** "Deployment is complete. Phase 6 configures the evolution loop: a scheduled `claude -p` session that runs weekly, scanning GitHub repos, npm registry, and the GitHub Advisory Database for updates and CVEs affecting your agent stack. Detections produce structured patch proposals delivered via Telegram with approval-by-reply. The human approval gate is non-negotiable. No auto-patching."

## Step 1: Scan Configuration (EVOL-01)

The evolution scan runs as a weekly `claude -p` session defined in `.agentbloc/jobs/evolution-scan.md`. A single Claude Code session is sufficient because Claude has native WebSearch and Bash tools to check all sources without custom scripts or external dependencies.

### Schedule

- **Default frequency:** Weekly (configurable in `governance.yaml` under `evolution.scan_frequency`)
- **Default day:** Sunday (configurable via `evolution.scan_day`)
- **Default time:** 10:00 local timezone (configurable via `evolution.scan_time`)
- Schedule outside the 01:00-03:00 window to avoid DST ambiguity (per scheduling best practices)

### Scan Sources

The evolution scan checks three categories:

| Source | Method | What It Detects |
|--------|--------|-----------------|
| **GitHub repos** | WebSearch for MCP server repositories used by the team | New versions, deprecation notices, breaking changes |
| **npm registry** | `npm view {package} version` via Bash tool | Package updates for Node.js-based MCP servers |
| **GitHub Advisory Database** | WebSearch for CVEs against used packages | Known vulnerabilities in dependencies |

### Job Definition

The evolution scan job lives at `.agentbloc/jobs/evolution-scan.md`. It instructs Claude to:

1. Read `team.yaml` and all `agents/*.yaml` to build the dependency inventory
2. For each MCP server and npm dependency, check current vs. installed version
3. Search the GitHub Advisory Database for CVEs matching used packages
4. Search PulseMCP directory for new MCP servers relevant to the team's integrations
5. Generate proposals for any findings (feature proposals or security alerts)
6. Deliver proposals via Telegram to the configured approval thread
7. If no findings, log "No updates detected" to the audit trail and exit silently

### Crontab Entry

```
# Weekly evolution scan (Sundays at 10:00 local time)
0 10 * * 0 /usr/bin/env bash -c 'source /path/to/.env && cd /path/to/project && claude -p "$(cat .agentbloc/jobs/evolution-scan.md)" >> .agentbloc/logs/cron.log 2>&1'
```

### governance.yaml Evolution Block

```yaml
evolution:
  scan_frequency: weekly
  scan_day: sunday
  scan_time: "10:00"
  human_approval_required: true      # NON-NEGOTIABLE
  sources:
    - github_advisory_db             # CVE scanning
    - npm_registry                   # Package version checks
    - pulsemcp                       # New MCP server discovery
```

## Step 2: Feature Detection (EVOL-02)

When the evolution scan discovers a new MCP server, a major version update, or a new API capability that could improve an existing agent's integration, it generates a **feature proposal**.

### Detection Triggers

- A new MCP server appears on PulseMCP that matches an integration domain the team uses
- An existing MCP server releases a major version with new capabilities
- A previously unverified integration becomes verified (new official MCP server replaces community alternative)
- An API the team uses adds new endpoints relevant to agent tasks

### Feature Proposal Structure

```markdown
# Feature Proposal: [Title]

**Date:** [scan date]
**Scan ID:** [evol-scan-NNN]
**Priority:** LOW | MEDIUM

## What Changed

[Description of the new version, new server, or new capability discovered]

## What It Enables

[Specific improvement to agent behavior or efficiency]

## Recommended Action

[update | add | replace]

## Affected Agents

| Agent | Current Integration | Proposed Change |
|-------|-------------------|-----------------|
| [name] | [current MCP server/version] | [proposed update] |
```

### Presentation

Feature proposals are batched into the weekly evolution report unless no findings exist. Present each proposal with a clear recommendation and let the user decide. Features are never urgent, so they always wait for the weekly batch.

## Step 3: Vulnerability Detection (EVOL-03)

When the evolution scan discovers a CVE filed against a used MCP server or dependency, it generates a **security alert**. Severity classification follows [references/incident-response.md](incident-response.md).

### Detection Triggers

- CVE filed against an npm package used by any agent's MCP server
- GitHub Advisory Database entry matching a dependency in the team's stack
- Deprecation notice with security implications for a used MCP server
- Known exploit published for a component in the agent ecosystem

### Security Alert Structure

```markdown
# Security Alert: [CVE ID or Title]

**Date:** [detection date]
**Scan ID:** [evol-scan-NNN]
**Severity:** P1 CRITICAL | P2 HIGH | P3 MEDIUM | P4 LOW
**CVE:** [CVE-YYYY-NNNNN or "No CVE assigned"]

## Affected Agents

| Agent | Dependency | Version | Exposure |
|-------|-----------|---------|----------|
| [name] | [package] | [installed version] | [what the vulnerability enables] |

## Vulnerability Details

[Description of the vulnerability, attack vector, and potential impact on the agent team]

## Recommended Mitigation

[update to version X | replace with alternative | disable affected integration | apply workaround]

## Risk If Unpatched

[What could happen if this vulnerability is not addressed]
```

### Severity-Based Routing

| Severity | Delivery | Timing |
|----------|----------|--------|
| **P1 Critical** | Immediate Telegram alert to the approval thread | Sent as soon as detected, does not wait for weekly batch |
| **P2 High** | Telegram alert within the weekly report, flagged prominently | Included in next scheduled report |
| **P3 Medium** | Included in weekly batch report | Standard weekly delivery |
| **P4 Low** | Logged in audit trail, included in weekly batch if present | No separate notification |

For P1 alerts, the evolution scan sends the security alert immediately via Telegram rather than accumulating it for the weekly batch. The human approval gate still applies: even P1 vulnerabilities require explicit approval before mitigation is applied.

## Step 4: Patch Proposal Format (EVOL-04)

Every proposed change, whether from feature detection or vulnerability detection, is formalized as a **patch proposal** before reaching the user. This structured format ensures the user has complete information to make an informed decision.

### Required Fields

Every patch proposal must include all of the following:

| Field | Purpose |
|-------|---------|
| **Title** | Clear description of the proposed change |
| **Date** | When the proposal was generated |
| **Scan ID** | Correlation ID linking to the evolution scan that produced it |
| **Priority** | P1 through P4, using incident-response.md severity classification |
| **Affected Agents** | Table showing which agents are impacted and how |
| **Current State** | What is currently installed/configured |
| **Proposed Change** | Specific technical change to apply |
| **Rationale** | Why this change is recommended |
| **Risk Assessment** | Breaking changes, blast-radius impact, potential side effects |
| **Rollback Plan** | Exact steps to undo the change if something goes wrong |

### Complete Patch Proposal Template

```markdown
# Patch Proposal: [Title]

**Date:** [YYYY-MM-DD]
**Scan ID:** [evol-scan-NNN]
**Priority:** [P1 CRITICAL | P2 HIGH | P3 MEDIUM | P4 LOW]

## Affected Agents

| Agent | Impact |
|-------|--------|
| [agent name] | [how this agent is affected] |

## Current State

- Package: [package name]
- Version installed: [current version]
- Last updated: [date of last update]

## Proposed Change

[Specific technical description of the change to apply]

## Rationale

[Why this change is needed: security fix, performance improvement, new capability, deprecation avoidance]

## Risk Assessment

- **Breaking changes:** [None documented | List specific breaking changes]
- **Blast radius:** [LOW | MEDIUM | HIGH with explanation]
- **Side effects:** [Known side effects or "None expected"]

## Rollback Plan

[Exact commands or steps to revert the change]

## Approval

Reply to this message to approve or reject this update.
- **Approve:** Reply "yes" or "approve"
- **Reject:** Reply "no" or "reject" with optional feedback
```

### Proposal State Tracking

Each proposal is tracked in `.agentbloc/state/evolution.json`:

```json
{
  "proposals": [
    {
      "id": "evol-scan-007-001",
      "scan_id": "evol-scan-007",
      "title": "Update Xero MCP Server to 0.4.0",
      "priority": "MEDIUM",
      "status": "pending",
      "created": "2026-04-21T10:15:00Z",
      "resolved": null,
      "resolution": null
    }
  ],
  "last_scan": "2026-04-21T10:00:00Z",
  "scan_count": 7
}
```

Valid statuses: `pending`, `approved`, `rejected`, `applied`, `expired`.

## Step 5: Human Approval Gate (EVOL-05)

The human approval gate is **NON-NEGOTIABLE** for all evolution actions. No change is ever applied automatically, regardless of severity or apparent urgency. The user must explicitly approve every patch proposal before it takes effect.

### Approval Flow

1. **Proposal delivered:** The evolution scan sends the patch proposal to the Telegram approval thread configured in `telegram.yaml`
2. **User reviews:** The user reads the proposal at their convenience (P1 alerts are flagged as urgent but still require approval)
3. **User responds:** The user replies directly to the proposal message:
   - **Approve:** "yes", "approve", "ok", "go ahead", "si", "adelante"
   - **Reject:** "no", "reject", "skip" (with optional feedback explaining why)
4. **Action taken:**
   - On **approval:** Apply the change, update affected agent configs, log to audit trail, confirm via Telegram
   - On **rejection:** Log the rejection reason, mark proposal as rejected, do not apply. The same proposal may resurface in future scans if the underlying condition persists
   - On **timeout:** Do nothing. The safe default is inaction. The proposal remains in `pending` status and is included in the next weekly report as a reminder

### Timeout Configuration

The approval timeout is configured in `governance.yaml`:

```yaml
approvals:
  default_timeout_minutes: 1440     # 24 hours
  reminder_after_minutes: 480       # 8 hours: send a reminder if no response
  timeout_action: none              # On timeout: "none" (safe default)
```

Timeout behavior is always "do nothing." There is no "auto-approve on timeout" option. This is by design: silence means uncertainty, and uncertainty means do not act.

### Audit Trail

Every approval interaction is logged to `.agentbloc/logs/audit.jsonl`:

```json
{
  "timestamp": "2026-04-21T14:30:00Z",
  "event": "evolution_approval",
  "proposal_id": "evol-scan-007-001",
  "action": "approved",
  "user": "operator",
  "channel": "telegram",
  "correlation_id": "evol-007-001-approve"
}
```

Rejected proposals include the user's feedback in a `reason` field. This creates a complete decision record for compliance auditing.

## Evolution Lifecycle

The evolution phase transitions from a guided conversation to an automated weekly cycle:

### Phase 6 Conversation (One-Time Setup)

During the Phase 6 conversation, Claude walks the user through:

1. **Review the evolution config** in `governance.yaml` (scan frequency, day, time, sources)
2. **Confirm the Telegram approval thread** is configured in `telegram.yaml`
3. **Run the first evolution scan** manually to demonstrate the process
4. **Review any initial proposals** and walk through the approval flow
5. **Confirm the cron job** for the weekly scan is active

### Ongoing Automated Cycle

After the one-time setup, the evolution loop runs automatically:

```
SCAN (weekly, sunday 10:00)
  |
  v
DETECT (check sources for features + vulnerabilities)
  |
  v
PROPOSE (generate structured patch proposals)
  |
  v
DELIVER (send to Telegram approval thread)
  |                    |
  v                    v
APPROVE            REJECT / TIMEOUT
  |                    |
  v                    v
APPLY              LOG + DO NOTHING
  |
  v
LOG (audit trail + state update)
```

### Batch vs. Immediate

- **Weekly batch:** Feature proposals (P3-P4 severity), non-urgent updates, and informational findings are accumulated and delivered in a single weekly report
- **Immediate alert:** P1 Critical and P2 High security alerts are delivered as soon as detected, even outside the weekly schedule. The approval gate still applies

### Proposal History

The evolution state file (`.agentbloc/state/evolution.json`) maintains a rolling history of all proposals. This enables:

- Tracking which proposals have been addressed and which are pending
- Resurfacing rejected proposals if the underlying condition worsens (e.g., a P4 vulnerability gets upgraded to P2)
- Generating monthly evolution summaries showing what changed and what was deferred

## Quick Reference

### Evolution Decision Tree

```
SCAN (weekly)
  |-- No findings --> Log "clean scan" --> EXIT
  |-- Feature found --> Generate Feature Proposal --> DELIVER
  |-- Vulnerability found
        |-- P1 Critical --> Immediate Telegram Alert --> APPROVE GATE
        |-- P2 High --> Flag in weekly report --> APPROVE GATE
        |-- P3-P4 --> Include in weekly batch --> APPROVE GATE

APPROVE GATE (NON-NEGOTIABLE)
  |-- User approves --> APPLY change --> Log --> Confirm via Telegram
  |-- User rejects --> Log rejection --> Do nothing
  |-- Timeout --> Do nothing (safe default)
```

### Key Rules

| Rule | Description |
|------|-------------|
| No auto-patching | Human approval required for ALL changes, regardless of severity |
| Timeout = inaction | If the user does not respond, nothing happens |
| Single session scan | One `claude -p` session with WebSearch + Bash handles all scanning |
| Telegram delivery | All proposals delivered via the Telegram approval thread |
| Audit everything | Every scan, proposal, approval, rejection, and application is logged |
| Rollback required | Every patch proposal must include a rollback plan |

### Cross-References

| Reference | What It Provides |
|-----------|-----------------|
| [incident-response.md](incident-response.md) | Severity classification (P1-P4) used for vulnerability prioritization |
| [phase-5-deployment.md](phase-5-deployment.md) | Artifact templates that evolution modifies (agent configs, governance) |
| [telegram-patterns.md](telegram-patterns.md) | Approval-by-reply pattern used for the human approval gate |
| [audit-logging.md](audit-logging.md) | JSONL log format for evolution audit entries |
