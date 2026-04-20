# Roadmap: AgentBloc

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-7 (shipped 2026-04-18) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v2.0 Designer + Deploy** — Phases 8-16 (In Progress, scope realigned 2026-04-20 per `.planning/v2.0-PROMPT.pdf`)

## Phases

<details>
<summary>✅ v1.0 Initial Release (Phases 1-7) — SHIPPED 2026-04-18</summary>

- [x] Phase 1: Skill Foundation (2/2 plans) — completed 2026
- [x] Phase 2: Security Cross-Cutting References (3/3 plans) — completed 2026
- [x] Phase 3: Interview and Design Phases (3/3 plans) — completed 2026
- [x] Phase 4: Integration and Confirmation Phases (2/2 plans) — completed 2026
- [x] Phase 5: Deployment Artifacts and Evolution (3/3 plans) — completed 2026
- [x] Phase 6: Repo Polish and Examples (3/3 plans) — completed 2026
- [x] Phase 7: Testing and CI (2/2 plans) — completed 2026-04-18

For full v1.0 details see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md).

</details>

### 🚧 v2.0 Designer + Deploy (In Progress)

Scope source: `.planning/v2.0-PROMPT.pdf`. 79 requirements across 13 categories. Load-bearing build order: Business Graph (8) → Designer (9) → MCP Discovery (10) → Browser Fallback (11) → Deploy + Memory (12) → Runtime (13) → Autonomy + Monitor + Control (14) → Anticipation (15) → Validation + Release (16).

- [ ] **Phase 8: Business Graph Foundation** — Extend v1.0 interview to emit Business Graph JSON. Freeze schema with validator. (INTV-01..04, BGRAPH-01..04 = 8 reqs)
- [ ] **Phase 9: Designer Agent** — AG2 CaptainAgent-pattern subagent that consumes Business Graph, emits `agent-profiles.yaml` with role / goal / backstory / tools / triggers / autonomy / outputs / escalation / dependencies, plus workflow orchestration classification into the 5 patterns. (DSGN-01..07, ORCH-01..04 = 11 reqs)
- [ ] **Phase 10: Integration Discovery — MCP Path** — Four-step search, steps 1-3 only: existing `.mcp.json` → ecosystem MCP install → wrapper MCP generation via `mcp-builder` skill + verification loop + evidence protocol. (INTEG-01..06 = 6 reqs)
- [ ] **Phase 11: Integration Discovery — Browser Fallback** — Step 4 of the four-step search. Playwright + Patchright browser subagent, HAR capture, curl replay, per-service ToS opt-in + license notice, three-tier API classification, output firewall (injection detector + fresh-context verify), PII redaction, detect-and-degrade anti-bot policy. Subsumes the 2026-04-18 "Discovery Agent" research. (BROWSER-01..12 = 12 reqs)
- [ ] **Phase 12: Deploy Pipeline + Agent Memory** — Materialize `agent-profiles.yaml` into `skills/{id}/SKILL.md` + ClaudeClaw job configs + `.mcp.json` merges + per-agent memory directories. Idempotent re-runs with diff presentation. (DEPLOY-01..08, MEM-01..06 = 14 reqs)
- [ ] **Phase 13: Multi-Agent Runtime** — Cron + n8n webhook trigger plumbing. Inter-agent coordination via ClaudeClaw `SendMessage` / `TeamCreate`. Correlation IDs. Kill switch + Telegram `/stop`. (RUNTIME-01..07 = 7 reqs)
- [ ] **Phase 14: Autonomy + Monitor + Control Plane** — Per-agent autonomy levels with approval round-trip + escalation, JSONL structured logging + registry.yaml + briefing agent + hierarchical reporting, Paperclip-inspired control plane (approval queue, cost tracking, task locking, status badges, activity feed). (AUTON-01..05, MONITOR-01..06, CTRL-01..05 = 16 reqs)
- [ ] **Phase 15: Anticipation Engine** — Designer Agent anticipation pass: reads Business Graph, proposes unrequested-but-needed agents from evidence-backed business-type heuristics, `ANTICIPATED` tag in proposal, decline-memory. The consulting-product differentiator. (ANTIC-01..05 = 5 reqs)
- [ ] **Phase 16: End-to-End Validation and Release** — Canonical Arco Rooms test case (5-agent team, 3 requested + 2 anticipated) drives an end-to-end validation run from interview through deploy. TAP additions for the new categories. README + CHANGELOG update. `v2.0.0` git tag. (Cross-cutting; no new requirements)

