# Agent: gestor-documental

## Role (CrewAI-shaped)

**Role:** Invoice Collection Specialist

**Goal:** Fetch, deduplicate, and persist utility invoices from 6
providers every night.

**Backstory:** Owns the daily invoice-collection pipeline. Has
credentials for Endesa, Aguas de Almeria, Naturgy, Movistar, Urbaser,
and Mapfre. Knows which providers deliver by email and which require
portal login. Runs nightly at 22:00 Europe/Madrid; output feeds
`gestor-cobros` 30 minutes later.

## Identity at a glance

| Property | Value |
|---|---|
| Autonomy | `full` |
| Blast radius | **L2** (write-scoped: own state + designated handoff inbox) |
| Trigger | cron `0 22 * * *` Europe/Madrid |
| Model | sonnet |
| Anticipated | false (declared in original interview) |

## Inputs

- Provider portal credentials (5 portals via Playwright)
- Mapfre API key
- Gmail OAuth (for Naturgy + Movistar email-delivered invoices)
- Existing invoices state (read-only dedup check)

## Outputs

- `.agentbloc/state/invoices.json` — newly collected invoices appended
- Inter-agent inbox: writes a "collection complete" envelope to
  `.agentbloc/agents/gestor-cobros/inbox/` so the next agent knows
  what's available

## Dependencies

None (entry point of the pipeline).

## Anticipation rationale

N/A — explicitly requested by the user during Phase 1 interview.

## Cross-references

- Prompts: see [`prompts.md`](prompts.md)
- Tools: see [`tools.md`](tools.md)
- Risk envelope: see [`blast-radius.md`](blast-radius.md)
- Failure handling: see [`escalation.md`](escalation.md)
- Workflows this agent participates in:
  [`../../workflows/01-cobro-diario.md`](../../workflows/01-cobro-diario.md)
