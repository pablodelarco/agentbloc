# Phase 9: Designer Agent - Pattern Map

**Mapped:** 2026-04-21
**Files analyzed:** 6 (4 new, 2 modified)
**Analogs found:** 6 / 6

## File Classification

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `.claude/agents/designer-agent.md` (NEW) | Claude Code subagent definition (YAML-frontmatter meta-agent) | request-response (main session spawns, subagent emits artifact) | `~/.claude/agents/gsd-pattern-mapper.md` (Claude Code subagent convention) | role-match (same frontmatter shape; different domain) |
| `.claude/skills/agentbloc/references/orchestration-patterns.md` (NEW) | reference file (pattern documentation loaded at Phase 2 entry) | request-response (Claude reads table, picks `type`) | `references/frameworks.md` (126 lines, table-driven pattern guide loaded at Phase 2) | exact (CONTEXT.md D-27 explicit structural twin) |
| `.claude/skills/agentbloc/references/agent-profile-schema.md` (NEW) | schema reference + prose validator | request-response (Designer reads checklist, runs checks before emitting YAML) | `references/business-graph-schema.md` (137 lines, schema + prose checklist) | exact (CONTEXT.md D-28 explicit structural twin; Phase 8 just shipped this shape) |
| `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` (NEW) | canonical test fixture (3 requested agents per D-30) | file-I/O (read by verification) | `examples/arco-rooms-business-graph.json` (103 lines, Phase 8 fixture) | exact (same fixture family, same Arco Rooms scenario) |
| `.claude/skills/agentbloc/references/phase-2-design.md` (MODIFY) | design protocol — wire Designer subagent invocation + conversational editing | CRUD on in-conversation state + subagent spawn | Phase 8 extension precedent: `references/phase-1-interview.md` modified by `08-02-PLAN.md` Task 1 (Summary Template + Emission subsection insert) | exact (same surgical-insert pattern; different file, same technique) |
| `.claude/skills/agentbloc/SKILL.md` (MODIFY) | skill hub — gate vocabulary + Phase 2 Summary wiring + Phase 3 precondition | config | `08-02-PLAN.md` Task 2 (three-edit SKILL.md surgical pattern from Phase 8) | exact (same file, same three-edit technique one phase later) |

---

## Pattern Assignments

### `.claude/agents/designer-agent.md` (NEW file — first project-local subagent)

**Analog:** `/Users/pablodelarco/.claude/agents/gsd-pattern-mapper.md` (Claude Code subagent frontmatter convention). Secondary: `/Users/pablodelarco/.claude/agents/gsd-codebase-mapper.md` and `/Users/pablodelarco/.claude/agents/gsd-framework-selector.md`.

**Why this analog:** Designer Agent is AgentBloc's first `.claude/agents/*.md` file. No in-repo precedent exists. Claude Code's subagent convention is documented by the global `~/.claude/agents/` directory — every subagent file there is a YAML-frontmatter + markdown-body definition. `gsd-pattern-mapper.md` is the cleanest, shortest (lines 1-12 show the entire frontmatter) analog for the structural spine.

**Target length:** 80-150 lines (scoped prompts keep subagents lean; CONTEXT.md D-21 emphasizes `context: fork` isolation means the body holds the whole worldview).

---

#### Pattern A: YAML frontmatter structure

Copy the shape from `gsd-pattern-mapper.md` lines 1-12:

```yaml
---
name: gsd-pattern-mapper
description: Analyzes codebase for existing patterns and produces PATTERNS.md mapping new files to closest analogs. Read-only codebase analysis spawned by /gsd-plan-phase orchestrator before planning.
tools: Read, Bash, Glob, Grep, Write
color: magenta
# hooks:
#   PostToolUse:
#     - matcher: "Write|Edit"
#       hooks:
#         - type: command
#           command: "npx eslint --fix $FILE 2>/dev/null || true"
---
```

**Adapt for Designer Agent** (per D-21: scoped tools, NO Bash, fork context):

```yaml
---
name: designer-agent
description: Consumes the Business Graph JSON at .agentbloc/graph/business-graph.json and emits a structured agent-profiles.yaml specifying the full agent team (CrewAI-shaped profiles + orchestration plan). Spawned from AgentBloc Phase 2 Design Summary gate. Never consumed in anticipation mode (Phase 15 extends).
tools: Read, Grep, Glob, Write
color: purple
context: fork
---
```

**Key deviations from the analog** (per D-21):
- Drop `Bash` from `tools` — Designer writes YAML only, no shell side effects.
- Add `context: fork` — main-session conversation noise should not reach Designer (new v2.1+ subagent feature).
- `Write` restricted by convention (prose-only; enforced in body section): `.agentbloc/team/agent-profiles.yaml` and `.agentbloc/team/team-topology.md` only.

---

#### Pattern B: Body structure (role + required_reading + task flow)

Copy the shape from `gsd-pattern-mapper.md` lines 14-30:

```markdown
<role>
You are a GSD pattern mapper. You answer "What existing code should new files copy patterns from?" and produce a single PATTERNS.md that the planner consumes.

Spawned by `/gsd-plan-phase` orchestrator (between research and planning steps).

**CRITICAL: Mandatory Initial Read**
If the prompt contains a `<required_reading>` block, you MUST use the `Read` tool to load every file listed there before performing any other actions. This is your primary context.

**Core responsibilities:**
- ...
</role>
```

**Adapt for Designer Agent**:

```markdown
<role>
You are AgentBloc's Designer Agent. You answer "Given this Business Graph, what agent team + orchestration plan best fits?" and produce a single agent-profiles.yaml that Phase 12 Deploy Pipeline consumes.

Spawned by AgentBloc's Phase 2 Design Summary gate (see SKILL.md and references/phase-2-design.md).

**CRITICAL: Mandatory Initial Read**
Before producing any output, you MUST Read:
1. `.agentbloc/graph/business-graph.json` (input)
2. `.claude/skills/agentbloc/references/agent-profile-schema.md` (output contract + validator)
3. `.claude/skills/agentbloc/references/orchestration-patterns.md` (pattern catalog + topology decision table)
4. `.claude/skills/agentbloc/references/blast-radius.md` (for auto-scoring per v1.0 D-09)
5. `.claude/skills/agentbloc/references/frameworks.md` (CrewAI role/goal/backstory shape)

**Core responsibilities:**
- Map each Business Graph process into agent role(s) per D-25 guardrails (tool overlap >= 50%, same trigger type + cadence, natural job-title fit)
- Pick team topology from {pipeline, mesh, hierarchy, swarm} using orchestration-patterns.md topology table
- Pick per-workflow orchestration pattern from {Sequential, Parallel, Loop, Event-driven, Conversational}
- Auto-score blast radius per agent using blast-radius.md
- Emit agent-profiles.yaml silently at `.agentbloc/team/agent-profiles.yaml`; NEVER show YAML to user
- Render the team as a table + per-agent cards for the main session to present (per v1.0 D-05)
</role>
```

---

#### Pattern C: Scoped-write-constraint language

**Analog:** `gsd-pattern-mapper.md` lines 29-30 — explicit read-only constraint:

```markdown
**Read-only constraint:** You MUST NOT modify any source code files. The only file you write is PATTERNS.md in the phase directory. All codebase interaction is read-only (Read, Bash, Glob, Grep). Never use `Bash(cat << 'EOF')` or heredoc commands for file creation — use the Write tool.
```

**Adapt for Designer**:

