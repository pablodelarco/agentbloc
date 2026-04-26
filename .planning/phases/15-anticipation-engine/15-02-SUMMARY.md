---
phase: 15-anticipation-engine
plan: 02
status: complete
date: 2026-04-26
commits:
  - 4d0712e feat(15-02): Task 1 declined-agents-schema.md
  - 79bc92a feat(15-02): Task 2 agent-profile-schema.md surgical extension
  - e1774e3 feat(15-02): Task 3 designer-agent.md anticipation pass
  - 443d3b6 feat(15-02): Task 4 phase-2-design.md Step 8.5 anticipation pass
  - ab3a10f feat(15-02): Task 5 SKILL.md anticipation See-line + Summary Gate
requirements_closed:
  - ANTIC-01
  - ANTIC-03
  - ANTIC-04
---

# Plan 15-02 SUMMARY: Anticipation Behavior , Schema + Subagent Extension + Wiring

## Outcome

1 net-new artifact (declined-agents-schema.md) plus 4 surgically extended files (agent-profile-schema.md, designer-agent.md, phase-2-design.md, SKILL.md). 5 atomic commits. ANTIC-01 + ANTIC-03 + ANTIC-04 closed at the behavior layer; with Plan 15-01 already closing ANTIC-02 + ANTIC-05, all 5 ANTIC requirements are now satisfied.

## Artifacts Emitted / Extended

| Artifact | Action | Lines | Plan target | Closes |
|---|---|---|---|---|
| `references/declined-agents-schema.md` | NEW | 74 | 70-110 | ANTIC-04 |
| `references/agent-profile-schema.md` | EXTENDED | 200 (was 178) | 195-235 | ANTIC-03 |
| `.claude/agents/designer-agent.md` | EXTENDED (scope_exclusion -> anticipation_pass replacement) | 170 (was 145) | 165-220 | ANTIC-01 |
| `references/phase-2-design.md` | EXTENDED | 393 (was 376) | 380-440 | (wires Step 8.5) |
| `SKILL.md` | EXTENDED (Phase 2 See-line + Summary Gate paragraph) | 208 (was 207) | 207-220 | (cites anticipation-heuristics.md per D-58) |

## What's Shipped

**`declined-agents-schema.md`** , Formal contract for `.agentbloc/graph/declined.json`. 5-field schema (agent_id + business_type + declined_at ISO-8601 + reason + correlation_id). Append-only discipline per Phase 14 D-87 trace-integrity pattern. Designer Integration Protocol section documents the read-and-filter behavior. Re-introduction Behavior section documents both manual-edit and conversational-add paths. Why Business-Level (not Team-Level) section locks in D-102 architectural decision. Subagent-only file (Designer reads it inside fork; not cited from SKILL.md per D-58).

**`agent-profile-schema.md` extension** , Schema Definition adds 3 OPTIONAL fields per agent (`anticipated: bool` + `anticipation_rationale: string` + `anticipation_sources: array`). Field Obligation Matrix gains a fourth row in OPTIONAL tier. Validation Check 9 (WARN-tier) added after Check 8: flags any anticipated agent missing rationale or with fewer than 3 sources, but does NOT block emission per D-101. Schema Versioning Rules updated to mention the new fields as additive. New Anticipation Fields H2 section appended at end documenting WHY the fields exist + how Phase 15 consumers use them. schema_version stays at 1 per D-101 backward-compatibility.

**`designer-agent.md` extension** , Mandatory Initial Read block extended with 6th read (declined.json, OPTIONAL absence). `<scope_exclusion>` block (Phase 9 D-30 lock, ~7 lines) REPLACED with `<anticipation_pass>` block (~30 lines) per D-99 + D-103 documented exception to surgical-insert-only rule. New block describes 6-step anticipation flow: read declined.json, look up business.type in heuristics map, degrade silently if no match, filter declined, emit anticipated agents, re-validate, render with [ANTICIPATED] tag. Decline handling sub-section documents the conversational-edit path (append to declined.json + remove from agent-profiles.yaml + bump modified_at + re-render TABLE). All other Designer prose preserved verbatim per surgical-edit discipline.

**`phase-2-design.md` extension** , Step 8 Scope note (line 307) updated to remove "excluded here" caveat and reference Step 8.5. New H2 "Step 8.5: Anticipation Pass (ANTIC-01..05)" inserted between Step 8 (Designer Subagent Invocation) and existing Conversational Editing Flow H2. Closes ANTIC-01 + ANTIC-03 + ANTIC-04 per the section. Quick Reference table gains row for Anticipation Pass at end (after Conversational Editing Flow row). Both anchors preserved verbatim per D-83 surgical-edit discipline.

