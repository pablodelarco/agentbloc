# Phase 15: Anticipation Engine , Context

**Gathered:** 2026-04-26
**Mode:** `--auto` lean inline (Claude selected recommended defaults; no subagent spawns; atomic commits per Phase 13/14 precedent)
**Status:** Ready for planning

<domain>
## Problem Statement

The Designer Agent (Phase 9) emits ONLY agents the user explicitly requested via the Business Graph `processes[]` array. Phase 15 adds a second pass: after the requested-agent emission, Designer reads the Business Graph `business.type` field, looks up the type in `references/anticipation-heuristics.md`, and proposes additional `ANTICIPATED`-tagged agents that the business pattern strongly implies but the user did not ask for. Each anticipated agent carries a 1-2 sentence rationale and 3+ evidence sources backing the heuristic.

The user accepts, declines, or defers each anticipated agent. Declines are recorded in `.agentbloc/graph/declined.json` so re-running Designer never re-proposes them. Anticipation degrades silently for business types not in the heuristics map (no hallucinated agents).

This is the consulting-product differentiator. PDF page 12-14 (Anticipation Engine section) cites this as what separates AgentBloc from CrewAI / LangGraph / AG2 / ADK / Mastra / Paperclip , none of those frameworks suggest unrequested agents. AgentBloc is positioned as a proactive AI consultant; without anticipation, it is just an automator.

Phase 15 closes 5 requirements: ANTIC-01 (anticipation pass after requested agents), ANTIC-02 (heuristics reference with evidence), ANTIC-03 (ANTICIPATED tag in proposal), ANTIC-04 (declined.json memory), ANTIC-05 (3+ evidence sources per mapping).

**What Phase 15 emits:**
1. 1 new reference: `anticipation-heuristics.md` (5+ business-type to anticipated-agents mappings, 3+ evidence sources per mapping)
2. 1 new reference: `declined-agents-schema.md` (ANTIC-04 schema for `.agentbloc/graph/declined.json`)
3. 2 new fixtures: `arco-rooms-anticipated-profiles.yaml` (5 agents = 3 requested + 2 anticipated) + `arco-rooms-declined.json` (sample decline)
4. 1 surgical extension: `agent-profile-schema.md` adds 3 OPTIONAL anticipation fields per agent (`anticipated: bool` + `anticipation_rationale: string` + `anticipation_sources: list`) + Validation Check 9
5. 1 subagent extension: `.claude/agents/designer-agent.md` replaces `<scope_exclusion>` block with `<anticipation_pass>` block describing the new behavior + declined.json read protocol
6. 2 surgical edits to existing references: `phase-2-design.md` inserts Step 8.5 Anticipation Pass H2 + updates Step 8 Scope note + adds Quick Reference row; `SKILL.md` adds See-line for anticipation-heuristics.md + Phase 2 Summary Gate paragraph extension

Phase 15 does NOT emit a new subagent. The anticipation pass is an EXTENSION of the existing Designer Agent (Phase 9 D-21), not a sibling subagent. The same fork-context isolation + scoped tools apply. No new Bash allow-list entries.

</domain>

<decisions>
## Implementation Decisions

### Inherited from Phases 8-14 + v1.0 (carry forward , do not re-decide)

The following are LOCKED upstream and MUST flow through Phase 15:

- **D-21 (Designer subagent at .claude/agents/designer-agent.md, context=fork, scoped tools, no Bash):** Phase 15 extends this same subagent surgically; no new subagent file.
- **D-26 (conversational edits via surgical patches):** Decline of an anticipated agent is a conversational edit; Designer applies the patch in-place AND appends to `.agentbloc/graph/declined.json`.
- **D-30 (Arco Rooms canonical: 3 requested + 2 anticipated agents):** Phase 15 anticipated agents are `analista-rentabilidad` + `gestor-incidencias` per Phase 9 SCOPE-EXCLUSION lock. The fixture in Plan 15-01 Task 2 ships the full 5-agent team.
- **D-58 (context-budget):** SKILL.md gains ONE new See-line (anticipation-heuristics.md). The declined-agents-schema.md is subagent-only (Designer reads it inside fork; not user-facing) and per D-58 does NOT appear in SKILL.md.
- **D-83 (surgical-edit discipline):** Plan 15-02 Tasks 3-5 insert only; never rewrites upstream content. The exception is `<scope_exclusion>` block in designer-agent.md , its semantic intent is REPLACED by `<anticipation_pass>` block (the lock release IS the unblock). All other Designer prose preserved verbatim.
- **Schema Versioning Rules (agent-profile-schema.md):** Adding 3 OPTIONAL fields to agent-profiles.yaml is an ADDITIVE change; `schema_version` stays at `1` per the rule "adding a new OPTIONAL field does NOT bump the version." Backward-compatible: Phase 9-emitted YAMLs without anticipation fields continue to validate.

