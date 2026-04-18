# Phase 4: Integration and Confirmation Phases - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Populate `references/phase-3-integration.md` and `references/phase-4-confirmation.md` with the complete conversational protocols Claude follows during the Integration Analysis (conversational Phase 3) and Step-by-Step Confirmation + Dry Run (conversational Phase 4) phases. The integration protocol must cover multi-method search, evidence verification, trust scoring, and an integration decision matrix per service. The confirmation protocol must cover per-agent step-by-step approval and a mandatory dry run with tool stubbing. Both files must integrate with the security reference files from Phase 2 and the design output from Phase 3.

</domain>

<decisions>
## Implementation Decisions

### Integration Search Strategy
- **D-01:** Multi-method integration search follows a strict priority order per action: official API (best) > MCP server (native) > Playwright browser automation (scraping) > email scraping (Gmail MCP) > webhook interception (event-driven) > manual notification (last resort). Claude searches each method in order and stops presenting alternatives after finding 3 viable options.
- **D-02:** Integration decision matrix per service: one table per service showing recommended method, alternative method, and fallback method. Each row includes: method name, pros, cons, setup complexity (low/medium/high), and trust score. The user sees a clear recommendation with "why" for each service.
- **D-03:** Integration search uses live web search (WebSearch, WebFetch) to verify current availability. No integration is presented without evidence. Claude searches for npm packages, GitHub repos, MCP server directories (PulseMCP), and official API documentation.

### Evidence and Trust Scoring
- **D-04:** Every integration claim includes: URL (source), package version (if applicable), last-commit date (for GitHub repos), and publisher info. If any of these is missing, the integration is marked [UNVERIFIED] and the user is warned. An [UNVERIFIED] integration can still be recommended if no better option exists, but the user must acknowledge the risk.
- **D-05:** Trust score per dependency uses a 3-tier system (HIGH/MEDIUM/LOW) based on:
  - **HIGH:** Official vendor-maintained (Anthropic, Microsoft, Google, Slack, etc.), or >500 GitHub stars with active maintenance (commit within 90 days)
  - **MEDIUM:** Community-maintained, 100-500 stars, commit within 180 days, clear documentation
  - **LOW:** <100 stars, >180 days since last commit, unclear maintainer, or no documentation
  - Low-trust dependencies are flagged with a warning and alternative options are highlighted
- **D-06:** Trust scoring references the MCP Server Discovery Protocol from CLAUDE.md for consistency. The 3-tier system aligns with the existing HIGH/MEDIUM/LOW confidence ratings used throughout the project.

### Confirmation Flow
- **D-07:** Per-agent confirmation reuses the contract card format from the design phase (Phase 3, D-05) but enhances it with integration findings: each agent card now includes a "Selected Integrations" section showing the chosen method per service, the trust score, and the credential requirement (from references/credentials.md).
- **D-08:** Step-by-step confirmation is strictly sequential: one agent at a time, user confirms or requests changes, then next agent. No batch confirmation. User can adjust integrations, blast-radius level, or failure handling at this point. Changes are reflected in the updated contract card.
- **D-09:** After all agents are individually confirmed, a final integration summary table shows the complete team with all integrations, trust scores, and credential requirements. This is the Phase 4 gate artifact.

### Dry Run Protocol
- **D-10:** Mandatory dry run executes all agents against N real records (user-specified count, default 5). All side-effect tools (Write to external systems, MCP sends, Telegram messages, API POST/PUT/DELETE) are stubbed: they return simulated success responses without executing. Read operations execute normally against real data.
- **D-11:** Dry run tool stubbing is achieved through explicit instruction in the agent skill files: "DRY RUN MODE: For all write/send operations, log what WOULD be done but do not execute. Return a simulated success response." This is a prompt-level mechanism, not a code-level stub. Research should investigate whether Claude Code hooks (PreToolUse) can block specific tool calls as an enforcement layer.
- **D-12:** Dry run report format: a structured markdown document showing per-agent results: what was read (real data), what would have been written/sent (simulated), any errors encountered, and a pass/fail verdict per agent. The report ends with a summary table and a confirmation gate: "Review the dry run results. Approve to proceed to deployment, or request changes."

### Security Integration Points
- **D-13:** During integration analysis, credential requirements per service are evaluated using the decision tree from references/credentials.md. Each integration gets a credential entry in the agent contract card.
- **D-14:** Prompt injection risk is assessed per integration during analysis: agents that ingest external content (emails, web scraping, API responses) are flagged and assigned defense layers from references/prompt-injection.md. This was already started in Design (Step 3 contract card) but is refined during integration analysis with specific layer assignments.

### Claude's Discretion
- Exact format of the integration decision matrix table (as long as it includes method, pros, cons, setup complexity, and trust score per row)
- How to present low-trust integrations (warning banner, inline note, or separate section)
- Dry run record count default (suggested 5, but Claude can adjust based on the complexity of the workflow)
- Whether the dry run report includes sample data previews or just summaries

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Stub Files (to populate)
- `references/phase-3-integration.md` : Integration analysis protocol stub with purpose statement to fill
- `references/phase-4-confirmation.md` : Confirmation and dry run protocol stub to fill

