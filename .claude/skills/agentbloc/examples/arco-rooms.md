# Arco Rooms -- Full Walkthrough

A property management company in Almeria, Spain managing ~30 rental properties across multiple owners. They collect utility invoices from 6 providers, match bank payments from 7 accounts across 4 banks, and report to property owners via Telegram. The owner is non-technical and wants to automate the daily invoice collection and payment matching workflow.

---

## Phase 1: Interview Summary

Key findings from the 9-category deep interview:

**The Problem.** The owner spends 2-3 hours daily collecting invoices from utility provider portals, cross-referencing bank transactions, and messaging property owners. Missed invoices and late payment detection cost roughly EUR 500/month in penalties and tenant disputes.

**The Current Workflow.** Every evening: log into 6 utility provider portals, download new invoices, open 4 banking apps to check 7 accounts, manually match payments to invoices in a Google Sheet, message owners via Telegram with updates. Entirely manual, error-prone, and tedious.

**The Services and Tools.** Google Sheets (master tenant registry, property details), 6 utility providers (Endesa, Aguas de Almeria, Naturgy, Movistar, Urbaser, Mapfre), 4 banks via online portals, Gmail (some providers send invoice emails), Telegram (owner communication).

**The Data.** Invoice PDFs and HTML tables from provider portals. Bank transaction CSVs and API responses. Tenant registry in Google Sheets with names, contract numbers, property addresses, start/end dates.

**Data Classification.** PII detected: tenant names, addresses, bank account references, contract numbers. Financial data: invoice amounts, payment amounts, bank transaction details. Jurisdiction: Spain (EU). GDPR activated automatically.

**The People.** Single operator (the owner). Property owners receive reports via Telegram but do not interact with the system. No approval chain needed for read/collect operations; owner reviews unmatched items.

**Edge Cases and Failures.** Provider portals go down (especially legacy ones). New tenants appear with unknown contract numbers. Bank transaction descriptions vary between banks. Duplicate invoice detection needed when both email and portal deliver the same invoice.

**Reporting and Communication.** Daily summary to the owner via Telegram. Per-property-owner monthly reports. Silence by default: only notify on new invoices, confirmed payments, unmatched items, and errors.

**Budget and Constraints.** Minimal budget. Free-tier integrations preferred. No deadline pressure but wants it running within a week. Must comply with GDPR given EU tenant data.

---

## Phase 2: Agent Team Design

**Topology: Pipeline** -- three sequential stages where each agent's output feeds the next.

| Agent | Role | Blast Radius | Model | Schedule |
|-------|------|-------------|-------|----------|
| Invoice Collector | Fetch invoices from 6 utility providers | L2: write-scoped | Sonnet | Daily 22:00 |
| Payment Matcher | Match bank transactions to invoices and tenants | L2: write-scoped | Opus | Daily 22:30 |
| Report Sender | Send summaries and alerts via Telegram | L4: send-external | Sonnet | Daily 23:00 |

```
[Invoice Collector] --> [Payment Matcher] --> [Report Sender]
     L2:write              L2:write             L4:send
     Sonnet                Opus                 Sonnet
```

The Invoice Collector reads from provider portals and emails, writing collected invoices to a local state file. The Payment Matcher reads bank transactions via PSD2 APIs and matches them against invoices using regex patterns with confidence thresholds. The Report Sender consolidates results and delivers via Telegram, requiring human approval for external sends.

Opus is assigned to Payment Matcher because fuzzy matching across variable bank transaction descriptions requires complex reasoning. The other agents handle structured extraction and message formatting, suitable for Sonnet.

---

## Phase 3: Integration Findings

### Invoice Collector Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Endesa | Playwright browser automation | HIGH (Microsoft) | Manual notification |
| Aguas de Almeria | Playwright browser automation | HIGH (Microsoft) | Manual notification |
| Naturgy | Gmail scraping (Google Workspace MCP) | HIGH | Playwright |
| Movistar | Gmail scraping (Google Workspace MCP) | HIGH | Playwright |
| Mapfre | Official API | HIGH | Gmail scraping |
| Urbaser | Playwright browser automation | HIGH (Microsoft) | Manual notification |
| Google Sheets | Google Sheets MCP (xing5/mcp-google-sheets) | HIGH | Google Workspace MCP |

### Payment Matcher Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Bank accounts (x4) | PSD2/Enable Banking via bank-mcp (elcukro/bank-mcp) | HIGH | Playwright per bank |

### Report Sender Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Telegram | Telegram Bot API MCP (guangxiangdebizi/telegram-mcp) | HIGH | Manual notification |

