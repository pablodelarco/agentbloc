---
phase: 11-integration-discovery-browser-fallback
plan: 04
subsystem: skill-wiring
status: complete
tags: [wiring, surgical-edit, forward-link-resolution, d-57, d-58, browser-01]
requires:
  - 11-01-SUMMARY.md  # browser-fallback.md (Plan 11-01 Task 1) + discovery-report-schema.md + output-firewall.md + fixture
  - 11-02-SUMMARY.md  # browser-stack.md (Plan 11-02 Task 1) + legal-posture.md + scripts/anti-bot-lint.sh + CI
  - 11-03-SUMMARY.md  # .claude/agents/browser-discovery.md (Plan 11-03 Task 1)
provides:
  - phase-3-integration.md Priority 3 section wired to browser-fallback.md + browser-stack.md + DISCOVERY-BLOCKED-REPORT.md (forward-link contract from Phase 10 Plan 10-03 resolved)
  - SKILL.md Phase 3 entry loads browser-fallback.md + browser-stack.md unconditionally (2 new See-lines, connector sentence rewritten)
affects:
  - .claude/skills/agentbloc/references/phase-3-integration.md  # Priority 3 heading unmarked + paragraph replaced + Step 2 descriptor cleanup
  - .claude/skills/agentbloc/SKILL.md  # Phase 3 See-line block extended from 4 to 6 entries + connector sentence extended
tech_stack:
  added: []
  patterns:
    - "Surgical Edit (Phase 10 D-40 + Phase 9 D-29): scoped Edit tool call with exact multi-line old_string/new_string preserving surrounding content byte-for-byte"
    - "Forward-Link Resolution: Phase 10 Plan 10-03 stubbed a [Phase 11 scope] marker + forthcoming See-line; Plan 11-04 closes the contract by unmarking the marker, replacing the stub paragraph with concrete citation, and keeping the v1.0 Summary block intact"
    - "Context-Budget Discipline (Phase 10 plan-eng-review P-1 observation, Phase 11 D-58): only 2 of the 5 Phase 11 references load unconditionally at Phase 3 entry; 3 (discovery-report-schema.md, output-firewall.md, legal-posture.md) load lazily inside browser-discovery subagent's forked context"
    - "Sub-Path Rather Than New Sub-Gate (D-58): browser fallback is a resolution_method under the existing mcp_integrations_verified sub-gate; no new State Transitions bullet added"
key_files:
  created: []
  modified:
    - .claude/skills/agentbloc/references/phase-3-integration.md  # +3 lines, -3 lines; 398 lines before, 398 after (character growth absorbed by natural wrapping in a single content line)
    - .claude/skills/agentbloc/SKILL.md  # +3 lines, -1 lines; 178 lines before, 180 after
decisions:
  - "D-57 applied: Priority 3 unmark + paragraph replacement + v1.0 Summary preservation (three sub-edits expressed as one Edit tool call with composite old_string/new_string)"
  - "D-58 applied: SKILL.md Phase 3 load-list extended with 2 See-lines (browser-fallback.md + browser-stack.md); NOT 5 lines; NOT a new sub-gate"
  - "Rule 3 auto-fix (GSD deviation): removed stale [Phase 11 scope] bracketed marker from Step 2 priority-order sentence (line 69) so the global grep-q '\\[Phase 11 scope\\]' acceptance criterion returns exit 1 as specified; unbracketed descriptor '(four-step fallback)' replaces it, matching new Priority 3 heading descriptor"
metrics:
  duration_minutes: 5
  completed_date: 2026-04-24
  tasks_completed: 2
  files_modified: 2
  files_created: 0
  commits:
    - 2984c1f  # Task 1: phase-3-integration.md Priority 3 wiring
    - 240001e  # Task 2: SKILL.md Phase 3 See-line block wiring
---

# Phase 11 Plan 04: Integration Discovery Browser Fallback Wiring Summary

Two surgical edits closing the forward-link contract Phase 10 Plan 10-03 left open: `phase-3-integration.md` Priority 3 section wired to `browser-fallback.md` + `browser-stack.md` + `DISCOVERY-BLOCKED-REPORT.md` + `scripts/anti-bot-lint.sh`, and `SKILL.md` Phase 3 entry See-line load-list extended from 4 to 6 references (unconditional loads only; D-58 context-budget discipline preserved).

## Final Line Counts

| File | Before | After | Delta | Budget | Status |
|------|--------|-------|-------|--------|--------|
| `.claude/skills/agentbloc/references/phase-3-integration.md` | 398 | 398 | +0 | 388-430 | In budget (character-level growth absorbed by prose wrapping in single content line) |
| `.claude/skills/agentbloc/SKILL.md` | 178 | 180 | +2 | 178-195 | In budget (well under 250-line v1.0 cap) |

