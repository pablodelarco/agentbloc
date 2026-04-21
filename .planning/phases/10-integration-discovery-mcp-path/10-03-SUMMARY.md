---
phase: 10-integration-discovery-mcp-path
plan: 03
subsystem: skill-wiring

tags: [skill-md, phase-3-integration, mcp-first, surgical-edit, gate-wiring, d-40, d-41]

# Dependency graph
requires:
  - phase: 10-integration-discovery-mcp-path
    provides: "mcp-integration-protocol.md + mcp-ecosystem-registry.md + integration-manifest-schema.md (Plan 10-01) and mcp-builder/SKILL.md (Plan 10-02) — the contracts this wiring plan mounts into the SKILL.md gate ritual"
  - phase: 09-designer-agent
    provides: "Three-edit precedent pattern for surgical SKILL.md modifications (State Transitions bullet + Summary Gate paragraph + Precondition paragraph — commit 783b538) which Phase 10 mirrors exactly one phase forward"

provides:
  - "phase-3-integration.md Step 2 Multi-Method Search Protocol reordered MCP-first per D-40 (Priority 1 and Priority 2 swapped)"
  - "phase-3-integration.md Priority 1 MCP Server (Four-Step Search) delegates full detail to mcp-integration-protocol.md via See-line while preserving v1.0 field summary"
  - "phase-3-integration.md Phase 3 entry load-list extended with 3 new references (mcp-integration-protocol + mcp-ecosystem-registry + integration-manifest-schema)"
  - "phase-3-integration.md Priority 3 Playwright Browser Automation marked [Phase 11 scope] with forward See-line to browser-fallback.md"
  - "SKILL.md State Transitions section extended with Phase 3 specific bullet naming the mcp_integrations_verified sub-gate"
  - "SKILL.md Phase 3 entry extended with Summary Gate paragraph citing D-14 + D-34 + D-35 and See-line load list grown from 1 to 4 references"
  - "SKILL.md Phase 4 entry gated on integration-manifest.yaml existing + every entry status: verified + healthcheck_at timestamp"
  - "Halt-and-Name Protocol (D-35, INTEG-05) now structurally wired into both the protocol file (Priority 1 summary) and the skill entry (Summary Gate paragraph)"

affects:
  - "phase-11-browser-fallback (will create references/browser-fallback.md to resolve the forward See-line inserted in phase-3-integration.md Priority 3)"
  - "phase-12-deploy-pipeline (consumes .agentbloc/integrations/integration-manifest.yaml gated by the new Phase 4 precondition)"
  - "phase-verification-10 (this plan completes Phase 10 wiring; ready for /gsd-verify-phase 10)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Three-edit surgical modification (SKILL.md and phase-N-*.md pattern) — Phase 10 mirrors Phase 9 commit 783b538 one phase forward"
    - "Priority-ladder reorder via combined Edit tool operation (intro sentence + two section headers in one old_string / new_string pair)"
    - "Phase-N-scope marker pattern for forward-link stubs (`[Phase 11 scope]` with forthcoming See-line)"
    - "Sub-gate vocabulary lockdown in State Transitions bullets (mcp_integrations_verified joins business_graph_validated and agent_profiles_validated)"

key-files:
  created:
    - ".planning/phases/10-integration-discovery-mcp-path/10-03-SUMMARY.md — this file"
  modified:
    - ".claude/skills/agentbloc/references/phase-3-integration.md — 3 surgical edits (388 -> 398 lines, +10)"
    - ".claude/skills/agentbloc/SKILL.md — 3 surgical edits (170 -> 178 lines, +8)"

key-decisions:
  - "D-40 applied operationally: MCP server promoted from v1.0 Priority 2 to v2.0 Priority 1; Official API demoted to Priority 2 with explicit 'Fallback when no MCP exists or can be generated' lead sentence"
  - "D-41 applied structurally: new `mcp_integrations_verified` sub-gate joins existing `business_graph_validated` and `agent_profiles_validated` in State Transitions, completing the Phase-1/2/3 gate vocabulary triad"
  - "Phase 3 entry See-line load list grows from 1 to 4 files (phase-3-integration + mcp-integration-protocol + mcp-ecosystem-registry + integration-manifest-schema) — matches the 4-file load-list established by Phase 1 (3 refs) and Phase 2 (3 refs) patterns"
  - "Priority 3 Playwright section intentionally retains v1.0 4-bullet summary under 'Summary (v1.0, preserved)' heading even though a forward See-line to Phase 11's browser-fallback.md was added — no regression until Phase 11 replaces the stub"
  - "Forward See-line to browser-fallback.md is an accepted broken link per T-10-12 (STRIDE disposition: accept); Phase 11 resolves it"

