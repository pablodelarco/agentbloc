# Phase 3: Deep Tool Discovery

> Loaded by SKILL.md at Phase 3 entry. Renamed from "Deep Integration
> Analysis" in v3.0; the substance is extended with the 5-tier readiness
> ranking that becomes the highest-leverage output of the whole skill.

## Table of Contents

- [When This Applies](#when-this-applies)
- [The 5-Tier Readiness Ranking](#the-5-tier-readiness-ranking)
- [Sub-gate](#sub-gate)
- [The 4-Step Discovery Protocol](#the-4-step-discovery-protocol)
- [Inventory Output](#inventory-output)
- [Cross-References](#cross-references)

## When This Applies

Phase 3 begins after Phase 2 (General Design) gate is `approved`. The
team's `agent-profiles.yaml` lists which tools each agent needs. Phase 3
turns that abstract list into a concrete, deeply-researched inventory
that ranks every tool by **readiness tier**.

This is the highest-leverage phase in v3.0. The downstream build session
(in Claude Code, Codex, Gemini, Cursor, OpenClaw) makes its biggest
implementation decisions based on the tier each tool gets here. Get
this right and the build session has zero ambiguity. Get it wrong and
the build session will re-do half the discovery work.

## The 5-Tier Readiness Ranking

Every tool the team needs gets exactly one tier:

| Tier | Meaning | Build effort | Output in spec folder |
|---|---|---|---|
| **EXISTS-MCP** | Public MCP server exists; install instructions known | Hours | `integrations/existing/<tool>.md` |
| **NEEDS-MCP-WRAPPER** | API exists, no public MCP; wrapper buildable via `mcp-builder` skill | Days | `integrations/needs-mcp-wrapper/<tool>/` (README + BUILD + ENDPOINTS + openapi) |
| **NEEDS-N8N-FLOW** | Visual / branching logic best done in n8n | Hours-days | `integrations/needs-n8n-flow/<tool>-flow.json` stub |
| **NEEDS-WEBHOOK** | Event-driven; receiver must be built | Days | `integrations/needs-webhook/<tool>-receiver.md` spec |
| **MANUAL** | No automation path possible / advisable | n/a | `integrations/manual/<tool>.md` rationale |

Tier assignment must be **evidence-backed** — every claim cites a URL
(MCP server repo, vendor API doc, etc.). No assumed capabilities.

See [inventory-protocol.md](inventory-protocol.md) for the tier
assignment decision tree.

## Sub-gate

`tool_inventory_complete`

Closes when:
1. Every tool referenced in `agent-profiles.yaml` has a tier assignment
2. Every tier assignment has an evidence URL (vendor docs, MCP repo, etc.)
3. `.agentbloc/integrations/inventory.yaml` exists and validates against
   [inventory-schema.md](inventory-schema.md)

## The 4-Step Discovery Protocol

Per tool, in order, until a tier is assigned:

### Step 1 — MCP Search

Check (in order):
1. Local `.mcp.json` for already-configured MCP servers
2. Ecosystem registry per [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md)
3. PulseMCP / Awesome MCP Servers / official Anthropic registry
4. Community GitHub search (>100 stars, last commit < 6 months)

If found and verified working → tier `EXISTS-MCP`. Done.

### Step 2 — API Investigation

If no MCP exists:
1. Find the vendor's public API documentation (REST, GraphQL, gRPC)
2. Look for an OpenAPI / Swagger spec
3. Assess least-privilege endpoint subset (usually 3-8 endpoints suffice
   per [mcp-synthesis.md](mcp-synthesis.md))

If a wrapper is buildable via `mcp-builder` → tier `NEEDS-MCP-WRAPPER`.
Spec out the wrapper now (the build session runs `mcp-builder` later).

### Step 3 — n8n Suitability

If no API or the workflow has heavy branching / multi-service / polling
logic, evaluate n8n suitability per
[n8n-flow-design.md](n8n-flow-design.md). When n8n wins:

- Visual logic is clearer than code
- Multiple services need to compose without writing glue
- Polling / scheduled triggers map to native n8n nodes
- The user's team can self-edit visually

→ tier `NEEDS-N8N-FLOW`. Spec out the flow JSON stub.

### Step 4 — Webhook or Manual

If the integration is event-driven (vendor pushes data when something
changes) → tier `NEEDS-WEBHOOK` per
[webhook-receiver-spec.md](webhook-receiver-spec.md).

If none of the above paths apply (frequency too low, compliance blocks
automation, human judgment required) → tier `MANUAL` with a clear
rationale.

For services with no API docs, spawn the `browser-discovery` subagent
per [browser-fallback.md](browser-fallback.md) to investigate the
service and produce a DISCOVERY-REPORT.md. The subagent's output
informs the tier decision.

## Inventory Output

Phase 3 closes by writing `.agentbloc/integrations/inventory.yaml`
silently. Schema in [inventory-schema.md](inventory-schema.md).

The user reviews:
- A rendered tier-ranked table (one row per tool with tier + evidence URL + effort estimate)
- Per-tool evidence rows (the URLs you cite)
- The sub-gate check ("every tool has a tier with evidence")

Confirm to advance to Phase 4 (Spec Review).

## Cross-References

- [inventory-protocol.md](inventory-protocol.md) — tier assignment decision tree (NEW in v3.0)
- [inventory-schema.md](inventory-schema.md) — inventory.yaml schema
- [mcp-integration-protocol.md](mcp-integration-protocol.md) — MCP search detail
- [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) — known-good MCPs
- [mcp-synthesis.md](mcp-synthesis.md) — wrapper design from APIs (NEW in v3.0)
- [n8n-flow-design.md](n8n-flow-design.md) — n8n decision + stub generation (NEW in v3.0)
- [webhook-receiver-spec.md](webhook-receiver-spec.md) — webhook patterns (NEW in v3.0)
- [browser-fallback.md](browser-fallback.md) — browser-discovery subagent invocation
- [browser-stack.md](browser-stack.md) — Playwright / Patchright stack
- [.claude/agents/browser-discovery.md](../../../agents/browser-discovery.md) — the subagent
