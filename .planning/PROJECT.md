# AgentBloc

## What This Is

An open-source Claude Code skill that acts as a **proactive AI consultant**: understands your business through a deep interview, designs the agent team you need, anticipates what you haven't asked for, and deploys a running multi-agent system on top of Claude Code + ClaudeClaw + MCP + n8n + Telegram. Generated artifacts run natively with zero custom runtime on the AgentBloc side.

Three-layer intelligence: **Understand** (business graph from interview) → **Diagnose** (classify each process: cron / reactive / analytical / interface / watchdog) → **Anticipate** (suggest agents the user didn't request but needs).

## Current State

v1.0 shipped 2026-04-18. Published to https://github.com/pablodelarco/agentbloc as a single anonymized orphan commit (`9c74c9e`). 68/68 requirements satisfied, 77/77 TAP tests passing, 4/4 CI jobs green. Full audit in `milestones/v1.0-MILESTONE-AUDIT.md`.

## Current Milestone: v2.0 Designer + Deploy (auto-generate and deploy agent teams)

**Goal:** Turn the v1.0 interview+design conversation into a **fully automated pipeline** that (a) produces a structured Business Graph from the interview, (b) auto-generates per-agent YAML profiles via a Designer Agent, (c) discovers or wraps the integrations each agent needs, (d) deploys them as ClaudeClaw skills + jobs + MCP entries + memory directories, and (e) runs the team end-to-end with event-driven triggers, hierarchical reporting, and proactive agent anticipation.

Reference: `.planning/v2.0-PROMPT.pdf` is the authoritative scope document for v2.0 (pivoted from earlier "Discovery Agent" framing on 2026-04-20).

**Target features (v2.0 scope):**
- **Business Graph JSON schema** produced by the v1.0 interview — structured business, processes, tools, channels, decision patterns
- **Designer Agent** (AG2 CaptainAgent pattern) — auto-generates agent profiles (role / goal / backstory / tools / triggers / autonomy / outputs / escalation / dependencies) from the Business Graph
- **Orchestration Classifier** — classifies each workflow as Sequential / Parallel / Loop / Event-driven / Conversational (the 5 universal patterns from CrewAI / LangGraph / AG2 / ADK)
- **Integration Discovery** — four-step search per tool: existing MCP in `.mcp.json` → ecosystem MCP (`npx -y @mcp/xxx`) → generate wrapper MCP from public API via a `mcp-builder` skill → **browser automation fallback** (Playwright MCP)
- **Deploy Pipeline** — auto-generates `skills/{agent-id}/SKILL.md`, ClaudeClaw cron/trigger job configs, `.mcp.json` entries, and per-agent memory directories
- **Agent Memory System** — `.claude/agents/{agent-id}/memory.md + state.json + last-run.json`
- **Multi-agent Runtime** — ClaudeClaw `Agent` / `TeamCreate` / `SendMessage` primitives + system cron + n8n webhooks for real-time triggers
- **Autonomy Controller** — per-agent level (`full` / `semi` / `supervised`) + structured escalation to Telegram with context
- **Hierarchical Reporting** — 30 agents → 5 team leads → 1 briefing agent → human (JSONL logs + registry.yaml + pluggable presentation layer)
- **Control Plane UX** (borrowed from Paperclip) — approval queue, per-agent cost tracking, task locking, status badges
- **Anticipation Engine** — suggests agents the user did not request but the business needs (the differentiator vs every other agent framework)
- **Validation against Arco Rooms** — 5-agent team (Gestor Cobros, Recepcionista, Gestor Documental, Analista + Gestor Incidencias anticipados) as canonical v2.0 test case

**Key context (v2.0):**
- **Positioning pivot**: AgentBloc is no longer just "secure agent-team designer" — it is a **proactive AI consultant** that surfaces needs the user didn't articulate. The Anticipate layer is the core differentiation.
- **Stack pivot**: AgentBloc remains a markdown skill, but it explicitly rides on **ClaudeClaw (TypeScript + Bun)** as its runtime platform. ClaudeClaw provides `Agent`, `TeamCreate`, `SendMessage`, Jobs (cron), Telegram bot, hooks, and the skills system. AgentBloc does not reinvent these.
- **Event bus**: **n8n** as the event bus for real-time triggers (webhooks from Gmail / Plaid / BBVA / forms / calendars → ClaudeClaw jobs → agent wakes). Cron remains for scheduled work; n8n covers reactive.
- **Framework inheritance**: v2.0 explicitly borrows patterns from CrewAI (role/goal/backstory), AG2 (CaptainAgent dynamic team generation), Google ADK (Sequential/Parallel/Loop primitives), LangGraph (checkpointing schema), Mastra (Zod-style schema validation between agents), Paperclip (control plane UX). Detailed mapping lives in `.planning/v2.0-PROMPT.pdf`.
- **Relationship to earlier "Discovery Agent" scope**: the prior framing (2026-04-18) was the browser-fallback piece of Integration Discovery Step 4, not the whole milestone. Research artifacts (`research/STACK.md`, `PITFALLS.md`, etc.) stay — they inform that specific sub-phase.

### Active (v2.0 requirement categories)

Requirements are tracked in fresh `REQUIREMENTS.md` written for this scope. Category prefixes:

- **INTV-xx**: Interview extension (v1.0 interview → Business Graph JSON)
- **BGRAPH-xx**: Business Graph schema (structure, validation, versioning)
- **DSGN-xx**: Designer Agent (auto-profile generation, orchestration classification)
- **INTEG-xx**: Integration Discovery steps 1–3 (MCP search, install, wrapper generation)
- **BROWSER-xx**: Integration Discovery step 4 (Playwright MCP browser fallback — reuses prior Discovery Agent research)
- **DEPLOY-xx**: Deploy Pipeline (skills / jobs / MCP configs / memory dir generation)
- **MEM-xx**: Agent Memory System (per-agent directory pattern)
- **ORCH-xx**: Orchestration (5 patterns, workflow runtime primitives)
- **RUNTIME-xx**: Multi-agent runtime (triggers, coordination, state)
- **AUTON-xx**: Autonomy Controller (full/semi/supervised + escalation)
- **MONITOR-xx**: Monitoring + hierarchical reporting (JSONL logs, registry, briefing agent)
- **CTRL-xx**: Control plane UX (approval queue, cost tracking, task locking, status badges)
- **ANTIC-xx**: Anticipation Engine (proactive agent suggestions)

### Validated

- ✓ v1.0 ships (see "Current State" above). 68/68 requirements validated.

### Out of Scope (v2.0)

| Feature | Reason |
|---------|--------|
| Python runtime for AgentBloc | Stack is Claude Code + ClaudeClaw (TypeScript + Bun). Python frameworks (CrewAI / LangGraph / AutoGen) are pattern references, not dependencies. |
| Separate orchestration server (Node.js + Postgres à la Paperclip) | Claude Code IS the runtime. ClaudeClaw provides job scheduling + bot. No additional 24/7 services. |
| Filesystem as inter-agent bus | `SendMessage` between agents (native ClaudeClaw / Claude Code) is faster and cleaner than Paperclip's file-based pattern. |
| Only hierarchical topology | AgentBloc supports pipeline, mesh, hierarchy, and swarm. Designer Agent picks. |
| LLM-routed dynamic agent selection (AG2 SelectorGroupChat) | Too much latency. Flows are hardcoded per team after Designer emits the plan. |
| Manual agent definition by the user | AgentBloc generates agents from the interview; user approves or tweaks — never writes agent YAML from scratch. |
| Web UI / visual workflow builder | Out of scope for v2.0. Progressive UI roadmap: Telegram (v2.0) → Web dashboard (v2.5, Bun + Hono) → Management UI (v3.0). |
| Database in v2.0 | Files-first: JSONL for logs, JSON/YAML/MD for state and config. SQLite arrives with the v2.5 web dashboard. |
| AgentBloc running as 24/7 process | Agents sleep between triggers. Cron and n8n webhooks wake them. |
| AutoGen integration patterns as primary reference | AutoGen is in maintenance mode (Microsoft shifted to Agent Framework). Use AG2 CaptainAgent specifically, but not AutoGen as primary framework reference. |
| Fingerprint evasion / stealth plugins inside Integration Discovery browser fallback | Legal/ethical anti-feature. Inherits the detect-and-degrade policy from the Discovery research. |

## Context

Shipped v1.0 contains ~4,500+ lines of markdown (SKILL.md hub + 19 reference files + 3 example walkthroughs + 2 bilingual glossaries + deployment artifacts + test scenarios + CI pipeline). Repo state:
- `master` branch: full private phase history with original Arco Rooms identifiers
- `main` branch: single orphan commit (anonymized) matching the public GitHub repo
- Remote `pablodelarco/agentbloc`: single commit `9c74c9e feat: AgentBloc v1.0`, CI green

**v2.0 kickoff context (2026-04-18 → 2026-04-20 pivot):**
- 2026-04-18: Milestone kicked off as "Discovery Agent — autonomous reverse engineering." 4 parallel research agents produced STACK / FEATURES / ARCHITECTURE / PITFALLS + SUMMARY. 46 requirements committed, 8 phases committed.
- 2026-04-20: PDF scope document (`v2.0-PROMPT.pdf`) re-anchored v2.0 as **"Designer + Deploy"** with Discovery relegated to a sub-step (Integration Discovery Step 4 browser fallback). PROJECT.md, REQUIREMENTS.md, ROADMAP.md rewritten to match the PDF. Research files retained — valuable for the browser-fallback sub-phase.
- GStack installed (`~/.claude/skills/gstack`, 38 skills linked). Will be used inside GSD phases (`/office-hours`, `/plan-ceo-review`, `/review`, `/qa`, `/cso`, `/ship`).
- Arco Rooms (7-property rental management) is the canonical v2.0 test case.

**Target audience:** Primary = SMB owners and ops teams automating manual processes. Secondary = developers and consultants accelerating agent deliveries.
**Business model:** Open-source skill on GitHub (portfolio piece) feeding premium consulting engagements on Upwork / LinkedIn. Premium tier may emerge around the Designer Agent's managed deployment (v2.5+).

## Constraints

- **Stack (AgentBloc skill)**: pure markdown skill (SKILL.md + references/). v1.0's "no custom runtime" rule is preserved *for AgentBloc*.
- **Stack (platform)**: AgentBloc runs inside **ClaudeClaw** (TypeScript + Bun plugin of Claude Code). ClaudeClaw provides `Agent` / `TeamCreate` / `SendMessage`, job scheduler (cron), Telegram bot, hooks, and skills system. AgentBloc does NOT reinvent these primitives.
- **Event bus**: **n8n** — already deployed on Pablo's infrastructure. Webhooks (Gmail filters, Plaid payment events, calendar watches, form submissions, Telegram bot triggers) route into ClaudeClaw jobs, which wake the relevant agent.
- **State**: files-first. JSONL logs (one event per line, append-only), JSON for machine-written state, YAML for human-authored config, Markdown for agent memory. No database in v2.0.
- **Deployment target**: Generated artifacts must work on any machine running Claude Code + ClaudeClaw + n8n. Self-hosted, VPS, or cloud — same shape.
- **Billing**: Claude Code CLI with Max subscription (`$200/mo`, no per-token cost) for Phase 1 validation. Swap to `ANTHROPIC_API_KEY` in `.env` to switch to pay-per-token without touching code. Prompt caching + batch API reduce ongoing costs at scale.
- **UI progression**: Telegram (v2.0) → Web dashboard (v2.5, Bun + Hono) → Management UI (v3.0). Logs + registry YAML are the data layer; UI is pluggable.
- **MCP-first**: every external integration goes through an MCP server. Wrapper generation (`mcp-builder` skill) for APIs without an MCP. Playwright MCP fallback for services without even a public API. No direct HTTP calls from agents.
- **Human-in-the-loop**: every agent has an autonomy level and an escalation path to Telegram. No silent failures.
- **Compliance**: GDPR patterns from v1.0 carry forward. HIPAA / PCI activate by data classification.
- **Skill size**: SKILL.md capped at ~250 lines. Progressive disclosure via references/.
- **Anti-feature inheritance**: detect-and-degrade anti-bot policy from the Discovery research applies to `BROWSER-xx` reqs (step 4 of Integration Discovery). No stealth libraries, no CAPTCHA solvers, no fingerprint spoofing — enforced by CI deny-list lint.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skill-only for v1.0 (no custom runtime) | Validates consulting thesis before building infrastructure | ✓ Validated — v1.0 shipped on GitHub |
| Claude Code + cron + MCP as deployment target | Proven in production (ClaudeClaw). Zero new dependencies | ✓ Good — v1.0 deployment artifacts all ship on this stack |
| Lean SKILL.md + references/ architecture | 539-line monolith too long for Claude Code best practices | ✓ Good — SKILL.md ~250 lines, progressive disclosure works |
| Gate enforcement via `[PHASE: N \| GATE: X]` ritual | Prose-only gates can be skipped | ✓ Good (modulo runtime behaviors requiring live testing) |
| Open source with consulting upsell | OSS builds trust + portfolio; consulting is the revenue layer | — Pending market validation |
| Security promoted from Phase 4 to Phase 2 (v1.0 roadmap revision) | All user-facing phases depend on real security framework | ✓ Good — v1.0 cross-references work |
| Publish strategy: `main` = single anonymized orphan commit, `master` = private full history | Clean public repo without personal-journey noise | ✓ Good — public repo professional, local history preserved |
| v2.0 scope pivot (2026-04-20): Designer + Deploy, not just Discovery | PDF scope document reframes v2.0 as the full auto-designer vision; Discovery becomes a sub-step | — New; drives the v2.0 roadmap |
| v2.0 stack: AgentBloc inside ClaudeClaw (TypeScript + Bun platform), not standalone | Reuses proven ClaudeClaw primitives (`Agent` / `TeamCreate` / `SendMessage` / Jobs / Telegram). Zero new services. | — New; locks stack for v2.0+ |
| v2.0 event bus: n8n for real-time triggers | Already deployed; native webhook support; zero new code needed | — New |
| v2.0 orchestration patterns: borrow from CrewAI + AG2 + ADK + LangGraph + Mastra + Paperclip | Cherry-pick proven patterns; no framework adoption | — New; specific picks in `v2.0-PROMPT.pdf` |
| v2.0 Anticipation Engine as differentiator | No competing framework suggests unrequested agents; this is the consulting-product signal | — New; P2 priority |
| Use gstack (virtual engineering team skills) inside GSD phases for v2.0+ | GSD owns workflow (discuss/plan/execute/verify); gstack contributes role reviews | — Pending first v2.0 phase |
| v2.0 → v3.0 → v4.0 arc (preserved): Designer Agent → Builder Agent (auto-MCP from browser discovery) → Self-Healing Evolution | Pipeline from "no MCP" → "custom MCP" → "self-maintaining MCP" is the consulting-product thesis | — Pending v2.0 completion |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-20 after v2.0 scope realignment (PDF prompt).*
