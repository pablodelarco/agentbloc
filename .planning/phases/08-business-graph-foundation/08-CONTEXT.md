# Phase 8: Business Graph Foundation - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning
**Decision mode:** Autonomous (per `autonomous_mode` memo — Pablo authorized expert-judgment decisions on implementation gray areas)

<domain>
## Phase Boundary

Extend the shipped v1.0 Phase 1 Interview so that it produces a canonical, schema-validated Business Graph JSON artifact alongside its existing prose Summary of Understanding — without changing the conversational UX the user experiences. Freeze the Business Graph schema, define the bounded-enum trigger shape, ship the validator as a prose-checklist gate in the Summary step, and commit the reference file that Phase 9 (Designer Agent) will consume as its input contract.

**In scope:**
- `references/business-graph-schema.md` (new) — canonical schema with required vs optional fields, `schema_version` field, validation checklist
- Extension of `references/phase-1-interview.md` — Summary gate emits the JSON; Category 7 seed question captures `decision_patterns`; Categories 3 and 8 extraction pulls `tools_available` and `channels`
- Extension of `SKILL.md` Phase 1 entry — Business Graph validation gate before Phase 2 transition
- `.agentbloc/graph/business-graph.json` file contract (location locked by `.planning/v2.0-PROMPT.pdf`)

**Out of scope (belongs to later phases):**
- Designer Agent consumption of the Business Graph (Phase 9)
- Agent profile YAML generation (Phase 9)
- Orchestration classification (Phase 9)
- Any deploy / runtime concerns (Phases 12–13)
- External JSON Schema validator (ajv etc.) — explicit non-goal in v2.0; see D-13

</domain>

<decisions>
## Implementation Decisions

### Inherited from v1.0 Phase 3 (carry forward — do not re-decide)

- **Inherited D-01 (Hybrid navigation):** 2–3 mandatory seed questions per category + adaptive branching. Applies to the extended Category 7 (`decision_patterns` capture) — add a seed, keep branching adaptive.
- **Inherited D-03 (One question per turn):** The Business Graph emission does not change this. Still strictly one question per turn throughout Phase 1.
- **Inherited D-04 (Soft framing):** The "15–25 questions across 9 areas" framing stays. Business Graph emission is invisible to this count.
- **Inherited D-08 (Progressive data classification):** Running tally feeds the Security Profile section of the Business Graph directly — no new classification step.
- **Inherited D-10 (Security Profile in Summary):** The Business Graph's Security Profile section is produced from the same tally. No duplicate work.

### New decisions (autonomous, per PDF + REQUIREMENTS + prior phases)

#### Emission mechanism

- **D-11 (Emission lives in the Summary gate, no subagent):** Claude writes `.agentbloc/graph/business-graph.json` during the existing Phase 1 Summary step. The JSON is produced first; the prose summary is rendered from the JSON so the two cannot drift. No separate `graph-builder` subagent — that would add surface area without benefit because the interview conversation already lives in the main session's context.

  **Rationale:** Minimum new moving parts. Summary gate already exists and already synthesizes the full interview. Adding a JSON write to the same step is additive, not a new architecture. Subagent-with-parse would have to re-read the transcript — duplicate work.

#### Schema

