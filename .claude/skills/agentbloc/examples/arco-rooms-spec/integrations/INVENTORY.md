# Tool Inventory — Arco Rooms

> Master tier-ranked matrix. Every tool the team's agents use appears
> exactly once with a tier assignment + evidence URL + effort estimate.

## Tier breakdown

| Tier | Count | Total effort (CC-hours) |
|---|---|---|
| EXISTS-MCP | 6 | 12 |
| NEEDS-MCP-WRAPPER | 2 | 11 |
| NEEDS-N8N-FLOW | 0 | 0 |
| NEEDS-WEBHOOK | 0 | 0 |
| MANUAL | 0 | n/a |

## Full inventory

| Tool | Tier | Used by | Effort (CC-h) | Evidence URL | Spec link |
|---|---|---|---|---|---|
| playwright-mcp | EXISTS-MCP | gestor-documental | 2 | https://github.com/microsoft/playwright-mcp | `existing/playwright-mcp.md` |
| google-workspace-mcp | EXISTS-MCP | gestor-documental | 2 | https://github.com/taylorwilsdon/google_workspace_mcp | `existing/google-workspace-mcp.md` |
| telegram-mcp | EXISTS-MCP | recepcionista | 2 | https://github.com/guangxiangdebizi/telegram-mcp | `existing/telegram-mcp.md` |
| gmail-mcp | EXISTS-MCP | gestor-documental | 2 | https://github.com/smithery-ai/gmail-mcp | `existing/gmail-mcp.md` |
| google-sheets-mcp | EXISTS-MCP | gestor-cobros | 2 | https://github.com/xing5/mcp-google-sheets | `existing/google-sheets-mcp.md` |
| notion-mcp | EXISTS-MCP | recepcionista (reserved) | 2 | https://github.com/community/notion-mcp | `existing/notion-mcp.md` |
| bank-mcp | NEEDS-MCP-WRAPPER | gestor-cobros | 6 | https://www.bbva.es/clientes/particulares/banca-electronica/api-de-datos.html | `needs-mcp-wrapper/bank-mcp/` |
| mapfre-api | NEEDS-MCP-WRAPPER | gestor-documental | 5 | https://www.mapfre.es/empresas/oficina-directa/api/ | `needs-mcp-wrapper/mapfre-api/` |

## Tier definitions

- **EXISTS-MCP** — public MCP server exists; install + auth instructions
  in `existing/<tool>.md`. Build effort: hours.
- **NEEDS-MCP-WRAPPER** — vendor API exists, no public MCP. Wrapper
  buildable via `mcp-builder` skill. Build effort: days. See
  `needs-mcp-wrapper/<tool>/BUILD.md`.
- **NEEDS-N8N-FLOW** — visual / branching / multi-service logic; n8n is
  the right tool. Stub flow JSON in `needs-n8n-flow/`. (None for this team.)
- **NEEDS-WEBHOOK** — vendor pushes events; receiver must be built and
  exposed. Spec in `needs-webhook/<tool>-receiver.md`. (None for this team.)
- **MANUAL** — no automation path appropriate. Runbook in
  `manual/<tool>.md`. (None for this team.)

## Build order (per ROADMAP.md)

1. **EXISTS-MCP first** (Phase 1 of ROADMAP, ~6 CC-hours): playwright-mcp,
   google-workspace-mcp, telegram-mcp, gmail-mcp, google-sheets-mcp,
   notion-mcp
2. **NEEDS-MCP-WRAPPER second** (Phase 2 of ROADMAP, ~11 CC-hours):
   bank-mcp (PSD2 across 4 banks) + mapfre-api can build in parallel

Tier 3 (n8n) and Tier 4 (webhook) are absent — this team is purely
poll-based. Tier 5 (manual) is absent — there are no irreducibly-human
steps in the current workflows.

## Cross-references

- Phase 3 protocol: `references/phase-3-integration.md`
- 5-tier decision tree: `references/inventory-protocol.md`
- Wrapper synthesis: `references/mcp-synthesis.md`
- ROADMAP.md (this team's phased build plan)
