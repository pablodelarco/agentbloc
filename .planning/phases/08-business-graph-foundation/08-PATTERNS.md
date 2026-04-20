# Phase 8: Business Graph Foundation - Pattern Map

**Mapped:** 2026-04-20
**Files analyzed:** 3 (1 new, 2 modified)
**Analogs found:** 3 / 3

## File Classification

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `.claude/skills/agentbloc/references/business-graph-schema.md` (NEW) | schema reference + prose validator | request-response (Claude reads checklist, runs checks in Summary gate) | `references/data-classification.md` | exact (same shape: TOC, definition tables, activation/validation rules, compliance matrix) |
| `.claude/skills/agentbloc/references/phase-1-interview.md` (MODIFY) | interview protocol extension | CRUD on in-conversation state + file write | v1.0 Phase 3 Plan 01 (`03-01-PLAN.md`) — populated this exact file | exact (same file, same extension pattern — additive category seed + Summary template section) |
| `.claude/skills/agentbloc/SKILL.md` (MODIFY) | skill hub — Phase 1 loading list + gate vocabulary | config | v1.0 Phase 3 Plan 01 Task 2 (SKILL.md edit adding unconditional `data-classification.md` load) | exact (same file, same edit pattern — extend Phase 1 unconditional load block + gate values) |

---

## Pattern Assignments

### `references/business-graph-schema.md` (NEW file)

**Analog:** `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/data-classification.md` (138 lines)

**Why this analog:** Both files are loaded unconditionally at Phase 1 entry, both document a bounded classification/enum system, both contain a table-driven activation matrix, and both terminate with decision rules Claude applies during conversation. The Business Graph `security_profile` field is literally a JSON-structured version of what data-classification.md produces — they are companion files by design (CONTEXT.md line 138).

**Target length:** 130-200 lines (matching the data-classification.md + blast-radius.md range; NOT the 274-line gdpr-patterns.md expansion).

---

#### Pattern A: File header + TOC block

Copy verbatim structure from `data-classification.md` lines 1-15:

```markdown
# Business Graph Schema

> Schema reference loaded unconditionally at Phase 1 entry alongside phase-1-interview.md and data-classification.md. Defines the canonical Business Graph JSON emitted by the Summary gate and the validation checklist Claude applies before writing the file.

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

Note: `data-classification.md` uses `## When This Applies` as section 1 in every reference file; always keep that convention.

---

#### Pattern B: "When This Applies" opening paragraph

From `data-classification.md` lines 16-19:

```markdown
## When This Applies

Claude reads this file during the Interview Phase (category 5: Data Classification) to determine what data the user's workflow handles. The classification result activates the corresponding compliance regime and shapes every subsequent phase: Design (blast-radius scoring), Integration (credential scoping), and Deployment (governance.yaml generation).
```

**Adapt for Business Graph** — concrete text the planner can drop in:

```markdown
## When This Applies

Claude reads this file during the Interview Phase Summary gate to produce the canonical Business Graph JSON at `.agentbloc/graph/business-graph.json`. The schema defines what MUST / SHOULD / MAY appear in the JSON. The validation checklist is a deterministic list of pass/fail checks Claude walks through before writing the file; failures surface as targeted follow-up questions in the conversation. Downstream consumers (Phase 9 Designer Agent, Phase 12 Deploy Pipeline, Phase 14 Briefing Agent) all read this artifact.
```

---

#### Pattern C: Bounded-enum type documentation (for D-18 trigger enum)

**Analog:** `data-classification.md` lines 20-30 (Classification Categories table) shows exactly how to document a bounded type with per-value semantics. Copy this table shape for the trigger enum.

Source excerpt (lines 22-29):

```markdown
| Category | Definition | Examples | Regime Triggered |
|----------|-----------|----------|-----------------|
| PII (Personal) | Data identifying a natural person (GDPR Art. 4) | Names, emails, phone numbers, addresses, DNI/NIE, date of birth | GDPR (if EU) |
| PHI (Health) | Health data linked to an individual | Patient records, diagnoses, prescriptions, medical history, health insurance IDs | GDPR + HIPAA |
| Financial | Payment or banking data | Credit card numbers, IBAN, bank accounts, CVV, invoices with payment details | GDPR + PCI |
| Public | Non-identifying business data | Product SKUs, public pricing, schedules, stock levels, published content | None |
```