```markdown
**Write constraint:** You MUST only write to `.agentbloc/team/agent-profiles.yaml` and optionally `.agentbloc/team/team-topology.md` (Mermaid diagram per v1.0 D-06). You MUST NOT modify source files in `.claude/skills/` or `.planning/`. No heredoc writes — use the Write tool. No Bash.
```

---

#### Pattern D: Conversational editing flow (per D-26)

**No direct subagent analog.** The conversational-patch pattern is new. Compose from:
1. Business Graph Re-run Behavior in `business-graph-schema.md` lines 116-122 (keep / overwrite / merge prompt)
2. phase-2-design.md Design Gate at lines 296-301 (accepts modification requests, loops back)

Skeleton the planner should write:

```markdown
<conversational_edits>
When the main session reports a user edit (e.g., "rename gestor-cobros to Maria's agent", "drop the analista for now"):

1. Parse the intent into a structured patch: {rename, delete, add-tool, change-autonomy, change-topology, ...}
2. Read existing `.agentbloc/team/agent-profiles.yaml` — NEVER regenerate from the Business Graph (D-26).
3. Apply the patch in-place. Bump `team.modified_at`.
4. Re-run the Validation Checklist from agent-profile-schema.md.
5. Re-render ONLY the TABLE (not the full YAML) for the user's next confirmation turn.
6. Write the patched YAML silently.

Regenerating from the Business Graph would re-insert rejected or renamed agents, fighting the user's intent. Patches win.
</conversational_edits>
```

---

### `.claude/skills/agentbloc/references/orchestration-patterns.md` (NEW)

**Analog:** `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/frameworks.md` (126 lines)

**Why this analog:** CONTEXT.md D-27 explicitly names this as a structural twin. Both files are loaded unconditionally at Phase 2 entry, both document a bounded pattern catalog with "when to use" decision guidance, both cite external frameworks without importing their runtimes, both end with a Quick Reference.

**Target length:** 130-170 lines (longer than frameworks.md because we cover 5 patterns + topology table + framework inheritance per D-27).

---

#### Pattern A: File header + TOC (spine) — copy verbatim from `frameworks.md` lines 1-13

```markdown
# Agent Framework Patterns

> Loaded by the design protocol during Phase 2. Maps patterns from CrewAI, LangGraph, and n8n to AgentBloc design decisions. These frameworks are referenced for their design patterns, not their runtimes. AgentBloc runs on Claude Code natively.

## Table of Contents

- [When This Applies](#when-this-applies)
- [CrewAI Patterns for AgentBloc](#crewai-patterns-for-agentbloc)
- [LangGraph Patterns for AgentBloc](#langgraph-patterns-for-agentbloc)
- [n8n Patterns for AgentBloc](#n8n-patterns-for-agentbloc)
- [Pattern Application by Tech Level](#pattern-application-by-tech-level)
- [Quick Reference](#quick-reference)
```

**Adapt for orchestration-patterns.md:**

```markdown
# Orchestration Patterns

> Loaded by SKILL.md at Phase 2 entry alongside phase-2-design.md and agent-profile-schema.md. Defines the 5 universal orchestration patterns Designer Agent classifies each workflow into, plus the topology decision table Designer uses to pick team shape. Framework inheritance is referenced — not imported.

## Table of Contents

- [When This Applies](#when-this-applies)
- [The 5 Orchestration Patterns](#the-5-orchestration-patterns)
- [Topology Decision Table](#topology-decision-table)
- [Framework Pattern Inheritance](#framework-pattern-inheritance)
- [Pattern Selection Heuristics](#pattern-selection-heuristics)
- [Quick Reference](#quick-reference)
```

---

#### Pattern B: "When This Applies" opening paragraph

**Analog:** `frameworks.md` lines 14-21:

```markdown
## When This Applies

Claude loads this file during the Design Phase. Specific sections are referenced based on the current design step:

- **Agent Identification (Step 1):** reference CrewAI for role-based decomposition. Break the workflow into distinct job roles, each with a clear responsibility boundary.
- **Topology Selection (Step 2):** reference LangGraph for the topology decision tree. Match the workflow's coordination pattern to Pipeline, Hierarchy, Mesh, or Swarm.
- **User Explanation:** reference n8n for the visual DAG mental model. Non-technical users understand "steps with arrows" better than "agents with topologies."
```

**Adapt for orchestration-patterns.md:**

```markdown
## When This Applies

Claude loads this file at Phase 2 entry and Designer Agent re-loads it inside its forked context. Specific sections are referenced based on the design step:

- **Topology Selection (DESG-02 + DSGN-04):** Use the Topology Decision Table to pick `team.topology` from {pipeline, mesh, hierarchy, swarm}. Default to **mesh** on ambiguity (D-23).
- **Orchestration Pattern Classification (ORCH-01):** For each `orchestration.workflows[]`, pick one of the 5 patterns and write it into `workflows[].type`.
- **Framework Inheritance:** When explaining rationale to the user, cite the pattern's origin (CrewAI / AG2 / ADK / LangGraph / Mastra / Paperclip) per PDF § "Qué Robamos de Cada Framework".
```

---

#### Pattern C: Bounded-pattern table (D-24 — 5 patterns)

**Analog:** `frameworks.md` lines 28-36 (CrewAI Concept Mapping table — 3-col, clean `|` layout):

```markdown
| CrewAI Concept | AgentBloc Equivalent | Notes |
|---------------|---------------------|-------|
| `role` | Role field in contract card | Function or expertise description. Be specific. |
| `goal` | Responsibility field | Scoped outcome this agent owns |
| `backstory` | Not used | AgentBloc agents are cron-triggered, not conversational personas |
```

**Adapt for 5-pattern table (per D-24):**

```markdown
## The 5 Orchestration Patterns

Designer Agent classifies each `orchestration.workflows[]` into exactly one of these patterns. Write the picked value into `workflows[].type`.

| Pattern | ADK Name | Signal From Business Graph | Designer Picks When | Arco Rooms Example |
|---------|----------|---------------------------|--------------------|--------------------|
| **Sequential** | `SequentialAgent` | Ordered steps with dependencies; each step feeds the next | Single-agent workflow has `steps[]` where step N depends on step N-1 | Cobro Mensual: verify -> remind -> generate -> update |
| **Parallel** | `ParallelAgent` | Multiple agents run independently; results merge | Multi-agent workflow with no inter-dependencies | Weekly Report assembly from 3 data sources |
| **Loop** | `LoopAgent` | Same step repeats until condition met | Watchdog-style (poll-until-due-date, retry-until-response) | Check-in reminder loop until guest confirms |
| **Event-driven** | Bus pattern | Agent wakes on external event, runs once, sleeps | Most AgentBloc flows — Gmail webhook, BBVA webhook, Telegram inbound | Recepcionista wakes on new Gmail message |
| **Conversational** | Negotiation | Agents deliberate via SendMessage until consensus | Rare; only when a business rule requires multi-party deliberation | Finance + legal agents must both approve a >=EUR 1000 refund |
```

---

#### Pattern D: Topology Decision Table (D-23)

**Analog:** `frameworks.md` lines 62-67 (LangGraph Topology Mapping table — 4 col) + lines 82-86 (Practical Sizing table):

```markdown
| LangGraph Pattern | AgentBloc Topology | When to Use | Agent Count |
|-------------------|-------------------|-------------|-------------|
| Sequential Pipeline | Pipeline | Fixed sequential stages, each feeding the next | 1-3 |
| Supervisor | Hierarchy | Centralized coordinator delegates to specialist agents | 3-5+ |
| Swarm | Swarm | Unknown optimal paths, parallel collection from many sources | 5+ |
| Mesh (peer-to-peer) | Mesh | Iterative refinement on shared artifacts, mutual feedback | 3-8 |
```