patterns-established:
  - "Three-edit SKILL.md surgical pattern (State Transitions bullet + Summary Gate + Precondition) — reusable for Phase 11, 12 as each new phase adds its own gate vocabulary"
  - "Delegation See-line pattern: core file preserves v1.0 summary while a See-line points to a protocol file for full detail (new Priority 1 in phase-3-integration.md delegates to mcp-integration-protocol.md)"
  - "Phase-N-scope stub pattern: marker in section heading + forward See-line + 'Summary (v1.0, preserved)' block keeps the v1.0 content while signaling future expansion"

requirements-completed: [INTEG-02, INTEG-05]

# Metrics
duration: 12min
completed: 2026-04-21
---

# Phase 10 Plan 03: Wire Phase 10 Contracts Into SKILL.md Gate Ritual Summary

**Six surgical edits across two files (phase-3-integration.md and SKILL.md) promote MCP-first to Priority 1 per D-40 and lock the mcp_integrations_verified sub-gate per D-41, mirroring the Phase 9 09-03 pattern one phase forward.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-04-21T09:08:32Z
- **Completed:** 2026-04-21T09:20:53Z
- **Tasks:** 2
- **Files modified:** 2
- **Commits:** 2 task commits + 1 SUMMARY commit

## Accomplishments

- Phase 3 integration protocol reordered MCP-first per D-40 with Priority 1 (MCP Server - Four-Step Search) delegating to mcp-integration-protocol.md while preserving v1.0 field summary (package / stars / commit / publisher / tools)
- Priority 3 Playwright Browser Automation stubbed with `[Phase 11 scope]` marker and forward See-line to `browser-fallback.md` without deleting v1.0 4-bullet summary
- SKILL.md State Transitions section now has the full Phase-1 / Phase-2 / Phase-3 triad of sub-gate bullets (business_graph_validated / agent_profiles_validated / mcp_integrations_verified)
- SKILL.md Phase 3 entry gained a Summary Gate paragraph citing D-14 silent emission + D-34 three-check Verification Loop + D-35 Halt-and-Name Protocol, plus its See-line load list grew from 1 to 4 references
- SKILL.md Phase 4 entry now has a Precondition paragraph gating on `.agentbloc/integrations/integration-manifest.yaml` existing + every entry `status: verified` with a `healthcheck_at` timestamp — blocks transition until the Phase 10 manifest contract is satisfied
- Zero new em-dashes across both files (CLAUDE.md compliance held)
- Regression-guard clean: zero hardcoded `Priority 1: Official API` / `Priority 2: MCP Server` strings in tests/ (plan-eng-review iron rule T-1)

## Task Commits

Each task committed atomically:

1. **Task 1: phase-3-integration.md MCP-first priority promotion + Phase 11 stub** — `28050c4` (feat)
2. **Task 2: SKILL.md mcp_integrations_verified sub-gate + Phase 3 Summary + Phase 4 precondition** — `7087a74` (feat)

**Plan metadata:** _this commit_ (docs: complete Phase 10 wiring)

## Files Created/Modified

### Modified

#### `.claude/skills/agentbloc/references/phase-3-integration.md` — 388 to 398 lines (+10)

**Edit 1: Phase 3 entry also-load list extension (lines 26-31 post-edit)**

Before (3 lines):
```
At Phase 3 entry, also load:
- [references/credentials.md](credentials.md) for the credential decision tree (used in Step 6)
- [references/prompt-injection.md](prompt-injection.md) for the defense layer pipeline (used in Step 6)
```

