# Phase 5: Deployment Artifacts and Evolution - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Populate `references/phase-5-deployment.md`, `references/phase-6-evolution.md`, `references/scheduling.md`, and `references/telegram-patterns.md` with the complete protocols Claude follows during the Deployment (conversational Phase 5) and Evolution (conversational Phase 6) phases. The deployment protocol must define all artifact templates (.agentbloc/ directory structure, team.yaml, agent.yaml, skill.md, governance.yaml, telegram.yaml, state schemas, job definitions, SUMMARY.md deployment guide). The evolution protocol must define the self-improvement loop (weekly scans, feature/vulnerability detection, patch proposals, human approval gate). Supporting references cover scheduling patterns and Telegram reporting conventions.

</domain>

<decisions>
## Implementation Decisions

### Artifact Directory Structure
- **D-01:** The .agentbloc/ directory uses a flat-with-subdirectories layout: `team.yaml` and `governance.yaml` at root, `agents/` for per-agent YAML and skill files, `state/` for JSON state files, `jobs/` for cron job definitions, `SUMMARY.md` as deployment guide, and `incident-response.md` as runbook. No deeper nesting.
- **D-02:** Per-agent files follow a naming convention: `agents/{agent-slug}.yaml` for the contract/config and `agents/{agent-slug}.skill.md` for the Claude Code prompt file. The slug is derived from the agent name (lowercase, hyphens).
- **D-03:** State files are JSON (not YAML) per CLAUDE.md: machine-written state uses JSON for programmatic reliability. Format: `state/{agent-slug}.json` with processed IDs, mappings, and checkpoint data.

### Template Completeness
- **D-04:** All artifact templates are grounded in the Arco Rooms reference implementation with real field values (agent names, cron times, integration references). Templates show a complete, runnable example that users can adapt. Not abstract placeholders.
- **D-05:** Each template includes inline comments explaining every field, so a non-technical user (Level: non-technical) can understand what each setting does without reading external documentation.

### Scheduling Patterns
- **D-06:** Cron uses standard 5-field format (minute hour day-of-month month day-of-week). All times in the user's local timezone, explicitly noted in team.yaml.
- **D-07:** DST-safe scheduling: recommend scheduling agents at times that are unambiguous during DST transitions (avoid 01:00-03:00 local time). Document the risk and the recommendation.
- **D-08:** No holiday support in v1.0. Agents run on their schedule regardless of holidays. Document as a limitation with a note that holiday awareness could be added in evolution phase.
- **D-09:** System cron + `claude -p` is the production deployment method. Claude Code Scheduled Tasks (Desktop) are fine for development/demo but expire after 7 days and require the Desktop app open.

### Telegram Reporting
- **D-10:** Thread-per-domain convention: each logical domain (e.g., "Invoices", "Payments", "Errors") gets its own Telegram thread within the team's chat. Keeps notifications organized by topic.
- **D-11:** Three notification tiers with distinct formatting: `info` (plain text, routine updates), `action_required` (bold header, requires user response), `error` (red alert emoji, immediate attention needed). Silence-by-default: no "everything is fine" messages.
- **D-12:** Approval-by-reply for Level 3-4 agents: when an agent needs human approval (blast-radius Level 3+), it sends an approval request via Telegram with a preview of the action. User replies to approve or reject. Timeout configurable in governance.yaml.
- **D-13:** Voice message support documented as a Telegram-native feature: users can reply with voice messages for approvals or feedback. Claude processes the transcription.

### Evolution Protocol
- **D-14:** Weekly evolution scan (configurable in governance.yaml). Scans check: GitHub repos for MCP server updates (new versions, deprecations), npm registry for package updates, CVE databases for known vulnerabilities in used dependencies.
- **D-15:** Feature detection: when a new MCP server or API appears that could improve an existing agent's integration, the evolution loop generates a "feature proposal" with what changed, what it enables, and the recommended action.
- **D-16:** Vulnerability detection: when a CVE is filed against a used MCP server or dependency, the evolution loop generates a "security alert" with severity, affected agents, and recommended mitigation.
- **D-17:** Patch proposal format: structured markdown with title, affected agents, current state, proposed change, rationale, risk assessment, and rollback plan. User must approve before any change is applied. No auto-patches.
- **D-18:** Human approval gate is non-negotiable for all evolution actions. The gate works through Telegram: proposal sent, user reviews, user approves or rejects with optional feedback.

### Deployment Guide (SUMMARY.md)
- **D-19:** SUMMARY.md serves as the complete deployment guide with sections: Prerequisites, Installation Steps, Configuration Checklist, First Run Verification, Monitoring Instructions, Modification Guide, Troubleshooting.
- **D-20:** The deployment guide is written for the user's technical level (detected during interview). Non-technical users get step-by-step with screenshots/descriptions. Developers get command-line instructions with config references.

