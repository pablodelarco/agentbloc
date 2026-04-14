# Phase 2: Security Cross-Cutting References - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 02-security-cross-cutting-references
**Areas discussed:** Depth and audience, Compliance triggers, Kill switch + ops

---

## Depth and Audience

### File depth

| Option | Description | Selected |
|--------|-------------|----------|
| Pragmatic patterns | 2-3 pages per file. Decision tree + concrete examples + artifact guidance. Focused on what Claude should DO. | ✓ |
| Full playbooks | 5-8 pages per file. Enterprise-grade with threat models, compliance matrices. | |
| Tiered by tech level | Non-technical summary + technical details. Claude loads right depth. | |

**User's choice:** Pragmatic patterns
**Notes:** None

### Tone

| Option | Description | Selected |
|--------|-------------|----------|
| Matter-of-fact | State requirement, explain why, move on. | ✓ |
| Cautionary | Emphasize risks, warnings. | |
| Consultative | Frame as professional advice with tradeoffs. | |

**User's choice:** Matter-of-fact
**Notes:** None

---

## Compliance Triggers

### Activation model

| Option | Description | Selected |
|--------|-------------|----------|
| Auto from data class | Auto-flag PII/HIPAA/PCI from interview data mentions. | |
| Explicit question | Ask user "Do you need GDPR compliance?" | |
| Region-based default | GDPR ON for EU, HIPAA/PCI when flagged. | |

**User's choice:** Hybrid (custom): Auto-detection as primary engine + GDPR always-on for EU as baseline + override as escape hatch only (can deactivate but never activate). Never ask non-technical users legal questions. The skill makes security decisions FOR the user.
**Notes:** User provided detailed rationale: "Preguntar '¿necesitas GDPR?' a un no-tecnico es delegarle una decision legal que el no puede tomar. Viola el principio de 'el skill hace el trabajo, no el usuario'."

### GDPR scope

| Option | Description | Selected |
|--------|-------------|----------|
| Core 4 patterns | Right to be forgotten, DSAR, breach notification, consent logging. | |
| Core 4 + DPO | Above plus DPO designation guidance and DPA template. | ✓ |
| Full GDPR toolkit | Above plus DPIA, cross-border transfer, cookie consent. | |

**User's choice:** Core 4 + DPO
**Notes:** DPO and DPA needed for B2B consulting pipeline.

---

## Kill Switch + Ops

### Kill switch mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| File-based + Telegram | Dual-path: .agentbloc/KILL_SWITCH file + Telegram /stop command. | ✓ |
| File-based only | Just the file check at agent start. | |
| Governance flag | Kill state in governance.yaml. | |

**User's choice:** File-based + Telegram
**Notes:** None

### Rate limiting

| Option | Description | Selected |
|--------|-------------|----------|
| Per-agent in YAML | Each agent.yaml has rate_limit config. | |
| Global in governance | governance.yaml has team-wide budget. | |
| Both | Global default + per-agent override. | ✓ |

**User's choice:** Both (layered)
**Notes:** None

### Audit format

| Option | Description | Selected |
|--------|-------------|----------|
| JSON append-only | JSONL, one object per line. Machine-parseable. | ✓ |
| Structured markdown | Human-readable markdown log. | |
| Claude's discretion | Let Claude decide per context. | |

**User's choice:** JSON append-only (JSONL)
**Notes:** None

## Claude's Discretion

- Credential hierarchy decision tree branching
- PII detection keywords/patterns
- Audit log retention default
- Incident response runbook structure

## Deferred Ideas

- Tenant isolation enforcement -- documented as pattern, enforcement is v2 scope
