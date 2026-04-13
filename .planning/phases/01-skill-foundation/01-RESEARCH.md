# Phase 1: Skill Foundation - Research

**Researched:** 2026-04-13
**Domain:** Claude Code skill architecture, progressive disclosure, conversation-embedded state management
**Confidence:** HIGH

## Summary

Phase 1 restructures AgentBloc from a monolithic 539-line SKILL.md into a lean ~200-line hub with progressive disclosure via a flat references/ directory, conversation-embedded state protocol, structural gate enforcement, bilingual detection (EN/ES), technical-level assessment, context refresh at phase boundaries, and a loopback protocol for invalidated gates. This is the foundation every subsequent phase depends on: if Claude does not reliably follow instructions throughout long multi-phase conversations, nothing else works.

The official Anthropic skill documentation (verified April 2026) confirms the hub-and-spoke progressive disclosure pattern as the correct architecture. SKILL.md body should be kept under 500 lines (official limit) with a project target of ~200 lines. Reference files are loaded on demand by Claude using file-read tools when SKILL.md instructions tell it to do so. There is no automatic `@reference` expansion in SKILL.md (that syntax only works in CLAUDE.md files). The "hybrid loading" decision (D-09) should be implemented as natural-language instructions ("Before starting this phase, read the interview guide at references/phase-1-interview.md") combined with markdown links that Claude can follow. This is the belt-and-suspenders approach the user wants.

**Primary recommendation:** Build SKILL.md as a ~200-line hub containing identity, state protocol, hard gates, phase summaries with reference pointers, language/tech-level detection rules, and a quality checklist. Create stub reference files for all 6 conversational phases. Move the Arco Rooms content to examples/arco-rooms.md. Test that Claude correctly loads reference files when directed.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** SKILL.md hub contains ONLY: identity/persona, hard gate definitions, 1-paragraph phase summaries with reference pointers, state protocol definition, language/tech-level detection rules. Target ~200 lines.
- **D-02:** All detailed phase procedures, question lists, output formats, artifact templates, and quality checklists move to individual reference files in references/.
- **D-03:** Arco Rooms reference implementation section moves to examples/arco-rooms.md. SKILL.md mentions it exists but does not inline the content.
- **D-04:** State line is VISIBLE to users but rendered as a styled header bar, not raw brackets. Format: `Phase 1: Deep Interview | Gate: pending | Level: basic`. Less technical-looking, maintains the transparency differentiator.
- **D-05:** Three technical levels: `non-technical`, `technical-basics`, `developer`. Assessed in the first interaction and carried throughout all phases.
- **D-06:** Three gate states: `pending` (working in this phase), `approved` (gate cleared, ready for next), `blocked` (issue prevents progression).
- **D-07:** The skill defines 5+1 conversational phases (distinct from the 7 GSD roadmap build phases):
  - Phase 1: Deep Interview
  - Phase 2: General Design
  - Phase 3: Deep Integration Analysis
  - Phase 4: Step-by-Step Confirmation + Dry Run (merged)
  - Phase 5: Deployment
  - Phase 6: Evolution (post-deploy, separate lifecycle)
- **D-08:** Phases are labeled with number + name in the state bar and conversation.
- **D-09:** Hybrid loading: each phase summary in SKILL.md includes BOTH a natural-language instruction ("Before starting this phase, read the interview guide") AND an explicit reference path as fallback. Belt and suspenders for reliability.
- **D-10:** Reference files are ONE level deep only. No nested references from within reference files. All references live at references/ root level (flat directory within references/).
- **D-11:** Security reference files also at references/ root (e.g., references/credentials.md, references/data-classification.md) not in a security/ subdirectory.

