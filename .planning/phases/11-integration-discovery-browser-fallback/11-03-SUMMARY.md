---
plan: 11-03
phase: 11
title: Browser-Discovery Subagent Definition
status: complete
completed_at: 2026-04-24T00:00:00Z
task_commit: 71637f2
---

# Plan 11-03 SUMMARY

## Plan ID

11-03 (Phase 11: Integration Discovery Browser Fallback).

## Status

Complete. Task 1 committed at `71637f2`. All 26 plan-verify grep checks PASS plus all 11 hardened-guard checks PASS. Line count 171 (within 170-280 target). Zero em-dashes.

## Artifact

| Path | Lines | Purpose |
| ---- | ----- | ------- |
| `.claude/agents/browser-discovery.md` | 171 | Claude Code subagent definition for Phase 3 Step 4 browser fallback. Structural twin of `.claude/agents/designer-agent.md` with `context: fork`, scoped Playwright MCP tool set, NO Bash, NO WebFetch. Ready for Plan 11-04 to wire into `phase-3-integration.md` Priority 3 via the D-57 See-line replacement. |

Frontmatter declares `name: browser-discovery`, `description` (folded scalar carrying the 7-line reverse-engineers copy), `tools` (Read, Grep, Glob, Write plus the 13 Playwright MCP tools in D-43 order), `color: red`, `context: fork`. First 18 lines contain zero `Bash`, zero `WebFetch`, zero other MCP tools.

Body XML blocks (7 blocks total, per plan spec):

1. `<role>` wraps three generator-style opening paragraphs, the Mandatory Initial Read list of 5 required inputs (TARGET.md, agent-profiles.yaml, discovery-report-schema.md, output-firewall.md, legal-posture.md), and 8 Core responsibilities bullets mapping to D-46, D-47, D-49, D-50, D-51, D-52, D-53, D-55, D-35.
2. `<write_constraint>` enumerates exactly 6 allowed write paths under `.agentbloc/discovery/` and explicit deny list for `.claude/skills/`, `.claude/agents/`, `.planning/`, `.env`, `.mcp.json`, `.agentbloc/team/`, `.agentbloc/integrations/`, `.mcp/`.
3. `<output_contract>` emits a 3-part success return (path + rendered markdown TABLE + one-line summary) and a 3-part halt return (named enum halt reason + DISCOVERY-BLOCKED-REPORT.md path + no DISCOVERY-REPORT.md written).
4. `<opt_in_gate>` emits the D-47 7-step protocol verbatim (ToS fetch via browser_navigate, ToS excerpt SHA256 via browser_snapshot, ToS tier classification, DISCOVERY-LICENSE-NOTICE.md render, user attestation surface, OPT_IN_LEDGER.jsonl append, browser launch only after ledger success) plus refusal posture for TOS-RED.
5. `<posture_classification>` emits the D-49 A/B/C enum rules verbatim (A = stock Playwright, B = Patchright CDP-leak patch only, C = HARD HALT) plus the explicit refusal prose naming fingerprint-spoofing libraries (playwright-extra, puppeteer-extra-plugin-stealth, puppeteer-extra), CAPTCHA solvers (2captcha, anticaptcha, deathbycaptcha, capsolver), and JA3/JA4 TLS fingerprint adjustments.
6. `<checkpoint_resume>` emits the D-50 hardened decision tree: Step 1 (fresh vs exists), Step 1b JSON validity guard, Step 2 (4-hour expires_at window), Step 2a concurrent-invocation guard (5-minute heartbeat window), Step 3 mid-operation expiry guard (GDPR Article 30 record-keeping rationale), plus explicit Timezone discipline clause requiring the Z UTC suffix on every ISO-8601 timestamp.
7. `<playwright_mcp_protocol>` binds the subagent to accessibility-tree snapshots via the 13 Playwright MCP tools and enumerates forbidden tool patterns.

Additional `<scope_exclusion>` block locks the subagent to single-service-per-invocation scope and cites the Mapfre canonical fixture (5 endpoints: 2 DOCUMENTED + 2 INTERNAL + 1 INTERNAL-HARDENED).

## Decisions Applied

| Decision | Applied Where |
| -------- | ------------- |
| D-43 (frontmatter + tool scope) | Frontmatter `tools` line carries the 13 Playwright MCP tools in exact order, plus Read/Grep/Glob/Write. NO Bash, NO WebFetch, NO other MCPs. Per BROWSER-01. |
| D-46 (OPT_IN_LEDGER.jsonl schema) | `<opt_in_gate>` Step 6 enumerates the 8 fields: `service_slug`, `opted_in_at`, `ip`, `jurisdiction`, `tos_tier`, `tos_url`, `tos_excerpt_sha256`, `attestation`. Append-only with `corrects_entry` for corrections. |
| D-47 (7-step opt-in gate) | `<opt_in_gate>` block contains the 7 numbered steps verbatim + refusal posture for TOS-RED. Per BROWSER-03. |
| D-49 (posture A/B/C classification) | `<posture_classification>` block with explicit refusal prose for Posture C naming all anti-features from REQUIREMENTS.md BROWSER-05. |
| D-50 (state.json + 4-hour expires_at + resume logic) | `<checkpoint_resume>` block with Step 1 through Step 2a decision tree + phase transition protocol + phase enum lifecycle (`opt-in-pending` through `complete` plus terminal `blocked`/`failed`). Per BROWSER-08. |
| D-55 (Ralph retry caps) | Core responsibilities bullet 8: default 3, hard cap 5, exponential backoff 1s/4s/16s, different timing NEVER different fingerprint. |
| D-58 (context-budget discipline) | Frontmatter does NOT load discovery-report-schema.md / output-firewall.md / legal-posture.md at Phase 3 entry; those load inside the subagent's forked context on invocation per Mandatory Initial Read. |
| BLOCK-1 eng-review (JSON validity guard) | Step 1b in `<checkpoint_resume>` validates `schema_version`, `service_slug`, `expires_at` ending with `Z`, and `phase` enum. On corrupt file: HALT with "corrupt or incompatible" message. Preserves the corrupt file for debugging (no auto-delete). |
| BLOCK-2 eng-review (concurrent-invocation guard) | Step 2a in `<checkpoint_resume>` detects concurrent live sessions via 5-minute heartbeat window. Halts with "Concurrent invocation not allowed" when `last_checkpoint_at` is within 5 minutes. |
| BLOCK-5 eng-review (mid-operation expiry guard) | Phase transition protocol re-checks `now() < state.expires_at` before each lifecycle transition. Expiry mid-operation HALTs with GDPR Article 30 record-keeping rationale: "would violate GDPR Article 30 audit trail". |
| A-03 UTC discipline | Explicit "Timezone discipline" clause at the top of `<checkpoint_resume>` requires the Z UTC suffix on all state.json timestamps. Local-time strings and numeric offsets (`+00:00`) are rejected. |

