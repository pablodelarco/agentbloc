# Phase 9: Designer Agent - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning
**Decision mode:** Autonomous (per `autonomous_mode` memo — Pablo authorized expert-judgment decisions on implementation gray areas)

<domain>
## Phase Boundary

Build the **Designer Agent** — a Claude Code subagent (`.claude/agents/designer-agent.md`, `context: fork`) that consumes the Phase 8 Business Graph JSON and autonomously produces a structured `agent-profiles.yaml` that specifies the full agent team: per-agent CrewAI-shaped profiles (role / goal / backstory / tools / triggers / autonomy / outputs / escalation / dependencies) plus an orchestration plan that classifies each workflow into one of five universal patterns. The user can edit the proposal conversationally, Designer re-emits. Phase 9 is the **AG2 CaptainAgent pattern adapted to AgentBloc**: a meta-agent that generates teams on demand.

Scope note: Phase 9 does NOT include the anticipation pass (Phase 15 extension). Phase 9 produces the **requested-agents-only** team; Phase 15 adds proactive anticipation on top.

**In scope:**
- `.claude/agents/designer-agent.md` — new Claude Code subagent definition with scoped tools (Read, Grep, Glob, Write on specific paths, no Bash)
- `.claude/skills/agentbloc/references/orchestration-patterns.md` — new reference file documenting the 5 universal patterns + decision heuristics
- `.claude/skills/agentbloc/references/agent-profile-schema.md` — new reference file defining the `agent-profiles.yaml` schema (structural twin of `business-graph-schema.md`, prose-checklist validator per D-13)
- `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` — canonical test fixture for the 3-agent Arco Rooms team (Gestor Cobros, Recepcionista, Gestor Documental; anticipated 2 are Phase 15 work)
- Extension to `SKILL.md` Phase 2 (Design) section — trigger the Designer subagent with the Business Graph as input; present rendered team summary for user confirmation per v1.0 D-05 (table + cards)
- Extension to `references/phase-2-design.md` — wire the Designer handoff and the conversational editing flow

**Out of scope (belongs to later phases):**
- Anticipation pass that proposes unrequested agents → Phase 15 (ANTIC)
- Integration Discovery for each agent's tools → Phase 10/11 (INTEG/BROWSER)
- Deploy Pipeline materializing the YAML into ClaudeClaw jobs → Phase 12 (DEPLOY)
- Agent memory directory bootstrap → Phase 12 (MEM)
- Runtime trigger wiring → Phase 13 (RUNTIME)
- Validator code that programmatically parses YAML — the validator stays prose-checklist per D-13 inheritance

</domain>

<decisions>
## Implementation Decisions

### Inherited from Phase 8 and v1.0 (carry forward — do not re-decide)