### Claude's Discretion
- Exact wording of the styled state bar (as long as it contains phase number, phase name, gate status, and tech level)
- Internal implementation of context refresh at phase boundaries (how to re-anchor critical instructions)
- Exact line count of SKILL.md (target ~200, hard cap 250)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | SKILL.md under 250 lines with YAML frontmatter, identity, hard gates, phase summaries, reference pointers | Official Anthropic docs confirm 500-line ceiling; hub-and-spoke pattern verified; frontmatter schema documented |
| ARCH-02 | Phase reference files load on demand (progressive disclosure via references/) | Confirmed: Claude reads reference files via file-read tools when instructed by SKILL.md. One level deep mandatory. |
| ARCH-03 | Every Claude response begins with state line | Community pattern for conversation-embedded state machine. No official Anthropic guidance exists for this specific pattern but it aligns with checklist workflow patterns. |
| ARCH-04 | Phase transitions require explicit user approval; structural enforcement prevents skipping | Hard gates + state protocol + visible state line create structural enforcement. Checklist patterns recommended by Anthropic best practices. |
| ARCH-05 | Context refresh pattern at phase boundaries to counter context rot | Progressive disclosure (load only active phase) + phase-boundary re-read instruction are the two mechanisms. Compaction reattaches first 5,000 tokens of skill. |
| ARCH-06 | Phase loopback protocol: new info invalidating a prior gate returns to that phase | Design decision; implemented as state protocol rule in SKILL.md (gate status transitions). |
| ARCH-07 | Bilingual conversation support (English/Spanish) with language auto-detection | Implemented as SKILL.md instruction. Claude natively handles multilingual conversations. Artifacts stay in English. |
| ARCH-08 | Technical-level detection in first interview question; adaptive language across ALL phases | Three-level system (non-technical/technical-basics/developer) carried in state line TECH field. Glossary files loaded on demand for non-technical users. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Stack:** Pure Claude Code skill (markdown files only). No TypeScript runtime in v1.0
- **Skill size:** SKILL.md capped at ~250 lines. Progressive disclosure via references/
- **Compliance:** GDPR patterns mandatory (European market)
- **Git commits:** Never add "Co-Authored-By: Claude" or any AI attribution
- **Quality:** Leave codebase better than found. No temporary fixes.
- **Plan mode:** Enter plan mode for any non-trivial task (3+ steps)

## Standard Stack

### Core
| Technology | Version | Purpose | Why Standard |
|------------|---------|---------|--------------|
| Claude Code Skills | v2.1+ (current v2.2.x) | Runtime for AgentBloc | The skill IS the product. SKILL.md + references/ is the entire codebase [VERIFIED: code.claude.com/docs/en/skills] |
| YAML frontmatter | Agent Skills standard | Skill activation and configuration | Official standard adopted by Anthropic [VERIFIED: code.claude.com/docs/en/skills] |
| Progressive disclosure | Claude Code native | Keep SKILL.md lean, load on demand | Official best practice: body under 500 lines [VERIFIED: platform.claude.com best practices] |
| Markdown reference files | Claude Code native | Phase procedures, security patterns, templates | One level deep from SKILL.md, loaded via file-read tools [VERIFIED: code.claude.com/docs/en/skills] |

### Supporting
| Technology | Purpose | When to Use |
|------------|---------|-------------|
| `allowed-tools` frontmatter | Pre-approve tools for the skill | Set on SKILL.md so Claude can research integrations without prompts [VERIFIED: code.claude.com/docs/en/skills] |
| `$ARGUMENTS` substitution | Pass arguments to skill | When user invokes with `/agentbloc [args]` [VERIFIED: code.claude.com/docs/en/skills] |
| `${CLAUDE_SKILL_DIR}` substitution | Reference skill directory | For scripts or files bundled with the skill [VERIFIED: code.claude.com/docs/en/skills] |

### Not Applicable to Phase 1
Template files, artifact generation, MCP servers, and deployment infrastructure are all Phase 2+ concerns. Phase 1 creates the skeleton that those phases fill.

## Architecture Patterns

### Recommended Project Structure

```
.claude/skills/agentbloc/
  SKILL.md                          # Hub (~200 lines)
  references/
    phase-1-interview.md            # Deep interview protocol (stub in Phase 1)
    phase-2-design.md               # Agent team design (stub)
    phase-3-integration.md          # Integration analysis (stub)
    phase-4-confirmation.md         # Confirmation + dry run (stub)
    phase-5-deployment.md           # Artifact generation (stub)
    phase-6-evolution.md            # Self-improvement loop (stub)
    credentials.md                  # Security: credential hierarchy (stub)
    data-classification.md          # Security: PII/PHI/financial (stub)
    blast-radius.md                 # Security: agent risk scoring (stub)
    audit-logging.md                # Security: compliance trail (stub)
    prompt-injection.md             # Security: defense patterns (stub)
    gdpr-patterns.md                # Security: GDPR compliance (stub)
    incident-response.md            # Security: runbook template (stub)
    tenant-isolation.md             # Security: multi-tenant (stub)
    frameworks.md                   # CrewAI/LangGraph/n8n patterns (stub)
    telegram-patterns.md            # Reporting patterns (stub)
    scheduling.md                   # Cron/timezone (stub)
    glossary-en.md                  # English glossary (stub)
    glossary-es.md                  # Spanish glossary (stub)
  examples/
    arco-rooms.md                   # Reference implementation (moved from SKILL.md)
```

