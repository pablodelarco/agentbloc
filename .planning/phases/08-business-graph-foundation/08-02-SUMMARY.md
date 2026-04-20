---
phase: 08-business-graph-foundation
plan: 02
subsystem: business-graph
tags: [interview-extension, skill-gate, business-graph-emission, summary-template]
requires:
  - .planning/phases/08-business-graph-foundation/08-02-PLAN.md
  - .planning/phases/08-business-graph-foundation/08-CONTEXT.md
  - .planning/phases/08-business-graph-foundation/08-PATTERNS.md
  - .planning/phases/08-business-graph-foundation/08-01-SUMMARY.md (schema reference + fixture created in Wave 1)
  - .claude/skills/agentbloc/references/business-graph-schema.md (Wave 1 deliverable)
  - .claude/skills/agentbloc/examples/arco-rooms-business-graph.json (Wave 1 fixture)
provides:
  - Phase 1 interview now emits `.agentbloc/graph/business-graph.json` during the Summary gate
  - SKILL.md loads business-graph-schema.md unconditionally at Phase 1 entry
  - Phase 2 transition gated on valid Business Graph file existing
  - `business_graph_validated` sub-gate vocabulary in State Transitions
affects:
  - Phase 09 (Designer Agent consumes `.agentbloc/graph/business-graph.json`)
  - Phase 12 (Deploy Pipeline reads `schema_version` from emitted graph)
  - Phase 14 (Briefing Agent reads per-process fields from emitted graph)
  - Phase 16 (End-to-end Arco Rooms validation uses emitted graph against fixture)
tech_stack:
  added: []
  patterns:
    - surgical inline edits to shipped v1.0 reference files (no structural refactor)
    - hybrid unconditional loading extended from 2 references to 3 (D-09 pattern reapplied)
    - rendered-table-for-human + silent-JSON-for-machine separation (D-14)
    - sub-gate vocabulary within existing `approved` state (no new top-level gate value)
key_files:
  created:
    - .planning/phases/08-business-graph-foundation/08-02-SUMMARY.md (this file)
  modified:
    - .claude/skills/agentbloc/references/phase-1-interview.md (350 -> 388 lines; +38)
    - .claude/skills/agentbloc/SKILL.md (159 -> 163 lines; +4)
    - .planning/REQUIREMENTS.md (INTV-01..04 marked [x] with Phase 08-02 completion notes)
    - .planning/ROADMAP.md (Phase 8 progress: 1/2 In progress -> 2/2 Complete; Plan 02 checkbox + SUMMARY link)
    - .planning/STATE.md (Current Position, Session Continuity, progress counters)
decisions:
  - "Added one seed question and one must-know checkbox to Category 7 (D-16), preserving the 9-category structure (D-01 honored). No 10th category."
  - "Bumped Quick Reference Category 7 must-know count from 3 to 4 for the new decision-rule checkbox, not just the seed count. Total must-know items goes 31 to 32 for accuracy."
  - "Inserted three new H3 subsections (Tools Available / Channels / Decision Patterns) between Services and Integrations and Data Model in the Summary template, keeping the business -> process -> tools -> channels -> data -> security flow per CONTEXT.md D-14."
  - "Business Graph Emission subsection placed immediately BEFORE the final confirmation prompt so the user confirms the rendered tables first, then the JSON is written silently (D-14 separation of concerns)."
  - "SKILL.md sub-gate named `business_graph_validated` added as a Phase-1-specific State Transitions bullet, NOT a new top-level Gate vocabulary value (CONTEXT.md specifics: no new gate vocabulary beyond one value)."
  - "Phase 2 precondition paragraph placed BETWEEN the descriptive sentence and the `You MUST read...` block, matching the existing hook-style prose style of SKILL.md phase sections."
metrics:
  duration_minutes: 6
  completed: 2026-04-21
  tasks: 2
  files_created: 1
  files_modified: 5
commits:
  - 862241b feat(08-02) wire Business Graph emission into Phase 1 interview
  - 0ffbcda feat(08-02) add Business Graph gate to SKILL.md
---

# Phase 8 Plan 2: Interview + SKILL.md Business Graph Wiring Summary

Extended the shipped v1.0 Phase 1 Interview so that it emits a validated Business Graph JSON artifact during the Summary gate, and extended SKILL.md so that Phase 1 entry loads the schema unconditionally and Phase 2 transition is gated on the file existing. No new categories, no new top-level gate values, no structural refactors -- purely additive surgical edits.

## What Shipped

### `.claude/skills/agentbloc/references/phase-1-interview.md` (350 -> 388 lines)

Four surgical edits, all additive:

**1. Category 7 Seed Question #3 (D-16)** -- line inserted inside the existing Seed Questions block:

```
3. "What rules do you apply when deciding how to handle these edge cases? For example: if an invoice is overdue by more than 7 days, what do you do?"
```

**2. Category 7 Must-Know Checkbox** -- appended to the existing checklist:

