---
phase: 09-designer-agent
plan: 01
subsystem: designer-agent
tags: [orchestration-patterns, agent-profiles, yaml-schema, crewai, adk, mesh-topology]

requires:
  - phase: 08-business-graph-foundation
    provides: Business Graph schema + Arco Rooms input fixture (consumed by the YAML fixture + cross-linked from the trigger enum)
provides:
  - orchestration-patterns.md (5-pattern catalog + topology decision table + framework inheritance)
  - agent-profile-schema.md (YAML schema + 3 bounded enums + 8-check validation checklist)
  - arco-rooms-agent-profiles.yaml (canonical 3-agent test fixture)
affects: [09-02-designer-subagent, 09-03-skill-wiring, 12-deploy-pipeline, 13-runtime, 14-briefing-agent, 15-anticipation, 16-e2e-validation]

tech-stack:
  added: []
  patterns:
    - "Three-tier field obligation matrix (REQUIRED / RECOMMENDED / OPTIONAL) mirroring business-graph-schema.md"
    - "Prose-checklist validator per D-13 (no external ajv / yamllint runtime)"
    - "Bounded enum tables for all free-form fields (autonomy, trigger, topology)"
    - "Surgical-patch re-run behavior per D-26 (never regenerate on user edits)"

key-files:
  created:
    - .claude/skills/agentbloc/references/orchestration-patterns.md
    - .claude/skills/agentbloc/references/agent-profile-schema.md
    - .claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml
  modified: []

key-decisions:
  - "D-24 normalized: 5 orchestration patterns use ADK vocabulary (Sequential / Parallel / Loop / Event-driven / Conversational) instead of PDF's verbose Graph / Negotiation / Role-delegation / Handoff / Bus naming"
  - "D-23 default topology: mesh on ambiguity (matches ClaudeClaw SendMessage pattern, degrades to pipeline if only 1 agent)"
  - "D-27 framework inheritance table: 6 frameworks (CrewAI / AG2 / Google ADK / LangGraph / Mastra / Paperclip) each with one-line AgentBloc application"
  - "D-28 structural twin: agent-profile-schema.md inherits the full spine of business-graph-schema.md (TOC + When This Applies + Schema Definition + Field Obligation Matrix + Bounded Enums + Validation Checklist + Emission Protocol + Re-run Behavior + Schema Versioning Rules)"
  - "D-22 three-tier schema: REQUIRED (refuse to emit), RECOMMENDED (emit with warnings), OPTIONAL (silent defaults); schema_version is integer 1"
  - "D-30 fixture scope: 3 requested agents only (gestor-documental, gestor-cobros, recepcionista); the 2 anticipated agents (Analista Rentabilidad, Gestor Incidencias) are Phase 15 work"

patterns-established:
  - "Reference spine: H1 + blockquote + TOC + When This Applies + content sections + Quick Reference. Cross-links use shorthand relative paths (no references/ prefix) for sibling files."
  - "Bounded-enum-as-table: every free-form field defines its allowed values in a 3-4 column markdown table with definition + signal + example, never as prose list."
  - "Validation as prose checklist: ordered numbered checks with FAIL / WARN outcomes, no external validator code, no ajv / yamllint dependency."
  - "Surgical patch semantics: Designer applies structured edits (rename / delete / add-tool / change-autonomy / change-topology / change-blast-radius) in-place to the YAML and bumps team.modified_at; never regenerates from Business Graph."

requirements-completed: [DSGN-02, DSGN-03, DSGN-04, ORCH-01, ORCH-02, ORCH-03, ORCH-04]

duration: 22min
completed: 2026-04-21
---

# Phase 9 Plan 1: Designer Agent Contract Files Summary

**5-pattern orchestration catalog + three-tier agent-profiles.yaml schema (CrewAI-shaped) + canonical 3-agent Arco Rooms fixture, all structurally twinned with Phase 8 references so Designer subagent (09-02) and SKILL.md wiring (09-03) have concrete contracts to consume**

## Performance

- **Duration:** 22 min
- **Started:** 2026-04-21T14:00:00Z
- **Completed:** 2026-04-21T14:22:00Z
- **Tasks:** 3
- **Files created:** 3

## Accomplishments

- Locked the 5 universal orchestration patterns (Sequential / Parallel / Loop / Event-driven / Conversational) with ADK-preserved naming so future codegen can map one-to-one onto Google ADK primitives
- Locked the 4-topology decision table (pipeline / mesh / hierarchy / swarm) with mesh as the ambiguity default
- Locked the canonical `agent-profiles.yaml` schema: `schema_version` + `team` (name + topology + rationale) + `agents[]` (CrewAI role/goal/backstory + tools + triggers + autonomy + outputs + escalation + dependencies + blast_radius + model) + `orchestration.workflows[]` (type + agents + trigger + why + steps/flow)
- Defined three bounded enums: Autonomy (full/semi/supervised), Trigger (cron/event/manual/inter-agent - extends Business Graph enum with inter-agent for peer calls), Topology (pipeline/mesh/hierarchy/swarm)
- Defined the 8-check Validation Checklist Designer walks before emitting the YAML (checks 1-7 block emission, check 8 warns)
- Documented the surgical-patch re-run behavior (D-26) - Designer NEVER regenerates from the Business Graph on user edits
- Shipped the canonical 3-agent Arco Rooms fixture (gestor-documental + gestor-cobros + recepcionista) with 2 workflows (cobro-diario sequential + unmatched-payment-alert event-driven), parseable by python3 yaml.safe_load with every REQUIRED field populated and every workflow agent ID + dependency resolving to an agent in agents[]

