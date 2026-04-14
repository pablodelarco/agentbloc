# Roadmap: AgentBloc

## Overview

AgentBloc transforms from a monolithic 539-line SKILL.md into a production-ready progressive-disclosure skill across seven phases. The journey starts with restructuring the hub file and state protocol (foundation), then establishes the security framework that all user-facing phases depend on (data classification, blast-radius scoring, credential management, compliance patterns). With security structural, the six conversational phase references are built in dependency order: interview/design (which classify PII/PHI and assign blast-radius scores against the security framework), then integration/confirmation (which filter by trust-score and enforce security governance). Deployment artifacts and the evolution loop follow, then repo polish for public launch, and finally replayable test scenarios and CI.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Skill Foundation** - Restructure SKILL.md as lean hub with state protocol, gates, bilingual support, and progressive disclosure pointers
- [x] **Phase 2: Security Cross-Cutting References** - Build all 9 security reference files that cross-cut the conversational phases (must exist before interview classifies data or design assigns blast-radius)
- [ ] **Phase 3: Interview and Design Phases** - Build reference files for the Interview (Phase 1) and Design (Phase 2) conversational phases, referencing security framework for data classification and blast-radius
- [ ] **Phase 4: Integration and Confirmation Phases** - Build reference files for Integration Analysis (Phase 3) and Confirmation + Dry Run (Phase 4) conversational phases, filtering by trust-score and enforcing security governance
- [ ] **Phase 5: Deployment Artifacts and Evolution** - Build deployment artifact templates, the Deployment (Phase 5) reference, and the Evolution (Phase 6) self-improvement loop
- [ ] **Phase 6: Repo Polish and Examples** - README, examples, glossaries, badges, CONTRIBUTING, LICENSE, SECURITY.md, CHANGELOG, and versioning
- [ ] **Phase 7: Testing and CI** - Replayable test scenarios, test harness, and GitHub Actions CI pipeline

## Phase Details

### Phase 1: Skill Foundation
**Goal**: Claude reliably follows AgentBloc instructions throughout long multi-phase conversations because SKILL.md is a lean hub with structural enforcement
**Depends on**: Nothing (first phase)
**Requirements**: ARCH-01, ARCH-02, ARCH-03, ARCH-04, ARCH-05, ARCH-06, ARCH-07, ARCH-08
**Success Criteria** (what must be TRUE):
  1. SKILL.md is under 250 lines with YAML frontmatter, identity section, hard gate definitions, phase summaries, and reference pointers to a references/ directory
  2. Every simulated Claude response in an AgentBloc session begins with the `[AGENTBLOC | PHASE: N | GATE: status | TECH: level]` state line
  3. Phase transitions require explicit user approval and cannot be skipped; attempting to skip triggers a gate-enforcement message
  4. Conversation language is auto-detected (English/Spanish) and all responses adapt accordingly
  5. Technical level is assessed in the first interaction and shapes vocabulary and depth across all subsequent phases
**Plans:** 2 plans

Plans:
- [x] 01-01-PLAN.md -- Rewrite SKILL.md as lean hub + extract Arco Rooms to examples/
- [x] 01-02-PLAN.md -- Create all 19 reference stub files in flat references/ directory

### Phase 2: Security Cross-Cutting References
**Goal**: Every security-sensitive decision across all conversational phases is backed by a dedicated reference file with actionable patterns, so that interview, design, integration, and deployment phases can reference a structural security framework rather than improvising
**Depends on**: Phase 1
**Requirements**: SECR-01, SECR-02, SECR-03, SECR-04, SECR-05, SECR-06, SECR-07, SECR-08, SECR-09
**Success Criteria** (what must be TRUE):
  1. Credential management reference provides a decision tree (OAuth > scoped API key > admin token), rotation policy, and log redaction rules
  2. Data classification reference categorizes PII/PHI/financial/public data during interview and specifies retention schedules and deletion workflows
  3. GDPR patterns (right to be forgotten, DSAR, 72h breach notification) and HIPAA/PCI-ready patterns activate automatically when data classification warrants
  4. Every deployed agent ships with kill switch capability, rate limiting, audit logging with correlation IDs and PII redaction, and prompt injection defenses
  5. Blast-radius scoring is enforced in design phase; agents with write-unrestricted or send-external scope automatically require human approval