- **Inherited D-11 (Phase 8):** Artifact emission lives in a gate, not a separate subagent invocation flow. Designer Agent emits `agent-profiles.yaml` as the gate output of Phase 2 Design — same pattern as Phase 8's Summary gate for the Business Graph.
- **Inherited D-13 (Phase 8):** Validators are prose-checklists inside the reference file, NOT external tooling (no ajv, no yamllint as a hard dep). `agent-profile-schema.md` uses the same structure as `business-graph-schema.md`.
- **Inherited D-14 (Phase 8):** Rendered table review for the human + silent machine-written artifact. User confirms the rendered team summary, Designer writes `agent-profiles.yaml` silently.
- **Inherited D-15 (Phase 8 + PDF):** File locations locked — `agent-profiles.yaml` lives at `.agentbloc/team/agent-profiles.yaml` (per PDF's `.agentbloc/` convention for deployment artifacts). Not in `.claude/skills/` (that's the skill source). Not in `.planning/` (that's planning artifacts).
- **Inherited v1.0 D-05:** Design output format = table overview + expandable cards. Table for scan, cards for per-agent detail. Designer renders this way.
- **Inherited v1.0 D-06:** ASCII inline + Mermaid in deployment artifacts for topology diagrams. Designer renders ASCII during the confirmation turn; Mermaid lands in the YAML (or an adjacent `team-topology.md`) for later Phase 12 deploy artifacts.
- **Inherited v1.0 D-07:** Designer RECOMMENDS topology with rationale; user can override. Same pattern, no changes.
- **Inherited v1.0 D-09:** Designer AUTO-SCORES blast-radius per agent based on its tools; user can override.

### New decisions (autonomous, per PDF + REQUIREMENTS + prior phases)

#### Subagent structure and contract

- **D-21 (Designer subagent at `.claude/agents/designer-agent.md`, `context: fork`, scoped tools):** DSGN-01 explicitly locks the file path and fork context. Tool scope: `Read` (Business Graph + refs), `Grep`/`Glob` (scan existing skills), `Write` (restricted to `.agentbloc/team/*` and conversation-summary rendering). **NO `Bash` access** — Designer does not execute shell commands; it only writes structured artifacts. This isolates the meta-agent from side effects.

  **Rationale:** Fork context isolates the YAML-generation work from the main interview session's context (which has tangential details the main conversation needs). Scoped tools minimize blast radius (Designer cannot accidentally modify other parts of the project). Matches Claude Code v2.1+ subagent convention.

#### Output YAML schema

- **D-22 (YAML schema mirrors Business Graph tiering with ORG-wide mandatory fields):** `agent-profiles.yaml` has three tiers like Business Graph:

  | Tier | Fields | Behavior if missing |
  |---|---|---|
  | REQUIRED | `team.name`, `team.topology` ∈ `{pipeline, mesh, hierarchy, swarm}`, `agents[]` (≥ 1), per-agent `id` + `role` + `goal` + `tools` (≥ 1) + `triggers` (≥ 1) + `autonomy` ∈ `{full, semi, supervised}`, `orchestration.workflows[]` (≥ 1) with `type` + `agents` | Validation fails. Designer refuses to emit; re-prompts user if ambiguous. |
  | RECOMMENDED | `backstory`, `outputs[]` (type + schema), `escalation`, `dependencies[]` | Designer warns but emits. Phase 12 Deploy Pipeline operates with degraded output for missing fields. |
  | OPTIONAL | Per-workflow `steps[]` or `flow` narrative, per-agent `model` hint, `team.briefing_agent_id` | Silent defaults. |

  `schema_version: 1` integer, bumped only on breaking changes — same rule as Business Graph D-12.

  **Rationale:** Phase 12 Deploy Pipeline cannot generate a skill without `role` + `goal` + `tools`; it can synthesize around missing `backstory`. Strict where deploy breaks, forgiving where it can degrade.

#### Topology selection (resolves STATE.md carry-forward)

- **D-23 (Decision table in `orchestration-patterns.md` + LLM judgment for edge cases):** Designer reads a decision table and picks the topology that best fits the Business Graph's process shape. Table:

  | Topology | Signal from Business Graph | Example |
  |---|---|---|
  | **Pipeline** | One linear process with clear handoffs (verify → remind → generate → update) | Cobro mensual workflow (single agent, ordered steps) |
  | **Mesh** | Multiple agents that can peer-call each other (Recepcionista asks Gestor Cobros for payment status) | 3-agent team that share context but have distinct roles |
  | **Hierarchy** | One team lead orchestrates per-domain workers; workers don't talk to each other directly | 5-15 agent org with briefing-agent at the top |
  | **Swarm** | N independent agents performing similar work in parallel (one-per-property watchdog) | Rare for SMB; common for multi-tenant ops |

  When the Business Graph is ambiguous, Designer defaults to **mesh** (most flexible, matches ClaudeClaw `SendMessage`, degrades naturally to pipeline if only one agent ends up being generated).

  **Rationale:** Explicit table gives Designer a deterministic starting point. LLM judgment on edge cases is OK because D-07 inheritance (topology recommendation with rationale, user can override) preserves human-in-the-loop.

#### Orchestration pattern classification (ORCH-01/02)

- **D-24 (5-pattern lookup table in `orchestration-patterns.md`, Designer picks per workflow, cites the table):** The 5 universal patterns from `v2.0-PROMPT.pdf`:

  | Pattern | PDF's description | Designer picks when |
  |---|---|---|
  | **Sequential** (ADK `SequentialAgent`) | Steps run in order; each step's output feeds the next | Workflow has ordered `steps[]` with dependencies (cobro_mensual: verify → remind → generate) |
  | **Parallel** (ADK `ParallelAgent`) | Multiple agents run independently; results merge | Multi-agent workflow where agents don't depend on each other (weekly report assembly from 3 data sources) |
  | **Loop** (ADK `LoopAgent`) | Same step repeats until condition met | Watchdog-style (check until due date passes, poll until response) |
  | **Event-driven** (Bus pattern) | Agent wakes on external event, runs once, sleeps | Most AgentBloc flows (Gmail webhook → Recepcionista reads; BBVA webhook → Gestor Cobros acts) |
  | **Conversational** (Negotiation pattern) | Agents "talk" to each other via SendMessage to reach consensus | Rare; only when business rule explicitly needs deliberation (e.g., "finance + legal agents must both approve a high-value refund") |

  Designer writes the picked `type` into `orchestration.workflows[].type` and cites `orchestration-patterns.md` in a short rationale field (`orchestration.workflows[].why`). PDF's longer "Negotiation / Role-delegation / Handoff" naming is normalized to the ADK/event-driven set for simplicity.

  **Rationale:** 5 patterns is the minimum that covers 95% of SMB workflows (per PDF § "5 Patrones de Orquestación Universales"). ADK naming is the simplest / most familiar; preserves mapping to Google ADK primitives if we ever want TypeScript codegen.

#### Process → role grouping (DSGN-05)

- **D-25 (LLM judgment with 3 guardrail heuristics):** Designer groups processes into agent roles using these guardrails, in order:

  1. **Tool overlap ≥50%** → same agent. (Two processes both needing `bbva` + `gmail` → same financial agent.)
  2. **Same trigger type + same cadence** → same agent. (Two cron-daily monitoring tasks → one watchdog.)
  3. **Natural "job title" fit** → same agent. (All collection subtasks → Gestor de Cobros, regardless of trigger variety.)

  When heuristics disagree, prefer **more agents** (split) over fewer (merge). User can collapse later via DSGN-07 conversational edits. The reverse (splitting a monolithic agent) is harder.

  **Rationale:** The split-first bias prevents "god agent" anti-pattern where one agent owns half the business.

#### Profile editing flow (DSGN-07)

- **D-26 (Conversational surgical patches, never re-generate-from-scratch):** When user says "rename gestor-cobros to María's agent" or "drop the analista for now", Designer:
  1. Parses the intent into a structured patch (rename / delete / add-tool / change-autonomy / etc.)
  2. Applies the patch in-place to `agent-profiles.yaml`
  3. Bumps an internal `modified_at` field in the YAML
  4. Re-renders the TABLE for the user (not the YAML)
  5. User confirms the table (same D-14 pattern as Business Graph)

  Designer does NOT regenerate from the Business Graph for edits. Regenerating would re-insert rejected / anticipated / user-renamed agents, fighting the user.

  **Rationale:** Edits are user intent; preserve them. Regenerating erases user judgment.

#### New reference file: `orchestration-patterns.md`

- **D-27 (New reference at `.claude/skills/agentbloc/references/orchestration-patterns.md`, structural twin of `frameworks.md`):** ORCH-02 explicitly requires this reference. Mirrors the existing v1.0 `frameworks.md` structure (CrewAI / LangGraph / n8n pattern references). Contents:
  - TOC
  - "When This Applies" section
  - 5 patterns with signal → recommendation table (D-24)
  - Topology decision table (D-23)
  - Framework inheritance: cite CrewAI (role/goal/backstory), AG2 (CaptainAgent), Google ADK (Sequential/Parallel/Loop), LangGraph (checkpointing schema shape), Mastra (Zod-style schemas), Paperclip (control plane UX) per PDF § "Qué Robamos de Cada Framework"
  - Quick Reference

  Loaded unconditionally at Phase 2 entry (same as `phase-2-design.md`).

  **Rationale:** Gives Designer a concrete reference to cite. Documents the framework pattern inheritance that the PDF calls out explicitly.

#### New reference file: `agent-profile-schema.md`

- **D-28 (New reference at `.claude/skills/agentbloc/references/agent-profile-schema.md`, structural twin of `business-graph-schema.md`):** Defines the schema Designer emits. Contains:
  - YAML example of a full agent profile (CrewAI-shaped: role, goal, backstory, tools, triggers, autonomy, outputs, escalation, dependencies)
  - Field Obligation Matrix per D-22
  - Autonomy enum `{full, semi, supervised}` with decision criteria
  - Trigger types — same enum as Business Graph process triggers (inherited D-18 from Phase 8) + new `inter-agent` type for peer calls
  - Prose Validation Checklist per D-13 inheritance

  **Rationale:** Symmetric with Business Graph schema. Phase 12 Deploy Pipeline reads this to know how to materialize each agent into a ClaudeClaw skill.

#### SKILL.md Phase 2 extension

- **D-29 (SKILL.md adds the Designer invocation step + gate):** Mirror of Phase 8's SKILL.md extensions (D-11, D-14, precondition). Specifically:
  - Add `agent_profiles_validated` to the gate vocabulary (sibling of `business_graph_validated`)
  - Add Phase 2 Summary gate: after Designer emits YAML, render the table, gate waits on user confirmation
  - Add Phase 3 precondition: verify `.agentbloc/team/agent-profiles.yaml` exists and validates before Phase 3 can begin
  - Add to Phase 2 unconditional-load list: `orchestration-patterns.md` and `agent-profile-schema.md`

  **Rationale:** Exact mirror of Phase 8's pattern — consistent gate ritual, consistent loading pattern. Keeps SKILL.md ≤250 lines (small additive edits).

#### Canonical test fixture

- **D-30 (Fixture at `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml`, derived from PDF page 3 example):** Strictly the 3 **requested** agents from the PDF — Gestor de Cobros, Recepcionista, Gestor Documental. The 2 anticipated agents (Analista Rentabilidad, Gestor Incidencias) are Phase 15 work and appear in a separate `arco-rooms-agent-profiles-anticipated.yaml` fixture when Phase 15 ships.

  **Rationale:** Phase 9 scope excludes anticipation. Keeping fixtures narrow makes Phase 9 verification clean.

### Claude's Discretion

- Exact wording of Designer subagent's backstory/prompt (beyond the required role/goal/scoped tools)
- Exact ASCII diagram style for topology renderings (match v1.0 convention)
- Table rendering format for the confirmation turn — keep consistent with Phase 8 D-14 and v1.0 D-05
- Order of the 5 patterns in the table — optimization for Designer's "first option it sees fits" bias
- How to handle ambiguous Business Graphs (fallback: ask user ONE clarifying question before emitting)
- Whether `team-topology.md` (Mermaid diagram) is emitted alongside `agent-profiles.yaml` or deferred to Phase 12 — lean: emit alongside (cheap, useful for debugging)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope Authority
- `.planning/v2.0-PROMPT.pdf` — v2.0 ground truth; **page 2 has the Business Graph example, page 3 has the agent-profiles.yaml example**, page 1 has the 5 orchestration patterns
- `.planning/REQUIREMENTS.md` § Designer Agent (DSGN-01..07) + § Orchestration Classifier (ORCH-01..04)
- `.planning/PROJECT.md` § Current Milestone + Constraints (ClaudeClaw subagent + TeamCreate/SendMessage primitives assumed)

### v2.0 Artifacts This Phase Consumes (from Phase 8)
- `.claude/skills/agentbloc/references/business-graph-schema.md` — input contract; Designer reads the Business Graph and maps it into agent profiles
- `.claude/skills/agentbloc/examples/arco-rooms-business-graph.json` — canonical input fixture for verification

### v1.0 Artifacts Being Extended
- `.claude/skills/agentbloc/references/phase-2-design.md` — the existing Design phase reference; Phase 9 wires the Designer subagent into it
- `.claude/skills/agentbloc/references/frameworks.md` — structural twin for the new `orchestration-patterns.md`
- `.claude/skills/agentbloc/references/blast-radius.md` — referenced during auto-scoring per inherited v1.0 D-09
- `.claude/skills/agentbloc/SKILL.md` — Phase 2 entry + gate ritual; add `agent_profiles_validated` gate value + Phase 3 precondition

### Prior Phase Context (carry-forward decisions)
- `.planning/phases/08-business-graph-foundation/08-CONTEXT.md` — D-11 through D-20 apply structurally
- `.planning/milestones/v1.0-phases/03-interview-and-design-phases/03-CONTEXT.md` — D-05 through D-10 on design-phase output format, topology recommendation, blast-radius auto-scoring

### New Files To Be Created (plan-phase will materialize)
- `.claude/agents/designer-agent.md` — the Designer Claude Code subagent
- `.claude/skills/agentbloc/references/orchestration-patterns.md` — 5-pattern + topology reference
- `.claude/skills/agentbloc/references/agent-profile-schema.md` — YAML schema + validator
- `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` — 3-agent fixture

### Reference Example (for shape testing)
- `.planning/v2.0-PROMPT.pdf` page 3 — Arco Rooms agent-profiles.yaml example. Use as the canonical shape.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `references/phase-2-design.md` (313 lines) — existing v1.0 Design phase protocol. Contains agent identification, topology selection, per-agent contract definition, governance specs. Phase 9 wires the Designer subagent INTO this flow — not a replacement. Designer is called when Phase 2 is ready to produce the structured YAML output.
- `references/frameworks.md` (126 lines) — v1.0 framework patterns reference. Structural twin for `orchestration-patterns.md`. Table-driven, Quick Reference, cites CrewAI / LangGraph / n8n.
- `references/business-graph-schema.md` (137 lines, new from Phase 8) — Design template for `agent-profile-schema.md`. Identical structure: H1 + blockquote + TOC + "When This Applies" + schema definition + field obligation matrix + bounded enums + validation checklist + Quick Reference.
- `SKILL.md` (163 lines) — has the `business_graph_validated` gate value pattern, Phase 1 unconditional load pattern, Phase 2 precondition pattern. All reusable for Phase 9 (agent_profiles_validated).
- `examples/arco-rooms-business-graph.json` (103 lines, new from Phase 8) — the Business Graph this phase's Designer consumes in the Arco Rooms test fixture.

### Established Patterns
- **Prose-checklist validator (Phase 8 D-13):** Validator lives in the schema reference file itself as an ordered prose checklist. No external tooling. Applied to YAML here.
- **Subagent with `context: fork` (Phase 8 D-11 extension):** Phase 9 introduces the first actual `.claude/agents/*.md` definition. Pattern: YAML frontmatter with `name`, `description`, `tools` list, `context: fork`.
- **Artifact emission in the Summary gate (Phase 8 D-11):** The subagent is invoked from the main session's Phase 2 flow, writes to a deterministic path, and the main session's gate waits for the file to exist and validate. Pattern repeats.
- **Rendered table review + silent artifact (Phase 8 D-14):** User confirms the rendered team summary (table + cards per v1.0 D-05); YAML is written silently.

### Integration Points
- `SKILL.md` Phase 2 entry: extend the unconditional-load list with `orchestration-patterns.md` + `agent-profile-schema.md`
- `SKILL.md` Phase 2 Summary: wire Designer subagent invocation + gate wait on `agent-profiles.yaml` validation
- `SKILL.md` Phase 3 entry: add precondition check (`.agentbloc/team/agent-profiles.yaml` exists + validates)
- `references/phase-2-design.md`: add "Designer Subagent Invocation" section; wire conversational editing flow per D-26
- `references/blast-radius.md`: no change — Designer reads existing scoring rules during auto-scoring
- `.agentbloc/team/`: new directory under the user's deployment artifact root (sibling of `.agentbloc/graph/`)

</code_context>

<specifics>
## Specific Ideas

- **The Designer subagent is AgentBloc's first real "agent that builds agents."** Everything after Phase 9 either consumes the YAML (Phase 12 deploy) or extends it (Phase 15 anticipation). The YAML schema is therefore the single most important contract in v2.0 after the Business Graph schema.
- **Mirror Phase 8 religiously.** Phase 8 shipped the Business Graph schema + validator + fixture + SKILL.md gate + interview wiring. Phase 9 is structurally identical: output YAML schema + validator + fixture + SKILL.md gate + design-phase wiring. A planner who recognizes the symmetry can write Phase 9 plans largely by analogy.
- **The 5-pattern orchestration table is the heart of ORCH.** Everything Designer decides about how workflows execute flows from this one table. Get it right once, Phase 9 is done; get it wrong, downstream phases fight the shape forever.
- **Fork-context isolation matters for Designer.** The main interview session has tangential user conversation (jokes, clarifications, tangents). Designer shouldn't see that noise — it should see only the Business Graph + schema + patterns. `context: fork` ensures the YAML-generation work is clean.
- **User edits beat regeneration (D-26).** If user renames an agent or drops one, Designer must never "helpfully" re-add it from the Business Graph on the next turn. User intent wins. This is the single biggest UX difference from naive AG2 CaptainAgent implementations.
- **Anticipation belongs to Phase 15, not Phase 9.** Phase 9 ships a Designer that generates EXACTLY what the Business Graph implies. Phase 15 ships the anticipation pass that proposes additional agents. Keeping them separate means Phase 9 verification is deterministic (same input → same output) and Phase 15 can evolve the anticipation heuristics without re-verifying Designer's core generation.

</specifics>

<deferred>
## Deferred Ideas

- **Topology auto-upgrade:** if a team grows past N agents during conversational edits (DSGN-07), Designer could auto-recommend upgrading mesh → hierarchy. Nice but premature; log for v2.5.
- **Per-agent model recommendation:** Designer could suggest Opus vs Sonnet vs Haiku per agent based on task complexity. Currently optional in D-22; upgrade to RECOMMENDED in a v2.5 follow-up once we have real usage data.
- **Multi-language team YAMLs:** bilingual role / goal / backstory (EN + ES). Currently English-only; Claude adapts at runtime. Belongs to a future milestone.
- **Designer as a CLI standalone:** `agentbloc design` invocation outside the conversational flow. Out of scope — AgentBloc is conversational (PROJECT.md constraint).
- **Visual YAML editor:** web UI for team editing. Explicitly out of scope (PROJECT.md).
- **Contract testing of YAML against real deployment:** Phase 16 validation run handles this; Phase 9 only verifies schema conformance, not runtime behavior.

</deferred>

---

*Phase: 09-designer-agent*
*Context gathered: 2026-04-21*
*Decision mode: autonomous (Pablo-authorized). All decisions open to veto — raise before Phase 10 discuss begins.*