**Adapt for Topology Decision Table (per D-23):**

```markdown
## Topology Decision Table

Designer Agent picks `team.topology` from the signal set below. On ambiguity, default to **mesh** (D-23).

| Topology | Signal From Business Graph | Example | Agent Count |
|----------|---------------------------|---------|-------------|
| **Pipeline** | One linear process with ordered handoffs (verify -> remind -> generate) | Single-process cobro flow | 1-3 |
| **Mesh** | Multiple agents that peer-call each other (Recepcionista asks Gestor Cobros for payment status) | Arco Rooms 3-agent team (default) | 3-8 |
| **Hierarchy** | One team lead orchestrates per-domain workers; workers don't talk peer-to-peer | 5-15 agent org with briefing-agent at the top | 5-15 |
| **Swarm** | N independent agents performing similar work in parallel (one-per-property watchdog) | Multi-tenant ops | 5+ |

**Default on ambiguity:** **mesh** — matches ClaudeClaw `SendMessage`, degrades naturally to pipeline when only one agent is generated.
```

---

#### Pattern E: Framework inheritance section (D-27 — PDF § "Qué Robamos")

**Analog:** `frameworks.md` lines 22-125 (three subsections: CrewAI Patterns, LangGraph Patterns, n8n Patterns — each with Concept Mapping / Best Practices / Arco Rooms Example subsections).

**Adapt** (per D-27 — six frameworks, lighter per-framework detail to keep file under 170 lines):

