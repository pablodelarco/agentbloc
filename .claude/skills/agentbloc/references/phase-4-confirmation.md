# Phase 4: Spec Review

> Loaded by SKILL.md at Phase 4 entry. Reframed in v3.0 from
> "Confirmation + Dry Run" to "Spec Review" — there is nothing to dry-run
> because v3.0 emits a spec folder, not running scripts. Spec Review is a
> walkthrough + sign-off ritual before the spec-engine subagent writes
> any files.

## Table of Contents

- [When This Applies](#when-this-applies)
- [What Spec Review Is](#what-spec-review-is)
- [Sub-gate](#sub-gate)
- [Walkthrough Protocol](#walkthrough-protocol)
- [Cross-References](#cross-references)

## When This Applies

Phase 4 begins after Phase 3 (Deep Tool Discovery) gate is `approved`.
The user has confirmed the tier-ranked tool inventory. Phase 4 closes
with the user signing off on what AgentBloc is about to write to the
spec folder.

There is no dry run. Nothing executes in v3.0. Spec Review replaces
the v2.0 dry-run ritual with a walkthrough.

## What Spec Review Is

A structured conversation in which you (AgentBloc) walk the user
through the proposed spec folder shape **without writing any files**.
The user gets to push back on anything before it's cemented. After
sign-off, Phase 5 emission is mechanical.

The walkthrough covers six dimensions:

1. **Workflows** — every workflow has falsifiable success criteria
2. **Agents** — every agent has unambiguous role / goal / blast-radius / autonomy
3. **Tools** — every tool has a tier + readiness assessment + evidence URL
4. **Governance** — PII, GDPR, audit, kill-switch, approval posture is documented
5. **Effort** — build estimate (CC-hours, human days) is realistic
6. **Hand-off completeness** — the build session has everything it
   needs (CLAUDE.md context, ROADMAP.md, per-tool BUILD.md instructions)

## Sub-gate

`spec_review_signed_off`

This gate has no file artifact (unlike Phase 3's `inventory.yaml` or
Phase 5's spec folder). It closes only when the user explicitly says
"approved" / "yes" / "adelante" / equivalent after reviewing the
walkthrough.

If the user pushes back on any dimension, return to the relevant
upstream phase:
- Workflow scope changes → Phase 1 (re-interview that workflow)
- Agent role / topology changes → Phase 2 (re-run designer-agent)
- Tool tier disagreement → Phase 3 (re-run inventory-protocol for that tool)
- Governance gap → walk it back through whichever phase introduced it

## Walkthrough Protocol

Render the proposed spec folder shape as a tree (preview only — no
files written yet):

```
<destination>/
├── README.md                      # <one-line preview of the team's purpose>
├── AGENTS.md                      # <one-line: what's in here>
├── CLAUDE.md                      # <one-line>
├── ROADMAP.md                     # <one-line: build phases summary>
│
├── workflows/
│   ├── 01-<workflow-id>.md        # <one-line success criteria>
│   └── ...
│
├── agents/
│   ├── <agent-id>/
│   │   ├── role.md                # <one-line role + autonomy>
│   │   ├── prompts.md
│   │   ├── tools.md               # <list of tool refs>
│   │   ├── blast-radius.md        # <Level N>
│   │   └── escalation.md
│   └── ...
│
├── integrations/
│   ├── INVENTORY.md               # <tier breakdown summary>
│   ├── existing/                  # <N tools>
│   ├── needs-mcp-wrapper/<tool>/  # <N tools>
│   ├── needs-n8n-flow/            # <N tools>
│   ├── needs-webhook/             # <N tools>
│   └── manual/                    # <N tools>
│
├── governance/
│   ├── blast-radius.md            # <highest agent level>
│   ├── audit-trail.md
│   ├── pii-redaction.md           # <PII categories present>
│   ├── kill-switch.md
│   └── approval-protocol.md
│
└── runtime/
    ├── BUILD.md
    ├── reference-impl/            # bash + cron + Telegram (advisory)
    └── alternatives.md
```

Then walk the six dimensions in order. For each, summarize what will be
written and ask: "Does this match what you want?" Don't move on until
the user explicitly confirms.

Pay special attention to:

- **Workflow success criteria** — are they falsifiable? "Process invoices
  faster" is not falsifiable; "Process all new invoices within 5 minutes
  of arrival, with <2% manual review rate" is.
- **Tier evidence** — every NEEDS-MCP-WRAPPER tool needs an OpenAPI
  source the build session can use. Every NEEDS-N8N-FLOW tool needs a
  rationale why n8n won over a code-based path.
- **Effort estimate honesty** — if the build estimate looks light, push
  it up. The build session inherits this estimate; an unrealistic number
  burns trust.

After all six dimensions are confirmed, mark the sub-gate
`spec_review_signed_off` as true and advance to Phase 5.

## Cross-References

- [phase-3-integration.md](phase-3-integration.md) — what Phase 3 produced
- [phase-5-spec-emission.md](phase-5-spec-emission.md) — what Phase 5 will write
- [spec-folder-structure.md](spec-folder-structure.md) — canonical output shape
- [inventory-protocol.md](inventory-protocol.md) — tier system
