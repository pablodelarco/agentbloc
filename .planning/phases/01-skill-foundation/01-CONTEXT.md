# Phase 1: Skill Foundation - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Restructure SKILL.md from a monolithic 539-line file into a lean ~200-250 line hub with structural gate enforcement, progressive disclosure via references/, bilingual support (EN/ES), technical-level detection, context refresh at phase boundaries, and phase loopback protocol. This is the foundation that every subsequent phase depends on.

</domain>

<decisions>
## Implementation Decisions

### Hub vs References Split
- **D-01:** SKILL.md hub contains ONLY: identity/persona, hard gate definitions, 1-paragraph phase summaries with reference pointers, state protocol definition, language/tech-level detection rules. Target ~200 lines.
- **D-02:** All detailed phase procedures, question lists, output formats, artifact templates, and quality checklists move to individual reference files in references/.
- **D-03:** Arco Rooms reference implementation section moves to examples/arco-rooms.md. SKILL.md mentions it exists but does not inline the content.

### State Protocol Design
- **D-04:** State line is VISIBLE to users but rendered as a styled header bar, not raw brackets. Format: `Phase 1: Deep Interview | Gate: pending | Level: basic`. Less technical-looking, maintains the transparency differentiator.
- **D-05:** Three technical levels: `non-technical`, `technical-basics`, `developer`. Assessed in the first interaction and carried throughout all phases.
- **D-06:** Three gate states: `pending` (working in this phase), `approved` (gate cleared, ready for next), `blocked` (issue prevents progression).

### Phase Naming + Numbering
- **D-07:** The skill defines 5+1 conversational phases (distinct from the 7 GSD roadmap build phases):
  - Phase 1: Deep Interview
  - Phase 2: General Design
  - Phase 3: Deep Integration Analysis
  - Phase 4: Step-by-Step Confirmation + Dry Run (merged)
  - Phase 5: Deployment
  - Phase 6: Evolution (post-deploy, separate lifecycle)
- **D-08:** Phases are labeled with number + name in the state bar and conversation: "Phase 1: Deep Interview", "Phase 2: General Design", etc.

### Reference Loading Strategy
- **D-09:** Hybrid loading: each phase summary in SKILL.md includes BOTH a natural-language instruction ("Before starting this phase, read the interview guide") AND an explicit @reference path as fallback. Belt and suspenders for reliability.
- **D-10:** Reference files are ONE level deep only. No nested references from within reference files. Claude Code docs confirm nested refs are only partially read. All references live at references/ root level (flat directory within references/).
- **D-11:** Security reference files also at references/ root (e.g., references/credentials.md, references/data-classification.md, references/blast-radius.md) not in a security/ subdirectory.

### Claude's Discretion
- Exact wording of the styled state bar (as long as it contains phase number, phase name, gate status, and tech level)
- Internal implementation of context refresh at phase boundaries (how to re-anchor critical instructions)
- Exact line count of SKILL.md (target ~200, hard cap 250)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Skill (to restructure)
- `SKILL.md` -- Current 539-line monolithic skill file; the raw material being restructured
- `enterprise-readiness.md` -- 18-gap audit with recommended file structure and prioritized fixes

### Research Findings
- `.planning/research/ARCHITECTURE.md` -- Progressive disclosure patterns, state machine design, build order
- `.planning/research/STACK.md` -- Claude Code skill architecture best practices, MCP ecosystem
- `.planning/research/PITFALLS.md` -- Context rot (#1 risk), activation failure, execution drift prevention
- `.planning/research/SUMMARY.md` -- Key findings synthesis with phase structure recommendations

### Requirements
- `.planning/REQUIREMENTS.md` -- ARCH-01 through ARCH-08 define Phase 1 acceptance criteria
- `.planning/ROADMAP.md` -- Phase 1 success criteria (5 items)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SKILL.md` -- Identity section (~16 lines), hard gates section (~11 lines), and language rules (~4 lines) can be preserved mostly as-is in the hub
- `SKILL.md` -- Phase flow diagram (lines 46-48) is a compact summary worth keeping in the hub
- `enterprise-readiness.md` -- Recommended file structure (lines 268-306) provides the target directory layout

### Established Patterns
- Current SKILL.md already uses YAML frontmatter (name, description) -- keep and enhance with version field
- Hard gates are defined as a `<HARD-GATE>` block -- restructure as numbered rules but keep the content
- Phase flow uses `INTERVIEW -> DESIGN -> ANALYSIS -> CONFIRMATION -> DEPLOYMENT` diagram -- extend to 5+1

### Integration Points
- SKILL.md frontmatter `description` field is the activation trigger -- must be rewritten for the model (3rd person, front-load use case)
- references/ files will be loaded by Claude Code's @reference mechanism -- test loading behavior
- The skill must work when installed at .claude/skills/agentbloc/ in any project

</code_context>

<specifics>
## Specific Ideas

- The enterprise-readiness.md recommends the [PHASE: N | GATE: X] ritual but the user prefers a STYLED version rather than raw brackets. The state bar should feel professional, not like a debug log.
- User explicitly wants 5+1 phases, matching their original product description. Phase 6 (Evolution) is a post-deploy lifecycle, not part of the core onboarding flow.
- Flat references/ directory (no subdirectories) is a firm constraint. Security files live at references/credentials.md not references/security/credentials.md. This contradicts the enterprise-readiness.md recommendation but is the right call for Claude Code loading reliability.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 01-skill-foundation*
*Context gathered: 2026-04-13*