## Task Commits

Each task was committed atomically:

1. **Task 1: Create orchestration-patterns.md** - `1f745a8` (feat)
2. **Task 2: Create agent-profile-schema.md** - `4bae6eb` (feat)
3. **Task 3: Create arco-rooms-agent-profiles.yaml fixture** - `fd59a0f` (feat)

## Files Created/Modified

- `.claude/skills/agentbloc/references/orchestration-patterns.md` (121 lines) - 5-pattern catalog + topology decision table + 6-framework inheritance + pattern selection heuristics + Quick Reference
- `.claude/skills/agentbloc/references/agent-profile-schema.md` (178 lines) - full YAML schema definition + three-tier field obligation matrix + 3 bounded enum tables (autonomy/trigger/topology) + 8-check validation checklist + emission protocol + re-run behavior with D-26 surgical-patch default + schema versioning rules
- `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` (96 lines) - canonical 3-agent test fixture with schema_version=1, mesh topology, 3 agents with all REQUIRED fields populated, 2 orchestration workflows (sequential + event-driven)

## Final Schema Shape

```yaml
schema_version: 1
team:
  name: "string"
  topology: "pipeline | mesh | hierarchy | swarm"
  topology_rationale: "string"
  modified_at: "ISO-8601 timestamp"
  briefing_agent_id: "string | null"

agents:
  - id: "string"
    role: "string"
    goal: "string"
    backstory: "string | null"
    tools: ["string"]
    triggers:
      - type: "cron | event | manual | inter-agent"
    autonomy: "full | semi | supervised"
    outputs:
      - type: "string"
        schema: "string | null"
    escalation: "string | null"
    dependencies: ["<other-agent-id>"]
    blast_radius: 1 | 2 | 3 | 4
    model: "opus | sonnet | haiku | null"

orchestration:
  workflows:
    - id: "string"
      type: "sequential | parallel | loop | event-driven | conversational"
      agents: ["<agent-id>", ...]
      trigger:
        type: "cron | event | manual"
      why: "string"
      steps: ["string", ...]
      flow: "string | null"
```

## The 5 Orchestration Patterns (D-24)

| Pattern | ADK Name | Signal From Business Graph | Designer Picks When | Arco Rooms Example |
|---------|----------|---------------------------|---------------------|--------------------|
| Sequential | SequentialAgent | Ordered steps with dependencies | Step N depends on step N-1 | Cobro mensual: verify -> remind -> generate -> update |
| Parallel | ParallelAgent | Independent agents, results merge | Weekly reports from 3 data sources | Weekly Report assembly |
| Loop | LoopAgent | Same step repeats until condition met | Poll until due date, retry until response | Check-in reminder loop |
| Event-driven | Bus pattern | Agent wakes on external event | Most AgentBloc flows | Recepcionista wakes on Gmail |
| Conversational | Negotiation | Multi-party deliberation via SendMessage | Rare; approval from 2+ agents | Finance + legal >= EUR 1000 refund |

## Topology Decision Table (D-23)

| Topology | Signal From Business Graph | Example | Agent Count |
|----------|---------------------------|---------|-------------|
| Pipeline | One linear process with ordered handoffs | Single-process cobro flow | 1-3 |
| Mesh | Peer-calling agents (default on ambiguity) | Arco Rooms 3-agent team | 3-8 |
| Hierarchy | One lead orchestrates per-domain workers | 5-15 agent org with briefing-agent | 5-15 |
| Swarm | N independent parallel agents | Multi-tenant watchdog | 5+ |

## Validation Checklist (D-13 prose-checklist validator)

1. **Check 1:** `schema_version` present and equals `1` (REQUIRED, auto-set)
2. **Check 2:** `team.name` non-empty + `team.topology` in {pipeline, mesh, hierarchy, swarm} (REQUIRED)
3. **Check 3:** `agents[]` length >= 1 (REQUIRED)
4. **Check 4:** Every agent has unique `id`, non-empty `role`, non-empty `goal`, `tools[]` (>=1), `triggers[]` (>=1), `autonomy` in {full, semi, supervised}, `blast_radius` in {1,2,3,4} (REQUIRED)
5. **Check 5:** Every `triggers[].type` in {cron, event, manual, inter-agent} with required sub-field (REQUIRED)
6. **Check 6:** `orchestration.workflows[]` length >= 1, every workflow has `type` in 5-pattern enum, `agents[]` (>=1), and a `trigger` (REQUIRED)
7. **Check 7:** Every `workflows[].agents[]` id AND every `agents[].dependencies[]` id resolves to an entry in `agents[]` (ORCH-04) (REQUIRED)
8. **Check 8:** RECOMMENDED fields populated or explicitly `null` (WARN)