**Adapt for D-18 trigger enum** — use the same 4-column layout:

```markdown
| Enum Value | Definition | Required Sub-fields | Example |
|------------|-----------|---------------------|---------|
| `cron` | Time-based recurring trigger | `schedule` (cron string) | `{"type":"cron","schedule":"0 9 * * 1"}` |
| `event` | External-event-driven trigger | `source` (service name) + `name` (event id) | `{"type":"event","source":"gmail","name":"new_message"}` |
| `manual` | Human-initiated trigger | `description` (free text) | `{"type":"manual","description":"Operator runs weekly"}` |
```

---

#### Pattern D: Field-obligation matrix (for D-12 three-tier strictness)

**Analog:** CONTEXT.md D-12 already has the exact table format (three tiers × fields × behavior-if-missing). Planner should render it as-is in `business-graph-schema.md` under `## Field Obligation Matrix`. Cross-reference structurally identical tables in `data-classification.md` Retention Schedule (lines 86-94) and Compliance Activation Matrix (lines 126-138) for markdown style consistency.

Reference — `data-classification.md` lines 126-138 (Compliance Activation Matrix):

```markdown
## Compliance Activation Matrix

Summary of which signals trigger which regimes:

| Signal Detected | Data Class | Regime Activated | Confidence |
|----------------|------------|-----------------|------------|
| Names, emails, addresses, phone numbers | PII | GDPR (if EU) | HIGH |
| Patient records, diagnoses, prescriptions | PHI | GDPR + HIPAA | HIGH |
| Credit card numbers, IBAN, bank accounts | Financial | GDPR + PCI | HIGH |
| Product SKUs, public pricing, schedules | Public | None | HIGH |
...
```

---

#### Pattern E: Validation Checklist — the novel element