## Phase Details

### Phase 8: Business Graph Foundation

**Goal**: The v1.0 interview produces a schema-validated Business Graph JSON as a first-class artifact that downstream v2.0 phases can rely on — without breaking the existing interview UX.

**Depends on**: v1.0 Phase 3 (Interview + Design — exists)
**Requirements**: INTV-01, INTV-02, INTV-03, INTV-04, BGRAPH-01, BGRAPH-02, BGRAPH-03, BGRAPH-04

**Success Criteria**:
1. Running the v1.0 Interview against the Arco Rooms scenario produces a `.agentbloc/graph/business-graph.json` file matching the schema in `references/business-graph-schema.md`
2. A Business Graph with a schema-version mismatch or missing required field produces a clear validation error with the specific path, not a generic failure
3. A reader who opens `references/business-graph-schema.md` can understand the full field set without reading the validator code
4. The interview conversation remains bilingual (EN/ES), non-technical, and flows as in v1.0 — the graph emission is a side effect the user doesn't have to think about

**Plans:** TBD (estimated 2)

### Phase 9: Designer Agent

**Goal**: A Claude Code subagent (`.claude/agents/designer-agent.md`, `context: fork`) consumes the Business Graph and autonomously produces an `agent-profiles.yaml` with correct topology selection, grouped roles, orchestration classification, and a presentation-ready team summary that the user can edit conversationally.

**Depends on**: Phase 8 (needs Business Graph + schema)
**Requirements**: DSGN-01, DSGN-02, DSGN-03, DSGN-04, DSGN-05, DSGN-06, DSGN-07, ORCH-01, ORCH-02, ORCH-03, ORCH-04

**Success Criteria**:
1. Running Designer Agent against the Arco Rooms Business Graph produces a valid `agent-profiles.yaml` with 3 requested agents (Gestor Cobros, Recepcionista, Gestor Documental) — Anticipation of the extra 2 happens in Phase 15
2. The produced team YAML validates against a schema check and every workflow resolves every agent reference it cites
3. Every agent profile carries role / goal / backstory / tools / triggers / autonomy / outputs / escalation / dependencies (CrewAI-shaped)
4. Designer Agent cites `references/orchestration-patterns.md` when selecting Sequential / Parallel / Loop / Event-driven / Conversational for each workflow
5. User can conversationally rename, merge, or drop agents and Designer regenerates the YAML with the edits applied (not starting from scratch)

**Plans:** TBD (estimated 3)

### Phase 10: Integration Discovery — MCP Path

**Goal**: For every tool an agent needs, AgentBloc can find, install, or generate an MCP server before falling back to browser automation. Every integration is verified (responds, has scopes, returns expected shape) before the Deploy Pipeline uses it.

**Depends on**: Phase 9 (needs `agent-profiles.yaml` to know which tools to discover)
**Requirements**: INTEG-01, INTEG-02, INTEG-03, INTEG-04, INTEG-05, INTEG-06

**Success Criteria**:
1. A tool with an existing `.mcp.json` entry skips directly to verification
2. A tool with no existing entry but a curated ecosystem MCP is proposed for install with the exact `npx -y` command; user approves; install succeeds
3. A tool with no MCP but a public API results in a wrapper generated at `.mcp/generated/<tool-id>/` that exposes the minimum operations the target agent needs
4. Verification failure (scope missing, credential absent, shape mismatch) surfaces in the conversation with the specific gap named, and the pipeline halts rather than silently deploying a broken integration
5. Every integration claim in the resulting `DEPLOY-REPORT.md` carries URL + package version + last-commit date per the v1.0 evidence protocol