After (6 lines):
```
At Phase 3 entry, also load:
- [references/credentials.md](credentials.md) for the credential decision tree (used in Step 6)
- [references/prompt-injection.md](prompt-injection.md) for the defense layer pipeline (used in Step 6)
- [references/mcp-integration-protocol.md](mcp-integration-protocol.md) for the 4-step MCP search flow (used in Step 2 Priority 1)
- [references/mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) for the curated MCP registry (used in Step 2 Priority 1 Step 2)
- [references/integration-manifest-schema.md](integration-manifest-schema.md) for the integration manifest output contract (used at Integration Gate)
```

Delta: +3 lines (load-list extension). v1.0 credentials.md + prompt-injection.md entries preserved verbatim.

**Edit 2: Step 2 intro sentence reorder + Priority 1/Priority 2 section swap (lines 69-90 post-edit)**

Before intro sentence (line 66, 1 line):
```
For each service in the inventory, search integration methods in this strict priority order. This follows decision D-01: official API (best) > MCP server (native) > Playwright browser automation > email scraping > webhook interception > manual notification (last resort).
```

After intro sentence (line 69, 1 line, reordered per D-40):
```
For each service in the inventory, search integration methods in this strict priority order. This follows v2.0 decision D-40 (MCP-first positioning from PROJECT.md): MCP server (four-step search) > official API (fallback when no MCP) > Playwright browser automation [Phase 11 scope] > email scraping > webhook interception > manual notification (last resort). See [mcp-integration-protocol.md](mcp-integration-protocol.md) for the full MCP search flow.
```

Before Priority 1 + Priority 2 sections (lines 68-84, 17 lines):
```
### Priority 1: Official API

WebSearch for `{service_name} API documentation`. If found, record:
- API endpoint base URL
- Authentication method (OAuth, API key, basic auth)
- Rate limits and quotas
- SDK availability (npm, Python, etc.)

### Priority 2: MCP Server

Search for existing MCP servers. Use PulseMCP (`list_servers` tool if available) or WebSearch for `{service_name} MCP server site:pulsemcp.com OR site:github.com`. If found, record:
- Package name (npm or GitHub)
- GitHub stars count
- Last commit date
- Publisher (individual or organization)
- Available tools/capabilities
```

After Priority 1 (NEW MCP) + Priority 2 (NEW Official API) sections (lines 71-90, 20 lines):
```
### Priority 1: MCP Server (Four-Step Search)

See [mcp-integration-protocol.md](mcp-integration-protocol.md) for the canonical 4-step flow: existing `.mcp.json` -> ecosystem registry lookup (via [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md)) -> wrapper generation via `.claude/skills/mcp-builder/SKILL.md` -> browser-fallback (Phase 11 scope).

**Summary for quick reference** (full detail in the protocol file):
- Package name (npm or GitHub) from mcp-ecosystem-registry.md or `.mcp/generated/<tool-id>/`
- GitHub stars count (trust_tier criterion per v1.0 INTG-04)
- Last commit date (trust_tier criterion)
- Publisher (individual or organization)
- Available tools/capabilities (populated by D-34 `tools/list` probe during Verification Loop)

After the 4-step search resolves, the D-34 three-check Verification Loop (Ping / Scope match / Shape probe) runs. Any FAIL triggers the Halt-and-Name Protocol per D-35 - no silent degradation. Output lands in `.agentbloc/integrations/integration-manifest.yaml` per [integration-manifest-schema.md](integration-manifest-schema.md).

### Priority 2: Official API

Fallback when no MCP exists or can be generated. WebSearch for `{service_name} API documentation`. If found, record:
- API endpoint base URL
- Authentication method (OAuth, API key, basic auth)
- Rate limits and quotas
- SDK availability (npm, Python, etc.)
```

Delta: +3 lines. v1.0 MCP fields (package / stars / commit / publisher / tools) preserved in new Priority 1 summary; v1.0 Official API bullets (4 bullets) preserved verbatim in new Priority 2 with "Fallback when no MCP exists or can be generated" lead added.

**Edit 3: Priority 3 Playwright [Phase 11 scope] marker (lines 92-100 post-edit)**

Before (lines 85-90, 6 lines):
```
### Priority 3: Playwright Browser Automation

If no API or MCP server exists, WebSearch for `{service_name} login portal` or `{service_name} web dashboard`. Note:
- Whether the portal uses standard web forms (automatable)
- Whether 2FA/CAPTCHA is required (complicates automation)
- Playwright MCP (microsoft/playwright-mcp) is the automation tool -- HIGH trust, Microsoft-maintained
```

