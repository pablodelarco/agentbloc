# Freelance Pipeline -- Full Walkthrough

A solo freelance web designer managing their business pipeline manually across scattered tools. They track leads in a Google Sheet, write proposals in Google Docs, send invoices via Xero, and lose track of follow-ups. With 5-10 active clients at any time, missed follow-ups and late invoices are costing real revenue. The freelancer is a developer and wants to automate the full lead-to-payment lifecycle.

---

## Phase 1: Interview Summary

Key findings from the 9-category deep interview:

**The Problem.** The freelancer loses 3-5 hours per week on administrative pipeline tasks: updating lead status, copying proposal templates, creating invoices, and sending follow-up reminders. Two qualified leads were lost last quarter due to follow-ups that slipped through the cracks. Estimated revenue impact: EUR 4,000/quarter.

**The Current Workflow.** A new lead arrives via website contact form (Netlify form submission triggers an email notification). The freelancer manually adds the lead to a Google Sheet, qualifies them based on budget and project fit, creates a proposal in Google Docs from a template, sends it via email, follows up if no response within 3 days. On project completion, they create an invoice in Xero and track payment status manually.

**The Services and Tools.** Google Sheets (lead tracking, client registry), Google Docs (proposal templates), Gmail (all client communication), Xero (invoicing and payment tracking), Netlify (website hosting, form submissions), Telegram (personal notifications and reminders).

**The Data.** Lead records: name, email, company, project description, budget range, source. Proposal documents: scope, timeline, pricing, terms. Invoice records: amount, due date, payment status, line items. Email threads per client.

**Data Classification.** PII detected: client names, email addresses, company names, phone numbers. Financial data: invoice amounts, payment status, bank details in Xero. Jurisdiction: EU clients (majority), some US clients. GDPR activated for EU data subjects.

**The People.** Solo operator. No approval chain. The freelancer is both the decision-maker and the executor. Clients interact via email only; they never see the internal pipeline.

**Edge Cases and Failures.** Leads that go cold and revive months later. Proposals requiring multiple revision rounds. Partial payments on milestone-based projects. Xero API rate limits during month-end batch invoicing. Duplicate lead detection when the same person submits the contact form twice.

**Reporting and Communication.** Weekly pipeline summary via Telegram (new leads, proposals sent, invoices outstanding). Real-time Telegram alert when a payment is received. Monthly revenue report.

**Budget and Constraints.** Xero standard plan (API access included). Google Workspace business account. No additional hosting budget. Developer-level comfort with configuration and debugging.

---

## Phase 2: Agent Team Design

**Topology: Pipeline** -- a linear business lifecycle where each stage feeds the next.

| Agent | Role | Blast Radius | Model | Schedule |
|-------|------|-------------|-------|----------|
| Lead Capture Agent | Detect new form submissions, add to pipeline | L2: write-scoped | Sonnet | Every 30 min |
| Proposal Generator | Create proposals from templates for qualified leads | L2: write-scoped | Opus | Daily 09:00 |
| Invoice Manager | Create and track invoices in Xero | L3: write-unrestricted | Sonnet | Daily 10:00 |
| Follow-Up Agent | Send reminders for stale proposals and overdue invoices | L4: send-external | Sonnet | Daily 11:00 |

```
[Lead Capture] --> [Proposal Generator] --> [Invoice Manager] --> [Follow-Up Agent]
   L2:write           L2:write              L3:write             L4:send
   Sonnet             Opus                  Sonnet               Sonnet
```

Lead Capture runs frequently (every 30 min) to catch new form submissions promptly. Proposal Generator uses Opus because it needs to reason about project scope, select the right template sections, and customize pricing based on the lead's budget range and requirements. Invoice Manager is Level 3 because it creates invoices in Xero (external write). Follow-Up Agent is Level 4 because it sends emails to clients.

This pipeline differs from Arco Rooms in that it represents a business lifecycle (lead to revenue) rather than an operational cycle (collect, match, report). Each stage moves a client forward through the funnel.

---

## Phase 3: Integration Findings

### Lead Capture Agent Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Gmail (form notifications) | Google Workspace MCP (taylorwilsdon) | HIGH | Gmail API direct |
| Google Sheets (lead registry) | Google Sheets MCP (xing5/mcp-google-sheets) | HIGH | Google Workspace MCP |

### Proposal Generator Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Google Docs (templates) | Google Workspace MCP | HIGH | Google Docs API direct |
| Google Sheets (lead data) | Google Sheets MCP | HIGH | Google Workspace MCP |
| Gmail (send proposal) | Google Workspace MCP | HIGH | Gmail API direct |

### Invoice Manager Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Xero | Xero MCP (XeroAPI/xero-mcp-server, official) | HIGH | Xero API direct |
| Google Sheets (invoice log) | Google Sheets MCP | HIGH | Google Workspace MCP |

### Follow-Up Agent Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Gmail (send follow-ups) | Google Workspace MCP | HIGH | Gmail API direct |
| Telegram (notifications) | Telegram Bot API MCP (guangxiangdebizi) | HIGH | Telegram Bot API direct |
| Xero (payment status check) | Xero MCP (official) | HIGH | Xero API direct |

All integrations score HIGH trust. Xero MCP is the official vendor-maintained server. Google Workspace MCP has 800+ stars and active maintenance. Telegram MCP is well-established with modular architecture.

---

