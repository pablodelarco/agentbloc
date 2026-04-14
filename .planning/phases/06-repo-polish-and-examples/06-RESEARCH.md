# Phase 6: Repo Polish and Examples - Research

**Researched:** 2026-04-14
**Domain:** Open-source repository documentation, example walkthrough writing, bilingual glossary expansion, repo meta-files (LICENSE, CONTRIBUTING, SECURITY, CHANGELOG), shields.io badges, SKILL.md versioning
**Confidence:** HIGH

## Summary

Phase 6 is a documentation-only phase with zero code dependencies. Every deliverable is a markdown or plain-text file. The research domain spans open-source repo conventions (README structure, badge syntax, licensing, changelogs), example walkthrough authoring (demonstrating the full 6-phase AgentBloc flow for three business domains), and bilingual glossary writing (English/Spanish technical vocabulary for AI automation).

The key technical findings are: (1) shields.io static badges use a simple URL pattern `https://img.shields.io/badge/{label}-{message}-{color}` that requires no build tooling; (2) CHANGELOG.md should follow the Keep a Changelog format with semver version headers and ISO 8601 dates; (3) the `version` field in SKILL.md frontmatter is NOT an officially recognized Claude Code skill field, but unknown frontmatter fields are silently ignored so it is safe to add; (4) the MIT License has a standard canonical text from the Open Source Initiative; (5) the Contributor Covenant 2.1 is the industry standard code of conduct for open-source projects.

**Primary recommendation:** Execute as three plans: (1) README.md + badges + LICENSE + CONTRIBUTING.md + SECURITY.md + CHANGELOG.md + SKILL.md version field, (2) three example walkthroughs, (3) bilingual glossary expansion. Plan 1 is independent. Plan 2 depends on understanding the full phase reference files. Plan 3 depends on cataloging all terms across the codebase.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** README structure: hero section (1-line tagline + 3-line description), badges row, "What is AgentBloc?" section (30-second pitch), "Quick Start" section (5-minute: clone, copy to skills, invoke /agentbloc), "How It Works" section (6-phase overview with diagram), "Examples" section (links to 3 walkthroughs), "Contributing" and "License" footer sections.
- **D-02:** Tone is professional but approachable. Not salesy, not enterprise. Think "senior engineer explaining a tool to a colleague." Written in English with a note that the skill supports Spanish.
- **D-03:** The 5-minute quickstart must work for someone who has Claude Code installed. Steps: clone repo, copy SKILL.md + references/ + examples/ to .claude/skills/agentbloc/, invoke with /agentbloc or describe a business problem.
- **D-04:** Three example walkthroughs, each demonstrating a full 6-phase AgentBloc flow: arco-rooms.md (expand existing), ecommerce-support.md (new), freelance-pipeline.md (new).
- **D-05:** Each walkthrough follows the same structure: Business Context, Interview Summary, Agent Team Design (with topology diagram), Integration Findings, Confirmed Agent Cards, Deployment Artifacts (key files shown), Evolution Notes. Not full YAML dumps: show the key decisions and outputs at each phase.
- **D-06:** Examples should be realistic but concise. Each walkthrough is 150-250 lines. They demonstrate the pattern, not every detail.
- **D-07:** Expand both glossary stubs (EN + ES) to 30+ terms covering all AgentBloc-specific concepts.
- **D-08:** Spanish glossary is a translation of the English glossary, not an independent document. Terms should use natural Spanish technical vocabulary.
- **D-09:** MIT License. Standard MIT text with "AgentBloc contributors" as copyright holder.
- **D-10:** CONTRIBUTING.md: how to contribute (fork, branch, PR), skill development guidelines, testing requirements, code of conduct reference.
- **D-11:** SECURITY.md: vulnerability disclosure process, supported versions table, response time commitments (acknowledge within 48h, fix within 7 days for critical).
- **D-12:** CHANGELOG.md: semver format, current version 1.0.0, entries for each phase completed.
- **D-13:** Add `version: 1.0.0` to SKILL.md YAML frontmatter. CHANGELOG.md at repo root tracks releases with date and changes.

### Claude's Discretion
- Badge design and shield.io URLs
- Exact README section ordering (as long as all required sections present)
- CONTRIBUTING.md code of conduct choice (Contributor Covenant recommended)
- Exact glossary term count (minimum 30, Claude adds relevant terms)
- CHANGELOG entry granularity (per-phase or per-feature)

