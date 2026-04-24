# Agent Memory Schema

> Canonical contract for .agentbloc/agents/<agent-id>/{memory.md, state.json, last-run.json}. Deploy-engine initializes these three files on every new deploy; runtime (Phase 13) reads and writes them.

## Table of Contents

- [When This Applies](#when-this-applies)
- [memory.md Template (D-64)](#memorymd-template-d-64)
- [state.json Schema (D-65 + D-60 RFC 8785)](#statejson-schema-d-65--d-60-rfc-8785)
- [last-run.json Schema (D-73)](#last-runjson-schema-d-73)
- [Bounded Enum: status](#bounded-enum-status)
- [Timezone Discipline](#timezone-discipline)
- [Validation Checklist](#validation-checklist)
- [Initialization Protocol (Deploy Time)](#initialization-protocol-deploy-time)
- [Runtime Protocol (Phase 13 Read/Write Semantics)](#runtime-protocol-phase-13-readwrite-semantics)
- [Cross-Reference](#cross-reference)
- [Re-run Semantics and Versioning](#re-run-semantics-and-versioning)

## When This Applies

The deploy-engine subagent (`.claude/agents/deploy-engine.md`, Plan 12-02) loads this file in its forked context on invocation, NOT at Phase 5 entry (per D-58 context-budget discipline). This file defines the three-file per-agent runtime contract at `.agentbloc/agents/<agent-id>/`. Downstream consumers: [deploy-protocol.md](deploy-protocol.md) Step 5 atomic write; Phase 13 Multi-Agent Runtime (reads all three files on agent wake, writes state.json + last-run.json on completion); Phase 14 Monitor (parses last-run.json for status rollups); Phase 16 End-to-End Validation (replays against the Arco Rooms fixture).

**Plan 12-01 triple literal override notice (PHASE 12 TRIPLE LITERAL OVERRIDE):** Per-agent memory files ship at `.agentbloc/agents/<agent-id>/{memory.md, state.json, last-run.json}` per D-59b, which overrides the REQUIREMENTS.md MEM-01 literal `.claude/agents/<id>/{memory,state,last-run}`. The `.claude/agents/` namespace is reserved by Claude Code for native subagent definitions (designer-agent.md, browser-discovery.md, deploy-engine.md); mixing customer runtime state with developer tooling is a namespace-hygiene violation. `.agentbloc/discovery/` was established in Phase 11 as the customer-state convention; `.agentbloc/agents/` extends the same pattern. Companion overrides: D-59a moves SKILL.md to `.claude/skills/<agent-id>/SKILL.md`; D-59c moves the registry to `.agentbloc/agents/registry.yaml`.

The unifying architectural principle is the stable-vs-mutable split: SKILL.md contracts are versioned, reviewed, audited (belong in `.claude/skills/`); memory files (this schema's output) are machine-written on every wake (belong in `.agentbloc/`, customer-mutable namespace per Phase 11 precedent). Git history stays clean on SKILL.md because content changes only on explicit re-deploy; memory files change on every wake without polluting the stable contract.

All three files are plaintext (memory.md is Markdown; state.json and last-run.json are JSON). The schema is explicitly human-editable and git-diff-friendly, satisfying MEM-06 "version-controllable + debuggable per v1.0 file-based-state decision".

## memory.md Template (D-64)

Each deployed agent's `memory.md` is NOT freeform markdown. It follows a fixed 4-section template so the agent can navigate deterministically on every wake without token-spending scans:

```markdown
# Agent Memory: <agent-id>

<!-- agentbloc:schema version=1 -->

## Domain Knowledge
<!-- Long-lived facts about the agent's domain: tenants, contracts, account numbers. Agent-editable markdown. -->

## Decisions
<!-- Append-only log of agent decisions with rationale. Format: `- YYYY-MM-DD: decision + rationale`. -->

## Integration Quirks
<!-- Known gotchas, API workarounds, rate-limit observations. -->

## Open Items
<!-- Unresolved questions for operator review. -->
```

The 4 sections cover the real-world categories (static knowledge / history / quirks / pending) per the file-based-state pattern documented in the 5-agent-system-24/7 post cited in PROJECT.md sources.

**Section-addition policy:** sections are RECOMMENDED (schema warns if missing but still emits). OPTIONAL: an agent can add sections beyond the 4 (e.g., `## Glossary`, `## Escalation History`); the schema does not forbid additive H2s. Section removal is forbidden; a deploy-time read that finds any of the 4 required H2 headers missing halts with `halt_reason: yaml-parse-error` citing the specific missing section.

**Initial contents (deploy-time stub):** each section starts with a one-line HTML comment guidance (as shown in the template). The agent adds to sections at wake; the user edits manually when domain knowledge shifts.

## state.json Schema (D-65 + D-60 RFC 8785)

One flat common schema for all agents regardless of role. Role-specific data nests under `working_state` (opaque to the deploy-engine, readable by the agent that owns it).

```json
{
  "schema_version": 1,
  "agent_id": "<agent-id>",
  "team": "<team-name>",
  "last_wake_at": "<ISO-8601 UTC with Z suffix | null>",
  "last_completion_at": "<ISO-8601 UTC with Z suffix | null>",
  "working_state": {},
  "processed_ids": [],
  "locks": [],
  "retries": [],
  "kill_switch_last_checked": "<ISO-8601 UTC with Z suffix | null>",
  "_agentbloc_fingerprint": { "sha256": "<64-hex>", "generated_at": "<ISO-8601 UTC with Z suffix>" }
}
```

Field semantics:

- `schema_version`: integer. Currently `1`. Downstream consumers refuse to proceed on an unknown major version.
- `agent_id`: the slug matching `.claude/skills/<agent-id>/SKILL.md` and `.agentbloc/agents/<agent-id>/`.
- `team`: the team slug matching `registry.yaml` `team.name`.
- `last_wake_at`: ISO-8601 UTC timestamp set by Phase 13 runtime on every wake. Null on first deploy.
- `last_completion_at`: ISO-8601 UTC timestamp set by Phase 13 runtime on task completion. Null on first deploy.
- `working_state`: free-form object namespaced to the agent's role (Gestor Cobros puts `current_month_payments[]`; Recepcionista puts `last_owner_notifications{}`). Opaque to the deploy-engine.
- `processed_ids`: idempotency set for processed invoices / transactions / messages to prevent double-processing. Bootstraps as `[]`.
- `locks`: task lock entries per Phase 14 CTRL-03. Phase 12 bootstraps as `[]`; Phase 14 populates at runtime.
- `retries`: exponential-backoff state for failed external calls. Bootstraps as `[]`.
- `kill_switch_last_checked`: Phase 13 RUNTIME-07 writes this on every wake. Phase 12 bootstraps as `null`.
- `_agentbloc_fingerprint`: D-60 fingerprint block. Stripped before RFC 8785 canonicalization + SHA256 computation.

**RFC 8785 Canonicalization Rules (D-60):** Before SHA256 fingerprint computation, the deploy-engine performs two steps:

1. Strip the `_agentbloc_fingerprint` top-level field.
2. Mask all ISO-8601 timestamp values (`last_wake_at`, `last_completion_at`, `kill_switch_last_checked`, any timestamps inside `retries[]`, and the `generated_at` inside the stripped fingerprint block) to the literal placeholder `<TIMESTAMP>`.
3. Re-serialize per RFC 8785 JSON Canonicalization Scheme (JCS): sorted object keys (lexicographic), UTF-8 encoding with no BOM, shortest-number representation (integers without trailing zeros, floats without scientific notation), no insignificant whitespace between tokens.
4. Compute SHA256 over the canonicalized byte sequence.

Matching hash on re-deploy = skip (no re-write). Differing hash = the state has drifted from the prior deployment; surface via Step 3 of [deploy-protocol.md](deploy-protocol.md) diff flow.

## last-run.json Schema (D-73)

```json
{
  "schema_version": 1,
  "agent_id": "<agent-id>",
  "action": "<action-name>",
  "result": "<result-summary>",
  "timestamp": "<ISO-8601 UTC with Z suffix>",
  "status": "active | idle | error",
  "correlation_id": "<uuid-v4>",
  "_agentbloc_fingerprint": { "sha256": "<64-hex>", "generated_at": "<ISO-8601 UTC with Z suffix>" }
}
```

Field semantics:

- `schema_version`: integer. Currently `1`.
- `agent_id`: the slug matching `state.json` `agent_id`.
- `action`: the action-name string Phase 13 assigns to the tick (e.g., `"collect-invoices"`, `"match-transactions"`, `"send-daily-report"`).
- `result`: one-line result summary. On status `active` this is the in-progress description; on `idle` the prior completion summary; on `error` the truncated exception message (the full error body lives in the audit log, not this file).
- `timestamp`: ISO-8601 UTC set by Phase 13 on every rewrite.
- `status`: one of the three-value bounded enum below.
- `correlation_id`: UUID-v4 that ties this entry to the per-tick audit log line for cross-reference.
- `_agentbloc_fingerprint`: D-60 fingerprint block, same rules as state.json.

**RFC 8785 Canonicalization Rules (D-60):** Identical to state.json. Strip `_agentbloc_fingerprint`, mask `timestamp` and the `generated_at` inside the fingerprint block to `<TIMESTAMP>`, re-serialize per RFC 8785, compute SHA256.

## Bounded Enum: status

The `status` field on last-run.json is drawn from a fixed 3-value set. Exactly one of: `active | idle | error`.

| Enum Value | Definition | Phase 13 Runtime Behavior |
|---|---|---|
| `active` | Agent is currently executing a tick | Runtime updates last-run.json with `status: active` at wake and replaces with terminal state on completion |
| `idle` | Agent completed its last tick cleanly and is waiting for the next trigger | Default state on deploy-time initialization; Phase 13 flips back to idle on clean completion |
| `error` | Agent hit an unhandled error during the last tick | Runtime surfaces the error via the agent's escalation channel (typically Telegram) and keeps `status: error` until the next successful wake |

Any value outside `{active, idle, error}` forces a Step 1 validation halt on deploy re-run.

## Timezone Discipline

All ISO-8601 timestamps in both state.json and last-run.json MUST carry the `Z` UTC suffix (the Z UTC suffix makes the timestamp timezone-unambiguous across checkout / clone / image-bake boundaries). Local-time strings (without `Z` and without an explicit offset like `+02:00`) are rejected by Validation Checklist Check 5. This matches Phase 11 `<checkpoint_resume>` discipline: agent-system state must be timezone-unambiguous across checkout / clone / image-bake boundaries.

Examples:

- `"2026-04-24T14:32:17Z"` (accepted)
- `"2026-04-24T14:32:17.000Z"` (accepted; fractional seconds are allowed)
- `"2026-04-24T14:32:17+02:00"` (rejected; explicit offset is ambiguous once the file moves across timezones)
- `"2026-04-24T14:32:17"` (rejected; local time is ambiguous)

## Validation Checklist

The deploy-engine walks this ordered list after rendering the three files in Step 5 and BEFORE writing to disk. Any FAIL halts with `halt_reason: yaml-parse-error` citing the check number and the specific field.

1. `schema_version` equals `1` on both state.json and last-run.json. FAIL: the deploy-engine wrote a wrong scaffold; halt.
2. All three files exist (or are about to be written) in `.agentbloc/agents/<agent-id>/`. Directory creation is part of Step 5; missing after write = filesystem error, halt with `halt_reason: permission-denied`.
3. state.json and last-run.json both parse as valid JSON (no trailing commas, no unquoted keys, no single quotes). FAIL: halt citing the specific parse error.
4. memory.md has all 4 required H2 sections (Domain Knowledge, Decisions, Integration Quirks, Open Items) present in order. FAIL: halt citing the missing or out-of-order section.
5. Every ISO-8601 timestamp in both JSON files carries a `Z` UTC suffix. Grep the files for ISO-8601 patterns without `Z`; matches must be zero. FAIL: halt citing the offending field.
6. `_agentbloc_fingerprint` field present on both state.json and last-run.json with a valid 64-hex `sha256`. FAIL: halt; the canonicalization step was skipped.
7. `agent_id` on both state.json and last-run.json matches the parent directory slug. FAIL: halt; registry Step 6 would otherwise write a stale pointer.
8. `status` on last-run.json is one of `{active, idle, error}`. FAIL: halt citing the invalid value.
9. The `<!-- agentbloc:schema version=1 -->` marker comment is present in memory.md at the expected location (right after the H1). FAIL: halt; Phase 13 runtime depends on this marker for schema-version routing.

## Initialization Protocol (Deploy Time)

Step 5 of [deploy-protocol.md](deploy-protocol.md) creates the three files for every agent in the agent-profiles.yaml roster. Initialization values:

- **memory.md:** the 4-section H2 skeleton shown above with the HTML-comment guidance under each section. The `<agent-id>` placeholder in the H1 is substituted with the actual agent-id.
- **state.json:** `schema_version: 1`, `agent_id` substituted, `team` substituted, all timestamps `null`, `working_state: {}`, `processed_ids: []`, `locks: []`, `retries: []`, `kill_switch_last_checked: null`. `_agentbloc_fingerprint` computed over the canonicalized body per D-60.
- **last-run.json:** `schema_version: 1`, `agent_id` substituted, `action: "initial-deploy"`, `result: "Agent initialized by deploy-engine; awaiting first trigger."`, `timestamp` set to the deploy timestamp (with Z suffix), `status: idle`, `correlation_id` set to a freshly-generated UUID-v4, `_agentbloc_fingerprint` computed per D-60.

After all three files are written, the deploy-engine walks the Validation Checklist above. Any FAIL triggers the halt flow in [deploy-protocol.md](deploy-protocol.md) Halt Protocol.

## Runtime Protocol (Phase 13 Read/Write Semantics)

Phase 13 Multi-Agent Runtime (RUNTIME-07) implements the following contract per MEM-05. Phase 12 emits the contract; Phase 13 reads and enforces it.

**On agent wake, read all three files in order:**

1. Read `memory.md`. Parse the 4 H2 sections. Extract `## Domain Knowledge` for context; read `## Integration Quirks` for known gotchas; read `## Open Items` for pending follow-ups.
2. Read `state.json`. Parse `working_state` for the role-specific namespace; parse `processed_ids` for idempotency checks; parse `locks` to check for blocking tasks; parse `retries` for any pending exponential-backoff re-attempts.
3. Read `last-run.json`. Inspect `status` and `timestamp` to detect stale errors from prior ticks.

**Before executing the tick:** Phase 13 RUNTIME-07 reads `.agentbloc/KILL_SWITCH` (SECR-05 kill-switch pre-check). If present, abort the wake immediately, set `status: idle` on last-run.json, and surface the abort via escalation. Update `state.json` `kill_switch_last_checked` to the current timestamp.

**On agent completion, write state and last-run:**

1. Update `state.json` via the D-60 RFC 8785 canonicalization: rewrite `working_state` with the new role-specific data, append any newly-processed ids to `processed_ids`, update `last_completion_at`, recompute and append `_agentbloc_fingerprint`.
2. Rewrite `last-run.json` with the terminal `status` (`idle` on clean completion; `error` on exception), the new `action` and `result`, the current `timestamp`, a fresh `correlation_id`, and the recomputed `_agentbloc_fingerprint`.
3. Optionally append to `memory.md` `## Decisions` section with a one-line entry: `- YYYY-MM-DD: <decision> + <rationale>`. The agent is the authority on what qualifies as a significant decision; runtime does not gate this write.

**On tick error (unhandled exception):** Phase 13 runtime writes `status: error` on last-run.json, writes the truncated exception to `result`, leaves `state.json.working_state` unchanged (do not persist mid-tick partial state), and surfaces via the agent's escalation channel.

## Cross-Reference

- [deploy-protocol.md](deploy-protocol.md) , Step 5 caller that writes these three files atomically
- [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) , sibling contract defining `{{agent.memory_refs}}` anchor, which points at these three files
- [deploy-report-schema.md](deploy-report-schema.md) , DEPLOY-REPORT.md surfaces these files under the `## Created` section on first deploy and under `## Skipped` on idempotent re-run
- `.planning/phases/11-integration-discovery-browser-fallback/11-CONTEXT.md` D-50 , Phase 11 state.json checkpoint pattern that this schema extends to deployed agents
- [blast-radius.md](blast-radius.md) , v1.0 taxonomy citation for the `working_state` role-specific fields

## Re-run Semantics and Versioning

The `schema_version` field on both JSON files is an integer. It starts at `1`. Breaking changes (removing a REQUIRED field, removing a status enum value, changing a top-level key) require a bump; additive changes (new OPTIONAL field, new status enum value, new RECOMMENDED field loosened to OPTIONAL) do not.

**Re-run compare:** On re-deploy, the deploy-engine reads the existing three files, strips the fingerprint blocks, canonicalizes per D-60, and computes SHA256. Matching hash = skip (no re-write; file data is preserved across deploys). Differing hash = present unified diff via Step 3 of [deploy-protocol.md](deploy-protocol.md) and wait for user approval before overwriting.

**Coordinated bump discipline:** `schema_version` is shared between state.json and last-run.json; they must bump together. memory.md carries its own `<!-- agentbloc:schema version=1 -->` marker which also bumps in lockstep. A single-file bump that drifts the three files out of sync is a schema violation caught by Validation Checklist Check 1 or Check 9.

Downstream consumers (Phase 13 Runtime, Phase 14 Monitor, Phase 15 Anticipation, Phase 16 Validation) read `schema_version` and refuse to proceed on an unknown major version. This matches the rule in [agent-profile-schema.md](agent-profile-schema.md), [integration-manifest-schema.md](integration-manifest-schema.md), and [discovery-report-schema.md](discovery-report-schema.md).
