# Integration Manifest Schema

> Schema reference loaded unconditionally at Phase 3 entry alongside [phase-3-integration.md](phase-3-integration.md), [mcp-integration-protocol.md](mcp-integration-protocol.md), and [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md). Defines the canonical `integration-manifest.yaml` emitted by Phase 3 Summary gate after the 4-step search and three-check verification loop complete, plus the validation checklist Claude walks before writing the file.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Schema Definition](#schema-definition)
- [Field Obligation Matrix](#field-obligation-matrix)
- [Resolution Method Bounded Enum](#resolution-method-bounded-enum)
- [Trust Tier Bounded Enum](#trust-tier-bounded-enum)
- [Status Bounded Enum](#status-bounded-enum)
- [Validation Checklist](#validation-checklist)
- [Emission Protocol](#emission-protocol)
- [Re-run Behavior](#re-run-behavior)
- [Schema Versioning Rules](#schema-versioning-rules)

## When This Applies

Claude reads this file during the Phase 3 Summary gate to produce the canonical `integration-manifest.yaml` at `.agentbloc/integrations/integration-manifest.yaml`. The schema defines what MUST, SHOULD, and MAY appear in the YAML. The Validation Checklist below is a deterministic list of pass/fail checks Claude walks before writing the file; failures surface as targeted follow-up questions in the conversation or trigger the Halt-and-Name Protocol per [mcp-integration-protocol.md](mcp-integration-protocol.md). Downstream consumers - Phase 12 Deploy Pipeline (renders manifest entries into `.mcp.json` merges + ClaudeClaw job configs), Phase 6 Evolution v1.0 inheritance (re-verifies on weekly cadence reading `healthcheck_at`), Phase 16 end-to-end TAP tests (replays the Arco Rooms canonical fixture) - all read this artifact. The `resolution_method` and `trust_tier` bounded enums define the execution paths Claude takes during the 4-step search; the `status` enum drives gate behavior per D-35.

## Schema Definition

```yaml
schema_version: 1                              # REQUIRED. Integer. Bumped only on breaking changes.
generated_at: "ISO-8601 timestamp"             # REQUIRED. When first written by Phase 3.
modified_at: "ISO-8601 timestamp"              # RECOMMENDED. Bumped on every re-verification run.

tools:                                         # REQUIRED. Length >= 1.
  - tool_id: "string"                          # REQUIRED. kebab-case, unique within file. Matches an entry in agent-profiles.yaml agents[].tools[].
    resolution_method: "existing | ecosystem | wrapper | browser-fallback | failed"   # REQUIRED. See Resolution Method Bounded Enum.
    mcp_server:                                # REQUIRED.
      package: "string"                        # REQUIRED. npm package (ecosystem), path under .mcp/generated/<tool-id>/ (wrapper), or .mcp.json key (existing).
      version: "string"                        # REQUIRED. Package semver or wrapper commit SHA.
      installed_via: "string | null"           # OPTIONAL. e.g. "npx -y @smithery-ai/gmail-mcp" or "wrapper" or ".mcp.json existing".
    evidence:                                  # REQUIRED.
      url: "string"                            # REQUIRED. GitHub / npm / official docs URL.
      last_commit: "ISO-8601 date | null"      # RECOMMENDED. Per v1.0 INTG-03.
      publisher: "string | null"               # RECOMMENDED. Per v1.0 INTG-03.
      trust_tier: "HIGH | MEDIUM | LOW"        # REQUIRED. See Trust Tier Bounded Enum.
      tools_declared: ["string", ...]          # RECOMMENDED. Result of tools/list probe (D-39).
      required_scopes: ["string", ...]         # RECOMMENDED. Declared credential scopes (D-39).
      healthcheck_at: "ISO-8601 timestamp"     # RECOMMENDED. When D-34 three checks last passed (D-39).
    used_by: ["<agent-id>", ...]               # RECOMMENDED. Must resolve to agents[] in agent-profiles.yaml (Check 7).
    status: "pending | verified | failed"     # REQUIRED. See Status Bounded Enum.
    failure_reason: "string | null"            # OPTIONAL. Populated only when status=failed; names the specific Check that failed.
```

## Field Obligation Matrix

| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED | `schema_version`, `generated_at`, `tools[]` (>=1), per-tool `tool_id` + `resolution_method` + `mcp_server.package` + `mcp_server.version` + `evidence.url` + `evidence.trust_tier` + `status` | Claude refuses to emit. Main session re-prompts through targeted follow-up, or the Halt-and-Name Protocol triggers. |
| RECOMMENDED | `modified_at`, `evidence.last_commit`, `evidence.publisher`, `evidence.tools_declared`, `evidence.required_scopes`, `evidence.healthcheck_at`, `used_by` | Claude emits with warnings. Missing any evidence field flags the entry `[UNVERIFIED]` per v1.0 INTG-06. Phase 12 Deploy Pipeline surfaces the warning in DEPLOY-REPORT.md. |
| OPTIONAL | `mcp_server.installed_via`, `failure_reason` (non-null only when status=failed) | Silent defaults. Phase 12 proceeds without comment. |

Downstream consumers refuse to proceed on an unknown major `schema_version`, the same rule as business-graph-schema.md and agent-profile-schema.md.

## Resolution Method Bounded Enum

The `resolution_method` field per tool is drawn from a fixed set. It drives which execution path Claude took during the 4-step search in [mcp-integration-protocol.md](mcp-integration-protocol.md). Downstream Phase 12 Deploy Pipeline reads this field to decide whether to merge into `.mcp.json` vs copy a wrapper vs skip.

| Enum Value | Definition | Required Sub-fields | Example |
|-----------|-----------|---------------------|---------|
| `existing` | Tool already in `.mcp.json` before Phase 3 ran | `mcp_server.installed_via: ".mcp.json existing"` | `{resolution_method: existing, mcp_server: {installed_via: ".mcp.json existing"}}` |
| `ecosystem` | Tool resolved via mcp-ecosystem-registry.md; user approved `npx -y <package>` install (D-37) | `mcp_server.installed_via: "npx -y <package>"` | `{resolution_method: ecosystem, mcp_server: {installed_via: "npx -y @smithery-ai/gmail-mcp"}}` |
| `wrapper` | Tool resolved via mcp-builder skill generating at `.mcp/generated/<tool-id>/` (D-33) | `mcp_server.package: ".mcp/generated/<tool-id>/"`, `mcp_server.installed_via: "wrapper"` | `{resolution_method: wrapper, mcp_server: {package: ".mcp/generated/bbva-mcp/", installed_via: "wrapper"}}` |
| `browser-fallback` | Phase 11 scope (BROWSER-01..12); reserved enum slot only in Phase 10 | (populated by Phase 11) | `{resolution_method: browser-fallback, status: pending}` |
| `failed` | None of Steps 1-4 resolved; Halt-and-Name Protocol triggered per D-35 | `failure_reason` populated with specific Check number | `{resolution_method: failed, status: failed, failure_reason: "Check 2: scope gmail.modify missing"}` |

Any value outside this enum blocks emission. Phase 10 does NOT populate `browser-fallback` in produced manifests; that enum value is reserved for Phase 11.

## Trust Tier Bounded Enum

The `evidence.trust_tier` field per tool is drawn from a fixed set. Criteria live in [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) Trust Tier Criteria per v1.0 INTG-04.

| Enum Value | Criteria | When to Pick |
|-----------|----------|--------------|
| `HIGH` | Official vendor-maintained OR community with >500 stars + commit within 90 days | Auto-pass proposal; default-yes approval |
| `MEDIUM` | Community 100-500 stars, commit within 180 days, clear docs | Propose with evidence; user approval required |
| `LOW` | <100 stars OR >180 days since last commit OR unclear maintainer OR no docs | Surface warning; suggest wrapper alternative; explicit user override required |

Cross-reference: [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md).

## Status Bounded Enum

The `status` field per tool is drawn from a fixed set. It drives the Phase 3 gate behavior.

| Enum Value | Definition | Phase 3 gate behavior |
|-----------|-----------|------------------------|
| `pending` | Tool entry created but Verification Loop not yet complete | Gate stays `pending` until all `tools[]` reach `verified` or `failed` |
| `verified` | All three D-34 checks (Ping / Scope match / Shape probe) passed; `healthcheck_at` stamped | Gate can transition to `approved` when every entry is verified |
| `failed` | One or more D-34 checks failed; Halt-and-Name Protocol triggered | Gate `blocked`; user must resolve (add scope, add credential, or edit agent tool list) before re-verification |

Cross-reference: [mcp-integration-protocol.md](mcp-integration-protocol.md) Verification Loop and Halt-and-Name Protocol.

## Validation Checklist

Claude walks this ordered list before writing `.agentbloc/integrations/integration-manifest.yaml`. Any FAIL blocks emission; the targeted follow-up surfaces in the conversation per D-14 rendered-table review pattern. REQUIRED-tier checks (1-7) block emission; RECOMMENDED check (8) emits with warnings.

**Check 1: `schema_version` present and equals current version (`1`)**
- FAIL: Set `schema_version: 1` automatically; no user follow-up needed.

**Check 2: Every `tools[].tool_id` unique, kebab-case, and matches an entry in `.agentbloc/team/agent-profiles.yaml` agents[].tools[]**
- FAIL: If the manifest has a tool not in any agent's tools[], remove it (dead entry). If an agent has a tool not in the manifest, the 4-step search missed it - re-run Step 1 for that tool.

**Check 3: Every `tools[].resolution_method` in {existing, ecosystem, wrapper, browser-fallback, failed} with the required sub-fields populated per the Resolution Method Bounded Enum**
- FAIL: Surface the specific tool and missing sub-field to the main session with a targeted question ("Which install path did tool <tool-id> resolve via?"), block emission.

**Check 4 (D-34 Ping): Every `tools[]` entry with status=verified has `evidence.tools_declared[]` length >= 1 (the MCP server responded to `tools/list` and declared at least one tool)**
- FAIL: Re-run the Verification Loop Ping check on that tool. If Ping fails: set `status: failed`, `failure_reason: "Check 4: server does not respond to tools/list"`, write VERIFICATION-FAILED.md per D-35.

**Check 5 (D-34 Scope match): Every `tools[]` entry with status=verified has (a) `evidence.tools_declared[]` intersecting its `used_by[]` agents' tools[] entries, AND (b) every `evidence.required_scopes[]` entry present in `.env` OR stubbed in `.env.example`**
- FAIL on scope missing: Auto-append the env var name to `.env.example` per D-38 with comment `# required by <used_by agent> for <package> scope <scope>`; halt with the specific missing var named.
- FAIL on tool overlap: Surface the gap; propose switching to Step 3 (wrapper) for the missing tool or reducing the agent's tool list.

**Check 6 (D-34 Shape probe): Every `tools[]` entry with status=verified has been called with a dry-run argument and the response shape matches the used_by agents' `outputs.schema` (when the output schema is defined in agent-profiles.yaml)**
- FAIL: Surface both shapes (declared vs observed) side-by-side in the conversation with specific field mismatches quoted. Block emission until user decides whether to accept the mismatch or re-generate the wrapper.

**Check 7: Every `tools[].used_by[]` agent id resolves to an entry in `.agentbloc/team/agent-profiles.yaml` agents[]**
- FAIL: Reject the YAML; log the unresolved id; re-read `.agentbloc/team/agent-profiles.yaml` for correct mapping. If the agent was renamed via Phase 9 conversational edit (D-26), update the manifest to match.

**Check 8 (WARN, not FAIL): RECOMMENDED fields populated (`evidence.last_commit`, `evidence.publisher`, `evidence.tools_declared`, `evidence.required_scopes`, `evidence.healthcheck_at`, `used_by`, `modified_at`) or explicitly `null`**
- WARN: Emit with `null` defaults; flag any missing field as `[UNVERIFIED]` per v1.0 INTG-06 in the rendered table so user can accept or fix.

## Emission Protocol

Emission happens during the Phase 3 Summary gate. The steps:

1. Walk the Validation Checklist above in order.
2. For each REQUIRED failure (Checks 1-7), either apply the targeted remediation (auto-append, re-run Verification Loop) or surface a targeted follow-up to the user and wait for resolution. Do not emit a partial manifest.
3. Once all REQUIRED checks pass, render the integrations to the user as a markdown table + per-tool evidence rows + security summary (D-14 pattern - the rendered table is what the user confirms; the YAML itself is NEVER shown).
4. After user confirmation ("yes" / "adelante" / etc.), write the YAML silently to `.agentbloc/integrations/integration-manifest.yaml`. Create the `.agentbloc/integrations/` directory if it does not exist.
5. Confirm emission in one sentence: "Integration manifest saved. Ready to move to the confirmation and dry-run phase."
6. Set the Phase 3 `mcp_integrations_verified` sub-gate to `approved` and allow transition to Phase 4.

If the user edits any entry during table review, re-run the Validation Checklist on the affected entry and re-emit the manifest. Per D-35, NEVER silently proceed with a partially-verified integration.

**Rendered table shape for user review** (7 columns):

| # | tool_id | resolution_method | package | trust_tier | used_by | status |

Per-tool evidence rows render the four D-39 fields (`tools_declared`, `required_scopes`, `healthcheck_at`, `last_commit`) as sub-bullets beneath the table row, only when non-null.

## Re-run Behavior

If `.agentbloc/integrations/integration-manifest.yaml` already exists when the Phase 3 Summary gate is reached, Claude asks the user: "I already have an integration manifest on file for this project. Do you want to (a) keep the existing one, (b) overwrite it, or (c) re-verify existing entries and add any new tools?" Default is **re-verify** (additive per D-36 idempotency rationale).

- **keep**: Skip emission, transition to Phase 4 with the existing manifest. Warn the user that stale `healthcheck_at` timestamps may cause Phase 6 Evolution to flag entries.
- **overwrite**: Replace the file entirely after a fresh 4-step search + Verification Loop pass for every tool in `.agentbloc/team/agent-profiles.yaml`. Warn the user that prior `healthcheck_at` history will be lost.
- **re-verify (default)**: Read the existing manifest; re-run the Verification Loop on every entry; bump `modified_at` to the current ISO-8601 timestamp; add entries for any new tools in agent-profiles.yaml that are not yet in the manifest; flag removed tools from the manifest when no agent uses them anymore. Designer Agent edits (D-26 conversational edits renaming agents) propagate via Check 7 on `used_by[]` resolution.

The `schema_version` on disk must match the current schema version. If it does not, refuse re-verify and emit `action_required: schema_version_mismatch` to the conversation so the user knows a manual migration is needed.

## Schema Versioning Rules

The `schema_version` field is an integer. It starts at `1`. The version bumps only on breaking changes:

- A REQUIRED field is removed or renamed.
- An enum value is removed from a bounded type (e.g., dropping `ecosystem` from `resolution_method`).

Additive changes do NOT bump the version:

- Adding a new OPTIONAL field.
- Adding a new value to a bounded enum (e.g., Phase 11 adding `browser-fallback` was planned at schema v1 and does NOT bump).
- Loosening a REQUIRED field to RECOMMENDED.

Downstream consumers (Phase 12 Deploy Pipeline, Phase 6 Evolution, Phase 16 TAP tests) read `schema_version` and refuse to proceed on an unknown major version.