### Security References (populated in Phase 2, consumed during integration and confirmation)
- `references/credentials.md` : Credential decision tree (OAuth > scoped API key > admin token), referenced during integration analysis per D-13
- `references/blast-radius.md` : 4-level scoring, approval matrix (consumed during confirmation to show updated blast-radius per agent)
- `references/prompt-injection.md` : 4-layer defense pipeline (consumed during integration analysis for agents ingesting external content per D-14)
- `references/audit-logging.md` : Audit logging patterns (referenced in governance during confirmation)
- `references/gdpr-patterns.md` : Compliance patterns activated by data classification (referenced during integration for PII-handling services)
- `references/incident-response.md` : Kill switch pattern (referenced during confirmation for governance review)

### Design Protocol (populated in Phase 3, consumed during integration and confirmation)
- `references/phase-2-design.md` : Agent contract card template reused in confirmation (D-07), topology diagram, governance specs
- `references/frameworks.md` : Framework patterns (lightweight reference during integration for agent topology context)

### Existing Skill Hub
- `SKILL.md` : Phase summaries and loading instructions for these reference files
- `examples/arco-rooms.md` : Reference implementation demonstrating integration patterns (multi-provider, multi-bank, fallback chains)

### Requirements
- `.planning/REQUIREMENTS.md` : INTG-01..05 and CONF-01..05 acceptance criteria
- `.planning/ROADMAP.md` : Phase 4 success criteria (5 items)

### Prior Phase Context
- `.planning/phases/01-skill-foundation/01-CONTEXT.md` : D-09 (hybrid loading), D-10 (flat references/)
- `.planning/phases/02-security-cross-cutting-references/02-CONTEXT.md` : D-04 (compliance activation model), D-05 (GDPR scope)
- `.planning/phases/03-interview-and-design-phases/03-CONTEXT.md` : D-05 (both table + cards format), D-08 (progressive classification), D-09 (blast-radius auto-scored with override)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `references/phase-3-integration.md` (12 lines) : Stub with purpose statement. Needs full structure added.
- `references/phase-4-confirmation.md` (12 lines) : Stub with purpose statement. Needs full structure added.
- `references/credentials.md` (118 lines) : Complete credential decision tree. Integration protocol must cross-reference this when evaluating each service's credential requirements.
- `references/prompt-injection.md` (179 lines) : Complete 4-layer defense pipeline. Integration protocol must cross-reference this when agents ingest external content.
- `references/phase-2-design.md` (313 lines) : Complete design protocol with contract card template. Confirmation protocol reuses this card format enhanced with integration findings.

### Established Patterns
- Security reference files follow a consistent structure: Table of Contents, "When This Applies" section, decision trees/tables, artifact templates, Quick Reference. Integration and confirmation protocols should follow this pattern.
- SKILL.md hybrid loading: "You MUST read the complete [protocol] before starting this phase" with explicit reference path. Both files are loaded at their respective phase entries.
- The design protocol produces an agent summary table and per-agent contract cards. The confirmation protocol should consume these as input and enhance them with integration data.

### Integration Points
- SKILL.md line 106: "You MUST read the complete integration analysis protocol before starting this phase" : phase-3-integration.md loaded at Phase 3 entry
- SKILL.md line 115: "You MUST read the complete confirmation and dry run protocol before starting this phase" : phase-4-confirmation.md loaded at Phase 4 entry
- The integration protocol receives the confirmed design (summary table + contract cards) as input from Phase 2
- The confirmation protocol receives the integration-enhanced contract cards as input from Phase 3

</code_context>

<specifics>
## Specific Ideas

- The integration decision matrix (D-02) should ground every recommendation in real evidence from web search. This differentiates AgentBloc from generic "just use an API" advice. The protocol should explicitly instruct Claude to search PulseMCP, npm, GitHub, and official docs before recommending.
- Arco Rooms example demonstrates the full fallback chain pattern (API > Gmail > Playwright > manual). The integration protocol should reference this as a concrete example of what a multi-method search looks like in practice.
- The dry run mechanism (D-11) is a known research area: whether Claude Code hooks (PreToolUse) can enforce tool stubbing deterministically or whether prompt-level instruction is sufficient. This was flagged as a Phase 4 research topic in STATE.md blockers. The researcher should investigate both approaches.
- The confirmation flow (D-08) being strictly sequential (one agent at a time) ensures the user understands each agent's complete picture before approving. This matches the "cost of a bad design is 10x the cost of one more question" philosophy from SKILL.md hard gates.

</specifics>

<deferred>
## Deferred Ideas

- Automated MCP server health checking (pinging endpoints to verify availability) during integration analysis: belongs in a future "integration monitoring" capability
- Integration version pinning (locking to specific MCP server versions for reproducibility): belongs in deployment phase, not analysis

</deferred>

---

*Phase: 04-integration-and-confirmation-phases*
*Context gathered: 2026-04-14*
