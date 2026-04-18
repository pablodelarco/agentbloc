# Phase 3: Interview and Design Phases - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 03-interview-and-design-phases
**Areas discussed:** Interview question strategy, Design output format, Security handoff points

---

## Interview Question Strategy

### Category navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Adaptive flow | Claude has seed questions per category but follows conversation naturally. Categories tracked internally. | |
| Fixed question tree | Each category has predefined questions asked in order. | |
| Hybrid: seeds + branching | 2-3 mandatory seed questions per category, then adaptive branching. Guaranteed minimum coverage. | ✓ |

**User's choice:** Hybrid: seeds + branching
**Notes:** None

### Category completion

| Option | Description | Selected |
|--------|-------------|----------|
| Internal checklist | Each category has 3-5 must-know items tracked silently. | ✓ |
| Explicit confirmation per category | Summarize and ask after each category. | |
| Summary gate at end | Single comprehensive summary covering all 9 categories. | |

**User's choice:** Internal checklist
**Notes:** None

### Questions per turn

| Option | Description | Selected |
|--------|-------------|----------|
| Strictly one | One question per turn, always. Matches INTV-02. | ✓ |
| One, bundle related | Usually one, up to 2 for tightly related sub-questions. | |
| Adaptive by tech level | One for non-technical, 2-3 for developers. | |

**User's choice:** Strictly one
**Notes:** None

### Length indicator

| Option | Description | Selected |
|--------|-------------|----------|
| No indicator | Flow naturally with no length expectations. | |
| Category progress only | Show which area you're in: "4 of 9 areas covered". | |
| Soft framing at start | "I'll ask about 15-25 questions across 9 areas." Then no tracking. | ✓ |

**User's choice:** Soft framing at start
**Notes:** None

---

## Design Output Format

### Agent detail level

| Option | Description | Selected |
|--------|-------------|----------|
| Full contract card | Each agent gets structured block with all fields. | |
| Summary table only | All agents in one table. Less detail, faster. | |
| Both: table + cards | Summary table first, then individual agent cards. | ✓ |

**User's choice:** Both: table overview + expandable cards
**Notes:** None

### Topology diagram format

| Option | Description | Selected |
|--------|-------------|----------|
| ASCII box diagram | Text-based, works in any terminal. | |
| Mermaid syntax | Renders in GitHub/markdown viewers. | |
| Both ASCII + Mermaid | ASCII inline, Mermaid in deployment artifacts. | ✓ |

**User's choice:** Both ASCII + Mermaid
**Notes:** None

### Topology selection presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Recommend with rationale | Claude recommends one topology with explanation. User can override. | ✓ |
| Compare options | Present 2-3 viable topologies with pros/cons. User picks. | |
| Just pick it | Claude selects silently, surfaces as fact in output. | |

**User's choice:** Recommend with rationale
**Notes:** None

---

## Security Handoff Points

### Data classification timing

| Option | Description | Selected |
|--------|-------------|----------|
| Inline during Data category | Classify during interview categories 4-5. | |
| Separate pass after interview | Complete all 9 categories, then dedicated analysis. | |
| Progressive classification | Classify as data mentions appear throughout ALL categories. Running tally. | ✓ |

**User's choice:** Progressive classification
**Notes:** None

### Blast-radius in design

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-scored with override | Claude assigns level automatically, shown in card. User can override. | ✓ |
| Explicit scoring conversation | After each agent, Claude asks about the scoring. | |
| Silent, flag only high-risk | Score silently, surface only Level 3-4 requiring approval. | |

**User's choice:** Auto-scored with override
**Notes:** None

### Security in interview summary

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, integrated | Summary includes "Security Profile" section with data classes, compliance regimes, implications. | ✓ |
| Separate security brief | Standalone security analysis after summary. | |
| No explicit section | Security feeds silently into design. | |

**User's choice:** Yes, integrated
**Notes:** None

## Claude's Discretion

- How CrewAI/LangGraph/n8n framework patterns integrate into design (explicit references, implicit influence, or contextual)
- Exact seed questions per interview category
- Exact must-know checklist items per category
- Agent card formatting and Mermaid diagram style

## Deferred Ideas

- Framework comparison matrix as standalone reference file