## Canonical Fixture Agent IDs

The 3 agents in `arco-rooms-agent-profiles.yaml` (per D-30):
- `gestor-documental` - Invoice Collection Specialist (blast_radius 2, full autonomy, cron 0 22 * * *)
- `gestor-cobros` - Payment Reconciliation Engine (blast_radius 2, semi autonomy, cron 30 22 * * * + inter-agent)
- `recepcionista` - Daily Operations Reporter (blast_radius 4, semi autonomy, cron 0 23 * * *)

**Confirmed absent per D-30 scope boundary (Phase 15 work):**
- Analista Rentabilidad (NOT in fixture)
- Gestor Incidencias (NOT in fixture)

Verified via grep: `grep -q "Analista Rentabilidad\|analista-rentabilidad\|Gestor Incidencias\|gestor-incidencias" fixture` returns no match.

## Decisions Made

- Followed the plan's exact emission specifications for all three artifacts; no architectural deviations
- Kept orchestration-patterns.md at the lower end of the 120-200 target range (121 lines) by using tables over prose
- agent-profile-schema.md landed at 178 lines (plan target 150-230), in the sweet spot for a schema reference
- Fixture kept strictly at the 3 requested agents per D-30; no anticipation leakage

## Deviations from Plan

None - plan executed exactly as written. All three files match their specified structural twins (frameworks.md for orchestration-patterns.md, business-graph-schema.md for agent-profile-schema.md, arco-rooms-business-graph.json for the YAML fixture). Validation assertions all pass cleanly on first YAML write.

## Issues Encountered

None. The plan's specifications were load-bearing and complete; zero blocking issues, zero bugs, zero missing functionality.

## User Setup Required

None - no external service configuration required. These are design-phase contract files; they do not touch runtime infrastructure.

## Next Phase Readiness

**Handoff to Plan 09-02 (Designer Subagent):**
The Designer subagent at `.claude/agents/designer-agent.md` will read these three files inside its forked context:
- `agent-profile-schema.md` is the contract Designer must satisfy (Validation Checklist + Field Obligation Matrix drive emission)
- `orchestration-patterns.md` is the catalog Designer cites when classifying workflows and selecting topology
- `arco-rooms-agent-profiles.yaml` is the verification target for Phase 16 end-to-end validation

**Handoff to Plan 09-03 (SKILL.md + phase-2-design.md wiring):**
- SKILL.md Phase 2 load list must reference both `orchestration-patterns.md` and `agent-profile-schema.md` (per D-29 unconditional-load list extension)
- The `agent_profiles_validated` sub-gate maps to the Validation Checklist in `agent-profile-schema.md` (checks 1-7 block emission, check 8 warns)
- The Phase 3 precondition verifies `.agentbloc/team/agent-profiles.yaml` exists and validates before Phase 3 can begin
- `phase-2-design.md` Step 8 (Designer Subagent Invocation) references the three files as required reading

**No blockers for downstream plans.** All contracts are locked, all bounded enums are closed sets, all cross-links use shorthand relative paths so companion-reference resolution works without the `references/` prefix.

## Self-Check: PASSED

**Files verified:**
- FOUND: .claude/skills/agentbloc/references/orchestration-patterns.md (121 lines)
- FOUND: .claude/skills/agentbloc/references/agent-profile-schema.md (178 lines)
- FOUND: .claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml (96 lines, parses clean)

**Commits verified:**
- FOUND: 1f745a8 (Task 1)
- FOUND: 4bae6eb (Task 2)
- FOUND: fd59a0f (Task 3)

**Acceptance criteria verified:**
- orchestration-patterns.md: all 6 framework names + 5 pattern names + 4 topology names + both cross-links present; 0 em-dashes; 121 lines (120-200 range); 7 H2 sections (>=6)
- agent-profile-schema.md: schema_version + 3 obligation tiers + 3 autonomy values + 4 trigger types + 4 topology values + 5 orchestration patterns + .agentbloc/team/agent-profiles.yaml path + all 3 cross-links + ORCH-04 + D-26 surgical-patch rule + yaml fence present; 0 em-dashes; 178 lines (150-230 range); 11 H2 sections (>=10)
- arco-rooms-agent-profiles.yaml: parses as valid YAML; schema_version=1; topology=mesh; exactly 3 agents {gestor-documental, gestor-cobros, recepcionista}; all REQUIRED fields populated; autonomy values from enum; trigger types from enum; 2 workflows with types from 5-pattern enum; all workflow agent IDs and agent dependencies resolve (ORCH-04); the 2 anticipated agents (Analista Rentabilidad, Gestor Incidencias) are ABSENT per D-30; 0 em-dashes

---
*Phase: 09-designer-agent*
*Completed: 2026-04-21*