### Deferred Ideas (OUT OF SCOPE)
- Screenshots/GIFs in README showing a live AgentBloc session: requires a recorded session, Phase 7 territory
- Interactive demo or playground: out of scope for v1.0
- Translations of README into Spanish: could be added later, README stays in English
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REPO-01 | README.md that explains AgentBloc in 30 seconds and lets a user try it in 5 minutes | README structure pattern (D-01), badge syntax, quickstart steps (D-03) |
| REPO-02 | Installation instructions: clone/copy into .claude/skills/, invoke with /agentbloc | Quickstart verified against Claude Code skill directory structure |
| REPO-03 | 3 example walkthroughs: real estate ops, ecommerce support, freelance pipeline | Walkthrough structure (D-05), topology variety guidance, 150-250 line targets |
| REPO-04 | CONTRIBUTING.md with development guidelines | Contributor Covenant 2.1 template, fork/branch/PR workflow pattern |
| REPO-05 | LICENSE file (open source) | MIT License canonical text, copyright holder format |
| REPO-06 | Badges (version, license, Claude Code compatible) | Shields.io static badge URL syntax verified |
| REPO-07 | Glossary files (English + Spanish) for non-technical users | 30+ terms cataloged from codebase, Spanish technical vocabulary conventions |
| REPO-08 | SECURITY.md at repo root with disclosure email, supported-versions table, and response-time commitments | GitHub SECURITY.md best practices, vulnerability disclosure template |
| ARCH-09 | Skill frontmatter carries semver `version` field; CHANGELOG.md at repo root tracks every release | SKILL.md frontmatter field analysis, Keep a Changelog format |
</phase_requirements>

## Standard Stack

This phase has no library dependencies. All deliverables are markdown and plain-text files. No package installations required.

### Core Tools
| Tool | Purpose | Why Standard |
|------|---------|--------------|
| Shields.io | Badge generation via URL | Industry standard for GitHub README badges. No build step, no dependencies [VERIFIED: shields.io] |
| Keep a Changelog format | CHANGELOG.md structure | Most widely adopted changelog convention for open-source projects [CITED: keepachangelog.com/en/1.0.0/] |
| Contributor Covenant 2.1 | Code of conduct for CONTRIBUTING.md | Most widely adopted open-source code of conduct [CITED: contributor-covenant.org/version/2/1/code_of_conduct/] |
| MIT License | LICENSE file | Decision D-09 locks this choice [VERIFIED: opensource.org/license/mit] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shields.io static badges | Dynamic GitHub badges | Dynamic badges auto-update but require GitHub API. Static is simpler for v1.0 and the version number changes infrequently |
| Keep a Changelog | Conventional Changelog (auto-generated) | Auto-generated requires tooling. Manual Keep a Changelog format fits a markdown-only project |
| Contributor Covenant 2.1 | Custom code of conduct | No reason to deviate. Contributor Covenant is the standard |

## Architecture Patterns

### File Structure After Phase 6

```
agentbloc/
  SKILL.md               # (modified: add version field to frontmatter)
  README.md               # (new: REPO-01, REPO-02, REPO-06)
  LICENSE                  # (new: REPO-05)
  CONTRIBUTING.md          # (new: REPO-04)
  SECURITY.md              # (new: REPO-08)
  CHANGELOG.md             # (new: ARCH-09)
  examples/
    arco-rooms.md          # (expanded: REPO-03)
    ecommerce-support.md   # (new: REPO-03)
    freelance-pipeline.md  # (new: REPO-03)
  references/
    glossary-en.md         # (expanded: REPO-07)
    glossary-es.md         # (expanded: REPO-07)
    ... (19 existing reference files unchanged)
```

### Pattern 1: README Hero Structure
**What:** A README that sells the project in 30 seconds with progressive depth.
**When to use:** Every open-source project landing page.
**Example:**
```markdown
<!-- Source: D-01 decision + best practices from github.com/jehna/readme-best-practices -->

# AgentBloc

> One-line tagline here

![version](badge-url) ![license](badge-url) ![Claude Code](badge-url)

3-line description paragraph.

## What is AgentBloc?

30-second pitch: problem, solution, audience.

## Quick Start

5-minute setup: clone, copy, invoke.

## How It Works

6-phase overview with ASCII flow diagram.

## Examples

Links to 3 walkthroughs.

## Contributing | License
```

