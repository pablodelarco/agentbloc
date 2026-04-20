---
phase: 08-business-graph-foundation
plan: 01
subsystem: business-graph
tags: [schema, reference, fixture, interview-extension]
requires:
  - .planning/phases/08-business-graph-foundation/08-01-PLAN.md
  - .planning/phases/08-business-graph-foundation/08-CONTEXT.md
  - .planning/phases/08-business-graph-foundation/08-PATTERNS.md
  - .claude/skills/agentbloc/references/data-classification.md (structural twin)
  - .claude/skills/agentbloc/examples/arco-rooms.md (fixture source walkthrough)
provides:
  - .claude/skills/agentbloc/references/business-graph-schema.md
  - .claude/skills/agentbloc/examples/arco-rooms-business-graph.json
affects:
  - Phase 08-02 (interview + SKILL.md wiring will cross-link this schema)
  - Phase 09 (Designer Agent consumes the Business Graph defined here)
  - Phase 12 (Deploy Pipeline reads schema_version from this schema)
  - Phase 14 (Briefing Agent reads per-process fields defined here)
  - Phase 16 (End-to-end validation uses the Arco Rooms fixture as target)
tech_stack:
  added: []
  patterns:
    - prose-checklist validator (no external tooling per D-13)
    - structural twin of data-classification.md (H1 + blockquote + TOC + "When This Applies" + table-driven content)
    - bounded enum with per-value required sub-fields (D-18 pattern)
    - three-tier field obligation matrix (REQUIRED / RECOMMENDED / OPTIONAL per D-12)
key_files:
  created:
    - .claude/skills/agentbloc/references/business-graph-schema.md (137 lines)
    - .claude/skills/agentbloc/examples/arco-rooms-business-graph.json (103 lines, valid JSON)
  modified: []
decisions:
  - "Rendered the D-12 field obligation matrix verbatim as a single table so Designer Agent (Phase 9) can map tier-to-behavior without interpretation"
  - "Cross-links use shorthand relative paths (phase-1-interview.md, not references/phase-1-interview.md) matching data-classification.md house convention"
  - "Fixture uses real Arco Rooms persona data (30 properties, Pablo operator, GDPR) pulled from examples/arco-rooms.md, not invented"
metrics:
  duration_minutes: 5
  completed: 2026-04-20
  tasks: 2
  files_created: 2
  files_modified: 0
commits:
  - cb1ce3a feat(08-01): create business-graph-schema.md reference
  - 868d18e feat(08-01): add arco-rooms-business-graph.json canonical test fixture
---

# Phase 8 Plan 1: Business Graph Schema Reference + Arco Rooms Test Fixture Summary

Created the canonical Business Graph schema reference file (`business-graph-schema.md`) and a realistic test fixture (`arco-rooms-business-graph.json`) derived from the existing Arco Rooms walkthrough. The schema is the contract every downstream v2.0 phase reads from; the fixture is the Phase 16 end-to-end validation target.

## What Shipped

### `.claude/skills/agentbloc/references/business-graph-schema.md` (137 lines)

The canonical schema reference, structurally twinned with `data-classification.md`. Nine H2 sections in order:

1. **Table of Contents** (anchor links to all sections)
2. **When This Applies** (load condition + downstream consumers: Phase 9 Designer, Phase 12 Deploy, Phase 14 Briefing; cross-links to `phase-1-interview.md` and `data-classification.md`)
3. **Schema Definition** (single fenced `jsonc` block, inline obligation tiers per field, example hints)
4. **Field Obligation Matrix** (D-12 three-tier table verbatim)
5. **Trigger Bounded Enum** (D-18 four-column table: enum value / definition / required sub-fields / example)
6. **Validation Checklist** (six ordered prose checks with FAIL/WARN outcomes and targeted follow-up questions)
7. **Emission Protocol** (D-11 + D-14: silent JSON write, rendered-table review, user confirmation gate)
8. **Re-run Behavior** (D-19: keep / overwrite / merge default; schema_version mismatch handling)
9. **Schema Versioning Rules** (integer versioning; breaking vs additive changes)

### Final schema shape

```jsonc
{
  "schema_version": 1,                        // REQUIRED. Integer. Bumped only on breaking changes.
  "business": {
    "type": "string",                         // REQUIRED. e.g. "rental-property-management"
    "size": "string | null",                  // RECOMMENDED. e.g. "7 properties, 1 operator"
    "owner": "string | null"                  // RECOMMENDED. e.g. "Maria"
  },
  "processes": [                              // REQUIRED. Length >= 1.
    {
      "name": "string",                       // REQUIRED.
      "steps": ["string"],                    // REQUIRED. Length >= 1.
      "trigger": {                            // RECOMMENDED.
        "type": "cron | event | manual",      // Bounded enum. See Trigger Bounded Enum section.
        // cron requires:    "schedule": "<cron string>"
        // event requires:   "source": "<service>", "name": "<event id>"
        // manual requires:  "description": "<free text>"
      },
      "tools": ["string"],                    // RECOMMENDED. Tool names referenced in this process.
      "frequency": "string | null",           // RECOMMENDED. e.g. "weekly", "daily-9am"
      "current_actor": "string | null",       // RECOMMENDED. Who does this today.
      "pain": "string"                        // REQUIRED. Free-text pain description.
    }
  ],
  "tools_available": ["string"],              // OPTIONAL. Extracted from interview Category 3.
  "channels": ["string"],                     // OPTIONAL. Extracted from Category 8. e.g. ["telegram","email"]
  "decision_patterns": ["string"],            // OPTIONAL. Free-text rules from Category 7 seed question.
  "security_profile": {                       // OPTIONAL. Structured version of the v1.0 data-classification tally.
    "data_classes": ["PII", "Financial"],
    "regimes_activated": ["GDPR"]
  },
  "business_context": "string | null"         // OPTIONAL. Free-text additional context.
}
```