**Plans:** TBD (estimated 3)

### Phase 11: Integration Discovery — Browser Fallback

**Goal**: When MCP search (Phase 10) fails, a browser subagent reverse-engineers the target service with full legal, anti-bot, and output-poisoning safeguards, emitting a schema-locked signed DISCOVERY-REPORT.md that the Deploy Pipeline can consume as a `[DISCOVERED]`-tier integration.

**Depends on**: Phase 10 (triggered when Steps 1-3 fail). Research basis in `.planning/research/` (STACK / FEATURES / ARCHITECTURE / PITFALLS / SUMMARY — committed 2026-04-18).
**Requirements**: BROWSER-01, BROWSER-02, BROWSER-03, BROWSER-04, BROWSER-05, BROWSER-06, BROWSER-07, BROWSER-08, BROWSER-09, BROWSER-10, BROWSER-11, BROWSER-12

**Success Criteria**:
1. Attempting to run browser discovery against a service without a signed `DISCOVERY-LICENSE-NOTICE.md` is refused with the exact missing path cited
2. A successful discovery run produces a valid `DISCOVERY-REPORT.md` with schema-locked YAML front-matter, SHA256 hash, `expires_at` field, and every endpoint carrying a three-tier API classification
3. Attempting to add `playwright-extra`, `puppeteer-extra-plugin-stealth`, a CAPTCHA solver, or a fingerprint-spoofing library to the project fails CI via the deny-list lint
4. A discovery run interrupted mid-flight resumes from `.agentbloc/discovery/<service-slug>/state.json` up to 4 hours later and completes without re-capturing already-captured state
5. PII redaction pipeline catches EU IBAN, US SSN, Luhn-valid credit cards, E.164 phones, and email addresses in a synthetic HAR, with the verification scan failing the run on any residual match
6. Posture-C detection (hardened anti-bot: DataDome / PerimeterX / CAPTCHA challenge) halts the run and emits `DISCOVERY-BLOCKED-REPORT.md` rather than attempting any bypass
7. The fresh-context verification pass successfully detects an injection payload planted in a synthetic response body and isolates it in `untrusted-data` fences

**Plans:** TBD (estimated 3-4)

### Phase 12: Deploy Pipeline + Agent Memory System

**Goal**: An approved `agent-profiles.yaml` becomes a running ClaudeClaw-compatible deployment: skills, jobs, MCP entries, memory directories, a registry, and a deploy report. Re-runs are idempotent. Every generated agent loads and every integration pings.

**Depends on**: Phase 9 (needs the profiles YAML), Phase 10 (needs verified MCP integrations), Phase 11 (needs browser-fallback reports if any)
**Requirements**: DEPLOY-01, DEPLOY-02, DEPLOY-03, DEPLOY-04, DEPLOY-05, DEPLOY-06, DEPLOY-07, DEPLOY-08, MEM-01, MEM-02, MEM-03, MEM-04, MEM-05, MEM-06

**Success Criteria**:
1. Running Deploy Pipeline against the Arco Rooms team produces `skills/gestor-cobros/SKILL.md`, `skills/recepcionista/SKILL.md`, `skills/gestor-docs/SKILL.md` with full prompts, correct MCP references, and autonomy-appropriate instruction language
2. Running Deploy Pipeline twice with the same `agent-profiles.yaml` does not duplicate or corrupt artifacts; a third run with edited profiles surfaces a diff and asks for approval before overwrite
3. The resulting `DEPLOY-REPORT.md` lists what was created, what was updated, what was skipped, and any pending user actions (missing credentials, ToS opt-in needed)
4. Every generated agent has `.claude/agents/<agent-id>/{memory.md, state.json, last-run.json}` with valid content
5. Post-deploy verification (DEPLOY-08) confirms every SKILL.md loads, every MCP server responds, every cron job is registered with ClaudeClaw

