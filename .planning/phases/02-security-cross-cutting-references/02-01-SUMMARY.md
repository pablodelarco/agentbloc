---
phase: 02-security-cross-cutting-references
plan: 01
subsystem: security-references
tags: [security, credentials, data-classification, blast-radius, gdpr, compliance]
dependency_graph:
  requires: []
  provides: [credential-decision-tree, data-classification-categories, blast-radius-scoring, compliance-activation-matrix]
  affects: [references/credentials.md, references/data-classification.md, references/blast-radius.md]
tech_stack:
  added: []
  patterns: [decision-tree, auto-detection-keywords, rotation-policy, approval-matrix, permission-minimization]
key_files:
  created: []
  modified:
    - references/credentials.md
    - references/data-classification.md
    - references/blast-radius.md
decisions:
  - Credential decision tree uses 3-step branching (OAuth > scoped API key > admin token) with blast-radius escalation for admin-only services
  - Data classification auto-detection uses bilingual EN/ES keyword tables with low-threshold activation (false positives preferred over missed classifications)
  - Blast-radius scoring targets 60-80% of agents at Level 1-2 with permission minimization checklist to push levels down
metrics:
  duration: 5 minutes
  completed: 2026-04-14
  tasks_completed: 3
  tasks_total: 3
  files_modified: 3
---

# Phase 02 Plan 01: Security Classification References Summary

Populated three foundational security reference files (credentials.md, data-classification.md, blast-radius.md) with actionable decision trees, bilingual auto-detection rules, and artifact generation templates that all subsequent conversational phases depend on.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Populate credentials.md with decision tree, rotation policy, redaction rules | 3b6373d | references/credentials.md |
| 2 | Populate data-classification.md with categories, auto-detection, retention, deletion | 7005112 | references/data-classification.md |
| 3 | Populate blast-radius.md with scoring levels, approval matrix, permission minimization | 40d6ef8 | references/blast-radius.md |

## Key Deliverables

**credentials.md (117 lines):**
- 3-step credential decision tree: OAuth > scoped API key > admin token
- Rotation policy table cross-referenced by credential type and data classification
- Log redaction rules with [REDACTED:*] and hash:* patterns
- Secret storage via .env with AGENTBLOC_{SERVICE}_{CREDENTIAL_TYPE} naming
- Quick reference table mapping credential types to blast-radius impact

**data-classification.md (138 lines):**
- 4-category classification (PII, PHI, Financial, Public) with regime triggers
- Bilingual EN/ES auto-detection keyword tables (high/medium confidence PII, PHI, financial signals)
- Hybrid activation logic per D-04: auto-detect primary, EU region baseline, override escape hatch only
- Retention schedule with GDPR, HIPAA, PCI regime overrides
- Art. 17 deletion workflow (5-step DSAR process with 30-day deadline)
- Regime conflict resolution: most restrictive wins, soft delete for erasure vs. retention conflicts
- Compliance activation matrix summary

**blast-radius.md (129 lines):**
- 4-level scoring table (read-only, write-scoped, write-unrestricted, send-external)
- Scoring decision tree for agent classification during Design phase
- Approval matrix: levels 3-4 require requires_approval: true with Telegram confirmation
- Permission minimization checklist (5 questions to push agent levels down)
- agent.yaml blast_radius template with Level 2 and Level 4 examples
- Design target: 60-80% of agents at Level 1-2

## Decisions Made

1. **Credential rotation frequency scaled by data class:** PHI/Financial data triggers the most aggressive rotation schedules (7-14 days for admin tokens vs. 30-90 days for public data).
2. **Bilingual keyword detection with low threshold:** Auto-detection uses EN/ES keyword pairs at two confidence tiers. A false positive activates compliance patterns unnecessarily (minor overhead) while a false negative misses a regulatory obligation (major risk).
3. **Permission minimization as design-time checklist:** Rather than post-hoc security review, blast-radius scoring includes 5 explicit downgrade questions Claude asks during agent design to minimize privilege before deployment.

## Deviations from Plan

None. Plan executed exactly as written.

## Threat Mitigations Applied

| Threat ID | Mitigation | Implemented In |
|-----------|-----------|----------------|
| T-02-01 | Log redaction rules specify ALWAYS redact API keys/tokens; hash pattern for PII references | references/credentials.md (Log Redaction Rules section) |
| T-02-02 | Levels 3-4 force requires_approval: true; permission minimization checklist reduces default scope | references/blast-radius.md (Approval Matrix + Permission Minimization sections) |
| T-02-03 | False positives preferred over missed classifications; override can only deactivate, never activate | references/data-classification.md (Activation Logic section) |

## Self-Check: PASSED

All 3 files verified on disk. All 3 commit hashes confirmed in git log.
