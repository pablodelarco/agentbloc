# Spec Folder Structure

> The canonical output shape that AgentBloc Phase 5 emits. Every file in
> the tree below is required (or explicitly conditional). Build sessions
> in any AI coding tool consume this folder as their ground truth.

## Table of Contents

- [The Tree](#the-tree)
- [Per-File Contracts](#per-file-contracts)
- [Conditional Files](#conditional-files)
- [Validation Checklist](#validation-checklist)
- [Why This Shape](#why-this-shape)

## The Tree

```
<destination>/
├── README.md                            # required — human-English overview
├── AGENTS.md                            # required — universal AI-tool context
├── CLAUDE.md                            # required — Claude-Code-specific context
├── ROADMAP.md                           # required — phased build plan + effort
├── SPEC-EMISSION-REPORT.md              # required — written last by spec-engine
│
├── workflows/                           # required (>=1 workflow)
│   └── <workflow-id>.md                 # one per business-graph workflow
│
├── agents/                              # required (>=1 agent)
│   └── <agent-id>/                      # one folder per agent
│       ├── role.md                      # required — CrewAI-shaped role/goal/backstory
│       ├── prompts.md                   # required — system + wake prompt reference
│       ├── tools.md                     # required — tools used (links to integrations/)
│       ├── blast-radius.md              # required — risk envelope + autonomy
│       └── escalation.md                # required — failure handling + tier
│
├── integrations/                        # required
│   ├── INVENTORY.md                     # required — master tier-ranked matrix
│   ├── existing/                        # conditional — present if any tier=EXISTS-MCP
│   │   └── <tool>.md
│   ├── needs-mcp-wrapper/               # conditional — present if any tier=NEEDS-MCP-WRAPPER
│   │   └── <tool>/
│   │       ├── README.md
│   │       ├── BUILD.md                 # how to invoke mcp-builder skill
│   │       ├── ENDPOINTS.md             # minimum-viable endpoints
│   │       └── openapi.yaml             # optional — present if API has OpenAPI
│   ├── needs-n8n-flow/                  # conditional
│   │   └── <tool>-flow.json             # n8n flow stub
│   ├── needs-webhook/                   # conditional
│   │   └── <tool>-receiver.md
│   └── manual/                          # conditional
│       └── <tool>.md                    # rationale for manual handling
│
├── governance/                          # required
│   ├── blast-radius.md                  # required — per-agent risk envelopes
│   ├── audit-trail.md                   # required — what gets logged + schema
│   ├── pii-redaction.md                 # required — GDPR posture
│   ├── kill-switch.md                   # required — halt mechanism design
│   └── approval-protocol.md             # required — when/how approval is requested
│
└── runtime/                             # required
    ├── BUILD.md                         # required — tool-agnostic build plan
    ├── reference-impl/                  # required — bash + cron + Telegram
    │   ├── README.md
    │   ├── helpers.sh
    │   ├── wake.sh
    │   ├── claude-wrap.sh
    │   ├── telegram-send.sh
    │   ├── telegram-poll.sh
    │   ├── approval-router.sh
    │   ├── escalation-router.sh
    │   ├── cron-generator.sh
    │   ├── loop.sh
    │   ├── activity-feed-merge.sh
    │   ├── hooks/autonomy-gate.sh
    │   └── .env.example
    └── alternatives.md                  # required — n8n/Temporal/Pipedream/Inngest/custom
```

## Per-File Contracts

| File | Purpose | Audience |
|---|---|---|
| `README.md` | One-pager: what this team does, who it's for, why | Human reading the repo |
| `AGENTS.md` | Universal AI-tool entry point | Codex, Cursor, OpenClaw, Gemini |
| `CLAUDE.md` | Claude-Code-specific entry point (skills/subagents/hooks vocab) | Claude Code |
| `ROADMAP.md` | Phased build plan: integrations first, then workflows, then runtime, then ship; effort estimates per phase | Build session orchestrator |
| `SPEC-EMISSION-REPORT.md` | Provenance + sub-gate close + tier breakdown + hand-off | Operator + future evolution |
| `workflows/<id>.md` | Trigger conditions, inputs, outputs, falsifiable success criteria, failure modes | Build session per workflow |
| `agents/<id>/role.md` | CrewAI-shaped role + goal + backstory + autonomy level | Build session per agent |
| `agents/<id>/prompts.md` | Reference system prompt + wake prompt | Build session implementing the agent |
| `agents/<id>/tools.md` | Tools list with cross-links to `integrations/*/<tool>` | Build session wiring tools |
| `agents/<id>/blast-radius.md` | This agent's risk envelope, why this autonomy was picked | Build session + governance review |
| `agents/<id>/escalation.md` | Failure tiers, escalation targets, retry policy | Build session error-handling |
| `integrations/INVENTORY.md` | Master tier-ranked table: tool, tier, evidence URL, effort | Build session triage entry point |
| `integrations/existing/<tool>.md` | Install + config + auth for the existing MCP | Build session per tier-1 tool |
| `integrations/needs-mcp-wrapper/<tool>/` | Wrapper spec + mcp-builder invocation steps | Build session per tier-2 tool |
| `integrations/needs-n8n-flow/<tool>-flow.json` | n8n flow stub user imports | Build session per tier-3 tool |
| `integrations/needs-webhook/<tool>-receiver.md` | Webhook receiver design spec | Build session per tier-4 tool |
| `integrations/manual/<tool>.md` | Why automation isn't appropriate; manual procedure | Operator + audit |
| `governance/*.md` | Cross-cutting safety contracts | Build session + ongoing review |
| `runtime/BUILD.md` | Tool-agnostic build plan; pointers per integration tier | Build session orchestrator |
| `runtime/reference-impl/*.sh` | Working bash substrate (advisory) | Build session if it picks bash + cron |
| `runtime/alternatives.md` | n8n / Temporal / Pipedream / Inngest / custom Python tradeoffs | Build session picking a runtime |

## Conditional Files

Subfolders under `integrations/` exist only if at least one tool was
classified into that tier in Phase 3. An empty tier means no subfolder
(don't write `integrations/needs-webhook/` if zero webhooks exist).

`integrations/needs-mcp-wrapper/<tool>/openapi.yaml` is present only if
the wrapper synthesis path has an OpenAPI source. Without one, the
build session will discover endpoints empirically using
[browser-fallback.md](browser-fallback.md) — `BUILD.md` documents the
fallback.

## Validation Checklist

`spec-engine` verifies all of these before writing
`SPEC-EMISSION-REPORT.md` and exiting Step 6:

- [ ] All required files present
- [ ] At least one workflow exists in `workflows/`
- [ ] At least one agent exists in `agents/`
- [ ] `integrations/INVENTORY.md` accounts for every tool referenced in
      any agent's `tools.md`
- [ ] Every workflow's referenced agents exist in `agents/`
- [ ] Every agent's referenced tools exist in `integrations/INVENTORY.md`
- [ ] Every governance file has content (not just stub)
- [ ] `runtime/reference-impl/` has all 12+ files cherry-picked from
      AgentBloc's substrate
- [ ] `ROADMAP.md` has a tier-aware build sequence (existing-MCP first,
      then needs-mcp-wrapper, then needs-n8n-flow / needs-webhook in
      parallel, then runtime + governance + ship)

Any unchecked → SPEC-EMISSION-FAILED-REPORT.md, sub-gate stays false.

## Why This Shape

- **Build session entry point clarity.** A new Claude Code (or Codex,
  Gemini, Cursor, OpenClaw) session opens the folder and reads
  `CLAUDE.md`/`AGENTS.md`. It immediately knows there's a `ROADMAP.md`
  to follow and a `workflows/` + `agents/` + `integrations/` tree to
  consume.
- **Tier-driven implementation order.** `integrations/` is sorted by
  tier subfolder so the build session does easy work (existing MCPs)
  first, then escalates to harder work (custom wrappers, n8n flows,
  webhooks). `ROADMAP.md` enforces this order with effort estimates.
- **Governance is co-located.** Cross-cutting concerns (PII, audit,
  blast-radius) live in `governance/` instead of being scattered
  across agent definitions. The build session reads governance once
  and applies it across the whole team.
- **Runtime is explicitly advisory.** `runtime/reference-impl/` is
  marked clearly as one option; `alternatives.md` lists others. The
  build session picks the right runtime for the user's environment
  (bash + cron is fine for a laptop demo, n8n for a non-technical user,
  Temporal for production-scale durability).
- **Spec evolution is grep-able.** Phase 6 reruns `spec-engine` with
  diff mode; the flat structure makes "which files changed?" trivial
  to compute.
