# E-Commerce Support -- Full Walkthrough

A mid-size Shopify-based e-commerce store receiving 50-100 support tickets daily. Three support staff are overwhelmed by repetitive order tracking inquiries, simple refund requests, and escalation routing. The store owner (technical-basics level) wants to automate the first-response layer so the human team focuses on complex cases only.

---

## Phase 1: Interview Summary

Key findings from the 9-category deep interview:

**The Problem.** Support staff spend 70% of their time on repetitive tickets: "where is my order?" and "I want a refund for item X." Response times average 8 hours. Customer satisfaction scores are dropping. The owner estimates this costs EUR 3,000/month in lost repeat purchases and refund processing delays.

**The Current Workflow.** Tickets arrive via email (forwarded to a shared inbox) and Shopify inbox. A support agent reads the ticket, looks up the order in Shopify admin, checks shipping status, drafts a response, and sends it. For refunds under EUR 50, the agent processes directly in Stripe. For refunds over EUR 50 or complex complaints, the agent escalates to the store owner via Slack.

**The Services and Tools.** Shopify (order management, customer data), Stripe (payment processing, refunds), Gmail (customer communication), Slack (internal escalation), Google Sheets (refund tracking log).

**The Data.** Order records (Shopify), payment records (Stripe), customer emails (Gmail), shipping tracking numbers (Shopify fulfillments), refund amounts and reasons (Stripe + Google Sheets).

**Data Classification.** PII detected: customer names, email addresses, shipping addresses, phone numbers. Financial data: payment amounts, refund amounts, last 4 digits of payment method. Jurisdiction: EU customers (majority). GDPR activated.

**The People.** Store owner (approves large refunds, handles escalations), 3 support staff (currently handle everything, will handle escalated cases only), customers (receive responses via email).

**Edge Cases and Failures.** Partial refunds when only some items returned. Orders with multiple shipments at different stages. Customers replying to automated responses expecting a human. Stripe API rate limits during sale events. Duplicate tickets from the same customer about the same order.

**Reporting and Communication.** Daily ticket summary to store owner via Slack. Weekly refund report in Google Sheets. Real-time Slack alerts for escalated tickets.

**Budget and Constraints.** Shopify Plus plan (API access included). Stripe standard account. Budget for MCP server hosting is minimal. Go-live target: 2 weeks. Must maintain GDPR compliance for EU customer data.

---

## Phase 2: Agent Team Design

**Topology: Hierarchy** -- a coordinator routes incoming tickets to specialist agents and collects results.

| Agent | Role | Blast Radius | Model | Trigger |
|-------|------|-------------|-------|---------|
| Support Coordinator | Classify tickets and route to specialists | L1: read-only | Sonnet | Event (new ticket) |
| Order Tracker | Look up order and shipping status, draft response | L2: write-scoped | Sonnet | Routed by Coordinator |
| Refund Processor | Evaluate refund eligibility, process or escalate | L3: write-unrestricted | Opus | Routed by Coordinator |
| Escalation Handler | Route complex cases to human team via Slack | L4: send-external | Sonnet | Routed by Coordinator |

```
              [Support Coordinator]
                   L1:read
                 /     |     \
  [Order Tracker] [Refund Processor] [Escalation Handler]
     L2:write        L3:write           L4:send
     Sonnet          Opus               Sonnet
```

The Support Coordinator reads incoming tickets (read-only) and classifies them into three categories: order status inquiry, refund request, or complex/escalation. It routes each ticket to the appropriate specialist. This keeps the coordinator at Level 1 with no write or send capabilities.

The Refund Processor uses Opus because refund eligibility requires reasoning about return policies, partial refund calculations, and edge cases like multi-item orders. It requires approval for refunds (Level 3). The Escalation Handler is Level 4 because it sends messages to the human team via Slack.

---

## Phase 3: Integration Findings

### Support Coordinator Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Shopify | Shopify MCP (community, 600+ stars) | HIGH | Shopify Admin API direct |
| Gmail | Google Workspace MCP (taylorwilsdon) | HIGH | Gmail API direct |

### Order Tracker Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Shopify | Shopify MCP | HIGH | Shopify Admin API |
| Gmail (send response) | Google Workspace MCP | HIGH | Gmail API |

### Refund Processor Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Stripe | Stripe MCP (community, 500+ stars) | HIGH | Stripe API direct |
| Shopify | Shopify MCP | HIGH | Shopify Admin API |
| Google Sheets (refund log) | Google Sheets MCP (xing5) | HIGH | Google Workspace MCP |

### Escalation Handler Integrations

| Service | Method | Trust | Fallback |
|---------|--------|-------|----------|
| Slack | Slack MCP Plugin (slackapi, official) | HIGH | Slack API direct |

All recommended integrations score HIGH trust. The Shopify and Stripe MCP servers are community-maintained with >500 stars and active commits. Slack MCP Plugin is officially maintained by Slack.

---

## Phase 4: Confirmed Agent Cards

### Support Coordinator