**Critical note on D-11 (flat references/):** The user explicitly decided against subdirectories like `references/security/`. All files are at the references/ root level. This contradicts the enterprise-readiness.md recommendation but is the correct call for Claude Code loading reliability. The architecture research (ARCHITECTURE.md) previously used `references/security/` paths -- the planner must use the flat structure instead.

### Pattern 1: Hub-and-Spoke Progressive Disclosure

**What:** SKILL.md is a table of contents (~200 lines). Each phase has a summary paragraph + explicit pointer to a reference file. Claude loads reference files via file-read tools when instructed. [VERIFIED: code.claude.com/docs/en/skills, platform.claude.com best practices]

**When to use:** Always. This is mandatory for a 6-phase skill.

**Implementation:**

```markdown
### Phase 1: Deep Interview

Conduct a structured deep interview covering 9 categories until you have
zero ambiguity about the user's workflow. Ask questions ONE AT A TIME.
Each answer shapes the next question. Assess technical level and language
in the first exchange.

Before starting this phase, read the complete interview protocol:
See [references/phase-1-interview.md](references/phase-1-interview.md)
```

**Key mechanism (VERIFIED):** Claude reads reference files using its standard file-read tools (Read tool in Claude Code). When SKILL.md says "See [references/phase-1-interview.md](references/phase-1-interview.md)", Claude follows the markdown link and reads the file. There is NO automatic expansion -- Claude must choose to read it. The natural-language instruction ("Before starting this phase, read the complete interview protocol") is what triggers Claude to actually load the file. The markdown link provides the path. This is the "belt and suspenders" approach from D-09.

**IMPORTANT: The `@path` import syntax works ONLY in CLAUDE.md files.** It does NOT work in SKILL.md files. [VERIFIED: code.claude.com/docs/en/memory -- "@path/to/import" is documented exclusively under CLAUDE.md imports, with no mention in skill documentation]. SKILL.md references use standard markdown links that Claude follows with file-read tools. Do NOT use `@references/phase-1-interview.md` syntax in SKILL.md.

### Pattern 2: Conversation-Embedded State Machine

**What:** Every Claude response in an AgentBloc session begins with a state line that encodes the current phase, gate status, and tech level. The conversation itself IS the state store. [ASSUMED -- community pattern, no official Anthropic documentation]

**When to use:** Every response within an active AgentBloc session.

**Implementation (adapted for D-04 styled format):**

```
Phase 1: Deep Interview | Gate: pending | Level: non-technical
```

The user wants this rendered as a styled header bar, not raw brackets. The requirement ARCH-03 specifies `[AGENTBLOC | PHASE: N | GATE: status | TECH: level]` format, but D-04 overrides this with the styled version. The planner should reconcile: the state line fulfills ARCH-03's intent (visible state in every response) while using D-04's user-preferred styling.

**State transitions:**
- `pending` -> `approved`: User explicitly confirms gate output ("yes", "approved", "ok", "adelante")
- `pending` -> `blocked`: Issue prevents progression
- `approved` -> `pending` (loopback): New info invalidates prior gate; gate resets to target phase
- Phase number increments ONLY after current gate is `approved` AND user confirms

**Compaction resilience:** After auto-compaction, Claude Code re-attaches the first 5,000 tokens of the most recently invoked skill. The state line in the most recent response survives because it is part of the conversation history. SKILL.md is re-read from disk. [VERIFIED: code.claude.com/docs/en/skills -- "Auto-compaction carries invoked skills forward within a token budget... re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens"]

### Pattern 3: Context Refresh at Phase Boundaries

**What:** When Claude transitions from one phase to the next, it re-reads the relevant reference file for the new phase. This counters context rot by ensuring fresh, complete instructions are in context at the start of each phase. [ASSUMED -- design decision, not an established pattern]