### Claude's Discretion
- Exact YAML field ordering within templates (as long as all required fields are present)
- Telegram message formatting details (emoji choice, markdown formatting within messages)
- Evolution scan implementation details (as long as weekly frequency and human approval gate are maintained)
- Incident response runbook structure (as long as it covers escalation, rollback, and common failures per DEPL-10)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Stub Files (to populate)
- `references/phase-5-deployment.md` : Deployment artifact generation protocol stub to fill
- `references/phase-6-evolution.md` : Post-deployment evolution protocol stub to fill
- `references/scheduling.md` : Scheduling patterns stub to fill
- `references/telegram-patterns.md` : Telegram reporting patterns stub to fill

### Security References (populated in Phase 2, consumed during deployment artifact generation)
- `references/credentials.md` : Credential hierarchy referenced in governance.yaml template
- `references/blast-radius.md` : Scoring levels referenced in agent.yaml templates and approval gates
- `references/audit-logging.md` : Log format and rate limiting referenced in governance.yaml template
- `references/gdpr-patterns.md` : Compliance patterns referenced when generating governance.yaml for PII-handling teams
- `references/incident-response.md` : Kill switch and severity classification referenced in incident-response.md artifact template
- `references/prompt-injection.md` : Defense layers referenced in agent skill.md templates

### Design and Integration Protocols (populated in Phases 3-4, provide input data model)
- `references/phase-2-design.md` : Agent contract card template (input to per-agent YAML generation), topology diagram, governance specs
- `references/phase-3-integration.md` : Integration decision matrix (input to per-agent integration config), trust scores
- `references/phase-4-confirmation.md` : Confirmed agent cards with integration findings (direct input to artifact generation)

### Existing Skill Hub
- `SKILL.md` : Phase summaries and loading instructions
- `examples/arco-rooms.md` : Reference implementation demonstrating all 11 patterns

### Requirements
- `.planning/REQUIREMENTS.md` : DEPL-01..11 and EVOL-01..05 acceptance criteria
- `.planning/ROADMAP.md` : Phase 5 success criteria (4 items)

### Prior Phase Context
- `.planning/phases/01-skill-foundation/01-CONTEXT.md` : D-10 (flat references/)
- `.planning/phases/02-security-cross-cutting-references/02-CONTEXT.md` : D-07 (dual-path kill switch), D-08 (layered rate limiting), D-09 (JSONL audit logs)
- `.planning/phases/03-interview-and-design-phases/03-CONTEXT.md` : D-05 (table + cards format), D-06 (ASCII + Mermaid diagrams)
- `.planning/phases/04-integration-and-confirmation-phases/04-CONTEXT.md` : D-07 (enhanced contract card), D-10 (dry run protocol), D-11 (dual-layer enforcement)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `references/phase-5-deployment.md` (12 lines) : Stub with purpose statement
- `references/phase-6-evolution.md` (12 lines) : Stub with purpose statement
- `references/scheduling.md` (12 lines) : Stub with purpose statement
- `references/telegram-patterns.md` (12 lines) : Stub with purpose statement
- `references/audit-logging.md` (190 lines) : Contains governance.yaml audit block template, rate limiting patterns (consumed by deployment protocol)
- `references/blast-radius.md` (129 lines) : Contains agent.yaml blast_radius config block template (consumed by deployment protocol)
- `references/incident-response.md` (213 lines) : Contains kill switch pattern and severity classification (consumed by deployment protocol)

### Established Patterns
- Security reference files: Table of Contents, "When This Applies", decision trees/tables, artifact templates, Quick Reference
- All reference files are flat in references/ directory (D-10 from Phase 1)
- SKILL.md hybrid loading at phase entry with explicit reference paths

### Integration Points
- SKILL.md lines 120-121: "You MUST read the complete deployment protocol before generating any artifacts" with reference to phase-5-deployment.md
- SKILL.md lines 128-129: "You MUST read the complete evolution protocol before starting this phase" with reference to phase-6-evolution.md
- The deployment protocol receives confirmed, integration-enhanced agent cards from Phase 4 as input
- Generated artifacts must be immediately runnable on Claude Code + cron + MCP + Telegram

</code_context>

<specifics>
## Specific Ideas

- The deployment protocol is the most artifact-heavy reference file in the project. It should contain complete YAML templates with every field, not abbreviated examples. The templates are the product: Claude generates these artifacts during an AgentBloc session.
- Arco Rooms example should ground every template. The team.yaml example should show a 3-agent pipeline (Invoice Collector, Payment Matcher, Report Sender). The agent.yaml examples should show different blast-radius levels.
- The evolution protocol is the lightest reference file. It defines a simple scan-detect-propose-approve loop. The complexity is in the human approval gate, not the scanning logic.
- scheduling.md and telegram-patterns.md are supporting references, not conversational phase protocols. They should be concise (80-120 lines each) and focused on patterns that deployment and design protocols cross-reference.

</specifics>

<deferred>
## Deferred Ideas

- Holiday-aware scheduling: v2.0 feature, not v1.0
- Multi-language Telegram notifications (auto-translating messages based on user language): could be added in evolution phase
- Dashboard/web UI for monitoring agent teams: explicitly out of scope per CLAUDE.md ("The Claude Code conversation IS the UI")

</deferred>

---

*Phase: 05-deployment-artifacts-and-evolution*
*Context gathered: 2026-04-14*
