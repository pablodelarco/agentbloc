# Architecture Patterns

**Domain:** Claude Code multi-phase conversational skill (agent team designer & deployer)
**Researched:** 2026-04-13

## Recommended Architecture

AgentBloc is a pure Claude Code skill (markdown files only, no TypeScript runtime) that drives a 6-phase conversational flow and generates deployment artifacts. The architecture must solve four simultaneous problems:

1. **Context efficiency** -- keep the skill's token footprint small while encoding deep procedural knowledge across 6 phases
2. **Phase enforcement** -- prevent Claude from skipping or reordering phases during a conversation
3. **Artifact generation** -- produce a structured `.agentbloc/` directory of YAML configs, skill markdown, and state schemas
4. **User adaptation** -- serve non-technical and technical users without separate codepaths

The recommended architecture is a **hub-and-spoke progressive disclosure pattern** with a **conversation-embedded state machine** and **template-driven artifact generation**.

```
.claude/skills/agentbloc/
|
|-- SKILL.md                          # Hub (~200-250 lines)
|   |                                    Level 2: loaded on trigger
|   |-- [identity, phase overview, gates, state protocol, pointers]
|   |
|   |-- references/                   # Spokes (loaded on demand)
|   |   |                                Level 3: loaded per-phase
|   |   |-- phase-1-interview.md
|   |   |-- phase-2-design.md
|   |   |-- phase-3-integration.md
|   |   |-- phase-4-confirmation.md
|   |   |-- phase-4.5-dry-run.md
|   |   |-- phase-5-deployment.md
|   |   |-- phase-6-evolution.md
|   |   |-- security/
|   |   |   |-- credentials.md
|   |   |   |-- data-classification.md
|   |   |   |-- blast-radius.md
|   |   |   |-- audit-logging.md
|   |   |   |-- prompt-injection.md
|   |   |   |-- gdpr-patterns.md
|   |   |   |-- incident-response-template.md
|   |   |   +-- tenant-isolation.md
|   |   |-- frameworks.md
|   |   |-- telegram-patterns.md
|   |   |-- scheduling.md
|   |   |-- glossary-en.md
|   |   +-- glossary-es.md
|   |
|   |-- templates/                    # Artifact skeletons (assets, not loaded into context)
|   |   |-- team.yaml.tmpl
|   |   |-- agent.yaml.tmpl
|   |   |-- agent-skill.md.tmpl
|   |   |-- governance.yaml.tmpl
|   |   |-- telegram.yaml.tmpl
|   |   |-- state-schema.json.tmpl
|   |   |-- job.md.tmpl
|   |   +-- incident-response.md.tmpl
|   |
|   |-- examples/                     # Gold-standard walkthroughs
|   |   |-- arco-rooms-walkthrough.md
|   |   |-- ecommerce-support.md
|   |   |-- freelance-pipeline.md
|   |   +-- legal-triage.md
|   |
|   +-- tests/
|       +-- scenarios/                # Replayable test scripts
|           |-- ecommerce-cs.jsonl
|           |-- real-estate-ops.jsonl
|           |-- healthcare-intake.jsonl
|           +-- legal-triage.jsonl
```

### Why This Layout

The Anthropic skill best-practices documentation (platform.claude.com) is explicit:

- **SKILL.md body under 500 lines** for optimal performance. The current 539-line monolith violates this. Target ~200-250 lines.
- **One level of reference depth.** All reference files link directly from SKILL.md. Never chain references/a.md -> references/b.md -> references/c.md. Claude partially reads nested files (uses `head -100`), causing incomplete information.
- **Three loading tiers.** Metadata (always in context, ~100 words), SKILL.md body (loaded on trigger, ~200-250 lines), reference files (loaded on demand, unlimited size).
- **Templates directory as assets.** Template files are never loaded into context -- Claude reads them only during Phase 5 artifact generation. This keeps context clean during Phases 1-4.
- **Examples directory.** Claude pattern-matches against gold-standard walkthroughs. Load only the most relevant example per session (e.g., if the user describes real estate ops, load arco-rooms-walkthrough.md).

### Component Boundaries