- **Actions:** Read new tickets from Shopify inbox and Gmail, classify by type (order-status, refund, escalation), route to appropriate specialist agent
- **Integrations:** Shopify MCP (read-only), Google Workspace MCP (read-only)
- **Blast Radius:** Level 1 (read-only)
- **Trigger:** Event-driven (new ticket arrival, polled every 5 minutes)
- **Failure handling:** Retry 3x on API timeout, default to escalation if classification fails
- **Prompt injection defense:** Layers 1, 2, 3 (ingests customer email content)

### Order Tracker

- **Actions:** Look up order in Shopify, check fulfillment/shipping status, draft response email, write to state
- **Integrations:** Shopify MCP (read orders, fulfillments), Google Workspace MCP (send email)
- **Blast Radius:** Level 2 (write-scoped to `.agentbloc/state/order-tracker.json`)
- **Trigger:** Routed by Support Coordinator
- **Failure handling:** Retry 3x on Shopify API timeout, escalate if order not found
- **Prompt injection defense:** Layers 1, 2, 3 (ingests customer messages)

### Refund Processor

- **Actions:** Check refund eligibility against store policy, calculate refund amount, process via Stripe (under EUR 50) or queue for owner approval (over EUR 50), log to Google Sheets
- **Integrations:** Stripe MCP (create refund), Shopify MCP (read order details), Google Sheets MCP (write refund log)
- **Blast Radius:** Level 3 (write-unrestricted, requires approval)
- **Trigger:** Routed by Support Coordinator
- **Failure handling:** Never auto-process without confirmation, queue for human review on any ambiguity
- **Prompt injection defense:** All 4 layers + validation LLM call (ingests emails, Level 3 blast radius)

### Escalation Handler

- **Actions:** Format escalation summary, send to support team Slack channel with ticket context, notify store owner for high-priority cases
- **Integrations:** Slack MCP Plugin (send messages)
- **Blast Radius:** Level 4 (send-external, requires approval)
- **Trigger:** Routed by Support Coordinator
- **Failure handling:** Retry 3x on Slack API failure, fall back to email notification
- **Prompt injection defense:** None (does not ingest external content directly)

### Dry Run Result

Dry run processed 10 sample tickets from the last 24 hours. 6 classified as order-status inquiries (Order Tracker drafted responses). 3 classified as refund-eligible (Refund Processor evaluated: 2 under EUR 50, 1 over EUR 50 queued for approval). 1 classified as complex (Escalation Handler formatted summary). All refund operations and Slack sends were stubbed. No side effects executed.

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
    support-coordinator.yaml
    support-coordinator.skill.md
    order-tracker.yaml
    order-tracker.skill.md
    refund-processor.yaml
    refund-processor.skill.md
    escalation-handler.yaml
    escalation-handler.skill.md
  state/
    support-coordinator.json
    order-tracker.json
    refund-processor.json
    escalation-handler.json
    cost-tracker.json
  jobs/
    ticket-pipeline.md
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
name: ecommerce-support
display_name: "E-Commerce Support Automation"
topology: hierarchy
timezone: Europe/Berlin
agents:
  - name: support-coordinator
    role: router
    config: agents/support-coordinator.yaml
    skill: agents/support-coordinator.skill.md
  - name: order-tracker
    role: worker
    config: agents/order-tracker.yaml
    skill: agents/order-tracker.skill.md
  - name: refund-processor
    role: worker
    config: agents/refund-processor.yaml
    skill: agents/refund-processor.skill.md
  - name: escalation-handler
    role: worker
    config: agents/escalation-handler.yaml
    skill: agents/escalation-handler.skill.md
schedule:
  type: event
  poll_interval: "*/5 * * * *"
```

Credentials stored in `.env` (gitignored). Refund Processor requires approval via Telegram before executing any Stripe refund. Audit logging tracks every ticket classification, refund decision, and escalation with correlation IDs.

---

## Phase 6: Evolution Notes

The weekly evolution scan checks:

- **Shopify API versions:** Shopify deprecates API versions quarterly; scan for upcoming deprecations affecting order/fulfillment endpoints
- **Stripe webhook changes:** New event types or payload format changes that affect refund processing
- **MCP server updates:** New versions of Shopify MCP, Stripe MCP, Slack MCP Plugin, Google Workspace MCP
- **Support volume patterns:** If ticket volume exceeds 200/day, recommend scaling the polling interval or adding parallel coordinator instances
- **New integrations:** PulseMCP for dedicated customer support MCP servers that could replace the custom classification logic

**Example patch proposal:**

```
Title: Update Shopify MCP to v2.1.0
Priority: P3 MEDIUM
What Changed: Shopify MCP 2.1.0 adds fulfillment tracking event support
Affected Agents: Support Coordinator, Order Tracker
Recommended Action: Update dependency version
Rollback Plan: Revert to Shopify MCP 2.0.x in agent configs
```

All proposals require explicit human approval via Telegram before any changes are applied. No auto-patching.