**No exact analog in references/** (prose-checklist-as-validator is a new pattern per CONTEXT.md line 144). Use two ingredients already in the codebase:

1. The **decision-tree-as-numbered-prose pattern** from `blast-radius.md` lines 32-53 (Scoring Decision Tree):

```markdown
## Scoring Decision Tree

For each agent in the team design, follow these steps:

**Step 1: Does the agent send data externally?**
- Sends emails, Telegram messages, API POST/PUT/DELETE to third-party services, or webhook calls?
- YES: **Level 4 (send-external)**
- NO: Continue to Step 2.

**Step 2: Does the agent write to files or databases without path restrictions?**
- Can write to arbitrary paths, run unrestricted Bash commands, or modify any state file?
- YES: **Level 3 (write-unrestricted)**
- NO: Continue to Step 3.
```

2. The **Master Completion Checklist pattern** from `phase-1-interview.md` lines 264-279 (Interview Completion Gate):

```markdown
## Interview Completion Gate (INTV-03)

Before generating the Summary of Understanding, verify ALL must-know items across all 9 categories:

### Master Completion Checklist

**The Problem:** core pain point, current cost, desired outcome, success criteria
**The Current Workflow:** end-to-end map, manual steps, frequency, time per cycle
...

**If any must-know item has a gap, ask targeted follow-up questions before proceeding.** Do not generate the summary until every checkbox above can be checked.
```

**Combine the two for the validation checklist** — ordered pass/fail gates with targeted resolution prompts. Concrete shape planner should emit:

```markdown
## Validation Checklist

Claude walks this ordered list before writing `.agentbloc/graph/business-graph.json`. Any FAIL triggers a conversational follow-up before emission.

**Check 1: `schema_version` present and equals current version (`1`)**
- FAIL: Emit `"schema_version": 1` automatically; no user follow-up needed.

**Check 2: `business.type` present and non-empty string**
- FAIL: Ask "What kind of business is this — a rental agency, ecommerce store, clinic, something else?" before emission.

**Check 3: `processes[]` present and length >= 1**
- FAIL: Ask "We've talked about your workflow — let me confirm the main process we're automating. Can you name it?" before emission.

**Check 4: Every `process` has `name`, `steps[]` (length >= 1), and `pain`**
- FAIL: For each gap, ask one targeted question (e.g., "For the <name> process, what specific pain does it cause today?") before emission.

**Check 5: Every `process.trigger.type` in {cron, event, manual} with required sub-field (per Trigger Bounded Enum section)**
- FAIL: Ask "What triggers <process-name> — a schedule, an external event, or a human action?" before emission.

**Check 6 (WARN, not FAIL): RECOMMENDED fields populated or explicitly marked `null`**
- WARN: Emit with `null` defaults; log the gap in the rendered table review (D-14) so user sees what was guessed.
```

---

#### Pattern F: Schema definition block

**No direct analog** for a commented-JSON schema in existing references/. Use TypeScript-lite comments per CONTEXT.md D-13 ("commented JSON/TypeScript-lite"). Keep it within one fenced block, heavily commented, resembling the `audit-logging.md` Field Definitions table style (lines 24-37) for clarity.

Planner should produce something like:

````markdown
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
        "type": "cron | event | manual",     // See Trigger Bounded Enum section.
        // ...type-specific sub-fields
      },
      "tools": ["string"],                    // RECOMMENDED. Tool names referenced in this process.
      "frequency": "string | null",           // RECOMMENDED. e.g. "weekly", "daily-9am"
      "current_actor": "string | null",       // RECOMMENDED. Who does this today.
      "pain": "string"                        // REQUIRED. Free-text pain description (D-20).
    }
  ],
  "tools_available": ["string"],              // OPTIONAL. Extracted from Category 3.
  "channels": ["string"],                     // OPTIONAL. Extracted from Category 8. e.g. ["telegram","email"]
  "decision_patterns": ["string"],            // OPTIONAL. Free-text rules from Category 7 D-16 seed question.
  "security_profile": {                       // OPTIONAL. Structured version of v1.0 D-10 tally.
    "data_classes": ["PII","Financial"],
    "regimes_activated": ["GDPR"]
  },
  "business_context": "string | null"         // OPTIONAL. Free-text additional context.
}
```
````

---

#### Pattern G: Emission Protocol + Re-run Behavior sections

No analog — these are Phase-8-specific (D-11, D-14, D-19). Planner should write these from CONTEXT.md directly. Keep each to 8-15 lines.

---

#### Pattern H: Cross-links to companion references

**Analog:** `phase-1-interview.md` lines 24-26 shows the cross-link convention for companion references loaded at Phase 1:

```markdown
## When This Applies

This file is loaded at Phase 1 entry, unconditionally alongside [references/data-classification.md](data-classification.md). Every AgentBloc session begins here. No questions are asked until both files are fully read.
```

**Apply:** `business-graph-schema.md`'s "When This Applies" should cross-link to both `phase-1-interview.md` and `data-classification.md` in the same shorthand-relative-path style (no leading `references/`).

---

### `references/phase-1-interview.md` (MODIFY)

**Analog:** `/Users/pablodelarco/agentbloc/.planning/milestones/v1.0-phases/03-interview-and-design-phases/03-01-PLAN.md` Task 1. This is the plan that originally populated `phase-1-interview.md` — it defines the exact section conventions the Phase 8 edit must honor (seed question format, adaptive branching bullets, Data Classification Scan footer, Summary template markdown tables).

**Localized extension points** (exact line ranges in the CURRENT `phase-1-interview.md`):

| Extension | Current location | What to add |
|-----------|------------------|-------------|
| **D-16: new seed question** in Category 7 | Lines 199-218 (`## Category 7: Edge Cases and Failures` through its `Data Classification Scan` footer). Specifically the **Seed Questions** subsection at lines 201-205. | Add seed question #3: `"What rules do you apply when deciding how to handle these edge cases? For example: if an invoice is overdue by more than 7 days, what do you do?"` |
| **D-16: new Must-Know item** | Line 207 (Must-Know Checklist for Category 7) | Add checkbox: `- [ ] Decision rules captured for at least the top edge case (feeds decision_patterns)` |
| **D-11: Business Graph emission in Summary** | Lines 281-333 (`## Summary of Understanding Template (INTV-04, D-10)` — the full template section). Insert NEW subsection **after** the confirmation gate on line 333. | Add `### Business Graph Emission` subsection (8-15 lines) describing the silent JSON write with cross-link to `business-graph-schema.md` validation checklist. |
| **D-14: rendered table review** | Same Summary of Understanding Template — the existing template already renders tables (lines 293-316). Extension is **additive table sections** for tools_available / channels / decision_patterns that don't yet exist. | Add three new subsections between "Services and Integrations" (line 293) and "Data Model" (line 298) OR group with existing sections — see structural note below. |
| **SKILL.md mention of new reference** | File-level change; see next file. | N/A here |

#### Seed question format pattern (for D-16 insertion)

**Analog:** `phase-1-interview.md` lines 71-74 (Category 1 Seed Questions):

```markdown
### Seed Questions

1. "What's the business problem you want to solve? Describe the pain point in your own words."
2. "What happens today when this problem isn't handled? What's the cost of the current situation?"
3. "How will you know the solution is working? What does success look like?"
```

Every seed question is **a single-sentence double-quoted string in a numbered list**. New D-16 question must follow the exact same format.

#### Adaptive Branching bullet format (for updating Category 7)

**Analog:** `phase-1-interview.md` lines 213-216 (Category 7 current Adaptive Branching):

```markdown
### Adaptive Branching

- If user says "nothing goes wrong," push back gently: "Every workflow has edge cases. What happens when data is missing, a tool is down, or someone doesn't respond on time?"
- If user describes catastrophic failures, probe for prevention: "Has this happened before? What was the impact, and what would have prevented it?"
- If failure modes involve data corruption or loss, flag for Design phase blast-radius gating."
```

Planner may add one new adaptive bullet for the rule-capture follow-up:
`- If user describes a rule or threshold, capture verbatim for decision_patterns: "Let me write that down — [paraphrase the rule]. Any other rules like that one?"`

#### Summary template table format (for D-14 tools_available / channels / decision_patterns)

**Analog:** `phase-1-interview.md` lines 293-316 (existing Services, Data Model, People, Edge Cases, Reporting tables):

```markdown
### Services and Integrations
| Service | Access Level | Integration Path |
|---------|-------------|-----------------|
| [Tool name] | [admin/API/web-only] | [API/MCP/Playwright/email] |

### Data Model
| Data Type | Format | Source | Destination | Volume |
|-----------|--------|--------|-------------|--------|
| [type] | [format] | [where from] | [where to] | [per cycle] |
```

Every Summary-section table uses: 3-6 columns, square-bracket `[placeholder]` example row, H3 heading. Planner should match this for the 3 new sections (tools_available, channels, decision_patterns) or fold into existing Services + Reporting tables.

**Structural note:** D-14 says "each section is its own confirmation moment." Safest path is 3 new H3 tables inserted after the existing "Services and Integrations" table and before "Data Model" — keeping the business→process→tools→channels→data→security flow CONTEXT.md D-14 describes.

#### Business Graph Emission subsection (for D-11)

No direct analog (this is a new gate-ritual extension). Use the existing confirmation gate language style at line 333:

```markdown
**Does this accurately capture your workflow? I need your confirmation before proceeding to the design phase.**
```

Concrete text planner can use:

```markdown
### Business Graph Emission (D-11, D-14)

Once the user confirms the rendered tables above:

1. Apply the Validation Checklist from [references/business-graph-schema.md](business-graph-schema.md).
2. For any failed REQUIRED check, ask the targeted follow-up question before emission.
3. Write the validated JSON silently to `.agentbloc/graph/business-graph.json`.
4. Confirm emission to the user in one sentence: "Business Graph saved. Ready to move to the design phase."
5. Transition: Phase 1 gate becomes `approved`; `business_graph_validated` gate becomes `approved`.

The JSON is not shown to the user. The rendered tables above ARE the user-facing review. Edits are conversational; after any edit, re-run the Validation Checklist and re-emit.
```

---

### `SKILL.md` (MODIFY)

**Analog:** `/Users/pablodelarco/agentbloc/.planning/milestones/v1.0-phases/03-interview-and-design-phases/03-01-PLAN.md` Task 2 (lines 216-258). This is the v1.0 edit that made `data-classification.md` load unconditionally at Phase 1 — the exact same file, same section, same pattern.

**Localized extension points** (exact line ranges in CURRENT `SKILL.md`, which is 160 lines):

| Extension | Current location | What to change |
|-----------|------------------|----------------|
| **Add `business-graph-schema.md` to unconditional load list** | Lines 88-95 (Phase 1 section, specifically lines 92-94 listing the two files currently loaded). | Add a third `See [references/business-graph-schema.md](references/business-graph-schema.md)` line. Update preceding sentence to "read the complete interview protocol AND the data classification reference AND the business graph schema". |
| **Phase 2 precondition** | Lines 97-102 (Phase 2: General Design section). | Add precondition line BEFORE the `You MUST read...` line: "Precondition: verify `.agentbloc/graph/business-graph.json` exists and validates against `references/business-graph-schema.md`. If missing or invalid, return to Phase 1 Summary gate." |
| **New gate value `business_graph_validated`** | Lines 24-30 (State Protocol state bar definition). | Extend gate vocabulary. See pattern below. |

#### Unconditional loading pattern (the exact v1.0 Phase 3 Task 2 edit)

Source — `03-01-PLAN.md` lines 226-241 (Before / After block for the original unconditional-load edit):

```markdown
Current text (lines 91-95):
\`\`\`
You MUST read the complete interview protocol before asking any questions:
See [references/phase-1-interview.md](references/phase-1-interview.md)

If the user's data involves PII, PHI, or financial information, also read:
See [references/data-classification.md](references/data-classification.md)
\`\`\`

Replace with:
\`\`\`
You MUST read the complete interview protocol AND the data classification reference before asking any questions:
See [references/phase-1-interview.md](references/phase-1-interview.md)
See [references/data-classification.md](references/data-classification.md)
\`\`\`
```

**Phase 8 applies the same micro-edit pattern one more time.** Current SKILL.md lines 92-94:

```markdown
You MUST read the complete interview protocol AND the data classification reference before asking any questions:
See [references/phase-1-interview.md](references/phase-1-interview.md)
See [references/data-classification.md](references/data-classification.md)
```

Replace with (concrete text planner can drop in):

```markdown
You MUST read the complete interview protocol AND the data classification reference AND the business graph schema before asking any questions:
See [references/phase-1-interview.md](references/phase-1-interview.md)
See [references/data-classification.md](references/data-classification.md)
See [references/business-graph-schema.md](references/business-graph-schema.md)
```

This is a 2-line net add + 1-word update — same surgical scope as the v1.0 precedent.

#### Gate value extension pattern

**Analog:** SKILL.md lines 24-40 (State Protocol) already defines gate vocabulary (`pending` / `approved` / `blocked`) and state transitions. The Phase 8 extension adds ONE new gate value **specific to the Phase 1→2 transition**: `business_graph_validated`. Per CONTEXT.md specifics ("No new gate vocabulary beyond one value"), planner should add this as a sub-gate within Phase 1's `approved` state, NOT a new top-level gate value.

Source excerpt — SKILL.md lines 36-40 (State Transitions):

```markdown
### State Transitions

- `pending` to `approved`: User explicitly confirms ("yes", "approved", "ok", "adelante")
- `pending` to `blocked`: An issue prevents progression
- Phase number increments ONLY after current gate is `approved` AND user explicitly confirms
```

**Planner should extend with Phase-1-specific rule** (insert as new bullet after line 40):

```markdown
- Phase 1 specific: `approved` requires BOTH user confirmation of the rendered Business Graph tables AND `business_graph_validated` sub-gate (all REQUIRED validation checks from references/business-graph-schema.md passed). The JSON file at `.agentbloc/graph/business-graph.json` must exist before Phase 2 begins.
```

#### Phase 2 precondition pattern

**Analog:** SKILL.md lines 97-102 (Phase 2 current block):

```markdown
### Phase 2: General Design

Translate the interview into a high-level agent team design. Identify agents (one per responsibility), map topology (pipeline, mesh, hierarchy, swarm), define contracts, schedules, and governance. Present as diagram + table.

You MUST read the complete design protocol before starting this phase:
See [references/phase-2-design.md](references/phase-2-design.md)
```

Planner should add a precondition sentence between the descriptive paragraph and the "You MUST read..." line:

```markdown
### Phase 2: General Design

Translate the interview into a high-level agent team design. Identify agents (one per responsibility), map topology (pipeline, mesh, hierarchy, swarm), define contracts, schedules, and governance. Present as diagram + table.

**Precondition:** Verify `.agentbloc/graph/business-graph.json` exists and validates against `references/business-graph-schema.md`. If missing, return the state bar to Phase 1 with gate `pending` and re-run the Summary gate.

You MUST read the complete design protocol before starting this phase:
See [references/phase-2-design.md](references/phase-2-design.md)
```

Size constraint per v1.0 Phase 1 plan: SKILL.md must stay under 250 lines. Current 160 → +~8 after this phase. Fits comfortably.

---

## Shared Patterns

### Reference file structural spine

**Source:** every file in `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/` (see `data-classification.md`, `blast-radius.md`, `audit-logging.md`)

Every reference file follows:

1. H1 title
2. One-line blockquote `> ` describing when/how loaded (lines 1-3)
3. `## Table of Contents` with anchor links (lines 5-14)
4. `## When This Applies` — paragraph explaining trigger condition (lines 16-19)
5. Substantive content as H2 sections
6. Frequently: `## Quick Reference` summary table at bottom

**Apply to:** `business-graph-schema.md` — must start with this exact skeleton.

### Table-driven rules

**Source:** `data-classification.md` (every section is a markdown table), `blast-radius.md` lines 22-29, `audit-logging.md` lines 25-37

All bounded enums / scoring / field definitions render as markdown tables, NOT prose lists. Columns typically: name | definition | required-companions | example | regime-or-level-triggered.

**Apply to:** `business-graph-schema.md` — field obligation matrix (D-12), trigger enum (D-18), and versioning rules all render as tables.

### Cross-link to companion reference

**Source:** `phase-1-interview.md` line 25 (unconditional companion load), and repeated "Cross-Reference" mini-sections throughout (lines 64-66)

Companion-loaded references cross-link to each other using **shorthand relative paths** (just `data-classification.md`, no `references/` prefix, because they sit in the same directory). From SKILL.md they use the full relative path (`references/data-classification.md`).

**Apply to:** `business-graph-schema.md` must cross-link to `phase-1-interview.md` (emission happens in the Summary gate there) and `data-classification.md` (feeds `security_profile` field).

### Surgical SKILL.md edits

**Source:** `03-01-PLAN.md` Task 2 (the v1.0 Phase 3 precedent)

All SKILL.md edits in extension phases follow the same discipline:
- Touch only the Phase N section where the change belongs
- Add reference links in the existing "You MUST read..." block, not a new block
- Keep total file under 250 lines
- Do not restructure State Protocol or Hard Gates sections; extend via additive bullets

**Apply to:** Phase 8 SKILL.md edits — three small additions (one line add in Phase 1 load list, one bullet add in State Transitions, one paragraph add in Phase 2).

---

## No Analog Found

| Sub-pattern | Reason | Fallback |
|-------------|--------|----------|
| Prose-checklist-as-schema-validator | New pattern introduced in this phase | Compose from `blast-radius.md` decision tree + `phase-1-interview.md` Master Completion Checklist (see Pattern E above) |
| Commented-JSON schema block in a reference | No reference file currently embeds a schema | Use JSONC fenced block per CONTEXT.md D-13; style loosely on `audit-logging.md` Example Entry (line 43) |
| Re-run/merge behavior documentation | No existing reference documents re-invocation semantics | Write from D-19 directly; keep to ~10 lines |

---

## Metadata

**Analog search scope:**
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/` (19 files, 5,255 lines total)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/SKILL.md` (160 lines)
- `/Users/pablodelarco/agentbloc/.planning/milestones/v1.0-phases/01-skill-foundation/` (reference stub creation precedent)
- `/Users/pablodelarco/agentbloc/.planning/milestones/v1.0-phases/03-interview-and-design-phases/` (phase-1-interview.md population + SKILL.md unconditional-load edit precedent)

**Primary analogs selected:**
1. `references/data-classification.md` — structural twin for `business-graph-schema.md`
2. `references/blast-radius.md` — decision-tree-as-prose pattern for validation checklist
3. `references/phase-1-interview.md` lines 199-218, 281-333 — extension points for D-16 seed + D-11/D-14 Summary emission
4. `03-01-PLAN.md` Task 2 — SKILL.md unconditional-load edit precedent (the v1.0 edit this phase's edit mirrors)

**Files scanned:** 22 (19 references + SKILL.md + 2 v1.0 phase plans)
**Pattern extraction date:** 2026-04-20
