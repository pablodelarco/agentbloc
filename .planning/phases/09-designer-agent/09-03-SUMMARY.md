---
phase: 09-designer-agent
plan: 03
subsystem: agentbloc-skill
tags: [skill-wiring, designer-subagent, gate-vocabulary, phase-2, phase-3]
requires:
  - .planning/phases/09-designer-agent/09-01-SUMMARY.md
  - .planning/phases/09-designer-agent/09-02-SUMMARY.md
  - .claude/agents/designer-agent.md
  - .claude/skills/agentbloc/references/orchestration-patterns.md
  - .claude/skills/agentbloc/references/agent-profile-schema.md
provides:
  - Phase 2 unconditional-load list extended (orchestration-patterns.md + agent-profile-schema.md)
  - Phase 2 Summary Gate spawns Designer subagent (context=fork) writing .agentbloc/team/agent-profiles.yaml
  - agent_profiles_validated sub-gate vocabulary (sibling of business_graph_validated)
  - Phase 3 precondition gating on .agentbloc/team/agent-profiles.yaml existence + validation
  - Step 8 Designer Subagent Invocation subsection in phase-2-design.md
  - Conversational Editing Flow subsection in phase-2-design.md (D-26 surgical patches, never regenerate)
affects:
  - .claude/skills/agentbloc/references/phase-2-design.md
  - .claude/skills/agentbloc/SKILL.md
tech-stack:
  patterns:
    - surgical-insert-into-existing-protocol (mirrors Phase 8 Task 1 technique, one phase later)
    - three-edit-SKILL.md-wiring (mirrors Phase 8 Task 2 pattern, one phase later)
    - sub-gate vocabulary extension (business_graph_validated -> agent_profiles_validated)
    - companion-reference cross-linking (relative paths within references/)
key-files:
  modified:
    - .claude/skills/agentbloc/references/phase-2-design.md (313 -> 376 lines, +63)
    - .claude/skills/agentbloc/SKILL.md (163 -> 170 lines, +7)
decisions:
  - "D-21: Designer subagent invocation path + context=fork locked into SKILL.md Summary Gate + phase-2-design.md Step 8 (authoritative references)"
  - "D-22: agent_profiles_validated sub-gate requires ALL REQUIRED checks of agent-profile-schema.md Validation Checklist before approved state"
  - "D-26: Surgical-patch protocol (never regenerate from Business Graph) encoded in Conversational Editing Flow H2 subsection"
  - "D-29: Three SKILL.md edits exactly mirror Phase 8 Task 2 pattern (State Transitions bullet append + Phase N load-list extension with Summary Gate paragraph + Phase N+1 precondition paragraph)"
metrics:
  duration_minutes: 3
  tasks_completed: 2
  files_modified: 2
  files_created: 1
  commits: 2
  completed_date: "2026-04-21"
---

# Phase 9 Plan 3: Designer Wiring into SKILL.md and phase-2-design.md Summary

Wire Plan 09-01's orchestration-patterns.md + agent-profile-schema.md references and Plan 09-02's Designer Agent subagent into AgentBloc's Phase 2 execution flow. Two files edited surgically (phase-2-design.md +63 lines; SKILL.md +7 lines) with zero em-dashes and SKILL.md staying at 170 lines (well under the 250-line v1.0 budget). Completes Phase 9 Designer Agent.

## Tasks Completed

### Task 1: phase-2-design.md (4 surgical edits) — commit `3b312ba`

Baseline: 313 lines. Final: 376 lines. Net: +63.

**Edit 1 — Design Opening companion-load sentence:**

Before:
```
You have the confirmed interview summary. Before starting design, also load [references/blast-radius.md](blast-radius.md) and [references/frameworks.md](frameworks.md). The Security Profile from the interview summary tells you which compliance regimes are active.
```

