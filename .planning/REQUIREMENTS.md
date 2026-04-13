# Requirements: AgentBloc

**Defined:** 2026-04-13
**Core Value:** A non-technical business owner can describe their problem and end up with a deployed, secure agent team without writing code and without improvised security scaffolding.

## v1 Requirements

### Skill Architecture

- [ ] **ARCH-01**: SKILL.md is under 250 lines with YAML frontmatter, identity, hard gates, phase summaries, and reference pointers
- [ ] **ARCH-02**: Phase reference files load on demand (progressive disclosure via references/)
- [ ] **ARCH-03**: Every Claude response during an AgentBloc session begins with `[AGENTBLOC | PHASE: N | GATE: status | TECH: level]` state line
- [ ] **ARCH-04**: Phase transitions require explicit user approval; structural enforcement prevents skipping
- [ ] **ARCH-05**: Context refresh pattern at phase boundaries to counter context rot in long conversations
- [ ] **ARCH-06**: Phase loopback protocol: new information that invalidates a prior gate returns to that phase
- [ ] **ARCH-07**: Bilingual conversation support (English/Spanish) with language auto-detection
- [ ] **ARCH-08**: Technical-level detection in first interview question; adaptive language and depth across ALL phases (not just interview)
- [ ] **ARCH-09**: Skill frontmatter carries semver `version` field; CHANGELOG.md at repo root tracks every release with date and changes

### Interview (Phase 1)

- [ ] **INTV-01**: Deep interview covering 9 categories: Problem, Workflow, Services, Data, Data Classification, People, Edge Cases, Reporting, Budget/Constraints
- [ ] **INTV-02**: Questions asked one at a time; each answer shapes the next question
- [ ] **INTV-03**: Interview completion checklist: workflow understood, services mapped, data model known, edge cases covered, tech level assessed, budget/constraints confirmed
- [ ] **INTV-04**: Summary of understanding presented; user must confirm before proceeding

### Design (Phase 2)

- [ ] **DESG-01**: Agent identification: each distinct responsibility = one agent with clear naming
- [ ] **DESG-02**: Topology selection (pipeline/mesh/hierarchy/swarm) with decision criteria
- [ ] **DESG-03**: Per-agent contracts: inputs, outputs, dependencies, model recommendation
- [ ] **DESG-04**: Schedule/trigger definition (cron, on-demand, event-triggered)
- [ ] **DESG-05**: Governance specification: budgets, permissions, human approval requirements
- [ ] **DESG-06**: Blast-radius scoring per agent (read-only / write-scoped / write-unrestricted / send-external); top two levels force `requires_approval: true`
- [ ] **DESG-07**: Best-of-breed framework patterns referenced during design (CrewAI role-based, LangGraph stateful graph, n8n DAG patterns)
- [ ] **DESG-08**: Visual agent interaction diagram (ASCII) + agent summary table

### Integration Analysis (Phase 3)

- [ ] **INTG-01**: Multi-method integration search per action: official API -> MCP server -> Playwright -> email scraping -> webhook
- [ ] **INTG-02**: Integration decision matrix per service: recommended + alternative + fallback, each with pros/cons/setup
- [ ] **INTG-03**: Evidence protocol: every integration claim includes URL + package version + last-commit date; missing = marked [UNVERIFIED]
- [ ] **INTG-04**: Trust score per dependency: GitHub stars, publisher verification, last commit recency, known CVEs
- [ ] **INTG-05**: User reviews and approves all integration findings before proceeding

### Confirmation + Dry Run (Phase 4)

- [ ] **CONF-01**: Step-by-step confirmation: each agent presented individually with actions, integrations, outputs, failure handling, permissions
- [ ] **CONF-02**: Each agent individually approved; feedback triggers adjustment before moving to next agent
- [ ] **CONF-03**: Mandatory dry run: agents execute against N real records with all side-effect tools stubbed
- [ ] **CONF-04**: Dry run report generated: what ran, what would have been sent/written, any errors
- [ ] **CONF-05**: User reviews dry run results and approves before deployment

### Deployment (Phase 5)