After (lines 92-100, 9 lines):
```
### Priority 3: Playwright Browser Automation [Phase 11 scope]

See forthcoming [references/browser-fallback.md](browser-fallback.md) (Phase 11 BROWSER-01..12) for the full Patchright + HAR capture + injection detector + PII redaction protocol. Phase 10 stubs this priority; Phase 11 wires it in.

**Summary (v1.0, preserved):**
- If no API or MCP server exists, WebSearch for `{service_name} login portal` or `{service_name} web dashboard`
- Whether the portal uses standard web forms (automatable)
- Whether 2FA/CAPTCHA is required (complicates automation)
- Playwright MCP (microsoft/playwright-mcp) is the automation tool -- HIGH trust, Microsoft-maintained
```

Delta: +4 lines. All 4 v1.0 bullets preserved verbatim under "Summary (v1.0, preserved)" heading; forward See-line to Phase 11's browser-fallback.md (broken link is intentional per D-40 + T-10-12 accept disposition).

**Net file delta: +10 lines (388 -> 398), within 388-430 budget.**

**Preservation confirmations (Steps 3-7 + Integration Gate + Quick Reference verbatim):**
- `^## Step 3: Evidence Verification$` present (line 129)
- `^## Step 4: Trust Scoring$` present (line 165)
- `^## Step 5: Decision Matrix Construction$` present (line 203)
- `^## Step 6: Security Cross-Reference$` present (line 246)
- `^## Step 7: Integration Presentation and Approval$` present (line 297)
- `^## Integration Gate$` present (line 328)
- `^## Quick Reference$` present (line 353)

**Regression-guard: clean.** `grep -rE "Priority 1:\s*Official API|Priority 2:\s*MCP Server" tests/` returns zero matches — no hardcoded v1.0 priority strings in TAP scenarios to invalidate.

#### `.claude/skills/agentbloc/SKILL.md` — 170 to 178 lines (+8)

**Edit 1: State Transitions Phase 3 specific bullet (line 42 post-edit)**

Before (line 41, 1 bullet):
```
- Phase 2 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered team table and per-agent cards AND the `agent_profiles_validated` sub-gate (all REQUIRED checks from [references/agent-profile-schema.md](references/agent-profile-schema.md) Validation Checklist have passed and the file at `.agentbloc/team/agent-profiles.yaml` has been written by the Designer subagent).
```

After (lines 41-42, 2 bullets):
```
- Phase 2 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered team table and per-agent cards AND the `agent_profiles_validated` sub-gate (all REQUIRED checks from [references/agent-profile-schema.md](references/agent-profile-schema.md) Validation Checklist have passed and the file at `.agentbloc/team/agent-profiles.yaml` has been written by the Designer subagent).
- Phase 3 specific: Gate transition to `approved` requires BOTH user confirmation of the rendered integrations table AND the `mcp_integrations_verified` sub-gate (all REQUIRED checks from [references/integration-manifest-schema.md](references/integration-manifest-schema.md) Validation Checklist have passed, every tool entry has `status: verified` with a `healthcheck_at` timestamp, and the file at `.agentbloc/integrations/integration-manifest.yaml` has been written).
```

Delta: +1 line. New sub-gate vocabulary (`mcp_integrations_verified`) added; Phase 2 bullet preserved verbatim as anchor.

**Edit 2: Phase 3 entry Summary Gate + extended See-line list (lines 119-125 post-edit)**

Before (lines 118-119, 2 lines):
```
You MUST read the complete integration analysis protocol before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
```

After (lines 119-125, 7 lines):
```
**Summary Gate:** After walking the 4-step MCP search + three-check Verification Loop, write `.agentbloc/integrations/integration-manifest.yaml` silently. The rendered integrations table + per-tool evidence rows are what the user reviews and confirms (D-14 mirror). See [references/mcp-integration-protocol.md](references/mcp-integration-protocol.md) Verification Loop for the D-34 three-check protocol and Halt-and-Name Protocol for D-35 failure handling.

You MUST read the complete integration analysis protocol AND the MCP integration protocol AND the ecosystem registry AND the integration manifest schema before starting this phase:
See [references/phase-3-integration.md](references/phase-3-integration.md)
See [references/mcp-integration-protocol.md](references/mcp-integration-protocol.md)
See [references/mcp-ecosystem-registry.md](references/mcp-ecosystem-registry.md)
See [references/integration-manifest-schema.md](references/integration-manifest-schema.md)
```

