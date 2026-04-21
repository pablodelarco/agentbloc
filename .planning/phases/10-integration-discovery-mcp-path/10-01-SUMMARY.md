---
phase: 10-integration-discovery-mcp-path
plan: 01
subsystem: integration
tags: [mcp, integration, schema, validator, fixture, arco-rooms, bounded-enum, evidence-protocol, trust-tier, verification-loop, halt-and-name]

# Dependency graph
requires:
  - phase: 09-designer-agent
    provides: ".agentbloc/team/agent-profiles.yaml (Phase 9 D-30 lock: gestor-documental / gestor-cobros / recepcionista agent IDs drive used_by[] resolution in Check 7 of the integration-manifest validator; tools[] arrays per agent are the input contract the Phase 3 4-step search resolves)"
  - phase: 08-business-graph-foundation
    provides: "prose-checklist validator pattern (D-13), silent artifact + rendered table review (D-14), bounded enum discrimination (D-18), three-tier field obligation (Phase 9 D-22), .agentbloc/ artifact hierarchy (D-15)"
provides:
  - ".claude/skills/agentbloc/references/mcp-integration-protocol.md (231 lines) - 4-step search flow + D-34 three-check Verification Loop + D-35 Halt-and-Name + D-38 credential gap + D-39 Evidence Protocol + ASCII Flow Diagram"
  - ".claude/skills/agentbloc/references/mcp-ecosystem-registry.md (142 lines) - curated registry seeded from CLAUDE.md MCP Server Ecosystem tables (15+ entries across 8 categories, HIGH/MEDIUM/LOW trust tiers, v1.0 INTG-04 Trust Tier Criteria)"
  - ".claude/skills/agentbloc/references/integration-manifest-schema.md (168 lines) - D-36 YAML schema + three-tier Field Obligation Matrix + three bounded enums (Resolution Method / Trust Tier / Status) + 8-check Validation Checklist + Emission Protocol + Re-run Behavior + Schema Versioning Rules"
  - ".claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml (189 lines) - canonical 8-tool happy-path fixture covering all 3 MCP resolution methods (3 existing / 3 ecosystem / 2 wrapper)"
  - ".claude/skills/agentbloc/examples/arco-rooms-integration-manifest-failures.yaml (66 lines) - companion failure-path fixture covering D-34 three-check failure modes for Phase 16 TAP replay (plan-eng-review T-2)"