### Validation checklist (6 checks)

1. **Check 1**: `schema_version` present and equals current version (`1`). FAIL -> emit automatically, no user follow-up.
2. **Check 2**: `business.type` present and non-empty. FAIL -> ask about business kind.
3. **Check 3**: `processes[]` present and length >= 1. FAIL -> ask to confirm the main process.
4. **Check 4**: Every process has `name`, `steps[]` (>= 1), and `pain`. FAIL -> ask targeted gap question.
5. **Check 5**: Every `process.trigger.type` in {cron, event, manual} with required sub-field. FAIL -> ask schedule / event / human action.
6. **Check 6 (WARN)**: RECOMMENDED fields populated or explicitly `null`. Emit with `null` defaults + log gap in rendered table review.

Checks 1-5 block emission; check 6 warns only.

### `.claude/skills/agentbloc/examples/arco-rooms-business-graph.json` (103 lines)

Realistic Arco Rooms Business Graph derived from `examples/arco-rooms.md`:

- `schema_version: 1`
- `business.type: "rental-property-management"`, owner `"Pablo"`, ~30 properties
- **3 processes** (Invoice Collection / Payment Matching / Owner Reporting), each with 4-5 steps, cron triggers at 22:00 / 22:30 / 23:00, `current_actor` and `pain` populated
- `tools_available` lists all 6 utility provider portals + Gmail + Telegram + Sheets + 4 bank accounts
- `channels: ["telegram", "email"]`
- 3 `decision_patterns` (overdue invoice notice, unmatched transaction escalation, portal downtime fallback)
- `security_profile` with `["PII", "Financial"]` + GDPR regime
- `business_context` captures Almeria Spain jurisdiction and solo-operator context

Every REQUIRED check in the schema's Validation Checklist passes on this fixture.

## Requirements Traced

| Requirement | Status | Evidence |
|-------------|--------|----------|
| BGRAPH-01 (schema definition: business / processes / tools_available / channels / decision_patterns) | COMPLETE | Schema Definition section in business-graph-schema.md; all fields present |
| BGRAPH-02 (schema_version field) | COMPLETE | `schema_version: 1` in schema + fixture; Schema Versioning Rules section defines bump criteria |
| BGRAPH-03 (trigger bounded enum `{cron, event, manual}` with type-specific fields) | COMPLETE | Trigger Bounded Enum section + 4-column table; fixture uses `cron` with `schedule` |
| BGRAPH-04 (lightweight validator) | COMPLETE | Validation Checklist section (6 ordered prose checks). Per D-13 the validator IS the checklist, no external tooling |

## Deviations from Plan

None. Plan executed exactly as written.

The plan's "Section 8 / Section 9" nomenclature in Task 1 counted eight H2 sections after the H1 title; the Table of Contents is itself an H2 section, giving 9 H2 headers total in the final file. This matches the data-classification.md analog (which also has a Table of Contents H2 + 7 content H2s). Acceptance criterion `grep -c "^## " >= 8` satisfied by the 9 H2 sections produced.

## Handoff Note for Plan 08-02

The schema file at `.claude/skills/agentbloc/references/business-graph-schema.md` is the contract Plan 08-02 wires into `phase-1-interview.md` and `SKILL.md`. Any changes to field obligations after this point require a `schema_version` bump.

Plan 08-02 extension points are already mapped in `08-PATTERNS.md`:

- `phase-1-interview.md` lines 199-218 for Category 7 D-16 seed question
- `phase-1-interview.md` lines 281-333 for Summary of Understanding D-11 emission subsection + D-14 rendered table additions
- `SKILL.md` lines 92-94 for adding `business-graph-schema.md` to the unconditional Phase 1 load list
- `SKILL.md` lines 97-102 for Phase 2 precondition (`.agentbloc/graph/business-graph.json` exists and validates)
- `SKILL.md` lines 36-40 for the `business_graph_validated` sub-gate State Transitions bullet

The Arco Rooms fixture at `examples/arco-rooms-business-graph.json` is the reference Plan 08-02 can cite in SKILL.md and the expected output shape for the Phase 16 end-to-end Arco Rooms run.

## Self-Check: PASSED

**Created files verified:**
- `FOUND: .claude/skills/agentbloc/references/business-graph-schema.md` (137 lines)
- `FOUND: .claude/skills/agentbloc/examples/arco-rooms-business-graph.json` (valid JSON, 3 processes)

**Commits verified:**
- `FOUND: cb1ce3a feat(08-01): create business-graph-schema.md reference`
- `FOUND: 868d18e feat(08-01): add arco-rooms-business-graph.json canonical test fixture`

**Acceptance criteria:**
- All 11 Task 1 automated checks pass (file exists, H1 exact match, schema_version, bounded enum phrasing, three tiers, output path, cross-links, numbered checks, jsonc fence, line count in 130-220, zero em-dashes)
- All 10 Task 2 automated checks pass (file exists, valid JSON parse, schema_version==1, processes>=3, per-process REQUIRED fields, trigger.type in bounded enum, GDPR activated, business.type set, decision_patterns field, telegram channel)
- All 4 BGRAPH requirements (01-04) materially satisfied with traceable evidence
- All 9 phase-level verification checks pass
