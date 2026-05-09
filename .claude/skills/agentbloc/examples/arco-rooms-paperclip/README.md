# Arco Rooms — Paperclip-shape Example

> Worked example for the v3.1 dual-emit design. The same inputs that produce `examples/arco-rooms-spec/` (portable shape) produce this folder when `target=paperclip-v1`.
>
> **Inputs (unchanged):**
> - `examples/arco-rooms-business-graph.json`
> - `examples/arco-rooms-agent-profiles.yaml`
> - `examples/arco-rooms-inventory.yaml`
>
> **Output (this folder):** `agentcompanies/v1` package importable via `npx companies.sh add ./arco-rooms-paperclip` in Paperclip.

## What's here

```
arco-rooms-paperclip/
├── COMPANY.md                                    # Company root entry (frontmatter + body)
├── .paperclip.yaml                               # Vendor extension: adapters + cron routines
├── README.md                                     # This file
├── agents/
│   ├── gestor-documental/AGENTS.md               # Invoice Collection Specialist
│   ├── gestor-cobros/AGENTS.md                   # Payment Reconciliation Engine
│   └── recepcionista/AGENTS.md                   # Daily Operations Reporter
├── skills/
│   ├── playwright-mcp/SKILL.md                   # tier=EXISTS-MCP (SHA-pinned source ref)
│   └── bank-mcp/SKILL.md                         # tier=NEEDS-MCP-WRAPPER (build instructions)
└── projects/
    └── cobro-diario/
        ├── PROJECT.md                            # Daily collection workflow
        └── tasks/
            └── 01-collect-invoices/TASK.md       # Recurring task example
```

The full emission would include 3 agents (already shown), 8 skills (2 shown for tier-coverage; 6 EXISTS-MCP + 2 NEEDS-MCP-WRAPPER total per inventory.yaml), and 2 projects (`cobro-diario` shown; `unmatched-payment-alert` would also be emitted as event-driven). This subset validates the template surface.

## Diff against the portable shape

For the same inputs, the portable shape at `examples/arco-rooms-spec/` is roughly **70 files** (5-file fan-out per agent, 5 governance files, runtime/reference-impl, INVENTORY.md, per-tier subfolders). The Paperclip shape is roughly **15 files** (1 file per agent, 1 file per skill, COMPANY.md + .paperclip.yaml).

The collapse happens because:
- Paperclip's `agents/<slug>/AGENTS.md` is one file with frontmatter + body, vs. the portable `role.md` + `prompts.md` + `tools.md` + `blast-radius.md` + `escalation.md` fan-out
- Paperclip is the runtime, so `runtime/reference-impl/` (12+ files) is suppressed
- Paperclip's governance is enforced at runtime via approval gates, so `governance/` (5 files) becomes inline `metadata.agentbloc.*` extensions on each AGENTS.md / SKILL.md

The portable shape's surface area carries more detail because it has to brief any AI coding tool with no shared runtime; Paperclip can share runtime with its package importers.

## Lossy items in this example

Per the design doc:
1. **Mesh topology**: All three agents have `reportsTo: null` because there's no hub. The peer-call relationships (recepcionista queries gestor-cobros, gestor-cobros depends on gestor-documental) live in narrative AGENTS.md sections + `metadata.agentbloc.topology: mesh` on COMPANY.md.
2. **Inter-agent trigger**: gestor-cobros has a `type=inter-agent` trigger from recepcionista (payment-status-query). This is documented in body narrative; Paperclip's runtime would route it via skill invocation.
3. **Readiness tiers**: 6 EXISTS-MCP + 2 NEEDS-MCP-WRAPPER tier classifications are preserved in `metadata.agentbloc.tier` on each SKILL.md. A sibling `.agentbloc/inventory.md` (not in this example folder; would be written next to the package at destination root) gives the build session a tier-sorted build order.

## Cross-references

- Design doc: [`docs/v3.1-paperclip-target.md`](../../../../docs/v3.1-paperclip-target.md)
- Portable shape (same inputs): [`examples/arco-rooms-spec/`](../arco-rooms-spec/)
- Inputs:
  - [`arco-rooms-business-graph.json`](../arco-rooms-business-graph.json)
  - [`arco-rooms-agent-profiles.yaml`](../arco-rooms-agent-profiles.yaml)
  - [`arco-rooms-inventory.yaml`](../arco-rooms-inventory.yaml)
- Paperclip spec: [paperclipai/paperclip docs/companies/companies-spec.md](https://github.com/paperclipai/paperclip/blob/master/docs/companies/companies-spec.md)
- Reference Paperclip company: [aeon-intelligence](https://github.com/paperclipai/companies/tree/main/aeon-intelligence)