## Diff Summary

### phase-3-integration.md (Task 1, commit 2984c1f)

**Edit 1 of 2 (combined as one Edit tool call per D-57):** Priority 3 heading unmark + forward-stub paragraph replacement + v1.0 Summary block preservation.

**Before (lines 92-100):**
```markdown
### Priority 3: Playwright Browser Automation [Phase 11 scope]

See forthcoming [references/browser-fallback.md](browser-fallback.md) (Phase 11 BROWSER-01..12) for the full Patchright + HAR capture + injection detector + PII redaction protocol. Phase 10 stubs this priority; Phase 11 wires it in.

**Summary (v1.0, preserved):**
- If no API or MCP server exists, WebSearch for `{service_name} login portal` or `{service_name} web dashboard`
- Whether the portal uses standard web forms (automatable)
- Whether 2FA/CAPTCHA is required (complicates automation)
- Playwright MCP (microsoft/playwright-mcp) is the automation tool -- HIGH trust, Microsoft-maintained
```

**After (lines 92-100):**
```markdown
### Priority 3: Playwright Browser Automation (Four-Step Fallback)

See [references/browser-fallback.md](browser-fallback.md) for the canonical Step 4 protocol: per-service legal opt-in -> subagent invocation -> HAR capture with checkpoint -> endpoint classification -> output firewall -> DISCOVERY-REPORT.md emission. See [references/browser-stack.md](browser-stack.md) for pinned versions (playwright@^1.59.1 + patchright@^1.59.4 for Posture B CDP-leak patches only) + anti-bot deny-list (9 forbidden packages including playwright-extra, CAPTCHA solvers, fingerprint spoofers; all enforced by CI via `scripts/anti-bot-lint.sh`). Posture C (hardened anti-bot: DataDome / PerimeterX / CAPTCHA challenge) always halts cleanly via DISCOVERY-BLOCKED-REPORT.md per BROWSER-09; no bypass attempts are made.

**Summary (v1.0, preserved):**
- If no API or MCP server exists, WebSearch for `{service_name} login portal` or `{service_name} web dashboard`
- Whether the portal uses standard web forms (automatable)
- Whether 2FA/CAPTCHA is required (complicates automation)
- Playwright MCP (microsoft/playwright-mcp) is the automation tool -- HIGH trust, Microsoft-maintained
```

**Edit 2 of 2 (auto-applied via Rule 3 deviation):** Step 2 priority-order sentence descriptor cleanup.

**Before (line 69 fragment):** `Playwright browser automation [Phase 11 scope]`
**After (line 69 fragment):** `Playwright browser automation (four-step fallback)`

Rationale: Plan 11-04 Task 1 acceptance criterion `grep -q "\[Phase 11 scope\]"` exit 1 is a global grep; a stale bracketed marker on line 69 would have failed the global check even though the plan's preservation rule scoped edits to lines 92-100. Rule 3 auto-fix: resolve the stale marker inline by matching the new Priority 3 heading descriptor.

### SKILL.md (Task 2, commit 240001e)

**Edit 1 of 1 (per D-58):** Phase 3 entry See-line load-list extended from 4 to 6; connector sentence extended.

**Before (lines 121-125):**
```markdown
You MUST read the complete integration analysis protocol AND the MCP integration protocol AND the ecosystem registry AND the integration manifest schema before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
See [references/mcp-integration-protocol.md](references/mcp-integration-protocol.md)
See [references/mcp-ecosystem-registry.md](references/mcp-ecosystem-registry.md)
See [references/integration-manifest-schema.md](references/integration-manifest-schema.md)
```

**After (lines 121-127):**
```markdown
You MUST read the complete integration analysis protocol AND the MCP integration protocol AND the ecosystem registry AND the integration manifest schema AND the browser-fallback protocol AND the browser stack reference before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
See [references/mcp-integration-protocol.md](references/mcp-integration-protocol.md)
See [references/mcp-ecosystem-registry.md](references/mcp-ecosystem-registry.md)
See [references/integration-manifest-schema.md](references/integration-manifest-schema.md)
See [references/browser-fallback.md](references/browser-fallback.md)
See [references/browser-stack.md](references/browser-stack.md)
```