After:
```
You have the confirmed Business Graph. Before starting design, also load [references/blast-radius.md](blast-radius.md), [references/frameworks.md](frameworks.md), [references/orchestration-patterns.md](orchestration-patterns.md), and [references/agent-profile-schema.md](agent-profile-schema.md). The Security Profile from the Business Graph tells you which compliance regimes are active.
```

Two additional companion reference links; "interview summary" rephrased to "Business Graph" (reflecting Phase 8 ship).

**Edit 2 — Insert Step 8 Designer Subagent Invocation H2** (between end of Step 7 Visual Presentation and `## Design Gate`):

New H2 subsection with three H3 children:
- `### Invocation` — spawn `.claude/agents/designer-agent.md` with `context: fork`; lists 5 initial-prompt context items (Business Graph path; required reading of schema + patterns + blast-radius + frameworks; output target `.agentbloc/team/agent-profiles.yaml`; optional companion `.agentbloc/team/team-topology.md`; Phase 15 anticipation scope exclusion)
- `### Output Contract` — confirmation string, rendered table + Contract Cards, ASCII topology diagram; YAML never shown to user
- `### Gate Check` — verify file exists + Checks 1-7 of schema passed + rendered artifacts presented; only then flip `agent_profiles_validated` sub-gate to approved

**Edit 3 — Insert Conversational Editing Flow H2** (between `## Design Gate` and `## Quick Reference`):

New H2 subsection with three H3 children:
- `### Surgical Patch Protocol` — 5-step flow: parse intent into structured patch {rename, delete, add-tool, remove-tool, change-autonomy, change-topology, change-blast-radius}; re-invoke Designer with patch payload + existing YAML (NEVER from Business Graph); apply in-place + bump `team.modified_at`; re-run Validation Checklist; return ONLY re-rendered table
- `### Never Regenerate` — if user says "redo from scratch", prompt once for confirmation; default to keep edits
- `### Gate Re-entry` — sub-gate returns to `pending` between rounds; flips back to `approved` after each user confirmation

Encodes D-26 surgical-patch rule: regeneration from Business Graph would re-insert rejected or renamed agents, fighting user intent.

**Edit 4 — Quick Reference table extended with 2 new rows:**

```
| Designer Subagent Invocation | DSGN-01..06, ORCH-01..04 | .agentbloc/team/agent-profiles.yaml + rendered team table + ASCII diagram | [agent-profile-schema.md](agent-profile-schema.md), [orchestration-patterns.md](orchestration-patterns.md), .claude/agents/designer-agent.md |
| Conversational Editing Flow | DSGN-07 | Surgical-patched YAML + re-rendered table | [agent-profile-schema.md](agent-profile-schema.md), .claude/agents/designer-agent.md |
```

### Task 2: SKILL.md (3 surgical edits) — commit `783b538`

Baseline: 163 lines. Final: 170 lines. Net: +7. Well under the 250-line v1.0 budget.

**Edit 1 — Append `Phase 2 specific:` bullet to State Transitions:**

Before (existing Phase 8 Phase 1 bullet retained as context):
```
- Phase 1 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered Business Graph tables AND the `business_graph_validated` sub-gate ...
```

After (new bullet appended as LAST item):
```
- Phase 1 specific: ... (unchanged)
- Phase 2 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered team table and per-agent cards AND the `agent_profiles_validated` sub-gate (all REQUIRED checks from [references/agent-profile-schema.md](references/agent-profile-schema.md) Validation Checklist have passed and the file at `.agentbloc/team/agent-profiles.yaml` has been written by the Designer subagent).
```

Net: +1 bullet. Exact parallel to Phase 8's Phase-1-specific bullet, one phase later.

**Edit 2 — Phase 2 section: add Summary Gate + extend load list:**

Before:
```
**Precondition:** Verify `.agentbloc/graph/business-graph.json` ... (Phase 8 retained)

You MUST read the complete design protocol before starting this phase:
See [references/phase-2-design.md](references/phase-2-design.md)
```

