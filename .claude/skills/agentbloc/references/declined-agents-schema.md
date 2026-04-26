# Declined Agents Schema

> Schema reference for `.agentbloc/graph/declined.json`. ANTIC-04 source-of-truth. Designer subagent reads this file at invocation start to filter anticipation-heuristics.md proposals before emitting the agent-profiles.yaml team. Subagent-only reference (not cited from SKILL.md per D-58 context-budget).

## Table of Contents

- [When This Applies](#when-this-applies)
- [Schema Definition](#schema-definition)
- [Field Obligation Matrix](#field-obligation-matrix)
- [Append-Only Discipline](#append-only-discipline)
- [Designer Integration Protocol](#designer-integration-protocol)
- [Re-introduction Behavior](#re-introduction-behavior)
- [Why Business-Level (not Team-Level)](#why-business-level-not-team-level)

## When This Applies

Designer Agent reads `.agentbloc/graph/declined.json` after the 5 mandatory schema reads (per `<anticipation_pass>` block in [`.claude/agents/designer-agent.md`](../../../agents/designer-agent.md)). Any anticipated agent proposed by [`anticipation-heuristics.md`](anticipation-heuristics.md) whose `agent_id` matches an entry in this file with the same `business_type` is filtered out before the rendered TABLE returns to the main session. If the file does not exist, Designer treats the decline set as empty and proceeds.

## Schema Definition

```json
[
  {
    "agent_id": "string",
    "business_type": "string",
    "declined_at": "ISO-8601 timestamp",
    "reason": "string | null",
    "correlation_id": "string"
  }
]
```

Top-level is a JSON array. Each entry is a 5-field object. The file is plain JSON (not JSONL) because it is read once at Designer invocation start, not append-streamed during agent execution. See [`examples/arco-rooms-declined.json`](../examples/arco-rooms-declined.json) for a working fixture.

## Field Obligation Matrix

| Field | Tier | Description |
|---|---|---|
| `agent_id` | REQUIRED | kebab-case ID matching the `id` of an anticipation-heuristics.md proposed agent (e.g., `gestor-incidencias`, `analista-rentabilidad`) |
| `business_type` | REQUIRED | Business Graph `business.type` value at decline time (e.g., `rental-property-management`); used to scope the decline so the same agent name in a different business shape is not pre-filtered |
| `declined_at` | REQUIRED | ISO-8601 UTC timestamp of decline (e.g., `2026-04-26T18:30:00Z`) |
| `reason` | RECOMMENDED | 1-line free-text rationale; not user-facing in v2.0 (for the user's own future reference when they wonder why a particular agent was filtered) |
| `correlation_id` | REQUIRED | Designer invocation correlation ID per Phase 13 D-75 format (`<source>-<UTC-Z-compact>-<nonce6>`); enables tracing the decline back to a specific Designer run |

## Append-Only Discipline

Per Phase 14 D-87 trace-integrity pattern. New declines append to the JSON array. Designer NEVER auto-removes entries. The user can manually edit the file to UN-decline (delete entries) if they change their mind; the file is plain JSON to make that easy.

## Designer Integration Protocol

Designer's `<anticipation_pass>` block (in `.claude/agents/designer-agent.md`) executes this protocol:

1. **Read declined.json:** Use the Read tool to load `.agentbloc/graph/declined.json` if it exists. If the file does not exist, treat the decline set as empty and proceed without filtering.
2. **Look up business.type:** Read `business.type` from the Business Graph (already loaded as part of the 5 mandatory schema reads).
3. **Query heuristics map:** Locate the matching H2 section in [`anticipation-heuristics.md`](anticipation-heuristics.md). If `business.type` is not in the map, skip the anticipation pass entirely (degrade silently per ANTIC).
4. **Filter declined:** For each anticipated agent the heuristics-map mapping proposes, check whether an entry exists in declined.json with both `agent_id` matching AND `business_type` matching the current `business.type`. Matching pairs are filtered out before rendering.
5. **Append on user decline:** When the user declines an anticipated agent during the Phase 2 review (e.g., "drop the incident tracker"), the main session passes a structured decline patch to Designer. Designer:
   1. Appends a new entry to declined.json (creating the file if absent) with the 5 fields above + the current Designer invocation correlation_id.
   2. Removes the agent from `agents[]` in agent-profiles.yaml per the conversational-edit surgical-patch protocol (D-26).
   3. Bumps `team.modified_at` and re-validates the YAML.
   4. Returns the updated rendered TABLE (now without the declined agent's row).

## Re-introduction Behavior

If the user later changes their mind ("actually add the incident tracker after all"), two paths work:

- **Manual edit:** the user removes the entry from declined.json directly, then re-runs Designer (which will re-propose from the heuristics map and emit the agent with `anticipated: true` + rationale + sources from the map).
- **Conversational add:** the user says "add an incident tracker" and Designer adds the agent directly via the conversational-edit add-agent path. The added agent emits with `anticipated: false` because the user added it explicitly (not via the heuristics map). This bypasses the heuristics-map filter; the declined.json entry remains for future Designer runs but does not block this manual addition.

## Why Business-Level (not Team-Level)

The decline file lives at `.agentbloc/graph/declined.json` (sibling to business-graph.json), not under `.agentbloc/team/`. The decline is a fact about the BUSINESS's preferences, not a fact about a specific TEAM instance. If the user regenerates the team via the Re-run Behavior overwrite path in [`agent-profile-schema.md`](agent-profile-schema.md), the decline persists , Designer respects it on the regenerated team. Re-running Designer against the same Business Graph months later (e.g., post v2.5 capability scan) honors the decline.

The schema is intentionally simple. v2.0 ships read-mostly behavior; v2.5 may add a CLI command for declined-management. v2.0 user paths are: manual file edit, conversational decline (auto-append), or team regeneration (decline survives).