### Pattern 2: Example Walkthrough Structure
**What:** A consistent structure for demonstrating a full AgentBloc 6-phase flow.
**When to use:** Each of the 3 example files.
**Example:**
```markdown
<!-- Source: D-05 decision -->

# [Business Name] -- AgentBloc Walkthrough

## Business Context
Who, what industry, what problem (3-5 lines).

## Phase 1: Interview Summary
Key discoveries across 9 categories. NOT the full transcript.

## Phase 2: Agent Team Design
Agent list table + topology choice + ASCII topology diagram.

## Phase 3: Integration Findings
Per-agent integration decisions (recommended + fallback). Trust scores.

## Phase 4: Confirmed Agent Cards
Per-agent summary: actions, integrations, blast-radius, schedule.

## Phase 5: Deployment Artifacts
Key .agentbloc/ files shown (team.yaml excerpt, one agent.yaml excerpt).
Directory tree of what was generated.

## Phase 6: Evolution Notes
What the weekly scan would check. One example patch proposal.
```

### Pattern 3: Glossary Format
**What:** Alphabetically ordered term definitions with consistent formatting.
**When to use:** Both glossary files (EN + ES).
**Example:**
```markdown
<!-- Source: existing glossary-en.md format -->

**Agent**: A specialized AI assistant that performs one specific job in your workflow.

**Blast-Radius**: A security score (1-4) measuring how much damage an agent
could cause if it malfunctioned. Higher scores require human approval.
```

### Pattern 4: Shields.io Badge Row
**What:** Three badges inline at the top of README.
**When to use:** README.md badges row (REPO-06).
**Example:**
```markdown
<!-- Source: VERIFIED at shields.io -->

![version: 1.0.0](https://img.shields.io/badge/version-1.0.0-blue)
![license: MIT](https://img.shields.io/badge/license-MIT-green)
![Claude Code: v2.1+](https://img.shields.io/badge/Claude%20Code-v2.1%2B-blueviolet)
```

### Anti-Patterns to Avoid
- **YAML dumps in examples:** Examples should show key decisions, not full 50-line YAML files. D-06 explicitly caps walkthroughs at 150-250 lines.
- **Salesy language in README:** D-02 says "professional but approachable," not marketing copy. Think engineer-to-engineer.
- **Literal English-to-Spanish translations:** D-08 requires natural Spanish technical vocabulary. "Flujo de trabajo" not "workflow" where Spanish has its own term, but keep universally-adopted English terms like API, webhook, cron. [VERIFIED: Xataka article on Spanish tech terminology confirms this convention]
- **Oversized glossary definitions:** Glossary is for quick lookup. Each definition should be 1-2 sentences max.
- **README quickstart requiring non-Claude-Code setup:** D-03 assumes the user already has Claude Code installed. Do not add Node.js installation, npm, or other prerequisites beyond "clone and copy."

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Badge images | Custom SVG files | Shields.io URL pattern | Auto-generated, consistent style, zero maintenance |
| License text | Paraphrased license | OSI canonical MIT text | Legal accuracy matters. Use the exact standard text |
| Code of conduct | Custom conduct rules | Contributor Covenant 2.1 | Industry standard, well-understood, legally reviewed |
| Changelog format | Ad-hoc format | Keep a Changelog (keepachangelog.com) | Established convention, machine-parseable, community-recognized |
| Security disclosure template | Custom disclosure process | GitHub SECURITY.md best practices | GitHub natively detects SECURITY.md and surfaces it in the Security tab |

**Key insight:** This phase is entirely documentation. Every file has an established convention. Following conventions reduces friction for contributors who have seen these patterns in hundreds of other repos.

## Common Pitfalls

### Pitfall 1: Quickstart That Doesn't Work
**What goes wrong:** The 5-minute quickstart has a step that fails because the directory structure doesn't match, or a path is wrong.
**Why it happens:** Writing instructions without verifying them against the actual repo structure.
**How to avoid:** The quickstart must reference the actual repo structure. Steps are: `git clone`, `mkdir -p ~/.claude/skills/agentbloc`, `cp -r SKILL.md references/ examples/ ~/.claude/skills/agentbloc/`, invoke. Each step must be tested against the real directory layout.
**Warning signs:** Any quickstart step that references a file or directory not in the repo.

