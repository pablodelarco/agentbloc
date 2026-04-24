# Phase 13: Multi-Agent Runtime - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md , this log preserves the rationale + alternatives considered.

**Date:** 2026-04-24
**Phase:** 13-multi-agent-runtime
**Mode:** `--auto` (autonomous, no interactive questions)
**Ground truth:** `.planning/v2.0-PROMPT.pdf` (authoritative) + `.planning/REQUIREMENTS.md` RUNTIME-01..07 + Phase 8-12 CONTEXT.md accumulated decisions + v1.0 SECR-05 kill-switch pattern

---

## Autonomous decisions locked (per `autonomous_mode.md` memo)

Pablo authorized expert-judgment decisions on implementation gray areas derivable from PDF + REQUIREMENTS + prior-phase decisions. The following decisions were made without interactive AskUserQuestion because each is externally grounded in a specific artifact (PDF page, REQUIREMENTS requirement, or inherited D-XX decision from Phases 8-12).

| # | Decision Area | Ground Truth | Decision |
|---|---------------|--------------|----------|
| D-73 | Wake-job template structure | PDF page 5 + RUNTIME-01/02/05 + Phase 12 D-62 template discipline | 6-section markdown (kill-switch / correlation-ID / memory read / input parse / execute / state write) across 3 template variants (cron / webhook / inter) per trigger type; dispatched by runtime-engine |
| D-74 | n8n webhook payload envelope | PDF page 5 trigger matrix + RUNTIME-02/03 + Phase 10 D-34 verification contract pattern | 4-field JSON envelope (schema_version, correlation_id, agent_id, trigger) with nested event-specific payload; runtime-agnostic fallback to local HTTP listener + file-based payload handoff |
| D-75 | Correlation-ID format | PDF page 5 + RUNTIME-06 + audit-logging.md `sess-<agent>-<NNN>` inherited pattern | `<trigger-source>-<UTC-Z-compact>-<nonce6>` with bounded trigger enum; propagation via env var + JSON payload + SendMessage metadata; child append `-sub-<NNN>` inherited |
| D-76 | Multi-agent coordination pattern | PDF page 5 verbatim "El primer agente que detecta que necesita a otro spawna el equipo" + RUNTIME-04/05 | First-agent-detects-need spawns TeamCreate with workflow.agents roster; single-agent workflows bypass TeamCreate at wake-template selection time; declared-vs-dynamic spawn_rule enum; writeStateHandoff fallback for no-ClaudeClaw runtimes |
| D-77 | Kill-switch runtime enforcement | v1.0 SECR-05 + PDF page 6 escalation/autonomy section + RUNTIME-07 + incident-response.md dual-path | 3-point enforcement (wake-time / per-side-effect-tool / team-transition); Telegram /stop n8n route YAML stub emitted; team-wide halt dissolves at next safe state transition |
| D-78 | Registry runtime block | Phase 12 D-63 registry schema + RUNTIME-04/05/06/07 | Additive top-level `runtime` block with correlation_prefix + team_timeout + coordination_preference + crontab manifest pointer + workflows + webhook_endpoints; schema_version: 1 independent of top-level |
| D-79 | Example fixture cadence | Phase 11 + Phase 12 fixture precedent + PDF Arco Rooms canonical test case | Two fixtures: narrative flow (3 scenarios incl. kill-switch mid-team) + structural artifacts (wake.md / crontab / n8n-routes / extended registry) |
| D-80 | runtime-engine subagent | Phase 12 D-67 deploy-engine narrow Bash precedent + RUNTIME wiring responsibilities | `.claude/agents/runtime-engine.md`, context:fork, scoped tools, Bash allow-list locked to 5 command prefixes (`crontab -e`, `crontab -l`, `shasum -a 256`, `claude agents list`, `claude mcp list`), NO WebFetch / other MCPs |
| D-81 | Phase 5 sub-gate extension | Phase 12 `deployment_artifacts_emitted` sub-gate precedent + D-11 gate-as-artifact-emission pattern | New sub-gate `runtime_wired` ANDed into Phase 5 gate; Phase 6 Evolution precondition extends to verify registry.runtime.cron_registered_at OR runtime.webhook_endpoints non-empty |
| D-82 | Reference-file inventory + line budgets | Phase 11 + Phase 12 cadence + D-29 SKILL.md 250-line cap | 3 new references + 3 templates + 2 fixtures + 1 subagent + 4 surgical edits; SKILL.md lands at ~203 lines with 47-line headroom |
| D-83 | Plan decomposition | Phase 9 / Phase 11 / Phase 12 three-plan cadence + ROADMAP 2-3 plan estimate | 3 plans: (13-01) contracts + fixtures, (13-02) runtime-engine subagent, (13-03) surgical wiring; sequential execution main-tree; no worktree per gsd-executor sandbox lesson |

