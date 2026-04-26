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

Designer Agent reads this file inside its forked context to produce the canonical `agent-profiles.yaml` at `.agentbloc/team/agent-profiles.yaml`. The schema defines what MUST, SHOULD, and MAY appear in the YAML. The Validation Checklist below is a deterministic list of pass/fail checks Designer walks before writing the file; failures surface as targeted follow-up questions through the main session's conversation. Downstream consumers - Phase 12 Deploy Pipeline (agent skills generation), Phase 13 Runtime (trigger wiring), Phase 14 Briefing Agent (team awareness), Phase 15 Anticipation (additive updates) - all read this artifact. The `triggers[].type` enum extends the Business Graph trigger enum in [business-graph-schema.md](business-graph-schema.md) with `inter-agent` for peer calls. Blast-radius scoring per agent follows the rules in [blast-radius.md](blast-radius.md).

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
  - id: "string"                               # REQUIRED. kebab-case, unique within file.
    role: "string"                             # REQUIRED. CrewAI-shaped. e.g. "Invoice Collection Specialist"
    goal: "string"                             # REQUIRED. Scoped outcome this agent owns.
    backstory: "string | null"                 # RECOMMENDED. CrewAI narrative identity.
    tools:                                     # REQUIRED. Length >= 1.
      - "string"                               # MCP reference or tool name.
    triggers:                                  # REQUIRED. Length >= 1.
      - type: "cron | event | manual | inter-agent"   # See Trigger Bounded Enum.
        # cron:        schedule: "<cron string>"
        # event:       source + name
        # manual:      description
        # inter-agent: caller + message
    autonomy: "full | semi | supervised"       # REQUIRED. See Autonomy Bounded Enum.
    outputs:                                   # RECOMMENDED.
      - type: "string"                         # e.g. "state-file", "telegram-message", "email"
        schema: "string | null"                # Mastra-style schema reference if applicable.
    escalation: "string | null"                # RECOMMENDED. e.g. "telegram:pablo"
    dependencies:                              # RECOMMENDED.
      - "<other-agent-id>"                     # Must resolve to agents[] (ORCH-04).
    blast_radius: 1 | 2 | 3 | 4                # REQUIRED. Auto-scored per blast-radius.md.
    model: "opus | sonnet | haiku | null"      # OPTIONAL. Per-agent model hint.
    anticipated: false                         # OPTIONAL. Default false. True when proposed by Phase 15 anticipation pass per D-99.
    anticipation_rationale: "string | null"    # OPTIONAL. 1-2 sentence narrative. Required (WARN-tier Check 9) when anticipated: true.
    anticipation_sources:                      # OPTIONAL. Array of URLs from anticipation-heuristics.md mapping. Min length 3 (WARN-tier) when anticipated: true.
      - "string"

orchestration:
  workflows:                                   # REQUIRED. Length >= 1.
    - id: "string"                             # REQUIRED. e.g. "cobro-diario"
      type: "sequential | parallel | loop | event-driven | conversational"  # REQUIRED.
      agents: ["<agent-id>", ...]              # REQUIRED. Length >= 1. All IDs must resolve (ORCH-04).
      trigger:                                 # REQUIRED. Same shape as agents[].triggers[].
        type: "cron | event | manual"
      why: "string"                            # RECOMMENDED. Citation of orchestration-patterns.md.
      steps: ["string", ...]                   # OPTIONAL. Used by sequential / loop.
      flow: "string | null"                    # OPTIONAL. Used by event-driven (free-text narrative).