**Plans:** TBD (estimated 3)

### Phase 13: Multi-Agent Runtime

**Goal**: Deployed agents wake correctly from cron, from n8n webhooks, and from inter-agent `SendMessage`. Teams assemble and dissolve per ClaudeClaw primitives. Correlation IDs let humans trace a single user event through multiple agent activations. Kill switch halts runs cleanly.

**Depends on**: Phase 12 (needs deployed agents to wake)
**Requirements**: RUNTIME-01, RUNTIME-02, RUNTIME-03, RUNTIME-04, RUNTIME-05, RUNTIME-06, RUNTIME-07

**Success Criteria**:
1. A cron trigger fires at the scheduled time, wakes the correct agent via `claude -p`, and emits a log entry with a new correlation ID
2. An n8n webhook (e.g., simulated "tenant message" from Telegram) wakes the correct agent with the payload attached
3. An agent that needs another agent's output spawns a team via `TeamCreate`, coordinates via `SendMessage`, and the team dissolves when the task is done
4. Correlation ID propagates through the full chain: a single user message appears in multiple agents' logs under the same ID
5. Touching `.agentbloc/KILL_SWITCH` or sending Telegram `/stop` halts the entire active team at the next state transition

**Plans:** TBD (estimated 2-3)

### Phase 14: Autonomy + Monitoring + Control Plane

**Goal**: Every deployed agent has the right autonomy level, surfaces its work through structured JSONL logs, routes approvals to a separate Telegram queue, tracks its own cost, locks shared resources, and reports to a briefing agent that consolidates the team's health for the human.

**Depends on**: Phase 13 (needs runtime events to produce logs + approval round-trips)
**Requirements**: AUTON-01, AUTON-02, AUTON-03, AUTON-04, AUTON-05, MONITOR-01, MONITOR-02, MONITOR-03, MONITOR-04, MONITOR-05, MONITOR-06, CTRL-01, CTRL-02, CTRL-03, CTRL-04, CTRL-05

**Success Criteria**:
1. A `semi`-autonomy agent attempting an external side-effect (send email, post message) sends a Telegram approval request with context and waits for the response before proceeding
2. A `supervised`-autonomy agent proposes every action without executing, and the approval round-trip is append-only logged with approver + outcome
3. The briefing agent, running daily, produces a Telegram message summarizing what each agent did, escalations pending, cost + token totals, and team status badges
4. Simulated resource contention: two agents need the same bank account reconciliation window — the second agent sees `locked_by: <first-agent-id>` and defers
5. Switching from Telegram to a placeholder "web dashboard" presentation requires ZERO changes to any agent's logging code — only a new consumer of the JSONL + registry

**Plans:** TBD (estimated 3-4)

### Phase 15: Anticipation Engine

**Goal**: Designer Agent proposes unrequested-but-needed agents based on evidence-backed business-type heuristics. This is the "proactive AI consultant" differentiator that separates AgentBloc from every other framework in the PDF research.