After:
```
**Precondition:** ... (unchanged from Phase 8)

**Summary Gate:** After walking the design protocol, spawn the Designer Agent subagent at `.claude/agents/designer-agent.md` (`context: fork`) to emit `.agentbloc/team/agent-profiles.yaml`. The subagent writes silently; the rendered team table + per-agent cards + ASCII topology diagram are what the user reviews and confirms. See [references/phase-2-design.md](references/phase-2-design.md) Step 8 for the invocation protocol.

You MUST read the complete design protocol AND the orchestration patterns reference AND the agent profile schema before starting this phase:
See [references/phase-2-design.md](references/phase-2-design.md)
See [references/orchestration-patterns.md](references/orchestration-patterns.md)
See [references/agent-profile-schema.md](references/agent-profile-schema.md)
```

Net: +1 `**Summary Gate:**` paragraph + 2 new See-lines + lead-in sentence rewritten. Same sentence-extension + paragraph-insert pattern as Phase 8 Task 2 Edit 1 + Edit 3 composed.

**Edit 3 — Phase 3 section: insert Precondition paragraph:**

Before:
```
### Phase 3: Deep Integration Analysis

For each agent action, find the BEST integration method. ... Present options with pros/cons/setup for every service.

You MUST read the complete integration analysis protocol before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
```

After:
```
### Phase 3: Deep Integration Analysis

For each agent action, find the BEST integration method. ... Present options with pros/cons/setup for every service.

**Precondition:** Verify `.agentbloc/team/agent-profiles.yaml` exists and validates against the Validation Checklist in [references/agent-profile-schema.md](references/agent-profile-schema.md). If the file is missing or fails any REQUIRED check, return the state bar to Phase 2 with gate `pending` and re-run the Summary gate before attempting Phase 3 again.

You MUST read the complete integration analysis protocol before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
```

Exact parallel of Phase 8 Task 2 Edit 3, one phase later. Net: +1 paragraph (+2 lines).

## Final File Line Counts

| File | Before | After | Net | Budget |
|------|--------|-------|-----|--------|
| `.claude/skills/agentbloc/references/phase-2-design.md` | 313 | 376 | +63 | 360-390 ✓ |
| `.claude/skills/agentbloc/SKILL.md` | 163 | 170 | +7 | <250 ✓ |

## Verification: All Acceptance Criteria Pass

### Task 1 (phase-2-design.md)
- Companion-load links for orchestration-patterns.md + agent-profile-schema.md present ✓
- `## Step 8: Designer Subagent Invocation` H2 with Invocation / Output Contract / Gate Check H3s ✓
- `## Conversational Editing Flow` H2 with Surgical Patch Protocol / Never Regenerate / Gate Re-entry H3s ✓
- Cites `context: fork`, `.claude/agents/designer-agent.md`, `.agentbloc/team/agent-profiles.yaml`, `agent_profiles_validated` ✓
- Phase 15 scope exclusion ("Anticipated") present ✓
- "NEVER regenerates" D-26 rule present ✓
- Quick Reference has 2 new rows (Designer Subagent Invocation, Conversational Editing Flow) ✓
- Steps 1-7, Design Gate preserved unchanged ✓
- 376 lines, zero em-dashes ✓

### Task 2 (SKILL.md)
- `Phase 2 specific:` State Transitions bullet with `agent_profiles_validated` sub-gate ✓
- `**Summary Gate:**` paragraph with designer-agent.md + context:fork + .agentbloc/team/agent-profiles.yaml ✓
- Load list extended with See-lines for orchestration-patterns.md + agent-profile-schema.md ✓
- Lead-in sentence rewritten ("AND the orchestration patterns reference AND the agent profile schema") ✓
- Phase 3 Precondition paragraph gating on agent-profiles.yaml ✓
- 2 Precondition paragraphs total (Phase 2 from Phase 8 + new Phase 3) ✓
- 6 `### Phase ` headings preserved ✓
- Phase 1 specific bullet from Phase 8 preserved ✓
- 170 lines (<250 v1.0 budget) ✓
- Zero em-dashes ✓
- YAML frontmatter preserved ✓