```markdown
## Framework Pattern Inheritance

AgentBloc borrows design patterns, not runtimes. Each pattern below has a PDF citation and a one-line AgentBloc application.

| Framework | Pattern Borrowed | AgentBloc Application |
|-----------|-----------------|----------------------|
| **CrewAI** | `role` / `goal` / `backstory` triad per agent | agent-profile-schema.md fields; role is the canonical identity |
| **AG2** | CaptainAgent meta-agent that generates teams on demand | Designer Agent itself (this file's consumer) |
| **Google ADK** | SequentialAgent / ParallelAgent / LoopAgent primitives | The 5-pattern table's ADK Name column |
| **LangGraph** | Checkpointing schema shape (durable state between steps) | `.agentbloc/state/*.json` per-agent, Git-commitable |
| **Mastra** | Zod-style per-agent input/output schema validation | `outputs[].type + schema` in agent profiles |
| **Paperclip** | Control plane UX (approval queue, cost tracking, task locking, status badges) | Phase 14 Briefing Agent consumes logs this way |
```

---

#### Pattern F: Quick Reference footer — copy shape from `frameworks.md` lines 121-126

```markdown
## Quick Reference

- **CrewAI:** Role-based agent decomposition. Every agent gets a specific job title, bounded responsibility, and defined outputs. Default method for agent identification.
- **LangGraph:** Topology selection via decision tree. Pipeline for simple flows, Hierarchy for 3-5+ agents, Mesh for iterative refinement, Swarm for unknown paths.
- **n8n:** Visual DAG mental model for non-technical explanation. "Steps with arrows." Also informs the deterministic vs. AI step mix through model routing.
- **Key rule:** These are borrowed patterns, not imported runtimes. AgentBloc runs on Claude Code. No Python, no TypeScript frameworks, no `pip install`, no `npm install`.
```

**Adapt — bullet per picked pattern + topology:**

```markdown
## Quick Reference

- **Sequential:** ordered `steps[]` with dependencies. Cobro-style single-agent flows.
- **Parallel:** independent multi-agent fan-out. Report-assembly flows.
- **Loop:** poll-until-condition. Reminder watchdogs.
- **Event-driven:** external-trigger wake. Most AgentBloc flows.
- **Conversational:** multi-party deliberation. Rare; only when business rules require consensus.
- **Default topology on ambiguity:** mesh. Default pattern on ambiguity: event-driven.
- **Rule:** Designer cites this file in `workflows[].why` and in `team.topology_rationale` so user sees the reasoning.
```

---

### `.claude/skills/agentbloc/references/agent-profile-schema.md` (NEW)

**Analog:** `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/business-graph-schema.md` (137 lines, just shipped in Phase 8-01)

**Why this analog:** CONTEXT.md D-28 explicitly names this as a structural twin. Identical structure: H1 + blockquote + TOC + When This Applies + Schema Definition + Field Obligation Matrix + Bounded Enum(s) + Validation Checklist + Emission Protocol + Re-run Behavior + Schema Versioning Rules.

**Target length:** 150-210 lines (slightly longer than business-graph-schema.md because more fields: role, goal, backstory, tools, triggers, autonomy, outputs, escalation, dependencies).

---

#### Pattern A: Copy structural spine wholesale from `business-graph-schema.md` lines 1-14

```markdown
# Business Graph Schema

> Schema reference loaded unconditionally at Phase 1 entry alongside [phase-1-interview.md](phase-1-interview.md) and [data-classification.md](data-classification.md). Defines the canonical Business Graph JSON emitted by the Summary gate and the validation checklist Claude applies before writing the file.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Schema Definition](#schema-definition)
- [Field Obligation Matrix](#field-obligation-matrix)
- [Trigger Bounded Enum](#trigger-bounded-enum)
- [Validation Checklist](#validation-checklist)
- [Emission Protocol](#emission-protocol)
- [Re-run Behavior](#re-run-behavior)
- [Schema Versioning Rules](#schema-versioning-rules)
```

**Adapt for agent-profile-schema.md:**

```markdown
# Agent Profile Schema

> Schema reference loaded unconditionally at Phase 2 entry alongside [phase-2-design.md](phase-2-design.md) and [orchestration-patterns.md](orchestration-patterns.md). Defines the canonical agent-profiles.yaml emitted by the Designer Agent subagent and the validation checklist Designer walks before writing the file.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Schema Definition](#schema-definition)
- [Field Obligation Matrix](#field-obligation-matrix)
- [Autonomy Bounded Enum](#autonomy-bounded-enum)
- [Trigger Bounded Enum](#trigger-bounded-enum)
- [Topology Bounded Enum](#topology-bounded-enum)
- [Validation Checklist](#validation-checklist)
- [Emission Protocol](#emission-protocol)
- [Re-run Behavior](#re-run-behavior)
- [Schema Versioning Rules](#schema-versioning-rules)
```

---

#### Pattern B: "When This Applies" paragraph — copy shape from `business-graph-schema.md` lines 16-18

```markdown
## When This Applies

Claude reads this file during the Interview Phase Summary gate to produce the canonical Business Graph JSON at `.agentbloc/graph/business-graph.json`. The schema defines what MUST, SHOULD, and MAY appear in the JSON. The validation checklist below is a deterministic list of pass/fail checks Claude walks through before writing the file; failures surface as targeted follow-up questions in the conversation. Downstream consumers (Phase 9 Designer Agent, Phase 12 Deploy Pipeline, Phase 14 Briefing Agent) all read this artifact.
```

**Adapt for agent-profile-schema.md:**

```markdown
## When This Applies

Designer Agent reads this file inside its forked context to produce the canonical agent-profiles.yaml at `.agentbloc/team/agent-profiles.yaml`. The schema defines what MUST, SHOULD, and MAY appear in the YAML. The validation checklist below is a deterministic list of pass/fail checks Designer walks before writing the file; failures surface as targeted follow-up questions through the main session's conversation. Downstream consumers (Phase 12 Deploy Pipeline — agent skills generation; Phase 13 Runtime — trigger wiring; Phase 14 Briefing Agent — team awareness; Phase 15 Anticipation — additive updates) all read this artifact.
```

---

#### Pattern C: Schema Definition block — copy JSONC-style from `business-graph-schema.md` lines 20-55, ADAPT TO YAML

**Source** (lines 22-55 — commented JSONC):

```jsonc
{
  "schema_version": 1,                        // REQUIRED. Integer. Bumped only on breaking changes.
  "business": {
    "type": "string",                         // REQUIRED. e.g. "rental-property-management"
    "size": "string | null",                  // RECOMMENDED. e.g. "7 properties, 1 operator"
    ...
```

**Adapt to commented YAML for agent-profiles.yaml** (mirrors PDF page 3 shape + D-22 tiering):

````markdown
## Schema Definition

```yaml
schema_version: 1                              # REQUIRED. Integer. Bumped only on breaking changes.
team:
  name: "string"                               # REQUIRED. e.g. "arco-rooms-team"
  topology: "pipeline | mesh | hierarchy | swarm"  # REQUIRED. See Topology Bounded Enum.
  topology_rationale: "string"                 # RECOMMENDED. One-line why this topology fits.
  modified_at: "ISO-8601 timestamp"            # OPTIONAL. Bumped on every conversational edit.
  briefing_agent_id: "string | null"           # OPTIONAL. Phase 14 briefing agent reference.

agents:                                        # REQUIRED. Length >= 1.
  - id: "string"                               # REQUIRED. kebab-case, unique within this file. e.g. "gestor-cobros"
    role: "string"                             # REQUIRED. CrewAI-shaped. e.g. "Invoice Collection Specialist"
    goal: "string"                             # REQUIRED. Scoped outcome. e.g. "Collect overdue rent invoices monthly"
    backstory: "string | null"                 # RECOMMENDED. CrewAI-shaped narrative identity.
    tools:                                     # REQUIRED. Length >= 1.
      - "string"                               # MCP reference or tool name, e.g. "bank-mcp", "telegram-bot"
    triggers:                                  # REQUIRED. Length >= 1.
      - type: "cron | event | manual | inter-agent"  # See Trigger Bounded Enum.
        # cron:         schedule: "<cron string>"
        # event:        source + name
        # manual:       description
        # inter-agent:  caller: "<agent-id>"  message: "<contract>"
    autonomy: "full | semi | supervised"       # REQUIRED. See Autonomy Bounded Enum.
    outputs:                                   # RECOMMENDED.
      - type: "string"                         # e.g. "telegram-message", "state-file", "email"
        schema: "string | null"                # Zod-style schema reference if applicable (Mastra pattern)
    escalation: "string | null"                # RECOMMENDED. e.g. "telegram:pablo"
    dependencies:                              # RECOMMENDED.
      - "<other-agent-id>"                     # Must resolve to an agent in agents[] (ORCH-04).
    blast_radius: 1 | 2 | 3 | 4                # REQUIRED. Auto-scored per blast-radius.md.
    model: "opus | sonnet | haiku | null"      # OPTIONAL. Per-agent model hint.

orchestration:
  workflows:                                   # REQUIRED. Length >= 1.
    - id: "string"                             # REQUIRED. e.g. "cobro-mensual"
      type: "sequential | parallel | loop | event-driven | conversational"  # REQUIRED. See orchestration-patterns.md.
      agents: ["<agent-id>", ...]              # REQUIRED. Length >= 1. All IDs must resolve (ORCH-04).
      trigger:                                 # REQUIRED. Same shape as agents[].triggers[].
        type: "cron | event | manual"
      why: "string"                            # RECOMMENDED. One-line citation of orchestration-patterns.md.
      steps: ["string", ...]                   # OPTIONAL. Used by sequential/loop types.
      flow: "string | null"                    # OPTIONAL. Used by event-driven type. Free-text narrative.
```
````

---

#### Pattern D: Field Obligation Matrix — copy exact 3-col table from `business-graph-schema.md` lines 57-65

```markdown
| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED | `schema_version`, `business.type`, `processes[]` (length >= 1), per-process `name` + `steps[]` + `pain` | Validation fails. Gate blocks Phase 2 transition. Claude asks the user the missing question. |
| RECOMMENDED | `business.size`, `business.owner`, per-process `trigger`, `tools`, `frequency`, `current_actor` | Validation warns but does not fail. Default to `null` or `"unknown"`. Phase 2 Designer Agent proceeds with degraded output and flags the gap. |
| OPTIONAL | `tools_available[]`, `channels[]`, `decision_patterns[]`, `security_profile`, `business_context` | Silent defaults. Empty arrays, `null` values. Designer Agent proceeds without comment. |
```

**Adapt for agent-profiles.yaml (per D-22):**

```markdown
## Field Obligation Matrix

| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED | `schema_version`, `team.name`, `team.topology`, `agents[]` (>=1), per-agent `id` + `role` + `goal` + `tools[]` (>=1) + `triggers[]` (>=1) + `autonomy` + `blast_radius`, `orchestration.workflows[]` (>=1) with `type` + `agents[]` (>=1) + `trigger` | Designer refuses to emit. Main session re-prompts user through targeted follow-up. |
| RECOMMENDED | `backstory`, `outputs[]`, `escalation`, `dependencies[]`, `team.topology_rationale`, `workflows[].why` | Designer emits with warnings. Phase 12 Deploy Pipeline operates with degraded output and flags gaps in DEPLOY-REPORT.md. |
| OPTIONAL | `team.modified_at`, `team.briefing_agent_id`, `model`, `workflows[].steps`, `workflows[].flow` | Silent defaults. Phase 12 proceeds without comment. |

Downstream consumers refuse to proceed on an unknown major `schema_version` — same rule as business-graph-schema.md.
```

---

#### Pattern E: Bounded-enum tables — copy 4-col shape from `business-graph-schema.md` lines 67-77 (Trigger Bounded Enum)

```markdown
| Enum Value | Definition | Required Sub-fields | Example |
|------------|-----------|---------------------|---------|
| `cron` | Time-based recurring trigger | `schedule` (cron string) | `{"type":"cron","schedule":"0 9 * * 1"}` |
| `event` | External-event-driven trigger | `source` (service name) + `name` (event id) | `{"type":"event","source":"gmail","name":"new_message"}` |
| `manual` | Human-initiated trigger | `description` (free text) | `{"type":"manual","description":"Operator runs weekly"}` |
```

**Adapt — THREE bounded enums needed (per D-28):**

```markdown
## Autonomy Bounded Enum

| Enum Value | Definition | Side-Effect Behavior | When to Pick |
|-----------|-----------|----------------------|--------------|
| `full` | Agent acts without prompting | No approval gate; audit log only | Agent only touches internal state files (L1-L2) |
| `semi` | Agent confirms before external side effects | Telegram approval required before send/write-external | Agent has L3 writes or occasional external sends |
| `supervised` | Agent proposes every action, waits for approval | Every side effect waits for explicit human ack | L4 agents + high-stakes (financial, legal) |

## Trigger Bounded Enum

Inherits from business-graph-schema.md trigger enum, PLUS one new type for peer calls:

| Enum Value | Definition | Required Sub-fields | Example |
|------------|-----------|---------------------|---------|
| `cron` | Time-based recurring trigger | `schedule` (cron string) | `{type: cron, schedule: "0 9 * * 1"}` |
| `event` | External-event-driven trigger | `source` + `name` | `{type: event, source: gmail, name: new_message}` |
| `manual` | Human-initiated trigger | `description` | `{type: manual, description: "Operator runs on-demand"}` |
| `inter-agent` | Peer-call from another agent via SendMessage | `caller` (agent-id) + `message` (contract) | `{type: inter-agent, caller: recepcionista, message: "payment-status-query"}` |

## Topology Bounded Enum

| Enum Value | Signal from Business Graph | Default Use | Cross-Reference |
|-----------|---------------------------|-------------|-----------------|
| `pipeline` | Linear ordered process with handoffs | 1-3 agents, sequential flow | orchestration-patterns.md |
| `mesh` | Peer-calling agents (default on ambiguity) | 3-8 agents, mutual SendMessage | orchestration-patterns.md |
| `hierarchy` | One lead orchestrates workers | 5-15 agents, briefing-agent root | orchestration-patterns.md |
| `swarm` | N independent parallel agents | Rare; multi-tenant watchdogs | orchestration-patterns.md |
```

---

#### Pattern F: Validation Checklist — copy numbered-check prose from `business-graph-schema.md` lines 79-99

```markdown
## Validation Checklist

Claude walks this ordered list before writing `.agentbloc/graph/business-graph.json`. Any FAIL triggers a conversational follow-up before emission; the REQUIRED tier checks (1-5) block emission; the RECOMMENDED tier check (6) emits with warnings.

**Check 1: `schema_version` present and equals current version (`1`)**
- FAIL: Emit `"schema_version": 1` automatically; no user follow-up needed.

**Check 2: `business.type` present and non-empty string**
- FAIL: Ask "What kind of business is this, a rental agency, ecommerce store, clinic, or something else?" before emission.
...
```

**Adapt for agent-profile-schema.md** (6-8 checks, planner completes from D-22 + ORCH-04):

```markdown
## Validation Checklist

Designer walks this ordered list before writing `.agentbloc/team/agent-profiles.yaml`. Any FAIL blocks emission; Designer re-prompts the main session with the targeted follow-up text.

**Check 1: `schema_version` present and equals current version (`1`)**
- FAIL: Set `schema_version: 1` automatically; no follow-up needed.

**Check 2: `team.name` non-empty string + `team.topology` in {pipeline, mesh, hierarchy, swarm}**
- FAIL: Pick topology via orchestration-patterns.md Topology Decision Table; default to `mesh` on ambiguity.

**Check 3: `agents[]` length >= 1**
- FAIL: Impossible from a valid Business Graph (processes[] >= 1). If triggered, re-read the Business Graph.

**Check 4: Every agent has `id` (unique), `role`, `goal`, `tools[]` (>=1), `triggers[]` (>=1), `autonomy` in {full, semi, supervised}, `blast_radius` in {1,2,3,4}**
- FAIL: For each gap, surface the specific agent and field to the main session with a targeted question.

**Check 5: `orchestration.workflows[]` length >= 1, every workflow has `type` in the 5-pattern enum, `agents[]` (>=1), and a `trigger`**
- FAIL: Classify via orchestration-patterns.md 5-pattern table; default to `event-driven` on ambiguity.

**Check 6: Every `workflows[].agents[]` id resolves to an entry in `agents[]` (ORCH-04)**
- FAIL: Reject the YAML; log the unresolved id; re-read Business Graph for correct mapping.

**Check 7: Every `agents[].dependencies[]` id resolves to an entry in `agents[]` (ORCH-04)**
- FAIL: Same as Check 6.

**Check 8 (WARN, not FAIL): RECOMMENDED fields populated or explicitly marked `null`**
- WARN: Emit with nulls; flag gaps in the rendered table for user to accept or fix.
```

---

#### Pattern G: Emission + Re-run + Versioning sections — copy shape from `business-graph-schema.md` lines 101-138

The last three sections of `business-graph-schema.md` are:
- `## Emission Protocol` (6 numbered steps, lines 103-110)
- `## Re-run Behavior` (keep/overwrite/merge prompt, lines 114-122)
- `## Schema Versioning Rules` (what bumps the version vs. additive, lines 124-137)

Copy all three verbatim, adapting paths (`.agentbloc/graph/business-graph.json` -> `.agentbloc/team/agent-profiles.yaml`) and adding D-26 conversational-edit rule to Re-run Behavior (patches beat regeneration).

---

### `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` (NEW)

**Analog:** `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/examples/arco-rooms-business-graph.json` (103 lines)

**Why this analog:** Same Arco Rooms scenario, same fixture role (canonical test data), same examples/ directory. The Business Graph fixture IS the input this YAML is generated from. Planner can walk the Business Graph 1:1 to verify the YAML covers all processes.

**Target length:** 90-140 lines (3 agents * ~25 lines/agent + team header + orchestration workflows).

---

#### Pattern A: Fixture provenance + coverage

The Business Graph at `examples/arco-rooms-business-graph.json` has THREE processes:
1. "Invoice Collection" (cron `0 22 * * *`, 8 tools, 5 steps) -> Gestor Documental-style agent
2. "Payment Matching" (cron `30 22 * * *`, 2 tools, 5 steps) -> Gestor de Cobros
3. "Owner Reporting" (cron `0 23 * * *`, 1 tool, 4 steps) -> Recepcionista-style reporter

**CONTEXT.md D-30 override:** The fixture uses the **PDF page 3 canonical 3 agents** (Gestor Cobros, Recepcionista, Gestor Documental) — NOT the Phase 1-4 v1.0 fixture's {Invoice Collector, Payment Matcher, Report Sender}. The mapping:
- Gestor Documental <- "Invoice Collection" process
- Gestor Cobros <- "Payment Matching" process + overdue-invoice rule from decision_patterns
- Recepcionista <- "Owner Reporting" process

The 2 anticipated agents (Analista Rentabilidad, Gestor Incidencias) are **excluded** per D-30 — they appear in a separate `arco-rooms-agent-profiles-anticipated.yaml` when Phase 15 ships.

---

#### Pattern B: YAML fixture shape — no direct analog, derive from PDF page 3 + agent-profile-schema.md

No existing YAML fixture in `.claude/skills/agentbloc/examples/`. Shape the fixture directly from the Schema Definition block in agent-profile-schema.md (Pattern C above). Planner should emit:

````markdown
```yaml
schema_version: 1
team:
  name: arco-rooms-team
  topology: mesh
  topology_rationale: "3 agents peer-call each other (Recepcionista queries Gestor Cobros for payment status before sending reports); mesh matches ClaudeClaw SendMessage pattern."
  briefing_agent_id: null

agents:
  - id: gestor-documental
    role: "Invoice Collection Specialist"
    goal: "Fetch, deduplicate, and persist utility invoices from 6 providers every night"
    backstory: "Owns the daily invoice-collection pipeline. Has credentials for Endesa, Aguas de Almeria, Naturgy, Movistar, Urbaser, Mapfre. Knows which providers deliver by email and which require portal login."
    tools:
      - playwright-mcp
      - google-workspace-mcp
      - mapfre-api
    triggers:
      - type: cron
        schedule: "0 22 * * *"
    autonomy: full
    outputs:
      - type: state-file
        schema: ".agentbloc/state/invoices.json"
    escalation: "telegram:pablo"
    dependencies: []
    blast_radius: 2
    model: sonnet

  - id: gestor-cobros
    role: "Payment Reconciliation Engine"
    goal: "Match bank transactions to invoices with confidence scoring; enforce the overdue-7-day rule"
    backstory: "Owns the daily payment-matching pipeline. Knows the tenant registry and confidence-score regex patterns. Applies decision_patterns rule: 'If overdue > 7 days, send formal notice.'"
    tools:
      - bank-mcp
      - google-sheets-mcp
    triggers:
      - type: cron
        schedule: "30 22 * * *"
      - type: inter-agent
        caller: recepcionista
        message: payment-status-query
    autonomy: semi
    outputs:
      - type: state-file
        schema: ".agentbloc/state/matches.json"
    escalation: "telegram:pablo"
    dependencies:
      - gestor-documental
    blast_radius: 2
    model: opus

  - id: recepcionista
    role: "Daily Operations Reporter"
    goal: "Send per-owner Telegram summary of invoices, payments, and unmatched items"
    backstory: "Owner-facing agent. Queries Gestor Cobros for payment status before composing messages. Sends to each owner's thread."
    tools:
      - telegram-mcp
    triggers:
      - type: cron
        schedule: "0 23 * * *"
    autonomy: semi
    outputs:
      - type: telegram-message
        schema: "per-owner-daily-summary"
    escalation: "telegram:pablo"
    dependencies:
      - gestor-cobros
    blast_radius: 4
    model: sonnet

orchestration:
  workflows:
    - id: cobro-diario
      type: sequential
      agents: [gestor-documental, gestor-cobros, recepcionista]
      trigger:
        type: cron
        schedule: "0 22 * * *"
      why: "Sequential per orchestration-patterns.md: each agent's output feeds the next (invoices -> matches -> report)."
      steps:
        - gestor-documental collects invoices
        - gestor-cobros matches payments
        - recepcionista sends per-owner summary

    - id: recepcionista-on-demand
      type: event-driven
      agents: [recepcionista]
      trigger:
        type: inter-agent
        caller: gestor-cobros
        message: unmatched-payment-alert
      why: "Event-driven per orchestration-patterns.md: Gestor Cobros wakes Recepcionista when unmatched items exceed threshold."
      flow: "Gestor Cobros detects >= 3 unmatched items; sends inter-agent message to Recepcionista; Recepcionista composes a Telegram alert to Pablo; returns."
```
````

---

### `.claude/skills/agentbloc/references/phase-2-design.md` (MODIFY)

**Analog:** `.planning/phases/08-business-graph-foundation/08-02-PLAN.md` Task 1 — the surgical Edit-4a/4b pattern for inserting new H3 subsections and an Emission subsection into an existing protocol file.

**Why this analog:** Phase 8 Task 1 was the identical structural operation on phase-1-interview.md (added a Category 7 seed question + Summary Template tables + Emission subsection with cross-link to business-graph-schema.md). Phase 9 applies the same surgical-insert pattern on phase-2-design.md (adds a Designer Subagent Invocation subsection + Conversational Editing subsection with cross-link to agent-profile-schema.md + orchestration-patterns.md).

**Localized extension points** (line ranges in the CURRENT 313-line `phase-2-design.md`):

| Extension | Current location | What to add |
|-----------|------------------|-------------|
| **Load companion references** | Lines 23-25 (Design Opening): "also load [references/blast-radius.md](blast-radius.md) and [references/frameworks.md](frameworks.md)" | Update to also reference `orchestration-patterns.md` and `agent-profile-schema.md` |
| **Designer Subagent Invocation** (D-21, D-22) | NEW H2 subsection. Insert **after** Step 7 (Visual Presentation, ends line 293) and **before** Design Gate (starts line 295). | Add full subsection: invocation payload, fork-context note, path `.agentbloc/team/agent-profiles.yaml`, gate wait |
| **Conversational Editing Flow** (D-26) | NEW H2 subsection. Insert **after** Design Gate (line 301) and **before** Quick Reference (line 303). | Add full subsection: patch types, in-place edit rule, never-regenerate rule, re-render-table-only |
| **Quick Reference update** | Lines 305-313 (table of Step -> ID -> Output -> Cross-References) | Add two new rows: Designer Invocation (DSGN-01..06 + ORCH-01..04) and Conversational Editing (DSGN-07) |

---

#### Pattern A: Companion references update (mirrors Phase 8 SKILL.md Edit 1)

**Analog:** `phase-2-design.md` lines 23-25 (existing Design Opening):

```markdown
You have the confirmed interview summary. Before starting design, also load [references/blast-radius.md](blast-radius.md) and [references/frameworks.md](frameworks.md). The Security Profile from the interview summary tells you which compliance regimes are active.
```

**Replace with:**

```markdown
You have the confirmed Business Graph. Before starting design, also load [references/blast-radius.md](blast-radius.md), [references/frameworks.md](frameworks.md), [references/orchestration-patterns.md](orchestration-patterns.md), and [references/agent-profile-schema.md](agent-profile-schema.md). The Security Profile from the Business Graph tells you which compliance regimes are active.
```

Net: +2 link references in the same sentence. No new paragraph.

---

#### Pattern B: Designer Subagent Invocation subsection (new)

**Analog:** `phase-1-interview.md` lines 319-338 (Business Graph Emission subsection — the exact pattern per Phase 8 Task 1 Edit 4b). The emission subsection of phase-1-interview.md starts with a numbered-list "Once the user confirms..." and ends with a `Phase N gate becomes approved` transition note. Phase 9 mirrors this structure in phase-2-design.md for Designer invocation.

Concrete text the planner should insert (between Step 7 and Design Gate):

```markdown
## Step 8: Designer Subagent Invocation (DSGN-01..06, ORCH-01..04)

Once Steps 1-7 above are complete and the draft team is in your working memory, spawn the Designer Agent subagent to materialize the structured artifact.

### Invocation

Spawn the subagent defined at `.claude/agents/designer-agent.md` (`context: fork`). The subagent inherits no main-session conversation noise; its world is the Business Graph + the schema references. Pass the following as the subagent's initial prompt context:

1. Path to Business Graph: `.agentbloc/graph/business-graph.json`
2. Required reading: `references/agent-profile-schema.md`, `references/orchestration-patterns.md`, `references/blast-radius.md`, `references/frameworks.md`
3. Output target: `.agentbloc/team/agent-profiles.yaml` (create `.agentbloc/team/` if missing)
4. Optional companion: `.agentbloc/team/team-topology.md` (Mermaid diagram per v1.0 D-06)
5. Scope note: Designer emits REQUESTED agents only. Anticipated agents are Phase 15 (ANTIC) and excluded here.

### Output Contract

Designer returns to the main session:
- Confirmation string: "agent-profiles.yaml saved at .agentbloc/team/agent-profiles.yaml"
- A rendered Markdown TABLE of the team (per v1.0 D-05) + per-agent cards
- An ASCII topology diagram (per v1.0 D-06)

The YAML is NEVER shown to the user. The rendered table + cards ARE the user-facing review.

### Gate

After Designer returns, verify:
1. `.agentbloc/team/agent-profiles.yaml` exists.
2. Validation Checklist from `references/agent-profile-schema.md` passes all REQUIRED checks.
3. The rendered table + ASCII diagram are presented to the user for confirmation.

Set the Phase 2 `agent_profiles_validated` sub-gate to `approved` only after the user confirms the rendered team.
```

---

#### Pattern C: Conversational Editing Flow subsection (new — D-26)

**Analog:** `business-graph-schema.md` Re-run Behavior (lines 114-122) for the keep/overwrite/merge shape. Combined with the v1.0 Phase 2 Design Gate (lines 296-301) for the "user override / modification request" language.

Concrete text the planner should insert (after Design Gate, before Quick Reference):

```markdown
## Conversational Editing Flow (DSGN-07)

After the user reviews the rendered team, they may request edits:

- "Rename gestor-cobros to Maria's agent."
- "Drop the recepcionista for now."
- "Give gestor-documental bash access."
- "Change topology from mesh to pipeline."

### Surgical Patch Protocol

For each user edit:

1. Parse the intent into a structured patch: `{rename, delete, add-tool, remove-tool, change-autonomy, change-topology, change-blast-radius}`.
2. Re-invoke Designer Agent with the patch payload AND the existing `.agentbloc/team/agent-profiles.yaml` as input. Designer NEVER regenerates from the Business Graph (regeneration would re-insert rejected or renamed agents, fighting user intent — D-26).
3. Designer applies the patch in-place, bumps `team.modified_at`, and re-runs the Validation Checklist.
4. Designer returns the NEW rendered table (not the YAML).
5. User confirms the new table.

### Never Regenerate

If the user says "redo the whole team," prompt for clarification: "Do you want me to start from scratch (discards your edits) or keep your edits and just refine specific agents?" Default to keep.

### Gate Re-entry

After every edit round, the Phase 2 `agent_profiles_validated` sub-gate returns to `pending` until user confirmation. Multiple edit rounds are fine; each completes its own confirmation turn.
```

---

### `.claude/skills/agentbloc/SKILL.md` (MODIFY)

**Analog:** `.planning/phases/08-business-graph-foundation/08-02-PLAN.md` Task 2 (the Phase 8 three-edit SKILL.md surgical pattern). This is the **exact same file** being extended **one phase later** with the **same three-edit pattern** — the Phase 9 extension is the structural twin of the Phase 8 extension.

**Localized extension points** (line ranges in the CURRENT 163-line `SKILL.md`):

| Extension | Current location | What to change | D-29 Sub-edit |
|-----------|------------------|----------------|---------------|
| **Add `agent_profiles_validated` sub-gate to State Transitions** | Lines 36-40 (State Transitions bullets; Phase 8 already added a `Phase 1 specific` bullet at line 40) | Append a `Phase 2 specific` bullet paralleling the existing Phase 1 bullet | Edit 1 |
| **Phase 2 Summary wiring (Designer invocation)** | Lines 98-105 (Phase 2: General Design section; Phase 8 added a Precondition paragraph at line 102) | Extend the "You MUST read..." block to include agent-profile-schema.md + orchestration-patterns.md AND add a Summary gate paragraph AFTER the Precondition | Edit 2 |
| **Phase 3 precondition** | Lines 107-112 (Phase 3: Deep Integration Analysis section) | Insert a `**Precondition:**` paragraph between the descriptive sentence and the "You MUST read..." block, parallel to the Phase 2 Precondition inserted in Phase 8 | Edit 3 |

**Size budget:** Current 163 lines + ~15 lines net add = ~178 lines. Stays under 250-line limit.

---

#### Pattern A — Edit 1: Add `agent_profiles_validated` sub-gate (mirrors Phase 8 Task 2 Edit 2)

**Analog:** `08-02-PLAN.md` Task 2 Edit 2 (lines 279-296) — inserted the `Phase 1 specific` bullet. Phase 9 inserts the parallel `Phase 2 specific` bullet.

**Source — current SKILL.md lines 36-40 (after Phase 8 shipped):**

```markdown
### State Transitions

- `pending` to `approved`: User explicitly confirms ("yes", "approved", "ok", "adelante")
- `pending` to `blocked`: An issue prevents progression
- Phase number increments ONLY after current gate is `approved` AND user explicitly confirms
- Phase loopback: If new information invalidates a prior approved gate, reset that phase to `pending`. Announce: "New information affects Phase N. Returning to re-validate."
- Phase 1 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered Business Graph tables AND the `business_graph_validated` sub-gate (all REQUIRED checks from [references/business-graph-schema.md](references/business-graph-schema.md) Validation Checklist have passed and the file at `.agentbloc/graph/business-graph.json` has been written).
```

**After Phase 9 edit — append one new bullet as the LAST item:**

```markdown
- Phase 2 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered team table and per-agent cards AND the `agent_profiles_validated` sub-gate (all REQUIRED checks from [references/agent-profile-schema.md](references/agent-profile-schema.md) Validation Checklist have passed and the file at `.agentbloc/team/agent-profiles.yaml` has been written by the Designer subagent).
```

Net: +1 bullet. Same micro-edit as Phase 8.

---

#### Pattern B — Edit 2: Extend Phase 2 load list + add Summary wiring (mirrors Phase 8 Task 2 Edit 1 + Edit 3)

**Analog:** `08-02-PLAN.md` Task 2 Edit 1 (Phase 1 load list extension) for the "AND the X AND the Y" sentence pattern + Task 2 Edit 3 (Phase 2 Precondition insert) for the paragraph-insert-between-prose-and-You-MUST shape.

**Source — current SKILL.md lines 98-105 (after Phase 8):**

```markdown
### Phase 2: General Design

Translate the interview into a high-level agent team design. Identify agents (one per responsibility), map topology (pipeline, mesh, hierarchy, swarm), define contracts, schedules, and governance. Present as diagram + table.

**Precondition:** Verify `.agentbloc/graph/business-graph.json` exists and validates against the Validation Checklist in [references/business-graph-schema.md](references/business-graph-schema.md). If the file is missing or fails any REQUIRED check, return the state bar to Phase 1 with gate `pending` and re-run the Summary gate before attempting Phase 2 again.

You MUST read the complete design protocol before starting this phase:
See [references/phase-2-design.md](references/phase-2-design.md)
```

**After Phase 9 edit — three micro-changes:**

1. Extend the "You MUST read..." sentence + add two See-lines (same pattern as Phase 8 Task 2 Edit 1):

```markdown
You MUST read the complete design protocol AND the orchestration patterns reference AND the agent profile schema before starting this phase:
See [references/phase-2-design.md](references/phase-2-design.md)
See [references/orchestration-patterns.md](references/orchestration-patterns.md)
See [references/agent-profile-schema.md](references/agent-profile-schema.md)
```

2. Insert a new Summary gate paragraph BETWEEN the Precondition block and the "You MUST read..." block:

```markdown
**Summary Gate:** After walking the design protocol, spawn the Designer Agent subagent (`.claude/agents/designer-agent.md`, `context: fork`) to emit `.agentbloc/team/agent-profiles.yaml`. The subagent writes silently; the rendered team table + per-agent cards are what the user reviews and confirms. See [references/phase-2-design.md](references/phase-2-design.md) Step 8 for the invocation protocol.
```

Final shape of the Phase 2 section becomes:

```markdown
### Phase 2: General Design

Translate the interview into a high-level agent team design. ...

**Precondition:** Verify `.agentbloc/graph/business-graph.json` exists and validates ... (unchanged from Phase 8).

**Summary Gate:** After walking the design protocol, spawn the Designer Agent subagent ... (NEW).

You MUST read the complete design protocol AND the orchestration patterns reference AND the agent profile schema before starting this phase:
See [references/phase-2-design.md](references/phase-2-design.md)
See [references/orchestration-patterns.md](references/orchestration-patterns.md)
See [references/agent-profile-schema.md](references/agent-profile-schema.md)
```

---

#### Pattern C — Edit 3: Add Phase 3 precondition (mirrors Phase 8 Task 2 Edit 3 exactly)

**Analog:** `08-02-PLAN.md` Task 2 Edit 3 (Phase 2 Precondition paragraph) — identical operation, one phase later.

**Source — current SKILL.md lines 107-112:**

```markdown
### Phase 3: Deep Integration Analysis

For each agent action, find the BEST integration method. Research APIs, MCP servers, npm packages, Playwright paths, email scraping, webhooks. Present options with pros/cons/setup for every service.

You MUST read the complete integration analysis protocol before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
```

**After Phase 9 edit — insert Precondition paragraph between the descriptive sentence and the "You MUST read..." block:**

```markdown
### Phase 3: Deep Integration Analysis

For each agent action, find the BEST integration method. Research APIs, MCP servers, npm packages, Playwright paths, email scraping, webhooks. Present options with pros/cons/setup for every service.

**Precondition:** Verify `.agentbloc/team/agent-profiles.yaml` exists and validates against the Validation Checklist in [references/agent-profile-schema.md](references/agent-profile-schema.md). If the file is missing or fails any REQUIRED check, return the state bar to Phase 2 with gate `pending` and re-run the Summary gate before attempting Phase 3 again.

You MUST read the complete integration analysis protocol before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
```

Exact parallel of Phase 8 Task 2 Edit 3. Net: +1 paragraph (+2 lines).

---

## Shared Patterns

### Reference file structural spine (applies to orchestration-patterns.md AND agent-profile-schema.md)

**Source:** every file in `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/` (see `frameworks.md`, `business-graph-schema.md`, `blast-radius.md`)

Every reference file follows:

1. H1 title
2. One-line blockquote `> ` describing when/how loaded (lines 1-3)
3. `## Table of Contents` with anchor links
4. `## When This Applies` — paragraph explaining trigger condition
5. Substantive content as H2 sections
6. `## Quick Reference` summary at bottom

**Apply to:** Both new references (orchestration-patterns.md, agent-profile-schema.md) open with this skeleton.

### Table-driven rules (applies to every new reference)

**Source:** `frameworks.md` (Concept Mapping, Topology Mapping, Practical Sizing — all tables), `business-graph-schema.md` (Field Obligation Matrix, Trigger Bounded Enum — all tables), `blast-radius.md` lines 22-29 (Scoring Levels table), `data-classification.md` (every section is a table)

All bounded enums / scoring / field definitions render as markdown tables, NOT prose lists. Columns typically: name | definition | required-companions | example | regime-or-level-triggered.

**Apply to:** orchestration-patterns.md 5-pattern table + topology table + framework inheritance table. agent-profile-schema.md field obligation matrix + 3 bounded enum tables.

### Cross-link to companion references (shorthand relative paths)

**Source:** `phase-1-interview.md` line 25 (unconditional companion load) + `business-graph-schema.md` lines 3, 18 (cross-links to phase-1-interview.md and data-classification.md)

Companion-loaded references cross-link to each other using **shorthand relative paths** (just `frameworks.md`, no `references/` prefix, because they sit in the same directory). From SKILL.md they use the full relative path (`references/frameworks.md`).

**Apply to:** orchestration-patterns.md cross-links to frameworks.md (sibling) and phase-2-design.md (sibling). agent-profile-schema.md cross-links to business-graph-schema.md (sibling) and orchestration-patterns.md (sibling) and blast-radius.md (sibling).

### Surgical SKILL.md edits (applies to the 3 D-29 edits)

**Source:** `08-02-PLAN.md` Task 2 (the Phase 8 precedent — the most recent SKILL.md edit pattern)

All SKILL.md edits in extension phases follow the same discipline:
- Touch only the Phase N section where the change belongs
- Add reference links in the existing "You MUST read..." block, not a new block (this is the "AND the X" sentence-extension pattern)
- Add gate rule as a new bullet to State Transitions (never a new top-level gate value)
- Keep total file under 250 lines
- Do not restructure State Protocol or Hard Gates sections; extend via additive bullets

**Apply to:** Phase 9 SKILL.md edits — three edits strictly parallel to Phase 8's three edits. Append-only in State Transitions; sentence-extension in Phase 2 load list; paragraph-insert in Phase 3.

### Subagent YAML frontmatter

**Source:** `/Users/pablodelarco/.claude/agents/gsd-pattern-mapper.md` lines 1-12 (`name`, `description`, `tools`, `color`)

Every Claude Code subagent file opens with a YAML frontmatter block listing `name` (lowercase kebab), `description` (one-liner explaining when to spawn), `tools` (comma-separated list), and optionally `color` (for UI). v2.1+ adds `context: fork` to isolate the subagent's working memory.

**Apply to:** `.claude/agents/designer-agent.md` — exactly this shape, with scoped tool set per D-21 (no Bash).

---

## No Analog Found

| Sub-pattern | Reason | Fallback |
|-------------|--------|----------|
| Project-local subagent in AgentBloc repo | `.claude/agents/` directory does not exist in this repo yet — Designer is the first | Use global `~/.claude/agents/` subagents as the convention reference (gsd-pattern-mapper.md is the cleanest shape) |
| Commented-YAML schema block in a reference | Phase 8's `business-graph-schema.md` uses JSONC; no YAML equivalent exists yet | Follow the same commented-line pattern as business-graph-schema.md but with YAML syntax (no braces, indentation-based nesting) |
| Conversational surgical-patch protocol | Phase 8's Re-run Behavior covers keep/overwrite/merge for JSON; patch-level edit for YAML is new | Compose from business-graph-schema.md Re-run Behavior + phase-2-design.md Design Gate (lines 296-301) for modification-request language; new D-26 rule is "never regenerate, patch in place" |
| 5-pattern orchestration catalog | No existing reference enumerates 5 patterns; frameworks.md covers 3 frameworks | Derive directly from v2.0-PROMPT.pdf page 1 ("5 Patrones de Orquestación Universales") and D-24 table. ADK naming from Google ADK primitives. |

---

## Metadata

**Analog search scope:**
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/` (20 files — includes the new business-graph-schema.md from Phase 8)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/SKILL.md` (163 lines)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/examples/` (2 files: arco-rooms.md walkthrough, arco-rooms-business-graph.json Phase 8 fixture)
- `/Users/pablodelarco/.claude/agents/` (28 global gsd-* subagents; convention reference only)
- `/Users/pablodelarco/agentbloc/.planning/phases/08-business-graph-foundation/` (just-shipped Phase 8 precedent — 08-PATTERNS.md + 08-02-PLAN.md)
- `/Users/pablodelarco/agentbloc/.planning/milestones/v1.0-phases/03-interview-and-design-phases/` (v1.0 D-05/D-06/D-07/D-09 inheritance context)

**Primary analogs selected:**
1. `references/business-graph-schema.md` — structural twin for `agent-profile-schema.md` (per D-28)
2. `references/frameworks.md` — structural twin for `orchestration-patterns.md` (per D-27)
3. `examples/arco-rooms-business-graph.json` — fixture family for `arco-rooms-agent-profiles.yaml` (per D-30)
4. `~/.claude/agents/gsd-pattern-mapper.md` — Claude Code subagent frontmatter convention for `.claude/agents/designer-agent.md` (per D-21; first project-local subagent)
5. `.planning/phases/08-business-graph-foundation/08-02-PLAN.md` Task 1 — surgical-insert precedent for `phase-2-design.md` extension (parallel operation)
6. `.planning/phases/08-business-graph-foundation/08-02-PLAN.md` Task 2 — three-edit SKILL.md precedent for the 3 D-29 edits (exact pattern repeat, one phase later)

**Files scanned:** 27 (20 references + SKILL.md + 2 examples + 28 global subagents sampled + 2 v1.0/v2.0 Phase 8 plans)
**Pattern extraction date:** 2026-04-21
