# Phase 9: Designer Agent - Discussion Log

> **Audit trail only.** Decisions live in `09-CONTEXT.md`.

**Date:** 2026-04-21
**Mode:** Autonomous (per `autonomous_mode` memo). No AskUserQuestion calls. Decisions derived from PDF + REQUIREMENTS + inherited Phase 8/v1.0 decisions.

**Gray areas analyzed:** subagent structure · YAML schema tiering · topology selection heuristics · orchestration pattern classification · process→role grouping · profile editing flow · new reference file placement · SKILL.md gate extension · canonical fixture scope

---

## Subagent structure and contract (D-21)

| Option | Description | Selected |
|--------|-------------|----------|
| Subagent with `context: fork` + scoped tools (Read/Grep/Glob/Write-restricted) | DSGN-01 explicit requirement; fork isolates generation from interview noise | ✓ |
| Subagent with default context (inherit main session) | Pollutes Designer with tangential user conversation | |
| Main-session orchestration (no subagent) | Couples Designer to interview context permanently; no reuse | |

---

## Output YAML schema tiering (D-22)

| Option | Description | Selected |
|--------|-------------|----------|
| Flat strict (all fields required) | Designer refuses on any missing field; brittle against ambiguous Business Graphs | |
| Three-tier (REQUIRED / RECOMMENDED / OPTIONAL) mirroring Phase 8 D-12 | Strict where deploy pipeline breaks; forgiving where it can degrade | ✓ |
| Flat forgiving (all fields optional) | Deploy pipeline has to synthesize too much; quality ceiling too low | |

---

## Topology selection (D-23; resolves STATE.md carry-forward)

| Option | Description | Selected |
|--------|-------------|----------|
| Decision table in `orchestration-patterns.md` + LLM judgment at boundaries | Deterministic starting point + preserves v1.0 D-07 human-override pattern | ✓ |
| LLM judgment only (no table) | Inconsistent choices across runs; harder to test | |
| Exhaustive rule engine (every edge case codified) | Overengineered for 4 topologies | |

**Default when ambiguous:** mesh. Most flexible, matches ClaudeClaw `SendMessage`, degrades naturally.

---

## Orchestration pattern classification (D-24; ORCH-01/02)

| Option | Description | Selected |
|--------|-------------|----------|
| 5-pattern table (Sequential / Parallel / Loop / Event-driven / Conversational) from PDF normalized to ADK vocabulary | Covers 95% of SMB workflows; simplest mapping to Google ADK primitives | ✓ |
| PDF's verbatim 5 patterns (Graph / Negotiation / Role-delegation / Handoff / Bus) | Verbose; Role-delegation and Handoff overlap significantly with Sequential | |
| 2-pattern minimum (Sequential / Event-driven) | Too thin; loses Parallel and Loop cases that exist in Arco Rooms | |

Designer cites the table in a `orchestration.workflows[].why` field.

---

## Process → role grouping (D-25; DSGN-05)

| Option | Description | Selected |
|--------|-------------|----------|
| LLM judgment + 3 guardrail heuristics (tool overlap ≥50% / same trigger+cadence / natural job-title fit) with split-first bias | Deterministic enough to explain; flexible enough for edge cases | ✓ |
| Hardcoded rules only | Can't handle "Gestor Documental" (tools don't overlap but job title does) | |
| Pure LLM judgment | Inconsistent; no rationale explanation for the user | |

---

## Profile editing flow (D-26; DSGN-07)

| Option | Description | Selected |
|--------|-------------|----------|
| Conversational surgical patches (parse intent → apply patch in-place → re-render table) | Preserves user edits; never "helpfully" re-adds rejected agents | ✓ |
| Regenerate-from-scratch on every edit | Fights user intent; re-inserts anticipated/renamed agents | |
| Direct YAML editing by user | Hostile to non-technical audience (primary user per PROJECT.md) | |

---

## New reference file: `orchestration-patterns.md` (D-27; ORCH-02)

| Option | Description | Selected |
|--------|-------------|----------|
| New file at `.claude/skills/agentbloc/references/orchestration-patterns.md` | ORCH-02 explicitly requires this path; structural twin of existing `frameworks.md` | ✓ |
| Embedded inside `designer-agent.md` subagent prompt | Not discoverable by other phases; hurts reuse | |
| Inside `phase-2-design.md` extension | Makes phase-2-design.md bloat past 400 lines; harder to maintain | |

---

## New reference file: `agent-profile-schema.md` (D-28)

| Option | Description | Selected |
|--------|-------------|----------|
| New file structurally twinned with `business-graph-schema.md` (schema + tiers + enums + prose checklist) | Consistency = maintenance win; Phase 8's schema pattern is already proven | ✓ |
| Schema inline in `phase-2-design.md` | Pollutes the design protocol with implementation detail | |
| External JSON Schema file | Breaks D-13 (no external tooling in AgentBloc skill); forces yaml→json bridge | |

---

## SKILL.md Phase 2 extension (D-29)

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror Phase 8 SKILL.md extension — 3 surgical edits (gate vocabulary add, Phase 2 Summary wiring, Phase 3 precondition) | Consistent ritual; minimal net line addition keeps SKILL.md ≤250 | ✓ |
| New Phase 2.5 section in SKILL.md | Breaks 6-phase brand (Phase 8 D-21 inheritance) | |
| No SKILL.md changes — Designer invocation only in `phase-2-design.md` | Gate enforcement becomes prose-only; loses the `[AGENTBLOC \| PHASE: N \| GATE: X]` ritual leverage | |

---

## Canonical test fixture (D-30)

| Option | Description | Selected |
|--------|-------------|----------|
| 3 requested agents only (Gestor Cobros / Recepcionista / Gestor Documental) per PDF | Matches Phase 9 scope (anticipation is Phase 15); clean verification | ✓ |
| Full 5-agent team including anticipated (+ Analista Rentabilidad, Gestor Incidencias) | Leaks Phase 15 scope into Phase 9; muddles verification boundary | |
| Empty fixture, add in Phase 15 | Phase 9 verification has no input to check Designer against | |

---

## Claude's Discretion

- Designer subagent prompt wording beyond the required role/goal/scoped tools
- ASCII diagram style (match v1.0 convention)
- Table rendering format for confirmation turn
- Pattern ordering in the 5-pattern table (optimize Designer's "first option it sees fits" bias)
- Ambiguous-graph fallback (suggest ONE clarifying question before emitting)
- Whether `team-topology.md` (Mermaid) emits alongside YAML (lean: yes, cheap and useful)

## Deferred Ideas

- Topology auto-upgrade as team grows (mesh → hierarchy at N agents) → v2.5
- Per-agent model recommendation as RECOMMENDED tier → v2.5 with usage data
- Multi-language YAMLs (bilingual EN/ES fields) → future milestone
- Designer CLI (`agentbloc design`) → out of scope (PROJECT.md: conversational only)
- Visual YAML editor → out of scope
- Runtime contract tests → Phase 16 validation run

## Scope Creep Redirected

- Anticipation pass (unrequested agents) → Phase 15 (ANTIC-01..05)
- Integration Discovery for each agent's tools → Phase 10/11 (INTEG / BROWSER)
- Deploy Pipeline materialization → Phase 12 (DEPLOY-01..08)
- Agent memory bootstrap → Phase 12 (MEM-01..06)
- Runtime trigger wiring → Phase 13 (RUNTIME-01..07)

---

*All autonomous decisions open to Pablo's veto before Phase 10 discuss begins.*