Delta: +5 lines. New Summary Gate paragraph (citing D-14 + D-34 + D-35) + rewritten connector sentence + 3 new See-lines (mcp-integration-protocol / mcp-ecosystem-registry / integration-manifest-schema); existing phase-3-integration.md See-line preserved verbatim.

**Edit 3: Phase 4 entry Precondition paragraph (line 131 post-edit)**

Before (lines 121-125, Phase 4 header + intro):
```
### Phase 4: Step-by-Step Confirmation + Dry Run

Get explicit approval for every single step each agent will perform. Then execute a mandatory dry run: agents run against real data with all side-effect tools stubbed. Validate outputs before going live.

You MUST read the complete confirmation and dry run protocol before starting this phase:
```

After (lines 127-133, Phase 4 header + intro + NEW Precondition):
```
### Phase 4: Step-by-Step Confirmation + Dry Run

Get explicit approval for every single step each agent will perform. Then execute a mandatory dry run: agents run against real data with all side-effect tools stubbed. Validate outputs before going live.

**Precondition:** Verify `.agentbloc/integrations/integration-manifest.yaml` exists AND every tool entry has `status: verified` with a `healthcheck_at` timestamp (per [references/integration-manifest-schema.md](references/integration-manifest-schema.md) Validation Checklist). If the file is missing, any entry is `status: failed`, or any REQUIRED check fails, return the state bar to Phase 3 with gate `pending` and re-run the Summary gate before attempting Phase 4 again.

You MUST read the complete confirmation and dry run protocol before starting this phase:
```

Delta: +2 lines. Phase 4 now gated on the Phase 10 manifest contract (T-10-13 mitigate disposition wired).

**Net file delta: +8 lines (170 -> 178), within 170-195 budget; well under 250-line v1.0 cap.**

**Preservation confirmations (Phase 1 / Phase 2 / Phase 5 / Phase 6 / Hard Gates / Quality Checklist / Reference Implementation verbatim):**
- `^- Phase 1 specific:.*business_graph_validated` present (line 40)
- `^- Phase 2 specific:.*agent_profiles_validated` present (line 41)
- Phase 2 Summary Gate "spawn the Designer Agent subagent" present (line 106)
- Phase 3 existing Precondition citing agent-profile-schema.md present (line 117)
- `^## Hard Gates$` present (line 52)
- `^## Quality Checklist$` present (line 161)
- `^## Reference Implementation$` present (line 176)

**Zero em-dashes** in either modified file (CLAUDE.md compliance held across both edits).

## Decisions Made

- **Combined Edit 2 in Task 1** (intro sentence + Priority 1/Priority 2 section swap): chose a single combined Edit tool operation rather than 3 separate edits because the three sub-changes share contiguous context (lines 66-84). Combining guaranteed atomic swap semantics and prevented interim file states where Priority 1 and Priority 2 could both reference "Official API" mid-transition.
- **Preserved v1.0 Official API 4 bullets verbatim in new Priority 2**: D-40 spec allowed prepending "Fallback when no MCP exists or can be generated" as the lead sentence; the 4 bullets (endpoint URL / auth method / rate limits / SDK) stayed untouched. This minimized diff noise and preserved the v1.0 contract text for any downstream reader.
- **Forward See-line to browser-fallback.md accepted as broken link**: per T-10-12 STRIDE disposition (accept), the "See forthcoming" language in the Priority 3 section signals Phase 11 will create the target. No silent degradation — the link is explicitly labeled forthcoming and reader is told Phase 11 creates the file.
- **SKILL.md landed at 178 lines, well under the 195 budget and 250-line cap**: D-41 predicted 180; actual 178 (the connector sentence replacement absorbed 1 line of the +1 bullet delta). Comfortable headroom for future phase additions.

## Deviations from Plan

None - plan executed exactly as written. All 6 surgical edits used the exact `old_string` / `new_string` text specified in the plan's `<interfaces>` block, in the specified order, with no content drift.

## Issues Encountered