## Phase 4: Confirmed Agent Cards

### Lead Capture Agent

- **Actions:** Poll Gmail for new Netlify form submission notifications, extract lead data, check for duplicates, add to Google Sheets pipeline
- **Integrations:** Google Workspace MCP (Gmail read), Google Sheets MCP (write lead row)
- **Blast Radius:** Level 2 (write-scoped to `.agentbloc/state/leads.json` and Google Sheets)
- **Schedule:** Every 30 minutes (`*/30 * * * *`)
- **Failure handling:** Retry 3x on API timeout, skip duplicate leads, log errors
- **Prompt injection defense:** Layers 1, 2, 3 (ingests form submission content via email)

### Proposal Generator

- **Actions:** Read qualified leads from pipeline, select appropriate proposal template in Google Docs, customize scope/pricing/timeline, save draft for freelancer review
- **Integrations:** Google Workspace MCP (Docs read/write), Google Sheets MCP (read lead data)
- **Blast Radius:** Level 2 (write-scoped to Google Docs drafts and `.agentbloc/state/proposals.json`)
- **Schedule:** Daily at 09:00 local time
- **Failure handling:** Skip leads with incomplete data, alert via Telegram, retry template fetch 3x
- **Prompt injection defense:** Layers 1, 2, 3 (processes client project descriptions)

### Invoice Manager

- **Actions:** Check for completed projects ready for invoicing, create invoice in Xero with correct line items, track payment status, update pipeline
- **Integrations:** Xero MCP (create/read invoices), Google Sheets MCP (update invoice log)
- **Blast Radius:** Level 3 (write-unrestricted in Xero, requires approval)
- **Schedule:** Daily at 10:00 local time
- **Failure handling:** Never auto-create invoice without confirmation, queue for review on any amount discrepancy
- **Prompt injection defense:** None (no external content ingestion, reads from internal state only)

### Follow-Up Agent

- **Actions:** Check proposal response status (no reply after 3 days), check overdue invoices in Xero, send follow-up emails to clients, notify freelancer via Telegram
- **Integrations:** Google Workspace MCP (send emails), Xero MCP (read payment status), Telegram MCP (notifications)
- **Blast Radius:** Level 4 (send-external, requires approval)
- **Schedule:** Daily at 11:00 local time
- **Failure handling:** Retry 3x on email delivery failure, never send duplicate follow-ups (state tracking)
- **Prompt injection defense:** None (sends outbound only, does not ingest external content)

### Dry Run Result

Dry run processed 3 sample leads through the full pipeline. 2 reached the proposal stage (templates selected and drafts prepared). 1 was auto-qualified for fast-track based on budget match and returning client status. An invoice draft was created for a recently completed project but not sent to Xero. Follow-up emails were drafted for 1 stale proposal and 1 overdue invoice but not sent. All writes and sends were stubbed and logged.

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
    lead-capture.yaml
    lead-capture.skill.md
    proposal-generator.yaml
    proposal-generator.skill.md
    invoice-manager.yaml
    invoice-manager.skill.md
    follow-up-agent.yaml
    follow-up-agent.skill.md
  state/
    leads.json
    proposals.json
    invoices.json
    follow-ups.json
    cost-tracker.json
  jobs/
    pipeline-run.md
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
name: freelance-pipeline
display_name: "Freelance Business Pipeline"
topology: pipeline
timezone: Europe/Madrid
agents:
  - name: lead-capture
    config: agents/lead-capture.yaml
    skill: agents/lead-capture.skill.md
  - name: proposal-generator
    config: agents/proposal-generator.yaml
    skill: agents/proposal-generator.skill.md
  - name: invoice-manager
    config: agents/invoice-manager.yaml
    skill: agents/invoice-manager.skill.md
  - name: follow-up-agent
    config: agents/follow-up-agent.yaml
    skill: agents/follow-up-agent.skill.md
schedule:
  type: cron
  expression: "*/30 * * * *"
```

Credentials stored in `.env` (gitignored). Invoice Manager requires approval via Telegram before creating invoices in Xero. Follow-Up Agent requires approval before sending client-facing emails. Audit logging with GDPR-compliant PII redaction for EU client data.

---

## Phase 6: Evolution Notes

The weekly evolution scan checks:

- **Xero API updates:** Version deprecations, new invoice/payment endpoints, webhook format changes
- **Google Workspace MCP updates:** New capabilities for Docs, Sheets, and Gmail that could simplify proposal generation or lead capture
- **New MCP servers:** PulseMCP directory for CRM-specific servers (HubSpot, Pipedrive) that could replace the Google Sheets-based lead tracking
- **Client volume patterns:** If lead volume exceeds 20/week, recommend upgrading Lead Capture polling frequency or adding a dedicated qualification agent
- **Template drift:** Proposal templates may need updates as service offerings change; scan for stale templates

**Example patch proposal:**

```
Title: Xero MCP server update to xero-mcp@1.0.0 (stable release)
Priority: P3 MEDIUM
What Changed: Official Xero MCP moves from beta to stable with improved invoice creation endpoints
Affected Agents: Invoice Manager, Follow-Up Agent (payment status reads)
Recommended Action: Update from xero-mcp@beta to xero-mcp@1.0.0
Rollback Plan: Pin xero-mcp@beta in agent configs and reinstall
```

All proposals require explicit human approval via Telegram before any changes are applied. No auto-patching.