```
- [ ] Decision rules captured for at least the top edge case (feeds decision_patterns in the Business Graph)
```

**3. Category 7 Adaptive Branching Bullet** -- appended to the existing branching list:

```
- If user describes a rule or threshold, capture it verbatim for decision_patterns: "Let me write that down: [paraphrase the rule]. Any other rules like that one you apply in this workflow?"
```

**4a. Three new H3 subsections in the Summary of Understanding Template** -- inserted between Services and Integrations (existing) and Data Model (existing), keeping the business -> process -> tools -> channels -> data flow per D-14:

- `### Tools Available (Business Graph tools_available)` -- table with Tool / Already in Use / Purpose columns. Extracted from Category 3 per D-17.
- `### Channels (Business Graph channels)` -- table with Channel / Used For columns. Extracted from Category 8 per D-17.
- `### Decision Patterns (Business Graph decision_patterns)` -- table with Rule / Source Category columns. Free-text per D-20.

**4b. Business Graph Emission subsection** -- inserted immediately before the final confirmation prompt. The five-step emission protocol:

1. Apply the Validation Checklist from business-graph-schema.md (Checks 1-6).
2. For any failed REQUIRED check (1-5), ask the targeted follow-up and wait.
3. Write validated JSON silently to `.agentbloc/graph/business-graph.json`.
4. Confirm in one sentence: "Business Graph saved. Ready to move to the design phase."
5. Set the Phase 1 `business_graph_validated` sub-gate to `approved`.

Re-run behavior (D-19): if file exists, ask keep / overwrite / merge (default merge).

**Plus:** Quick Reference table bumped: Category 7 seed 2 -> 3, must-know 3 -> 4; Totals 20 -> 21 seed questions, 31 -> 32 must-know items.

### `.claude/skills/agentbloc/SKILL.md` (159 -> 163 lines)

Three surgical edits, all additive:

**1. Phase 1 entry unconditional load list (lines 92-94 -> 93-96):**

Before:
```
You MUST read the complete interview protocol AND the data classification reference before asking any questions:
See [references/phase-1-interview.md](references/phase-1-interview.md)
See [references/data-classification.md](references/data-classification.md)
```

After:
```
You MUST read the complete interview protocol AND the data classification reference AND the business graph schema before asking any questions:
See [references/phase-1-interview.md](references/phase-1-interview.md)
See [references/data-classification.md](references/data-classification.md)
See [references/business-graph-schema.md](references/business-graph-schema.md)
```

Same 3-line micro-edit pattern used by v1.0 Phase 3 Plan 01 Task 2 when data-classification.md was first added to unconditional load.

**2. State Transitions bullet appended (new line 40):**

```
- Phase 1 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered Business Graph tables AND the `business_graph_validated` sub-gate (all REQUIRED checks from [references/business-graph-schema.md](references/business-graph-schema.md) Validation Checklist have passed and the file at `.agentbloc/graph/business-graph.json` has been written).
```

Added as a Phase-1-specific rule inside existing `pending` -> `approved` transition vocabulary. NO new top-level gate value introduced.

**3. Phase 2 Precondition paragraph inserted (new line 102):**

```
**Precondition:** Verify `.agentbloc/graph/business-graph.json` exists and validates against the Validation Checklist in [references/business-graph-schema.md](references/business-graph-schema.md). If the file is missing or fails any REQUIRED check, return the state bar to Phase 1 with gate `pending` and re-run the Summary gate before attempting Phase 2 again.
```

Placed between the descriptive paragraph and the `You MUST read...` block of Phase 2: General Design.

## Requirements Traced

| Requirement | Status | Evidence |
|-------------|--------|----------|
| INTV-01 (Interview emits Business Graph JSON) | COMPLETE | Business Graph Emission subsection in phase-1-interview.md Summary gate writes `.agentbloc/graph/business-graph.json` silently after table confirmation. Cross-linked from SKILL.md Phase 2 precondition. |
| INTV-02 (decision_patterns captured as free-text) | COMPLETE | Category 7 new seed question #3 + Decision Patterns Summary table + adaptive-branching verbatim-capture bullet. D-20 free-text policy preserved. |
| INTV-03 (channels + tools_available as distinct fields) | COMPLETE | Tools Available table extracts from Category 3; Channels table extracts from Category 8. Both are distinct H3 subsections in the Summary template and map to distinct Business Graph JSON fields. |
| INTV-04 (structured review of rendered sections) | COMPLETE | Summary of Understanding Template now renders all Business Graph sections (business, processes, tools_available, channels, decision_patterns, security_profile) as tables; user confirms tables before silent JSON emission (D-14). |

All four Phase 8 ROADMAP Success Criteria pass after this plan:

**SC1:** Emission path wired in both phase-1-interview.md (emission subsection) and SKILL.md (Phase 2 precondition). Fixture at `examples/arco-rooms-business-graph.json` is the reference shape.

