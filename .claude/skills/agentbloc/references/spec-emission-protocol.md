# Spec Emission Protocol

> Loaded by SKILL.md and the `spec-engine` subagent at Phase 5 entry.
> Defines the 6-step spec-folder emission flow per
> [v3.0-architecture.md](../../../docs/v3.0-architecture.md).

## Table of Contents

- [When This Applies](#when-this-applies)
- [Inputs and Outputs](#inputs-and-outputs)
- [The 6 Steps](#the-6-steps)
- [Failure Handling](#failure-handling)
- [Cross-References](#cross-references)

## When This Applies

The `spec-engine` subagent invokes this protocol exactly once per
Phase 5 entry. The protocol is imperative: each step has a contract,
a checkpoint, and a failure mode. Skipping or reordering steps is
forbidden.

## Inputs and Outputs

**Inputs (validated at Step 1):**
- `.agentbloc/graph/business-graph.json` (Phase 1 output)
- `.agentbloc/team/agent-profiles.yaml` (Phase 2 output)
- `.agentbloc/integrations/inventory.yaml` (Phase 3 output)
- Phase 4 sign-off (recorded in conversation; SKILL.md asserts before invocation)
- `<destination>` (default `.agentbloc/spec/`; user may override)

**Outputs (delivered at Step 6):**
- A spec folder at `<destination>` matching [spec-folder-structure.md](spec-folder-structure.md)
- `<destination>/SPEC-EMISSION-REPORT.md` per [spec-emission-report-schema.md](spec-emission-report-schema.md)
- Closes Phase 5 sub-gate `spec_folder_emitted`

## The 6 Steps

### Step 1 — Input validation and destination resolution

- Resolve `<destination>` (default or user override)
- Read all three input artifacts; validate each against its schema
- Fail with SPEC-EMISSION-FAILED-REPORT.md(step=1) if any input is missing or invalid
- Snapshot SHA256 of each input to be embedded in the final report

### Step 2 — Core docs emission

- Write `README.md`, `AGENTS.md`, `CLAUDE.md`, `ROADMAP.md` from
  templates at `templates/spec-folder/*.tmpl`
- Substitute `{{team_name}}`, `{{workflow_count}}`, `{{agent_count}}`,
  `{{tool_count}}`, etc. from input artifacts
- Fail with step=2 if any template is missing or any required
  substitution variable is null

### Step 3 — Workflows + agents emission

- For each workflow in `business-graph.json`: write `workflows/<id>.md`
- For each agent in `agent-profiles.yaml`: write `agents/<id>/{role,prompts,tools,blast-radius,escalation}.md`
- Validate cross-references (every workflow's agents must exist in
  agent-profiles.yaml; every agent's tools must exist in inventory.yaml)
- Fail with step=3 on any orphan reference

### Step 4 — Integrations emission

This is the highest-leverage step. Read `inventory.yaml` and write:

- `integrations/INVENTORY.md` (master matrix)
- Per-tier subfolder content per
  [inventory-protocol.md](inventory-protocol.md):
  - `existing/<tool>.md` for `EXISTS-MCP` tier
  - `needs-mcp-wrapper/<tool>/` (README + BUILD + ENDPOINTS + openapi)
    for `NEEDS-MCP-WRAPPER` tier
  - `needs-n8n-flow/<tool>-flow.json` + activation steps for
    `NEEDS-N8N-FLOW` tier
  - `needs-webhook/<tool>-receiver.md` for `NEEDS-WEBHOOK` tier
  - `manual/<tool>.md` for `MANUAL` tier

- Fail with step=4 if any tool has tier `UNKNOWN` (Phase 3 didn't
  complete the inventory) or evidence URL is missing for any tier
  assignment

### Step 5 — Governance + runtime emission

- Write `governance/{blast-radius,audit-trail,pii-redaction,kill-switch,approval-protocol}.md`
- Write `runtime/BUILD.md` (tool-agnostic build plan)
- Copy `templates/spec-folder/runtime/reference-impl/` into
  `runtime/reference-impl/` with adaptive path placeholders
- Write `runtime/alternatives.md`

### Step 6 — Report emission and sub-gate close

- Write `<destination>/SPEC-EMISSION-REPORT.md` per
  [spec-emission-report-schema.md](spec-emission-report-schema.md)
- Compute and embed: input SHA256s, file count, tier breakdown, effort
  estimate, hand-off instructions
- Exit 0; sub-gate `spec_folder_emitted` is now true

## Failure Handling

Any step failure → write SPEC-EMISSION-FAILED-REPORT.md with:
- `step_number` (1-6)
- Plain-English root cause
- Suggested resolution (which prior phase to revisit, or which input to fix)
- List of files that WERE successfully written (so user can inspect or
  manually clean up)

The subagent exits non-zero. SKILL.md surfaces the report and resets
Phase 5 gate to `blocked`. The sub-gate stays false.

## Cross-References

- [phase-5-spec-emission.md](phase-5-spec-emission.md) — orchestration overview
- [spec-folder-structure.md](spec-folder-structure.md) — output shape
- [spec-emission-report-schema.md](spec-emission-report-schema.md) — REPORT.md schema
- [inventory-protocol.md](inventory-protocol.md) — Phase 3 tier system
- [.claude/agents/spec-engine.md](../../../agents/spec-engine.md) — the subagent