**When to use:** Every phase transition.

**Implementation:**

```markdown
### Phase Transition Protocol

When transitioning to a new phase:
1. Update the state line to the new phase number with gate: pending
2. Read the reference file for the new phase (e.g., references/phase-2-design.md)
3. Re-read the hard gates section of this file (SKILL.md)
4. Summarize the previous phase outcome before beginning the new phase
```

This pattern directly addresses Pitfall 1 (context rot). By Phase 4 or 5 in a long conversation, SKILL.md instructions may have decayed in Claude's attention. Forcing a re-read of SKILL.md hard gates + the new phase reference file restores full instruction compliance.

### Pattern 4: Bilingual Detection and Technical-Level Assessment

**What:** In the first exchange, Claude detects the user's language (respond in that language) and assesses their technical level (non-technical / technical-basics / developer). Both are carried in the state line for the entire session. [ASSUMED -- design decision]

**When to use:** First exchange of every AgentBloc session.

**Implementation:**

```markdown
## Language and Technical Level

### Language Detection
Respond in whatever language the user writes in. If they switch languages
mid-conversation, switch with them. All generated artifacts (YAML, markdown
config files) remain in English for consistency. Conversation and explanations
match the user's language.

### Technical Level Assessment
Infer from the user's first message. If ambiguous, ask:
- EN: "How would you describe your technical comfort? (a) I use apps but don't
  code, (b) I understand APIs and databases, (c) I'm a developer"
- ES: "Como describirias tu nivel tecnico? (a) Uso apps pero no programo,
  (b) Entiendo APIs y bases de datos, (c) Soy desarrollador"

Map to: non-technical | technical-basics | developer

### Behavior by Level
- **non-technical**: Load glossary on demand. Explain every technical term.
  Use analogies. Hide YAML details during design. Show plain-language summaries.
- **technical-basics**: Brief parenthetical definitions for jargon. Show
  simplified YAML. Walk through key files.
- **developer**: Full technical precision. Complete YAML. All generated files.
```

### Anti-Patterns to Avoid

- **Monolithic SKILL.md:** The current 539-line file violates the 500-line official limit and would be 1500+ lines with all enterprise-readiness content. Never inline phase details in the hub. [VERIFIED: platform.claude.com -- "Keep SKILL.md body under 500 lines"]
- **Nested reference chains:** SKILL.md -> phase-2.md -> frameworks.md is two hops. Claude may use `head -100` to preview nested files, resulting in incomplete information. All references must be one hop from SKILL.md. [VERIFIED: platform.claude.com -- "Keep references one level deep from SKILL.md"]
- **`@import` syntax in SKILL.md:** The `@path` import syntax is a CLAUDE.md feature, not a SKILL.md feature. SKILL.md references use markdown links that Claude follows via file-read tools. Using `@` in SKILL.md will not auto-expand the file. [VERIFIED: code.claude.com/docs/en/memory vs code.claude.com/docs/en/skills]
- **Prose-only gates:** Writing "NEVER skip the interview" without structural enforcement. Claude ignores these under context pressure. Use the visible state line ritual instead. [CITED: research.trychroma.com/context-rot, enterprise-readiness.md]
- **External state files during design:** Do not write .agentbloc/state.json during Phases 1-4. The filesystem should be pristine until Phase 5. The conversation IS the state during design phases. [ASSUMED -- design decision from ARCHITECTURE.md research]
- **Security subdirectory (references/security/):** D-11 explicitly forbids this. All reference files at references/ root level.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Skill frontmatter | Custom metadata format | Standard YAML frontmatter with `name`, `description`, `allowed-tools` fields | Official Agent Skills standard. Cross-tool compatible. [VERIFIED: code.claude.com] |
| Reference loading | Custom file-loading mechanism or `@import` in SKILL.md | Natural-language instructions + markdown links in SKILL.md body | Claude reads files via built-in Read tool when instructed. No custom loader needed. [VERIFIED: code.claude.com] |
| State persistence | JSON state files during design phases | Conversation-embedded state line in every response | The conversation IS the state during Phases 1-4. External files add complexity without benefit. [ASSUMED] |
| Technical level adaptation | Complex branching logic | Three-word state field (non-technical/technical-basics/developer) + conditional loading of glossary files | Claude handles conditional behavior via instructions. No programmatic branching needed. [ASSUMED] |