```

## Field Obligation Matrix

| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED | `schema_version`, `team.name`, `team.topology`, `agents[]` (>=1), per-agent `id` + `role` + `goal` + `tools[]` (>=1) + `triggers[]` (>=1) + `autonomy` + `blast_radius`, `orchestration.workflows[]` (>=1) with `type` + `agents[]` (>=1) + `trigger` | Designer refuses to emit. Main session re-prompts user through targeted follow-up. |
| RECOMMENDED | `backstory`, `outputs[]`, `escalation`, `dependencies[]`, `team.topology_rationale`, `workflows[].why` | Designer emits with warnings. Phase 12 Deploy Pipeline operates with degraded output and flags gaps in DEPLOY-REPORT.md. |
| OPTIONAL | `team.modified_at`, `team.briefing_agent_id`, `model`, `workflows[].steps`, `workflows[].flow` | Silent defaults. Phase 12 proceeds without comment. |
| OPTIONAL | `anticipated`, `anticipation_rationale`, `anticipation_sources[]` | Designer emits anticipated agents per Phase 15 D-99; existing consumers (Phase 12 deploy-engine, Phase 14 briefing-agent) ignore (backward-compatible per D-101). |

Downstream consumers refuse to proceed on an unknown major `schema_version`, the same rule as business-graph-schema.md.

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
| `event` | External-event-driven trigger | `source` (service) + `name` (event id) | `{type: event, source: gmail, name: new_message}` |
| `manual` | Human-initiated trigger | `description` (free text) | `{type: manual, description: "Operator runs on demand"}` |
| `inter-agent` | Peer-call from another agent via SendMessage | `caller` (agent-id) + `message` (contract) | `{type: inter-agent, caller: recepcionista, message: "payment-status-query"}` |

Any value outside this enum forces a clarification question before emission.

## Topology Bounded Enum

The `team.topology` field is drawn from a fixed set. Full signal rationale and decision table live in [orchestration-patterns.md](orchestration-patterns.md) Topology Decision Table.

| Enum Value | Signal from Business Graph | Default Use | Cross-Reference |
|-----------|---------------------------|-------------|-----------------|
| `pipeline` | Linear ordered process with handoffs | 1-3 agents, sequential flow | orchestration-patterns.md |
| `mesh` | Peer-calling agents (default on ambiguity) | 3-8 agents, mutual SendMessage | orchestration-patterns.md |
| `hierarchy` | One lead orchestrates workers | 5-15 agents, briefing-agent root | orchestration-patterns.md |
| `swarm` | N independent parallel agents | Rare; multi-tenant watchdogs | orchestration-patterns.md |

Default on ambiguity: `mesh`.

## Validation Checklist

Designer walks this ordered list before writing `.agentbloc/team/agent-profiles.yaml`. Any FAIL blocks emission; Designer re-prompts the main session with the targeted follow-up text. REQUIRED-tier checks (1-7) block emission; RECOMMENDED check (8) emits with warnings.

**Check 1: `schema_version` present and equals current version (`1`)**
- FAIL: Set `schema_version: 1` automatically; no follow-up needed.

**Check 2: `team.name` non-empty string AND `team.topology` in {pipeline, mesh, hierarchy, swarm}**
- FAIL: Pick topology via [orchestration-patterns.md](orchestration-patterns.md) Topology Decision Table; default to `mesh` on ambiguity.

**Check 3: `agents[]` length >= 1**
- FAIL: Impossible from a valid Business Graph (processes[] >= 1). If triggered, re-read the Business Graph.

**Check 4: Every agent has unique `id`, non-empty `role`, non-empty `goal`, `tools[]` (>=1), `triggers[]` (>=1), `autonomy` in {full, semi, supervised}, `blast_radius` in {1,2,3,4}**
- FAIL: For each gap, surface the specific agent and field to the main session with a targeted question.

**Check 5: Every `triggers[].type` in {cron, event, manual, inter-agent} with required sub-field per Trigger Bounded Enum**
- FAIL: Ask "What triggers <agent-id>, a schedule, external event, human action, or another agent?" before emission.

**Check 6: `orchestration.workflows[]` length >= 1, every workflow has `type` in the 5-pattern enum, `agents[]` (>=1), and a `trigger`**
- FAIL: Classify via [orchestration-patterns.md](orchestration-patterns.md) 5-pattern table; default to `event-driven` on ambiguity.

**Check 7: Every `workflows[].agents[]` id AND every `agents[].dependencies[]` id resolves to an entry in `agents[]` (ORCH-04)**
- FAIL: Reject the YAML; log the unresolved id; re-read Business Graph for correct mapping.

**Check 8 (WARN, not FAIL): RECOMMENDED fields populated or explicitly marked `null`**
- WARN: Emit with nulls; flag gaps in the rendered table so user can accept or fix.

**Check 9 (WARN, not FAIL): For every agent with `anticipated: true`, both `anticipation_rationale` non-null AND `anticipation_sources` array length >= 3**
- WARN: Emit with the gap; flag in the rendered table as `ANTICIPATED (rationale missing)` or `ANTICIPATED (only N sources, need 3)` so user can ask Designer to fill the gap.
- Designer auto-emitting from [anticipation-heuristics.md](anticipation-heuristics.md) ALWAYS populates rationale + 3 sources (the map is the source of truth). The WARN tier covers conversational-edit additions where the user supplies a partial agent.

## Emission Protocol

Emission happens when the main session's Phase 2 Design Summary gate spawns the Designer Agent subagent (D-21). The steps:

1. Designer walks the Validation Checklist above in order.
2. For each REQUIRED failure (Checks 1-7), Designer returns a targeted follow-up to the main session and waits for the user's answer before resuming.
3. Once all REQUIRED checks pass, Designer writes the validated YAML silently to `.agentbloc/team/agent-profiles.yaml`. Create the `.agentbloc/team/` directory if it does not exist.
4. Designer returns a rendered TABLE + per-agent cards + ASCII topology diagram to the main session (per v1.0 D-05 and D-06). The YAML itself is NEVER shown to the user.
5. The main session presents the table / cards / diagram to the user and asks for confirmation.
6. After user confirmation, the main session sets the Phase 2 `agent_profiles_validated` sub-gate to `approved` and allows transition to Phase 3.

If the user edits any table, follow the Re-run Behavior below.

## Re-run Behavior

If `.agentbloc/team/agent-profiles.yaml` already exists when the Summary gate is reached, the main session asks the user: "I already have an agent team on file for this project. Do you want to (a) keep the existing one, (b) overwrite it, or (c) apply specific edits to it?" Default is **apply edits** (surgical patch per D-26).

- **keep**: Skip emission, transition to Phase 3 with the existing team.
- **overwrite**: Designer regenerates the YAML from scratch against the Business Graph. Warn the user that previous conversational edits (renames, drops, additions) will be lost.
- **apply edits (default, D-26)**: Designer parses user intent into a structured patch (rename / delete / add-tool / remove-tool / change-autonomy / change-topology / change-blast-radius), applies it in-place to the existing YAML, bumps `team.modified_at`, re-runs the Validation Checklist, and re-renders the TABLE for user confirmation. Designer NEVER regenerates from the Business Graph for edits - regeneration would re-insert rejected or renamed agents, fighting user intent.

The `schema_version` on disk must match the current schema version. If it does not, refuse edit/merge and emit `action_required: schema_version_mismatch` to the conversation so the user knows a manual migration is needed.

## Schema Versioning Rules

The `schema_version` field is an integer. It starts at `1`. The version bumps only on breaking changes:

- A REQUIRED field is removed or renamed.
- An enum value is removed from a bounded type (e.g., dropping `semi` from `autonomy`).

Additive changes do NOT bump the version:

- Adding a new OPTIONAL field (e.g., `model` hint, `anticipated`, `anticipation_rationale`, `anticipation_sources`).
- Adding a new value to a bounded enum (e.g., adding `inter-agent` to triggers).
- Loosening a REQUIRED field to RECOMMENDED.

Downstream consumers (Phase 12 Deploy, Phase 13 Runtime, Phase 14 Briefing Agent, Phase 15 Anticipation) read `schema_version` and refuse to proceed on an unknown major version.

## Anticipation Fields (Phase 15)

When Designer's anticipation pass emits an unrequested-but-needed agent (per Phase 15 D-99), the agent profile carries 3 additional fields:

- `anticipated: true` flags the agent as a Phase 15 proposal (vs. a user-requested agent from the Business Graph processes[])
- `anticipation_rationale` is a 1-2 sentence narrative explaining WHY this agent is suggested (sourced from [anticipation-heuristics.md](anticipation-heuristics.md) per-mapping rationale)
- `anticipation_sources` is an array of >= 3 URLs cited as evidence (sourced from [anticipation-heuristics.md](anticipation-heuristics.md) Evidence sources block)

These fields are OPTIONAL per the Schema Versioning Rules above (additive extension; schema_version unchanged at 1). Existing consumers (Phase 12 deploy-engine, Phase 14 briefing-agent) ignore them; Phase 15 anticipation-aware consumers (Designer's own conversational-edit decline path, Phase 2 rendered TABLE renderer) read them.

User decisions on anticipated agents (accept / decline / defer) are handled in the Phase 2 conversational-edit path; declines append to `.agentbloc/graph/declined.json` per [declined-agents-schema.md](declined-agents-schema.md). The fixture at [`examples/arco-rooms-anticipated-profiles.yaml`](../examples/arco-rooms-anticipated-profiles.yaml) demonstrates a 5-agent team (3 requested + 2 anticipated) for the canonical Arco Rooms case.
