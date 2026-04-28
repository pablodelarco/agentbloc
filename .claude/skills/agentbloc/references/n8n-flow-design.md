# n8n Flow Design

> Loaded by SKILL.md during Phase 3 when a tool is assigned tier
> `NEEDS-N8N-FLOW`. Defines when n8n wins over a code-based path,
> what the spec folder must contain, and the stub-flow generation
> protocol.

## Table of Contents

- [When n8n Wins](#when-n8n-wins)
- [What the Spec Folder Must Contain](#what-the-spec-folder-must-contain)
- [Stub Flow JSON Generation](#stub-flow-json-generation)
- [Activation Steps in `BUILD.md`](#activation-steps-in-buildmd)
- [Cross-References](#cross-references)

## When n8n Wins

n8n is the right tier when ANY of these hold:

| Signal | Why n8n |
|---|---|
| **Multi-service composition** | Workflow chains 3+ services; visual flow is clearer than code |
| **Branching logic** | Conditional routing based on data shape; if/else nodes are first-class |
| **Polling triggers** | n8n's Schedule + Webhook nodes are mature; less boilerplate than custom cron |
| **User self-edits visually** | Non-technical operator wants to tune routing without re-running AgentBloc |
| **Many vendors, no MCP for any** | n8n has 600+ pre-built integrations; cheaper than 5 separate MCP wrappers |
| **Heavy data transformation** | Visual JSON-mapping nodes ergonomic for non-developers |

Code (NEEDS-MCP-WRAPPER) wins when:
- Tight coupling to agent prose (the wrapper is called inline by agent reasoning)
- Custom business logic per request that doesn't compose visually
- Performance-sensitive (p99 latency budget < 500ms)
- Single-vendor with a clean API and good MCP candidates

When in doubt, prefer n8n if the user's team will own the flow long-term;
prefer code if the agent owns the integration.

## What the Spec Folder Must Contain

For each `NEEDS-N8N-FLOW` tool, `spec-engine` writes:

```
integrations/needs-n8n-flow/
└── <flow-id>-flow.json     # n8n-importable flow stub
```

Optionally a `<flow-id>.md` adjacent if the flow needs context (which
agent triggers it, what it returns, how it integrates with the agent's
tools.md).

## Stub Flow JSON Generation

The stub is a valid n8n flow JSON with:
- Trigger node (Webhook, Schedule, or Manual)
- Skeleton processing nodes (HTTP Request placeholders for each
  upstream / downstream service)
- Output node (back to the calling agent's inbox via webhook callback,
  OR to a downstream service)
- Sticky notes that explain what the build session needs to fill in
  (auth credentials, endpoint URLs, transformation rules)

**Example stub (lead enrichment flow):**

```json
{
  "name": "lead-enrichment",
  "nodes": [
    {
      "parameters": {"path": "lead-capture"},
      "name": "Webhook (in)",
      "type": "n8n-nodes-base.webhook",
      "position": [200, 300]
    },
    {
      "parameters": {"content": "TODO: configure Clearbit API credential"},
      "name": "Sticky Note - Clearbit Auth",
      "type": "n8n-nodes-base.stickyNote",
      "position": [200, 100]
    },
    {
      "parameters": {"url": "https://person.clearbit.com/v2/people/find"},
      "name": "Clearbit Enrich",
      "type": "n8n-nodes-base.httpRequest",
      "position": [400, 300]
    },
    {
      "parameters": {"url": "{{$env.AGENTBLOC_INBOX_WEBHOOK}}"},
      "name": "Inbox Callback",
      "type": "n8n-nodes-base.httpRequest",
      "position": [600, 300]
    }
  ],
  "connections": {
    "Webhook (in)": {"main": [[{"node": "Clearbit Enrich"}]]},
    "Clearbit Enrich": {"main": [[{"node": "Inbox Callback"}]]}
  }
}
```

The stub is intentionally minimal. The build session (or a non-technical
operator) imports the JSON into n8n, fills in credentials, tests with
sample payloads, and connects to the agent's inbox.

## Activation Steps in `BUILD.md`

For every `NEEDS-N8N-FLOW` tool, `spec-engine` writes activation steps
into `runtime/BUILD.md`:

```markdown
### Tier 3 — n8n flows

For each `integrations/needs-n8n-flow/<flow-id>-flow.json`:

1. **Install n8n** (if the user's environment doesn't already have one):
   - Self-hosted Docker: `docker run -p 5678:5678 n8nio/n8n`
   - Hosted: register at n8n.cloud (free tier supports the demo)

2. **Import the flow JSON.**
   - n8n UI → Workflows → New → Import → Upload `<flow-id>-flow.json`

3. **Fill in credentials.**
   - Each `Sticky Note - X Auth` node names a credential the user creates
     via n8n UI → Credentials → New
   - Never paste credentials into the flow JSON; use n8n's credential store

4. **Wire to AgentBloc inbox.**
   - The "Inbox Callback" HTTP Request node POSTs back to the agent's
     inbox endpoint. If using the bash + cron reference impl, this is
     a webhook that calls `scripts/wake.sh <agent-id> webhook-n8n`.
     If using a different runtime, adapt accordingly.

5. **Test.**
   - n8n UI → Test workflow → fire a sample webhook payload
   - Verify the flow completes and the agent's inbox receives the
     enriched data

6. **Activate.**
   - Save and activate the flow. The n8n trigger node now responds to
     real events.
```

## Cross-References

- [inventory-protocol.md](inventory-protocol.md) — Q3 decision tree
- [phase-3-integration.md](phase-3-integration.md) — orchestration
- [webhook-receiver-spec.md](webhook-receiver-spec.md) — Tier 4 sibling
- [mcp-synthesis.md](mcp-synthesis.md) — Tier 2 alternative
- n8n docs: https://docs.n8n.io/ (link verification in CI)