**Key insight:** AgentBloc is a pure markdown skill. There is no code to write -- only instructions to compose. Every "implementation" decision is about how to word instructions so Claude follows them reliably. The "don't hand-roll" principle here means: don't invent custom mechanisms when Claude Code's native features handle the use case.

## Common Pitfalls

### Pitfall 1: Context Rot Kills Skill Compliance

**What goes wrong:** By Phase 4-5 in a long conversation, SKILL.md instructions decay in Claude's attention. Hard gates get silently skipped. The state line ritual stops appearing. Security fields are omitted from outputs.
**Why it happens:** Claude's context window is shared. As conversation grows, instruction weight drops proportionally. The "lost-in-the-middle" effect hits rules in the middle of long skill files hardest. AgentBloc guarantees long conversations by design.
**How to avoid:** (1) Cut SKILL.md to ~200 lines. (2) Load only the active phase's reference file. (3) Put hard gates at the TOP of SKILL.md. (4) Context refresh at every phase boundary (re-read SKILL.md gates + new phase reference). (5) One level deep only for references.
**Warning signs:** Claude skips the state line mid-conversation. Phase transitions happen without user confirmation. Quality checklist items silently omitted.
[CITED: research.trychroma.com/context-rot]

### Pitfall 2: Skill Activation Failure

**What goes wrong:** AgentBloc never gets invoked. User gets generic Claude behavior instead of the 6-phase flow.
**Why it happens:** Claude uses only `name` and `description` from frontmatter to decide activation. Poor description = poor activation. Current description is first-person and lacks Spanish triggers.
**How to avoid:** (1) Rewrite description in third person (Anthropic requirement). (2) Front-load the key use case. (3) Include both English and Spanish trigger phrases. (4) Keep under 1024 chars but make keyword-rich. (5) Description truncated at 250 chars in listings -- put the most important content first.
**Warning signs:** Users say "Claude just answered normally." Non-English prompts miss activation.
[VERIFIED: platform.claude.com -- "Always write in third person", "descriptions longer than 250 characters are truncated"]

### Pitfall 3: Reference Files Not Loaded

**What goes wrong:** Claude acknowledges a phase transition but does not actually read the reference file. It proceeds with only the summary paragraph from SKILL.md, missing detailed procedures.
**Why it happens:** Natural-language instructions ("read the interview guide") are suggestions, not commands. Under time pressure or long context, Claude may skip the file read to respond faster.
**How to avoid:** (1) Hybrid loading (D-09): both natural-language instruction AND markdown link. (2) Make the instruction a "low freedom" directive: "You MUST read [references/phase-1-interview.md] before asking any interview questions." (3) Include a visible indicator in the response that confirms the file was loaded (e.g., "Loaded: phase-1-interview.md").
**Warning signs:** Claude's phase output is shallow or missing categories that the reference file defines. Claude does not reference specific checklist items from the reference file.
[VERIFIED: platform.claude.com -- "low freedom" for fragile operations]

### Pitfall 4: State Line Ritual Abandoned Mid-Conversation

**What goes wrong:** Claude starts with the state line in early responses but stops using it after 5-10 exchanges.
**Why it happens:** The ritual is "procedural overhead" that does not produce user-visible value. Claude prioritizes helpfulness over compliance with rituals under context pressure.
**How to avoid:** (1) Make the state line the FIRST thing in the response template, before any content. (2) Make it styled and professional (D-04) so it adds visual value. (3) Include it in the context refresh protocol so it is re-anchored at every phase boundary. (4) Consider a "If your previous response did not include the state bar, add it now" self-correction instruction.
**Warning signs:** Responses start without the state bar after the 5th exchange.
[CITED: PITFALLS.md research -- execution drift]

### Pitfall 5: Over-Cutting SKILL.md

**What goes wrong:** In the effort to reach ~200 lines, critical context is removed from SKILL.md and placed in reference files that Claude does not read until needed. The hub becomes too thin to maintain session coherence.
**Why it happens:** Aggressive line-count optimization. Treating the line count as more important than information density.
**How to avoid:** Keep in SKILL.md: (1) Full identity/persona section (~20 lines). (2) All 5 hard gate rules (~15 lines). (3) Complete state protocol with transition rules (~25 lines). (4) Language/tech-level detection rules (~20 lines). (5) One-paragraph summary + reference pointer per phase (~6 phases x 5 lines = 30 lines). (6) Quality checklist (~10 lines). Total: ~120-150 lines of content + frontmatter + headers = ~180-220 lines. This leaves room within the 250-line cap.
**Warning signs:** Claude does not maintain persona consistency. Hard gates are violated because they are in a reference file instead of the hub.
[ASSUMED -- design judgment from enterprise-readiness.md analysis]