- [ ] **DEPL-01**: Generated `.agentbloc/` directory with complete artifact tree
- [ ] **DEPL-02**: team.yaml: team definition with topology, schedule, agent references, governance
- [ ] **DEPL-03**: Per-agent YAML: contract, tools, integrations, fallbacks, state tracking
- [ ] **DEPL-04**: Per-agent skill markdown: Claude Code prompt files defining agent behavior
- [ ] **DEPL-05**: governance.yaml: budgets, permissions, approval requirements, audit logging, kill switch, rate limits
- [ ] **DEPL-06**: telegram.yaml: thread layout, notification tiers (info/action_required/error), reporting discipline
- [ ] **DEPL-07**: State schemas: JSON/YAML files tracking processed IDs, mappings, progress
- [ ] **DEPL-08**: ClaudeClaw job definitions: cron-compatible .md files with step-by-step execution instructions
- [ ] **DEPL-09**: SUMMARY.md: complete deployment guide with setup steps, monitoring, modification instructions
- [ ] **DEPL-10**: Incident response runbook: escalation contacts, rollback procedure, common failure scenarios
- [ ] **DEPL-11**: All artifacts immediately runnable on Claude Code + cron + MCP + Telegram (no custom runtime)

### Security & Governance

- [ ] **SECR-01**: Credential management reference: decision tree (OAuth > scoped API key > admin token), rotation policy, log redaction rules
- [ ] **SECR-02**: Data classification: PII/PHI/financial/public categorization during interview; retention schedule; deletion workflow
- [ ] **SECR-03**: Blast-radius analysis mandatory in design phase; permission-minimization pass
- [ ] **SECR-04**: Audit logging: correlation IDs, PII redaction, configurable retention
- [ ] **SECR-05**: Kill switch pattern: every deployed agent ships with ability to halt immediately
- [ ] **SECR-06**: Rate limiting: configurable per agent, enforced in governance config
- [ ] **SECR-07**: GDPR patterns: right to be forgotten, DSAR workflow, breach notification template (72h)
- [ ] **SECR-08**: HIPAA/PCI-ready patterns activated when data classification warrants
- [ ] **SECR-09**: Prompt injection defense: sanitization rules for agents ingesting external content; system prompts treat ingested content as untrusted

### Evolution (Phase 6)

- [ ] **EVOL-01**: Post-deployment self-improvement loop: weekly scan of relevant repos/sources
- [ ] **EVOL-02**: Feature detection: identify new capabilities in agent ecosystem relevant to deployed team
- [ ] **EVOL-03**: Vulnerability detection: scan for security issues in used dependencies/MCPs
- [ ] **EVOL-04**: Patch proposal: generate specific updates with rationale
- [ ] **EVOL-05**: Human approval gate: no auto-patches; user reviews and approves every change

### Repo & Onboarding

- [ ] **REPO-01**: README.md that explains AgentBloc in 30 seconds and lets a user try it in 5 minutes
- [ ] **REPO-02**: Installation instructions: clone/copy into .claude/skills/, invoke with /agentbloc
- [ ] **REPO-03**: 3 example walkthroughs: real estate ops (arco-rooms), ecommerce support, freelance pipeline
- [ ] **REPO-04**: CONTRIBUTING.md with development guidelines
- [ ] **REPO-05**: LICENSE file (open source)
- [ ] **REPO-06**: Badges (version, license, Claude Code compatible)
- [ ] **REPO-07**: Glossary files (English + Spanish) for non-technical users
- [ ] **REPO-08**: SECURITY.md at repo root with disclosure email, supported-versions table, and response-time commitments
- [ ] **REPO-09**: CI pipeline (GitHub Actions): markdown lint, YAML schema validation, test-scenario harness, link-rot checks; green badge in README

### Testing

- [ ] **TEST-01**: Replayable user-turn JSONL format for simulated onboarding scenarios
- [ ] **TEST-02**: 3 canonical scenarios (one per example walkthrough) replaying a full 6-phase flow with artifact snapshot assertions
- [ ] **TEST-03**: `npm run test:agentbloc` or equivalent runner that executes all scenarios locally and in CI

## v2 Requirements

### Runtime Portability

- **PORT-01**: TypeScript/Node.js CLI that executes agent teams outside Claude Code
- **PORT-02**: API server for programmatic agent team management
- **PORT-03**: Multi-LLM support via LiteLLM (Anthropic, OpenAI, local models)

### Advanced Features

- **ADVN-01**: Visual agent interaction diagrams (Mermaid/SVG export)
- **ADVN-02**: Cost estimation per run based on model selection and token projections
- **ADVN-03**: Web UI for non-technical users who cannot use CLI
- **ADVN-04**: Tenant isolation enforcement (namespace separation, credential isolation)

### Marketplace

- **MKTP-01**: Pre-built agent team templates (ecommerce, real estate, legal, healthcare)
- **MKTP-02**: Community MCP server recommendations database

