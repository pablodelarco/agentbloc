---
phase: 1
slug: skill-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 1 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell commands (wc, grep, test) + manual review |
| **Config file** | none |
| **Quick run command** | `wc -l SKILL.md && ls references/` |
| **Full suite command** | `wc -l SKILL.md && ls references/ && grep -c "PHASE:" SKILL.md` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must pass
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 01-01-01 | 01 | 1 | ARCH-01 | automated | `wc -l SKILL.md` (must be < 250) | pending |
| 01-01-02 | 01 | 1 | ARCH-01 | automated | `grep -c "^---$" SKILL.md` (YAML frontmatter present) | pending |
| 01-02-01 | 02 | 1 | ARCH-02 | automated | `ls references/*.md \| wc -l` (reference files exist) | pending |
| 01-02-02 | 02 | 1 | ARCH-03 | manual | Verify state bar format in SKILL.md instructions | pending |
| 01-03-01 | 03 | 1 | ARCH-04 | manual | Verify gate enforcement instructions present | pending |
| 01-03-02 | 03 | 1 | ARCH-07 | manual | Verify bilingual detection instructions present | pending |
| 01-03-03 | 03 | 1 | ARCH-08 | manual | Verify tech-level detection instructions present | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements (no test framework needed for markdown validation).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| State bar format is styled, not raw brackets | ARCH-03 | Prose content, not machine-testable | Read SKILL.md state protocol section, confirm it instructs styled output |
| Phase summaries include hybrid loading (natural instruction + @reference) | ARCH-02 | Content quality, not machine-testable | Read each phase summary in SKILL.md, confirm both instruction and path present |
| Context refresh pattern described | ARCH-05 | Design pattern, not machine-testable | Read SKILL.md for phase boundary refresh instructions |
| Phase loopback protocol defined | ARCH-06 | Design pattern, not machine-testable | Read SKILL.md for loopback rules |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or manual instructions
- [ ] SKILL.md under 250 lines
- [ ] Reference files created in flat references/ directory
- [ ] Frontmatter valid YAML with version field
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
