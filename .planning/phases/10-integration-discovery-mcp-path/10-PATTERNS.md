# Phase 10: Integration Discovery — MCP Path - Pattern Map

**Mapped:** 2026-04-21
**Files analyzed:** 7 (5 new + 2 modified)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.claude/skills/agentbloc/references/mcp-integration-protocol.md` | reference (imperative flow) | request-response / transform | `.claude/skills/agentbloc/references/orchestration-patterns.md` + `.claude/skills/agentbloc/references/phase-3-integration.md` | exact (dual) |
| `.claude/skills/agentbloc/references/mcp-ecosystem-registry.md` | reference (declarative table) | lookup | `.claude/skills/agentbloc/references/frameworks.md` | exact |
| `.claude/skills/agentbloc/references/integration-manifest-schema.md` | reference (schema contract) | CRUD / validation | `.claude/skills/agentbloc/references/agent-profile-schema.md` + `.claude/skills/agentbloc/references/business-graph-schema.md` | exact (dual) |
| `.claude/skills/mcp-builder/SKILL.md` | top-level skill (code generator) | file-I/O / transform | `.claude/skills/agentbloc/SKILL.md` (frontmatter shape) + `.claude/agents/designer-agent.md` (scoped-tool + no-Bash posture) | role-match (no intra-repo top-level skill analog) |
| `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml` | fixture (YAML artifact) | data | `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` + `.claude/skills/agentbloc/examples/arco-rooms-business-graph.json` | exact (dual) |
| `.claude/skills/agentbloc/references/phase-3-integration.md` (MODIFY) | reference (surgical edit) | transform | Git commit `3b312ba` (phase-2-design.md surgical edit pattern) | exact |
| `.claude/skills/agentbloc/SKILL.md` (MODIFY) | skill index (surgical edit) | transform | Git commit `783b538` (Phase 9 D-29 SKILL.md extension) | exact |

---

## Pattern Assignments

### `mcp-integration-protocol.md` (reference, imperative flow)

**Analog A:** `.claude/skills/agentbloc/references/orchestration-patterns.md` (121 lines — structural spine for an imperative decision-flow reference)
**Analog B:** `.claude/skills/agentbloc/references/phase-3-integration.md` (388 lines — the v1.0 integration protocol being extended; reuse its step-heading grammar and decision-matrix shape)

**File-opening pattern** (orchestration-patterns.md lines 1-12):
```markdown
# Orchestration Patterns

> Loaded by SKILL.md at Phase 2 entry alongside [phase-2-design.md](phase-2-design.md) and [agent-profile-schema.md](agent-profile-schema.md). Defines the 5 universal orchestration patterns Designer Agent classifies each workflow into, plus the topology decision table Designer uses to pick team shape. Framework patterns are referenced, not imported. AgentBloc runs on Claude Code natively.

## Table of Contents