**Plans:** 3 plans

Plans:
- [ ] 02-01-PLAN.md -- Populate credentials.md, data-classification.md, blast-radius.md with classification and scoring patterns
- [ ] 02-02-PLAN.md -- Populate audit-logging.md (+ rate limiting) and gdpr-patterns.md (+ HIPAA/PCI) with compliance governance patterns
- [ ] 02-03-PLAN.md -- Populate incident-response.md (+ kill switch), prompt-injection.md, and tenant-isolation.md with defense and response patterns

### Phase 3: Interview and Design Phases
**Goal**: The skill can conduct a deep structured interview and produce a complete agent team design with topology, contracts, and governance specs, classifying data against the security framework and assigning blast-radius scores per the security references
**Depends on**: Phase 2
**Requirements**: INTV-01, INTV-02, INTV-03, INTV-04, DESG-01, DESG-02, DESG-03, DESG-04, DESG-05, DESG-06, DESG-07, DESG-08
**Success Criteria** (what must be TRUE):
  1. The Interview phase covers all 9 categories (Problem, Workflow, Services, Data, Data Classification, People, Edge Cases, Reporting, Budget/Constraints), asking questions one at a time with adaptive follow-ups
  2. Interview concludes with a summary of understanding that the user must explicitly confirm before advancing
  3. Design phase produces agent identification, topology selection, per-agent contracts, schedule definitions, governance specs, and blast-radius scores
  4. A visual agent interaction diagram (ASCII) and agent summary table are generated during design
  5. Best-of-breed framework patterns (CrewAI, LangGraph, n8n) are referenced during design decisions
**Plans:** 3 plans

Plans:
- [ ] 03-01-PLAN.md -- Populate interview protocol (phase-1-interview.md) with 9-category deep interview + adjust SKILL.md unconditional loading
- [ ] 03-02-PLAN.md -- Populate design protocol (phase-2-design.md) with agent identification, topology, contracts, governance, blast-radius, and visual presentation
- [ ] 03-03-PLAN.md -- Populate framework patterns reference (frameworks.md) with CrewAI, LangGraph, and n8n pattern mappings

### Phase 4: Integration and Confirmation Phases
**Goal**: The skill can analyze integrations with evidence-backed recommendations and execute a mandatory dry run before deployment, filtering by trust-score and enforcing security governance from the security framework
**Depends on**: Phase 3
**Requirements**: INTG-01, INTG-02, INTG-03, INTG-04, INTG-05, CONF-01, CONF-02, CONF-03, CONF-04, CONF-05
**Success Criteria** (what must be TRUE):
  1. Integration analysis searches multiple methods per action (API, MCP, Playwright, email, webhook) and presents a decision matrix with recommended/alternative/fallback options
  2. Every integration claim includes URL + package version + last-commit date; missing evidence is marked [UNVERIFIED]
  3. Trust score per dependency evaluates GitHub stars, publisher verification, last commit recency, and known CVEs; low-trust dependencies are flagged
  4. Each agent is presented individually for step-by-step confirmation with actions, integrations, outputs, failure handling, and permissions
  5. A mandatory dry run executes against real records with all side-effect tools stubbed, producing a report of what ran and what would have been sent/written; user must review and approve before proceeding to deployment
**Plans:** 2 plans

Plans:
- [x] 04-01-PLAN.md -- Populate integration analysis protocol (phase-3-integration.md) with multi-method search, evidence verification, trust scoring, decision matrices, and security cross-references
- [x] 04-02-PLAN.md -- Populate confirmation and dry run protocol (phase-4-confirmation.md) with sequential agent approval, dry run dual-layer enforcement, report generation, and final approval gate