### New decisions (autonomous, per PDF + REQUIREMENTS + prior-phase patterns)

#### Anticipation pass placement (resolves ANTIC-01, ANTIC-03)

- **D-99 (Anticipation pass runs INSIDE Designer Agent's same fork-context invocation, AFTER Validation Checklist passes for requested agents but BEFORE the YAML is written and the rendered table returns to the main session):** This means a single Designer invocation emits a single agent-profiles.yaml with both requested + anticipated agents in one file. Anticipated agents are differentiated only by the `anticipated: true` flag + `anticipation_rationale` + `anticipation_sources` fields.

  Why same-invocation: spawning a separate "anticipation-agent" subagent would (a) duplicate the Business Graph read, (b) duplicate the schema-validation walk, (c) require a second main-session round-trip. The user-facing pause point is the rendered TABLE (Step 8 cards), not the subagent invocation. Anticipation must surface in the SAME table the user reviews; per Phase 14 D-88 precedent (briefing-agent runs as deployed agent, not internal subagent) we minimize subagent-spawn overhead.

  Why before YAML write: the anticipation fields go INTO the same YAML as the requested agents. Single file, one validation pass, one rendered TABLE.

  Alternatives considered:
  | Option | Selected |
  |---|---|
  | A. Separate anticipation-agent subagent invoked after Designer | Rejected , doubles invocations, doubles Business Graph reads, splits the user review into two table presentations |
  | B. Separate anticipated-profiles.yaml file alongside agent-profiles.yaml | Rejected , Phase 12 deploy-engine would need to merge two files; single-file pattern matches Phase 14 D-98 schema-extension precedent |
  | C. Anticipation pass inside same Designer invocation, single agent-profiles.yaml output | ✓ |
  | D. Anticipation as a Phase-2-design.md user-confirmation question only (no YAML representation) | Rejected , Phase 12 deploy-engine + Phase 14 briefing-agent both need to know which agents are anticipated for downstream behavior (e.g., briefing-agent skips anticipated agents declined post-deploy) |

#### Heuristics evidence rigor (resolves ANTIC-02, ANTIC-05)

- **D-100 (anticipation-heuristics.md ships with 5+ business-type to anticipated-agents mappings; each mapping cites 3+ independent sources from the set: industry reports, regulatory documents, framework docs (CrewAI examples, n8n templates), academic papers, vendor case studies, or peer-reviewed trade publications):** Sources MUST be independent (not three blog posts citing each other). The bar is consulting-product credibility , a non-technical user who clicks a citation should land on a reputable resource, not a chain of low-trust mirrors.

  Initial mappings shipped in v2.0:
  1. **rental-property-management** -> Profitability Analyst + Incident Tracker (canonical Arco Rooms case)
  2. **ecommerce** -> Returns Analyst + Inventory Forecaster
  3. **freelance-services** -> Cashflow Forecaster + Lead Pipeline Tracker
  4. **restaurant** -> Inventory Reconciler + Reputation Monitor
  5. **professional-services** (consulting / agency / law) -> Utilization Tracker + Renewal Anticipator

  Future mappings ship as additive updates (new mappings = new H2 sections in anticipation-heuristics.md, no schema bump). Business types not in the map degrade silently (Designer skips the anticipation pass entirely; ANTIC's "no hallucination" success criterion).

  **Rationale section per mapping:** Each mapping is a 4-block H2 section: (a) `## Business type: <type>`, (b) `### Anticipated agents` table with role + goal + 1-line rationale, (c) `### Evidence sources` numbered list with at least 3 entries (URL + last-checked date + 1-line summary), (d) `### When NOT to anticipate` paragraph (explicit guardrails).

  Alternatives considered:
  | Option | Selected |
  |---|---|
  | A. Single source per mapping (lower bar) | Rejected , consulting-product credibility demands triangulation; ANTIC-05 explicitly requires 3+ |
  | B. 5+ sources per mapping (higher bar) | Rejected , slows initial map authoring without proportional credibility gain; 3 is the canonical "well-supported" threshold in market research |
  | C. 3+ independent sources per mapping (current decision) | ✓ |
  | D. No evidence requirement; trust Claude's training data | Rejected , defeats the consulting-product positioning; PDF page 13 cites evidence-backing as the differentiator |

#### Schema extension (resolves ANTIC-03)

- **D-101 (agent-profile-schema.md gains 3 OPTIONAL anticipation fields per agent: `anticipated: boolean` (default false), `anticipation_rationale: string | null` (1-2 sentence narrative), `anticipation_sources: array<string> | null` (URL list with min length 3 when `anticipated: true`)):** Backward-compatible per Schema Versioning Rules; `schema_version` stays at 1.

  The Validation Checklist gains Check 9 (RECOMMENDED tier; warns but does not block emission):
  > **Check 9 (WARN, not FAIL): For every agent with `anticipated: true`, both `anticipation_rationale` non-null AND `anticipation_sources` array length >= 3.**
  > WARN: Emit with the gap; flag in the rendered table so user sees `ANTICIPATED (rationale missing)` and can ask Designer to add it.

  Why RECOMMENDED not REQUIRED: a user editing an anticipated agent into existence via conversational edit (e.g., "add a profitability analyst") may not supply rationale + 3 sources up front; Designer should accept the partial and emit the warning so the user iterates. Forcing REQUIRED would block low-friction conversational additions , wrong friction in the wrong place. The CONSULTING-PRODUCT credibility gate is the heuristics map (anticipation-heuristics.md), not the per-agent metadata; if the user manually adds an unrelated agent, it is THEIR agent, not AgentBloc's anticipation.

  When Designer auto-emits an anticipated agent FROM the heuristics map: rationale + 3 sources are ALWAYS populated (the map IS the source of truth). The WARN tier covers the conversational-edit path only.

  Alternatives considered:
  | Option | Selected |
  |---|---|
  | A. Single `anticipated: bool` flag, rationale + sources stored in heuristics map only | Rejected , rationale is per-instance (auto-emitted Profitability Analyst for Arco Rooms vs. user-added one differ); per-agent storage matches Phase 14 D-98 metadata-on-agent pattern |
  | B. REQUIRED-tier validation on rationale + sources | Rejected , blocks low-friction conversational addition; wrong friction location |
  | C. RECOMMENDED-tier with WARN + table flag | ✓ |
  | D. New top-level `anticipations:` block siblings to `agents:` | Rejected , splits a single agent's identity across two YAML sections; Phase 12 deploy-engine + Phase 14 briefing-agent would each need to merge; per-agent storage is simpler |

#### Decline memory (resolves ANTIC-04)

- **D-102 (declined.json lives at `.agentbloc/graph/declined.json` , sibling to `.agentbloc/graph/business-graph.json`; append-only JSON array; each entry records `agent_id` + `business_type` + `declined_at` ISO-8601 + `reason` (free-text) + `correlation_id` (Designer invocation that proposed it)):** Designer reads this file at invocation start (after the 5 mandatory reads in the existing CRITICAL: Mandatory Initial Read block); any entry with `agent_id` matching a heuristics-map proposal is filtered out before adding to the rendered table.

  **Why sibling to business-graph.json:** the decline memory is BUSINESS-GRAPH-LEVEL state, not team-level. If the user changes their team via conversational edits (rename, merge, drop a requested agent), the decline of an anticipated agent should persist; it is a fact about THIS BUSINESS'S preferences, not THIS TEAM's instance. Re-running Designer against the same Business Graph months later (e.g., post v2.5 capability scan) honors the decline.

  **Why append-only:** matches Phase 14 D-87 jsonl-log-schema pattern (append-only, never rewritten; trace integrity preserved). User can manually edit the file to UN-decline (delete entries) if they change their mind, but Designer never auto-removes entries.

  **Format choice (JSON not JSONL):** declined.json is read once at Designer invocation start, not append-streamed during agent execution. Single-array JSON file is more debuggable for a low-frequency artifact. Phase 14 D-87 chose JSONL specifically for high-volume log streams; ANTIC-04 doesn't fit that profile.

  Alternatives considered:
  | Option | Selected |
  |---|---|
  | A. `.agentbloc/team/declined.json` (team-level) | Rejected , decline is business-level not team-level; persists across team regenerations |
  | B. Inline declined-agents in agent-profiles.yaml `team.declined_anticipations[]` | Rejected , YAML grows unboundedly with each decline; conflates per-instance team state with persistent business preference |
  | C. `.agentbloc/graph/declined.json` (sibling to business-graph.json), JSON array, append-only (current decision) | ✓ |
  | D. `.agentbloc/graph/declined.jsonl` for symmetry with logs | Rejected , declined is low-frequency / read-mostly; single-array JSON is easier to grep + edit |

#### Surgical edits to existing references (resolves ANTIC-01..05 final wiring)

- **D-103 (Surgical edits follow Phase 14 D-93 + D-83 surgical-edit discipline; insertion-only; SKILL.md gains ONE new See-line per D-58 context-budget):** Plan 15-02 Tasks 3-5 add:

  1. **`.claude/agents/designer-agent.md`:** REPLACE `<scope_exclusion>` block (lines 139-145, the Phase 9 D-30 lock) with new `<anticipation_pass>` block describing: read declined.json after the 5 mandatory reads; after Validation Checklist passes for requested agents, query anticipation-heuristics.md by `business.type`; emit anticipated agents with `anticipated: true` + rationale + sources; filter out any matching declined.json entries; render TABLE with `[ANTICIPATED]` tag prefix on those rows; cite anticipation-heuristics.md in the rendered cards. The block also says: if `business.type` is not present in heuristics map, skip anticipation entirely (no hallucination per ANTIC degrade-silently rule).

  2. **`references/phase-2-design.md`:** Insert new H3 section "Step 8.5: Anticipation Pass" between existing Step 8 (Designer Subagent Invocation) and existing Conversational Editing Flow H2 section. Update the existing line 307 Scope note to remove the "excluded here" caveat and reference the new Step 8.5. Add a Quick Reference row for "Anticipation Pass | ANTIC-01..05 | anticipation-heuristics.md, declined.json, agent-profile-schema.md anticipation fields".

  3. **`SKILL.md`:** Insert ONE new See-line in Phase 2 entry pointing to anticipation-heuristics.md. Extend the Phase 2 Summary Gate paragraph (line 109) to mention that Designer's invocation now includes an anticipation pass that surfaces ANTICIPATED-tagged agents the user can accept / decline / defer. NO sub-gate added (anticipation is part of the existing `agent_profiles_validated` sub-gate; the validation checklist Check 9 is a WARN not a FAIL, so it does not block emission). NO new Phase 5/6 wiring (Phase 12 deploy-engine + Phase 14 briefing-agent already consume agent-profiles.yaml; the new fields are OPTIONAL and existing consumers ignore them).

  Per Phase 13 D-83 surgical-edit discipline: zero rewrites of upstream content; insertion-only edits except for the Designer subagent's `<scope_exclusion>` -> `<anticipation_pass>` semantic replacement (which IS the unblock that Phase 15 ships). All other Designer prose preserved verbatim.

### Claude's Discretion

The following decisions are deferred to plan-time (gsd-planner inline) per Phase 13/14 precedent:

- **Exact line counts per emitted reference** , Plan 15-01 sets per-task budgets based on the depth required (anticipation-heuristics.md probably 200-280L for 5 mappings * 4 blocks each; declined-agents-schema.md probably 60-100L)
- **Order of plan tasks within Plan 15-01 / 15-02** , planner sequences atomically with dependency-aware ordering (15-01 tasks are independent and parallelizable; 15-02 task 3 depends on tasks 1+2 completing because designer-agent.md cites both)
- **Specific Arco Rooms anticipated agent profiles (Analista Rentabilidad + Gestor Incidencias roles, goals, tools, autonomy levels)** , planner pulls from anticipation-heuristics.md rental-property-management mapping + Phase 9 fixture conventions

### Folded Todos

None , Phase 15 scope is fully specified by REQUIREMENTS.md ANTIC category + PDF page 12-14 (Anticipation Engine section) + Phase 9 D-30 scope-exclusion-lock-release; no backlog items relevant.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authoritative scope document

- `.planning/v2.0-PROMPT.pdf` , v2.0 scope; Phase 15 corresponds to the "Anticipation Engine" section (PDF pages 12-14 by section, not by physical page number; search for "anticipation" + "proactive consultant" + "differentiator").

### Requirements

- `.planning/REQUIREMENTS.md` §"Anticipation Engine (ANTIC)" L144-152 (5 reqs)

### Prior-phase context (referenced when conflicts arise)

- `.planning/phases/09-designer-agent/09-CONTEXT.md` , D-21 through D-30 (Designer subagent contracts; Phase 15 extends D-21 in-place; D-30 scope-exclusion replaced by D-99 anticipation pass)
- `.planning/phases/14-autonomy-monitoring-control/14-CONTEXT.md` , D-93 through D-98 (surgical-edit + schema-extension patterns; Phase 15 mirrors D-98 for agent-profile-schema additive extension)

### Existing references consumed at plan time

- `.claude/skills/agentbloc/references/agent-profile-schema.md` , Phase 9 D-22 schema (Phase 15 surgically adds anticipation fields per D-101)
- `.claude/skills/agentbloc/references/phase-2-design.md` , Phase 9 D-29 design protocol (Phase 15 inserts Step 8.5 per D-103)
- `.claude/skills/agentbloc/references/business-graph-schema.md` , Phase 8 BGRAPH-01 schema (Phase 15 reads `business.type` field for anticipation lookup; no schema changes)
- `.claude/skills/agentbloc/examples/arco-rooms-business-graph.json` , Phase 8 fixture (Phase 15 reads `business.type: rental-property-management` to drive Arco Rooms anticipation)
- `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` , Phase 9 fixture (Phase 15 SUPERSEDES with arco-rooms-anticipated-profiles.yaml; the original 3-agent fixture stays as Phase 9 baseline; the new 5-agent fixture is the Phase 16 golden-file)

### Existing subagent consumed as pattern reference

- `.claude/agents/designer-agent.md` , Phase 9 D-21 subagent definition (Phase 15 surgically replaces `<scope_exclusion>` -> `<anticipation_pass>`)

### SKILL.md + main-skill integration

- `.claude/skills/agentbloc/SKILL.md` , Phase 15 surgical wiring per D-103 (one new Phase 2 See-line + Summary Gate paragraph extension; no new sub-gate); follows Phase 14 D-93 surgical-edit discipline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Phase 9 designer-agent.md (145 lines):** Already has `<output_contract>` returning rendered TABLE + cards + ASCII diagram. Phase 15 anticipation pass writes anticipated rows INTO the same table (with `[ANTICIPATED]` prefix); cards gain `Rationale:` + `Evidence:` sub-bullets when `anticipated: true`. No table or card schema changes; insertion-only.
- **Phase 9 agent-profile-schema.md Validation Checklist (Checks 1-8):** Phase 15 adds Check 9 at the WARN tier per D-101.
- **Phase 9 phase-2-design.md Step 8 (designer subagent invocation):** Phase 15 inserts Step 8.5 after Step 8; existing Conversational Editing Flow H2 stays unchanged.
- **Phase 8 business-graph-schema.md `business.type` field:** Already populated for every Business Graph (BGRAPH-01); Phase 15 uses this as the heuristics-map key.

### Established Patterns

- **2-plan cadence (Phase 8 precedent for narrow phases):** Plan 15-01 = data (heuristics + fixtures); Plan 15-02 = behavior (schema extension + subagent extension + surgical wiring).
- **Atomic commits per task (Phase 12-14 precedent):** Every reference, every fixture, every surgical edit lands as a discrete commit with `feat(15-NN): Task X <subject>` format.
- **Em-dash gate = 0 across new prose (Phase 13/14 precedent):** Verified at commit time per task.
- **Surgical-edit discipline (D-83 precedent):** Plan 15-02 Tasks 4-5 insert only; Task 3 has the documented exception of `<scope_exclusion>` -> `<anticipation_pass>` semantic replacement (the lock release).
- **Schema additive extension (Phase 14 D-98 precedent):** New fields are OPTIONAL; schema_version unchanged; backward-compatible.

### Integration Points

- **Designer Agent extension:** Phase 15 modifies `.claude/agents/designer-agent.md` `<scope_exclusion>` block -> `<anticipation_pass>` block in Plan 15-02 Task 3. All other Designer prose preserved.
- **agent-profile-schema.md:** Surgical extension in Plan 15-02 Task 2 adds 3 OPTIONAL fields + Validation Check 9.
- **SKILL.md Phase 2 entry:** One new See-line + Summary Gate paragraph extension. NO new sub-gate (anticipation is part of `agent_profiles_validated`).
- **Arco Rooms fixtures:** New `arco-rooms-anticipated-profiles.yaml` (5-agent variant) co-exists with existing `arco-rooms-agent-profiles.yaml` (3-agent baseline). Phase 16 uses the 5-agent variant for the canonical E2E run.

</code_context>

<specifics>
## Specific Ideas

- **The 5 v2.0 heuristic mappings are the consulting-product manifest:** rental-property-management, ecommerce, freelance-services, restaurant, professional-services. Future mappings ship as additive updates; v2.0 ships these 5 to validate the pattern + cover the most common SMB shapes.
- **Anticipated agent rationale must be one user-readable scan:** the rendered card MUST tell the user WHY in <= 2 sentences. "You probably need a Profitability Analyst because your 7-property rental business has invoice + payment data flows but no agent currently consolidates margin per property , owners typically ask this monthly per industry benchmarks." NOT "you probably need this." This bar is set in anticipation-heuristics.md per-mapping rationale prose.
- **declined.json is business-level state, not team-level:** if the user regenerates the team via overwrite (Re-run Behavior overwrite path), the decline persists and Designer respects it on the regenerated team. Tested via Plan 15-01 Task 3 fixture documenting the schema.
- **Heuristics-map evidence URLs MUST resolve at v2.0 ship date:** Plan 15-01 Task 1 acceptance criterion is that every URL is reachable (HTTP 200) and the cited content is current. Phase 16 E2E run re-verifies. Stale URLs are not allowed in v2.0 ship.
- **Anticipation degrades silently for unknown business types:** if `business.type: marketplace` (not in v2.0 map), Designer skips the anticipation pass entirely and emits zero anticipated agents. The rendered TABLE shows requested agents only; the rendered cards include a 1-line note "No anticipation candidates for business type 'marketplace' in current v2.0 map; future updates may add support." This matches the ANTIC degrade-silently success criterion.

</specifics>

<deferred>
## Deferred Ideas

- **More than 5 business-type mappings in v2.0:** ship 5 to validate the pattern; v2.5 + v3.0 expand based on consulting-engagement learnings. Out of v2.0 scope.
- **Anticipation re-evaluation on Business Graph change:** if the user expands their business (adds more properties, adds new processes), the anticipation pass currently runs only on the FIRST Phase 2 invocation per project. v2.5 may add a "rerun anticipation" CLI command. v2.0 ships first-invocation-only behavior; user can manually trigger by deleting agent-profiles.yaml and re-running.
- **Cross-business-type anticipation (multi-type businesses, e.g., rental + ecommerce):** v2.0 ships single-type lookup. v2.5 may support multi-type composition. Out of v2.0 scope.
- **Heuristics-map confidence scoring (LOW / MEDIUM / HIGH per mapping):** v2.0 ships unweighted (every mapping in the map IS recommended); v2.5 may add confidence scores so Designer can prioritize HIGH-confidence anticipations first. Out of v2.0 scope.
- **Heuristics-map auto-update from learned engagements:** anticipated agents that the user accepts vs. declines could feed back into the map. v3.0 self-healing scope per REQUIREMENTS.md deferred-to-v4.0 list. Out of v2.0 scope.
- **Anticipation for non-business types (personal automation, hobby projects):** v2.0 ships SMB-focused mappings only. Personal-automation anticipation is out of consulting-product scope.

### Reviewed Todos (not folded)

None , no relevant pending todos identified for Phase 15.

</deferred>

---

*Phase: 15-anticipation-engine*
*Context gathered: 2026-04-26*
*Mode: --auto lean inline (Claude selected recommended defaults; no subagent spawns; atomic commits per Phase 13/14 precedent)*
