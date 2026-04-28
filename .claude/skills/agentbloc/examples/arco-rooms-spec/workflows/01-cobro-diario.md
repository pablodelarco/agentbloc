# Workflow: cobro-diario

> Daily invoice collection → payment matching → per-owner reporting.
> Sequential pipeline; each agent's output feeds the next.

## Trigger

| Type | Detail |
|---|---|
| `cron` | `0 22 * * *` Europe/Madrid |

## Inputs

| Name | Type | Source |
|---|---|---|
| Provider portal credentials | OAuth + form login | `.env` (Endesa, Aguas, Naturgy, Movistar, Urbaser) |
| Mapfre API key | api-key | `.env` `MAPFRE_API_KEY` |
| Gmail OAuth | refresh token | `.env` Google Workspace MCP |
| Bank PSD2 credentials | OAuth | `.env` `BBVA_PSD2_*` (one set per bank) |
| Tenant registry | Google Sheet | `google-sheets-mcp` |

## Outputs

| Name | Type | Sink |
|---|---|---|
| Collected invoices | JSON state file | `.agentbloc/state/invoices.json` |
| Match results with confidence scores | JSON state file | `.agentbloc/state/matches.json` |
| Per-owner Telegram summary | Telegram message | one thread per property owner |

## Agents involved

| Agent | Role |
|---|---|
| `gestor-documental` | Collects invoices from 6 providers (5 portals + 1 API + email scrape) |
| `gestor-cobros` | Matches bank transactions to invoices with regex + confidence scoring |
| `recepcionista` | Composes + sends per-owner Telegram daily summary |

## Success criteria (falsifiable)

- p95 end-to-end pipeline duration < 45 minutes (22:00 → 22:45)
- Invoice collection: ≥5 of 6 providers succeed (1 portal-down tolerance)
- Payment matching: ≥85% of bank transactions matched with confidence ≥ 0.7
- Owner reporting: each owner receives exactly 1 Telegram message by 23:15
- Zero duplicate invoices written (dedup by provider+date+amount)
- Zero PII in audit log (Spain DNI/NIE redaction passes)

## Failure modes

| Mode | Detection | Handling |
|---|---|---|
| Portal down (Endesa, Aguas, etc.) | Playwright timeout | Skip provider; retry next day; log to audit |
| Bank PSD2 token expired | 401 from bank-mcp | Escalate via `escalation-router.sh`; persistent halt until `/resume` |
| Telegram approval timeout (recepcionista L4) | No `/approve` within 600s | Escalate to `escalations_thread_id`; halt for next cron |
| Inter-agent inbox write fails | atomic_write_inbox returns non-zero | Retry 3x; escalate on persistent failure |
| Tenant registry sheet unreachable | Google Sheets MCP timeout | gestor-cobros falls back to last cached registry; flag stale |

## Topology

```
22:00 ─> [gestor-documental] ──invoices.json──> 22:30 [gestor-cobros] ──matches.json──> 23:00 [recepcionista] ──> Telegram (per-owner)
              L2: write                                L2: write                              L4: send
              full autonomy                            semi (approval)                        semi (approval)
              Sonnet                                   Opus                                   Sonnet
```

## Cross-references

- Agents: [`gestor-documental`](../agents/gestor-documental/role.md),
  [`gestor-cobros`](../agents/gestor-cobros/role.md),
  [`recepcionista`](../agents/recepcionista/role.md)
- Tools used: 6 EXISTS-MCP + 2 NEEDS-MCP-WRAPPER per
  [`../integrations/INVENTORY.md`](../integrations/INVENTORY.md)
- Governance: [blast-radius](../governance/blast-radius.md),
  [audit-trail](../governance/audit-trail.md),
  [approval-protocol](../governance/approval-protocol.md)
