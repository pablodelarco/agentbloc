# Phase 3: Interview and Design Phases - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Populate `references/phase-1-interview.md` and `references/phase-2-design.md` with the complete conversational protocols that Claude follows during the first two AgentBloc phases. The interview protocol covers 9 categories with adaptive questioning and progressive data classification. The design protocol covers agent identification, topology selection, contracts, governance, and blast-radius scoring. Both files must integrate with the security reference files created in Phase 2.

</domain>

<decisions>
## Implementation Decisions

### Interview Question Strategy
- **D-01:** Hybrid navigation: each of the 9 categories has 2-3 mandatory seed questions, then Claude branches adaptively based on answers. Guaranteed minimum coverage with flexibility to follow the conversation.
- **D-02:** Internal checklist for completion: each category has 3-5 "must-know" items. Claude tracks them silently. When all are covered (through any question path), the category is done. User never sees the checklist.
- **D-03:** Strictly one question per turn. Always. Matches INTV-02. Non-technical users don't get overwhelmed.
- **D-04:** Soft framing at start of interview: "I'll ask about 15-25 questions across 9 areas to fully understand your workflow." No further progress tracking during the interview.

### Design Output Format
- **D-05:** Both table overview + expandable cards. First show a summary table of the full agent team (Name, Role, Inputs, Outputs, Blast-Radius, Model), then detail each agent individually with a full contract card (name, role description, inputs/outputs, tools/integrations, trigger/schedule, blast-radius level, model recommendation, failure handling).
- **D-06:** Both ASCII + Mermaid for topology diagram. ASCII inline in conversation for immediate readability, Mermaid in deployment artifacts for documentation/GitHub rendering.
- **D-07:** Topology recommendation with rationale: Claude analyzes the workflow and recommends one topology (pipeline/mesh/hierarchy/swarm) with a brief explanation why. User can override.

### Security Handoff Points
- **D-08:** Progressive data classification throughout the entire interview, not limited to the Data category. Any data mention in any category triggers classification (a name in "People" triggers PII, a payment in "Services" triggers financial). Running tally updated continuously using auto-detection patterns from references/data-classification.md.
- **D-09:** Blast-radius auto-scored with override: Claude assigns blast-radius level per agent automatically based on its tools/permissions during design. Shown in the agent card. User can override ("this agent should be read-only, not write-scoped").
- **D-10:** Interview summary includes an integrated "Security Profile" section: data classes found, compliance regimes activated (GDPR/HIPAA/PCI), and implications for the design phase. Security is part of the workflow summary, not a separate concern.

### Claude's Discretion
- How CrewAI/LangGraph/n8n framework patterns are woven into design decisions (explicit references, implicit influence, or contextual comparison depending on user's tech level)
- Exact seed questions per interview category (as long as 2-3 mandatory seeds exist per category)
- Exact must-know checklist items per category (as long as 3-5 items per category)
- Agent card formatting and Mermaid diagram style
- How to handle interview categories that overlap (e.g., data mentions in Services vs Data category)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Stub Files (to populate)
- `references/phase-1-interview.md` -- Interview protocol stub with 9 category sections to fill
- `references/phase-2-design.md` -- Design protocol stub to fill with agent identification, topology, contracts, governance

### Security References (populated in Phase 2, consumed by these protocols)
- `references/data-classification.md` -- PII/PHI/financial/public categories, auto-detection keywords, compliance activation matrix
- `references/blast-radius.md` -- 4-level scoring system, approval matrix, permission minimization checklist
- `references/credentials.md` -- Credential decision tree (referenced during design governance specs)
- `references/audit-logging.md` -- Audit logging patterns (referenced during design governance specs)
- `references/gdpr-patterns.md` -- GDPR/HIPAA/PCI compliance patterns (activated by data classification)

### Framework Patterns (referenced during design)
- `references/frameworks.md` -- CrewAI, LangGraph, n8n pattern references (stub, populated in Phase 3 or left as Claude's discretion)

### Existing Skill Hub
- `SKILL.md` -- Phase summaries and hybrid loading instructions that point to these reference files
- `examples/arco-rooms.md` -- Reference implementation demonstrating all 11 AgentBloc patterns

### Requirements
- `.planning/REQUIREMENTS.md` -- INTV-01..04 and DESG-01..08 acceptance criteria
- `.planning/ROADMAP.md` -- Phase 3 success criteria (5 items)

### Prior Phase Context
- `.planning/phases/01-skill-foundation/01-CONTEXT.md` -- D-09 (hybrid loading), D-10 (flat references/), D-07 (5+1 phases)
- `.planning/phases/02-security-cross-cutting-references/02-CONTEXT.md` -- D-04 (compliance activation model), D-05 (GDPR scope)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `references/phase-1-interview.md` (48 lines) -- Stub with 9 category section headers already in place. Content goes under each existing heading.
- `references/phase-2-design.md` (11 lines) -- Minimal stub with purpose statement. Needs full structure added.
- `references/data-classification.md` (138 lines) -- Complete auto-detection keyword lists (bilingual EN/ES), compliance activation matrix, retention schedules. Interview protocol must reference this during progressive classification.
- `references/blast-radius.md` (129 lines) -- 4-level scoring with approval matrix and agent.yaml template. Design protocol must reference this during agent card generation.

### Established Patterns
- Security reference files use pragmatic format: table of contents, "When This Applies" section, decision trees, quick reference tables. Interview and design protocols should follow a similar structure.
- SKILL.md hybrid loading: "You MUST read the complete interview protocol before asking any questions: See [references/phase-1-interview.md](...)" -- the reference files are loaded at phase entry, not piecemeal.

### Integration Points
- SKILL.md line 92: "You MUST read the complete interview protocol before asking any questions" -- phase-1-interview.md is loaded in full at Phase 1 entry
- SKILL.md line 94-95: "If the user's data involves PII, PHI, or financial information, also read: references/data-classification.md" -- but with progressive classification (D-08), this should trigger during interview, not after
- SKILL.md line 101: "You MUST read the complete design protocol before starting this phase" -- phase-2-design.md loaded at Phase 2 entry

</code_context>

<specifics>
## Specific Ideas

- Progressive classification (D-08) is the most architecturally interesting decision. It means data-classification.md must be loaded at interview start (not conditionally after data is found), because classification happens throughout all 9 categories. The SKILL.md conditional loading ("If the user's data involves PII...") may need adjustment to always load data-classification.md during interview.
- The "both table + cards" design format (D-05) gives non-technical users a quick overview and developers the full picture. The summary table serves as the Phase 2 gate artifact -- user approves the team composition before diving into individual agent cards.
- Framework patterns (CrewAI/LangGraph/n8n) are Claude's discretion per D-07 from Phase 1 context. The design protocol should have a section that references frameworks.md but lets Claude decide how heavily to integrate patterns based on the user's tech level and workflow complexity.

</specifics>

<deferred>
## Deferred Ideas

- Framework comparison matrix as a standalone reference (if the user wants explicit CrewAI vs LangGraph comparison during design, that could be its own reference file -- currently left to Claude's discretion)

</deferred>

---

*Phase: 03-interview-and-design-phases*
*Context gathered: 2026-04-14*