affects: [10-02, 10-03, 11-browser-fallback, 12-deploy-pipeline, 16-e2e-tap-verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Prose-checklist validator inline in schema reference file (D-13 carry-forward) - no external YAML linter, no ajv, no jsonschema; 8 checks enumerated in integration-manifest-schema.md Validation Checklist"
    - "Three bounded enums driving control flow (D-18 pattern applied to MCP path): resolution_method, trust_tier, status"
    - "Three-tier field obligation matrix (REQUIRED / RECOMMENDED / OPTIONAL) per D-22"
    - "Silent YAML artifact + rendered table review (D-14 carry-forward) applied to integration manifest"
    - "ASCII Flow Diagram section in protocol reference (plan-eng-review A-1) showing 4-step search + Verification Loop branches"
    - "Canonical fixture covering happy-path (Task 4) + companion failure-path fixture (Task 5, plan-eng-review T-2) - same pattern v1.0 uses for decision-matrix examples"

key-files:
  created:
    - ".claude/skills/agentbloc/references/mcp-integration-protocol.md (231 lines, Task 1)"
    - ".claude/skills/agentbloc/references/mcp-ecosystem-registry.md (142 lines, Task 2)"
    - ".claude/skills/agentbloc/references/integration-manifest-schema.md (168 lines, Task 3)"
    - ".claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml (189 lines, Task 4)"
    - ".claude/skills/agentbloc/examples/arco-rooms-integration-manifest-failures.yaml (66 lines, Task 5)"
  modified: []

key-decisions:
  - "D-31 three-reference split: mcp-integration-protocol.md (imperative flow) + mcp-ecosystem-registry.md (declarative lookup) + integration-manifest-schema.md (output contract). Mirrors Phase 8/9 single-source-of-truth-per-shape principle."
  - "D-34 three-check Verification Loop: Ping (tools/list responds) + Scope match (tools intersect agent tools[] AND credentials present) + Shape probe (response shape matches agent outputs.schema). Encoded as prose-checklist Checks 4-6 in the schema validator."
  - "D-35 Halt-and-Name Protocol: failure writes VERIFICATION-FAILED.md at .agentbloc/integrations/<tool-id>/ + manifest entry status=failed + failure_reason names specific check + Phase 3 gate blocked + targeted conversation. Failure fixture (Task 5) covers all 3 failure modes."
  - "D-36 separate artifact at .agentbloc/integrations/integration-manifest.yaml (not an agent-profiles.yaml extension). Keeps Designer output idempotent across re-verification runs; Phase 12 Deploy Pipeline has single source for is-ready state."
  - "D-39 evidence protocol extends v1.0 INTG-03 with four MCP-specific RECOMMENDED fields: tools_declared (tools/list probe result), required_scopes (credential declarations), healthcheck_at (ISO timestamp when all three D-34 checks last passed), trust_tier (HIGH/MEDIUM/LOW re-evaluated each verification). Missing any field emits [UNVERIFIED] per v1.0 INTG-06."
  - "D-42 canonical fixture distribution: 8 tools (>=3 existing, >=3 ecosystem, >=2 wrapper, zero browser-fallback per Phase 11 scope, zero failed per happy-path scope). Phase 16 TAP replays this exact fixture against arco-rooms-agent-profiles.yaml."
  - "plan-eng-review T-2 addition: companion failure-path fixture (Task 5) so Phase 16 can validate Halt-and-Name end-to-end instead of prose-only documentation."

patterns-established:
  - "Schema reference file pattern (structural twin of business-graph-schema.md + agent-profile-schema.md): H1 + blockquote scope note + TOC + When This Applies + Schema Definition fenced yaml + Field Obligation Matrix + Bounded Enum tables + Validation Checklist + Emission Protocol + Re-run Behavior + Schema Versioning Rules. 160-280 line budget."
  - "Protocol reference file pattern (structural twin of orchestration-patterns.md): H1 + TOC + When This Applies + imperative flow per step + Verification Loop + Halt-and-Name + Evidence Protocol + Flow Diagram + Quick Reference. 140-260 line budget."
  - "Registry reference file pattern (structural twin of frameworks.md): H1 + TOC + 8 category tables + Trust Tier Criteria + Quick Reference. 140-260 line budget."
  - "Canonical fixture pair pattern: happy-path + failure-path as sibling files in examples/, same YAML dialect, same agent-id references, valid-schema-but-distinct-downstream-handling. Phase 16 TAP replays both."

requirements-completed: [INTEG-01, INTEG-02, INTEG-04, INTEG-06]

# Metrics
duration: ~40min
completed: 2026-04-21
---

# Phase 10 Plan 1: Integration Discovery MCP Path Contracts Summary

**Three new reference files (mcp-integration-protocol.md / mcp-ecosystem-registry.md / integration-manifest-schema.md, 541 lines total) plus two canonical fixtures (arco-rooms-integration-manifest.yaml happy-path 189 lines + arco-rooms-integration-manifest-failures.yaml companion 66 lines) materialize the MCP-first 4-step integration discovery protocol (D-31), the D-34 three-check Verification Loop, the D-35 Halt-and-Name Protocol, the D-36 .agentbloc/integrations/integration-manifest.yaml contract, and the D-42 Arco Rooms canonical fixture so Plan 10-02 (mcp-builder skill) and Plan 10-03 (SKILL.md + phase-3-integration.md wiring) can cite these references without duplicating the contract.**

## Performance

- **Duration:** ~40 min (Tasks 1-3 by sibling agent; Tasks 4-5 + SUMMARY by this agent)
- **Tasks:** 5/5
- **Files created:** 5 (3 references + 2 fixtures)

## Accomplishments

- Created `.claude/skills/agentbloc/references/mcp-integration-protocol.md` (231 lines) with the 4-step search flow (existing -> ecosystem -> wrapper -> browser-fallback/failed), D-34 three-check Verification Loop, D-35 Halt-and-Name Protocol referencing VERIFICATION-FAILED.md, D-38 `.env.example` auto-append rule, D-39 Evidence Protocol with four MCP-specific fields, ASCII Flow Diagram (plan-eng-review A-1), and Quick Reference.
- Created `.claude/skills/agentbloc/references/mcp-ecosystem-registry.md` (142 lines) with 15+ curated MCP server entries across 8 categories (Communication, Google Workspace, E-Commerce, CRM, Accounting, Browser, Development, Workflow) seeded from the CLAUDE.md "MCP Server Ecosystem: Verified Available" tables, HIGH/MEDIUM/LOW trust tiers populated, and v1.0 INTG-04 Trust Tier Criteria section carried forward.
- Created `.claude/skills/agentbloc/references/integration-manifest-schema.md` (168 lines) with the D-36 YAML Schema Definition, three-tier Field Obligation Matrix (REQUIRED/RECOMMENDED/OPTIONAL), three bounded enums (Resolution Method / Trust Tier / Status), 8-check Validation Checklist wiring D-34 three checks into Checks 4-6, Emission Protocol targeting `.agentbloc/integrations/integration-manifest.yaml` + `mcp_integrations_verified` sub-gate, Re-run Behavior (default: re-verify additive), and Schema Versioning Rules.
- Created `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml` (189 lines) as the canonical happy-path fixture satisfying all 8 Validation Checklist checks: 8 tool entries distributed per D-42 (3 existing / 3 ecosystem / 2 wrapper / 0 browser-fallback / 0 failed), every REQUIRED field populated, every RECOMMENDED field populated except where intentionally empty (e.g., `required_scopes: []` on playwright-mcp because browser automation needs no credentials), every `used_by[]` resolves to one of the 3 Phase 9 agent IDs.
- Created `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest-failures.yaml` (66 lines) as the companion failure-path fixture (plan-eng-review T-2): 3 entries, one per D-34 check, every entry `status: failed` with populated `failure_reason` and `null` `healthcheck_at`. Phase 16 TAP replays this alongside the happy-path to validate Halt-and-Name end-to-end.
- Satisfied requirements INTEG-01 (existing .mcp.json path), INTEG-02 (ecosystem registry path), INTEG-04 (three-check verification), INTEG-06 (evidence protocol) via protocol sections + schema checks + fixture entries; INTEG-03 (wrapper generation) satisfied by sibling Plan 10-02; INTEG-05 (Halt-and-Name) partially satisfied here (schema `status: failed` enum + failure fixture), further fleshed out by Plan 10-03's SKILL.md sub-gate wiring.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create mcp-integration-protocol.md** - `915f575` (feat)
2. **Task 2: Create mcp-ecosystem-registry.md** - `fc4d919` (feat)
3. **Task 3: Create integration-manifest-schema.md** - `10666ec` (feat)
4. **Task 4: Create arco-rooms-integration-manifest.yaml happy-path fixture** - `3895dc4` (feat)
5. **Task 5: Create arco-rooms-integration-manifest-failures.yaml companion** - `cd10257` (feat)

**Plan metadata:** Pending. This SUMMARY commit is next (`docs(10-01): complete Phase 10 contracts plan (5 tasks, 5 files, all REQUIRED + RECOMMENDED fields populated)`).

## Files Created

| # | Path | Lines | Purpose |
|---|------|-------|---------|
| 1 | `.claude/skills/agentbloc/references/mcp-integration-protocol.md` | 231 | Imperative flow reference: 4-step search + Verification Loop + Halt-and-Name + Evidence Protocol |
| 2 | `.claude/skills/agentbloc/references/mcp-ecosystem-registry.md` | 142 | Declarative lookup reference: curated registry, trust-tiered |
| 3 | `.claude/skills/agentbloc/references/integration-manifest-schema.md` | 168 | Output contract reference: schema + enums + 8-check validator |
| 4 | `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml` | 189 | Canonical happy-path fixture (8 tools, all 3 resolution methods) |
| 5 | `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest-failures.yaml` | 66 | Companion failure-path fixture (3 D-34 failure modes) |

**Total:** 796 lines across 5 files.

## Final Schema Shape

Copied from `integration-manifest-schema.md` Schema Definition section:

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

## Bounded Enum Tables

### Resolution Method Bounded Enum

| Enum Value | Definition | Required Sub-fields | Example |
|-----------|-----------|---------------------|---------|
| `existing` | Tool already in `.mcp.json` before Phase 3 ran | `mcp_server.installed_via: ".mcp.json existing"` | `{resolution_method: existing, mcp_server: {installed_via: ".mcp.json existing"}}` |
| `ecosystem` | Tool resolved via mcp-ecosystem-registry.md; user approved `npx -y <package>` install (D-37) | `mcp_server.installed_via: "npx -y <package>"` | `{resolution_method: ecosystem, mcp_server: {installed_via: "npx -y @smithery-ai/gmail-mcp"}}` |
| `wrapper` | Tool resolved via mcp-builder skill generating at `.mcp/generated/<tool-id>/` (D-33) | `mcp_server.package: ".mcp/generated/<tool-id>/"`, `mcp_server.installed_via: "wrapper"` | `{resolution_method: wrapper, mcp_server: {package: ".mcp/generated/bbva-mcp/", installed_via: "wrapper"}}` |
| `browser-fallback` | Phase 11 scope (BROWSER-01..12); reserved enum slot only in Phase 10 | (populated by Phase 11) | `{resolution_method: browser-fallback, status: pending}` |
| `failed` | None of Steps 1-4 resolved; Halt-and-Name Protocol triggered per D-35 | `failure_reason` populated with specific Check number | `{resolution_method: failed, status: failed, failure_reason: "Check 2: scope gmail.modify missing"}` |

### Trust Tier Bounded Enum

| Enum Value | Criteria | When to Pick |
|-----------|----------|--------------|
| `HIGH` | Official vendor-maintained OR community with >500 stars + commit within 90 days | Auto-pass proposal; default-yes approval |
| `MEDIUM` | Community 100-500 stars, commit within 180 days, clear docs | Propose with evidence; user approval required |
| `LOW` | <100 stars OR >180 days since last commit OR unclear maintainer OR no docs | Surface warning; suggest wrapper alternative; explicit user override required |

### Status Bounded Enum

| Enum Value | Definition | Phase 3 gate behavior |
|-----------|-----------|------------------------|
| `pending` | Tool entry created but Verification Loop not yet complete | Gate stays `pending` until all `tools[]` reach `verified` or `failed` |
| `verified` | All three D-34 checks (Ping / Scope match / Shape probe) passed; `healthcheck_at` stamped | Gate can transition to `approved` when every entry is verified |
| `failed` | One or more D-34 checks failed; Halt-and-Name Protocol triggered | Gate `blocked`; user must resolve (add scope, add credential, or edit agent tool list) before re-verification |

## 8-Check Validation Checklist

From `integration-manifest-schema.md` Validation Checklist section:

1. **Check 1** (REQUIRED): `schema_version` present and equals current version (`1`). FAIL: auto-set `schema_version: 1`.
2. **Check 2** (REQUIRED): Every `tools[].tool_id` unique, kebab-case, and matches an entry in agent-profiles.yaml agents[].tools[]. FAIL: remove dead entry or re-run Step 1 for missing tool.
3. **Check 3** (REQUIRED): Every `tools[].resolution_method` in `{existing, ecosystem, wrapper, browser-fallback, failed}` with required sub-fields populated per Resolution Method Bounded Enum. FAIL: surface specific tool + missing sub-field.
4. **Check 4** (REQUIRED, D-34 Ping): Every verified entry has `evidence.tools_declared[]` length >= 1. FAIL: re-run Ping check; on Ping fail set `status: failed`, write VERIFICATION-FAILED.md.
5. **Check 5** (REQUIRED, D-34 Scope match): Every verified entry has (a) `evidence.tools_declared[]` intersecting `used_by[]` agents' tools[], AND (b) every `evidence.required_scopes[]` entry present in `.env` OR stubbed in `.env.example`. FAIL on scope: auto-append env var to `.env.example` with inline comment; halt with specific var named. FAIL on tool overlap: surface gap, propose wrapper switch.
6. **Check 6** (REQUIRED, D-34 Shape probe): Every verified entry has been dry-run called and response shape matches `used_by` agents' `outputs.schema`. FAIL: surface both shapes side-by-side; block emission.
7. **Check 7** (REQUIRED): Every `tools[].used_by[]` agent id resolves to an entry in agent-profiles.yaml agents[]. FAIL: reject YAML; re-read agent-profiles.yaml.
8. **Check 8** (WARN, not FAIL): RECOMMENDED fields populated or explicitly `null`. WARN: emit with `null` defaults; flag missing as `[UNVERIFIED]` per v1.0 INTG-06.

Checks 1-7 block emission. Check 8 emits with warnings.

## Happy-Path Fixture Tool Distribution (Task 4)

All 8 tools from `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml`:

| # | tool_id | resolution_method | package | trust_tier | used_by | status |
|---|---------|-------------------|---------|------------|---------|--------|
| 1 | playwright-mcp | existing | @playwright/mcp | HIGH | gestor-documental | verified |
| 2 | google-workspace-mcp | existing | google_workspace_mcp | MEDIUM | gestor-documental | verified |
| 3 | telegram-mcp | existing | telegram-mcp | MEDIUM | recepcionista | verified |
| 4 | gmail-mcp | ecosystem | @smithery-ai/gmail-mcp | MEDIUM | gestor-documental | verified |
| 5 | google-sheets-mcp | ecosystem | mcp-google-sheets | MEDIUM | gestor-cobros | verified |
| 6 | notion-mcp | ecosystem | notion-mcp | MEDIUM | recepcionista | verified |
| 7 | bank-mcp | wrapper | .mcp/generated/bank-mcp/ | MEDIUM | gestor-cobros | verified |
| 8 | mapfre-api | wrapper | .mcp/generated/mapfre-api/ | MEDIUM | gestor-documental | verified |

**Distribution:** `existing: 3`, `ecosystem: 3`, `wrapper: 2`, `browser-fallback: 0`, `failed: 0`. Satisfies D-42 exactly. All 3 Phase 9 agent IDs (gestor-documental, gestor-cobros, recepcionista) appear in at least one used_by[] (Check 7 passes).

## Failure-Path Fixture Entries (Task 5)

All 3 tools from `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest-failures.yaml`:

| # | tool_id | D-34 Check | used_by | failure_reason (one-liner) |
|---|---------|-----------|---------|----------------------------|
| 1 | stripe-mcp | Check 1 (Ping) | gestor-cobros | Server does not respond to tools/list after 30s timeout; npx install succeeded but binary does not start cleanly |
| 2 | gmail-modify-mcp | Check 2 (Scope match) | recepcionista | GOOGLE_OAUTH_TOKEN present but lacks gmail.modify scope; agent needs send_message; resolution options per D-38; .env.example auto-appended |
| 3 | bank-mcp-experimental | Check 3 (Shape probe) | gestor-cobros | list_transactions returned {txns, cursor} but agent outputs.schema expects {transactions, next_page}; resolution options: regenerate wrapper OR update schema |

All 3 entries: `status: failed`, `healthcheck_at: null`, `failure_reason` populated with specific Check number + specific gap. Phase 16 TAP replays alongside happy-path fixture to validate D-35 Halt-and-Name end-to-end (plan-eng-review T-2).

## Requirement Coverage

| Requirement | Satisfied By |
|-------------|--------------|
| **INTEG-01** (existing .mcp.json path) | mcp-integration-protocol.md Step 1 section; integration-manifest-schema.md Resolution Method Bounded Enum `existing` row; happy-path fixture has 3 existing entries (playwright-mcp, google-workspace-mcp, telegram-mcp) |
| **INTEG-02** (ecosystem registry path) | mcp-integration-protocol.md Step 2 section + D-37 approval gate; mcp-ecosystem-registry.md is the lookup table (15+ entries, 8 categories); happy-path fixture has 3 ecosystem entries (gmail-mcp, google-sheets-mcp, notion-mcp) |
| **INTEG-03** (wrapper generation) | Satisfied by sibling Plan 10-02 (mcp-builder skill). This plan's fixture has 2 wrapper entries (bank-mcp, mapfre-api) exercising the contract shape. |
| **INTEG-04** (three-check verification) | mcp-integration-protocol.md Verification Loop section with Ping/Scope match/Shape probe; integration-manifest-schema.md Validation Checklist Checks 4-6 wire them in; failure fixture (Task 5) covers all 3 check failures end-to-end |
| **INTEG-05** (Halt-and-Name on failure) | mcp-integration-protocol.md Halt-and-Name Protocol section referencing VERIFICATION-FAILED.md; integration-manifest-schema.md Status Bounded Enum `failed` row + `failure_reason` field; failure fixture embodies the protocol. Plan 10-03 completes wiring into SKILL.md sub-gate. |
| **INTEG-06** (evidence protocol) | mcp-integration-protocol.md Evidence Protocol section extends v1.0 INTG-03 with D-39 fields; integration-manifest-schema.md evidence sub-field is REQUIRED with trust_tier + RECOMMENDED with tools_declared/required_scopes/healthcheck_at/last_commit/publisher; both fixtures populate evidence rows |

## Decisions Made

None. Plan executed exactly as specified. All 5 task action blocks were emitted verbatim, including the two YAML fixtures whose exact contents the plan prescribed byte-for-byte. Tool distribution in the happy-path fixture matches D-42 exactly (3 existing / 3 ecosystem / 2 wrapper); failure fixture covers all 3 D-34 checks per plan-eng-review T-2.

## Deviations from Plan

None - plan executed exactly as written.

Tasks 1-3 (the three reference files) were executed by a sibling agent in a prior session; commit hashes 915f575, fc4d919, 10666ec verified present. Tasks 4-5 + SUMMARY executed in this session.

The plan's Task 4 and Task 5 `<action>` blocks provided complete YAML content verbatim. Both fixtures were copied byte-for-byte with only plan-authored content; zero adjustments to schema, distribution, agent mapping, or failure_reason wording. Zero em-dashes introduced.

**Total deviations:** 0
**Impact on plan:** None. Clean execution.

## Issues Encountered

None.

## Self-Check Verification

All plan-level acceptance criteria (14 phase-level checks from 10-01-PLAN.md `<verification>` block + per-task acceptance criteria) verified post-commit:

- All 3 reference files exist at planned paths with H2 counts meeting minimums (protocol 11, registry 12, schema 11)
- All 3 reference files within line-count bounds (protocol 231 in 140-260; registry 142 in 140-260; schema 168 in 160-280)
- Happy-path fixture parses as valid YAML; 8 tools; distribution 3/3/2; zero browser-fallback; zero failed; every used_by resolves to Phase 9 agent IDs; zero em-dashes
- Failure-path fixture parses as valid YAML; 3 tools; all status=failed; all failure_reason populated; all healthcheck_at=null; every used_by resolves to Phase 9 agent IDs; line count 66 in 40-90 bound; zero em-dashes
- ASCII Flow Diagram section present in mcp-integration-protocol.md (plan-eng-review A-1 satisfied)
- All 4 plan-assigned requirements (INTEG-01, INTEG-02, INTEG-04, INTEG-06) traced to specific sections + fixture entries; INTEG-03 satisfied by sibling Plan 10-02; INTEG-05 partially satisfied (schema + fixture), wiring completes in Plan 10-03

**Post-commit checks:**
- `git log --oneline | grep "10-01"` lists all 5 task commits: `cd10257`, `3895dc4`, `10666ec`, `fc4d919`, `915f575`
- Deletion scan: `git diff --diff-filter=D --name-only HEAD~2 HEAD` returns empty (no deletions)
- Untracked scan: no new non-screenshot files left outside the 5 task commits

## Handoff Note for Plan 10-02

Plan 10-02 is already COMPLETE (commits `376d179` + `9500107`, `.claude/skills/mcp-builder/SKILL.md` at 150 lines, `10-02-SUMMARY.md` shipped). Cross-links between Plan 10-01 and Plan 10-02 artifacts resolve as intended:

- mcp-builder SKILL.md cites `integration-manifest-schema.md` + `mcp-integration-protocol.md` under its Reference Implementation / Cross-reference section; both targets exist.
- mcp-builder generates wrappers at `.mcp/generated/<tool-id>/` matching the Resolution Method Bounded Enum `wrapper` row in integration-manifest-schema.md: `mcp_server.package: ".mcp/generated/<tool-id>/"` + `mcp_server.installed_via: "wrapper"`. The happy-path fixture's 2 wrapper entries (bank-mcp, mapfre-api) demonstrate the exact output shape.
- The generated wrapper's README.md is the source truth for `tools_declared` + `required_scopes` that Phase 3 Verification Loop populates. mcp-builder's `<output_contract>` mandates this so the D-39 evidence fields are populable without manual input.

No post-integration adjustment required between 10-01 and 10-02.

## Handoff Note for Plan 10-03

Plan 10-03 (SKILL.md + phase-3-integration.md surgical wiring) depends on this plan's artifacts:

- **SKILL.md Phase 3 unconditional-load list:** add all three new references (`mcp-integration-protocol.md`, `mcp-ecosystem-registry.md`, `integration-manifest-schema.md`) by full path. Paths are stable - ship as specified.
- **SKILL.md `mcp_integrations_verified` sub-gate (D-41):** maps to the 8-check Validation Checklist in `integration-manifest-schema.md`. Gate approves when Checks 1-7 pass AND every entry has `status: verified` with populated `healthcheck_at`. Check 8 emits warnings but does not block.
- **SKILL.md Phase 4 precondition (D-41):** verify `.agentbloc/integrations/integration-manifest.yaml` exists AND every entry has `status: verified` with populated `healthcheck_at`. If any entry is `status: failed` or missing, return state bar to Phase 3 `pending`.
- **phase-3-integration.md Priority 1 MCP section (D-40):** delegate full detail to `mcp-integration-protocol.md` via See-line. Preserve summary in place so scanners understand the contract without jumping files. Demote v1.0 Priority 1 (Official API) to Priority 2. Mark Priority 3 (Playwright) with `[Phase 11 scope]` + See-line forward.
- **Fixture usage for Plan 10-03 verification:** the happy-path fixture (`arco-rooms-integration-manifest.yaml`) is the canonical "what the gate emits on success" reference; the failure fixture (`arco-rooms-integration-manifest-failures.yaml`) is the canonical "what the gate emits on Halt-and-Name" reference. 10-03 can cite both by path.
- **Cross-link shape:** all new references already use shorthand relative paths (e.g., `[phase-3-integration.md](phase-3-integration.md)`) consistent with existing agentbloc references. 10-03 surgical edits to `phase-3-integration.md` must preserve this convention.

**Ordering:** Plan 10-03 is the Wave 2 wiring plan and depends on both 10-01 (this plan, now complete) and 10-02 (complete). Plan 10-03 is unblocked.

## Threat Flags

None. Plan 10-01 ships reference files + YAML fixtures only; no code, no network surface, no new credentials or file-access patterns. All trust-boundary surface documented in the plan's `<threat_model>` is encoded in-reference:

- **T-10-01 (stale-registry drift):** mitigated by `mcp-ecosystem-registry.md` last-commit column + `evidence.last_commit` RECOMMENDED field + `healthcheck_at` timestamp. Phase 6 Evolution reads these to trigger re-verification.
- **T-10-03 (scope over-grant):** mitigated by `integration-manifest-schema.md` Check 5 Scope match and evidence.required_scopes RECOMMENDED field; D-38 credential gap protocol writes `.env.example` stubs with inline comments.
- **T-10-04 (silent verification bypass):** mitigated by `integration-manifest-schema.md` Status Bounded Enum forbidding `status: verified` without `healthcheck_at`; failure fixture embodies the Halt-and-Name path.
- **T-10-06 (prompt injection in MCP ingested content):** mitigated by mcp-integration-protocol.md Evidence Protocol referencing `prompt-injection.md` for injection-defense layer assignment; carries forward v1.0 INTG-06.

No new threat surface introduced by this plan beyond what the plan's `<threat_model>` catalogued.

## Next Phase Readiness

- **Plan 10-02 (Wave 1 sibling):** COMPLETE. mcp-builder skill exists at `.claude/skills/mcp-builder/SKILL.md`; forward cross-links into this plan's references resolve.
- **Plan 10-03 (Wave 2):** READY. All three references + both fixtures exist at stable paths; sub-gate vocabulary (`mcp_integrations_verified`), output path (`.agentbloc/integrations/integration-manifest.yaml`), and companion references are ready to cite verbatim.
- **Phase 11 (Browser Fallback):** READY for Step 4 implementation. `resolution_method: browser-fallback` enum value is reserved + documented; `phase-3-integration.md` Priority 3 marker is ready for Plan 10-03 to annotate with the `[Phase 11 scope]` See-line forward.
- **Phase 12 Deploy Pipeline:** READY to consume `.agentbloc/integrations/integration-manifest.yaml`. Schema is stable at `schema_version: 1`; Phase 12 reads `mcp_server.{package, installed_via}` + `resolution_method` + `status` + `healthcheck_at` to decide `.mcp.json` merges + ClaudeClaw job config generation.
- **Phase 16 E2E TAP verification:** READY to replay both fixtures. Running Phase 3's 4-step search against `arco-rooms-agent-profiles.yaml` should produce a manifest structurally equivalent to `arco-rooms-integration-manifest.yaml` (same 8 entries, same distribution, same used_by mapping, timestamps differ); forcing the 3 failure modes should produce entries matching `arco-rooms-integration-manifest-failures.yaml` (plan-eng-review T-2).

**Blockers:** None.

---
*Phase: 10-integration-discovery-mcp-path*
*Plan: 10-01*
*Completed: 2026-04-21*

## Self-Check: PASSED