**SC2:** Schema's Validation Checklist has per-check FAIL prompts with field-specific resolution questions (Checks 1-5 block emission, Check 6 warns). Emission subsection invokes the Checklist in order.

**SC3:** `business-graph-schema.md` is prose + tables + commented-JSON block (no external validator code). Readable standalone.

**SC4:** Interview preserves 9 categories, `### Seed Questions` structure, `One Question Per Turn` (D-03), `Soft Framing` (D-04), and bilingual detection (unchanged in `data-classification.md`). Business Graph emission is a silent Summary-gate side effect.

## Deviations from Plan

**None functionally.** One small scope adjustment documented here:

**[Rule 2 - Correctness] Quick Reference Category 7 must-know count bumped from 3 to 4.** The plan's formatting-constraint note only called out the seed count bump (2 -> 3) and Totals (20 -> 21). However, Edit 2 added a fourth must-know checkbox to Category 7, so the Quick Reference must-know column for that row had to go 3 -> 4 AND the Totals must-know cell had to go 31 -> 32 for internal consistency. This is a correctness fix (the table is a count of actual items), not a scope change. Documented here so a future audit sees the intent.

## Verification Summary

Task 1 automated checks (all pass):
- Seed question text present (1 match)
- Must-know checkbox present (1 match)
- Adaptive branching bullet present
- Three new H3 subsections present (Tools Available, Channels, Decision Patterns)
- Business Graph Emission H3 present
- Canonical JSON path cited
- Cross-links to business-graph-schema.md present (4 matches total)
- `business_graph_validated` sub-gate named
- Line count 388 (within 380-410 target)
- Category count exactly 9 (no 10th, D-01 honored)
- Em-dash count 0 (CLAUDE.md compliant)

Task 2 automated checks (all pass):
- business-graph-schema.md See-line added
- "AND the business graph schema" intro sentence updated
- `business_graph_validated` named in State Transitions
- `Precondition:` marker present in Phase 2
- Canonical JSON path cited in SKILL.md
- Line count 163 (well under 250-line CLAUDE.md cap; +4 from baseline 159)
- Phase section count 6 (preserved)
- Em-dash count 0 (CLAUDE.md compliant)

Phase-level ROADMAP Success Criteria (all 4 pass):
- SC1: phase-1-interview + SKILL both reference `.agentbloc/graph/business-graph.json`; fixture exists
- SC2: schema has FAIL-path prompts; emission subsection invokes Validation Checklist
- SC3: schema file readable standalone (prose + tables, no external code)
- SC4: 9 categories preserved; seed questions, one-question-per-turn, soft framing, bilingual detection all intact

## Handoff Note for Phase 9 (Designer Agent)

Phase 1 of the interview now emits `.agentbloc/graph/business-graph.json` with shape locked in `references/business-graph-schema.md`. Designer Agent reads this file and refuses to proceed on an unknown `schema_version` value. Current version: `1`. Canonical test fixture at `examples/arco-rooms-business-graph.json`.

The emission is silent (D-14). The user confirms the rendered tables in the Summary gate; the JSON is a side effect. Designer Agent does not need to re-parse the transcript -- the Business Graph is the input contract.

Re-run behavior (D-19): if the file exists when the Interview runs again, Claude asks keep / overwrite / merge. Designer Agent should assume it may receive a merged graph (multiple processes accumulated across sessions).

Extension points already mapped if Designer needs to extend the schema:
- Add a new optional field -> no `schema_version` bump needed
- Add an enum value to `trigger.type` -> no bump (additive)
- Remove or rename a REQUIRED field -> bump to `schema_version: 2` and write a migration note in business-graph-schema.md

## Self-Check: PASSED

**Created files verified:**
- FOUND: .planning/phases/08-business-graph-foundation/08-02-SUMMARY.md (this file)

**Modified files verified:**
- FOUND: .claude/skills/agentbloc/references/phase-1-interview.md (388 lines, +38 from baseline)
- FOUND: .claude/skills/agentbloc/SKILL.md (163 lines, +4 from baseline)
- FOUND: .planning/REQUIREMENTS.md (INTV-01..04 all marked [x] with Phase 08-02 notes)
- FOUND: .planning/ROADMAP.md (Phase 8 row 2/2 Complete; Plan 02 checkbox + SUMMARY link)
- FOUND: .planning/STATE.md (Current Position, progress 4% -> 8%, Session Continuity next-step updated)

**Commits verified:**
- FOUND: 862241b feat(08-02): wire Business Graph emission into Phase 1 interview
- FOUND: 0ffbcda feat(08-02): add Business Graph gate to SKILL.md

**Acceptance criteria:**
- All 11 Task 1 automated checks pass
- All 8 Task 2 automated checks pass
- All 4 INTV requirements (01-04) materially satisfied with traceable evidence
- All 4 Phase 8 ROADMAP success criteria pass
- All 9 plan-level success criteria satisfied (verified above)