### Pitfall 2: Examples That Don't Match the Skill Protocols
**What goes wrong:** An example walkthrough describes an interview with 5 questions, but phase-1-interview.md specifies 9 categories and one-question-at-a-time.
**Why it happens:** Writing examples from imagination instead of the actual reference files.
**How to avoid:** Each example section must be consistent with the corresponding phase reference file. The implementer MUST read the phase reference files before writing examples.
**Warning signs:** Example mentions a "topology" not in the 4 supported types (pipeline/mesh/hierarchy/swarm), or skips a phase, or bundles interview questions.

### Pitfall 3: Glossary Terms That Miss Key Concepts
**What goes wrong:** The glossary has 30+ terms but misses terms that non-technical users actually encounter during a session.
**Why it happens:** Generating terms from memory instead of scanning the actual codebase.
**How to avoid:** Grep the entire references/ directory and SKILL.md for bolded terms, technical jargon, and concepts that appear in user-facing output. The glossary should cover every term a non-technical user would encounter.
**Warning signs:** A reference file uses a term (e.g., "correlation ID", "DSAR", "PSD2") that has no glossary entry.

### Pitfall 4: Spanish Glossary With Unnatural Translations
**What goes wrong:** Translating "webhook" as "gancho web" or "kill switch" as "interruptor de muerte" when native Spanish tech speakers would just say "webhook" and "kill switch."
**Why it happens:** Literal translation without knowledge of Spanish technical conventions.
**How to avoid:** D-08 provides the rule: use natural Spanish technical vocabulary. Some English terms are universal in Spanish tech (API, webhook, cron, OAuth). Others have standard Spanish equivalents (workflow = flujo de trabajo, blast radius = radio de impacto). [VERIFIED: Xataka 2026 article confirms these conventions]
**Warning signs:** A translated term that a Spanish-speaking developer would not recognize or would find awkward.

### Pitfall 5: CHANGELOG Not Reflecting Actual Phases
**What goes wrong:** CHANGELOG entries are generic ("initial release") without reflecting what each phase actually built.
**Why it happens:** Writing the changelog without reviewing what each phase delivered.
**How to avoid:** D-12 says entries for each phase completed. Review the ROADMAP.md phase descriptions and success criteria to write accurate changelog entries.
**Warning signs:** A changelog entry that doesn't map to a specific phase or requirement.

### Pitfall 6: Version Field Breaking SKILL.md
**What goes wrong:** Adding `version: 1.0.0` to the frontmatter causes a parsing issue or unexpected behavior.
**Why it happens:** `version` is not an officially recognized SKILL.md frontmatter field.
**How to avoid:** Claude Code silently ignores unknown frontmatter fields. Adding `version: 1.0.0` is safe. It has no runtime effect but serves as a human-readable version indicator in the file itself. The CHANGELOG.md is the authoritative version record. [VERIFIED: code.claude.com/docs/en/skills confirms unknown frontmatter fields are ignored]
**Warning signs:** None expected. This is a cosmetic addition.

## Code Examples

Verified patterns from official sources:

### MIT License Text
```text
# Source: opensource.org/license/mit (VERIFIED)

MIT License

Copyright (c) 2026 AgentBloc contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### CHANGELOG.md Format
```markdown
# Source: keepachangelog.com/en/1.0.0/ (VERIFIED)

# Changelog

All notable changes to AgentBloc are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-14

### Added
- Phase 1: SKILL.md lean hub with state protocol, gates, bilingual support,
  progressive disclosure (ARCH-01 through ARCH-08)
- Phase 2: 9 security cross-cutting reference files covering credentials,
  data classification, blast-radius, audit logging, GDPR, incident response,
  prompt injection, and tenant isolation (SECR-01 through SECR-09)
- Phase 3: Interview protocol (9-category deep interview) and Design protocol
  (topology, contracts, governance, blast-radius scoring) (INTV-01 through DESG-08)
- Phase 4: Integration analysis protocol (multi-method search, trust scoring)
  and Confirmation + Dry Run protocol (sequential approval, dual-layer enforcement)
  (INTG-01 through CONF-05)
- Phase 5: Deployment artifact generation templates (11 artifact types) and
  Evolution loop protocol (scan-detect-propose-approve) (DEPL-01 through EVOL-05)
- Phase 6: README, examples, glossaries, repo meta-files, versioning
  (REPO-01 through REPO-08, ARCH-09)