None. Both files were read fully before editing, Edit tool operations succeeded on first attempt, and all acceptance-criteria grep checks passed on first verification pass.

## User Setup Required

None - no external service configuration required. This is a pure documentation/skill-wiring plan.

## Next Phase Readiness

**Phase 10 structurally complete.** All 6 INTEG requirements (INTEG-01 through INTEG-06) now wired end-to-end across Plans 10-01 / 10-02 / 10-03:

- INTEG-01 (contract-first interface design): Plan 10-01 created mcp-integration-protocol.md + integration-manifest-schema.md as the contracts; Plan 10-03 mounts them at Phase 3 entry.
- INTEG-02 (ecosystem install path): Plan 10-01 created mcp-ecosystem-registry.md; Plan 10-03 wires it as Step 2 Priority 1 Step-2 lookup + loads it at SKILL.md Phase 3 entry.
- INTEG-03 (wrapper generation via mcp-builder): Plan 10-02 created the mcp-builder skill; Plan 10-03 references its path in the phase-3-integration.md Priority 1 summary.
- INTEG-04 (trust-tier + evidence fields): Plan 10-01 integration-manifest-schema.md Validation Checklist; Plan 10-03 SKILL.md Phase 3 specific bullet enforces it.
- INTEG-05 (halt-and-name UX, no silent degradation): Plan 10-01 D-35 specification; Plan 10-03 cites it in phase-3-integration.md Priority 1 summary + SKILL.md Phase 3 Summary Gate paragraph; sub-gate blocks Phase 4 transition until every entry has status: verified.
- INTEG-06 (manifest as deploy-pipeline input): Plan 10-01 integration-manifest-schema.md; Plan 10-03 SKILL.md Phase 4 precondition gates on the manifest file's existence + status.

**Ready for `/gsd-verify-phase 10`.**

### Handoff to Phase 11 (Integration Discovery - Browser Fallback, BROWSER-01..12)

Phase 11 creates `.claude/skills/agentbloc/references/browser-fallback.md` to resolve the forward See-line inserted in `phase-3-integration.md` Priority 3 by this plan. Target content per the forward See-line: "full Patchright + HAR capture + injection detector + PII redaction protocol". Phase 11 also replaces the Priority 3 "Phase 10 stubs this priority; Phase 11 wires it in." sentence with the live wiring text once browser-fallback.md exists.

### Handoff to Phase 12 (Deploy Pipeline)

Phase 12 consumes `.agentbloc/integrations/integration-manifest.yaml` to render `.mcp.json` merges + ClaudeClaw job configs. The manifest's contract is locked by:

- Plan 10-01's `integration-manifest-schema.md` Validation Checklist (what fields must be populated)
- Plan 10-03's SKILL.md Phase 4 precondition (every entry `status: verified` with `healthcheck_at` timestamp, or Phase 4 returns to Phase 3 pending)

Phase 12 MUST:
1. Read `.agentbloc/integrations/integration-manifest.yaml` as input
2. Surface `status: failed` entries as blockers before deploy-artifact generation
3. Surface `[UNVERIFIED]` entries (missing evidence fields) as warnings in DEPLOY-REPORT.md per v1.0 INTG-06 carry-forward
4. Propagate `healthcheck_at` timestamps into deploy-report health-check freshness checks

## Self-Check: PASSED

Verified before completion:

- `test -f .claude/skills/agentbloc/references/phase-3-integration.md` — FOUND
- `test -f .claude/skills/agentbloc/SKILL.md` — FOUND
- Commit `28050c4` (Task 1) — FOUND via `git log --oneline`
- Commit `7087a74` (Task 2) — FOUND via `git log --oneline`
- phase-3-integration.md: 398 lines (within 388-430 budget)
- SKILL.md: 178 lines (within 170-195 budget)
- Zero em-dashes in both files
- All 6 surgical edits verified via grep against their expected text
- Regression-guard clean (zero hardcoded v1.0 priority strings in tests/)
- Preservation: Steps 3-7 + Integration Gate + Quick Reference unchanged in phase-3-integration.md
- Preservation: Phase 1 / 2 / 5 / 6 + Hard Gates + Quality Checklist + Reference Implementation unchanged in SKILL.md

---
*Phase: 10-integration-discovery-mcp-path*
*Completed: 2026-04-21*
