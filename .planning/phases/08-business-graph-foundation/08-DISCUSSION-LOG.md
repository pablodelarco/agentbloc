# Phase 8: Business Graph Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `08-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 08-business-graph-foundation
**Mode:** Autonomous (per `autonomous_mode` memo saved 2026-04-20; Pablo signaled *"Quiero que seas tu con tu inteligencia el que responda y mejore todas las fases de forma completamente autonoma"*)
**Gray areas analyzed:** Emission mechanism · Schema strictness + versioning · Validator placement · User-facing review

---

## Emission Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Claude writes during Summary gate | JSON produced first; prose summary rendered from JSON. Zero drift risk. No new subagent. Minimal new surface area. | ✓ |
| Separate graph-builder subagent | Dedicated subagent parses transcript to emit JSON. Rigorous but duplicates work (transcript already in main session). | |
| Final prompt with strict format | Claude told "now emit JSON in this exact shape." Less rigorous; prone to format drift. | |

**Decision:** D-11 — emission lives in the Summary gate, no subagent.
**Reasoning:** Reuses existing Summary step. JSON is source of truth; prose is derived. Zero divergence risk.

---

## Schema Strictness + Versioning

| Option | Description | Selected |
|--------|-------------|----------|
| Strict (all fields required) | Validator rejects any incomplete graph. Safest for Designer Agent but brittle — interview can be abandoned at any category. | |
| Forgiving (minimal required) | Only `schema_version` + `business.type` required. Everything else optional. Designer Agent has to degrade across many fields. | |
| By-section (tiered) | REQUIRED / RECOMMENDED / OPTIONAL tiers. Strict on what Designer cannot degrade without (business + processes); forgiving on enrichment fields. | ✓ |

**Decision:** D-12 — by-section strictness. `schema_version` as simple integer, bumped only on breaking changes.
**Reasoning:** Matches Designer Agent's actual needs. Designer cannot produce agents without processes; Designer can synthesize around missing decision_patterns. Integer versioning keeps mental model small for a schema with one in-repo consumer.

---

## Validator Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone skill (`.claude/skills/validate-business-graph/`) | Invokable independently. Reusable from tests. New skill directory; extra surface area. | |
| Built-in gate in SKILL.md Phase 1 Summary | Validation checklist lives in `references/business-graph-schema.md`; Claude walks it during the Summary gate. Honors markdown-only constraint. | ✓ |
| External JSON Schema script (ajv) | Maximally rigorous. Introduces JS/Python runtime dependency — breaks AgentBloc's "markdown-only skill" constraint. | |

**Decision:** D-13 — prose-checklist inside `business-graph-schema.md`, executed at the Summary gate.
**Reasoning:** Fits AgentBloc's aesthetic (prose-as-logic, same as gate rituals). TAP tests in Phase 16 give external rigor without runtime dependency. ajv is deferred as a clean upgrade path if Phase 9+ needs it.

---

## User-Facing Review at Conclusion

| Option | Description | Selected |
|--------|-------------|----------|
| Silent validation | JSON emitted; only surface if validation fails. User never sees the JSON. Risk: user misses errors in the captured data. | |
| Rendered table + hidden JSON emission | Human-readable sections presented for confirmation; JSON written silently. Edits conversational; JSON re-emitted after edits. | ✓ |
| Show raw JSON + ask to confirm | Maximally transparent but hostile to non-technical users (primary audience). | |

**Decision:** D-14 — rendered table review, JSON emission silent.
**Reasoning:** INTV-04 asks for "structured review." Table is what humans can reason about; JSON is what Phase 9 reads. No compromise.

---

## Claude's Discretion

- Exact table rendering format (column order, grouping per section) — ship consistent with v1.0 D-05
- Exact wording of Category 7 edge-case-rule seed question (D-16)
- Whether `security_profile` is a JSON field or prose-only — leaning JSON (as OPTIONAL), Phase 9 Designer benefits from structured access
- Failed-validation prompt style — ship a default; iterate on real user sessions

## Additive Locks (not asked as questions; decided by scope)

- **D-15** — file location `.agentbloc/graph/business-graph.json` (locked by PDF)
- **D-16** — `decision_patterns` capture via new Category 7 seed question (preserves 9-category structure)
- **D-17** — `tools_available` + `channels` extracted from existing Categories 3 + 8 (no new questions)
- **D-18** — `process.trigger.type` bounded enum `{cron, event, manual}` with type-specific required fields
- **D-19** — on re-run with existing graph: default merge (additive); user can choose overwrite
- **D-20** — `process.pain` stays free-text (Designer uses NLU)

## Deferred Ideas

- External JSON Schema validator (ajv) — revisit if Phase 9 needs stricter validation
- `webhook` / `loop` additions to `process.trigger.type` enum — add when actually needed
- Mermaid / visual Business Graph rendering — future milestone
- Spanish-localized JSON schema — unnecessary; table view is bilingual, schema stays English

## Scope Creep Redirected

- **Designer Agent consumption of the graph** → Phase 9 (already scoped)
- **Agent profile YAML generation** → Phase 9
- **Orchestration classification** → Phase 9
- **Business Graph for teams / multi-tenant** → post-v2.0

---

*All autonomous decisions above are open to Pablo's veto. Raise disagreements before Phase 9 plan-phase begins.*
