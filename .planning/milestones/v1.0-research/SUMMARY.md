# Research Summary: AgentBloc

**Domain:** Claude Code skill for AI agent team design and deployment
**Researched:** 2026-04-13
**Overall confidence:** HIGH (core architecture), MEDIUM (state management patterns)

## Executive Summary

AgentBloc is a pure markdown Claude Code skill that guides users through a 6-phase conversational flow from "I have a manual business process" to "I have a deployed AI agent team." The current implementation is a single 539-line SKILL.md file that exceeds Anthropic's official 500-line ceiling and is missing 60%+ of the content identified in the enterprise-readiness audit (security governance, dry run, evidence protocol, 4 of 6 artifact templates, self-improvement loop, framework patterns, non-technical adaptation).

The architecture research confirms that Anthropic's progressive disclosure pattern is the correct approach: a lean SKILL.md hub (~200-250 lines) with reference files loaded on demand. This is not just a recommendation -- it is the documented best practice from Anthropic's official skill authoring guide, validated by their own skill-creator reference implementation. The three-tier loading model (metadata always in context, SKILL.md body on trigger, reference files on demand) directly solves AgentBloc's core tension: encoding deep procedural knowledge across 6 phases without exceeding context window budgets.

Phase enforcement is the second critical architectural decision. Research into Claude Code skill behavior reveals that prose-only gates ("NEVER skip the interview") are systematically ignored under context pressure. The recommended approach is a conversation-embedded state machine where every Claude response begins with `[AGENTBLOC | PHASE: N | GATE: status | TECH: level]`. This creates a visible, auditable state line that survives context compaction and makes phase transitions explicit. The community pattern is well-established, though no official Anthropic guidance prescribes a specific state management approach.

The deployment artifact architecture uses a template-driven pattern: YAML/markdown skeleton files in a `templates/` directory that Claude reads only during Phase 5 and populates with data gathered across Phases 1-4. Templates are treated as assets (never loaded into context until needed), maintaining clean context during the conversational phases. The generated `.agentbloc/` directory contains 8 artifact types: team.yaml, per-agent YAML, per-agent skill markdown, governance.yaml, telegram.yaml, state schemas, ClaudeClaw job definitions, and incident response runbooks.

## Key Findings

**Stack:** Pure Claude Code skill (markdown only). Artifacts target Claude Code + cron + MCP + Telegram. No custom runtime in v1.0. CrewAI and LangGraph patterns referenced during design; not used as runtime dependencies.

**Architecture:** Hub-and-spoke progressive disclosure with conversation-embedded state machine. SKILL.md (~200-250 lines) + 7 phase references + 8 security references + 8 artifact templates + 4 examples + glossaries + framework library = ~35 files total.

**Critical pitfall:** Context rot -- Claude's ability to follow skill instructions degrades as conversations grow long. AgentBloc's multi-phase nature guarantees long conversations. Solution: aggressive progressive disclosure (load only the active phase), critical rules at the TOP of SKILL.md, and a "context refresh" pattern at phase boundaries.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Skill Restructuring (Foundation)** -- Split the monolithic SKILL.md into hub + spokes. Define the state protocol, hard gates, and reference pointers. This must come first because every subsequent phase depends on Claude reliably following instructions throughout long conversations.
   - Addresses: SKILL.md over line limit, prose-only gates, progressive disclosure
   - Avoids: Context rot (Pitfall 1), execution drift (Pitfall 3)

2. **Core Phase Development** -- Build the 7 phase reference files (Phase 1-6 + Phase 4.5) with their detailed procedures, output formats, and quality checklists. Build security cross-cutting references in parallel. Complete all 8 artifact templates.
   - Addresses: 4 missing artifact templates, missing dry run, missing evidence protocol, missing security governance
   - Avoids: Generated artifacts that don't work (Pitfall 4), integration hallucination (Pitfall 5)

3. **Security and Governance** -- Build the 8 security reference files: credentials, data classification, blast radius, audit logging, prompt injection, GDPR, incident response, tenant isolation. These cross-cut multiple phases and must exist before end-to-end testing.
   - Addresses: Enterprise-readiness audit critical items 1-4, 10-11
   - Avoids: Credential leakage, over-scoped permissions, missing compliance patterns

