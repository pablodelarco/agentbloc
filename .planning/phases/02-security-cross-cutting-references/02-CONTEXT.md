# Phase 2: Security Cross-Cutting References - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Populate the 8 existing security reference stub files (created in Phase 1) with actionable patterns that all subsequent conversational phases can reference. Plus ensure the 9th requirement (SECR-09 prompt injection) is fully covered. These files become the security backbone: Interview uses data-classification.md, Design uses blast-radius.md, Integration uses credentials.md, Deployment uses all of them. Content must be pragmatic patterns (2-3 pages per file), not enterprise playbooks.

</domain>

<decisions>
## Implementation Decisions

### Depth and Audience
- **D-01:** Each security reference file is 2-3 pages of pragmatic patterns. Content is focused on "what Claude should DO during the AgentBloc flow" not "everything about security." Decision trees, concrete examples, and artifact generation guidance.
- **D-02:** No tiered content by tech level within security files. The SKILL.md tech-level system handles presentation adaptation. Security reference content is written at a single technical depth (implementer-level) and Claude simplifies for non-technical users via behavior-by-level rules.
- **D-03:** Tone is matter-of-fact when presenting security findings to users. "Your workflow handles PII. Here's what that means for the design." Not cautionary, not alarmist.

### Compliance Activation
- **D-04:** Hybrid activation model for compliance regimes:
  - **Auto-detection (primary engine):** During interview, if data mentions emails/names/addresses -> PII flag -> GDPR. Health/patient data -> HIPAA. Payment cards/IBAN -> PCI. Low threshold: better false positive than missed.
  - **Region-based default (baseline):** If client operates in EU (detected from interview language, business region, or asked at start), GDPR is non-negotiable floor. European SMBs don't need to be "proposed" GDPR -- it applies by law.
  - **Override (escape hatch only):** User can deactivate a detection ("this looks like PII but it's synthetic test data"). Override can only DEACTIVATE, never activate. If there's a signal, Claude activates automatically.
  - **Never ask "do you need GDPR?" to a non-technical user.** That delegates a legal decision they cannot make. The skill does the work, not the user.
- **D-05:** GDPR scope is Core 4 + DPO: right to be forgotten (Art. 17), DSAR workflow (Art. 15), 72h breach notification (Art. 33), consent logging (Art. 6), plus Data Protection Officer designation guidance and Data Processing Agreement template for B2B consulting.
- **D-06:** HIPAA and PCI patterns are documented but only activated when data classification warrants. They are "ready" patterns, not default-on.

### Kill Switch and Operations
- **D-07:** Kill switch is dual-path: file-based (.agentbloc/KILL_SWITCH checked at agent start) + Telegram /stop command. File-based is zero-dependency, Telegram is remote-friendly. Both paths halt execution immediately.
- **D-08:** Rate limiting is layered: global default in governance.yaml, per-agent override in agent.yaml. Example: governance sets `max_cost_usd: 50/day`, individual agent can have `rate_limit: { max_calls: 100, period: '1h' }`.
- **D-09:** Audit logs are JSON append-only (JSONL). Fields: timestamp, correlation_id, agent, action, result, pii_redacted. Machine-parseable, one object per line. Retention configurable in governance.yaml.

### Claude's Discretion
- Exact decision tree branching for credential hierarchy (as long as OAuth > scoped API key > admin token preference order is maintained)
- Specific PII detection keywords/patterns for auto-classification
- Audit log retention default period (suggest 90 days)
- Incident response runbook template structure

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Stub Files (to populate)
- `references/credentials.md` -- SECR-01: Credential management decision tree
- `references/data-classification.md` -- SECR-02: Data classification categories and retention
- `references/blast-radius.md` -- SECR-03: Per-agent blast-radius scoring
- `references/audit-logging.md` -- SECR-04: Audit logging with correlation IDs
- `references/gdpr-patterns.md` -- SECR-07: GDPR compliance patterns (Core 4 + DPO)
- `references/prompt-injection.md` -- SECR-09: Prompt injection defense
- `references/incident-response.md` -- SECR-10: Incident response runbook template
- `references/tenant-isolation.md` -- Tenant isolation patterns (documented but v2 scope)

### Kill switch and rate limiting (no existing stub -- goes into governance patterns)
- Kill switch pattern documented in deployment reference or as section in relevant security files
- Rate limiting documented as governance.yaml pattern

### Research and Audit
- `.planning/research/STACK.md` -- Security tooling patterns section
- `enterprise-readiness.md` -- Gap analysis items 1.1-1.7, 2.1-2.5, and Section 6 (Security Deep Dive)
- `.planning/REQUIREMENTS.md` -- SECR-01 through SECR-09 acceptance criteria

### Prior Phase Context
- `.planning/phases/01-skill-foundation/01-CONTEXT.md` -- D-10 (flat references/), D-11 (security files at root)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- 8 security stub files already exist in references/ (created by Phase 1, Plan 01-02)
- Each stub has: title, purpose statement, placeholder for content, and "Content will be added in Phase 2" marker
- SKILL.md already references data-classification.md from Phase 1 interview section (line 95)

### Established Patterns
- Flat references/ directory (D-10 from Phase 1) -- all files at root level
- Hybrid loading pattern (D-09 from Phase 1) -- natural instruction + markdown link
- SKILL.md references security files conditionally ("If the user's data involves PII, also read...")

### Integration Points
- Phase 3 (Interview) will reference data-classification.md during interview category "Data"
- Phase 3 (Design) will reference blast-radius.md during agent design
- Phase 4 (Integration) will reference credentials.md during integration analysis
- Phase 5 (Deployment) will reference all security files when generating governance.yaml

</code_context>

<specifics>
## Specific Ideas

- The compliance activation model (D-04) is the most architecturally significant decision. It establishes that AgentBloc makes security decisions FOR the user, not delegates them TO the user. This is a core differentiator.
- GDPR scope includes DPO guidance and DPA template because the consulting pipeline targets B2B clients who will need these for their own compliance.
- Kill switch is dual-path (file + Telegram) because the primary audience runs agents on VPS/cloud where SSH access may not be immediate but Telegram is always available on mobile.
- Audit logs are JSONL because state files are already JSON (per PROJECT.md constraint) and JSONL is the simplest machine-parseable append-only format.

</specifics>

<deferred>
## Deferred Ideas

- Tenant isolation enforcement (namespace separation, credential isolation) -- documented in references/tenant-isolation.md as a pattern but enforcement is v2 scope per REQUIREMENTS.md Out of Scope table.

</deferred>

---

*Phase: 02-security-cross-cutting-references*
*Context gathered: 2026-04-14*
