---
phase: 3
slug: interview-and-design-phases
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-14
---

# Phase 3 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | grep + file existence checks (markdown content validation) |
| **Config file** | none |
| **Quick run command** | `grep -c "## " references/phase-1-interview.md references/phase-2-design.md` |
| **Full suite command** | `grep -l "Content will be added\|Placeholder\|<!-- Content:" references/*.md` (should return empty for populated files) |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run quick command to verify section headers exist
- **After every plan wave:** Run full suite to confirm no stub markers remain
- **Before `/gsd-verify-work`:** All 12 requirement IDs grep-verified
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 03-01-01 | 01 | 1 | INTV-01 | grep | `grep -c "## The Problem\|## The Current Workflow\|## The Services" references/phase-1-interview.md` | pending |
| 03-01-02 | 01 | 1 | INTV-02 | grep | `grep "one question" references/phase-1-interview.md` | pending |
| 03-01-03 | 01 | 1 | INTV-03 | grep | `grep "checklist\|must-know" references/phase-1-interview.md` | pending |
| 03-01-04 | 01 | 1 | INTV-04 | grep | `grep "summary\|Summary of Understanding" references/phase-1-interview.md` | pending |
| 03-02-01 | 02 | 1 | DESG-01 | grep | `grep "agent identification\|one agent per" references/phase-2-design.md` | pending |
| 03-02-02 | 02 | 1 | DESG-02 | grep | `grep "pipeline\|mesh\|hierarchy\|swarm" references/phase-2-design.md` | pending |
| 03-02-03 | 02 | 1 | DESG-03 | grep | `grep "contract\|inputs.*outputs" references/phase-2-design.md` | pending |
| 03-02-04 | 02 | 1 | DESG-04 | grep | `grep "schedule\|trigger\|cron" references/phase-2-design.md` | pending |
| 03-02-05 | 02 | 1 | DESG-05 | grep | `grep "governance\|budget\|permission" references/phase-2-design.md` | pending |
| 03-02-06 | 02 | 1 | DESG-06 | grep | `grep "blast-radius\|requires_approval" references/phase-2-design.md` | pending |
| 03-02-07 | 02 | 1 | DESG-07 | grep | `grep "CrewAI\|LangGraph\|n8n" references/phase-2-design.md` | pending |
| 03-02-08 | 02 | 1 | DESG-08 | grep | `grep "diagram\|ASCII\|Mermaid\|summary table" references/phase-2-design.md` | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework installation needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Interview flow quality | INTV-01 | Conversational quality requires reading | Read phase-1-interview.md and verify 9 categories have seed questions |
| Design output readability | DESG-08 | Visual format quality requires reading | Read phase-2-design.md and verify ASCII diagram template exists |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands
- [x] Sampling continuity maintained
- [x] No Wave 0 dependencies needed
- [x] Feedback latency < 1s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
