# Phase 15: Anticipation Engine , Discussion Log

**Mode:** `--auto` lean inline (no human Q&A; Claude selected recommended defaults per autonomous-mode user memory directive: "Drive AgentBloc phases autonomously , make implementation decisions yourself using PDF scope + REQUIREMENTS as ground truth")
**Date:** 2026-04-26

## Decisions resolved without prompting (5)

### Q1: Same-invocation anticipation vs separate sub-agent?

**Resolution: D-99 same-invocation.** Spawning a separate "anticipation-agent" subagent would (a) duplicate Business Graph reads, (b) duplicate schema validation, (c) require two main-session round-trips. The user-facing pause point is the rendered TABLE in Phase 2 Step 8; anticipation must surface in the SAME table. Per Phase 14 D-88 precedent (briefing-agent runs as deployed agent, not internal subagent), we minimize subagent-spawn overhead.

### Q2: How many business-type mappings to ship in v2.0?

**Resolution: D-100 ship 5.** rental-property-management (canonical Arco Rooms), ecommerce, freelance-services, restaurant, professional-services. Validates the pattern + covers most common SMB shapes. Future mappings ship as additive updates (no schema bump per Phase 14 D-98 precedent). Bar of "5 mappings * 3 evidence sources = 15 cited URLs" is the v2.0 ship bar.

### Q3: Schema extension via REQUIRED or RECOMMENDED tier?

**Resolution: D-101 RECOMMENDED tier (Validation Check 9 WARN-not-FAIL).** Forcing REQUIRED would block low-friction conversational additions (user says "add a profitability analyst" without supplying rationale + 3 sources). The CONSULTING-PRODUCT credibility gate is anticipation-heuristics.md (Designer auto-emits ALWAYS populates rationale + sources from the map); per-agent metadata is the per-instance shape and accepts partial values. WARN tier surfaces gaps in the rendered TABLE.

### Q4: Where does declined.json live?

**Resolution: D-102 `.agentbloc/graph/declined.json`** (sibling to business-graph.json). Decline is BUSINESS-LEVEL state, not team-level , persists across team regenerations + conversational edits. JSON array (not JSONL) because the file is read once at Designer invocation start, not append-streamed during agent execution. Append-only per Phase 14 D-87 trace-integrity pattern.

### Q5: How does SKILL.md change?

**Resolution: D-103 ONE new See-line in Phase 2 entry + Summary Gate paragraph extension; NO new sub-gate.** Anticipation is part of the existing `agent_profiles_validated` sub-gate; Validation Check 9 is WARN not FAIL so it does not block emission. NO new Phase 5/6 wiring (Phase 12 deploy-engine + Phase 14 briefing-agent already consume agent-profiles.yaml; new fields are OPTIONAL and existing consumers ignore them per backward-compatibility per D-101).

## Auto-decisions cited from upstream (no re-decision)

| Decision | Source | Phase 15 application |
|---|---|---|
| D-21 Designer subagent at .claude/agents/designer-agent.md | Phase 9 | Phase 15 extends in-place, no new subagent file |
| D-26 Conversational edits via surgical patches | Phase 9 | Decline of anticipated agent is a surgical patch + append to declined.json |
| D-30 Arco Rooms 3 requested + 2 anticipated agents | Phase 9 | Plan 15-01 Task 2 fixture ships full 5-agent team |
| D-58 SKILL.md context budget (subagent-only files NOT cited) | Phases 9-14 | declined-agents-schema.md is subagent-only; SKILL.md does NOT cite it |
| D-83 Surgical-edit discipline (insertion-only) | Phase 13 | Plan 15-02 Tasks 4-5 insert only; Task 3 documented exception |
| D-93 Sub-gate pattern (monitor_wired ANDed with deployment_artifacts_emitted + runtime_wired) | Phase 14 | NO new sub-gate added in Phase 15 (anticipation is part of existing agent_profiles_validated) |
| D-98 Schema additive extension (backward-compatible, schema_version unchanged) | Phase 14 | Plan 15-02 Task 2 adds 3 OPTIONAL fields; agent-profiles.yaml schema_version stays at 1 |

## Items the user could re-decide later (low priority)

1. **5 business-type mappings vs more:** if v2.5 consulting engagements surface common gaps (e.g., SaaS subscription business, healthcare clinic), add mappings additively. v2.0 ships 5 to validate the pattern.
2. **REQUIRED vs RECOMMENDED tier on Validation Check 9:** if Phase 16 E2E run shows users frequently emitting partial anticipated agents without rationale, tighten to REQUIRED in v2.5. v2.0 ships RECOMMENDED to favor low-friction conversational additions.
3. **declined.json business-level vs team-level:** if user feedback indicates that a user wants different teams under the same business to have different declined sets (e.g., "for the prod team I declined Profitability Analyst, but I want it on the test team"), split into business-level + team-level files in v2.5. v2.0 ships business-level only.

---

*All decisions per autonomous-mode user memory directive: "Drive AgentBloc phases autonomously , make implementation decisions yourself using PDF scope + REQUIREMENTS as ground truth; ask only when genuinely blocked or for user-preference calls"*
