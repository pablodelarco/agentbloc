---
phase: 16-end-to-end-validation-and-release
plan: 01
status: complete
date: 2026-04-26
commits:
  - 4f645b4 feat(16-01): Task 1 arco-rooms.jsonl v2.0 walkthrough + 13 assertions
  - 81592b4 feat(16-01): Task 2 run-tests.sh Category 6 v2.0 coverage validator
  - 6d36ec0 feat(16-01): Task 3 interleave assertions + fix SKILL.md path resolution
success_criteria_closed:
  - 1
  - 2
---

# Plan 16-01 SUMMARY: TAP Harness + Arco Rooms E2E Coverage

## Outcome

3 atomic commits closing Phase 16 Success Criteria 1 (Arco Rooms scenario exercises full v2.0 flow) + 2 (TAP harness gains >= 1 assertion per new v2.0 category). Bonus: incidentally fixed a v1.0-era latent SKILL.md path bug that had been silently failing in `validate_references` since Phase 12 D-59a path namespace reshuffle.

## Artifacts Emitted / Extended

| Artifact | Action | Lines | Plan target | Closes |
|---|---|---|---|---|
| `tests/scenarios/arco-rooms.jsonl` | EXTENDED | 81 (was 50) | 80-130 | SC-1 |
| `tests/run-tests.sh` | EXTENDED | 311 (was 254) | 280-340 | SC-2 |

## What's Shipped

**`arco-rooms.jsonl` extension** , 31 new lines appended preserving all 50 v1.0 baseline turns byte-identical. Appended block contains 14 new conversation turns (7 user + 7 assistant) at Phase 6 walking through every v2.0 capability + 13 assertion lines interleaved at the correct slot (each assertion immediately follows the assistant turn it tests, per validate_assertions semantics). Coverage: BGRAPH (`business-graph.json`), INTV (`decision_patterns`), DSGN (`agent-profiles.yaml`), ORCH (`(sequential|event-driven|conversational|loop|parallel)`), ANTIC (`ANTICIPATED`), DEPLOY (`DEPLOY-REPORT`), MEM (`(memory.md|state.json|last-run.json)`), RUNTIME (`correlation_id`), AUTON (`(autonomy|approval-router)`), MONITOR (`(jsonl-log-schema|briefing-agent)`), CTRL (`(activity-feed|status badges)`), INTEG (`integration-manifest.yaml`), BROWSER (`(DISCOVERY-LICENSE-NOTICE|Patchright)`).

**`run-tests.sh` extension** , 49 net new lines via two changes:
1. NEW `validate_v2_category_coverage` (Category 6 validator): emits one TAP line per v2.0 category checked against the scenario file as a whole; uses portable `case` statement instead of Bash 4 `declare -A` for macOS compat; SKIP-emits for non-arco-rooms scenarios so other v1.0 examples don't fail
2. EXTENDED `validate_references`: prefers `.claude/skills/agentbloc/SKILL.md` (v2.0 canonical path per Phase 12 D-59a), falls back to `$REPO_ROOT/SKILL.md` for v1.0 backward compat. Fixes a latent bug where v1.0 baseline expected SKILL.md at repo root but Phase 12 moved it.

## Acceptance Gates

| Gate | Result | Evidence |
|---|---|---|
| Em-dash gate (NEW prose) | PASS | grep -c "—" on diff hunks = 0 across both files |
| arco-rooms.jsonl JSON validity | PASS | 81/81 lines parse cleanly via jq -e |
| arco-rooms.jsonl phase non-decreasing | PASS | All appended turns at Phase 6; validate_sequence emits ok |
| run-tests.sh syntactic validity | PASS | bash -n tests/run-tests.sh |
| TAP harness exit 0 | PASS | 146 tests, 146 pass, 0 fail |
| 13 v2.0 anchor coverage on arco-rooms | PASS | All 13 ok lines emitted (tests 35-47) |
| 13 v2.0 assertions on arco-rooms | PASS | All 13 ok lines emitted (tests 22-34 post-rearchitecture) |
| Existing v1.0 assertions still pass | PASS | All 18 v1.0 baseline assertions still match (tests 4-21) |
| SKILL.md ref validation now passes | PASS | 27 SKILL.md cross-references all resolve under .claude/skills/agentbloc/ (tests 120-146) |

## Architectural Invariants Held

| Invariant | Expected | Evidence |
|---|---|---|
| D-83 (surgical-edit discipline) | Existing 50-turn baseline preserved verbatim | head -50 arco-rooms.jsonl matches pre-Phase-16 baseline byte-identical |
| D-104 (Category 6 validator) | Validator added; SKIP-emits for non-canonical scenarios | run-tests.sh L221-L268 contains validate_v2_category_coverage with case-statement portability |
| Atomic commits per task (Phase 13/14/15 precedent) | 3 commits for Plan 16-01 | git log confirms commits 4f645b4 + 81592b4 + 6d36ec0 |
| TAP harness backward compat | All existing v1.0 assertions still pass | 18 v1.0 + 13 v2.0 = 31 assertion ok lines per scenario file |

## Lean-Mode Compromise Disclosure

None. All artifacts within target line ranges. The 3-commit task structure (instead of 2) reflects the Task 3 dual-fix discovery (SKILL.md path bug surfaced during TAP execution); both fixes landed atomically in commit 6d36ec0 since they were discovered during the same TAP run and would have caused FAILED test count if shipped separately.

## Lessons (folded into Phase 16 D-104)

- **Assertion locality matters in JSONL scenarios:** validate_assertions tests each assertion against `last_assistant_content`, which mutates on every assistant turn parse. Assertions stacked at end-of-file all test against the closing assistant turn. Future scenarios should interleave assertions immediately after the assistant turn they test.
- **macOS Bash 3.2 compat requires case statements:** `declare -A` associative arrays only work in Bash 4+. CI runs Linux Bash 4+ but local dev macOS ships Bash 3.2. Portable approach: `case "$category" in PATTERN1) ...; esac` inside a for loop.
- **Test runner SKIPs are TAP-compliant ok lines with annotation suffix:** Per TAP spec, SKIP is communicated via the directive `# SKIP <reason>` appended to ok lines. Plan 16-01 chose explicit `ok N - <name>: <category> SKIP (<reason>)` text format which is TAP-spec-compliant + human-readable in plain output.

## Next

Plan 16-02 (Release Artifacts + v2.0.0 Tag) ships:
1. README v2.0 What's New section + version badge bump
2. CHANGELOG [2.0.0] entry per Keep-a-Changelog
3. `.planning/milestones/v2.0-ROADMAP.md` archive per D-106
4. LOCAL annotated git tag v2.0.0 (NO push per D-107)
