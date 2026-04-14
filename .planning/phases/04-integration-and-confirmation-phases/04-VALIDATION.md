---
phase: 04
slug: integration-and-confirmation-phases
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-14
---

# Phase 04 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell commands (grep, wc, test) for markdown content verification |
| **Config file** | none (shell commands only) |
| **Quick run command** | `wc -l references/phase-3-integration.md references/phase-4-confirmation.md` |
| **Full suite command** | `bash -c 'echo "=== Integration ===" && wc -l references/phase-3-integration.md && echo "=== Confirmation ===" && wc -l references/phase-4-confirmation.md'` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run quick line count check
- **After every plan wave:** Run full structural verification (grep for required sections)
- **Before `/gsd-verify-work`:** All structural checks must pass
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | INTG-01 | T-04-01 | Multi-method search protocol with priority order | structural | `grep -c "API.*MCP.*Playwright" references/phase-3-integration.md` | N/A content | pending |
| 04-01-02 | 01 | 1 | INTG-02 | - | Decision matrix template with pros/cons/trust | structural | `grep -c "Decision Matrix" references/phase-3-integration.md` | N/A content | pending |
| 04-01-03 | 01 | 1 | INTG-03 | T-04-02 | Evidence protocol with URL/version/commit | structural | `grep -c "UNVERIFIED" references/phase-3-integration.md` | N/A content | pending |
| 04-01-04 | 01 | 1 | INTG-04 | T-04-03 | Trust scoring 3-tier system | structural | `grep -c "HIGH.*MEDIUM.*LOW" references/phase-3-integration.md` | N/A content | pending |
| 04-01-05 | 01 | 1 | INTG-05 | - | Integration gate requires user approval | structural | `grep -c "confirm" references/phase-3-integration.md` | N/A content | pending |
| 04-02-01 | 02 | 1 | CONF-01 | - | Per-agent confirmation with contract card | structural | `grep -c "contract card" references/phase-4-confirmation.md` | N/A content | pending |
| 04-02-02 | 02 | 1 | CONF-02 | - | Individual agent approval flow | structural | `grep -c "approve" references/phase-4-confirmation.md` | N/A content | pending |
| 04-02-03 | 02 | 1 | CONF-03 | T-04-04 | Dry run with tool stubbing | structural | `grep -c "stub\|DRY RUN" references/phase-4-confirmation.md` | N/A content | pending |
| 04-02-04 | 02 | 1 | CONF-04 | - | Dry run report format | structural | `grep -c "Dry Run Report" references/phase-4-confirmation.md` | N/A content | pending |
| 04-02-05 | 02 | 1 | CONF-05 | - | User reviews and approves dry run | structural | `grep -c "confirm.*deploy\|approve.*deploy" references/phase-4-confirmation.md` | N/A content | pending |

*Status: pending (pre-execution)*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. No test framework needed for markdown content verification.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Protocol readability and flow | All INTG/CONF | Subjective quality of conversational instructions | Read through each protocol and verify logical flow |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands
- [x] Sampling continuity: every task has a structural grep check
- [x] Wave 0 not needed (shell commands only)
- [x] No watch-mode flags
- [x] Feedback latency < 2s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