**`SKILL.md` extension** , Phase 2 Summary Gate paragraph extended with one sentence about Step 8.5 anticipation pass. Phase 2 entry gains ONE new See-line for anticipation-heuristics.md (per D-58 context-budget; declined-agents-schema.md NOT cited because subagent-only). NO new sub-gate added (anticipation is part of existing agent_profiles_validated). NO Phase 5/6 wiring changes (existing consumers ignore new fields per backward-compatibility per D-101).

## Acceptance Gates

| Gate | Result | Evidence |
|---|---|---|
| Em-dash gate (NEW prose, 5 files) | PASS | `grep -c '—' <file>` = 0 for all 5 files post-edit |
| D-83 surgical-edit discipline | PASS | All upstream anchors preserved verbatim: "Step 8: Designer Subagent Invocation" (phase-2-design.md L295), "Conversational Editing Flow" (phase-2-design.md L353), "agent_profiles_validated" (SKILL.md), "schema_version: 1" (agent-profile-schema.md L25) |
| Designer subagent integrity | PASS | All `<role>` + `<write_constraint>` + `<process_to_role_grouping>` + `<topology_selection>` + `<orchestration_classification>` + `<blast_radius_scoring>` + `<validation_and_emission>` + `<conversational_edits>` + `<output_contract>` blocks preserved byte-identical; only `<scope_exclusion>` -> `<anticipation_pass>` semantic replacement |
| Schema backward compatibility | PASS | schema_version stays at 1 (additive extension per D-101); existing arco-rooms-agent-profiles.yaml (3-agent baseline) still validates against extended schema |
| Plan 15-01 fixture validates | PASS | arco-rooms-anticipated-profiles.yaml validates against new agent-profile-schema.md including Validation Check 9 (rationale + 3 sources present on both anticipated agents) |
| SKILL.md context budget (D-58) | PASS | grep counts: anticipation-heuristics.md = 1 cited; declined-agents-schema.md = 0 cited (subagent-only correctly excluded) |

## Architectural Invariants Held

| Invariant | Expected | Evidence |
|---|---|---|
| D-21 (Designer subagent path) | `.claude/agents/designer-agent.md` unchanged location, still context=fork, still scoped tools | Frontmatter byte-identical pre-/post-edit |
| D-26 (conversational-edit surgical patches) | Decline path appends to declined.json + surgical patches agent-profiles.yaml, never regenerates | `<anticipation_pass>` Decline handling section cites D-26 explicitly |
| D-58 (SKILL.md context budget grep-for-absence) | declined-agents-schema.md NOT in SKILL.md | grep returns 0 |
| D-83 (surgical-edit discipline) | All 4 surgical-edit files preserve upstream anchors | grep-for-presence verified per task |
| D-93 (sub-gate pattern) | NO new sub-gate for Phase 15 | grep "anticipation_validated\|anticipation_wired" SKILL.md = 0 (sub-gate is existing agent_profiles_validated) |
| D-98 (additive schema extension) | schema_version unchanged at 1 | grep "schema_version: 1" agent-profile-schema.md L25 = preserved |
| D-99 (anticipation pass same-invocation) | Designer's <anticipation_pass> block runs in same fork-context invocation as requested-agent emission | designer-agent.md anticipation_pass block placed inside same XML structure as <validation_and_emission>, not as a separate subagent definition |
| D-101 (3 OPTIONAL fields + WARN tier Check 9) | Schema accepts all anticipated agents with backward-compat | agent-profile-schema.md L55-58 + L79 + L147-149 verified |
| D-102 (declined.json business-level path) | declined-agents-schema.md cites .agentbloc/graph/declined.json (sibling to business-graph.json) | declined-agents-schema.md Why Business-Level section verified |
| D-103 (SKILL.md ONE See-line + Summary Gate paragraph + NO sub-gate) | Surgical edit discipline + context budget held | grep for "anticipation-heuristics" in SKILL.md = 1 match; no new sub-gate names |

## Lean-Mode Compromise Disclosure

All 5 emitted/extended files landed within target ranges. No lean-mode shortfall in Plan 15-02. The line counts:
- declined-agents-schema.md: 74 lines (target 70-110 , within budget)
- agent-profile-schema.md: 200 lines (target 195-235 , within budget)
- designer-agent.md: 170 lines (target 165-220 , within budget)
- phase-2-design.md: 393 lines (target 380-440 , within budget)
- SKILL.md: 208 lines (target 207-220 , within budget)

Plan 15-01's anticipation-heuristics.md remains the only lean-mode shortfall (-52 lines vs. target 200-300); Plan 15-02 fully reaches its budgets.

## Next

Phase 15 close-out: 15-VERIFICATION.md + ROADMAP / STATE / REQUIREMENTS updates + final phase-close commit. After Phase 15 ships, only Phase 16 (E2E validation + v2.0.0 release) remains for v2.0 milestone close.