## Code Examples

### YAML Frontmatter (Verified Pattern)

```yaml
# Source: code.claude.com/docs/en/skills (official documentation)
---
name: agentbloc
description: >
  Designs and deploys AI agent teams for businesses through a structured
  6-phase conversational flow: deep interview, agent team design, integration
  analysis, step-by-step confirmation with dry run, deployment artifact
  generation, and post-deploy evolution. Activates when users want to automate
  business workflows, design AI agents, or deploy autonomous processes.
  Triggers: /agentbloc, "design agents", "automate my business", "automatizar
  mi negocio", "crear agentes", "agent team".
allowed-tools: Read Grep Glob WebSearch WebFetch Bash
---
```

**Field constraints (VERIFIED):**
- `name`: max 64 chars, lowercase + hyphens only, no "anthropic" or "claude" [VERIFIED: platform.claude.com]
- `description`: max 1024 chars, truncated at 250 in listings, must be third person [VERIFIED: platform.claude.com]
- `allowed-tools`: space-separated string or YAML list, pre-approves tools [VERIFIED: code.claude.com/docs/en/skills]
- All fields are optional except `description` (recommended) [VERIFIED: code.claude.com/docs/en/skills]
- Do NOT set `disable-model-invocation: true` -- AgentBloc should auto-activate [VERIFIED: code.claude.com]
- Do NOT set `context: fork` -- AgentBloc needs conversation history [VERIFIED: code.claude.com]

### Reference Link Pattern (How Claude Loads Files)

```markdown
# Source: code.claude.com/docs/en/skills (official documentation)
# In SKILL.md, reference files are pointed to via markdown links.
# Claude reads them with file-read tools when instructed.

### Phase 1: Deep Interview

Conduct a structured deep interview covering 9 categories. Ask questions
one at a time. Each answer shapes the next question.

You MUST read the complete interview protocol before asking any questions:
See [references/phase-1-interview.md](references/phase-1-interview.md)

If the user's data involves PII, PHI, or financial information, also read:
See [references/data-classification.md](references/data-classification.md)
```

### State Line (Styled Format per D-04)

```markdown
# Source: CONTEXT.md D-04 (user decision)
# Every AgentBloc response MUST begin with this styled state bar:

**Phase 1: Deep Interview | Gate: pending | Level: non-technical**

# Examples of state transitions:

**Phase 1: Deep Interview | Gate: approved | Level: technical-basics**
# (User confirmed interview summary, ready for next phase)

**Phase 2: General Design | Gate: pending | Level: developer**
# (Transitioned to Phase 2, working on design)

**Phase 1: Deep Interview | Gate: loopback from Phase 3 | Level: non-technical**
# (New info in Phase 3 invalidated Phase 1 gate, returning to re-interview)
```

### Compaction Survival Pattern