```

### SECURITY.md Template
```markdown
# Source: GitHub docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository (VERIFIED)

# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in AgentBloc, please report it
responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, email: [security contact email]

### What to include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgment:** Within 48 hours
- **Assessment:** Within 5 business days
- **Fix for critical issues:** Within 7 days
- **Fix for non-critical issues:** Within 30 days

### Disclosure Policy

We follow coordinated disclosure. We will work with you to understand and
address the issue before any public disclosure.
```

### SKILL.md Version Field Addition
```yaml
# Source: VERIFIED that unknown frontmatter fields are silently ignored
# (code.claude.com/docs/en/skills)

---
name: agentbloc
version: 1.0.0
description: >
  Designs and deploys AI agent teams for businesses through a structured
  6-phase conversational flow...
allowed-tools: Read Grep Glob WebSearch WebFetch Bash
---
```

### Shields.io Badge Markdown
```markdown
# Source: VERIFIED at shields.io

![version: 1.0.0](https://img.shields.io/badge/version-1.0.0-blue)
![license: MIT](https://img.shields.io/badge/license-MIT-green)
![Claude Code: v2.1+](https://img.shields.io/badge/Claude%20Code-v2.1%2B-blueviolet)
```

## Glossary Term Catalog

Terms to include in the expanded glossaries (30+ minimum). Gathered by scanning all reference files and SKILL.md in the codebase. [VERIFIED: grep of references/ and SKILL.md]

### Core AgentBloc Concepts
1. Agent
2. Agent Team
3. Topology (Pipeline, Hierarchy, Mesh, Swarm)
4. Phase (the 6-phase flow)
5. Gate (approval gate)
6. Blast-Radius
7. Dry Run
8. Kill Switch
9. State File
10. Governance

### Integration and Technical
11. MCP Server
12. API
13. Webhook
14. OAuth
15. Cron
16. Playwright (browser automation)
17. Trust Score
18. Fallback Chain
19. Decision Matrix

### Security and Compliance
20. PII (Personally Identifiable Information)
21. PHI (Protected Health Information)
22. GDPR
23. HIPAA
24. PCI
25. DSAR (Data Subject Access Request)
26. Audit Log
27. Correlation ID
28. Prompt Injection
29. Credential Hierarchy
30. Rate Limiting

### Deployment and Operations
31. Artifact
32. ClaudeClaw / Job Definition
33. State Schema
34. Idempotency
35. Telegram Thread
36. Evolution Loop

### Additional Candidates (Claude's discretion per D-07)
37. Subagent
38. Progressive Disclosure
39. Tenant Isolation
40. PSD2 / Open Banking
41. Notification Discipline
42. Contract (agent contract)

### Spanish Translation Notes
| English Term | Spanish Term | Notes |
|-------------|-------------|-------|
| Workflow | Flujo de trabajo | Standard Spanish equivalent [VERIFIED: Xataka] |
| API | API | Universal, keep in English [VERIFIED: Xataka] |
| Webhook | Webhook | Universal, keep in English [VERIFIED: Xataka] |
| Cron | Cron | Universal Unix term, keep as-is |
| Kill Switch | Kill switch | Widely adopted in Spanish tech; alternative: "interruptor de emergencia" |
| Blast-Radius | Radio de impacto | Natural Spanish equivalent [ASSUMED] |
| Dry Run | Ejecucion de prueba | Already used in existing glossary-es.md [VERIFIED: glossary-es.md] |
| Pipeline | Pipeline | Universally adopted in Spanish tech [ASSUMED] |
| OAuth | OAuth | Protocol name, never translated |
| PII | Datos personales identificables (DPI) | GDPR uses "datos personales" [ASSUMED] |
| GDPR | RGPD (Reglamento General de Proteccion de Datos) | Official EU Spanish name [ASSUMED] |
| Audit Log | Registro de auditoria | Standard Spanish [ASSUMED] |
| Trust Score | Puntuacion de confianza | Natural translation [ASSUMED] |
| State File | Archivo de estado | Direct translation, natural [ASSUMED] |

## Example Topology Assignments

Each walkthrough should demonstrate a different topology to showcase AgentBloc's versatility (per CONTEXT.md specifics section):

| Example | Topology | Rationale |
|---------|----------|-----------|
| Arco Rooms (real estate) | Pipeline | Sequential flow: collect invoices, match payments, report. Each agent's output feeds the next. Already established in existing reference files. [VERIFIED: phase-2-design.md uses Arco Rooms as pipeline example] |
| E-commerce Support | Hierarchy | Coordinator agent routes to specialist workers (order tracker, refund processor, escalation handler). Different request types need different agents. [ASSUMED] |
| Freelance Pipeline | Pipeline | Sequential business lifecycle: lead capture, proposal generation, invoice tracking. Natural linear flow. [ASSUMED] |

**Note:** The CONTEXT.md specifics section suggests hierarchy for ecommerce and pipeline for freelance. The planner should follow this guidance.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual README badges with hardcoded SVGs | Shields.io URL-based dynamic badges | Standard since ~2015, widely adopted | Zero maintenance, consistent styling |
| Freeform changelogs | Keep a Changelog format | keepachangelog.com v1.0.0 (2017), widely adopted | Machine-parseable, contributor-friendly |
| Custom codes of conduct | Contributor Covenant 2.1 | Version 2.1 released 2021, current standard | Industry recognition, legal review included |
| GitHub advisory-only security | SECURITY.md at repo root | GitHub natively surfaces SECURITY.md since 2019 | Discoverable, standardized disclosure process |

**Deprecated/outdated:**
- GitHub-flavored markdown badges (old style `[![Build Status]()]`): Still work but shields.io provides better consistency
- CHANGELOG without version headers: Keep a Changelog makes version tracking explicit

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | "Radio de impacto" is the natural Spanish translation for "blast-radius" | Spanish Translation Notes | LOW: easy to correct during implementation. Native speaker review flagged in STATE.md |
| A2 | PII translates to "Datos personales identificables (DPI)" in Spanish GDPR context | Spanish Translation Notes | LOW: GDPR uses "datos personales" but the acronym DPI may not be standard |
| A3 | "RGPD" is the official Spanish acronym for GDPR | Spanish Translation Notes | LOW: well-established EU term, but should verify |
| A4 | "Registro de auditoria" is the standard Spanish for "Audit Log" | Spanish Translation Notes | LOW: standard accounting/compliance term |
| A5 | "Puntuacion de confianza" is the natural Spanish for "Trust Score" | Spanish Translation Notes | LOW: natural translation, but "score" might stay as "score" in tech Spanish |
| A6 | "Archivo de estado" is the natural Spanish for "State File" | Spanish Translation Notes | LOW: direct translation |
| A7 | "Pipeline" stays as "Pipeline" in Spanish tech | Spanish Translation Notes | LOW: very widely adopted English loanword |
| A8 | E-commerce example uses hierarchy topology | Example Topology Assignments | LOW: CONTEXT.md specifics section explicitly suggests this |
| A9 | Freelance example uses pipeline topology | Example Topology Assignments | LOW: CONTEXT.md specifics section explicitly suggests this |

**Risk assessment:** All assumptions are LOW risk. Most are Spanish translation choices that are easily correctable. STATE.md already flags Spanish glossary for native-speaker review. No assumptions affect architectural decisions.

## Open Questions

1. **Security contact email for SECURITY.md**
   - What we know: D-11 specifies SECURITY.md should have a vulnerability disclosure process
   - What's unclear: No email address has been specified for security reports
   - Recommendation: Use a placeholder like `security@agentbloc.dev` or `[INSERT SECURITY EMAIL]` and flag for the user to replace. The planner should include this as a task note.

2. **CONTRIBUTING.md testing requirements**
   - What we know: D-10 says CONTRIBUTING.md should include testing requirements
   - What's unclear: Phase 7 (Testing and CI) hasn't been built yet. There is no test harness to reference.
   - Recommendation: Write testing requirements section as a placeholder that references Phase 7 deliverables. State that contributors should run `npm run test:agentbloc` (per TEST-03) once available, and that markdown linting is the minimum bar for v1.0.

3. **README "How It Works" diagram format**
   - What we know: D-01 specifies a "How It Works" section with a 6-phase overview with diagram
   - What's unclear: ASCII art vs. Mermaid vs. text description
   - Recommendation: Use ASCII art (like the existing SKILL.md phase flow). This is consistent with the codebase and renders in all markdown viewers. Mermaid requires GitHub rendering support and not all viewers support it.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual review (documentation phase) |
| Config file | None (no automated tests for markdown) |
| Quick run command | Visual inspection of rendered markdown |
| Full suite command | `markdownlint **/*.md` (available in Phase 7) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REPO-01 | README explains AgentBloc in 30s, quickstart in 5min | manual-only | Visual review of README.md | No (Wave 0) |
| REPO-02 | Installation instructions work | manual-only | Execute quickstart steps on clean machine | No (Wave 0) |
| REPO-03 | 3 example walkthroughs demonstrate full 6-phase flow | manual-only | Verify each example has all 6 phase sections | No (Wave 0) |
| REPO-04 | CONTRIBUTING.md present with guidelines | manual-only | `test -f CONTRIBUTING.md` | No (Wave 0) |
| REPO-05 | LICENSE file present | manual-only | `test -f LICENSE` | No (Wave 0) |
| REPO-06 | Badges render correctly | manual-only | Verify badge URLs return HTTP 200 | No (Wave 0) |
| REPO-07 | Glossary files with 30+ terms each | manual-only | Count terms in glossary files | No (Wave 0) |
| REPO-08 | SECURITY.md present with required sections | manual-only | `test -f SECURITY.md` | No (Wave 0) |
| ARCH-09 | Version in SKILL.md frontmatter, CHANGELOG at root | manual-only | `grep 'version:' SKILL.md && test -f CHANGELOG.md` | No (Wave 0) |

### Sampling Rate
- **Per task commit:** Visual review of generated markdown files
- **Per wave merge:** Full checklist verification against CONTEXT.md decisions
- **Phase gate:** All 9 requirements verified present and formatted correctly

### Wave 0 Gaps
- [ ] No automated markdown linting yet (Phase 7 scope)
- [ ] No link-rot checking yet (Phase 7 scope)
- [ ] Verification is manual for this phase; automated validation comes in Phase 7

*(Phase 7 will add markdownlint, link-rot checks, and CI pipeline that retroactively validates Phase 6 deliverables)*

## Security Domain

This phase creates documentation files only. No executable code, no secrets, no data processing.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A (documentation only) |
| V3 Session Management | No | N/A (documentation only) |
| V4 Access Control | No | N/A (documentation only) |
| V5 Input Validation | No | N/A (documentation only) |
| V6 Cryptography | No | N/A (documentation only) |

### Security Considerations Specific to This Phase

| Concern | Mitigation |
|---------|-----------|
| Accidental secret inclusion in examples | Examples must use placeholder values (e.g., `BOT_TOKEN=your-telegram-bot-token`), never real credentials |
| SECURITY.md email exposure | Use a role-based email (security@domain), not a personal email |
| LICENSE accuracy | Use exact OSI canonical MIT text, not a paraphrase |

## Sources

### Primary (HIGH confidence)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- frontmatter reference, supported fields, unknown field handling
- [Shields.io](https://shields.io/) -- badge URL syntax, static badge format
- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) -- CHANGELOG.md format specification
- [MIT License (OSI)](https://opensource.org/license/mit) -- canonical license text
- [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) -- code of conduct template
- [GitHub SECURITY.md docs](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository) -- security policy best practices

### Secondary (MEDIUM confidence)
- [GitHub README Best Practices](https://github.com/jehna/readme-best-practices) -- README structure patterns
- [Xataka: Workflow automation in Spanish](https://www.xataka.com/basics/workflow-flujo-trabajo-que-que-tipos-hay-como-funcionan-automatizados-inteligencia-artificial) -- Spanish technical vocabulary conventions

### Codebase (HIGH confidence)
- `SKILL.md` (158 lines) -- current frontmatter, phase structure, reference links
- `examples/arco-rooms.md` (50 lines) -- existing example to expand, 11 patterns documented
- `references/glossary-en.md` (29 lines) -- existing stub with 8 terms, format established
- `references/glossary-es.md` (29 lines) -- existing stub with 8 terms, format established
- `references/phase-1-interview.md` through `references/phase-6-evolution.md` -- all phase protocols for example accuracy
- `references/blast-radius.md` -- scoring levels for glossary definitions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools are well-documented, established standards with canonical sources
- Architecture: HIGH -- file structure is straightforward markdown, patterns from CONTEXT.md decisions are explicit
- Pitfalls: HIGH -- documented from direct analysis of the codebase and established open-source conventions
- Spanish translations: MEDIUM -- several translations are assumed and flagged for native-speaker review

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (stable domain, documentation conventions change slowly)
