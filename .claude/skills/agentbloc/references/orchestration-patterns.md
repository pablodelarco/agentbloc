# Orchestration Patterns

> Loaded by SKILL.md at Phase 2 entry alongside [phase-2-design.md](phase-2-design.md) and [agent-profile-schema.md](agent-profile-schema.md). Defines the 5 universal orchestration patterns Designer Agent classifies each workflow into, plus the topology decision table Designer uses to pick team shape. Framework patterns are referenced, not imported. AgentBloc runs on Claude Code natively.

## Table of Contents

- [When This Applies](#when-this-applies)
- [The 5 Orchestration Patterns](#the-5-orchestration-patterns)
- [Topology Decision Table](#topology-decision-table)
- [Framework Pattern Inheritance](#framework-pattern-inheritance)
- [Pattern Selection Heuristics](#pattern-selection-heuristics)
- [Quick Reference](#quick-reference)

## When This Applies

Claude loads this file at Phase 2 entry and the Designer Agent subagent re-loads it inside its forked context. Specific sections are referenced based on the design step:

- **Topology Selection (DESG-02 + DSGN-04):** Use the Topology Decision Table to pick `team.topology` from {pipeline, mesh, hierarchy, swarm}. Default to **mesh** on ambiguity.
- **Orchestration Pattern Classification (ORCH-01):** For each `orchestration.workflows[]` entry, pick one of the 5 patterns below and write it into `workflows[].type`. Cite the pattern name in `workflows[].why`.
- **Framework Inheritance:** When explaining rationale to the user, cite the pattern's origin (CrewAI / AG2 / Google ADK / LangGraph / Mastra / Paperclip). These are borrowed design patterns, never imported runtimes.

## The 5 Orchestration Patterns

Designer Agent classifies each `orchestration.workflows[]` entry into exactly one of these patterns. Write the picked value into `workflows[].type`. ADK naming is preserved for easy mapping to Google ADK primitives if TypeScript codegen is later added.

| Pattern | ADK Name | Signal From Business Graph | Designer Picks When | Arco Rooms Example |
|---------|----------|---------------------------|---------------------|--------------------|
| **Sequential** | `SequentialAgent` | Ordered steps with dependencies; each step feeds the next | Single-agent or multi-agent workflow has ordered `steps[]` where step N depends on step N-1 | Cobro mensual: verify -> remind -> generate -> update |
| **Parallel** | `ParallelAgent` | Multiple agents run independently; results merge | Multi-agent workflow with no inter-dependencies; weekly reports assembled from independent data sources | Weekly Report assembly from 3 data sources |
| **Loop** | `LoopAgent` | Same step repeats until condition met | Watchdog-style (poll until due date passes, retry until response) | Check-in reminder loop until guest confirms |
| **Event-driven** | Bus pattern | Agent wakes on external event, runs once, sleeps | Most AgentBloc flows - Gmail webhook, BBVA webhook, Telegram inbound | Recepcionista wakes on new Gmail message |
| **Conversational** | Negotiation | Agents deliberate via SendMessage until consensus | Rare; only when a business rule requires multi-party deliberation | Finance + legal agents must both approve a >= 1000 EUR refund |

**Pattern notes:**

- **Sequential** is the most common single-agent pattern. Write `workflows[].steps[]` as an ordered list; Designer lists each step in turn. Deploy Pipeline renders this into a linear cron chain.
- **Parallel** requires every fan-out agent to write to a distinct output key so the merge step has no collisions. If outputs overlap, split the workflow.
- **Loop** requires an explicit exit condition in the workflow description. Designer writes this into `workflows[].flow` as prose so Phase 12 Deploy can render it into a runtime predicate.
- **Event-driven** is the default for external-trigger flows. Designer writes the trigger shape into `workflows[].trigger` (`source` + `name` for `event`, `schedule` for `cron`).
- **Conversational** adds latency (two or more LLM turns per round). Use only when the business rule genuinely requires multi-party approval; otherwise prefer one agent with a deterministic rule.

## Topology Decision Table

Designer Agent picks `team.topology` from the signal set below. On ambiguity, default to **mesh** - matches ClaudeClaw `SendMessage`, degrades naturally to pipeline when only one agent is generated.

| Topology | Signal From Business Graph | Example | Agent Count |
|----------|---------------------------|---------|-------------|
| **Pipeline** | One linear process with ordered handoffs (verify -> remind -> generate) | Single-process cobro flow | 1-3 |
| **Mesh** | Multiple agents that peer-call each other (Recepcionista asks Gestor Cobros for payment status) | Arco Rooms 3-agent team (default) | 3-8 |
| **Hierarchy** | One team lead orchestrates per-domain workers; workers do not talk peer-to-peer | 5-15 agent org with briefing-agent at the top | 5-15 |
| **Swarm** | N independent agents performing similar work in parallel (one-per-property watchdog) | Multi-tenant ops | 5+ |

**Default on ambiguity:** `mesh`. Designer writes the rationale into `team.topology_rationale` so the user sees the reasoning.

**Topology notes:**

- **Pipeline** is the cleanest to debug (each step has exactly one upstream and one downstream). Pick it when the Business Graph shows a single linear process with ordered handoffs and no peer calls.
- **Mesh** is the most forgiving shape. When Designer is unsure whether agents will eventually peer-call each other, pick mesh. It degrades to pipeline automatically if only one agent is generated.
- **Hierarchy** pays off once the team has a dedicated coordinator agent. Below 5 agents it adds overhead without benefit; prefer mesh.
- **Swarm** is rare for SMB automation. Pick it only when the Business Graph describes N identical workers that each own a partition (one-per-property, one-per-tenant, one-per-region).
- **Upgrade path:** a team generated as `pipeline` can be upgraded to `mesh` during conversational edits if the user adds an agent that peer-calls another. Designer re-emits with `topology: mesh` and bumps `team.modified_at`.

## Framework Pattern Inheritance

AgentBloc borrows design patterns, not runtimes. Each pattern below has a source framework and a one-line AgentBloc application. Designer cites the framework in conversational rationale when technical level permits.

| Framework | Pattern Borrowed | AgentBloc Application |
|-----------|-----------------|----------------------|
| **CrewAI** | `role` / `goal` / `backstory` triad per agent | agent-profile-schema.md fields; role is the canonical identity |
| **AG2** | CaptainAgent meta-agent that generates teams on demand | Designer Agent itself (this file's consumer) |
| **Google ADK** | SequentialAgent / ParallelAgent / LoopAgent primitives | The 5-pattern table's ADK Name column |
| **LangGraph** | Checkpointing schema shape (durable state between steps) | `.agentbloc/state/*.json` per-agent, Git-commitable |
| **Mastra** | Zod-style per-agent input/output schema validation | `outputs[].type + schema` in agent profiles |
| **Paperclip** | Control plane UX (approval queue, cost tracking, task locking, status badges) | Phase 14 Briefing Agent consumes agent logs this way |

**Rule:** These are borrowed patterns, never imported runtimes. AgentBloc runs on Claude Code. No Python runtime, no TypeScript agent framework, no `pip install`, no `npm install` of agent SDKs.

**Per-framework notes:**

- **CrewAI** shapes the per-agent identity. Designer writes `role`, `goal`, and `backstory` into every agent. The role is the canonical short identity (e.g., "Invoice Collection Specialist"); the goal is the scoped outcome; the backstory is the narrative prompt the deployed SKILL.md inherits.
- **AG2** shapes Designer itself. AG2's CaptainAgent is the "agent that creates agents" pattern; AgentBloc's Designer is the direct adaptation. Designer reads the Business Graph and emits `agent-profiles.yaml`; CaptainAgent reads a request and emits a team spec.
- **Google ADK** shapes the orchestration vocabulary. ADK ships `SequentialAgent` / `ParallelAgent` / `LoopAgent` as runtime primitives; AgentBloc uses the same names as labels in `workflows[].type` so downstream codegen (if ever added) maps one-to-one.
- **LangGraph** shapes the state-file contract. Each agent writes a JSON checkpoint after every side effect. The file shape mirrors LangGraph's persistent-state model but uses plain JSON files under `.agentbloc/state/` instead of a library-backed store, so state is Git-commitable and human-editable.
- **Mastra** shapes output schema validation. Per-agent `outputs[].schema` points at a schema contract (path, name, or inline definition) that downstream consumers verify before accepting the output.
- **Paperclip** shapes the Phase 14 control plane. Briefing Agent (Phase 14) reads per-agent logs and renders approval queues, cost tracking, task locking, and status badges the same way Paperclip does.

## Pattern Selection Heuristics

When the Business Graph does not clearly signal one pattern:

1. **If the workflow has a cron trigger and one ordered steps list** -> pick `sequential`.
2. **If the workflow has an event trigger from an external service** (gmail, webhook, telegram inbound) -> pick `event-driven`.
3. **If the workflow description mentions "poll", "retry", "until", or "watch"** -> pick `loop`.
4. **If multiple agents read the same input and write independent outputs** -> pick `parallel`.
5. **If the workflow requires multi-party deliberation** (approval from more than one agent before a side effect) -> pick `conversational`. Rare.
6. **Default on ambiguity:** `event-driven`. Most AgentBloc flows are external-trigger-driven.

For topology:

1. **1-3 agents, linear flow:** pick `pipeline`.
2. **3-8 agents that peer-call each other:** pick `mesh` (default).
3. **5+ agents with a coordinator:** pick `hierarchy`.
4. **N independent agents doing the same kind of work in parallel:** pick `swarm`.
5. **Default on ambiguity:** `mesh`.

**Designer's obligation:** Every `workflows[].type` pick must be justified in `workflows[].why` with a one-line citation of this file. Every `team.topology` pick must be justified in `team.topology_rationale` with a one-line signal from the Business Graph. If the rationale field is missing, the Validation Checklist in [agent-profile-schema.md](agent-profile-schema.md) emits a WARN (not a FAIL), but downstream consumers benefit from the rationale being present.

## Quick Reference

- **Sequential:** ordered `steps[]` with dependencies. Cobro-style single-agent flows.
- **Parallel:** independent multi-agent fan-out. Report-assembly flows.
- **Loop:** poll-until-condition. Reminder watchdogs.
- **Event-driven:** external-trigger wake. Most AgentBloc flows.
- **Conversational:** multi-party deliberation. Rare; only when business rules require consensus.
- **Default topology on ambiguity:** `mesh`. Default orchestration pattern on ambiguity: `event-driven`.
- **Rule:** Designer cites this file in `workflows[].why` and in `team.topology_rationale` so the user sees the reasoning.
- **Framework rule:** Borrowed patterns, not imported runtimes. AgentBloc runs on Claude Code. No `pip`, no `npm` install of agent SDKs.
- **Cross-reference:** Downstream consumers of `workflows[].type` are the Phase 12 Deploy Pipeline (renders the 5 patterns into cron chains, ClaudeClaw job configs, and n8n webhook routes) and the Phase 13 Multi-Agent Runtime (interprets the pattern at dispatch time). Both read from the same 5-pattern enum defined here.
- **Escalation:** If Designer cannot pick a pattern with confidence, it returns a targeted follow-up to the main session ("This workflow has no clear trigger - is it cron, external event, or human-initiated?") before emitting. A guessed pattern is worse than a one-question clarification.
- **Idempotency:** Pattern picks are deterministic for a given Business Graph. Re-running Designer against the same `business-graph.json` yields the same `workflows[].type` values unless user edits intervene (D-26 surgical patches override regeneration).
- **Ordering:** The 5 patterns are listed in rough prevalence order for SMB automation: Sequential and Event-driven dominate; Parallel appears in report assembly; Loop in watchdogs; Conversational is rare.
