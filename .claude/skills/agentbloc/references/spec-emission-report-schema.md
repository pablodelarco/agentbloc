# Spec Emission Report Schema

> Dual-artifact contract for Phase 5 Step 6 emission. SPEC-EMISSION-
> REPORT.md is the happy-path summary; SPEC-EMISSION-FAILED-REPORT.md
> is the halt-and-name twin emitted instead on any hard-fail. Both
> live at the spec folder root.

## Table of Contents

- [When This Applies](#when-this-applies)
- [SPEC-EMISSION-REPORT.md Schema](#spec-emission-reportmd-schema)
- [SPEC-EMISSION-FAILED-REPORT.md Schema](#spec-emission-failed-reportmd-schema)
- [Bounded Enums](#bounded-enums)
- [Validation Checklist](#validation-checklist)
- [Cross-References](#cross-references)

## When This Applies

The `spec-engine` subagent loads this file in its forked context on
invocation, NOT at Phase 5 entry (context-budget discipline). This file
defines the dual emission contract: exactly ONE of SPEC-EMISSION-REPORT.md
(happy path) or SPEC-EMISSION-FAILED-REPORT.md (halt) is written per
emission run.

Downstream consumers:
- [spec-emission-protocol.md](spec-emission-protocol.md) Step 6
  (emission trigger)
- SKILL.md (reads `verification_status` to decide if sub-gate
  `spec_folder_emitted` is true)
- Phase 6 Spec Evolution (reads input snapshot SHA256s to detect drift
  between emissions)
- Operator humans (read after every emission to understand what
  shipped)

## SPEC-EMISSION-REPORT.md Schema

```yaml
---
agentbloc_version: "1.0.0"
emitted_at: "<ISO-8601 UTC timestamp>"
destination: "<absolute path>"
team_name: "<from agent-profiles.yaml team.name>"
verification_status: success
revision: 1                           # bumped on Phase 6 re-emission
---

# Spec Emission Report — <team name>

## Summary

<one-paragraph human-readable: N agents, M workflows, K integrations
ranked across the 5 tiers, total effort estimate>

## Input Snapshots

| Artifact | SHA256 | Path |
|---|---|---|
| business-graph.json | <64-hex> | .agentbloc/graph/business-graph.json |
| agent-profiles.yaml | <64-hex> | .agentbloc/team/agent-profiles.yaml |
| inventory.yaml      | <64-hex> | .agentbloc/integrations/inventory.yaml |

## Files Emitted

<flat tree of every file written, with byte counts>

```text
README.md                    1234 bytes
AGENTS.md                    2456 bytes
CLAUDE.md                    3781 bytes
ROADMAP.md                   4123 bytes
workflows/01-lead-capture.md 1899 bytes
agents/lead-capture/role.md  ...
...
```

## Tier Breakdown

| Tier | Count | Tools |
|---|---|---|
| EXISTS-MCP | N | telegram, gmail, sheets, ... |
| NEEDS-MCP-WRAPPER | N | notion, stripe, ... |
| NEEDS-N8N-FLOW | N | lead-enrichment-flow |
| NEEDS-WEBHOOK | N | shopify-order-webhook |
| MANUAL | N | notarized-signing |
| **Total** | **N** | |

## Effort Estimate

| Phase | Effort (CC-hours) | Effort (human-days) |
|---|---|---|
| Build integrations | N | M |
| Wire workflows     | N | M |
| Build runtime      | N | M |
| Test + ship        | N | M |
| **Total**          | **N** | **M** |

## Revision History

### Revision 1 — <ISO timestamp>

Initial emission.

<!-- Phase 6 spec evolution appends new sections here -->

## Hand-off

The spec folder is build-ready. Open a Claude Code (or Codex / Gemini /
Cursor / OpenClaw) session in `<destination>` and follow ROADMAP.md.

For Claude Code specifically: the session reads CLAUDE.md as project
context and ROADMAP.md as the task plan.

For other AI coding tools: the session reads AGENTS.md as universal
context and ROADMAP.md as the task plan.

## Provenance

Emitted by AgentBloc spec-engine subagent (.claude/agents/spec-engine.md).
Phase 5 sub-gate `spec_folder_emitted` is now closed. SKILL.md may
advance to Phase 6.
```

## SPEC-EMISSION-FAILED-REPORT.md Schema

```yaml
---
agentbloc_version: "1.0.0"
failed_at: "<ISO-8601 UTC timestamp>"
destination: "<absolute path>"
team_name: "<from agent-profiles.yaml team.name OR 'unknown' if Step 1 failed>"
verification_status: failed
step_number: 1                        # 1-6, which step failed
halt_reason: <one of the bounded enum values>
---

# Spec Emission Failed — <team name>

## Failure Reason

<plain-English root cause; not a stack trace; describes WHAT failed
in human terms>

## Step <N> Context

<what the subagent was attempting at the step that failed; what
preconditions were checked; what specifically tripped>

## Suggested Resolution

<how the user can fix and re-run; e.g., "fix agent-profiles.yaml
line 47: trigger.schedule is empty for agent 'lead-capture'", or
"re-run /agentbloc and revisit Phase 3 because tool 'notion' has no
tier assignment">

## Partial Output

<list of files that WERE successfully written before failure; the
user can inspect them but should NOT consider the spec folder valid>

```text
README.md                    1234 bytes  WRITTEN
AGENTS.md                    2456 bytes  WRITTEN
CLAUDE.md                    3781 bytes  WRITTEN
ROADMAP.md                   ----        NOT WRITTEN — failure here
workflows/                   ----        NOT WRITTEN
...
```

## Provenance

Emitted by AgentBloc spec-engine subagent. Phase 5 sub-gate
`spec_folder_emitted` is FALSE. SKILL.md halts Phase 6 entry and
surfaces this report for user resolution.
```

## Bounded Enums

### `verification_status`

| Value | Meaning |
|---|---|
| `success` | All 6 protocol steps completed; spec folder is build-ready |
| `failed` | A protocol step failed; partial output may exist |

### `halt_reason` (failure path only)

| Value | Step | Common cause |
|---|---|---|
| `input_missing` | 1 | One of the three input artifacts is absent |
| `input_invalid` | 1 | An input artifact failed schema validation |
| `destination_exists` | 1 | Destination is non-empty and `--overwrite` was not passed |
| `template_missing` | 2 | A required template file is absent in the skill's templates/ |
| `cross_reference_orphan` | 3 | A workflow's agent doesn't exist, or an agent's tool isn't in inventory |
| `tier_unknown` | 4 | An inventory tool has no tier assignment (Phase 3 incomplete) |
| `evidence_missing` | 4 | An inventory tier assignment has no evidence URL |
| `governance_stub` | 5 | A governance file would be empty (security gap) |
| `runtime_copy_failed` | 5 | reference-impl copy failed (filesystem error) |
| `report_write_failed` | 6 | Could not write the report itself (filesystem error) |

## Validation Checklist

Before writing SPEC-EMISSION-REPORT.md (success path), the subagent
verifies:

- [ ] All required files in [spec-folder-structure.md](spec-folder-structure.md) are present
- [ ] No conditional file is present without its precondition (e.g.,
      `needs-webhook/` only exists if at least one tool is tier-4)
- [ ] Cross-references resolve: every workflow's agents exist; every
      agent's tools exist in inventory
- [ ] `runtime/reference-impl/` has all 12+ cherry-picked files
- [ ] Input SHA256s computed and embedded
- [ ] Tier breakdown table totals match `inventory.yaml` length
- [ ] Effort estimate is non-zero

If any check fails, write SPEC-EMISSION-FAILED-REPORT.md instead with
the appropriate `halt_reason`.

## Cross-References

- [spec-emission-protocol.md](spec-emission-protocol.md) — the 6-step protocol
- [spec-folder-structure.md](spec-folder-structure.md) — what gets validated
- [phase-5-spec-emission.md](phase-5-spec-emission.md) — phase orchestration
- [.claude/agents/spec-engine.md](../../../agents/spec-engine.md) — the subagent
