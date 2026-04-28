# AGENTS.md — Arco Rooms Team

> Universal AI-tool context. Works in Codex, Cursor, Gemini, OpenClaw,
> Claude Code. For Claude-Code-specific entry vocabulary (skills,
> subagents, hooks), also read `CLAUDE.md`.

## What this folder is

A build-ready **spec** for a 3-agent Property Management team. Generated
by AgentBloc (the architect). Your job (the builder) is to implement
the team described here. The folder is the contract; you decide HOW
to wire it up.

## Read order

1. `ROADMAP.md` — phased build plan with effort estimates
2. `workflows/<id>.md` — what each workflow does (one file per workflow)
3. `agents/<id>/` — CrewAI-shaped agent designs (one folder per agent)
4. `integrations/INVENTORY.md` — tier-ranked tools with evidence URLs
5. `governance/` — 5 safety contracts (blast-radius, audit, PII, kill-switch, approvals)
6. `runtime/BUILD.md` — tool-agnostic build plan
7. `runtime/reference-impl/` — bash + cron + Telegram substrate (advisory)
8. `runtime/alternatives.md` — when to pick n8n / Temporal / Pipedream / custom Python instead

## The team in one sentence

Three agents collect utility invoices, match bank payments across 4
Spanish banks via PSD2, and send per-owner Telegram summaries every
evening — replacing 2-3 hours/day of manual work for the operator.

## Topology

```
[gestor-documental] ──invoices.json──> [gestor-cobros] ──matches.json──> [recepcionista] ──> Telegram
       L2: write                           L2: write                          L4: send
       Sonnet                              Opus                               Sonnet
       full autonomy                       semi (approval gate)              semi (approval gate)
```

Mesh topology: `recepcionista` also queries `gestor-cobros` via
inter-agent message before composing reports (see
`workflows/02-payment-matching.md` and `agents/recepcionista/`).

## Tier-ranked tool inventory

8 tools across the team:

- 6 **EXISTS-MCP** — install + configure (~12 CC-hours total)
- 2 **NEEDS-MCP-WRAPPER** — synthesize via `mcp-builder` skill or
  equivalent codegen (~11 CC-hours total)

No n8n flows, no webhook receivers, no manual runbooks for this team.

## Governance contracts you must honor

These contracts are language- and runtime-agnostic. Implement them in
whatever stack you choose:

1. **Blast radius (L1-L4)** — `governance/blast-radius.md`
2. **Audit trail (12-field JSONL, append-only, PII-redacted)** — `governance/audit-trail.md`
3. **PII redaction (GDPR + Spain DNI/NIE)** — `governance/pii-redaction.md`
4. **Kill switch (3 independent triggers)** — `governance/kill-switch.md`
5. **Approval protocol (Telegram thread for L3+)** — `governance/approval-protocol.md`

## Build target

~16 CC-hours via the bash + cron reference impl in
`runtime/reference-impl/`. Pick a different runtime per
`runtime/alternatives.md` if your environment fits better.

## Provenance

Spec emitted by AgentBloc v3.0.0 on 2026-04-28. Inputs SHA256-pinned in
`SPEC-EMISSION-REPORT.md` for forensics + drift detection on
re-emission.
