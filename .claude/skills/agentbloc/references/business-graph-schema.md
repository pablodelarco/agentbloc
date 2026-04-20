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

## When This Applies

Claude reads this file during the Interview Phase Summary gate to produce the canonical Business Graph JSON at `.agentbloc/graph/business-graph.json`. The schema defines what MUST, SHOULD, and MAY appear in the JSON. The validation checklist below is a deterministic list of pass/fail checks Claude walks through before writing the file; failures surface as targeted follow-up questions in the conversation. Downstream consumers (Phase 9 Designer Agent, Phase 12 Deploy Pipeline, Phase 14 Briefing Agent) all read this artifact. The `security_profile` field is the JSON-structured version of the running tally produced by the interview's data-classification scan in [data-classification.md](data-classification.md); emission itself happens in the Summary of Understanding step defined in [phase-1-interview.md](phase-1-interview.md).

## Schema Definition

```jsonc
{
  "schema_version": 1,                        // REQUIRED. Integer. Bumped only on breaking changes.
  "business": {
    "type": "string",                         // REQUIRED. e.g. "rental-property-management"
    "size": "string | null",                  // RECOMMENDED. e.g. "7 properties, 1 operator"
    "owner": "string | null"                  // RECOMMENDED. e.g. "Maria"
  },
  "processes": [                              // REQUIRED. Length >= 1.
    {
      "name": "string",                       // REQUIRED.
      "steps": ["string"],                    // REQUIRED. Length >= 1.
      "trigger": {                            // RECOMMENDED.
        "type": "cron | event | manual",      // Bounded enum. See Trigger Bounded Enum section.
        // cron requires:    "schedule": "<cron string>"
        // event requires:   "source": "<service>", "name": "<event id>"
        // manual requires:  "description": "<free text>"
      },
      "tools": ["string"],                    // RECOMMENDED. Tool names referenced in this process.
      "frequency": "string | null",           // RECOMMENDED. e.g. "weekly", "daily-9am"
      "current_actor": "string | null",       // RECOMMENDED. Who does this today.
      "pain": "string"                        // REQUIRED. Free-text pain description.
    }
  ],
  "tools_available": ["string"],              // OPTIONAL. Extracted from interview Category 3.
  "channels": ["string"],                     // OPTIONAL. Extracted from Category 8. e.g. ["telegram","email"]
  "decision_patterns": ["string"],            // OPTIONAL. Free-text rules from Category 7 seed question.
  "security_profile": {                       // OPTIONAL. Structured version of the v1.0 data-classification tally.
    "data_classes": ["PII", "Financial"],
    "regimes_activated": ["GDPR"]
  },
  "business_context": "string | null"         // OPTIONAL. Free-text additional context.
}
```

## Field Obligation Matrix

| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED | `schema_version`, `business.type`, `processes[]` (length >= 1), per-process `name` + `steps[]` + `pain` | Validation fails. Gate blocks Phase 2 transition. Claude asks the user the missing question. |
| RECOMMENDED | `business.size`, `business.owner`, per-process `trigger`, `tools`, `frequency`, `current_actor` | Validation warns but does not fail. Default to `null` or `"unknown"`. Phase 2 Designer Agent proceeds with degraded output and flags the gap. |
| OPTIONAL | `tools_available[]`, `channels[]`, `decision_patterns[]`, `security_profile`, `business_context` | Silent defaults. Empty arrays, `null` values. Designer Agent proceeds without comment. |

Downstream consumers (Phase 9 Designer Agent, Phase 12 Deploy, Phase 14 Briefing) read `schema_version` and refuse to proceed on an unknown major version.

## Trigger Bounded Enum

Every `process.trigger.type` value is drawn from a fixed set: `{cron, event, manual}`. Each value pairs with a specific required sub-field so Phase 9 Designer Agent can map the trigger directly onto an orchestration primitive without free-text interpretation.

| Enum Value | Definition | Required Sub-fields | Example |
|------------|-----------|---------------------|---------|
| `cron` | Time-based recurring trigger | `schedule` (cron string) | `{"type":"cron","schedule":"0 9 * * 1"}` |
| `event` | External-event-driven trigger | `source` (service name) + `name` (event id) | `{"type":"event","source":"gmail","name":"new_message"}` |
| `manual` | Human-initiated trigger | `description` (free text) | `{"type":"manual","description":"Operator runs weekly"}` |