### Phase 5: Deployment Artifacts and Evolution
**Goal**: The skill generates a complete, immediately runnable .agentbloc/ artifact directory and provides a post-deployment self-improvement loop with human approval
**Depends on**: Phase 4
**Requirements**: DEPL-01, DEPL-02, DEPL-03, DEPL-04, DEPL-05, DEPL-06, DEPL-07, DEPL-08, DEPL-09, DEPL-10, DEPL-11, EVOL-01, EVOL-02, EVOL-03, EVOL-04, EVOL-05
**Success Criteria** (what must be TRUE):
  1. A .agentbloc/ directory is generated containing team.yaml, per-agent YAML, per-agent skill markdown, governance.yaml, telegram.yaml, state schemas, ClaudeClaw job definitions, and incident response runbook
  2. All generated artifacts are immediately runnable on Claude Code + cron + MCP + Telegram with zero custom runtime dependencies
  3. SUMMARY.md deployment guide provides complete setup steps, monitoring instructions, and modification guidance
  4. Evolution phase performs weekly scans for new capabilities and vulnerabilities in used dependencies, generating patch proposals that require human approval before application
**Plans:** 3 plans

Plans:
- [x] 05-01-PLAN.md -- Populate deployment artifact generation protocol (phase-5-deployment.md) with complete YAML/JSON/markdown templates for all .agentbloc/ artifacts
- [x] 05-02-PLAN.md -- Populate evolution protocol (phase-6-evolution.md) with scan-detect-propose-approve loop and human approval gate
- [x] 05-03-PLAN.md -- Populate scheduling patterns (scheduling.md) and Telegram reporting patterns (telegram-patterns.md) supporting references

### Phase 6: Repo Polish and Examples
**Goal**: The GitHub repo sells AgentBloc's vision in 30 seconds and lets a user try it in 5 minutes, with professional documentation and example walkthroughs
**Depends on**: Phase 5
**Requirements**: REPO-01, REPO-02, REPO-03, REPO-04, REPO-05, REPO-06, REPO-07, REPO-08, ARCH-09
**Success Criteria** (what must be TRUE):
  1. README.md explains AgentBloc in 30 seconds (what it is, who it is for) and provides 5-minute quickstart (clone, copy to skills, invoke)
  2. Three complete example walkthroughs (real estate ops, ecommerce support, freelance pipeline) demonstrate a full 6-phase flow end to end
  3. Bilingual glossary files (English + Spanish) define all technical terms for non-technical users
  4. SECURITY.md, CONTRIBUTING.md, LICENSE, CHANGELOG.md, and version badges are present and accurate
**Plans:** 3 plans

Plans:
- [x] 06-01-PLAN.md -- Create README.md with hero, badges, quickstart, how-it-works + repo meta-files (LICENSE, CONTRIBUTING, SECURITY, CHANGELOG) + SKILL.md version field
- [x] 06-02-PLAN.md -- Write three example walkthroughs (arco-rooms expansion, ecommerce-support, freelance-pipeline) demonstrating full 6-phase flows
- [x] 06-03-PLAN.md -- Expand bilingual glossaries (EN + ES) from 8 terms to 35+ terms covering all AgentBloc concepts

### Phase 7: Testing and CI
**Goal**: Every example walkthrough has a replayable test scenario that validates the full 6-phase flow, runnable locally and in CI
**Depends on**: Phase 6
**Requirements**: TEST-01, TEST-02, TEST-03, REPO-09
**Success Criteria** (what must be TRUE):
  1. A replayable user-turn JSONL format exists for simulating onboarding scenarios
  2. Three canonical test scenarios (one per example walkthrough) replay a full 6-phase flow with artifact snapshot assertions
  3. A test runner executes all scenarios locally and reports pass/fail with artifact validation
  4. GitHub Actions CI pipeline runs markdown lint, YAML schema validation, test scenarios, and link-rot checks; green badge displayed in README
**Plans**: TBD

Plans:
- [ ] 07-01: TBD
- [ ] 07-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7

**Dependency Chain:**
Foundation -> Security -> Interview/Design -> Integration/Confirmation -> Deployment/Evolution -> Repo -> Testing

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Skill Foundation | 0/2 | Planning complete | - |
| 2. Security Cross-Cutting References | 0/3 | Planning complete | - |
| 3. Interview and Design Phases | 0/3 | Planning complete | - |
| 4. Integration and Confirmation Phases | 0/2 | Planning complete | - |
| 5. Deployment Artifacts and Evolution | 0/3 | Planning complete | - |
| 6. Repo Polish and Examples | 0/3 | Planning complete | - |
| 7. Testing and CI | 0/2 | Not started | - |