- **D-12 (By-section strictness; integer versioning):** The schema defines three tiers of field obligation. `schema_version: integer` starts at `1` and only bumps on breaking changes.

  | Tier | Fields | Behavior if missing |
  |---|---|---|
  | REQUIRED | `schema_version`, `business.type`, `processes[]` (length ≥ 1), per-process `name` + `steps[]` + `pain` | Validation fails. Gate blocks Phase 2 transition. Claude asks the user the missing question. |
  | RECOMMENDED | `business.size`, `business.owner`, per-process `trigger`, `tools`, `frequency`, `current_actor` | Validation warns but does not fail. Default to `null` or `"unknown"`. Phase 2 Designer Agent proceeds with degraded output and flags the gap. |
  | OPTIONAL | `tools_available[]`, `channels[]`, `decision_patterns[]`, `security_profile`, `business_context` free-text | Silent defaults. Empty arrays, `null` values. Designer Agent proceeds without comment. |

  **Versioning rule:** bump only on (a) required field removed or renamed, or (b) enum value removed from a bounded type (e.g., dropping `cron` from `trigger.type`). Additive changes — adding optional fields, adding enum values, loosening required → recommended — do NOT bump the version. Designer Agent (Phase 9) reads `schema_version` and refuses to proceed on any major version it does not know.

  **Rationale:** Strict for fields Designer cannot degrade on (no processes → no agents to design). Forgiving for enrichment fields that Designer can synthesize around. Simple integer keeps the mental model small; SemVer is overkill for a schema with one consumer in-repo.

#### Validator placement

- **D-13 (Built-in gate via prose-checklist in `business-graph-schema.md`):** The validator is NOT external tooling. It is a deterministic checklist inside `references/business-graph-schema.md` that Claude reads and applies during the Summary gate. No `ajv`, no `jsonschema` Python, no new npm dependency. AgentBloc stays markdown-only.

  **Mechanics:** `business-graph-schema.md` has three sections: (1) the schema definition as commented JSON/TypeScript-lite, (2) a required/recommended/optional field matrix matching D-12, (3) a **validation checklist** — an ordered list of pass/fail checks Claude walks through before emitting. Failed checks surface to the user with a specific resolution prompt ("I don't have `business.type` yet — what kind of business is this?"). The gate will not emit the JSON until all REQUIRED checks pass.

  **Rationale:** Honors the AgentBloc "markdown-only skill" constraint. Avoids introducing a JS/Python runtime just for schema checking. TAP tests in Phase 16 verify against canned Business Graphs, giving us the external rigor without the runtime dependency. If Phase 9+ needs stricter validation (e.g., Designer Agent wants guaranteed-parseable input), we can upgrade to ajv then — but premature for Phase 8.

#### User-facing review

- **D-14 (Rendered table review + silent JSON emission):** At the end of the interview, Claude shows the Business Graph as a human-readable table/card view — matching the style of v1.0 D-10's Security Profile. The JSON file is written silently to `.agentbloc/graph/business-graph.json` as a side effect. User confirms the **rendered table**, not the JSON; edits are conversational ("owner should be María, not Pablo"), and Claude re-emits the JSON after edits.

  **Presentation structure:** business block → processes table → tools available → channels → decision patterns → Security Profile (already in v1.0). Each section is its own confirmation moment.

  **Rationale:** INTV-04 asks for "structured review." A tall JSON blob is structured but not friendly to non-technical users (the primary audience). Table view is what humans can reason about. Silent JSON is what Phase 9 Designer Agent reads. No compromise — user gets UX, Designer gets data.

### Additive decisions (not in REQUIREMENTS, needed for clean implementation)

- **D-15 (File location locked by PDF):** `.agentbloc/graph/business-graph.json`. Not negotiable — Phase 9 Designer, Phase 12 Deploy, and Phase 14 briefing agent all expect this path.

- **D-16 (`decision_patterns` capture point):** Add one seed question to Category 7 "Edge Cases and Failures": *"What rules do you apply when deciding how to handle [an edge case the user described]?"* The free-text responses feed the `decision_patterns[]` array. Alternative would have been a 10th category; folding into Category 7 keeps the 9-category structure that v1.0 shipped (D-01 honored).

- **D-17 (`tools_available` and `channels` extraction):** No new interview questions. Categories 3 (Services and Tools) and 8 (Reporting and Communication) already capture these; the Business Graph emission step extracts them into their dedicated fields. If Category 3 yields an empty list, Claude asks a clarifying question at emission time ("I didn't capture specific tools you use — does anything come to mind?") before emitting.

