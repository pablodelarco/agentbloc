---
name: Cobro Diario
description: Nightly invoice collection, payment matching, and per-owner reporting pipeline
slug: cobro-diario
schema: agentcompanies/v1
owner: gestor-documental
metadata:
  agentbloc:
    workflow_type: sequential
    pattern_rationale: "Each agent's output feeds the next: invoices.json -> matches.json -> Telegram"
    success_criteria:
      - "p95 end-to-end pipeline duration < 45 minutes (22:00 to 22:45)"
      - "Invoice collection: at least 5 of 6 providers succeed (1 portal-down tolerance)"
      - "Payment matching: at least 85% of bank transactions matched with confidence >= 0.7"
      - "Owner reporting: each owner receives exactly 1 Telegram message by 23:15"
      - "Zero duplicate invoices written (dedup by provider+date+amount)"
      - "Zero PII in audit log (Spain DNI/NIE redaction passes)"
---

# Cobro Diario (Daily Collection)

Sequential nightly pipeline. Three agents run on staggered cron schedules, each handing off via state file or inter-agent message to the next.

```
22:00  gestor-documental   collects invoices       writes invoices.json
22:30  gestor-cobros       matches transactions    writes matches.json (reads invoices.json)
23:00  recepcionista       composes + sends        Telegram per-owner threads (reads matches.json)
```

## Why this pattern

Sequential, not parallel. Each step's output is the next step's input. Parallel would require shared coordination on what counts as "today's invoices" and create race conditions on the state file.

Loop is also wrong here: this is once-per-day, not "until done." The cron handles cadence.

Event-driven applies to the sibling project `unmatched-payment-alert`, which wakes recepcionista when gestor-cobros detects 3+ unmatched payments. That project is separate; this one is the steady-state nightly run.

## Trigger

Cron `0 22 * * *` Europe/Madrid (defined in `.paperclip.yaml` `routines.cobro-diario`). The trigger fires gestor-documental's wake; gestor-cobros and recepcionista wake on their own staggered crons (22:30 and 23:00) but the pipeline conceptually starts here.

## Agents

| Agent | Role | Wake | Output |
|---|---|---|---|
| [gestor-documental](../../agents/gestor-documental/AGENTS.md) | Invoice Collection Specialist | 22:00 | `.agentbloc/state/invoices.json` |
| [gestor-cobros](../../agents/gestor-cobros/AGENTS.md) | Payment Reconciliation Engine | 22:30 | `.agentbloc/state/matches.json` |
| [recepcionista](../../agents/recepcionista/AGENTS.md) | Daily Operations Reporter | 23:00 | Telegram messages per owner |

## Inputs

| Name | Type | Source |
|---|---|---|
| Provider portal credentials | OAuth + form login | `.env` (Endesa, Aguas, Naturgy, Movistar, Urbaser) |
| Mapfre API key | api-key | `.env` `MAPFRE_API_KEY` |
| Gmail OAuth | refresh token | `.env` Google Workspace MCP |
| Bank PSD2 credentials | OAuth | `.env` `BBVA_PSD2_*`, `SANTANDER_PSD2_*`, etc. (one set per bank) |
| Tenant registry | Google Sheet | `google-sheets-mcp` |

## Outputs

| Name | Type | Sink |
|---|---|---|
| Collected invoices | JSON state file | `.agentbloc/state/invoices.json` |
| Match results with confidence scores | JSON state file | `.agentbloc/state/matches.json` |
| Per-owner Telegram summary | Telegram message | one thread per property owner |
| Pablo's daily self-summary | Telegram message | briefing thread |

## Tasks

The project decomposes into three tasks, one per pipeline step. See:

- [`tasks/01-collect-invoices/TASK.md`](tasks/01-collect-invoices/TASK.md) (the example included in this fixture)
- `tasks/02-match-payments/TASK.md` (full emission would include this)
- `tasks/03-send-owner-reports/TASK.md` (full emission would include this)

Each task is recurring (`recurring: true`) and inherits the project's cron trigger.

## Failure modes

| Mode | Detection | Handling |
|---|---|---|
| Portal down (Endesa, Aguas, etc.) | Playwright timeout | Skip provider; retry next day; log to audit |
| Bank PSD2 token expired | 401 from bank-mcp | Escalate; halt next cron until `/resume` from Pablo |
| Telegram approval timeout | No `/approve` within 600s | Tier 1/2/3 ladder; escalate at 1800s |
| Inter-agent inbox write fails | atomic_write_inbox returns non-zero | Retry 3x; escalate on persistent failure |
| Tenant registry sheet unreachable | Google Sheets MCP timeout | gestor-cobros falls back to last cached registry; flag stale |

## Success criteria (falsifiable)

Listed in frontmatter under `metadata.agentbloc.success_criteria`. Each criterion is testable. Implement them as integration tests against your runtime of choice.

## Cross-references

- Operating rules: [`../../COMPANY.md`](../../COMPANY.md) "Operating rules" section
- Sibling project (event-driven): `../unmatched-payment-alert/PROJECT.md` (not in this example subset)