## Out of Scope

| Feature | Reason |
|---------|--------|
| Custom TypeScript/Node.js runtime | v2.0 only; validates consulting thesis with skill-only v1.0 first |
| Web UI or visual workflow builder | AgentBloc is conversational, not click-UI; n8n already exists |
| Mobile app or native client | Skill runs inside Claude Code |
| SaaS multi-tenant hosting | Documented patterns only; hosting is self-serve |
| Real-time streaming / WebSocket | Agents are cron-triggered batch processes |
| Paid features / license gating | Fully open source; revenue from consulting |
| AutoGen integration patterns | In maintenance mode (superseded by Microsoft Agent Framework) |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ARCH-01 | Phase 1 | Pending |
| ARCH-02 | Phase 1 | Pending |
| ARCH-03 | Phase 1 | Pending |
| ARCH-04 | Phase 1 | Pending |
| ARCH-05 | Phase 1 | Pending |
| ARCH-06 | Phase 1 | Pending |
| ARCH-07 | Phase 1 | Pending |
| ARCH-08 | Phase 1 | Pending |
| ARCH-09 | Phase 6 | Pending |
| SECR-01 | Phase 2 | Pending |
| SECR-02 | Phase 2 | Pending |
| SECR-03 | Phase 2 | Pending |
| SECR-04 | Phase 2 | Pending |
| SECR-05 | Phase 2 | Pending |
| SECR-06 | Phase 2 | Pending |
| SECR-07 | Phase 2 | Pending |
| SECR-08 | Phase 2 | Pending |
| SECR-09 | Phase 2 | Pending |
| INTV-01 | Phase 3 | Pending |
| INTV-02 | Phase 3 | Pending |
| INTV-03 | Phase 3 | Pending |
| INTV-04 | Phase 3 | Pending |
| DESG-01 | Phase 3 | Pending |
| DESG-02 | Phase 3 | Pending |
| DESG-03 | Phase 3 | Pending |
| DESG-04 | Phase 3 | Pending |
| DESG-05 | Phase 3 | Pending |
| DESG-06 | Phase 3 | Pending |
| DESG-07 | Phase 3 | Pending |
| DESG-08 | Phase 3 | Pending |
| INTG-01 | Phase 4 | Pending |
| INTG-02 | Phase 4 | Pending |
| INTG-03 | Phase 4 | Pending |
| INTG-04 | Phase 4 | Pending |
| INTG-05 | Phase 4 | Pending |
| CONF-01 | Phase 4 | Pending |
| CONF-02 | Phase 4 | Pending |
| CONF-03 | Phase 4 | Pending |
| CONF-04 | Phase 4 | Pending |
| CONF-05 | Phase 4 | Pending |
| DEPL-01 | Phase 5 | Pending |
| DEPL-02 | Phase 5 | Pending |
| DEPL-03 | Phase 5 | Pending |
| DEPL-04 | Phase 5 | Pending |
| DEPL-05 | Phase 5 | Pending |
| DEPL-06 | Phase 5 | Pending |
| DEPL-07 | Phase 5 | Pending |
| DEPL-08 | Phase 5 | Pending |
| DEPL-09 | Phase 5 | Pending |
| DEPL-10 | Phase 5 | Pending |
| DEPL-11 | Phase 5 | Pending |
| EVOL-01 | Phase 5 | Pending |
| EVOL-02 | Phase 5 | Pending |
| EVOL-03 | Phase 5 | Pending |
| EVOL-04 | Phase 5 | Pending |
| EVOL-05 | Phase 5 | Pending |
| REPO-01 | Phase 6 | Pending |
| REPO-02 | Phase 6 | Pending |
| REPO-03 | Phase 6 | Pending |
| REPO-04 | Phase 6 | Pending |
| REPO-05 | Phase 6 | Pending |
| REPO-06 | Phase 6 | Pending |
| REPO-07 | Phase 6 | Pending |
| REPO-08 | Phase 6 | Pending |
| REPO-09 | Phase 7 | Pending |
| TEST-01 | Phase 7 | Pending |
| TEST-02 | Phase 7 | Pending |
| TEST-03 | Phase 7 | Pending |

**Coverage:**
- v1 requirements: 68 total
- Mapped to phases: 68
- Unmapped: 0

---
*Requirements defined: 2026-04-13*
*Last updated: 2026-04-13 after roadmap revision (Security promoted to Phase 2)*
