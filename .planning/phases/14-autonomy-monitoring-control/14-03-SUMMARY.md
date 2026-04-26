# Plan 14-03 Summary: SKILL.md + Templates + Subagents Surgical Wiring

Plan 14-03 closes the Phase 14 structural loop with 7 surgical edits across 8 existing files. No new files emitted; insertion-only edits per Phase 13 D-83 surgical-edit discipline.

## Surgical edits

| # | File | Edit | Commit | Closes |
|---|------|------|--------|--------|
| 1 | `templates/deployed-agent-skill-full.md.tmpl` | Side-effect Approval Routing paragraph (full=proceed semantics) | `b059896` | AUTON-01 prose layer (full) |
| 2 | `templates/deployed-agent-skill-semi.md.tmpl` | Side-effect Approval Routing paragraph (semi=approval-on-external) + $TOOL_REASONING | `6ea5ffe` | AUTON-01 + AUTON-02 prose (semi) |
| 3 | `templates/deployed-agent-skill-supervised.md.tmpl` | Side-effect Approval Routing paragraph (supervised=stricter scope) + $TOOL_REASONING | `cb276da` | AUTON-01 + AUTON-02 prose (supervised) |
| 4 | `references/phase-5-deployment.md` | Step 7.6 Monitor Wiring Hand-off section (between Step 7.5 + Step 8) | `4e2c114` | All 16 Phase 14 reqs at user-visible deploy-flow layer |
| 5 | `references/incident-response.md` | Escalation Protocol H2 section (after Phase 13 Runtime Kill-Switch Semantics) | `8b327ae` | AUTON-04 + AUTON-05 user-facing reference |
| 6 | `SKILL.md` | 4 surgical edits: 4 new See-lines + monitor_wired sub-gate + Summary Gate update + Phase 6 Precondition extension | `c002d2c` | D-93 |
| 7 | `.claude/agents/deploy-engine.md` + `.claude/agents/runtime-engine.md` | deploy-engine: briefing-agent template emission + monitor block in registry; runtime-engine: 4 shell scripts (approval-router.sh + escalation-router.sh + claude-wrap.sh + activity-feed-merge.sh) + autonomy-gate.sh hook | `eded9e9` | Subagent extension; D-67 + D-80 narrow Bash allow-lists UNCHANGED |

## D-XX decisions applied

- **D-58 (context-budget):** SKILL.md Phase 5 entry adds ONLY 4 new See-lines; briefing-agent.md.tmpl + autonomy-gate.sh + claude-wrap.sh + escalation-router.sh + approval-router.sh + activity-feed-merge.sh are NOT loaded at Phase 5 entry (subagent-only / runtime-only).
- **D-83 (surgical-edit discipline):** All 7 edits insertion-only; preservation verified by grep for Phase 12/13 anchor strings (Step 7.5, Step 8, Runtime Kill-Switch Semantics, deployment_artifacts_emitted, runtime_wired) intact post-edit.
- **D-93 (SKILL.md surgical wiring):** monitor_wired sub-gate ANDed with deployment_artifacts_emitted + runtime_wired in State Transitions; Phase 6 Precondition verifies briefing_agent_id + approval_thread_id non-null; Summary Gate cites BRIEFING-FIRST-RUN.md.
- **D-94 (deployed-skill template approval-routing):** 3 templates extended with autonomy-appropriate paragraphs; $TOOL_REASONING contract cited in semi + supervised variants.
- **D-95 (phase-5-deployment Step 7.6):** Mirrors Phase 13 Step 7.5 grammar; cites all 8 Plan 14-01 + 14-02 references; lists 16 closed requirements.
- **D-96 (incident-response Escalation Protocol):** H2 section appended after Phase 13 Runtime Kill-Switch Semantics; documents 4-part template + persistent halt + /resume.

## All 16 Phase 14 requirements closed end-to-end

| Requirement | Closure path |
|-------------|--------------|
| AUTON-01 (autonomy levels) | autonomy-controller.md + 3 deployed-skill templates per D-94 + autonomy-gate.sh hook |
| AUTON-02 (approval routing) | approval-router.md + autonomy-gate.sh + Telegram approvals thread per CTRL-01 |
| AUTON-03 (append-only approval log) | jsonl-log-schema.md approvals.jsonl + approval-router.md flow |
| AUTON-04 (escalation with full context) | escalation-protocol.md + escalations Telegram thread + persistent halt |
| AUTON-05 (4-part escalation message) | escalation-protocol.md template + 3 worked examples |
| MONITOR-01 (canonical JSONL schema) | jsonl-log-schema.md 12-field schema + JCS canonicalization |
| MONITOR-02 (per-agent per-day path) | jsonl-log-schema.md path convention `.claude/agents/logs/<DATE>/<agent-id>.jsonl` |
| MONITOR-03 (registry monitor block) | deploy-engine.md emits monitor: block in registry.yaml per D-93 |
| MONITOR-04 (default briefing agent) | briefing-agent.md.tmpl + deploy-engine emission per team |
| MONITOR-05 (hierarchy chain) | reporting-hierarchy.md 4-layer chain |
| MONITOR-06 (pluggable presentation) | briefing-renderer.sh format-{telegram,html,json} stubs in briefing-agent.md.tmpl |
| CTRL-01 (separate approval thread) | approval-router.md + 3-thread separation in registry.yaml monitor |
| CTRL-02 (cost tracking) | jsonl-log-schema.md cost_usd field + billing-rates.md + claude-wrap.sh + agent-memory-schema.md last-run.json v2 |
| CTRL-03 (task locking) | task-locking.md + flock + JSON lock-file |
| CTRL-04 (status badges) | agent-memory-schema.md last-run.json status ENUM + briefing message format |
| CTRL-05 (activity feed) | activity-feed.md + activity-feed-merge.sh (briefing-agent invokes daily) |

## Phase 14 structural completion signal

After this plan, the user-facing flow is:

1. SKILL.md Phase 5 entry loads phase-5-deployment.md + deploy-protocol.md + n8n-integration.md + runtime-coordination.md + correlation-id.md + jsonl-log-schema.md + autonomy-controller.md + approval-router.md + reporting-hierarchy.md (9 references unconditionally per D-58)
2. deploy-engine subagent emits DEPLOY-REPORT.md (Phase 12 + Phase 14 briefing-agent SKILL.md + monitor block; closes `deployment_artifacts_emitted`)
3. runtime-engine subagent emits RUNTIME-REPORT.md (Phase 13 + Phase 14 4 shell scripts + autonomy-gate hook; closes `runtime_wired`)
4. briefing-agent first-run emits BRIEFING-FIRST-RUN.md (Phase 14; closes `monitor_wired`)
5. SKILL.md State Transitions Phase 5 -> Phase 6 gates on ALL THREE sub-gates true
6. Phase 6 Evolution Precondition verifies registry.yaml runtime block AND monitor block presence

Phase 14 is structurally complete. Ready for `/gsd-verify-phase 14`.

## Verification status

All per-task verifies passed at commit time. Em-dash gate clean across new prose insertions (legacy em-dashes in unchanged upstream content out of scope per Phase 13 D-83 precedent). All Phase 12/13 cross-references intact post-edit. D-58 grep-for-absence verified on SKILL.md (subagent-only files NOT cited).