## ROADMAP Phase 9 Success Criteria — All Wired End-to-End

| SC | Criterion | Wiring Location |
|----|-----------|-----------------|
| 1 | Designer produces valid agent-profiles.yaml for Arco Rooms | Plan 09-01 (fixture + schema) + Plan 09-02 (subagent) + Plan 09-03 SKILL.md Summary Gate paragraph ✓ |
| 2 | YAML validates against schema + workflows resolve agent refs | Plan 09-01 Validation Checklist + Plan 09-03 agent_profiles_validated sub-gate ✓ |
| 3 | Every profile carries role/goal/backstory/tools/triggers/autonomy/outputs/escalation/dependencies | Plan 09-01 agent-profile-schema.md Schema Definition + Field Obligation Matrix ✓ |
| 4 | Designer cites orchestration-patterns.md when picking patterns | Plan 09-02 (Designer body) + Plan 09-03 Phase 2 load list extension + phase-2-design.md Step 8 companion-load ✓ |
| 5 | Conversational rename/merge/drop patches YAML (not from scratch) | Plan 09-02 conversational_edits block + Plan 09-03 Conversational Editing Flow H2 subsection ✓ |

## Requirements Completed

- `DSGN-06` — Designer invoked from Phase 2 Summary Gate (wired)
- `DSGN-07` — Conversational surgical-patch editing flow documented in phase-2-design.md
- `ORCH-02` — orchestration-patterns.md loaded unconditionally at Phase 2 entry (SKILL.md Edit 2)

## Deviations from Plan

None. All four phase-2-design.md edits and all three SKILL.md edits landed exactly as specified. Every `grep` acceptance check passes. The only ambiguity was SKILL.md landing at exactly 170 lines (the plan's strict `-gt 170` check targets 171+ but its narrative guidance says "between 170 and 185"); the file is within the stated budget and the strict under-250 hard gate is satisfied with 80 lines of headroom.

## Handoff to Phase 10 (Integration Discovery — MCP Path)

Phase 2 Design now emits `.agentbloc/team/agent-profiles.yaml` with shape locked in `references/agent-profile-schema.md`. Phase 10's Integration Discovery reads this file's `agents[].tools[]` arrays to know which integrations to search for. The subagent at `.claude/agents/designer-agent.md` is the invocation target. Phase 3 cannot proceed without a validated agent-profiles.yaml — the `agent_profiles_validated` sub-gate is load-bearing for the transition.

Phase 9 Designer Agent is now structurally complete (3/3 plans). The wiring is symmetric with Phase 8 Business Graph Foundation: the same three-edit SKILL.md pattern, the same sub-gate vocabulary style (business_graph_validated → agent_profiles_validated), the same surgical-insert technique on the Phase N design protocol. Future phases (10, 11, 12) can pattern-match this symmetry one phase later.

## Commits

- `3b312ba` — feat(09-03): wire Designer subagent into phase-2-design.md
- `783b538` — feat(09-03): wire agent_profiles_validated sub-gate + Phase 2 Summary + Phase 3 precondition

## Self-Check: PASSED

- Created file exists: `.planning/phases/09-designer-agent/09-03-SUMMARY.md` — FOUND
- Commit `3b312ba` — FOUND (feat(09-03): wire Designer subagent into phase-2-design.md)
- Commit `783b538` — FOUND (feat(09-03): wire agent_profiles_validated sub-gate + Phase 2 Summary + Phase 3 precondition)
- phase-2-design.md grew from 313 → 376 lines with zero em-dashes
- SKILL.md grew from 163 → 170 lines (under 250 budget) with zero em-dashes
- All Phase 9 ROADMAP success criteria wired end-to-end