Any value outside this enum forces a clarification question before emission; extensions (`webhook`, `loop`) are deferred to a future schema version bump.

## Validation Checklist

Claude walks this ordered list before writing `.agentbloc/graph/business-graph.json`. Any FAIL triggers a conversational follow-up before emission; the REQUIRED tier checks (1-5) block emission; the RECOMMENDED tier check (6) emits with warnings.

**Check 1: `schema_version` present and equals current version (`1`)**
- FAIL: Emit `"schema_version": 1` automatically; no user follow-up needed.

**Check 2: `business.type` present and non-empty string**
- FAIL: Ask "What kind of business is this, a rental agency, ecommerce store, clinic, or something else?" before emission.

**Check 3: `processes[]` present and length >= 1**
- FAIL: Ask "We've talked about your workflow. Let me confirm the main process we're automating. Can you name it?" before emission.

**Check 4: Every `process` has `name`, `steps[]` (length >= 1), and `pain`**
- FAIL: For each gap, ask one targeted question (e.g., "For the <name> process, what specific pain does it cause today?") before emission.

**Check 5: Every `process.trigger.type` in {cron, event, manual} with required sub-field (per Trigger Bounded Enum section)**
- FAIL: Ask "What triggers <process-name>, a schedule, an external event, or a human action?" before emission.

**Check 6 (WARN, not FAIL): RECOMMENDED fields populated or explicitly marked `null`**
- WARN: Emit with `null` defaults; log the gap in the rendered table review so the user sees what was guessed.

## Emission Protocol

Emission happens during the [phase-1-interview.md](phase-1-interview.md) Summary of Understanding gate. The steps:

1. Walk the Validation Checklist above in order.
2. For each REQUIRED failure (Checks 1-5), ask the targeted conversational follow-up and wait for the user's answer before resuming.
3. Once all REQUIRED checks pass, render the Business Graph to the user as the tables in the Summary of Understanding Template (business, processes, tools_available, channels, decision_patterns, security_profile). The JSON itself is never shown to the user.
4. After user confirmation ("yes" / "adelante" / etc.), write the JSON silently to `.agentbloc/graph/business-graph.json`. Create the `.agentbloc/graph/` directory if it does not exist.
5. Confirm emission in one sentence: "Business Graph saved. Ready to move to the design phase."
6. Set the Phase 1 `business_graph_validated` sub-gate to `approved` and allow transition to Phase 2.

If the user edits any table, re-run the Validation Checklist and re-emit the JSON.

## Re-run Behavior

If `.agentbloc/graph/business-graph.json` already exists when the Summary gate is reached, Claude asks the user: "I already have a Business Graph on file for this project. Do you want to (a) keep the existing one, (b) overwrite it, or (c) merge new processes into it?" Default is **merge** (additive).

- **keep**: Skip emission, transition to Phase 2 with the existing graph.
- **overwrite**: Replace the file entirely after a fresh Validation Checklist pass.
- **merge**: Add newly captured processes to the existing `processes[]` array. If a new process shares a `name` with an existing one, present both to the user and ask whether to rename, overwrite the old, or skip the new.

The `schema_version` on disk must match the current schema version. If it does not, refuse merge and emit `"action_required": "schema_version_mismatch"` to the conversation so the user knows a manual migration is needed.

## Schema Versioning Rules

The `schema_version` field is an integer. It starts at `1`. The version bumps only on breaking changes:

- A REQUIRED field is removed or renamed.
- An enum value is removed from a bounded type (e.g., dropping `cron` from `trigger.type`).

Additive changes do NOT bump the version:

- Adding a new OPTIONAL field.
- Adding a new value to a bounded enum.
- Loosening a REQUIRED field to RECOMMENDED.

Downstream consumers (Phase 9 Designer Agent, Phase 12 Deploy, Phase 14 Briefing) read `schema_version` and refuse to proceed on an unknown major version.
