# Inventory Schema

> Schema reference loaded unconditionally at Phase 3 entry alongside
> [phase-3-integration.md](phase-3-integration.md),
> [inventory-protocol.md](inventory-protocol.md), and
> [mcp-integration-protocol.md](mcp-integration-protocol.md). Defines
> the canonical `inventory.yaml` emitted by Phase 3 after the 4-step
> discovery protocol and tier ranking complete, plus the validation
> checklist Claude walks before writing the file.
>
> The schema's highest-leverage element is the **`tier`** top-level
> field — the 5-tier readiness ranking per
> [inventory-protocol.md](inventory-protocol.md) — which becomes the
> primary decision in Phase 3. The Phase 5 `spec-engine` reads
> `inventory.yaml` to decide which spec-folder template to write per
> tool (`integrations/existing/`, `integrations/needs-mcp-wrapper/`,
> etc.).

## Table of Contents

- [When This Applies](#when-this-applies)
- [Schema Definition](#schema-definition)
- [Field Obligation Matrix](#field-obligation-matrix)
- [Tier Bounded Enum](#tier-bounded-enum)
- [Resolution Method Bounded Enum](#resolution-method-bounded-enum)
- [Trust Tier Bounded Enum](#trust-tier-bounded-enum)
- [Status Bounded Enum](#status-bounded-enum)
- [Validation Checklist](#validation-checklist)
- [Emission Protocol](#emission-protocol)
- [Re-run Behavior](#re-run-behavior)
- [Schema Versioning Rules](#schema-versioning-rules)

## When This Applies

Claude reads this file during the Phase 3 sub-gate
`tool_inventory_complete` to produce the canonical `inventory.yaml` at
`.agentbloc/integrations/inventory.yaml`. The schema defines what
MUST, SHOULD, and MAY appear. The Validation Checklist below is a
deterministic list of pass/fail checks Claude walks before writing the
file; failures surface as targeted follow-up questions or trigger the
Halt-and-Name Protocol per
[mcp-integration-protocol.md](mcp-integration-protocol.md).

Downstream consumer: Phase 5 `spec-engine` reads `inventory.yaml`,
groups tools by `tier`, and writes one `integrations/<tier-dir>/<tool>`
spec per entry plus the master `integrations/INVENTORY.md` matrix.

## Schema Definition

```yaml
schema_version: 2                              # REQUIRED. Integer. Schema version. Currently 2.
generated_at: "ISO-8601 timestamp"             # REQUIRED. When first written by Phase 3.
modified_at: "ISO-8601 timestamp"              # RECOMMENDED. Bumped on every re-discovery run.

tools:                                         # REQUIRED. Length >= 1.
  - tool_id: "string"                          # REQUIRED. kebab-case, unique within file. Matches an entry in agent-profiles.yaml agents[].tools[].
    tier: "EXISTS-MCP | NEEDS-MCP-WRAPPER | NEEDS-N8N-FLOW | NEEDS-WEBHOOK | MANUAL"   # REQUIRED. See Tier Bounded Enum.
    used_by: ["<agent-id>", ...]               # REQUIRED. Must resolve to agents[] in agent-profiles.yaml (Check 7).
    estimated_effort_cc_hours: 4               # REQUIRED. Integer. Per inventory-protocol.md effort estimates.
    evidence:                                  # REQUIRED.
      url: "string"                            # REQUIRED. Tier-specific evidence URL (see Tier Bounded Enum).
      cited_at: "ISO-8601 timestamp"           # REQUIRED. When the URL was inspected.
      last_commit: "ISO-8601 date | null"      # CONDITIONAL. REQUIRED for tier=EXISTS-MCP; OPTIONAL otherwise.
      publisher: "string | null"               # CONDITIONAL. REQUIRED for tier=EXISTS-MCP; OPTIONAL otherwise.
      trust_tier: "HIGH | MEDIUM | LOW"        # CONDITIONAL. REQUIRED for tier=EXISTS-MCP only.

    # Tier-specific sub-fields below. Only the sub-tree matching `tier` is populated.

    mcp_server:                                # REQUIRED when tier=EXISTS-MCP. Forbidden otherwise.
      package: "string"                        # REQUIRED. npm package name OR `.mcp.json` key.
      version: "string"                        # REQUIRED. Package semver.
      installed_via: "string | null"           # OPTIONAL. e.g. "npx -y @smithery-ai/gmail-mcp" or ".mcp.json existing".
      tools_declared: ["string", ...]          # RECOMMENDED. Result of tools/list probe.
      required_scopes: ["string", ...]         # RECOMMENDED. Declared credential scopes.
      healthcheck_at: "ISO-8601 timestamp"     # RECOMMENDED. When verification last passed.

    wrapper:                                   # REQUIRED when tier=NEEDS-MCP-WRAPPER. Forbidden otherwise.
      openapi_url: "string | null"             # REQUIRED if vendor publishes OpenAPI. URL or path.
      vendor_docs_url: "string"                # REQUIRED. Vendor's public API documentation.
      auth_pattern: "api-key | oauth | service-account | bearer-token"  # REQUIRED.
      endpoint_subset: ["string", ...]         # RECOMMENDED. The minimum-viable endpoint list.
      output_path: "string"                    # RECOMMENDED. Default: ".mcp/generated/<tool_id>/".

    n8n_flow:                                  # REQUIRED when tier=NEEDS-N8N-FLOW. Forbidden otherwise.
      flow_path: "string"                      # REQUIRED. Path to stub flow JSON in spec folder.
      services_chained: ["string", ...]        # RECOMMENDED. Vendors the flow composes.
      trigger_node: "webhook | schedule | manual"  # REQUIRED.

    webhook:                                   # REQUIRED when tier=NEEDS-WEBHOOK. Forbidden otherwise.
      vendor_docs_url: "string"                # REQUIRED. Webhook subscription documentation.
      events_subscribed: ["string", ...]       # REQUIRED. Event names consumed.
      signature_header: "string"               # REQUIRED. e.g. "Stripe-Signature".
      env_secret_name: "string"                # REQUIRED. e.g. "STRIPE_WEBHOOK_SECRET".

    manual:                                    # REQUIRED when tier=MANUAL. Forbidden otherwise.
      rationale: "string"                      # REQUIRED. Why automation is not appropriate.
      frequency: "string"                      # REQUIRED. e.g. "1x/year", "1x/quarter", "on-demand".
      runbook_path: "string | null"            # OPTIONAL. Path to runbook in spec folder.

    status: "pending | verified | failed"     # REQUIRED. See Status Bounded Enum.
    failure_reason: "string | null"            # OPTIONAL. Populated only when status=failed.
```

## Field Obligation Matrix

| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED (always) | `schema_version`, `generated_at`, `tools[]` (>=1), per-tool `tool_id` + `tier` + `used_by` + `estimated_effort_cc_hours` + `evidence.url` + `evidence.cited_at` + `status` + the matching tier-specific sub-tree | Claude refuses to emit. Main session re-prompts via targeted follow-up, or Halt-and-Name Protocol triggers. |
| REQUIRED (tier-conditional) | `evidence.last_commit` + `evidence.publisher` + `evidence.trust_tier` (when tier=EXISTS-MCP); the matching `mcp_server` / `wrapper` / `n8n_flow` / `webhook` / `manual` sub-tree | Claude refuses to emit. Surfaces specific missing field. |
| RECOMMENDED | `modified_at`; `mcp_server.tools_declared`, `mcp_server.required_scopes`, `mcp_server.healthcheck_at` (tier=EXISTS-MCP); `wrapper.endpoint_subset`, `wrapper.output_path` (tier=NEEDS-MCP-WRAPPER); `n8n_flow.services_chained` (tier=NEEDS-N8N-FLOW) | Claude emits with warnings. Missing field flags entry `[UNVERIFIED]`. Phase 4 Spec Review surfaces the warning. |
| OPTIONAL | `mcp_server.installed_via`, `manual.runbook_path`, `failure_reason` (non-null only when status=failed) | Silent defaults. Phase 5 spec-engine proceeds without comment. |

Downstream consumers refuse to proceed on an unknown major
`schema_version`, the same rule as
[business-graph-schema.md](business-graph-schema.md) and
[agent-profile-schema.md](agent-profile-schema.md).

## Tier Bounded Enum

The `tier` field is the highest-leverage decision in Phase 3. It maps
each tool to a build-effort path and a spec-folder destination per
[inventory-protocol.md](inventory-protocol.md).

| Enum Value | Definition | Required Evidence | Spec-folder destination |
|-----------|-----------|-------------------|--------------------------|
| `EXISTS-MCP` | Public MCP server exists; install + auth instructions known | MCP server repo URL + last-commit date + star count | `integrations/existing/<tool>.md` |
| `NEEDS-MCP-WRAPPER` | Vendor API exists; no public MCP; wrapper buildable via `mcp-builder` skill | Vendor API docs URL + OpenAPI spec URL (if available) | `integrations/needs-mcp-wrapper/<tool>/{README,BUILD,ENDPOINTS}.md + openapi.yaml` |
| `NEEDS-N8N-FLOW` | Visual / branching / multi-service logic; n8n is the right tool | n8n integration page or community node URL + rationale | `integrations/needs-n8n-flow/<tool>-flow.json` |
| `NEEDS-WEBHOOK` | Vendor pushes events; receiver must be built and exposed | Vendor webhook documentation URL + event types | `integrations/needs-webhook/<tool>-receiver.md` |
| `MANUAL` | No automation path is appropriate (compliance, frequency, cost, complexity) | Compliance/regulatory citation OR explicit user decision | `integrations/manual/<tool>.md` |

Any value outside this enum blocks emission. Tier assignment is
evidence-backed per [inventory-protocol.md](inventory-protocol.md).

## Resolution Method Bounded Enum

Within `tier=EXISTS-MCP`, the `mcp_server.installed_via` field
optionally categorizes how the MCP got resolved during Phase 3. This
is informational only; it doesn't gate emission.

| Enum Value | Definition |
|---|---|
| `.mcp.json existing` | Tool already in local `.mcp.json` before Phase 3 ran |
| `npx -y <package>` | Resolved via ecosystem registry; user approved auto-install |
| `wrapper` | (Legacy synonym; prefer tier=NEEDS-MCP-WRAPPER) |
| `null` | Not specified |

## Trust Tier Bounded Enum

The `evidence.trust_tier` field per tool is drawn from a fixed set
when `tier=EXISTS-MCP`. Criteria live in
[mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) Trust Tier
Criteria.

| Enum Value | Criteria | When to Pick |
|---|---|---|
| `HIGH` | Official vendor-maintained OR community with >500 stars + commit within 90 days | Auto-pass proposal; default-yes approval |
| `MEDIUM` | Community 100-500 stars, commit within 180 days, clear docs | Propose with evidence; user approval required |
| `LOW` | <100 stars OR >180 days since last commit OR unclear maintainer OR no docs | Surface warning; suggest `tier=NEEDS-MCP-WRAPPER` alternative; explicit user override required |

`LOW` trust tier on `EXISTS-MCP` should usually flip the assignment to
`NEEDS-MCP-WRAPPER` instead — the `mcp-builder` synthesis path produces
a more reliable wrapper than a stale community MCP.

## Status Bounded Enum

The `status` field per tool is drawn from a fixed set. It drives the
Phase 3 sub-gate behavior.

| Enum Value | Definition | Sub-gate behavior |
|---|---|---|
| `pending` | Tool entry created but evidence verification not yet complete | `tool_inventory_complete` stays `pending` until all entries reach `verified` or `failed` |
| `verified` | Evidence URL fetched, claims verified (MCP repo accessible / API docs reachable / vendor webhook docs valid / etc.) | Sub-gate transitions to `approved` when every entry is `verified` |
| `failed` | Evidence verification failed (URL 404, repo deleted, API docs gone) OR Halt-and-Name Protocol triggered | Sub-gate `blocked`; user must resolve (cite alternative, switch tier, or remove tool) before re-verification |

Cross-reference: [mcp-integration-protocol.md](mcp-integration-protocol.md)
Verification Loop and Halt-and-Name Protocol.

## Validation Checklist

Claude walks this ordered list before writing
`.agentbloc/integrations/inventory.yaml`. Any FAIL blocks emission;
the targeted follow-up surfaces in the conversation per the rendered-
table review pattern. REQUIRED-tier checks (1-9) block emission;
RECOMMENDED check (10) emits with warnings.

**Check 1: `schema_version` present and equals current version (`2`)**
- FAIL: Set `schema_version: 2` automatically; no user follow-up needed.

**Check 2: Every `tools[].tool_id` unique, kebab-case, and matches an entry in `.agentbloc/team/agent-profiles.yaml` agents[].tools[]**
- FAIL: If the inventory has a tool not in any agent's tools[], remove it (dead entry). If an agent has a tool not in the inventory, the 4-step search missed it — re-run discovery for that tool.

**Check 3: Every `tools[].tier` is in the bounded enum (`EXISTS-MCP` / `NEEDS-MCP-WRAPPER` / `NEEDS-N8N-FLOW` / `NEEDS-WEBHOOK` / `MANUAL`)**
- FAIL: Surface the specific tool and invalid value to the main session ("Tool <tool-id> tier=<value> is not in the enum; pick one of EXISTS-MCP / NEEDS-MCP-WRAPPER / NEEDS-N8N-FLOW / NEEDS-WEBHOOK / MANUAL"); block emission.

**Check 4: Every `tools[]` entry has the matching tier-specific sub-tree populated AND no other tier sub-trees populated**
- FAIL on missing sub-tree: surface the specific tool and missing keys (e.g., "tier=EXISTS-MCP requires `mcp_server` sub-tree with `package` + `version`"). Block emission.
- FAIL on extra sub-tree: surface the conflict ("tier=NEEDS-MCP-WRAPPER but `mcp_server` sub-tree present; remove or change tier"). Block emission.

**Check 5: Every `tools[]` entry has `evidence.url` and `evidence.cited_at` populated**
- FAIL: Re-run the 4-step discovery protocol for that tool. No tier assignment without evidence.

**Check 6: For tier=EXISTS-MCP, `evidence.last_commit` + `evidence.publisher` + `evidence.trust_tier` are populated**
- FAIL on `last_commit > 180 days`: warn that this is `LOW` trust; suggest re-assigning to `NEEDS-MCP-WRAPPER`. User can override.
- FAIL on missing: re-fetch the repo URL and parse.

**Check 7: Every `tools[].used_by[]` agent id resolves to an entry in `.agentbloc/team/agent-profiles.yaml` agents[]**
- FAIL: Reject the YAML; log the unresolved id; re-read agent-profiles.yaml for correct mapping.

**Check 8: For tier=EXISTS-MCP entries with status=verified, the MCP server responded to `tools/list` (`evidence.tools_declared[]` length >= 1) AND every `mcp_server.required_scopes[]` entry is present in `.env` OR stubbed in `.env.example`**
- FAIL on Ping: set `status: failed`, `failure_reason: "tools/list probe failed"`, write VERIFICATION-FAILED.md.
- FAIL on scope missing: auto-append the env var name to `.env.example` with comment `# required by <used_by agent> for <package> scope <scope>`; halt with the specific missing var named.

**Check 9: Every `tools[].estimated_effort_cc_hours` is a positive integer within the per-tier band per [inventory-protocol.md](inventory-protocol.md) Effort Estimates**
- FAIL on out-of-band: warn the user that the estimate is unusually high/low for this tier; ask for confirmation. Optimistic estimates erode trust; conservative ones build it.

**Check 10 (WARN, not FAIL): RECOMMENDED fields populated (`modified_at`, tier-specific RECOMMENDED sub-fields, `evidence.last_commit` for non-EXISTS-MCP tiers when known)**
- WARN: Emit with `null` defaults; flag any missing field as `[UNVERIFIED]` in the rendered table so user can accept or fix.

## Emission Protocol

Emission happens during the Phase 3 sub-gate close. The steps:

1. Walk the Validation Checklist above in order.
2. For each REQUIRED failure (Checks 1-9), either apply the targeted
   remediation (auto-append, re-run verification) or surface a
   targeted follow-up to the user and wait for resolution. Do not
   emit a partial inventory.
3. Once all REQUIRED checks pass, render the inventory to the user as
   a markdown table grouped by tier + per-tool evidence rows + tier
   distribution summary. The rendered table is what the user
   confirms; the YAML itself is NEVER shown.
4. After user confirmation ("yes" / "adelante" / etc.), write the YAML
   silently to `.agentbloc/integrations/inventory.yaml`. Create the
   `.agentbloc/integrations/` directory if it does not exist.
5. Confirm emission in one sentence: "Inventory saved. Ready to move
   to spec review."
6. Set the Phase 3 `tool_inventory_complete` sub-gate to `approved`
   and allow transition to Phase 4.

If the user edits any entry during table review, re-run the
Validation Checklist on the affected entry and re-emit the inventory.
Per [mcp-integration-protocol.md](mcp-integration-protocol.md),
NEVER silently proceed with a partially-verified entry.

**Rendered table shape for user review** (8 columns, grouped by tier):

| # | tool_id | tier | used_by | effort | evidence | trust_tier | status |

Per-tool sub-bullets render the tier-specific RECOMMENDED fields
(`tools_declared`, `required_scopes`, `healthcheck_at`,
`endpoint_subset`, `events_subscribed`, etc.) only when non-null.

## Re-run Behavior

If `.agentbloc/integrations/inventory.yaml` already exists when the
Phase 3 sub-gate is reached, Claude asks the user: "I already have
an inventory on file for this project. Do you want to (a) keep the
existing one, (b) overwrite it, or (c) re-verify existing entries and
add any new tools?" Default is **re-verify** (additive).

- **keep**: Skip emission, transition to Phase 4 with the existing
  inventory. Warn the user that stale `cited_at` timestamps may cause
  Phase 6 Spec Evolution to flag entries.
- **overwrite**: Replace the file entirely after a fresh 4-step search +
  evidence verification for every tool in
  `.agentbloc/team/agent-profiles.yaml`. Warn the user that prior
  evidence history will be lost.
- **re-verify (default)**: Read the existing inventory; re-run evidence
  verification on every entry; bump `modified_at` to current ISO-8601;
  add entries for any new tools in agent-profiles.yaml that are not
  yet in the inventory; flag removed tools when no agent uses them
  anymore. Designer Agent edits (conversational rename) propagate via
  Check 7 on `used_by[]` resolution.

The `schema_version` on disk must match the current schema version.
If it does not, refuse re-verify and emit `action_required:
schema_version_mismatch` to the conversation so the user knows a
manual migration is needed.

## Schema Versioning Rules

The `schema_version` field is an integer. Currently `2`. The
version bumps only on breaking changes:

- A REQUIRED field is removed or renamed.
- An enum value is removed from a bounded type.
- A field's obligation tier flips (e.g., REQUIRED → forbidden).

Additive changes do NOT bump the version:

- Adding a new OPTIONAL field.
- Adding a new value to a bounded enum.
- Loosening a REQUIRED field to RECOMMENDED.

Downstream consumers (Phase 5 spec-engine, Phase 6 Spec Evolution,
Phase 16 TAP tests) read `schema_version` and refuse to proceed on
an unknown major version.

## Cross-References

- [phase-3-integration.md](phase-3-integration.md) — phase orchestration
- [inventory-protocol.md](inventory-protocol.md) — 5-tier decision tree + evidence requirements
- [mcp-integration-protocol.md](mcp-integration-protocol.md) — Step 1 MCP search detail
- [mcp-synthesis.md](mcp-synthesis.md) — tier=NEEDS-MCP-WRAPPER spec design
- [n8n-flow-design.md](n8n-flow-design.md) — tier=NEEDS-N8N-FLOW spec design
- [webhook-receiver-spec.md](webhook-receiver-spec.md) — tier=NEEDS-WEBHOOK spec design
- [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) — known-good MCPs + trust tier criteria
- [spec-folder-structure.md](spec-folder-structure.md) — Phase 5 destination map