**Depends on**: Phase 9 (extends Designer's output with the anticipation pass)
**Requirements**: ANTIC-01, ANTIC-02, ANTIC-03, ANTIC-04, ANTIC-05

**Success Criteria**:
1. Running Designer Agent against the Arco Rooms Business Graph proposes the Analista Rentabilidad + Gestor Incidencias anticipated agents alongside the three requested ones, each tagged `ANTICIPATED` with rationale
2. `references/anticipation-heuristics.md` documents at least three independent sources for each business-type → needed-agent mapping
3. User declining an anticipated agent records it in `.agentbloc/graph/declined.json`; re-running Designer does not re-propose it
4. Anticipation does not trigger for business types outside the documented heuristics — the engine degrades silently rather than hallucinating agents
5. A reviewer reading the anticipated agent presentation can understand the rationale in one scan (not just "you probably need this" — the why is visible)

**Plans:** TBD (estimated 2)

### Phase 16: End-to-End Validation and Release

**Goal**: The canonical Arco Rooms test case drives a full run from `/agentbloc` invocation through deployed + triggered + reporting team. TAP tests added for the new v2.0 categories. README + CHANGELOG updated. `v2.0.0` tag.

**Depends on**: Phases 8-15 complete
**Requirements**: (cross-cutting — no new REQ-IDs; re-verifies all 79 v2.0 requirements in an integration context)

**Success Criteria**:
1. Running the Arco Rooms scenario from `/agentbloc` invocation produces: a valid Business Graph, a valid `agent-profiles.yaml` with 5 agents (3 requested + 2 anticipated), verified integrations for each agent, a successful Deploy Pipeline run, a simulated cron + webhook trigger each waking the correct agent, and a first briefing report delivered to Telegram
2. TAP harness gains at least one scenario per new category (INTV / BGRAPH / DSGN / ORCH / INTEG / BROWSER / DEPLOY / MEM / RUNTIME / AUTON / MONITOR / CTRL / ANTIC)
3. README lists the v2.0 new capabilities in the 30-second pitch and links a "v2.0 Arco Rooms example" walkthrough
4. CHANGELOG entry for v2.0.0 describes the Designer + Deploy pipeline, the Anticipation differentiator, and the stack context (ClaudeClaw + n8n)
5. A `v2.0.0` git tag exists with annotated release notes pointing at `.planning/milestones/v2.0-ROADMAP.md` after archive

**Plans:** TBD (estimated 2)

## Progress

| Phase | Milestone | Plans (est) | Status | Completed |
|-------|-----------|-------------|--------|-----------|
| 1. Skill Foundation | v1.0 | 2/2 | Complete | 2026 |
| 2. Security Cross-Cutting References | v1.0 | 3/3 | Complete | 2026 |
| 3. Interview and Design Phases | v1.0 | 3/3 | Complete | 2026 |
| 4. Integration and Confirmation Phases | v1.0 | 2/2 | Complete | 2026 |
| 5. Deployment Artifacts and Evolution | v1.0 | 3/3 | Complete | 2026 |
| 6. Repo Polish and Examples | v1.0 | 3/3 | Complete | 2026 |
| 7. Testing and CI | v1.0 | 2/2 | Complete | 2026-04-18 |
| 8. Business Graph Foundation | v2.0 | 0/2 | Not started | — |
| 9. Designer Agent | v2.0 | 0/3 | Not started | — |
| 10. Integration Discovery — MCP Path | v2.0 | 0/3 | Not started | — |
| 11. Integration Discovery — Browser Fallback | v2.0 | 0/3 | Not started | — |
| 12. Deploy Pipeline + Agent Memory | v2.0 | 0/3 | Not started | — |
| 13. Multi-Agent Runtime | v2.0 | 0/3 | Not started | — |
| 14. Autonomy + Monitor + Control Plane | v2.0 | 0/4 | Not started | — |
| 15. Anticipation Engine | v2.0 | 0/2 | Not started | — |
| 16. End-to-End Validation and Release | v2.0 | 0/2 | Not started | — |

**v2.0 totals:** 9 phases · ~25 plans estimated · 79 requirements · 13 categories

**Coverage:** 79/79 requirements mapped (verification pending — gsd-roadmapper re-run optional after scope pivot). All 13 categories land in exactly one primary phase; cross-cutting reqs re-verified in Phase 16.

**Dependency chain (load-bearing, do NOT reorder):**
- 8 → 9: Designer needs Business Graph
- 9 → 10: MCP Discovery needs the profiles' tools list
- 10 → 11: Browser fallback triggers only when MCP search fails
- {10, 11} → 12: Deploy needs verified integrations
- 12 → 13: Runtime needs deployed agents
- 13 → 14: Monitor + Control need runtime events
- 9 → 15: Anticipation extends Designer's output (can run parallel to 10-14 once 9 lands)
- 8..15 → 16: Validation integrates everything