## Why --auto worked for Phase 13

All 11 new decisions (D-73..D-83) are derivable:
- **From PDF directly:** D-73 (wake trigger structure), D-74 (n8n envelope), D-75 (correlation propagation), D-76 (first-agent-detects), D-77 (kill-switch inheritance)
- **From REQUIREMENTS.md literals:** D-81 (gate semantics), D-83 (3 plans per ROADMAP "Plans (est): 2-3")
- **From Phase 9/11/12 inherited precedent:** D-78 (registry additive pattern), D-79 (fixture cadence), D-80 (subagent structure), D-82 (reference inventory)

No gray areas required clarification because:
1. The PDF authoritatively defines the trigger matrix (cron / webhook / inter) and coordination pattern (first-agent-detects-need spawns).
2. RUNTIME-01..07 are atomic requirements with no internal inconsistencies (unlike Phase 12's DEPLOY-01/MEM-01/DEPLOY-05 triple-tension that required user review).
3. All Phase 13 artifact shapes mirror already-locked Phase 12 precedents (D-59 three-namespace, D-62 template split, D-67 narrow Bash) with additive-only changes.
4. v1.0 SECR-05 kill-switch pattern is fully documented in incident-response.md; Phase 13 just runs the actions.

## Areas explicitly considered and resolved without external escalation

- **n8n integration depth** , Phase 13 emits YAML stubs, not automated pushes. Why: n8n route installation requires an n8n MCP wrapper which is a separate integration effort; out of Phase 13 scope. Deferred to v2.5+ (noted in deferred section).
- **Distributed / multi-host runtime** , Rejected. v2.0 is explicitly single-host per PROJECT.md constraints. Deferred to v3.0+.
- **SQLite log persistence** , Rejected. D-1 files-first. JSONL logs are the v2.0 primary storage. Deferred to v2.5+.
- **Runtime observability** (live dashboards, web UI) , Rejected. Phase 13 emits grep-able correlation IDs; visual tooling is v2.5+.
- **Generic signal-interrupt for mid-prose kill** , Rejected for v2.0. Claude Code has no prose-level interrupt primitive that works across ClaudeClaw and plain runtimes; D-77 three-point enforcement is the realistic best-effort.
- **UUID vs. readable correlation IDs** , Chose readable (D-75). UUIDs force lookup tables; readable IDs enable single-grep end-to-end tracing, which matches Pablo's operational workflow on mobile Telegram.

## Canonical References added during analysis (not decided interactively)

- `.planning/v2.0-PROMPT.pdf` page 5 "Fase 5: Runtime y Gestión Multi-Agente" (read in full during analysis)
- `.planning/v2.0-PROMPT.pdf` page 7-8 Stack Decisions section (ClaudeClaw as runtime, n8n as event bus)
- `.claude/skills/agentbloc/references/scheduling.md` (cron + DST + pipeline spacing)
- `.claude/skills/agentbloc/references/telegram-patterns.md` (thread-per-domain, approval-by-reply)
- `.claude/skills/agentbloc/references/audit-logging.md` (correlation-ID pattern inherited)
- `.claude/skills/agentbloc/references/incident-response.md` (kill-switch dual-path inherited)
- `.claude/skills/agentbloc/references/phase-5-deployment.md` (existing kill-switch + crontab template, line anchors for Step 7.5 insertion)
- `.claude/skills/agentbloc/references/orchestration-patterns.md` (5-pattern table inherited)
- `.claude/skills/agentbloc/references/agent-profile-schema.md` (triggers + dependencies + topology enum)
- `.claude/skills/agentbloc/references/agent-memory-schema.md` (memory + state schema inherited)
- Phase 12 `.planning/phases/12-deploy-pipeline-agent-memory/12-CONTEXT.md` (D-59..D-72 inherited)
- Phase 11 `.planning/phases/11-integration-discovery-browser-fallback/11-CONTEXT.md` (D-35 + D-45 + D-46 inherited)
- Phase 9 `.planning/phases/09-designer-agent/09-CONTEXT.md` (D-21 + D-23 + D-24 + D-29 inherited)

## Deferred Ideas (preserved in CONTEXT.md)

See `13-CONTEXT.md <deferred>` section for the full list (17 items). None are scope creep; all are explicitly phase-assigned (Phase 14 / Phase 15 / Phase 16 / v2.5 / v3.0 / v4.0) with traceable requirement IDs.
