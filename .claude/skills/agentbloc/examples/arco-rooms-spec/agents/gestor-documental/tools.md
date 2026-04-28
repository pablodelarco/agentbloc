# Tools — gestor-documental

> Tools this agent uses, with cross-links to integrations and blast
> levels. Build session wires each tool from the corresponding
> `integrations/<tier>/<tool>` folder.

## Tool table

| Tool | Tier | Blast | Operations | Integration link |
|---|---|---|---|---|
| `playwright-mcp` | EXISTS-MCP | L2 | browser_navigate, browser_snapshot, browser_click, browser_type | `../../integrations/existing/playwright-mcp.md` |
| `google-workspace-mcp` | EXISTS-MCP | L1 (Gmail read) / L2 (Drive download) | gmail_list_messages, gmail_get_message, drive_download_file | `../../integrations/existing/google-workspace-mcp.md` |
| `mapfre-api` | NEEDS-MCP-WRAPPER | L2 | get_policy, list_claims | `../../integrations/needs-mcp-wrapper/mapfre-api/` |

## Per-tool invocation pattern

### playwright-mcp

Used for 5 utility portals: Endesa, Aguas de Almeria, Naturgy fallback,
Movistar fallback, Urbaser. Each portal has a dedicated playbook in
the agent's prose (per provider's login flow + invoice download path).

Operations the agent calls:
- `browser_navigate` — go to provider login URL — L1
- `browser_type` — credential input — L2 (writes to remote form, treated as L2)
- `browser_click` — submit + navigate to invoices — L2
- `browser_snapshot` — accessibility tree extract — L1
- Download via the snapshot link — L2 (writes to local fs)

Approval gating (full autonomy): NONE — the agent proceeds on all L2
operations. PostToolUse audit hook still logs every call.

### google-workspace-mcp

Used for Naturgy + Movistar email-delivered invoices.

Operations:
- `gmail_list_messages` — filter `from:facturas@*` — L1
- `gmail_get_message` — fetch message + attachment IDs — L1
- `drive_download_file` — download PDF attachment to local path — L2

Approval gating: NONE (full autonomy).

### mapfre-api

Used for Mapfre insurance policies + claims (replaces portal scraping).

Operations:
- `get_policy` — fetch policy details for a known policy_id — L2 (read+cache local)
- `list_claims` — list current claims — L2

Approval gating: NONE (full autonomy + L2 only).

## Excluded tools (least-privilege boundary)

- `telegram-mcp` — gestor-documental does NOT send notifications
  directly; recepcionista is the team's L4 send-external agent. If
  gestor-documental needs to escalate, it uses `escalation-router.sh`
  (which posts to escalations_thread_id, not the agent's general
  L4 surface)
- `bank-mcp` — invoice collection is read-only against utilities;
  bank data belongs to gestor-cobros
- Any DELETE / WRITE operation against the tenant registry — that's
  Pablo's manual purview

If a future requirement adds a need (e.g., archiving invoices to
Notion), AgentBloc Phase 6 (spec evolution) revisits this exclusion
list and updates blast-radius accordingly.

## Cross-references

- Inventory: [`../../integrations/INVENTORY.md`](../../integrations/INVENTORY.md)
- Blast-radius envelope: [`blast-radius.md`](blast-radius.md)
- Approval protocol: [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
