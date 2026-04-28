# Inventory Protocol — The 5-Tier Readiness Ranking

> Loaded by SKILL.md and the `browser-discovery` subagent during Phase 3.
> The decision tree for assigning each tool a tier in
> `.agentbloc/integrations/inventory.yaml`. This is the highest-leverage
> output of the entire skill.

## Table of Contents

- [The 5 Tiers](#the-5-tiers)
- [The Decision Tree](#the-decision-tree)
- [Evidence Requirements](#evidence-requirements)
- [Effort Estimates by Tier](#effort-estimates-by-tier)
- [Edge Cases](#edge-cases)
- [Cross-References](#cross-references)

## The 5 Tiers

| Tier | Definition | Build effort | Spec output |
|---|---|---|---|
| **EXISTS-MCP** | Public MCP server exists; install + auth instructions known | Hours | `integrations/existing/<tool>.md` |
| **NEEDS-MCP-WRAPPER** | Vendor API exists; no public MCP; wrapper buildable via `mcp-builder` skill | Days | `integrations/needs-mcp-wrapper/<tool>/` |
| **NEEDS-N8N-FLOW** | Visual / branching / multi-service logic; n8n is the right tool | Hours-days | `integrations/needs-n8n-flow/<tool>-flow.json` |
| **NEEDS-WEBHOOK** | Vendor pushes events; receiver must be built and exposed | Days | `integrations/needs-webhook/<tool>-receiver.md` |
| **MANUAL** | No automation path is appropriate (compliance, frequency, cost, complexity) | n/a | `integrations/manual/<tool>.md` |

## The Decision Tree

For each tool the team needs, walk this tree top-to-bottom. Stop at the
first tier that fits. Cite an evidence URL for the choice.

```
START
  │
  ├─ Q1: Does an MCP server already exist for this tool?
  │       Sources: .mcp.json, mcp-ecosystem-registry.md, PulseMCP,
  │       Awesome MCP Servers, GitHub search (>100 stars).
  │       Verify: install instructions in a verified repo; smoke test
  │       the server connects.
  │       YES → tier EXISTS-MCP. Cite the repo URL. Done.
  │       NO  → continue.
  │
  ├─ Q2: Does the vendor expose a public API (REST / GraphQL / gRPC)?
  │       Sources: vendor docs site, OpenAPI / Swagger spec, postman
  │       collections.
  │       Verify: there's a documented authentication path and at
  │       least the 3-8 endpoints the team needs are documented.
  │       YES → continue (Q3).
  │       NO  → continue (Q4).
  │
  ├─ Q3: Is the integration better expressed as code or as a visual flow?
  │       Visual wins when: 3+ services compose, polling logic is
  │       branchy, the user's team will self-edit, or the workflow
  │       is largely declarative.
  │       Code wins when: tight coupling to agent prose, custom
  │       business logic per request, performance-sensitive.
  │       CODE   → tier NEEDS-MCP-WRAPPER. Spec the wrapper per
  │                mcp-synthesis.md. Cite the OpenAPI URL.
  │       VISUAL → tier NEEDS-N8N-FLOW. Spec the flow per
  │                n8n-flow-design.md. Cite the n8n integration page.
  │
  ├─ Q4: Is the integration event-driven (vendor pushes when something changes)?
  │       Examples: Stripe webhooks, Shopify webhooks, GitHub webhooks,
  │       Slack Events API.
  │       Verify: the vendor exposes a webhook subscription mechanism.
  │       YES → tier NEEDS-WEBHOOK. Spec the receiver per
  │              webhook-receiver-spec.md. Cite the webhook docs.
  │       NO  → continue (Q5).
  │
  └─ Q5: Is automation appropriate at all?
          Sometimes the right answer is "this stays manual." Triggers:
          - Compliance forbids automation (notarized signing, etc.)
          - Frequency is so low that a runbook beats a script
          - Human judgment is irreducibly part of the step
          - The cost of getting it wrong is higher than the cost of
            doing it by hand
          → tier MANUAL. Document the rationale; provide a runbook
            template for the human to follow.
```

For tools where Q1 returns NO and Q2 is unclear (vendor docs are
sparse), spawn the `browser-discovery` subagent per
[browser-fallback.md](browser-fallback.md) to investigate. The subagent
emits a DISCOVERY-REPORT.md that informs Q2/Q3/Q4 decisions.

## Evidence Requirements

Every tier assignment must cite a URL. No exceptions.

| Tier | Required evidence |
|---|---|
| EXISTS-MCP | MCP server repo URL + last-commit date + star count |
| NEEDS-MCP-WRAPPER | Vendor API docs URL + OpenAPI spec URL (if available) |
| NEEDS-N8N-FLOW | n8n integration page or community node URL + rationale |
| NEEDS-WEBHOOK | Vendor webhook documentation URL + event types |
| MANUAL | Compliance / regulatory citation OR explicit user decision |

Phase 4 (Spec Review) verifies every entry has evidence. Missing
evidence → user pushes back, return to Phase 3 for that tool.

## Effort Estimates by Tier

| Tier | Typical CC-hours | Typical human-days |
|---|---|---|
| EXISTS-MCP | 1-2 | 0.5 (install + auth + smoke test) |
| NEEDS-MCP-WRAPPER | 4-8 | 1-2 (per mcp-builder + endpoint subset) |
| NEEDS-N8N-FLOW | 2-4 | 1 (configure + test the flow) |
| NEEDS-WEBHOOK | 6-10 | 2 (receiver + verification + retry handling) |
| MANUAL | 0 (it's a runbook) | 0.5 (write the runbook) |

These estimates are inputs to `ROADMAP.md`. They should be
**conservative** — overestimating builds trust; underestimating burns
it.

## Edge Cases

**Multiple-tier candidates.** If a tool fits two tiers (e.g., Notion
has both an API and a public MCP that's flaky), prefer the more-
reliable path. If both are reliable, prefer EXISTS-MCP > NEEDS-MCP-
WRAPPER > NEEDS-N8N-FLOW.

**Bring-your-own MCP.** Some users will say "I already have a custom
MCP for this internal service." That's tier EXISTS-MCP with the user's
internal repo as the evidence URL. Trust but verify (smoke test it).

**OAuth-only services.** Some tools (Google Workspace, Notion) require
OAuth dance during install. The tier is unchanged but `BUILD.md` flags
the OAuth requirement as a build-time blocker the user must complete.

**Rate-limited APIs.** Some APIs (Linkedin, Twitter) have aggressive
rate limits. Tier might still be NEEDS-MCP-WRAPPER, but the wrapper
spec should include rate-limiting strategy in `ENDPOINTS.md`.

**Browser-discovery results.** If `browser-discovery` finds no
documented API but a usable internal API (DOCUMENTED tier in its
report), promote to NEEDS-MCP-WRAPPER. If only INTERNAL or
INTERNAL-HARDENED tier, generally prefer MANUAL unless the user has
explicit license to scrape.

## Cross-References

- [phase-3-integration.md](phase-3-integration.md) — phase orchestration
- [inventory-schema.md](inventory-schema.md) — `inventory.yaml` schema
- [mcp-integration-protocol.md](mcp-integration-protocol.md) — Q1 detail (MCP search)
- [mcp-synthesis.md](mcp-synthesis.md) — Q3 NEEDS-MCP-WRAPPER spec design
- [n8n-flow-design.md](n8n-flow-design.md) — Q3 NEEDS-N8N-FLOW spec design
- [webhook-receiver-spec.md](webhook-receiver-spec.md) — Q4 webhook spec design
- [browser-fallback.md](browser-fallback.md) — `browser-discovery` invocation
- [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) — known-good MCPs