## Verification Results

### Plan 26-check automated grep bundle: PASS

| # | Check | Expected | Actual |
| - | ----- | -------- | ------ |
| 1 | File exists at `.claude/agents/browser-discovery.md` | yes | yes |
| 2 | First 18 lines `^name: browser-discovery$` | match | match |
| 3 | First 18 lines `^context: fork$` | match | match |
| 4 | First 18 lines `^color: red$` | match | match |
| 5 | First 18 lines NO `\bBash\b` | no match | no match |
| 6 | First 18 lines NO `\bWebFetch\b` | no match | no match |
| 7 | `mcp__playwright__browser_navigate` | present | present |
| 8 | `mcp__playwright__browser_snapshot` | present | present |
| 9 | `mcp__playwright__browser_network_requests` | present | present |
| 10 | `<write_constraint>` + `</write_constraint>` | both | both |
| 11 | `<output_contract>` + `</output_contract>` | both | both |
| 12 | `<opt_in_gate>` + `</opt_in_gate>` | both | both |
| 13 | `<posture_classification>` + `</posture_classification>` | both | both |
| 14 | `<checkpoint_resume>` + `</checkpoint_resume>` | both | both |
| 15 | `CRITICAL: Mandatory Initial Read` | present | present |
| 16 | `OPT_IN_LEDGER.jsonl` | present | present |
| 17 | `DISCOVERY-LICENSE-NOTICE.md` | present | present |
| 18 | `DISCOVERY-BLOCKED-REPORT.md` | present | present |
| 19 | `DISCOVERY-REPORT.md` | present | present |
| 20 | `state.json` | present | present |
| 21 | `discovery-report-schema.md` | present | present |
| 22 | `output-firewall.md` | present | present |
| 23 | `legal-posture.md` | present | present |
| 24 | em-dash count | 0 | 0 |
| 25 | line count >=170 | yes | 171 |
| 26 | line count <=280 | yes | 171 |

Bundle output: `PASS`.

### Hardened-guard checks (6088e86 eng-review additions): PASS

| # | Check | Result |
| - | ----- | ------ |
| A | `JSON validity guard` | PASS |
| B | `corrupt or incompatible` | PASS |
| C | `Concurrent-invocation guard` | PASS |
| D | `heartbeat window: 5 minutes` | PASS |
| E | `Concurrent invocation not allowed` | PASS |
| F | `mid-operation expiry guard` | PASS |
| G | `expired mid-operation` | PASS |
| H | `GDPR Article 30` | PASS |
| I | `Z UTC suffix` | PASS (exact literal substring match) |
| J | `Timezone discipline` | PASS |
| K | `schema_version` | PASS |

### Requirements Satisfied

| Requirement | Status | Evidence |
| ----------- | ------ | -------- |
| BROWSER-01 | Complete | Subagent at `.claude/agents/browser-discovery.md` with `context: fork`, Playwright MCP tool scope only, NO Bash, NO WebFetch. TARGET.md listed as first Mandatory Initial Read item. |
| BROWSER-03 | Complete | `<opt_in_gate>` 7-step protocol blocks browser launch until DISCOVERY-LICENSE-NOTICE.md signed AND OPT_IN_LEDGER.jsonl entry appended. |
| BROWSER-08 | Complete | `<checkpoint_resume>` decision tree implements 4-hour `expires_at` resume semantics with phase-level granularity, concurrent-invocation guard, mid-operation expiry guard, and UTC timezone discipline. |

## Commits

- `71637f2` — `feat(11): create browser-discovery subagent (Plan 11-03 Task 1)`

## Downstream Wiring

File is ready for Plan 11-04 to:

1. Unmark `[Phase 11 scope]` in `references/phase-3-integration.md` Priority 3 and replace the forward See-line with concrete references to `browser-fallback.md` + `browser-stack.md` (per D-57).
2. Extend `SKILL.md` Phase 3 See-line load-list with `browser-fallback.md` + `browser-stack.md` (per D-58 context-budget discipline). The subagent's 3 additional references (discovery-report-schema.md, output-firewall.md, legal-posture.md) are loaded only inside the forked subagent context on invocation, NOT unconditionally at Phase 3 entry.