4. **Testing and Validation** -- Build evaluation scenarios (3-5 diverse industry walkthroughs). Test activation rates across Haiku/Sonnet/Opus. Validate artifact generation with YAML linting. Test with non-technical users.
   - Addresses: No testing harness, untested non-technical flow
   - Avoids: Skill activation failure (Pitfall 2), non-technical user abandonment (Pitfall 7)

5. **Polish, Examples, and Launch** -- Build the gold-standard walkthrough examples (arco-rooms, ecommerce, freelance, legal). Create glossaries. Write the README. Position the consulting upsell naturally.
   - Addresses: Missing examples, missing glossaries, repo quality
   - Avoids: README that over-promises, consulting upsell mispositioned

**Phase ordering rationale:**
- Foundation first because all reference files depend on SKILL.md's structure being correct.
- Core phases before security because security files cross-reference phase output formats -- you need to know what Phase 2 outputs before you can write blast-radius.md.
- Security before testing because tests must validate security enforcement.
- Examples last because they demonstrate the complete flow -- they cannot be written until all phases are defined.
- Build order within phases: Layer 0 (SKILL.md) -> Layer 1 (phase references) -> Layer 2 (cross-cutting references) -> Layer 3 (templates) -> Layer 4 (examples) -> Layer 5 (tests).

**Research flags for phases:**
- Phase 2 (Core Development): The dry run pattern (Phase 4.5) needs deeper research on tool-stubbing mechanisms in Claude Code. How do you tell Claude Code to "run this agent but stub all write/send tools"?
- Phase 3 (Security): GDPR compliance patterns for agent systems are a rapidly evolving area. The NIST AI Agent Standards Initiative (launched January 2026) may produce new guidance before this phase ships.
- Phase 4 (Testing): Activation rate testing methodology is not well-documented. Need to define a repeatable benchmark for measuring skill activation across prompts.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Claude Code skill format is stable. MCP ecosystem is well-documented. No custom runtime decisions. |
| Features | HIGH | Enterprise-readiness audit + competitor analysis provides clear feature landscape. Table stakes are unambiguous. |
| Architecture | HIGH (structure), MEDIUM (state management) | Progressive disclosure is official Anthropic pattern. State machine ritual is community pattern, not officially documented. |
| Pitfalls | HIGH | Multi-source verification: Anthropic docs, Chroma context-rot research, community failure reports, production incident analyses. |

## Gaps to Address

- **Tool-stubbing for dry run:** How to make Claude Code execute an agent session with write/send tools disabled needs investigation during Phase 4.5 development. Possible approaches: `allowed-tools` in agent YAML, PreToolUse hooks that block during dry run, or a `--dry-run` flag in the ClaudeClaw job definition.
- **Activation rate benchmarking:** No standardized methodology exists for measuring skill activation rates. Need to create a test harness with 20+ diverse prompts across models.
- **Compaction recovery depth:** How much conversation history survives compaction for skills with long conversations (15+ exchanges)? The 5,000-token reattachment budget may not be sufficient for mid-phase recovery. Needs empirical testing.
- **Template validation:** Whether Claude can reliably populate YAML templates without syntax errors needs testing. May need a validation script (Python) bundled as a skill utility.
- **Spanish glossary completeness:** The glossary files need native-speaker review. Machine-generated technical glossaries in Spanish often miss regional terminology differences.

## Sources

### Official (HIGH confidence)
- [Skill authoring best practices - Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Agent Skills Overview - Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [skill-creator SKILL.md - Anthropic Official Skills Repo](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md)

### Research and Analysis (MEDIUM-HIGH confidence)
- [Context Rot Research - Chroma](https://research.trychroma.com/context-rot)
- [Progressive Disclosure Pattern - DeepWiki](https://deepwiki.com/daymade/claude-code-skills/3.3-progressive-disclosure-pattern)
- AgentBloc enterprise-readiness.md (project-specific audit)
- AgentBloc PROJECT.md (requirements and constraints)
