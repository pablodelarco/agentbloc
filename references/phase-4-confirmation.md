# Step-by-Step Confirmation and Dry Run Protocol

> Loaded by SKILL.md at Phase 4 entry. Defines how you present each agent for individual approval, manage change requests, execute a mandatory dry run with stubbed side-effect tools, generate a dry run report, and obtain final user approval before deployment.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Confirmation Opening](#confirmation-opening)
- [Step 1: Enhanced Contract Card Format](#step-1-enhanced-contract-card-format)
- [Step 2: Sequential Agent Approval](#step-2-sequential-agent-approval)
- [Step 3: Integration Summary Gate](#step-3-integration-summary-gate)
- [Step 4: Dry Run Configuration](#step-4-dry-run-configuration)
- [Step 5: Dry Run Execution](#step-5-dry-run-execution)
- [Step 6: Dry Run Report](#step-6-dry-run-report)
- [Step 7: Final Approval Gate](#step-7-final-approval-gate)
- [Quick Reference](#quick-reference)

## When This Applies

You read this file when the Phase 3 (Deep Integration Analysis) gate is approved and Phase 4 begins. Your input is the set of integration-enhanced agent contract cards produced during Phase 3: each agent's original design card (from [references/phase-2-design.md](phase-2-design.md)) with three added sections: Selected Integrations, Prompt Injection Defense, and Credential Summary.

Before presenting any agent, also load:
- [references/blast-radius.md](blast-radius.md) for the approval matrix (Level 3-4 agents require human approval)
- [references/audit-logging.md](audit-logging.md) for governance context during the dry run
- [references/incident-response.md](incident-response.md) for kill switch patterns referenced during governance review
- [references/credentials.md](credentials.md) for credential types shown in confirmation cards

## Confirmation Opening

Explain the phase to the user. Adapt to their technical level.

**Non-technical:**
> "Now I'll walk through each agent one at a time. For each one, you'll see exactly what it does, what services it connects to, how it handles problems, and what passwords or logins it needs. You can change anything before we test it. After you approve all agents, we'll do a safe test run where the agents read your real data but don't actually send any messages or change anything."

**Technical-basics:**
> "We'll review each agent individually. For each one, I'll show you the full contract card with integrations, credentials, and failure handling. Once all agents are confirmed, we run a mandatory dry run: real reads, stubbed writes and sends. Nothing changes until you approve the results."

**Developer:**
> "Sequential per-agent confirmation with integration-enhanced contract cards. After approval, mandatory dry run with dual-layer enforcement: prompt-level instruction + PreToolUse hooks + subagent tool restriction. All READ operations execute against real data. All WRITE/SEND operations are stubbed and logged."

## Step 1: Enhanced Contract Card Format

Each agent is presented using the contract card format from [references/phase-2-design.md](phase-2-design.md), enhanced with integration findings from Phase 3. The enhanced card adds three sections below the standard fields.

### Template

```markdown
### Agent: [Agent Name]

| Field | Value |
|-------|-------|
| **Role** | [from design phase] |
| **Responsibility** | [from design phase] |
| **Inputs** | [from design phase] |
| **Outputs** | [from design phase] |
| **Dependencies** | [from design phase] |
| **Tools** | [from design phase] |
| **Trigger** | [from design phase] |
| **Blast Radius** | [from design phase] |
| **Approval Required** | [from design phase] |
| **Model** | [from design phase] |
| **Failure Handling** | [from design phase] |

**Selected Integrations:**

| Service | Method | Trust | Credential | Setup |
|---------|--------|-------|------------|-------|
| [service] | [recommended method from decision matrix] | [HIGH/MEDIUM/LOW] | [OAuth/API key/admin per credentials.md] | [low/medium/high] |

**Prompt Injection Defense:** [Layer assignment from references/prompt-injection.md, refined during integration analysis]

**Credential Summary:**

| Service | Credential Type | Scope | Rotation | Env Variable |
|---------|----------------|-------|----------|--------------|
| [service] | [OAuth 2.0 / scoped API key / admin token] | [specific scope] | [rotation period] | AGENTBLOC_{SERVICE}_{TYPE} |
```

### Behavior by Level

**Non-technical users:** Present a plain-language summary BEFORE the full card. This summary explains what the agent does, what it connects to, and what access it needs, without technical jargon.

Example summary for a non-technical user:
> "This agent collects invoices from Xero, Endesa, and Gmail every day at 10pm. It needs your Xero login, Endesa portal password, and Google account access. It saves what it finds to a local file but never sends messages or changes anything in your accounts."

After the summary, show the full card for the record. If the user seems confused by the card, focus discussion on the summary.

**Technical-basics and developer users:** Show the full card immediately. Highlight changes from the original design phase card (new integrations, updated blast-radius, credential additions).

### Example: Arco Rooms Invoice Collector

**Plain-language summary (non-technical):**
> "This agent collects invoices from Xero, Endesa, and Gmail every day at 10pm. It needs your Xero login, Endesa portal password, and Google account access. It saves what it finds to a local file but never sends messages or changes anything in your accounts."

**Full enhanced card:**

```markdown
### Agent: Invoice Collector

| Field | Value |
|-------|-------|
| **Role** | Invoice Collection Specialist |
| **Responsibility** | Fetch new invoices from utility providers |
| **Inputs** | Provider credentials (env vars), state/processed-invoices.json |
| **Outputs** | state/invoices.json (new invoices appended) |
| **Dependencies** | None (first in pipeline) |
| **Tools** | Read, Write, Glob, mcp__xero__*, mcp__playwright__* |
| **Trigger** | Daily at 22:00 (`0 22 * * *`) |
| **Blast Radius** | Level 2 (write-scoped) |
| **Approval Required** | No |
| **Model** | Sonnet |
| **Failure Handling** | Retry 3x per provider, skip on persistent failure, alert via Telegram |

**Selected Integrations:**

| Service | Method | Trust | Credential | Setup |
|---------|--------|-------|------------|-------|
| Xero | Official MCP (xero-mcp@beta) | HIGH | OAuth 2.0 (read:invoices) | Medium |
| Endesa | Playwright browser automation | HIGH (Microsoft) | Web login (env vars) | High |
| Gmail (invoice emails) | Google Workspace MCP | HIGH | OAuth 2.0 (gmail.readonly) | Medium |

**Prompt Injection Defense:** Layers 1, 2, 3 (ingests emails and web pages)

**Credential Summary:**

| Service | Credential Type | Scope | Rotation | Env Variable |
|---------|----------------|-------|----------|--------------|
| Xero | OAuth 2.0 | read:invoices | Auto-refresh | AGENTBLOC_XERO_CLIENT_ID, AGENTBLOC_XERO_CLIENT_SECRET |
| Endesa | Web login | Portal access | 90 days | AGENTBLOC_ENDESA_USER, AGENTBLOC_ENDESA_PASS |
| Gmail | OAuth 2.0 | gmail.readonly | Auto-refresh | AGENTBLOC_GOOGLE_OAUTH_CLIENT_ID, AGENTBLOC_GOOGLE_OAUTH_CLIENT_SECRET |
```

## Step 2: Sequential Agent Approval

Present agents strictly one at a time in their pipeline/topology execution order. Never present the next agent until the current one is approved.

### Approval Flow

For each agent:

1. **Present the enhanced contract card** (with plain-language summary for non-technical users).
2. **Ask:** "Do you approve this agent, or would you like to make changes?"
3. **If approved:** Record the approval. Move to the next agent.
4. **If changes requested:** Update the card based on feedback. Present the updated card for re-approval. Repeat until approved.

### Allowed Changes

The user can request any of the following during confirmation:

- Change the integration method for a service (swap API for Playwright, etc.)
- Adjust the blast-radius level (with warning if lowering, per [references/blast-radius.md](blast-radius.md))
- Modify failure handling strategy (retry count, skip vs halt, notification target)
- Add or remove integrations
- Change credential type or scope
- Modify the trigger schedule
- Change the model assignment

### Change Propagation

When a change to one agent affects downstream agents, propagate it:

- If Agent A's output format changes, check if Agent B (which consumes that output) needs adjustment.
- If a shared credential scope changes, update all agents that use it.
- If a blast-radius override changes the approval requirement, update the governance summary.

Announce propagated changes: "Updating Agent A's output format also requires adjusting Agent B's input parsing. I've updated both cards."

### Confirmation Fatigue Mitigation

If the user appears to be rubber-stamping approvals (approving instantly without review, saying "just approve them all," or approving in under 5 seconds), slow down:

- **Highlight what is different** about this agent compared to the previous one or compared to the original design.
- **Call out high-impact elements:** "This agent has Level 4 blast radius -- it sends external messages. Worth a closer look."
- **For non-technical users:** Present a "key changes from design phase" highlight before each card, summarizing what changed during integration analysis.

If the user explicitly asks to batch-approve remaining agents, comply but note: "Understood. Approving the remaining agents. Each one's full card is recorded in your confirmation log for reference."

## Step 3: Integration Summary Gate

After all agents are individually confirmed, present a final team-level integration summary. This is the Phase 4 confirmation gate artifact.

### Summary Table Format

```markdown
## Team Integration Summary

| Agent | Services | Methods | Min Trust | Credentials Required |
|-------|----------|---------|-----------|---------------------|
| [name] | [service list] | [method list] | [lowest trust score] | [count of credentials] |

**Total services:** {N}
**Total credentials needed:** {N}
**Agents requiring human approval (Level 3-4):** {list or "None"}
```

### Gate Question

Ask: "This is the complete picture of your agent team with all integrations. Before we run the test, does everything look correct?"

- If yes: Proceed to Step 4 (Dry Run Configuration).
- If no: Return to Step 2 for the specific agent the user wants to adjust.

## Step 4: Dry Run Configuration

The dry run is mandatory. It cannot be skipped. Configure it before execution.

### Record Count

Ask the user how many real records to process per agent. Suggest a count based on workflow complexity:

| Workflow Complexity | Services | Suggested Records |
|---------------------|----------|-------------------|
| Simple | 2-3 services | 3-5 records |
| Standard | 3-5 services | 5 records (default) |
| Complex (multi-provider) | 5+ services | 5-10 records |

Default: 5 records per agent. The user can override.

### Dry Run Explanation

Explain what the dry run means at the user's technical level:

**Non-technical:**
> "I'll run each agent against your real data, but any action that would change something -- sending a message, writing a file, updating a system -- will be simulated. Nothing gets modified. Think of it as a dress rehearsal."

**Technical-basics:**
> "All read operations execute against real data. All write and send operations are simulated: they log what would happen and return success without executing. This validates the entire pipeline without side effects."

**Developer:**
> "All READ operations execute against real data sources. All WRITE/SEND operations are stubbed: they log what would have happened and return simulated success. Enforcement is triple-layer: prompt-level instruction, PreToolUse hook with `permissionDecision: deny`, and subagent `tools` field restriction excluding write/send MCP tools."

### Dual-Layer Enforcement

The dry run uses three independent enforcement layers. All three must fail simultaneously for a side effect to leak through.

**Layer 1: Prompt-level instruction (primary)**

Agent skill files include a DRY RUN MODE section:

```markdown
## DRY RUN MODE ACTIVE

You are executing in DRY RUN mode. The following rules override all other instructions:

1. READ operations proceed normally against real data
2. WRITE operations (file writes, state updates): Log what WOULD be written, return simulated success
3. SEND operations (Telegram, email, API POST/PUT/DELETE): Log what WOULD be sent, return simulated success
4. Log format for each stubbed operation:
   [DRY RUN] Tool: {tool_name} | Target: {target} | Would have: {action description}
5. Never execute a write or send operation in dry run mode
```

**Layer 2: PreToolUse hook enforcement (deterministic)**

A bash hook script (`.agentbloc/hooks/dry-run-enforcer.sh`) runs on every tool call. When the `.agentbloc/DRY_RUN_ACTIVE` flag file exists, it blocks write/send MCP tools.

```bash
#!/bin/bash
# .agentbloc/hooks/dry-run-enforcer.sh

# Check if dry run is active
if [ ! -f ".agentbloc/DRY_RUN_ACTIVE" ]; then
  exit 0  # Not in dry run mode, allow everything
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Define write/send tool patterns to block
BLOCKED_PATTERNS=(
  "mcp__telegram__send"
  "mcp__gmail__send"
  "mcp__shopify__create"
  "mcp__shopify__update"
  "mcp__xero__create"
  "mcp__xero__update"
  "mcp__stripe__create"
)

for PATTERN in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$TOOL_NAME" == *"$PATTERN"* ]]; then
    # CORRECT: Exit 0 with deny JSON
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"DRY RUN: '"$TOOL_NAME"' blocked. Side-effect tools are stubbed during dry run."}}'
    exit 0
  fi
done

# Block Write/Edit to non-report paths during dry run
if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
  if [[ "$FILE_PATH" != *".agentbloc/dry-run-report"* && "$FILE_PATH" != *".agentbloc/logs"* ]]; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"DRY RUN: Write to '"$FILE_PATH"' blocked. Only dry run reports and logs are writable."}}'
    exit 0
  fi
fi

exit 0
```

Hook configuration in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__*|Write|Edit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .agentbloc/hooks/dry-run-enforcer.sh"
          }
        ]
      }
    ]
  }
}
```

**Anti-pattern warning:** Exit code 2 means "hook crashed," not "policy denied." Claude Code may ignore it and proceed with the tool call. Always use exit 0 with the JSON `permissionDecision: "deny"` structure. Similarly, exit code 1 is treated as a non-blocking error. The JSON deny via exit 0 is the only correct enforcement path.

**Layer 3: Subagent tool restriction (belt-and-suspenders)**

During dry run, agent subagent definitions use the `tools` field to exclude write/send MCP tools entirely:

```yaml
---
name: invoice-collector-dryrun
description: Dry run version of invoice-collector with read-only tools
tools: Read, Grep, Glob, WebSearch, WebFetch, mcp__playwright__navigate, mcp__playwright__snapshot
# Note: NO mcp__telegram, NO mcp__shopify__create, NO mcp__xero__create, etc.
---
```

### Flag File

Before starting the dry run, create the flag file:
```bash
mkdir -p .agentbloc && touch .agentbloc/DRY_RUN_ACTIVE
```

After all agents complete the dry run, remove it:
```bash
rm .agentbloc/DRY_RUN_ACTIVE
```

The flag file controls Layer 2 enforcement. It must exist for the entire duration of the dry run and must be removed before production execution begins.

## Step 5: Dry Run Execution

Execute each agent in pipeline/topology order against the configured number of real records.

### Per-Agent Execution

For each agent in order:

1. **Load the agent's skill file** with the DRY RUN MODE preamble injected.
2. **Execute read operations** against real data sources (APIs, files, databases). These proceed normally.
3. **Log every stubbed write/send operation** with the `[DRY RUN]` prefix and the format: `[DRY RUN] Tool: {tool_name} | Target: {target} | Would have: {action description}`.
4. **Record results:** operations performed, data read, actions that would have been taken, any errors encountered.
5. **If an agent fails** (error, missing data, credential issue, timeout): record the failure with details and continue to the next agent. Do not halt the entire dry run for a single agent failure.
6. **Pass the agent's simulated output** to the next agent in the pipeline as if the write had succeeded.

### Execution Model

For v1.0, the dry run is a conversational simulation within the AgentBloc session. You walk through what each agent would do step-by-step, executing real reads and logging simulated writes. This avoids the complexity of spawning actual subagents during the design conversation. The deployment phase (Phase 5) generates actual subagent definitions with dry-run hooks for post-deployment testing.

### Completion

After all agents complete, remove the DRY_RUN_ACTIVE flag file. Proceed to the dry run report.

## Step 6: Dry Run Report

Generate a structured markdown report summarizing the dry run results.

### Report Template

```markdown
# Dry Run Report

**Team:** {team_name}
**Date:** {date}
**Records processed:** {N} per agent
**Mode:** DRY RUN (all side-effect tools stubbed)

## Per-Agent Results

### Agent: [Name]
**Status:** PASS / FAIL / PASS (with warnings)

| # | Operation | Type | Target | Result |
|---|-----------|------|--------|--------|
| 1 | [description] | READ (real) | [target] | [result] |
| 2 | [description] | WRITE (stubbed) | [target] | [DRY RUN] Would have: [action] |
| 3 | [description] | SEND (stubbed) | [target] | [DRY RUN] Would have: [action] |

**Errors:** [list or "None"]
**Warnings:** [list or "None"]
**Verdict:** PASS / FAIL with explanation

[Repeat for each agent]

## Summary

| Agent | Read Ops | Write Ops (stubbed) | Send Ops (stubbed) | Errors | Verdict |
|-------|----------|--------------------|--------------------|--------|---------|
| [name] | [count] | [count] | [count] | [count] | [verdict] |

**Overall:** [summary verdict]
```

### Verdict Criteria

| Verdict | Condition |
|---------|-----------|
| **PASS** | Agent completed all operations. Reads returned expected data. Stubbed writes/sends logged correctly. No errors. |
| **PASS (with warnings)** | Agent completed but with non-critical issues: missing optional data, low-confidence matches, expected edge cases (unmapped entities, etc.). |
| **FAIL** | Agent could not complete its operations: credential failure, API error, missing required data, unexpected exceptions. |

### Example: Arco Rooms Dry Run Report

```markdown
# Dry Run Report

**Team:** Arco Rooms Property Management
**Date:** 2026-04-14
**Records processed:** 5 per agent
**Mode:** DRY RUN (all side-effect tools stubbed)

## Per-Agent Results

### Agent: Invoice Collector
**Status:** PASS

| # | Operation | Type | Target | Result |
|---|-----------|------|--------|--------|
| 1 | Read invoices from Xero | READ (real) | Xero API | 3 invoices retrieved |
| 2 | Read emails from Gmail | READ (real) | Gmail MCP | 2 invoice emails found |
| 3 | Navigate Endesa portal | READ (real) | Playwright | Portal loaded, 1 invoice found |
| 4 | Write to state/invoices.json | WRITE (stubbed) | .agentbloc/state/invoices.json | [DRY RUN] Would append 6 invoice records |
| 5 | Send notification | SEND (stubbed) | Telegram operations thread | [DRY RUN] Would send: "6 new invoices collected" |

**Errors:** None
**Verdict:** PASS

### Agent: Payment Matcher
**Status:** PASS (with warnings)

| # | Operation | Type | Target | Result |
|---|-----------|------|--------|--------|
| 1 | Read bank transactions | READ (real) | Bank MCP | 12 transactions retrieved |
| 2 | Read invoices state | READ (real) | .agentbloc/state/invoices.json | 6 invoices loaded |
| 3 | Match transactions | PROCESS | In-memory | 4 high-confidence, 1 low-confidence, 1 unmatched |
| 4 | Write matches | WRITE (stubbed) | .agentbloc/state/matches.json | [DRY RUN] Would write 5 match records |
| 5 | Flag for review | SEND (stubbed) | Telegram | [DRY RUN] Would send: "1 low-confidence match needs review" |

**Warnings:** 1 transaction could not be matched (new tenant not in mapping)
**Verdict:** PASS (unmapped entity expected for new tenants)

### Agent: Report Sender
**Status:** PASS

| # | Operation | Type | Target | Result |
|---|-----------|------|--------|--------|
| 1 | Read matches state | READ (real) | .agentbloc/state/matches.json | 5 matches loaded |
| 2 | Send daily summary | SEND (stubbed) | Telegram operations thread | [DRY RUN] Would send: daily summary with 5 matched payments |
| 3 | Send tenant notifications | SEND (stubbed) | Telegram tenant threads | [DRY RUN] Would send: 4 payment confirmations to tenants |
| 4 | Send review request | SEND (stubbed) | Telegram operations thread | [DRY RUN] Would send: "1 low-confidence match needs review" |

**Errors:** None
**Verdict:** PASS

## Summary

| Agent | Read Ops | Write Ops (stubbed) | Send Ops (stubbed) | Errors | Verdict |
|-------|----------|--------------------|--------------------|--------|---------|
| Invoice Collector | 3 | 1 | 1 | 0 | PASS |
| Payment Matcher | 2 | 1 | 1 | 0 | PASS (warnings) |
| Report Sender | 1 | 0 | 3 | 0 | PASS |

**Overall:** All agents passed dry run. Ready for deployment approval.
```

## Step 7: Final Approval Gate

Present the dry run report and ask for explicit approval.

### All Agents Passed

> "All agents completed the dry run successfully. Review the results above. Approve to proceed to deployment, or request changes."

If the user approves: update the state bar to `Phase 4: Step-by-Step Confirmation + Dry Run | Gate: approved | Level: {level}`. Prepare to transition to Phase 5 (Deployment).

### Any Agent Failed

> "Agent {name} encountered issues during the dry run. I recommend addressing these before deployment: {specific issues with context}. Would you like to adjust the agent and re-run, or proceed with the known issues?"

If the user wants to fix:
- Return to Step 2 for the specific agent that needs adjustment.
- After changes, re-run the dry run (return to Step 4).

If the user accepts the known issues:
- Document the accepted issues in the dry run report under an "Accepted Risks" section.
- Proceed to deployment with a note that these issues are known.

### User Requests Re-Run

If the user asks to re-run the dry run (different record count, after config changes, etc.):
- Return to Step 4 with the updated configuration.
- Generate a new dry run report that replaces the previous one.

## Quick Reference

| Step | What It Does | Key Output |
|------|-------------|------------|
| Enhanced Contract Card | Presents each agent with integration data | Card with Selected Integrations, Credential Summary, Prompt Injection Defense |
| Sequential Approval | One agent at a time, confirm or change | Approval record per agent |
| Integration Summary Gate | Team-level overview after all agents approved | Summary table with total services, credentials, approval agents |
| Dry Run Configuration | Set record count, explain enforcement | DRY_RUN_ACTIVE flag created |
| Dry Run Execution | Run agents against real data, stub side effects | Per-agent operation logs |
| Dry Run Report | Structured results with per-agent verdicts | Markdown report with summary table |
| Final Approval Gate | User approves or requests changes | Phase 4 gate approved/blocked |

### Enforcement Layer Summary

| Layer | Mechanism | Controls | Failure Mode |
|-------|-----------|----------|--------------|
| 1 (Prompt) | DRY RUN MODE section in skill file | Agent behavior | LLM may not follow perfectly |
| 2 (Hook) | PreToolUse with `permissionDecision: "deny"` (exit 0 + JSON) | Tool execution | Deterministic block |
| 3 (Subagent) | `tools` field excludes write/send MCP tools | Tool availability | Tools not available at all |

### Card Fields Added in Phase 4

| Section | Source | Purpose |
|---------|--------|---------|
| Selected Integrations | Phase 3 decision matrix | Shows chosen method, trust, credential, setup per service |
| Prompt Injection Defense | Phase 3 analysis + [references/prompt-injection.md](prompt-injection.md) | Layer assignment for agents ingesting external content |
| Credential Summary | Phase 3 analysis + [references/credentials.md](credentials.md) | Service, type, scope, rotation, env variable per credential |

### Verdict Criteria Summary

| Verdict | Meaning | Action |
|---------|---------|--------|
| PASS | All operations succeeded | Approve for deployment |
| PASS (with warnings) | Non-critical issues found | Review warnings, approve if acceptable |
| FAIL | Critical issues prevented completion | Fix agent and re-run dry run |
