# Phase 5: Spec Emission

> Loaded by SKILL.md when Phase 5 begins. Replaces v2.0 phase-5-deployment.md
> entirely — this phase no longer emits running scripts. It writes a portable
> build-ready spec folder that any AI coding agent (Claude Code, Codex, Gemini,
> Cursor, OpenClaw) can execute.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Sub-gate](#sub-gate)
- [Preconditions](#preconditions)
- [Output: The Spec Folder](#output-the-spec-folder)
- [Emission Protocol (6 Steps)](#emission-protocol-6-steps)
- [SPEC-EMISSION-REPORT.md](#spec-emission-reportmd)
- [Failure Mode: SPEC-EMISSION-FAILED-REPORT.md](#failure-mode-spec-emission-failed-reportmd)
- [Idempotency](#idempotency)
- [Cross-References](#cross-references)

## When This Applies

Phase 5 begins after Phase 4 (Spec Review) gate is `approved`. The user has
walked the proposed spec folder shape with you and explicitly signed off on
scope, blast-radius posture, and effort estimate. This phase is the
materialization step.

The `spec-engine` subagent at `.claude/agents/spec-engine.md` (`context: fork`,
scoped tools) does the actual emission. SKILL.md spawns it; the user reviews
the resulting folder and the SPEC-EMISSION-REPORT.md.

## Sub-gate

`spec_folder_emitted`

This is the **only** sub-gate in Phase 5 (v3.0 simplification — v2.5 had three:
`deployment_artifacts_emitted`, `runtime_wired`, `monitor_wired`). It closes
when:

1. The canonical folder structure exists at the target path
2. Every required file is present and validates against
   [spec-folder-structure.md](spec-folder-structure.md)
3. SPEC-EMISSION-REPORT.md is written to the spec folder root

If any of those fail, SPEC-EMISSION-FAILED-REPORT.md is emitted instead and
the sub-gate stays false. Phase 6 entry halts; surface the failure for user
resolution.

## Preconditions

Before invoking `spec-engine`, verify:

| File | Schema | Source phase |
|---|---|---|
| `.agentbloc/graph/business-graph.json` | [business-graph-schema.md](business-graph-schema.md) | Phase 1 |
| `.agentbloc/team/agent-profiles.yaml` | [agent-profile-schema.md](agent-profile-schema.md) | Phase 2 |
| `.agentbloc/integrations/inventory.yaml` | [inventory-schema.md](inventory-schema.md) | Phase 3 |
| Phase 4 sign-off recorded in conversation | (Spec Review walkthrough) | Phase 4 |

If any upstream artifact is missing or fails validation, return Phase N to
`pending` and re-run that phase's Summary Gate before re-attempting Phase 5.

## Output: The Spec Folder

Default destination: `.agentbloc/spec/`. User can override with an explicit
path. The shape is locked in
[spec-folder-structure.md](spec-folder-structure.md):

```
<destination>/
├── README.md                # Human-English overview
├── AGENTS.md                # Universal AI-tool context (Codex/Cursor/etc)
├── CLAUDE.md                # Claude-Code-specific project context
├── ROADMAP.md               # Phased build plan + effort estimates
│
├── workflows/<id>.md        # WHAT — one per workflow
├── agents/<id>/             # WHO — role, prompts, tools, blast-radius, escalation
├── integrations/            # HOW — INVENTORY.md + per-tier subfolders
│   ├── INVENTORY.md
│   ├── existing/
│   ├── needs-mcp-wrapper/<tool>/
│   ├── needs-n8n-flow/
│   ├── needs-webhook/
│   └── manual/
├── governance/              # Blast-radius, audit, PII, kill-switch, approval
└── runtime/
    ├── BUILD.md             # Tool-agnostic build plan
    ├── reference-impl/      # Bash + cron + Telegram (advisory)
    └── alternatives.md      # n8n / Temporal / Pipedream / Inngest / custom
```

## Emission Protocol (6 Steps)

The `spec-engine` subagent executes these steps in order. Each step is
checkpointed; on any failure, the subagent emits SPEC-EMISSION-FAILED-REPORT.md
with the step number and root cause and exits non-zero.

### Step 1 — Resolve destination and snapshot inputs

- Resolve `<destination>` from user input or default to `.agentbloc/spec/`
- Refuse to overwrite an existing non-empty folder unless the user passed
  `--overwrite` (idempotent re-run safe; see [Idempotency](#idempotency))
- Snapshot SHA256s of the three input artifacts (business-graph.json,
  agent-profiles.yaml, inventory.yaml) into the report header for forensics

### Step 2 — Emit core docs

Write the four root-level docs that drive the build session:

| File | Purpose | Template |
|---|---|---|
| `README.md` | Human-English: what this team does, who it's for | `templates/spec-folder/README.md.tmpl` |
| `AGENTS.md` | Universal AI-tool context (works in Codex/Cursor/etc) | `templates/spec-folder/AGENTS.md.tmpl` |
| `CLAUDE.md` | Claude-Code-specific (uses skills, subagents, hooks vocabulary) | `templates/spec-folder/CLAUDE.md.tmpl` |
| `ROADMAP.md` | Phased build plan with effort estimates per phase | `templates/spec-folder/ROADMAP.md.tmpl` |

`CLAUDE.md` and `AGENTS.md` overlap in substance but differ in emphasis:
AGENTS.md is universal context (works for any tool), CLAUDE.md adds
Claude-Code-specific guidance (skills/subagents/hooks naming). Both are
emitted so the build session has the right entry point regardless of tool.

### Step 3 — Emit workflows + agents

For each workflow in `business-graph.json`, write `workflows/<id>.md` from
[templates/spec-folder/workflows/](../templates/spec-folder/workflows/) with:
- Trigger conditions
- Inputs / outputs
- Falsifiable success criteria
- Failure modes + handling

For each agent in `agent-profiles.yaml`, write `agents/<id>/` with:
- `role.md` (CrewAI-shaped role + goal + backstory)
- `prompts.md` (system prompt + wake prompt; reference implementation)
- `tools.md` (tools this agent uses; cross-links to integrations/)
- `blast-radius.md` (per-agent risk envelope + autonomy level)
- `escalation.md` (failure handling + tier)

### Step 4 — Emit integrations

This is the high-leverage part. Read `inventory.yaml` and write:

- `integrations/INVENTORY.md` — the master tier-ranked matrix (one row per
  tool with tier + evidence URL + setup-effort estimate)
- For tier `EXISTS-MCP`: `integrations/existing/<tool>.md` with install +
  config + auth instructions
- For tier `NEEDS-MCP-WRAPPER`: `integrations/needs-mcp-wrapper/<tool>/`
  containing `README.md`, `BUILD.md` (steps for build session to run
  `mcp-builder` skill), `ENDPOINTS.md` (minimum-viable endpoints with
  least-privilege rationale), and `openapi.yaml` if the wrapper needs a
  spec source
- For tier `NEEDS-N8N-FLOW`: `integrations/needs-n8n-flow/<tool>-flow.json`
  stub + activation instructions
- For tier `NEEDS-WEBHOOK`: `integrations/needs-webhook/<tool>-receiver.md`
  spec for the webhook endpoint the build session will create
- For tier `MANUAL`: `integrations/manual/<tool>.md` documenting why no
  automation path is appropriate (compliance, frequency, cost, complexity)

### Step 5 — Emit governance + runtime references

Write `governance/` with five files (sourced from the v2.0 references that
KEEP-AS-IS):
- `blast-radius.md` (lifted from references/blast-radius.md, contextualized
  to this team's specific agents)
- `audit-trail.md` (what gets logged; schema reference)
- `pii-redaction.md` (GDPR posture; redaction rules)
- `kill-switch.md` (halt mechanism design)
- `approval-protocol.md` (when + how human approval is requested)

Write `runtime/`:
- `BUILD.md` — tool-agnostic build plan; pointers per integration tier
- `reference-impl/` — copy of
  [templates/spec-folder/runtime/reference-impl/](../templates/spec-folder/runtime/reference-impl/)
  (bash + cron + Telegram substrate) with adaptive path placeholders
- `alternatives.md` — when to consider n8n / Temporal / Pipedream / Inngest /
  custom Python instead of the bash reference impl

### Step 6 — Write SPEC-EMISSION-REPORT.md and exit

After all writes succeed, emit SPEC-EMISSION-REPORT.md at the spec folder
root with the schema in [spec-emission-report-schema.md](spec-emission-report-schema.md).
Exit 0. The sub-gate `spec_folder_emitted` is now true.

## SPEC-EMISSION-REPORT.md

Canonical schema (see [spec-emission-report-schema.md](spec-emission-report-schema.md)
for full definition):

- `agentbloc_version`, `emitted_at`, `destination`
- Summary paragraph
- Input snapshot SHA256s for forensics
- Flat tree of every file written + byte counts
- Tier breakdown (count + tools per tier)
- Effort estimate (CC-hours + human days per build phase)
- Hand-off instructions for the build session
- Provenance line

## Failure Mode: SPEC-EMISSION-FAILED-REPORT.md

If any emission step fails, the subagent writes this report instead and
exits non-zero. Captures:

- `failed_at`, `destination`, `step_number` (1-6)
- Plain-English root cause (not a stack trace)
- Step context: what was being attempted
- Suggested resolution (how the user can fix and re-run)
- List of files that WERE successfully written before failure

SKILL.md surfaces this report verbatim and resets Phase 5 gate to `blocked`.

## Idempotency

Re-running spec emission on the same inputs produces the same output
(modulo timestamps in the report). The subagent SHA256s the inputs and
writes them to the report header so a build session can detect drift if
spec is re-emitted with different inputs.

If the destination already contains a spec folder:
- Without `--overwrite`: refuse and emit a warning instead of
  SPEC-EMISSION-FAILED-REPORT.md
- With `--overwrite`: write atomically (tmp folder + rename) so a
  partial overwrite never leaves the destination broken

## Cross-References

- [phase-5-spec-emission.md](phase-5-spec-emission.md) — this file (orchestration)
- [spec-emission-protocol.md](spec-emission-protocol.md) — the 6-step canonical flow
- [spec-folder-structure.md](spec-folder-structure.md) — output shape spec
- [spec-emission-report-schema.md](spec-emission-report-schema.md) — REPORT.md schema
- [.claude/agents/spec-engine.md](../../../agents/spec-engine.md) — the subagent
- [phase-6-evolution.md](phase-6-evolution.md) — what happens after a spec ships