- **D-18 (`trigger` bounded enum):** `process.trigger.type` ∈ `{cron, event, manual}`.
  - `cron` requires `schedule` (cron string).
  - `event` requires `source` (service name) + `name` (event identifier).
  - `manual` requires `description` (free text).
  - Anything outside the enum forces a clarification question before emission.

  **Rationale:** Designer Agent (Phase 9) maps trigger types directly to the orchestration patterns (ORCH-01). A bounded enum makes that mapping deterministic. Adding `webhook` or `loop` later is a v2.0 post-ship migration (additive, no version bump).

- **D-19 (Re-run / overwrite behavior):** If `.agentbloc/graph/business-graph.json` already exists at the Summary gate, Claude asks the user: *keep existing / overwrite / merge new processes into existing.* Default is **merge** (additive — new processes join existing, duplicate names flagged for user resolution). Overwrite only if user says so. Prevents data loss in the common "I want to add another workflow" case.

- **D-20 (`process.pain` stays free-text):** No enum, no category. Users describe pain differently ("manual", "repetitive", "error-prone", "takes 3 hours every Monday"). Designer Agent (Phase 9) uses natural-language understanding to classify; premature structuring here would lose fidelity.

### Claude's Discretion

- Exact table rendering format for the review (column order, grouping within each section) — keep consistent with v1.0 D-05 (table + cards)
- Exact wording of the D-16 edge-case-rule seed question — ship a default, adapt to user's language
- Whether to include the Security Profile inside the Business Graph JSON (`security_profile` field) or keep it in the prose summary only — **lean: include in JSON as OPTIONAL field.** Phase 9 Designer Agent benefits from structured access. If deferred, D-12's OPTIONAL tier handles absence gracefully.
- How to present a failed validation check — ship a default; adjust from real user sessions
- Merge-conflict resolution style when D-19 "merge" encounters duplicate process names — present to user, let them decide rename vs overwrite

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope Authority
- `.planning/v2.0-PROMPT.pdf` — v2.0 ground truth; Business Graph JSON example lives on page 2–3
- `.planning/REQUIREMENTS.md` § Interview Extension (INTV-01..04) + § Business Graph Schema (BGRAPH-01..04)
- `.planning/PROJECT.md` § Current Milestone (three-layer intelligence: Understand / Diagnose / Anticipate)

### v1.0 Artifacts Being Extended
- `.claude/skills/agentbloc/references/phase-1-interview.md` — the 9-category interview being extended. Summary gate is the insertion point.
- `.claude/skills/agentbloc/references/data-classification.md` — feeds the `security_profile` field of the Business Graph
- `.claude/skills/agentbloc/SKILL.md` — Phase 1 entry + gate ritual; add Business Graph validation gate before Phase 2 transition

### Prior Phase Context (carry-forward decisions)
- `.planning/milestones/v1.0-phases/03-interview-and-design-phases/03-CONTEXT.md` — D-01 through D-10 still apply
- `.planning/milestones/v1.0-phases/01-skill-foundation/01-CONTEXT.md` — hybrid loading pattern (D-09), flat references/ directory (D-10 of that phase)

### New File To Be Created (not yet committed — plan-phase will add)
- `.claude/skills/agentbloc/references/business-graph-schema.md` — schema definition + validation checklist (this is the main deliverable of Phase 8)

### Reference Example (for shape testing)
- `.planning/v2.0-PROMPT.pdf` page 2 — Arco Rooms Business Graph JSON example. Use as the canonical shape to validate the schema against.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `references/phase-1-interview.md` (~350 lines): ships with 9 category sections, seed questions, must-know checklists, Summary of Understanding template. **Summary of Understanding Template section** (around line 20 of the Table of Contents) is the exact insertion point for D-11 emission.
- `references/data-classification.md` (138 lines): complete auto-detection keyword lists, compliance activation matrix. The Business Graph `security_profile` field is a JSON-structured version of what this produces.
- `SKILL.md` Phase 1 section: already has gate ritual (`[AGENTBLOC | PHASE: 1 | GATE: ... | TECH: ...]`). Adding a `business_graph_validated` gate value is a vocabulary extension, not a new pattern.