Net delta: +2 lines (2 new See-lines appended in canonical order: imperative protocol first, declarative stack reference second, matching browser-discovery subagent's Mandatory Initial Read ordering per Plan 11-03). Existing 4 See-lines preserved byte-for-byte.

## Decisions Applied

### D-57: phase-3-integration.md Priority 3 unmark + See-line rewrite

Applied exactly as specified. Heading changes from `### Priority 3: Playwright Browser Automation [Phase 11 scope]` to `### Priority 3: Playwright Browser Automation (Four-Step Fallback)`. Stub paragraph replaced with 3-sentence concrete paragraph citing (1) browser-fallback.md canonical Step 4 protocol with 6-step flow enumeration, (2) browser-stack.md pinned versions + anti-bot deny-list + CI script, (3) Posture C halt behavior via DISCOVERY-BLOCKED-REPORT.md per BROWSER-09. v1.0 Summary block preserved verbatim.

### D-58: SKILL.md Phase 3 load-list extension with context-budget discipline

Applied exactly as specified. Only 2 of Phase 11's 5 references load unconditionally at Phase 3 entry: `browser-fallback.md` (imperative protocol) and `browser-stack.md` (declarative stack). The other 3 (`discovery-report-schema.md`, `output-firewall.md`, `legal-posture.md`) load lazily inside browser-discovery subagent's forked context on invocation. grep-for-absence checks pass (subagent-only refs confirmed NOT loaded at Phase 3 entry).

## Preservation Confirmations

### phase-3-integration.md (Task 1)

- v1.0 Summary header `**Summary (v1.0, preserved):**` preserved byte-for-byte (grep count 1)
- 4 v1.0 Summary bullets preserved byte-for-byte (login portal / standard web forms / 2FA-CAPTCHA / microsoft/playwright-mcp + HIGH trust)
- Phase-10-produced Priority 1 MCP Server (Four-Step Search) header preserved (grep count 1)
- Phase-10-produced Priority 2 Official API header preserved (grep count 1)
- v1.0 Priorities 4-6 (Email Scraping / Webhook Interception / Manual Notification) preserved (grep count 3)
- Steps 3-7 headers preserved byte-for-byte (Evidence Verification / Trust Scoring / Decision Matrix Construction / Security Cross-Reference / Integration Presentation and Approval)
- Integration Gate + Quick Reference headers preserved
- Zero em-dashes introduced (`grep -c "—"` returns 0)
- Priority 3 header count stable (exactly 1 `### Priority 3:` header)

### SKILL.md (Task 2)

- D-58 grep-for-absence: `discovery-report-schema.md`, `output-firewall.md`, `legal-posture.md` all absent from SKILL.md (3/3 pass)
- Existing 4 See-lines preserved byte-for-byte in original order
- Phase 3 See-line block now has exactly 6 See-lines (awk + grep count returns 6)
- Phase 3 Precondition paragraph (agent-profiles.yaml) preserved (awk scoped grep count 1)
- Phase 3 Summary Gate paragraph preserved (`**Summary Gate:**` grep count 2 across Phase 2 + Phase 3)
- State Transitions Phase-specific bullet count stable at 3 (Phase 1 + Phase 2 + Phase 3; no Phase 4 bullet added per D-58)
- mcp_integrations_verified sub-gate mention intact (browser fallback is sub-path, not new gate)
- Phase 1 / Phase 2 / Phase 4 / Phase 5 / Phase 6 entry headers preserved
- Phase 4 Precondition (integration-manifest.yaml) preserved (awk scoped grep count 1)
- Hard Gates + Quality Checklist + Reference Implementation section headers preserved
- Zero em-dashes (`grep -c "—"` returns 0)

## Deviations from Plan

### Rule 3 auto-fix: stale [Phase 11 scope] marker on Step 2 priority-order sentence

- **Found during:** Task 1 acceptance verification (global grep check)
- **Issue:** Plan 11-04 Task 1 acceptance criterion `grep -q "\[Phase 11 scope\]" ... returns exit 1` is a global file-wide grep. Line 69 of phase-3-integration.md contained a stale bracketed marker `Playwright browser automation [Phase 11 scope]` inside the Step 2 priority-order descriptor sentence (not in the Priority 3 heading the plan targeted). This marker was introduced by Phase 10 Plan 10-03 as a cross-reference to the forthcoming Priority 3 section.
- **Fix:** Replaced `[Phase 11 scope]` with `(four-step fallback)` to match the new Priority 3 heading descriptor. Keeps the mention of Playwright in the priority-order list; removes the stale forward-reference marker now that Phase 11 has shipped the concrete reference files.
- **Files modified:** `.claude/skills/agentbloc/references/phase-3-integration.md` (line 69, one-line edit, zero net line-count delta)
- **Commit:** 2984c1f (bundled with Task 1 primary edit)
- **Rationale:** The plan's Task 1 had internal tension between "don't edit before line 91" (preservation rule) and "grep-q '\\[Phase 11 scope\\]' returns exit 1" (global acceptance criterion). The global acceptance criterion won because the forward-link resolution intent (close the stale marker debt Phase 10 left) applies to every marker of that shape in the file, not just the Priority 3 heading. Rule 3 auto-fix is in scope because the task was blocked from passing its acceptance criterion otherwise.

No other deviations. Plan executed as written.

## BROWSER-01 Traceability

Requirement BROWSER-01 (browser-discovery subagent invocation wired into user-facing Phase 3 flow):

1. **`phase-3-integration.md` Priority 3** now cites `browser-fallback.md` which contains the `<subagent_invocation>` contract from Plan 11-01 (per-service legal opt-in gate -> Task() dispatch to browser-discovery subagent with TARGET.md + budget + fork context).
2. **`SKILL.md` Phase 3 entry** loads `browser-fallback.md` unconditionally, so Claude reads Step 1 (per-service legal opt-in gate with DISCOVERY-LICENSE-NOTICE.md emission + OPT_IN_LEDGER.jsonl append + user attestation) before ever invoking the browser-discovery subagent. Legal opt-in enforcement is now in the user-facing flow per ROADMAP Phase 11 success criterion 1.
3. **`SKILL.md` Phase 3 entry** also loads `browser-stack.md` unconditionally, surfacing `scripts/anti-bot-lint.sh` as the CI enforcement path for the 9-package anti-bot deny-list. CI deny-list active per ROADMAP Phase 11 success criterion 3 (the lint + CI step exist from Plan 11-02; Plan 11-04 surfaces them at the Phase 3 narrative layer).

## Forward-Link Contract Resolution

Phase 10 Plan 10-03 Task 1 Edit 3 introduced:
- A `[Phase 11 scope]` marker on the Priority 3 heading
- A `See forthcoming [references/browser-fallback.md](browser-fallback.md)` forward See-line with language "Phase 10 stubs this priority; Phase 11 wires it in."

Plan 11-04 resolves this contract:
- `[Phase 11 scope]` marker removed from Priority 3 heading AND from Step 2 priority-order descriptor sentence (global grep returns exit 1)
- "forthcoming" language removed (grep returns exit 1)
- "Phase 10 stubs this priority" language removed (grep returns exit 1)
- `browser-fallback.md` link now resolves to the concrete Plan 11-01 artifact that exists on disk
- `browser-stack.md` added as second reference, pointing to Plan 11-02 artifact that exists on disk
- `DISCOVERY-BLOCKED-REPORT.md` named for Posture C halts per BROWSER-09
- `scripts/anti-bot-lint.sh` named for CI deny-list enforcement per BROWSER-05

## Handoff Note for Phase 11 Verification

All 12 BROWSER requirements (BROWSER-01 through BROWSER-12) wired end-to-end across Plans 11-01 (imperative protocol + schema + firewall + Mapfre fixture), 11-02 (stack + legal + CI lint), 11-03 (browser-discovery subagent), and 11-04 (wiring; this plan). Phase 11 structurally complete. Ready for `/gsd-verify-phase 11`. Forward-link contract from Phase 10 Plan 10-03 (browser-fallback.md forward See-line) is now resolved; citation is concrete, target file exists.

## Handoff Note for Phase 12 (Deploy Pipeline)

Phase 12 consumes `.agentbloc/discovery/<service-slug>/DISCOVERY-REPORT.md` entries as `[DISCOVERED]`-tier integrations alongside `[VERIFIED]` MCP-path entries from Phase 10. Every `DISCOVERY-REPORT.md` with SHA256 hash + user_attestation_timestamp matching `OPT_IN_LEDGER.jsonl` is ready for deploy; `DISCOVERY-BLOCKED-REPORT.md` entries block Phase 4 gate; `INTERNAL-HARDENED` endpoints surface as enhanced-risk warnings in `DEPLOY-REPORT.md` per D-53 carry-forward.

## Self-Check: PASSED

- [x] `.claude/skills/agentbloc/references/phase-3-integration.md`: FOUND (398 lines, in [388,430] budget)
- [x] `.claude/skills/agentbloc/SKILL.md`: FOUND (180 lines, in [178,195] budget)
- [x] Commit `2984c1f` (Task 1): FOUND in git log
- [x] Commit `240001e` (Task 2): FOUND in git log
- [x] All 2 tasks' acceptance criteria: PASS (full grep battery, preservation checks, em-dash absence, D-58 grep-for-absence)
- [x] Forward-link contract from Phase 10 Plan 10-03: RESOLVED