- [When This Applies](#when-this-applies)
- [The 5 Orchestration Patterns](#the-5-orchestration-patterns)
- [Topology Decision Table](#topology-decision-table)
- [Framework Pattern Inheritance](#framework-pattern-inheritance)
- [Pattern Selection Heuristics](#pattern-selection-heuristics)
- [Quick Reference](#quick-reference)
```
**Apply:** H1 + blockquote loading note (name Phase 3 entry, reference delegation from `phase-3-integration.md`, re-state the "MCP-first" positioning constraint) + TOC with sections: When This Applies / Step 1 Existing .mcp.json / Step 2 Ecosystem Registry / Step 3 Wrapper Generation / Step 4 Browser Fallback (stub, Phase 11) / Verification Loop (D-34) / Halt-and-Name (D-35) / Evidence Protocol / Quick Reference.

**Imperative step-section pattern** (phase-3-integration.md lines 64-117 — "Step 2: Multi-Method Search Protocol"):
```markdown
## Step 2: Multi-Method Search Protocol

For each service in the inventory, search integration methods in this strict priority order. This follows decision D-01: official API (best) > MCP server (native) > Playwright browser automation > email scraping > webhook interception > manual notification (last resort).

### Priority 1: Official API

WebSearch for `{service_name} API documentation`. If found, record:
- API endpoint base URL
- Authentication method (OAuth, API key, basic auth)
- Rate limits and quotas
- SDK availability (npm, Python, etc.)

### Priority 2: MCP Server

Search for existing MCP servers. Use PulseMCP (`list_servers` tool if available) or WebSearch for `{service_name} MCP server site:pulsemcp.com OR site:github.com`. If found, record:
- Package name (npm or GitHub)
- GitHub stars count
- Last commit date
- Publisher (individual or organization)
- Available tools/capabilities
```
**Apply:** Write the 4-step search protocol as "Step N: <action>" H2 headings with "Priority <N>: <path>" H3 subsections. Each step declares the action verb (Check / Search / Generate / Delegate), the input artifact (agent-profiles.yaml tools[] entry), the output record (manifest entry fields), and the bounded enum value to write into `resolution_method`. Final `## Step 5: Verification Loop` embeds the three D-34 prose checks (Ping / Scope match / Shape probe) as ordered numbered list with FAIL/PASS branches matching the validation-checklist cadence in `business-graph-schema.md` lines 83-99.

**Bounded-enum-driven control flow** (orchestration-patterns.md lines 22-41 — 5-pattern table with signal + decision column):
```markdown
| Pattern | ADK Name | Signal From Business Graph | Designer Picks When | Arco Rooms Example |
|---------|----------|---------------------------|---------------------|--------------------|
| **Sequential** | `SequentialAgent` | Ordered steps with dependencies; each step feeds the next | Single-agent or multi-agent workflow has ordered `steps[]` where step N depends on step N-1 | Cobro mensual: verify -> remind -> generate -> update |
| **Event-driven** | Bus pattern | Agent wakes on external event, runs once, sleeps | Most AgentBloc flows - Gmail webhook, BBVA webhook, Telegram inbound | Recepcionista wakes on new Gmail message |
```
**Apply:** Mirror this shape for the `resolution_method` enum table. Columns: `resolution_method` value / Signal from agent-profiles.yaml / Claude picks when / Arco Rooms example. Rows = `existing` / `ecosystem` / `wrapper` / `browser-fallback` (stub) / `failed`. Default on ambiguity: `ecosystem` (ecosystem registry lookup is cheaper than wrapper generation).

**Quick-Reference closer pattern** (orchestration-patterns.md lines 108-122):
```markdown
## Quick Reference

- **Sequential:** ordered `steps[]` with dependencies. Cobro-style single-agent flows.
- **Parallel:** independent multi-agent fan-out. Report-assembly flows.
- **Loop:** poll-until-condition. Reminder watchdogs.
- **Event-driven:** external-trigger wake. Most AgentBloc flows.
- **Conversational:** multi-party deliberation. Rare; only when business rules require consensus.
- **Default topology on ambiguity:** `mesh`. Default orchestration pattern on ambiguity: `event-driven`.
- **Rule:** Designer cites this file in `workflows[].why` and in `team.topology_rationale` so the user sees the reasoning.
- **Cross-reference:** Downstream consumers of `workflows[].type` are the Phase 12 Deploy Pipeline (renders the 5 patterns into cron chains, ClaudeClaw job configs, and n8n webhook routes) and the Phase 13 Multi-Agent Runtime (interprets the pattern at dispatch time). Both read from the same 5-pattern enum defined here.
```
**Apply:** Close with a `## Quick Reference` bullet block: one-liner per resolution_method, default on ambiguity, rule about evidence record completeness, cross-reference to Phase 12 Deploy Pipeline (consumer of `integration-manifest.yaml`) and Phase 16 TAP tests.

**Cross-reference inline pattern** (phase-3-integration.md line 216-217):
```markdown
**Credential requirement:** {credential_type} with `{scope}` scope (per [references/credentials.md](credentials.md))
**Prompt injection risk:** {layer_assignment} (per [references/prompt-injection.md](prompt-injection.md))
```
**Apply:** For the evidence-protocol section, cross-reference `credentials.md` (D-34 scope-match check) + `prompt-injection.md` (ingestion-layer assignment) + `integration-manifest-schema.md` (output contract) + `mcp-ecosystem-registry.md` (Step 2 lookup target).

---

### `mcp-ecosystem-registry.md` (reference, declarative lookup)

**Analog:** `.claude/skills/agentbloc/references/frameworks.md` (126 lines — curated table of named tools with evidence columns, same declarative-lookup shape)

**File-opening pattern** (frameworks.md lines 1-21):
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

## When This Applies

Claude loads this file during the Design Phase. Specific sections are referenced based on the current design step:

- **Agent Identification (Step 1):** reference CrewAI for role-based decomposition. Break the workflow into distinct job roles, each with a clear responsibility boundary.
```
**Apply:** H1 + blockquote (loaded by SKILL.md at Phase 3 entry alongside `mcp-integration-protocol.md`; this is a lookup table for Step 2 of the 4-step search, not an imperative flow). TOC with sections per service category: Communication / Google Workspace / E-Commerce & Payments / CRM / Accounting / Browser Automation / Development / Workflow Automation (meta).

**Curated-table-with-evidence pattern** (frameworks.md lines 28-40):
```markdown
### Concept Mapping

| CrewAI Concept | AgentBloc Equivalent | Notes |
|---------------|---------------------|-------|
| `role` | Role field in contract card | Function or expertise description. Be specific. |
| `goal` | Responsibility field | Scoped outcome this agent owns |
| `backstory` | Not used | AgentBloc agents are cron-triggered, not conversational personas |
| `tools` | Tools field + blast-radius allowed_tools | Restricted by blast-radius level (see blast-radius.md) |
| `expected_output` | Outputs field | Specific file paths, message formats, or state mutations |
```
**Apply:** Each category section = one H2 + one markdown table with columns per entry. Seed columns from `/Users/pablodelarco/agentbloc/CLAUDE.md` § "MCP Server Ecosystem" tables (reproduced below for recall):
- Registry table columns: `tool_id` / `package` / `publisher` / `trust_tier` (HIGH/MEDIUM/LOW per v1.0 INTG-04) / `last_commit_checked` / `required_scopes` / `tools_declared` / `notes`
- Seed ~20 entries: Telegram (Bot API + MTProto), Slack (official + community), Google Workspace, Google Sheets, Shopify, Stripe, HubSpot, Salesforce, Notion, Xero, Bank (multi-provider), Playwright (official + community), Filesystem, Git, GitHub, Memory, Zapier
- Preserve the HIGH / MEDIUM / LOW tier language verbatim from CLAUDE.md so v1.0 trust-scoring vocabulary stays consistent

**Best-practice + Arco Rooms example pattern** (frameworks.md lines 38-54):
```markdown
### Best Practices

Use specific, function-focused role descriptions. "Invoice Collection Specialist" not "Data Agent." ...

**When to apply:** Always. This is the default agent identification method for every AgentBloc design.

### Arco Rooms Example

The Arco Rooms property management team uses CrewAI-style role decomposition:

| Agent | Role | Responsibility | Blast Radius |
```
**Apply:** After each category table, include a one-paragraph "When to pick this MCP" note (matches v1.0 INTG-04 trust-tier selection rule) + optional Arco-Rooms example row showing which registry entry resolves which agent's tool.

**Trust-tier policy block pattern** (frameworks.md lines 109-119):
```markdown
## Pattern Application by Tech Level

Claude adjusts how deeply it references each framework based on the user's technical level (captured during the interview phase):

| User Tech Level | CrewAI Pattern | LangGraph Pattern | n8n Pattern |
|-----------------|---------------|-------------------|-------------|
| non-technical | Implicit (applied behind the scenes, not named) | Implicit (topology chosen without framework jargon) | Primary: visual flow metaphor used to explain the design |
```
**Apply:** Replace "by Tech Level" with "Trust Tier Criteria" — reproduce the HIGH / MEDIUM / LOW definitions from `phase-3-integration.md` lines 160-165 so the registry is self-contained (a user reading only this file can still resolve trust).

**Quick-Reference closer pattern** (frameworks.md lines 121-126):
```markdown
## Quick Reference

- **CrewAI:** Role-based agent decomposition. Every agent gets a specific job title, bounded responsibility, and defined outputs. Default method for agent identification.
- **LangGraph:** Topology selection via decision tree. Pipeline for simple flows, Hierarchy for 3-5+ agents, Mesh for iterative refinement, Swarm for unknown paths.
- **n8n:** Visual DAG mental model for non-technical explanation. "Steps with arrows." Also informs the deterministic vs. AI step mix through model routing.
- **Key rule:** These are borrowed patterns, not imported runtimes. AgentBloc runs on Claude Code. No Python, no TypeScript frameworks, no `pip install`, no `npm install` of agent SDKs.
```
**Apply:** Close with one bullet per category (default MCP name + trust tier snapshot), plus a "Key rule: Registry entries are seed data for Step 2 of the 4-step search. Missing any required field → fall through to Step 3 (wrapper generation)."

---

### `integration-manifest-schema.md` (reference, schema contract)

**Analog A:** `.claude/skills/agentbloc/references/agent-profile-schema.md` (178 lines)
**Analog B:** `.claude/skills/agentbloc/references/business-graph-schema.md` (137 lines)

Both analogs share an identical spine. Use `agent-profile-schema.md` as the primary template (newer, Phase 9 pattern) and `business-graph-schema.md` for the JSON-vs-YAML comment-style distinction.

**File-opening pattern** (agent-profile-schema.md lines 1-20):
```markdown
# Agent Profile Schema

> Schema reference loaded unconditionally at Phase 2 entry alongside [phase-2-design.md](phase-2-design.md) and [orchestration-patterns.md](orchestration-patterns.md). Defines the canonical `agent-profiles.yaml` emitted by the Designer Agent subagent and the validation checklist Designer walks before writing the file.

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

## When This Applies

Designer Agent reads this file inside its forked context to produce the canonical `agent-profiles.yaml` at `.agentbloc/team/agent-profiles.yaml`. ...
```
**Apply:** Identical TOC structure with `Resolution Method Bounded Enum` + `Trust Tier Bounded Enum` + `Status Bounded Enum` instead of Autonomy/Trigger/Topology. "When This Applies" paragraph names Phase 3 entry + the 4-step search + downstream consumer (Phase 12 Deploy Pipeline).

**Schema Definition block pattern — YAML with inline comments** (agent-profile-schema.md lines 22-66):
```yaml
schema_version: 1                              # REQUIRED. Integer. Bumped only on breaking changes.
team:
  name: "string"                               # REQUIRED. e.g. "arco-rooms-team"
  topology: "pipeline | mesh | hierarchy | swarm"  # REQUIRED. See Topology Bounded Enum.
  topology_rationale: "string"                 # RECOMMENDED. One-line why this topology fits.
  modified_at: "ISO-8601 timestamp"            # OPTIONAL. Bumped on every conversational edit.
  briefing_agent_id: "string | null"           # OPTIONAL. Phase 14 briefing agent reference.

agents:                                        # REQUIRED. Length >= 1.
  - id: "string"                               # REQUIRED. kebab-case, unique within file.
    role: "string"                             # REQUIRED. CrewAI-shaped. e.g. "Invoice Collection Specialist"
    tools:                                     # REQUIRED. Length >= 1.
      - "string"                               # MCP reference or tool name.
    triggers:                                  # REQUIRED. Length >= 1.
      - type: "cron | event | manual | inter-agent"   # See Trigger Bounded Enum.
```
**Apply:** Render the D-36 schema verbatim from `10-CONTEXT.md` lines 107-129 using this exact inline-comment pattern (REQUIRED / RECOMMENDED / OPTIONAL in caps at the start of each comment, bounded-enum values quoted and pipe-separated).

**Field Obligation Matrix pattern** (agent-profile-schema.md lines 68-76):
```markdown
## Field Obligation Matrix

| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED | `schema_version`, `team.name`, `team.topology`, `agents[]` (>=1), per-agent `id` + `role` + `goal` + `tools[]` (>=1) + `triggers[]` (>=1) + `autonomy` + `blast_radius`, `orchestration.workflows[]` (>=1) with `type` + `agents[]` (>=1) + `trigger` | Designer refuses to emit. Main session re-prompts user through targeted follow-up. |
| RECOMMENDED | `backstory`, `outputs[]`, `escalation`, `dependencies[]`, `team.topology_rationale`, `workflows[].why` | Designer emits with warnings. Phase 12 Deploy Pipeline operates with degraded output and flags gaps in DEPLOY-REPORT.md. |
| OPTIONAL | `team.modified_at`, `team.briefing_agent_id`, `model`, `workflows[].steps`, `workflows[].flow` | Silent defaults. Phase 12 proceeds without comment. |

Downstream consumers refuse to proceed on an unknown major `schema_version`, the same rule as business-graph-schema.md.
```
**Apply:** Three-row Tier / Fields / Behavior-if-missing matrix. REQUIRED = `schema_version` + `tools[].tool_id` + `resolution_method` + `mcp_server.package` + `mcp_server.version` + `evidence.url` + `evidence.trust_tier` + `status`. RECOMMENDED = `evidence.last_commit` + `evidence.publisher` + `evidence.tools_declared` + `evidence.required_scopes` + `evidence.healthcheck_at` + `used_by`. OPTIONAL = `evidence.installed_via` + `modified_at` + `failure_reason` (only populated when status=failed).

**Bounded Enum pattern** (agent-profile-schema.md lines 78-98):
```markdown
## Autonomy Bounded Enum

The `autonomy` field per agent is drawn from a fixed set. It drives whether Phase 14 Autonomy layer inserts an approval gate before each side effect.

| Enum Value | Definition | Side-Effect Behavior | When to Pick |
|-----------|-----------|----------------------|--------------|
| `full` | Agent acts without prompting | No approval gate; audit log only | Agent only touches internal state files (blast_radius 1-2) |
| `semi` | Agent confirms before external side effects | Telegram approval required before send or write-external | Agent has L3 writes or occasional external sends |
| `supervised` | Agent proposes every action, waits for approval | Every side effect waits for explicit human ack | L4 agents and high-stakes flows (financial, legal) |

## Trigger Bounded Enum

Inherits the cron / event / manual types from [business-graph-schema.md](business-graph-schema.md) Trigger Bounded Enum, plus one new type for peer calls between agents (ORCH-03).

| Enum Value | Definition | Required Sub-fields | Example |
|-----------|-----------|---------------------|---------|
| `cron` | Time-based recurring trigger | `schedule` (cron string) | `{type: cron, schedule: "0 9 * * 1"}` |
```
**Apply:** Three bounded-enum H2 sections:
1. **Resolution Method Bounded Enum** — columns: Enum Value / Definition / Required Sub-fields / Example. Rows: `existing` / `ecosystem` / `wrapper` / `browser-fallback` / `failed`. Each row names the mcp_server sub-fields it must populate (e.g., `wrapper` requires `installed_via: "wrapper"` + path under `.mcp/generated/<tool-id>/`).
2. **Trust Tier Bounded Enum** — columns: Enum Value / Criteria / When to Pick. Rows: HIGH / MEDIUM / LOW. Cross-reference `phase-3-integration.md` Step 4 Trust Scoring so the v1.0 definitions stay the single source.
3. **Status Bounded Enum** — columns: Enum Value / Definition / Phase 3 gate behavior. Rows: `pending` / `verified` / `failed`.

**Validation Checklist pattern** (agent-profile-schema.md lines 114-140):
```markdown
## Validation Checklist

Designer walks this ordered list before writing `.agentbloc/team/agent-profiles.yaml`. Any FAIL blocks emission; Designer re-prompts the main session with the targeted follow-up text. REQUIRED-tier checks (1-7) block emission; RECOMMENDED check (8) emits with warnings.

**Check 1: `schema_version` present and equals current version (`1`)**
- FAIL: Set `schema_version: 1` automatically; no follow-up needed.

**Check 2: `team.name` non-empty string AND `team.topology` in {pipeline, mesh, hierarchy, swarm}**
- FAIL: Pick topology via [orchestration-patterns.md](orchestration-patterns.md) Topology Decision Table; default to `mesh` on ambiguity.

**Check 5: Every `triggers[].type` in {cron, event, manual, inter-agent} with required sub-field per Trigger Bounded Enum**
- FAIL: Ask "What triggers <agent-id>, a schedule, external event, human action, or another agent?" before emission.
```
**Apply:** 8 ordered prose checks covering the D-34 three-check verification + schema validity. Each check = bold **Check N: <assertion>** + FAIL: <remediation> bullet. Must include:
- Check 1: `schema_version: 1`
- Check 2: Every `tools[].tool_id` is unique kebab-case
- Check 3: Every `resolution_method` ∈ bounded enum with required sub-fields populated
- Check 4 (D-34 Ping): MCP server responds to `tools/list`, declares ≥1 tool → if FAIL, set `status: failed` + write `VERIFICATION-FAILED.md` per D-35
- Check 5 (D-34 Scope match): `evidence.tools_declared[]` intersects the agent's `tools[]` AND every scope present in `.env` or `.env.example` → if FAIL, auto-append to `.env.example` per D-38
- Check 6 (D-34 Shape probe): tool response shape matches `outputs.schema` in agent profile → if FAIL, surface both shapes side-by-side
- Check 7: `used_by[]` resolves to agent ids in `.agentbloc/team/agent-profiles.yaml`
- Check 8 (WARN): RECOMMENDED fields populated or explicitly `null`

**Emission Protocol pattern** (business-graph-schema.md lines 103-112):
```markdown
## Emission Protocol

Emission happens during the [phase-1-interview.md](phase-1-interview.md) Summary of Understanding gate. The steps:

1. Walk the Validation Checklist above in order.
2. For each REQUIRED failure (Checks 1-5), ask the targeted conversational follow-up and wait for the user's answer before resuming.
3. Once all REQUIRED checks pass, render the Business Graph to the user as the tables in the Summary of Understanding Template (business, processes, tools_available, channels, decision_patterns, security_profile). The JSON itself is never shown to the user.
4. After user confirmation ("yes" / "adelante" / etc.), write the JSON silently to `.agentbloc/graph/business-graph.json`. Create the `.agentbloc/graph/` directory if it does not exist.
5. Confirm emission in one sentence: "Business Graph saved. Ready to move to the design phase."
6. Set the Phase 1 `business_graph_validated` sub-gate to `approved` and allow transition to Phase 2.
```
**Apply:** Emission during Phase 3 Summary gate. Ordered 6-step numbered list: walk checklist → surface targeted follow-up on any FAIL → render the integrations TABLE (D-14: YAML never shown) → write silently to `.agentbloc/integrations/integration-manifest.yaml` → confirm "Integration manifest saved" → set `mcp_integrations_verified` sub-gate to approved.

**Re-run Behavior pattern** (business-graph-schema.md lines 114-122):
```markdown
## Re-run Behavior

If `.agentbloc/graph/business-graph.json` already exists when the Summary gate is reached, Claude asks the user: "I already have a Business Graph on file for this project. Do you want to (a) keep the existing one, (b) overwrite it, or (c) merge new processes into it?" Default is **merge** (additive).

- **keep**: Skip emission, transition to Phase 2 with the existing graph.
- **overwrite**: Replace the file entirely after a fresh Validation Checklist pass.
- **merge**: Add newly captured processes to the existing `processes[]` array. If a new process shares a `name` with an existing one, present both to the user and ask whether to rename, overwrite the old, or skip the new.
```
**Apply:** Same three-option (keep / overwrite / re-verify) prompt. Default is **re-verify** (additive per D-36 idempotency rationale — re-running Phase 3 rotates verification state, not Designer output). Include "schema_version mismatch on disk → refuse re-verify and emit `action_required: schema_version_mismatch`" clause verbatim.

**Schema Versioning Rules pattern** (agent-profile-schema.md lines 165-177):
```markdown
## Schema Versioning Rules

The `schema_version` field is an integer. It starts at `1`. The version bumps only on breaking changes:

- A REQUIRED field is removed or renamed.
- An enum value is removed from a bounded type (e.g., dropping `semi` from `autonomy`).

Additive changes do NOT bump the version:

- Adding a new OPTIONAL field (e.g., `model` hint).
- Adding a new value to a bounded enum (e.g., adding `inter-agent` to triggers).
- Loosening a REQUIRED field to RECOMMENDED.
```
**Apply:** Verbatim. `schema_version: 1` integer. Bumps only when a REQUIRED field is removed/renamed OR an enum value is removed. Adding `browser-fallback` to `resolution_method` enum does NOT bump. Downstream (Phase 12) refuses unknown major version.

---

### `mcp-builder/SKILL.md` (top-level skill, code generator)

**Analog A:** `.claude/skills/agentbloc/SKILL.md` (170 lines — YAML frontmatter shape + H1 role paragraph + section structure)
**Analog B:** `.claude/agents/designer-agent.md` (145 lines — scoped-tools + no-Bash + `<write_constraint>` + `<output_contract>` XML-tagged sections)

`mcp-builder` is a skill, not a subagent, but it shares the designer-agent posture (scoped tools, write-only paths, no shell). No existing top-level skill inside AgentBloc yet — combine the two analogs.

**Frontmatter pattern** (agentbloc/SKILL.md lines 1-13):
```markdown
---
name: agentbloc
version: 1.0.0
description: >
  Designs and deploys AI agent teams for businesses through a structured
  6-phase conversational flow: deep interview, agent team design, integration
  analysis, step-by-step confirmation with dry run, deployment artifact
  generation, and post-deploy evolution. Activates when users want to automate
  business workflows, design AI agents, or deploy autonomous processes.
  Triggers: /agentbloc, "design agents", "automate my business", "automatizar
  mi negocio", "crear agentes", "agent team".
allowed-tools: Read Grep Glob WebSearch WebFetch Bash
---
```
**Apply (mcp-builder frontmatter):**
```markdown
---
name: mcp-builder
version: 0.1.0
description: >
  Generates minimal TypeScript MCP server wrappers from public-API specs.
  Produces single-file index.ts + package.json + README.md per tool under
  .mcp/generated/<tool-id>/, using @modelcontextprotocol/sdk and Bun as
  the executor. Activates when a caller (typically AgentBloc Phase 3)
  needs an MCP wrapper for a service without an ecosystem-registry entry.
  Triggers: /mcp-build, "wrap this API as an MCP", "generate MCP server".
allowed-tools: Read Grep Glob Write WebFetch
---
```
Note the tool restriction per D-21 / D-32: Read + Grep + Glob + Write + WebFetch. **NO Bash** (critical — matches designer-agent posture). No WebSearch (registry lookup happens in the caller's context).

**Top paragraph role-shape pattern** (agentbloc/SKILL.md lines 15-22):
```markdown
# AgentBloc -- AI Agent Team Designer

You are AgentBloc, an AI consultant that designs and deploys autonomous agent teams for businesses. You guide users from a vague idea ("I want to automate my invoices") to a fully specified, deployable agent team through deep interviewing, research, and iterative design.

You are not a chatbot. You are a senior AI solutions architect who happens to live inside Claude Code. You have opinions about what works and what doesn't. You push back when a user's idea won't work, and you proactively suggest better approaches. You speak plainly with non-technical users, use technical precision with developers, and adapt to Spanish seamlessly.

You NEVER say "it cannot be done." Every problem has a solution: official API, MCP server, browser automation (Playwright), email scraping, webhook interception, or creative workarounds. You always present multiple options.
```
**Apply:** H1 + 2-3 paragraph role declaration. "You are mcp-builder, a code generator that produces minimal TypeScript MCP server wrappers. You take (a) the calling agent's `tools[]` entry and `outputs.schema` from `agent-profiles.yaml`, (b) a public-API spec URL or OpenAPI document, and produce a single-file `.mcp/generated/<tool-id>/` directory with the minimum viable tool surface the calling agent needs. You do NOT generate full API surfaces — per D-33b, least-privilege is the posture."

**Scoped write-constraint pattern** (designer-agent.md lines 39-48):
```markdown
<write_constraint>
You MUST only write to the following paths:

- `.agentbloc/team/agent-profiles.yaml` (primary output)
- `.agentbloc/team/team-topology.md` (optional Mermaid diagram companion; emit if useful for downstream Phase 12)

Create the `.agentbloc/team/` directory if it does not exist.

You MUST NOT modify any source files under `.claude/skills/` or `.planning/`. You have no Bash access; you cannot run shell commands, install packages, or execute the generated YAML. Use the Write tool exclusively for file creation. No heredoc writes, no `cat << EOF` patterns.
</write_constraint>
```
**Apply:** `<write_constraint>` XML-tagged section. Allowed paths: `.mcp/generated/<tool-id>/package.json` + `.mcp/generated/<tool-id>/index.ts` + `.mcp/generated/<tool-id>/README.md`. Forbidden: anywhere else. No Bash. No `cat << EOF`. Use Write tool exclusively. Note that Claude does NOT run `bun install` or `bun run` — D-37 install discipline applies (the user runs installs in their own shell).

**Core responsibilities list pattern** (designer-agent.md lines 26-37):
```markdown
**Core responsibilities:**

- Map each Business Graph `processes[]` entry into agent role(s) using the process-to-role grouping heuristics below (DSGN-05).
- Pick `team.topology` from {pipeline, mesh, hierarchy, swarm} using the Topology Decision Table in orchestration-patterns.md (DSGN-04, D-23).
- Produce CrewAI-shaped profiles per agent: role / goal / backstory / tools / triggers / autonomy / outputs / escalation / dependencies / blast_radius / model (DSGN-03).
- Walk the Validation Checklist in agent-profile-schema.md before writing. Any REQUIRED failure (Checks 1-7) blocks emission; return the targeted follow-up to the main session.
- Emit `agent-profiles.yaml` silently at `.agentbloc/team/agent-profiles.yaml`. NEVER show the YAML to the user.
```
**Apply:** Bulleted core-responsibilities list. Each bullet cites a decision tag (D-33, D-33b). Responsibilities include: fetch API spec via WebFetch / extract minimal tool surface from calling agent's schema / generate single-file index.ts + package.json + README.md / embed inline comments explaining what API surface was exposed / halt with targeted error if spec cannot be resolved.

**Output Contract pattern** (designer-agent.md lines 125-137):
```markdown
<output_contract>
Every invocation returns to the main session:

1. A path confirmation: `.agentbloc/team/agent-profiles.yaml` exists and validates.
2. A markdown TABLE + per-agent Contract Cards + ASCII topology diagram suitable for direct paste into the main conversation.
3. A one-line summary: "<N> agents, topology=<topology>, <M> workflows classified."

On validation failure, return ONLY:

1. The specific Check number that failed (from agent-profile-schema.md Validation Checklist).
2. The targeted follow-up question from the schema for the main session to ask the user.
3. No YAML file written.
</output_contract>
```
**Apply:** `<output_contract>` section. Return path confirmation `.mcp/generated/<tool-id>/` + summary of exposed tool surface (tool names + each tool's arguments) + one-line "wrapper saved, <N> tools exposed, run `bun install` in `.mcp/generated/<tool-id>/` then add to .mcp.json." On failure (API spec missing, insufficient schema info, forbidden scope) return specific error + no files written.

**Smoke-test / example section** (not in designer-agent.md but needed for D-32 claim that the skill is stable standalone): use the "Reference Implementation" closer pattern from `agentbloc/SKILL.md` lines 168-170:
```markdown
## Reference Implementation

A complete reference implementation (Arco Rooms property management) demonstrating all AgentBloc patterns is available at [examples/arco-rooms.md](examples/arco-rooms.md).
```
**Apply:** Close with `## Reference Implementation` section pointing at an example wrapper generation (e.g., a minimal weather-API wrapper). Optional for v0.1; Pablo discretion per `10-CONTEXT.md` § Claude's Discretion.

---

### `arco-rooms-integration-manifest.yaml` (fixture, YAML artifact)

**Analog A:** `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` (97 lines — Phase 9 fixture; same business context, same agents, same YAML dialect)
**Analog B:** `.claude/skills/agentbloc/examples/arco-rooms-business-graph.json` (Phase 8 fixture — JSON schema_version header pattern)

**Header pattern** (arco-rooms-agent-profiles.yaml lines 1-7):
```yaml
schema_version: 1
team:
  name: arco-rooms-team
  topology: mesh
  topology_rationale: "3 agents peer-call each other (Recepcionista queries Gestor Cobros for payment status before sending owner reports; Gestor Cobros depends on Gestor Documental invoice output); mesh matches ClaudeClaw SendMessage pattern."
  briefing_agent_id: null
```
**Apply:** Top-of-file keys per D-36 schema — `schema_version: 1` then `generated_at: "2026-04-21T17:42:00Z"` then `modified_at: "2026-04-21T17:42:00Z"` then `tools:` array. Timestamps in ISO-8601 with Z suffix (matches the `healthcheck_at` format in the D-36 schema).

**Tool entry pattern** (arco-rooms-agent-profiles.yaml lines 9-27):
```yaml
agents:
  - id: gestor-documental
    role: "Invoice Collection Specialist"
    goal: "Fetch, deduplicate, and persist utility invoices from 6 providers every night"
    backstory: "Owns the daily invoice-collection pipeline..."
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
```
**Apply:** Each `tools[]` entry follows the D-36 schema verbatim. Per D-42, show ~8 tools across the 3 Arco Rooms agents covering:
- **~3 via `resolution_method: existing`** — e.g., `playwright-mcp` (already in `.mcp.json` from gstack), `google-workspace-mcp` (existing entry), `telegram-mcp`
- **~3 via `resolution_method: ecosystem`** — e.g., `gmail-mcp` (`@smithery-ai/gmail-mcp`), `google-calendar-mcp` (`@google-workspace-mcp/calendar`), `notion-mcp`, `google-sheets-mcp`, `xero-mcp`
- **~2 via `resolution_method: wrapper`** — e.g., `bbva-mcp` (PSD2 wrapper generated at `.mcp/generated/bbva-mcp/`), `arco-rooms-api` (custom reservation API wrapper)
- **zero via `browser-fallback`** (Phase 11 scope)
- **zero via `failed`** (happy-path fixture)

**used_by ID-resolution pattern** (arco-rooms-agent-profiles.yaml lines 47-48 — dependencies[] resolves to agent ids):
```yaml
    dependencies:
      - gestor-documental
```
**Apply:** Every tool entry's `used_by[]` MUST resolve to agent ids in `arco-rooms-agent-profiles.yaml` (`gestor-documental`, `gestor-cobros`, `recepcionista`). Check 7 in `integration-manifest-schema.md` enforces this.

**Idempotency pattern** — both fixture analogs are deterministic. The integration manifest must be reproducible from the same agent-profiles.yaml input modulo timestamps (per `10-CONTEXT.md` § Specifics: "The 4-step search is deterministic per input"). Do NOT hand-author entries that can only be explained by running `npm view` mid-generation.

---

### `phase-3-integration.md` (MODIFY, surgical edit)

**Analog:** Git commit `3b312ba` (2026-04-21, Phase 9: wire Designer subagent into phase-2-design.md)

This commit demonstrates the exact Phase 9 D-29 surgical-edit pattern that Phase 10 D-40 mirrors. Three categories of edit: load-list extension + new H2 section added before closing Gate + Quick Reference table row appended.

**Load-list extension pattern** (from 3b312ba, phase-2-design.md Design Opening):
```diff
-You have the confirmed interview summary. Before starting design, also load [references/blast-radius.md](blast-radius.md) and [references/frameworks.md](frameworks.md). The Security Profile from the interview summary tells you which compliance regimes are active.
+You have the confirmed Business Graph. Before starting design, also load [references/blast-radius.md](blast-radius.md), [references/frameworks.md](frameworks.md), [references/orchestration-patterns.md](orchestration-patterns.md), and [references/agent-profile-schema.md](agent-profile-schema.md). The Security Profile from the Business Graph tells you which compliance regimes are active.
```
**Apply:** Edit `phase-3-integration.md` lines 26-28 (at Phase 3 entry, also load section):
- Before: `- [references/credentials.md](credentials.md) for the credential decision tree (used in Step 6)` + `- [references/prompt-injection.md](prompt-injection.md) for the defense layer pipeline (used in Step 6)`
- After: add three more bullets — `- [references/mcp-integration-protocol.md](mcp-integration-protocol.md) for the 4-step MCP search flow (used in Step 2)` + `- [references/mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) for the curated registry (used in Step 2 Priority 1)` + `- [references/integration-manifest-schema.md](integration-manifest-schema.md) for the output artifact contract (used at Gate)`

**Priority-ladder reorder pattern** (D-40 Edit 1): The existing `phase-3-integration.md` lines 66-67 currently state:
```markdown
For each service in the inventory, search integration methods in this strict priority order. This follows decision D-01: official API (best) > MCP server (native) > Playwright browser automation > email scraping > webhook interception > manual notification (last resort).
```
**Apply:** Replace with "This follows v2.0 decision D-40 (MCP-first): MCP server (four-step search) > official API (fallback when no MCP) > Playwright browser automation > email scraping > webhook interception > manual notification (last resort). See [mcp-integration-protocol.md](mcp-integration-protocol.md) for the full MCP search flow." Then promote `### Priority 2: MCP Server` (lines 77-84) to `### Priority 1: MCP Server (Four-Step Search)` and demote `### Priority 1: Official API` (lines 68-75) to `### Priority 2: Official API`.

**Delegation-stub pattern** (D-40 Edit 2): After the new Priority 1 MCP heading, collapse the in-place detail to a pointer:
```markdown
### Priority 1: MCP Server (Four-Step Search)

See [mcp-integration-protocol.md](mcp-integration-protocol.md) for the canonical 4-step flow: existing `.mcp.json` → ecosystem registry lookup → wrapper generation via `mcp-builder` skill → browser-fallback (Phase 11 scope).

**Summary for quick reference:** [preserve the 8-line summary from the existing Priority 2 section so users scanning `phase-3-integration.md` can resolve without jumping files]
```
**Apply:** Preserve the existing section's summary (package name / GitHub stars / last commit / publisher / tools) but replace detailed search instructions with the delegation pointer.

**Phase-11 stub pattern** (D-40 Edit 3): The existing `### Priority 3: Playwright Browser Automation` (lines 86-90) gets a marker:
```markdown
### Priority 3: Playwright Browser Automation [Phase 11 scope]

See forthcoming [references/browser-fallback.md] (Phase 11 BROWSER-01..12) for the full Patchright + HAR capture + injection detector + PII redaction protocol.

**Summary (v1.0, preserved):** [keep the existing 4-line bullet list verbatim]
```
**Apply:** Add the `[Phase 11 scope]` marker + See-line pointing forward (broken link is acceptable — Phase 11 will create the file). Preserve the v1.0 bullet summary so the page still reads standalone.

**Preservation rule:** Per D-40 rationale, do NOT re-litigate Steps 3-7 (evidence / trust / decision matrix / security / presentation). Those 200+ lines stay verbatim.

---

### `SKILL.md` (MODIFY, surgical edit)

**Analog:** Git commit `783b538` (2026-04-21, Phase 9 D-29 SKILL.md extension — three surgical edits: State Transitions bullet + Phase 2 entry + Phase 3 precondition)

This commit is the **exact mirror** Phase 10 D-41 must follow. The diff pattern is:

**State Transitions bullet pattern** (from 783b538 line 41):
```diff
 - Phase 1 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered Business Graph tables AND the `business_graph_validated` sub-gate (all REQUIRED checks from [references/business-graph-schema.md](references/business-graph-schema.md) Validation Checklist have passed and the file at `.agentbloc/graph/business-graph.json` has been written).
+- Phase 2 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered team table and per-agent cards AND the `agent_profiles_validated` sub-gate (all REQUIRED checks from [references/agent-profile-schema.md](references/agent-profile-schema.md) Validation Checklist have passed and the file at `.agentbloc/team/agent-profiles.yaml` has been written by the Designer subagent).
```
**Apply (D-41 Edit 1):** Insert after line 41 (existing Phase 2 specific bullet):
```markdown
- Phase 3 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered integrations table AND the `mcp_integrations_verified` sub-gate (all REQUIRED checks from [references/integration-manifest-schema.md](references/integration-manifest-schema.md) Validation Checklist have passed, every tool entry has `status: verified` with a `healthcheck_at` timestamp, and the file at `.agentbloc/integrations/integration-manifest.yaml` has been written).
```

**Phase entry extension pattern** (from 783b538 lines 102-110 — Phase 2 load-list expansion + Summary Gate note):
```diff
 **Precondition:** Verify `.agentbloc/graph/business-graph.json` exists and validates ...

-You MUST read the complete design protocol before starting this phase:
+**Summary Gate:** After walking the design protocol, spawn the Designer Agent subagent at `.claude/agents/designer-agent.md` (`context: fork`) to emit `.agentbloc/team/agent-profiles.yaml`. The subagent writes silently; the rendered team table + per-agent cards + ASCII topology diagram are what the user reviews and confirms. See [references/phase-2-design.md](references/phase-2-design.md) Step 8 for the invocation protocol.
+
+You MUST read the complete design protocol AND the orchestration patterns reference AND the agent profile schema before starting this phase:
 See [references/phase-2-design.md](references/phase-2-design.md)
+See [references/orchestration-patterns.md](references/orchestration-patterns.md)
+See [references/agent-profile-schema.md](references/agent-profile-schema.md)
```
**Apply (D-41 Edit 2):** Edit the Phase 3 section (current lines 112-119). After the existing Precondition paragraph, insert a Summary Gate paragraph and extend the load list:
```markdown
**Summary Gate:** After walking the 4-step search, write `.agentbloc/integrations/integration-manifest.yaml` silently. The rendered integrations table + per-tool evidence rows + security summary are what the user reviews and confirms (D-14 mirror). See [references/mcp-integration-protocol.md](references/mcp-integration-protocol.md) Verification Loop for the D-34 three-check protocol.

You MUST read the complete integration analysis protocol AND the MCP integration protocol AND the ecosystem registry AND the integration manifest schema before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
See [references/mcp-integration-protocol.md](references/mcp-integration-protocol.md)
See [references/mcp-ecosystem-registry.md](references/mcp-ecosystem-registry.md)
See [references/integration-manifest-schema.md](references/integration-manifest-schema.md)
```

**Phase 4 precondition pattern** (from 783b538 lines 117-119 — Phase 3 precondition was the mirror insertion):
```diff
 For each agent action, find the BEST integration method. ...
+
+**Precondition:** Verify `.agentbloc/team/agent-profiles.yaml` exists and validates against the Validation Checklist in [references/agent-profile-schema.md](references/agent-profile-schema.md). If the file is missing or fails any REQUIRED check, return the state bar to Phase 2 with gate `pending` and re-run the Summary gate before attempting Phase 3 again.
```
**Apply (D-41 Edit 3):** Edit the Phase 4 section (current lines 121-126). After the section intro paragraph, insert:
```markdown
**Precondition:** Verify `.agentbloc/integrations/integration-manifest.yaml` exists AND every tool entry has `status: verified` with a `healthcheck_at` timestamp (per [references/integration-manifest-schema.md](references/integration-manifest-schema.md) Validation Checklist). If the file is missing, any entry is `status: failed`, or any REQUIRED check fails, return the state bar to Phase 3 with gate `pending` and re-run the Summary gate before attempting Phase 4 again.
```

**Budget discipline:** Three edits total. Line count delta: +12 lines. SKILL.md at 170 + 12 = 182 lines, still 68 under the 250-line v1.0 cap (per D-29 / D-41 budget).

---

## Shared Patterns

### Prose-checklist validator (Phase 8 D-13, inherited)

**Source:** `.claude/skills/agentbloc/references/business-graph-schema.md` lines 79-99 + `.claude/skills/agentbloc/references/agent-profile-schema.md` lines 114-140

**Apply to:** `integration-manifest-schema.md` Validation Checklist (Check 1-8) AND the three D-34 verification checks embedded in `mcp-integration-protocol.md`.

**Excerpt:**
```markdown
**Check 1: `schema_version` present and equals current version (`1`)**
- FAIL: Set `schema_version: 1` automatically; no follow-up needed.

**Check 2: `business.type` present and non-empty string**
- FAIL: Ask "What kind of business is this, a rental agency, ecommerce store, clinic, or something else?" before emission.
```
**Rule:** No external tooling (no ajv, jsonschema, yaml linter). Every check = bold **Check N: <assertion>** + FAIL: <specific-remediation>. Remediation names the exact conversational follow-up verbatim when possible.

---

### Silent artifact + rendered table review (Phase 8 D-14, inherited)

**Source:** `.claude/skills/agentbloc/references/business-graph-schema.md` lines 106-111 (Emission Protocol step 3)

**Apply to:** `integration-manifest-schema.md` Emission Protocol step 3 AND SKILL.md Phase 3 Summary Gate paragraph.

**Excerpt:**
```markdown
3. Once all REQUIRED checks pass, render the Business Graph to the user as the tables in the Summary of Understanding Template (business, processes, tools_available, channels, decision_patterns, security_profile). The JSON itself is never shown to the user.
4. After user confirmation ("yes" / "adelante" / etc.), write the JSON silently to `.agentbloc/graph/business-graph.json`. Create the `.agentbloc/graph/` directory if it does not exist.
```
**Rule:** YAML is NEVER shown. User reviews a rendered markdown table only. Artifact written silently.

---

### Artifact placement under `.agentbloc/` hierarchy (Phase 8 D-15 + PDF, inherited)

**Source:** `.claude/skills/agentbloc/references/business-graph-schema.md` line 108 (`.agentbloc/graph/business-graph.json`) + `.claude/skills/agentbloc/references/agent-profile-schema.md` line 148 (`.agentbloc/team/agent-profiles.yaml`)

**Apply to:** All Phase 10 artifacts:
- `.agentbloc/integrations/integration-manifest.yaml` (primary output, written silently)
- `.agentbloc/integrations/<tool-id>/VERIFICATION-FAILED.md` (D-35 halt-and-name artifact)
- `.mcp/generated/<tool-id>/` (wrapper output; separate hierarchy because it's executable code, not AgentBloc state)

**Rule:** `.agentbloc/` = AgentBloc-owned state + artifacts. `.mcp/` = Claude-Code-owned MCP server workspace. Directories auto-created on first write.

---

### Bounded enum for discriminated unions (Phase 8 D-18, inherited)

**Source:** `.claude/skills/agentbloc/references/business-graph-schema.md` lines 67-77 (Trigger Bounded Enum)

**Apply to:** `integration-manifest-schema.md` three bounded-enum sections (Resolution Method / Trust Tier / Status) AND `mcp-integration-protocol.md` resolution_method table.

**Excerpt:**
```markdown
| Enum Value | Definition | Required Sub-fields | Example |
|-----------|-----------|---------------------|---------|
| `cron` | Time-based recurring trigger | `schedule` (cron string) | `{"type":"cron","schedule":"0 9 * * 1"}` |
| `event` | External-event-driven trigger | `source` (service name) + `name` (event id) | `{"type":"event","source":"gmail","name":"new_message"}` |
```
**Rule:** Four-column table: Enum Value / Definition / Required Sub-fields / Example. Any value outside the enum forces a clarification question before emission.

---

### Three-tier field obligation (Phase 9 D-22, inherited)

**Source:** `.claude/skills/agentbloc/references/agent-profile-schema.md` lines 68-74 (Field Obligation Matrix)

**Apply to:** `integration-manifest-schema.md` Field Obligation Matrix.

**Excerpt:**
```markdown
| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED | `schema_version`, `team.name`, `team.topology`, `agents[]` (>=1), ... | Designer refuses to emit. Main session re-prompts user through targeted follow-up. |
| RECOMMENDED | `backstory`, `outputs[]`, `escalation`, ... | Designer emits with warnings. Phase 12 Deploy Pipeline operates with degraded output and flags gaps in DEPLOY-REPORT.md. |
| OPTIONAL | `team.modified_at`, `team.briefing_agent_id`, ... | Silent defaults. Phase 12 proceeds without comment. |
```
**Rule:** Three tiers only. REQUIRED blocks emission. RECOMMENDED emits with warning. OPTIONAL silent default.

---

### Scoped-tools, no-Bash subagent/skill posture (Phase 9 D-21, inherited)

**Source:** `.claude/agents/designer-agent.md` lines 1-7 (frontmatter) + lines 39-48 (`<write_constraint>`)

**Apply to:** `mcp-builder/SKILL.md` frontmatter (Read + Grep + Glob + Write + WebFetch) + `<write_constraint>` block (writes only to `.mcp/generated/<tool-id>/`).

**Excerpt (frontmatter):**
```markdown
---
name: designer-agent
description: Consumes the Business Graph JSON at .agentbloc/graph/business-graph.json...
tools: Read, Grep, Glob, Write
color: purple
context: fork
---
```

**Excerpt (write_constraint):**
```markdown
<write_constraint>
You MUST only write to the following paths:

- `.agentbloc/team/agent-profiles.yaml` (primary output)
- `.agentbloc/team/team-topology.md` (optional Mermaid diagram companion; emit if useful for downstream Phase 12)

Create the `.agentbloc/team/` directory if it does not exist.

You MUST NOT modify any source files under `.claude/skills/` or `.planning/`. You have no Bash access; you cannot run shell commands, install packages, or execute the generated YAML. Use the Write tool exclusively for file creation. No heredoc writes, no `cat << EOF` patterns.
</write_constraint>
```
**Rule:** No Bash ever. Scoped writes only. Explicit `<write_constraint>` XML section with allowed paths enumerated.

---

### Surgical edits to existing references (Phase 9 D-29, inherited)

**Source:** Git commits `3b312ba` (phase-2-design.md, 2026-04-21) + `783b538` (SKILL.md, 2026-04-21)

**Apply to:** `phase-3-integration.md` D-40 edits + `SKILL.md` D-41 edits.

**Rule:** Additive, not replacive. New H2 section (`## Step 8: ...`) added before closing Gate section. Load-list bullets appended. Quick Reference table rows appended. Line-count delta stays under +15 lines per file per edit round. SKILL.md total stays under 250 lines (v1.0 cap).

---

## No Analog Found

None. All seven files have strong intra-repo analogs. `mcp-builder/SKILL.md` is the only file that lacks a **top-level skill** analog inside this repo (no other top-level skill exists under `.claude/skills/` besides `agentbloc/`), but the combination of `agentbloc/SKILL.md` (frontmatter shape) and `designer-agent.md` (scoped-tool + no-Bash posture) covers the shape comprehensively — no external stack reference needed.

---

## Metadata

**Analog search scope:**
- `.claude/skills/agentbloc/references/` (23 files, full inventory)
- `.claude/skills/agentbloc/examples/` (5 files)
- `.claude/agents/` (designer-agent.md)
- `.claude/skills/agentbloc/SKILL.md`
- Git history: commits `3b312ba`, `783b538` (Phase 9 surgical-edit precedents)

**Files scanned:** 9 directly read + 3 cross-referenced via commit diff

**Pattern extraction date:** 2026-04-21

---

## PATTERN MAPPING COMPLETE

**Phase:** 10 - Integration Discovery — MCP Path
**Files classified:** 7 (5 new + 2 modified)
**Analogs found:** 7 / 7

### Coverage
- Files with exact analog: 6
- Files with role-match analog: 1 (`mcp-builder/SKILL.md` — dual analog covers the shape)
- Files with no analog: 0

### Key Patterns Identified
- All three new references share the H1 + blockquote loading note + TOC + "When This Applies" + bounded-enum table + Validation Checklist (prose) + Emission Protocol + Re-run Behavior + Quick Reference spine established in Phase 8/9
- `mcp-builder/SKILL.md` combines AgentBloc's SKILL.md frontmatter shape (name / version / description / allowed-tools) with designer-agent.md's scoped-tools + `<write_constraint>` + `<output_contract>` posture — critically, no Bash
- Surgical edits to `phase-3-integration.md` and `SKILL.md` follow the exact Phase 9 D-29 pattern demonstrated by git commits 3b312ba + 783b538: additive load-list extensions + new H2 sections + precondition insertions, no rewrites, staying under the 250-line SKILL.md cap

### File Created
`/Users/pablodelarco/agentbloc/.planning/phases/10-integration-discovery-mcp-path/10-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files for the 3 projected plans (10-01 contracts, 10-02 mcp-builder skill, 10-03 wiring).