| Component | Responsibility | Loaded When | Communicates With |
|-----------|---------------|-------------|-------------------|
| SKILL.md (hub) | Identity, phase summary, gate protocol, state machine rules, reference pointers | Skill trigger | All reference files (one-level-deep pointers) |
| phase-N-*.md (spokes) | Detailed phase procedures, question sets, output formats, quality checklists | Claude enters that phase | SKILL.md (reads back for gate protocol), security/*.md (cross-referenced), templates/ (Phase 5 only) |
| security/*.md | Security governance patterns (credentials, data classification, blast radius, audit, GDPR, prompt injection) | Any phase touching data/integrations/deployment | phase-2, phase-3, phase-5 |
| frameworks.md | Pattern library from CrewAI/LangGraph/AutoGen/n8n | Phase 2 (design decisions) | phase-2-design.md |
| glossary-{lang}.md | Plain-language definitions for non-tech users | First interview question detects tech level | All phases (language adaptation) |
| templates/*.tmpl | Artifact skeletons with placeholder syntax | Phase 5 (artifact generation) | phase-5-deployment.md |
| examples/*.md | Complete end-to-end walkthroughs | When Claude needs a reference pattern | Any phase (pattern matching) |
| tests/scenarios/*.jsonl | Replayable user-turn sequences | Testing/evaluation only | External evaluation harness |

### Data Flow

```
USER MESSAGE
     |
     v
[SKILL.md body - always active after trigger]
     |
     |-- Detects current phase from conversation state
     |-- Reads the relevant phase-N reference file
     |-- Optionally reads security/*.md or glossary-*.md
     |
     v
[PHASE LOGIC in references/phase-N-*.md]
     |
     |-- Executes phase-specific procedures
     |-- Produces phase output (summary, design, analysis, etc.)
     |-- Evaluates gate criteria
     |
     v
[GATE CHECK - enforced by state protocol in SKILL.md]
     |
     |-- If gate NOT met: stay in current phase
     |-- If gate MET + user approval: advance phase counter
     |
     v
[NEXT PHASE or ARTIFACT GENERATION]
     |
     |-- Phase 5: reads templates/*.tmpl
     |-- Generates .agentbloc/ directory tree
     |-- Writes files to user's project
```

---

## Pattern 1: Progressive Disclosure (File Organization)

### What
SKILL.md serves as a table of contents. Phase details, security guidance, templates, and examples live in separate files loaded on demand. This is the official Anthropic-recommended pattern for skills exceeding 200 lines.

### When
Always. This is not optional for a 6-phase skill. The current 539-line monolith would be 1500+ lines with all the missing enterprise-readiness content.

### Implementation

**SKILL.md structure (~200-250 lines):**

```markdown
---
name: agentbloc
description: >
  Designs and deploys AI agent teams for businesses through a 6-phase
  conversational flow. Guides users from manual process description to
  deployed agent team with YAML configs, skill files, and governance.
  Use when the user wants to automate a business workflow, create AI agents,
  design an agent team, or says /agentbloc. Also activates for "automatizar",
  "crear agentes", "agent team", "automate my business".
---

# AgentBloc -- AI Agent Team Designer

[Identity section: 15-20 lines. Senior AI solutions architect persona.]

## State Protocol

[State machine rules: 20-30 lines. See Pattern 2 below.]

## Hard Gates

[5 immutable rules: 15-20 lines. Structural, not prose.]

## Phase Overview

### Phase 1: Deep Interview
[3-5 line summary + pointer]
For detailed procedures: See [references/phase-1-interview.md](references/phase-1-interview.md)

### Phase 2: Agent Team Design
[3-5 line summary + pointer]
For detailed procedures: See [references/phase-2-design.md](references/phase-2-design.md)

[... repeat for all 6 phases ...]

## Security (Cross-Phase)

When any phase involves credentials, sensitive data, or external integrations:
- Credential handling: See [references/security/credentials.md](references/security/credentials.md)
- Data classification: See [references/security/data-classification.md](references/security/data-classification.md)
[... pointers to all security references ...]

## User Adaptation

Detect technical level in first exchange. Adapt language accordingly.
- Glossary (English): See [references/glossary-en.md](references/glossary-en.md)
- Glossary (Spanish): See [references/glossary-es.md](references/glossary-es.md)

## Quality Checklist

[10-line universal checklist applying to all phases]
```

### Why This Specific Organization

1. **Phase files are the primary spokes.** Each phase is self-contained with its own procedures, question sets, output formats, and quality gates. Claude loads only the active phase.
2. **Security files are cross-cutting.** They are referenced from multiple phases (Phase 1 for data classification questions, Phase 2 for blast-radius analysis, Phase 3 for integration trust scores, Phase 5 for governance artifact generation). Separate files avoid duplication.
3. **Templates are assets, not references.** They contain YAML/markdown skeletons with placeholders. Claude reads them during Phase 5 only, then fills in the blanks. They never need to be in context during Phases 1-4.
4. **Glossaries enable user adaptation.** When Claude detects a non-technical user, it loads the glossary once and uses it throughout the session. Technical users never trigger this load.

**Confidence: HIGH** -- This pattern is directly documented in Anthropic's official skill authoring best practices (platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) and demonstrated in Anthropic's own skill-creator reference implementation.

---

## Pattern 2: Conversation-Embedded State Machine (Phase Management)

### What
A structural ritual where Claude prefixes every response with a phase/gate marker, creating a visible state machine embedded in the conversation itself. The conversation IS the state -- no external state file needed during the design flow.

### When
Every response within an active AgentBloc session. This is the primary enforcement mechanism for phase gates.

### Implementation

**State protocol (in SKILL.md):**

```markdown
## State Protocol

Every response in an AgentBloc session MUST begin with a state line:

[AGENTBLOC | PHASE: {N} | GATE: {status} | TECH: {level}]

Where:
- PHASE: 1-6 (current phase number)
- GATE: pending | approved | loopback:{target_phase}
- TECH: non-technical | basics | developer (detected in Phase 1, fixed thereafter)

### Phase Transitions

A phase transition occurs ONLY when ALL conditions are met:
1. The current phase's completion criteria are satisfied (documented in each phase reference)
2. The gate output has been presented to the user
3. The user has explicitly approved ("yes", "approved", "ok", "adelante", or equivalent)
4. The state line updates to the next phase number

### Loopback Protocol

If information discovered in Phase N invalidates an approved gate from Phase M (where M < N):
1. Set GATE to loopback:{M}
2. Explain what changed and why the earlier phase needs revision
3. Return to Phase M and re-run its gate
4. Re-approve all phases from M through N-1 before continuing

### Context Compaction Safety

After /compact or auto-compaction, Claude re-reads SKILL.md and reconstructs
the current phase from conversation context. The state line in the most recent
response is the source of truth.
```

### Why Conversation-Embedded (Not File-Based)

Claude Code skills operate within a single conversation session. There is no persistent state between messages beyond what exists in the conversation history and the filesystem. Three approaches were considered:

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Conversation-embedded state line** | Zero filesystem overhead; survives compaction (state line is in recent messages); visible to user; self-documenting | Relies on Claude following the ritual; no external enforcement | **Use this.** Skills are markdown instructions, not code. The ritual is the enforcement. |
| **Filesystem state file** (.agentbloc/state.json) | Machine-readable; persists across sessions | Premature (artifacts only exist after Phase 5); file mutations during design phases create confusion; extra tool calls | Reject for design flow. Use only for deployed agent state. |
| **CLAUDE.md / MEMORY.md injection** | Loaded automatically on session start | Limited to 200 lines / 25KB; pollutes global config; not scoped to skill | Reject. |

The conversation-embedded approach is the right tradeoff because:
1. The AgentBloc flow is inherently conversational -- the conversation IS the primary artifact during Phases 1-4.
2. Claude Code re-attaches skill context after compaction (first 5,000 tokens of the most recently invoked skill). The state line in the last response survives this.
3. External state files add complexity without benefit during the design phases. The filesystem should only be touched during Phase 5 (artifact generation).

**Confidence: MEDIUM** -- This pattern is recommended in the enterprise-readiness audit and aligns with community patterns for workflow skills. No official Anthropic documentation prescribes a specific state management approach for multi-phase skills. The `[PHASE: N | GATE: X]` ritual is a common community pattern.

---

## Pattern 3: Template-Driven Artifact Generation

### What
Phase 5 (Deployment) reads template files from `templates/` and populates them with data gathered across Phases 1-4. The templates are YAML/markdown skeletons with clearly marked placeholders. Claude fills in the placeholders and writes the complete files to the user's `.agentbloc/` directory.

### When
Phase 5 only. Templates are never loaded into context before Phase 5.

### Implementation

**Template format (e.g., templates/team.yaml.tmpl):**

```yaml
# AgentBloc Team Configuration
# Generated by AgentBloc v{version}
# Date: {generated_date}

name: {team_name}
description: {team_description}
topology: {topology}  # pipeline | mesh | hierarchy | swarm
schedule: "{cron_expression}"
notify: {notify_level}  # error | always | summary

telegram:
  thread_layout: {thread_layout}  # domain | agent
  threads:
    # {for each thread}
    {thread_id}:
      name: "{thread_emoji} {thread_name}"
      agents: [{thread_agents}]

agents:
  # {for each agent}
  - name: {agent_name}
    ref: agents/{agent_name}.yaml

phases:
  # {for each phase gate}
  - agent: {agent_name}
    gate: "{gate_condition}"
    on_fail: {on_fail}  # retry | escalate | skip
    max_retries: {max_retries}

governance:
  ref: governance.yaml
```

**Output structure (.agentbloc/ directory):**

```
.agentbloc/
|-- team.yaml                       # Team definition (from team.yaml.tmpl)
|-- agents/
|   |-- {agent-name}.yaml           # Per-agent contract (from agent.yaml.tmpl)
|   +-- ...
|-- skills/
|   |-- {agent-name}.md             # Per-agent behavior (from agent-skill.md.tmpl)
|   +-- ...
|-- integrations/
|   |-- {service-name}.md           # Integration setup instructions
|   +-- ...
|-- jobs/
|   +-- {team-name}-{schedule}.md   # ClaudeClaw job (from job.md.tmpl)
|-- state/
|   +-- {provider}-state.json       # State tracking (from state-schema.json.tmpl)
|-- governance.yaml                 # Budgets, permissions, audit (from governance.yaml.tmpl)
|-- telegram.yaml                   # Thread layout (from telegram.yaml.tmpl)
|-- INCIDENT_RESPONSE.md            # Incident runbook (from incident-response.md.tmpl)
+-- SUMMARY.md                      # Deployment guide (generated, no template)
```

### Why Templates, Not Inline Generation

1. **Consistency.** Every AgentBloc deployment follows the same schema. Templates enforce structure that inline generation might drift from.
2. **Maintainability.** Updating a template field (e.g., adding a new governance field) propagates to all future deployments without changing SKILL.md.
3. **Zero context cost during Phases 1-4.** Templates sit as assets. Only Phase 5 reference reads them.
4. **Separation of concerns.** The phase reference (phase-5-deployment.md) documents the generation PROCEDURE. The templates document the generation STRUCTURE. Different things change for different reasons.

**Confidence: MEDIUM** -- Anthropic's docs explicitly support templates as "assets" in the `assets/` directory. The specific template format (YAML with `{placeholder}` syntax) is a pragmatic choice. Claude understands placeholder syntax natively; no custom parser needed.

---

## Pattern 4: Cross-Cutting Security References

### What
Security is not a single phase -- it cross-cuts Phases 1-5. Rather than duplicating security guidance in each phase file, security concerns are extracted into focused reference files that multiple phases reference.

### When
- **Phase 1 (Interview):** References `data-classification.md` to ask the right questions
- **Phase 2 (Design):** References `blast-radius.md` and `credentials.md` for design decisions
- **Phase 3 (Integration):** References `prompt-injection.md` and `credentials.md` for trust scoring
- **Phase 4.5 (Dry Run):** References `audit-logging.md` for test observation
- **Phase 5 (Deployment):** References all security files for governance.yaml generation
- **Phase 6 (Evolution):** References `tenant-isolation.md` and `gdpr-patterns.md` for compliance monitoring

### Implementation

Each phase reference file contains a security callout section:

```markdown
## Security Checkpoint

Before completing this phase, verify:

**If data classification includes PII/PHI/financial:**
- Read [references/security/data-classification.md](../security/data-classification.md)
- Apply mandatory GDPR/HIPAA/PCI patterns from [references/security/gdpr-patterns.md](../security/gdpr-patterns.md)

**If design includes write/delete/send-external capabilities:**
- Read [references/security/blast-radius.md](../security/blast-radius.md)
- Score each agent and force approval gate for high-risk agents
```

This is NOT nested referencing (which Anthropic warns against). SKILL.md points to phase files. Phase files contain the security callout text inline, with paths that Claude can choose to follow. The security files themselves never reference other files.

**Confidence: HIGH** -- The cross-cutting nature of security is a well-established pattern. The enterprise-readiness audit explicitly identifies 8 security sub-domains that affect multiple phases.

---

## Pattern 5: User Adaptation via Conditional Loading

### What
First interaction detects the user's technical level (non-technical / basics / developer) and language. This determines:
- Whether to load glossary files
- How much detail to show vs. hide
- What vocabulary to use in explanations

### When
First exchange in Phase 1. The TECH field in the state line is fixed for the session once detected.

### Implementation

```markdown
## User Adaptation

### Detection (First Exchange)
Before any interview questions, determine:
1. **Language:** Respond in whatever language the user writes in.
   Artifacts (YAML, markdown) always in English for consistency.
2. **Technical level:** Infer from the user's first message.
   If ambiguous, ask: "How would you describe your technical comfort?
   (a) I use apps but don't code, (b) I understand APIs and databases,
   (c) I'm a developer"

### Behavior by Level

**Non-technical (TECH: non-technical)**
- Load [references/glossary-{lang}.md] at session start
- Explain every technical term on first use
- Use analogies (e.g., "an API is like a waiter between your app and the service")
- Hide YAML details during confirmation; show plain-language summaries
- In Phase 5, present SUMMARY.md first; mention technical files exist but don't walk through them

**Technical basics (TECH: basics)**
- Load glossary on demand (only when user asks "what is X?")
- Use technical terms with brief parenthetical definitions
- Show simplified YAML during confirmation
- Walk through SUMMARY.md + key YAML files in Phase 5

**Developer (TECH: developer)**
- No glossary loading
- Full technical precision
- Show complete YAML during confirmation
- Walk through all generated files in Phase 5
```

**Confidence: MEDIUM** -- This pattern is a design decision, not an established skill pattern. The enterprise-readiness audit identified non-tech adaptation as vestigial. The three-level approach is a practical compromise.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Monolithic SKILL.md
**What:** Putting all phase details, templates, and security guidance in a single SKILL.md file.
**Why bad:** Exceeds the 500-line recommended limit. Every token competes with conversation history. Claude's ability to follow instructions degrades as SKILL.md grows. The current 539 lines is already over the limit -- and it is missing 60%+ of the required content.
**Instead:** Progressive disclosure. SKILL.md is a hub (~200-250 lines). Everything else is a spoke.

### Anti-Pattern 2: Nested Reference Chains
**What:** SKILL.md -> phase-2.md -> frameworks.md -> langraph-details.md
**Why bad:** Anthropic's official docs explicitly warn against this. Claude may use `head -100` to preview nested files, resulting in incomplete information. More than one level of indirection causes unreliable loading.
**Instead:** SKILL.md references everything directly. Phase files may contain inline callouts with paths, but those paths point to files that SKILL.md also directly lists.

### Anti-Pattern 3: External State Files During Design Phases
**What:** Writing .agentbloc/state.json during Phases 1-4 to track conversation progress.
**Why bad:** The filesystem should be pristine until Phase 5. Writing state files during design phases creates confusion (user sees partially generated artifacts), adds tool-call overhead, and conflates "skill state" (where are we in the conversation?) with "deployment state" (what have the agents processed?).
**Instead:** Conversation-embedded state line. The conversation IS the state during design. The filesystem is for deployment artifacts only.

### Anti-Pattern 4: Prose-Only Gates
**What:** Writing "NEVER skip the interview" or "The user MUST approve" without structural enforcement.
**Why bad:** These are instructions Claude can (and does) ignore under pressure. They provide no visible signal that a gate was checked.
**Instead:** The `[AGENTBLOC | PHASE: N | GATE: status]` ritual. Every response starts with the state line. Phase transitions require the gate to flip from "pending" to "approved". This is visible in the conversation and auditable.

### Anti-Pattern 5: Loading All Templates at Once
**What:** Reading all 8 template files at the start of Phase 5.
**Why bad:** Wastes context window tokens. Each template might be 50-100 lines. Loading all 8 is 400-800 lines of template scaffolding consuming context.
**Instead:** Load templates one at a time as each artifact is generated. Generate team.yaml (read team.yaml.tmpl, fill, write). Then generate each agent.yaml. Then governance.yaml. Sequential, not bulk.

---

## Scalability Considerations

| Concern | Current (v1.0) | At 10+ reference files | At 50+ templates |
|---------|-----------------|----------------------|-------------------|
| Context window pressure | Manageable. ~200 line SKILL.md + 1 phase file (~200 lines) + optional security file (~100 lines) = ~500 lines active. | Still manageable. Only 1-2 reference files active at once. Naming conventions help Claude pick the right file. | Templates are assets. Only 1 loaded at a time during Phase 5. No scaling concern. |
| File discovery | SKILL.md lists all references explicitly. | Add a "Reference Index" section to SKILL.md with grep-friendly descriptions. | Template naming convention (*.tmpl) + directory listing in phase-5-deployment.md. |
| Maintenance burden | 7 phase files + 8 security files + 4 examples = ~19 files. | Moderate. Each file is self-contained. Changes to one file don't cascade. | Templates change rarely. Schema updates are the main trigger. |
| Compaction resilience | State line in most recent response survives compaction. SKILL.md reloaded (first 5,000 tokens). | Phase file must be re-read after compaction. SKILL.md pointers enable this. | Not affected. Templates only relevant in Phase 5. |

---

## Build Order (Dependency Graph)

The following build order reflects both file dependencies and the order in which content can be meaningfully written.

### Layer 0: Foundation (no dependencies)
```
SKILL.md (hub)
  Depends on: nothing (this is the root)
  Blocks: everything else (all references point from here)
```

### Layer 1: Phase References (depend on SKILL.md structure)
```
references/phase-1-interview.md
  Depends on: SKILL.md (phase overview defines boundaries)
  Blocks: phase-2 (interview output feeds design)

references/phase-2-design.md
  Depends on: SKILL.md, phase-1 (design needs interview output format)
  Blocks: phase-3, phase-4, phase-5, frameworks.md

references/phase-3-integration.md
  Depends on: SKILL.md, phase-2 (integration analysis needs design output)
  Blocks: phase-4

references/phase-4-confirmation.md
  Depends on: SKILL.md, phase-2, phase-3 (confirms design + integrations)
  Blocks: phase-4.5

references/phase-4.5-dry-run.md
  Depends on: SKILL.md, phase-4 (dry run needs confirmed design)
  Blocks: phase-5

references/phase-5-deployment.md
  Depends on: SKILL.md, ALL prior phases (generates artifacts from all prior output)
  Blocks: templates/*, phase-6

references/phase-6-evolution.md
  Depends on: SKILL.md, phase-5 (evolution acts on deployed artifacts)
  Blocks: nothing (terminal phase)
```

### Layer 2: Cross-Cutting References (depend on phase boundaries, not phase content)
```
references/security/credentials.md
  Depends on: SKILL.md (needs to know which phases reference it)
  Blocks: phase-2, phase-3, phase-5

references/security/data-classification.md
  Depends on: SKILL.md, phase-1 (needs interview question format)
  Blocks: phase-1, phase-5

references/security/blast-radius.md
  Depends on: SKILL.md, phase-2 (needs design output format)
  Blocks: phase-2, phase-5

references/security/audit-logging.md
  Depends on: SKILL.md
  Blocks: phase-5 (governance.yaml generation)

references/security/prompt-injection.md
  Depends on: SKILL.md
  Blocks: phase-3 (trust scoring)

references/security/gdpr-patterns.md
  Depends on: data-classification.md (activated by data class)
  Blocks: phase-5

references/security/incident-response-template.md
  Depends on: SKILL.md
  Blocks: phase-5 (INCIDENT_RESPONSE.md generation)

references/security/tenant-isolation.md
  Depends on: SKILL.md
  Blocks: phase-5 (optional, activated by multi-tenant context)

references/frameworks.md
  Depends on: phase-2 (needs design vocabulary)
  Blocks: nothing (advisory reference)

references/telegram-patterns.md
  Depends on: SKILL.md
  Blocks: phase-5 (telegram.yaml generation)

references/scheduling.md
  Depends on: SKILL.md
  Blocks: phase-5 (cron configuration)

references/glossary-en.md, references/glossary-es.md
  Depends on: nothing (standalone vocabulary)
  Blocks: nothing (loaded on demand)
```

### Layer 3: Templates (depend on phase-5-deployment.md defining the generation procedure)
```
templates/team.yaml.tmpl
templates/agent.yaml.tmpl
templates/agent-skill.md.tmpl
templates/governance.yaml.tmpl
templates/telegram.yaml.tmpl
templates/state-schema.json.tmpl
templates/job.md.tmpl
templates/incident-response.md.tmpl
  All depend on: phase-5-deployment.md (defines how templates are populated)
  All block: nothing (terminal artifacts)
```

### Layer 4: Examples (depend on all phases being defined)
```
examples/arco-rooms-walkthrough.md
  Depends on: ALL phase references + ALL templates (demonstrates full flow)
  Blocks: nothing (reference material)

examples/ecommerce-support.md
examples/freelance-pipeline.md
examples/legal-triage.md
  Same dependency pattern as arco-rooms
```

### Layer 5: Tests (depend on examples and phase definitions)
```
tests/scenarios/*.jsonl
  Depends on: ALL phase references + examples (test against defined behavior)
  Blocks: nothing (evaluation infrastructure)
```

### Suggested Build Sequence

Given the dependency graph, build in this order:

1. **SKILL.md** -- The hub. Define the phase overview, state protocol, hard gates, and all reference pointers. Even though reference files do not exist yet, define where they WILL be. This is the skeleton.

2. **Phase 1 (interview)** + **data-classification.md** + **glossaries** -- The entry point. You cannot test anything without Phase 1. Data classification is needed in Phase 1's interview questions. Glossaries enable user adaptation from the start.

3. **Phase 2 (design)** + **blast-radius.md** + **credentials.md** + **frameworks.md** -- Design depends on interview output. Security references cross-cut here.

4. **Phase 3 (integration)** + **prompt-injection.md** -- Integration analysis is the most research-heavy phase. Prompt injection defense is critical here.

5. **Phase 4 (confirmation)** + **Phase 4.5 (dry run)** -- These are relatively lightweight procedural files.

6. **Phase 5 (deployment)** + **ALL templates** + **telegram-patterns.md** + **scheduling.md** + **audit-logging.md** + **gdpr-patterns.md** + **incident-response-template.md** + **tenant-isolation.md** -- The biggest batch. Phase 5 references every template and many security files. Build them together.

7. **Phase 6 (evolution)** -- Terminal phase. Depends on deployed artifacts existing.

8. **Examples** -- Can only be written after all phases are defined. Start with arco-rooms (the reference implementation).

9. **Tests** -- Last. Replay scenarios against the complete skill.

---

## Sources

### Official Documentation (HIGH confidence)
- [Skill authoring best practices - Anthropic Platform Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Agent Skills Overview - Anthropic Platform Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Equipping agents for the real world with Agent Skills - Anthropic Blog](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills)

### Community Patterns (MEDIUM confidence)
- [Progressive Disclosure Pattern - DeepWiki](https://deepwiki.com/daymade/claude-code-skills/3.3-progressive-disclosure-pattern)
- [Claude Code Skills Structure Guide - GitHub Gist](https://gist.github.com/mellanon/50816550ecb5f3b239aa77eef7b8ed8d)
- [Claude Code Workflow Orchestration - GitHub](https://github.com/barkain/claude-code-workflow-orchestration)
- [skill-creator SKILL.md - Anthropic Official Skills Repo](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md)

### Project-Specific Context
- AgentBloc SKILL.md (current monolithic state, 539 lines)
- AgentBloc enterprise-readiness.md (gap analysis identifying 18 prioritized fixes)
- AgentBloc PROJECT.md (requirements and constraints)