Trust scores follow the 3-tier system: HIGH for official vendor-maintained or >500 stars with active maintenance, MEDIUM for 100-500 stars community projects, LOW for unmaintained or undocumented projects.

---

## Phase 4: Confirmed Agent Cards

### Invoice Collector

- **Actions:** Fetch invoices from 6 providers (API, email, browser), deduplicate, write to state file
- **Integrations:** Playwright MCP, Google Workspace MCP, Google Sheets MCP, Mapfre API
- **Blast Radius:** Level 2 (write-scoped to `.agentbloc/state/invoices.json`)
- **Schedule:** Daily at 22:00 Europe/Madrid
- **Failure handling:** Retry 3x per provider, skip on persistent failure, alert via Telegram
- **Prompt injection defense:** Layers 1, 2, 3 (ingests emails and web pages)

### Payment Matcher

- **Actions:** Read bank transactions, load invoices from state, match by regex with confidence scoring, flag low-confidence and unmatched items
- **Integrations:** bank-mcp (PSD2), Google Sheets MCP (tenant registry)
- **Blast Radius:** Level 2 (write-scoped to `.agentbloc/state/matches.json`)
- **Schedule:** Daily at 22:30 Europe/Madrid
- **Failure handling:** Retry 3x per bank, skip failed banks, continue with available data
- **Prompt injection defense:** Layers 1, 2, 3 (ingests bank API responses)

### Report Sender

- **Actions:** Read match results, compose daily summary, send to owner via Telegram, send per-owner monthly reports
- **Integrations:** Telegram Bot API MCP
- **Blast Radius:** Level 4 (send-external, requires approval)
- **Schedule:** Daily at 23:00 Europe/Madrid
- **Failure handling:** Retry 3x for Telegram delivery, log failures to audit trail
- **Prompt injection defense:** None (no external content ingestion)

### Dry Run Result

Dry run processed 5 invoices from 3 providers and 12 bank transactions. 4 matched automatically with high confidence. 1 flagged for review (low-confidence match on a new tenant). No side effects executed. All writes and sends were stubbed and logged.

---

## Phase 5: Deployment Artifacts

Generated `.agentbloc/` directory structure:

```
.agentbloc/
  team.yaml
  governance.yaml
  telegram.yaml
  SUMMARY.md
  incident-response.md
  .env.example
  agents/
    invoice-collector.yaml
    invoice-collector.skill.md
    payment-matcher.yaml
    payment-matcher.skill.md
    report-sender.yaml
    report-sender.skill.md
  state/
    invoice-collector.json
    payment-matcher.json
    report-sender.json
    cost-tracker.json
  jobs/
    daily-pipeline.md
    evolution-scan.md
  logs/
    audit.jsonl
  hooks/
    kill-switch-enforcer.sh
    dry-run-enforcer.sh
    output-monitor.js
```

**team.yaml excerpt:**

```yaml
name: arco-rooms
display_name: "Arco Rooms Property Management"
topology: pipeline
timezone: Europe/Madrid
agents:
  - name: invoice-collector
    config: agents/invoice-collector.yaml
    skill: agents/invoice-collector.skill.md
  - name: payment-matcher
    config: agents/payment-matcher.yaml
    skill: agents/payment-matcher.skill.md
  - name: report-sender
    config: agents/report-sender.yaml
    skill: agents/report-sender.skill.md
schedule:
  type: cron
  expression: "0 22 * * *"
```

Credentials are stored in `.env` (gitignored) with `.env.example` providing the schema. Audit logging in JSONL format with PII redaction and correlation IDs. Kill switch at `.agentbloc/KILL_SWITCH`.

---

## Phase 6: Evolution Notes

The weekly evolution scan checks:

- **MCP server updates:** New versions of bank-mcp, Google Workspace MCP, Playwright MCP, Telegram MCP
- **New MCP servers:** PulseMCP directory for better alternatives to current integrations (e.g., official bank APIs replacing PSD2 aggregators)
- **Security vulnerabilities:** GitHub Advisory Database for CVEs against npm packages used by MCP servers
- **Regulation changes:** PSD2 compliance updates, GDPR enforcement actions affecting data handling patterns
- **Playwright selectors:** Legacy provider portals may change their HTML structure, breaking browser automation

**Example patch proposal:**

```
Title: Update bank-mcp to v0.5.0
Priority: P3 MEDIUM
What Changed: bank-mcp 0.5.0 adds support for 2 additional Spanish banks
Affected Agents: Payment Matcher
Recommended Action: Update dependency version
Rollback Plan: Revert to bank-mcp 0.4.x in payment-matcher.yaml
```

All proposals require explicit human approval via Telegram before any changes are applied. No auto-patching.