```markdown
# Source: code.claude.com/docs/en/skills (official documentation)
# After auto-compaction, Claude Code:
# 1. Summarizes the conversation
# 2. Re-attaches the most recent invocation of each skill (first 5,000 tokens)
# 3. Skills share a combined 25,000-token budget

# To maximize survival:
# - Keep SKILL.md under 5,000 tokens (~200-250 lines at ~20 tokens/line)
# - Put critical rules (hard gates, state protocol) at the TOP
# - The state line in the most recent response survives in conversation history
# - Phase reference files are NOT re-attached -- Claude must re-read them
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom `@reference` expansion in SKILL.md | Markdown links + natural-language instructions; Claude reads via file tools | Always (skills never had `@import`) | Do NOT assume `@` works in SKILL.md |
| Single monolithic skill file | Hub + reference files (progressive disclosure) | Claude Code v2.0+ (official best practice) | 500-line ceiling; reference files for details |
| Commands in `.claude/commands/` | Skills in `.claude/skills/` (commands still work) | Claude Code v2.1+ (skills merged commands) | Skills support frontmatter, supporting files, auto-activation |
| Description as summary for humans | Description as activation trigger for the model (third person) | Agent Skills standard adoption | Write description for Claude, not the README |
| Manual `@import` in CLAUDE.md | `@path` auto-expansion in CLAUDE.md (max 5 hops) | Claude Code v2.1+ | CLAUDE.md only; NOT available in SKILL.md |

**Deprecated/outdated:**
- `.claude/commands/` still works but `.claude/skills/` is recommended. Skills add frontmatter, supporting files, and auto-activation. [VERIFIED: code.claude.com]
- Anthropic's archived MCP reference servers (Google Drive, GitHub) replaced by community-maintained alternatives. Not relevant to Phase 1 but noted for later phases. [VERIFIED: STACK.md research]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Conversation-embedded state line is the best phase enforcement mechanism | Pattern 2 | If Claude systematically ignores the state line ritual, we need hook-based enforcement instead. MEDIUM risk -- community reports suggest the pattern works but is not 100% reliable. |
| A2 | Context refresh by re-reading reference files at phase boundaries will counter context rot | Pattern 3 | If Claude does not actually re-read files when instructed at phase boundaries, rot continues. Could test with explicit "Confirm you have read [file]" instructions. LOW risk -- file-read is a standard tool call. |
| A3 | Three technical levels (non-technical/basics/developer) are sufficient | Pattern 4 | If the spectrum is more nuanced (e.g., "technical but not a developer" vs "developer unfamiliar with AI"), we may need adjustment. LOW risk -- can be refined in later phases. |
| A4 | Stub reference files are acceptable for Phase 1 (not fully fleshed out) | Architecture | Phase 1 creates the skeleton. Detailed content for reference files is Phase 2-5 work. If stubs are too thin, Claude may not follow the progressive disclosure pattern correctly during testing. LOW risk. |
| A5 | The `blocked` gate state (D-06) is needed in addition to `pending` and `approved` | Pattern 2 | If no real scenario triggers `blocked`, it adds unnecessary complexity. LOW risk -- can be removed later if unused. |

## Open Questions

1. **State line styling vs ARCH-03 format**
   - What we know: ARCH-03 specifies `[AGENTBLOC | PHASE: N | GATE: status | TECH: level]`. D-04 specifies `Phase 1: Deep Interview | Gate: pending | Level: basic` (styled, not bracketed).
   - What's unclear: Whether ARCH-03 should be updated to match D-04 or whether both formats should coexist.
   - Recommendation: D-04 is the user's explicit preference. Implement D-04 format. Update ARCH-03 description to match. The intent (visible state in every response) is preserved.

2. **Reference file loading verification**
   - What we know: Claude reads files via Read tool when instructed. No auto-expansion.
   - What's unclear: How reliably Claude follows "read this file" instructions in SKILL.md across different models (Haiku vs Sonnet vs Opus).
   - Recommendation: Test with both natural-language instruction + markdown link (hybrid per D-09). If unreliable, add explicit "Confirm: I have read [filename]" acknowledgment step.

3. **Compaction behavior with many reference files**
   - What we know: After compaction, first 5,000 tokens of SKILL.md are re-attached. Reference files are NOT re-attached.
   - What's unclear: After compaction mid-phase, does Claude know to re-read the current phase's reference file?
   - Recommendation: Include in the state protocol: "After any context compaction, re-read the reference file for the current phase before continuing."

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual conversation testing (no automated test framework for Claude Code skills exists in this project yet) |
| Config file | none (Phase 7 builds the test harness) |
| Quick run command | Manual: invoke `/agentbloc` in Claude Code and test one phase |
| Full suite command | Manual: complete a full 6-phase conversation and verify all criteria |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ARCH-01 | SKILL.md under 250 lines | manual/script | `wc -l SKILL.md` (verify < 250) | Wave 0 |
| ARCH-02 | Reference files load on demand | manual | Invoke skill, check that Claude reads reference file during phase | Wave 0 |
| ARCH-03 | State line in every response | manual | Complete 5+ exchanges, verify state line present in every response | Wave 0 |
| ARCH-04 | Phase transitions require user approval | manual | Attempt to skip a phase without approval, verify enforcement | Wave 0 |
| ARCH-05 | Context refresh at phase boundaries | manual | Transition between phases, verify Claude re-reads reference file | Wave 0 |
| ARCH-06 | Loopback protocol works | manual | Introduce contradictory info in Phase 3, verify return to Phase 1 | Wave 0 |
| ARCH-07 | Bilingual support | manual | Start conversation in Spanish, verify Spanish responses | Wave 0 |
| ARCH-08 | Tech level detection and adaptation | manual | Use non-technical language, verify simplified responses | Wave 0 |

### Sampling Rate
- **Per task commit:** `wc -l SKILL.md` to verify line count
- **Per wave merge:** Manual conversation test covering ARCH-01 through ARCH-08
- **Phase gate:** All 8 requirements manually verified before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] No automated test infrastructure exists yet (Phase 7 scope)
- [ ] Line-count verification can be scripted: `wc -l .claude/skills/agentbloc/SKILL.md`
- [ ] Manual testing protocol needs to be documented as a checklist

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 1 is skill structure only; no auth |
| V3 Session Management | No | No sessions in Phase 1 |
| V4 Access Control | No | No access control in Phase 1 |
| V5 Input Validation | Partially | Skill frontmatter validated by Claude Code runtime |
| V6 Cryptography | No | No crypto in Phase 1 |

Phase 1 is a structural reorganization of markdown files. Security patterns (credentials, data classification, blast radius, etc.) are Phase 2 scope. However, Phase 1 MUST create the reference pointers that Phase 2 will populate. The stub files at references/credentials.md, references/data-classification.md, etc. must exist so the SKILL.md hub can point to them.

### Known Threat Patterns for Phase 1

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Skill activation hijacking (malicious prompt tricks Claude into activating AgentBloc inappropriately) | Spoofing | Write precise `description` field; do not over-broaden triggers |
| Instruction injection via reference files (if reference files are user-editable) | Tampering | Reference files ship with the skill; not user-modifiable at runtime |

## Sources

### Primary (HIGH confidence)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Verified April 2026. Complete skill architecture: frontmatter schema, reference files, progressive disclosure, compaction behavior, tool pre-approval, string substitutions, skill lifecycle.
- [Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) -- Verified April 2026. 500-line ceiling, progressive disclosure patterns, checklist workflows, naming conventions, third-person descriptions, "low freedom" vs "high freedom" instructions, one-level-deep references.
- [Claude Code Memory Documentation](https://code.claude.com/docs/en/memory) -- Verified April 2026. CLAUDE.md `@import` syntax (NOT available in SKILL.md), file loading order, compaction behavior, 200-line recommendation for CLAUDE.md, 25KB auto-memory limit.

### Secondary (MEDIUM confidence)
- [Context Rot Research - Chroma](https://research.trychroma.com/context-rot) -- 18 frontier models tested; all degrade as context grows
- [AgentBloc enterprise-readiness.md](enterprise-readiness.md) -- Project-specific audit identifying 18 gaps; recommended file structure
- [AgentBloc ARCHITECTURE.md](.planning/research/ARCHITECTURE.md) -- Hub-and-spoke pattern, state machine design, build order
- [AgentBloc PITFALLS.md](.planning/research/PITFALLS.md) -- Context rot, activation failure, execution drift
- [AgentBloc STACK.md](.planning/research/STACK.md) -- Skill architecture, MCP ecosystem, deployment patterns

### Tertiary (LOW confidence)
- [MindStudio: Claude Code Skills Architecture](https://www.mindstudio.ai/blog/claude-code-skills-architecture-skill-md-reference-files) -- Community analysis of reference file patterns
- [Steve Kinney: Referencing Files in Claude Code](https://stevekinney.com/courses/ai-development/referencing-files-in-claude-code) -- Community tutorial on @ syntax and file references

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Official Anthropic documentation verified for all skill architecture claims
- Architecture (hub-and-spoke): HIGH -- Progressive disclosure is the official documented pattern
- Architecture (state machine): MEDIUM -- Conversation-embedded state line is a community pattern, not officially documented by Anthropic
- Pitfalls: HIGH -- Multi-source verification (Anthropic docs, Chroma research, community reports)
- Reference loading mechanism: HIGH -- Verified that `@import` is CLAUDE.md-only; SKILL.md uses markdown links + file-read tools

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (30 days -- Claude Code skill architecture is stable)
