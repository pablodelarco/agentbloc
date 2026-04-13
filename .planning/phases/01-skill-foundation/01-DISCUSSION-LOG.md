# Phase 1: Skill Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-13
**Phase:** 01-skill-foundation
**Areas discussed:** Hub vs references split, State protocol design, Phase naming + numbering, Reference loading

---

## Hub vs References Split

### Hub content

| Option | Description | Selected |
|--------|-------------|----------|
| Identity + gates + summaries | Keep: identity/persona, hard gates, 1-paragraph phase summaries with @reference pointers. Move all detail to references/. Leanest option (~200 lines). | ✓ |
| Identity + gates + Phase 1 full | Keep Phase 1 (Interview) inline since it's always the entry point. Other phases as summaries + pointers. (~250 lines). | |
| Everything except templates | Keep phase specs inline, move only artifact templates and reference material. Closer to current structure (~350 lines, over budget). | |

**User's choice:** Identity + gates + summaries (leanest option)
**Notes:** None

### Arco Rooms

| Option | Description | Selected |
|--------|-------------|----------|
| Move to examples/ | Move to examples/arco-rooms.md. SKILL.md just mentions it exists. | ✓ |
| Remove entirely | Drop it from the skill. Build proper examples in Phase 6 instead. | |
| Keep as pattern lib | Inline the patterns (not the specific case) as a reference table in SKILL.md | |

**User's choice:** Move to examples/
**Notes:** None

---

## State Protocol Design

### Visibility

| Option | Description | Selected |
|--------|-------------|----------|
| Always visible | User sees [AGENTBLOC | PHASE: 1 | GATE: pending | TECH: basic] at top of every response. Full transparency. | |
| Visible but styled | Rendered as a subtle header bar: Phase 1: Interview | Gate: pending | Level: basic. Less technical-looking. | ✓ |
| Internal only | Claude tracks state internally but doesn't show it to user. Cleaner UX but loses the transparency differentiator. | |

**User's choice:** Visible but styled
**Notes:** None

### Tech levels

| Option | Description | Selected |
|--------|-------------|----------|
| 3 levels | non-technical / technical-basics / developer. Simple, covers the spectrum. | ✓ |
| 4 levels | non-technical / business-ops / technical / developer. Distinguishes ops people. | |
| 2 levels | simplified / technical. Binary choice, less nuance but simpler to implement. | |

**User's choice:** 3 levels
**Notes:** None

### Gate values

| Option | Description | Selected |
|--------|-------------|----------|
| 3 states | pending / approved / blocked. Minimal, clear. | ✓ |
| 4 states | pending / in-progress / approved / blocked. Distinguishes working from waiting. | |
| 2 states | open / approved. Binary. | |

**User's choice:** 3 states
**Notes:** None

---

## Phase Naming + Numbering

### Phase count

| Option | Description | Selected |
|--------|-------------|----------|
| 6 phases | Interview, Design, Integration, Confirmation+DryRun, Deployment, Evolution. | |
| 7 phases | Interview, Design, Integration, Confirmation, Dry Run, Deployment, Evolution. | |
| 5+1 phases | Core 5 + Evolution (post-deploy, separate lifecycle). Matches original description. | ✓ |

**User's choice:** 5+1 phases
**Notes:** None

### Phase labels

| Option | Description | Selected |
|--------|-------------|----------|
| Numbers + names | Phase 1: Deep Interview, Phase 2: General Design, etc. | ✓ |
| Names only | Interview, Design, Integration Analysis, etc. | |
| Emoji + names | Visual markers for non-technical users. | |

**User's choice:** Numbers + names
**Notes:** None

---

## Reference Loading

### Loading strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit @ references | Each phase summary ends with @references/phase-N.md. Auto-loaded. Most reliable. | |
| Read-file instruction | Natural language: "Before starting, read references/phase-N.md". Less reliable. | |
| Hybrid | Both: natural instruction + @reference as fallback. Belt and suspenders. | ✓ |

**User's choice:** Hybrid
**Notes:** None

### Nesting

| Option | Description | Selected |
|--------|-------------|----------|
| One level deep only | References point to SKILL.md's references/. No nested references. | ✓ |
| Two levels allowed | Phase refs can reference security/ sub-refs. Risk of partial loading. | |
| Flat directory | All reference files at references/ root level. No subdirectories. | |

**User's choice:** One level deep only (flat references/ directory)
**Notes:** None

## Claude's Discretion

- Exact wording of the styled state bar
- Internal implementation of context refresh at phase boundaries
- Exact line count of SKILL.md

## Deferred Ideas

None -- discussion stayed within phase scope
