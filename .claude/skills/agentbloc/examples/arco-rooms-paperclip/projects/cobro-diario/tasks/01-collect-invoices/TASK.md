---
name: Collect Invoices
slug: collect-invoices
schema: agentcompanies/v1
assignee: gestor-documental
project: cobro-diario
recurring: true
metadata:
  agentbloc:
    step_index: 1
    workflow_type: sequential
    output_artifact: ".agentbloc/state/invoices.json"
    output_schema_ref: ".agentbloc/state/invoices.schema.json"
---

# Collect Invoices

First step of the `cobro-diario` pipeline. Run by [gestor-documental](../../../../agents/gestor-documental/AGENTS.md) every night at 22:00 Europe/Madrid.

## What happens in this task

1. Log into 5 utility provider portals (Endesa, Aguas de Almería, Naturgy, Movistar, Urbaser) via `playwright-mcp` using cookie-persisted sessions
2. For each portal: navigate to the invoices page, list new invoices since the last successful run, download each as PDF
3. Read the Mapfre API for any new policy invoices (api-key auth)
4. Scrape Gmail for invoice emails from providers that don't expose portals (`google-workspace-mcp` + `gmail-mcp`)
5. Deduplicate collected invoices against the existing `.agentbloc/state/invoices.json` by fingerprint hash `(provider, period, amount)`
6. Atomically write newly collected invoices to `.agentbloc/state/invoices.json` (temp + rename)
7. Emit a per-run summary line to the audit log: invoices collected per provider, providers that failed, run duration

## Inputs

- `.agentbloc/state/invoices.json` (existing, for dedup)
- 5 provider portals + Mapfre API + Gmail
- Playwright cookie cache at `~/.cache/playwright-mcp/`

## Outputs

- Updated `.agentbloc/state/invoices.json` with new entries appended (atomic)
- Raw PDFs in `.agentbloc/state/raw-invoices/<provider>/<YYYY-MM>/`
- Audit log line at `.agentbloc/audit/<YYYY-MM-DD>.jsonl` per the team audit-trail schema

## Falsifiable success criteria

- At least 5 of 6 providers complete successfully (1-portal-down tolerance)
- Zero duplicate entries written to `invoices.json` (assertion: post-run, sort + uniq on fingerprint hash equals total entry count)
- All new entries carry a non-null `due_date` and `amount`
- Run completes in under 25 minutes (median); under 45 minutes (p95)

## Failure modes

| Mode | Detection | Handling |
|---|---|---|
| Provider portal down | Playwright navigation timeout > 60s | Skip provider, log warning, continue to next |
| Cookie expired | Provider login flow hits unexpected 2FA prompt | Send Telegram alert "X cookies expired, please re-auth"; skip provider |
| Mapfre API key invalid | 401 from `mapfre-api` | Send Telegram alert; skip Mapfre; continue |
| Gmail OAuth refresh fails | `google-workspace-mcp` returns auth error | Send Telegram alert; skip Gmail; continue |
| State file write fails | atomic write returns non-zero | Halt; set last-run.json status=error; do NOT retry the same wake (file system issue, not transient) |

## Provider sub-step rules

The portal fallback rule applies here: if a provider portal is unreachable for 3 consecutive days, gestor-documental falls back to Gmail scraping for that provider (when the provider also delivers by email) AND sends a Telegram alert to Pablo. The 3-day counter resets on a successful portal run.

## Cross-references

- Agent: [`../../../../agents/gestor-documental/AGENTS.md`](../../../../agents/gestor-documental/AGENTS.md)
- Skills used: [playwright-mcp](../../../../skills/playwright-mcp/SKILL.md), google-workspace-mcp, gmail-mcp, mapfre-api (last is NEEDS-MCP-WRAPPER)
- Project: [`../../PROJECT.md`](../../PROJECT.md)
- Operating rules (portal fallback): [`../../../../COMPANY.md`](../../../../COMPANY.md)