### Established Patterns
- **Hybrid loading (v1.0 D-09):** `phase-1-interview.md` + `data-classification.md` load unconditionally at Phase 1 entry. Phase 8 adds `business-graph-schema.md` to the unconditional load set — minor SKILL.md edit.
- **Running tally pattern (v1.0 D-08):** progressive data classification maintains an internal markdown tally never shown to the user. The Business Graph emission is the moment the tally becomes externalized — from in-conversation-memory to on-disk JSON.
- **Prose-checklist as validator (new pattern, but fits AgentBloc aesthetic):** AgentBloc already uses prose-as-logic elsewhere (gate rituals are prose rules Claude follows deterministically). The validation checklist in `business-graph-schema.md` is the same pattern applied to schema enforcement.

### Integration Points
- `SKILL.md` Phase 1 entry: extend unconditional loading list to include `business-graph-schema.md`
- `SKILL.md` Phase 2 entry: add precondition "verify `.agentbloc/graph/business-graph.json` exists and validates" before allowing transition
- `phase-1-interview.md` Category 7 "Edge Cases and Failures": add one seed question per D-16
- `phase-1-interview.md` Summary of Understanding Template: extend with emission step per D-11, add rendered table format per D-14
- `.agentbloc/graph/` directory: new directory, created on first emission (no pre-existing setup needed)

</code_context>

<specifics>
## Specific Ideas

- **The schema is a contract with Phase 9.** Designer Agent's quality ceiling is determined by how well-structured this Business Graph is. Every field that Designer needs to reason about (topology selection, agent role identification, trigger classification, anticipation heuristics) must be present or derivable. D-12's by-section strictness enumerates exactly what Designer cannot degrade on.
- **The Arco Rooms example in the PDF is the canonical test fixture.** Phase 16 validation will run the interview against Arco Rooms and verify the Business Graph matches the PDF's example shape (give or take minor additive fields). Phase 8 should produce a schema that the PDF's JSON satisfies.
- **The JSON is machine-consumed; the table is human-consumed.** D-14 separation of concerns: never ask a non-technical user to read or edit JSON. Always render, always accept conversational edits, always re-emit.
- **No new category, no new gate vocabulary beyond one value.** The phase is additive, not architectural. SKILL.md gains one new gate value (`business_graph_validated`); the 9-category interview stays nine; the Summary step gains one responsibility.
- **`decision_patterns` is the seed for v2.0's Anticipation Engine (Phase 15).** The explicit rule-capture in Category 7 gives Anticipation enough surface to work from ("user said: if payment > 7 days late → formal notice" signals a compliance-oriented business → anticipate Legal Notice Agent).

</specifics>

<deferred>
## Deferred Ideas

- **External JSON Schema validator (ajv):** deferred. If Phase 9 Designer Agent hits correctness issues from loose validation, revisit in a v2.0 follow-up phase. Phase 16 TAP tests are the current rigor layer.
- **`process.trigger` enum extension (`webhook`, `loop`):** deferred. Add when Phase 11 (Browser Fallback) or Phase 14 (Monitor) actually needs them — additive, no version bump.
- **Business Graph visualization (Mermaid / diagram):** interesting but out of scope. Belongs in Phase 16 or a future milestone when the UI layer matures.
- **Multi-language Business Graph (Spanish field names / localized enum):** not necessary. User-facing content is the rendered table, which can be bilingual. The JSON schema stays in English (universal developer default) — Phase 9 Designer Agent produces bilingual agent profiles from English graph fields.
- **Versioning migration tool:** premature. If/when we ever bump to `schema_version: 2`, write a one-shot migration script then.

</deferred>

---

*Phase: 08-business-graph-foundation*
*Context gathered: 2026-04-20*
*Decision mode: autonomous (Pablo-authorized). All decisions above are mine to defend; Pablo retains veto on any he disagrees with — raise early if so.*
